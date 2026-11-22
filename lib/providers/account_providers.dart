// F2 Tài khoản và đồng bộ: nối auth_service và sync_service với Riverpod.
// Chưa đăng nhập hoặc Firebase chưa sẵn sàng (FirebaseSetup.isReady = false) thì không làm gì,
// app chạy bằng Hive như trước.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_boxes.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'app_providers.dart';
import 'focus_session_provider.dart';

final authServiceProvider = Provider((ref) => AuthService());

/// Người dùng đang đăng nhập, null nếu chưa (hoặc không có máy chủ).
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

/// Tên đăng nhập của người dùng hiện tại.
final currentUsernameProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  final name = user.displayName;
  return name != null && name.isNotEmpty ? name : AuthRules.usernameFromEmail(user.email ?? '');
});

class SyncStatusNotifier extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState();

  void set(SyncState value) => state = value;
}

/// Trạng thái đồng bộ: offline / syncing / synced / error, kèm lastSyncedAt.
final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncState>(SyncStatusNotifier.new);

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    onDataChanged: () => reloadLocalData(ref),
    onStateChanged: (state) => ref.read(syncStatusProvider.notifier).set(state),
  );
  ref.onDispose(service.stop);
  return service;
});

/// Bật đồng bộ khi đăng nhập, tắt khi đăng xuất. DisGretApp theo dõi provider này.
final syncControllerProvider = Provider<void>((ref) {
  final service = ref.watch(syncServiceProvider);
  ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
    final uid = next.value?.uid;
    // Chạy sau khi provider dựng xong: Riverpod không cho đổi provider khác (trạng thái đồng
    // bộ) ngay trong lúc đang dựng provider này.
    Future.microtask(() => uid == null ? service.stop() : service.start(uid));
  }, fireImmediately: true);
});

/// Các thao tác tài khoản cho màn Cài đặt.
class AccountActions {
  AccountActions(this._ref);

  final Ref _ref;

  AuthService get _auth => _ref.read(authServiceProvider);

  Future<void> signIn(String username, String password) => _auth.signIn(username, password);

  Future<void> signUp(String username, String password) => _auth.signUp(username, password);

  /// Đăng xuất: dừng nghe, đợi đẩy nốt thay đổi (tối đa vài giây), xoá thật dữ liệu trên máy,
  /// đăng xuất Firebase. Máy quay về trạng thái như mới cài (vào lại onboarding); dữ liệu vẫn
  /// còn trên mây, đăng nhập lại là có.
  Future<void> signOut() async {
    final sync = _ref.read(syncServiceProvider);
    await sync.flushNow();
    await sync.stop();
    await HiveBoxes.clearUserData();
    await _auth.signOut();
    reloadLocalData(_ref);
    _ref.invalidate(focusSessionProvider);
  }
}

final accountActionsProvider = Provider(AccountActions.new);
