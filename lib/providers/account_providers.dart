// F2, F3 Tài khoản và đồng bộ: nối auth_service và sync_service với Riverpod.
// Chưa đăng nhập hoặc Firebase chưa sẵn sàng (FirebaseSetup.isReady = false) thì không làm gì,
// app chạy bằng Hive như trước.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_boxes.dart';
import '../data/local_store.dart';
import '../services/auth_service.dart';
import '../services/firebase_setup.dart';
import '../services/sync_service.dart';
import 'app_providers.dart';
import 'focus_session_provider.dart';

final authServiceProvider = Provider((ref) => AuthService());

/// Firebase đã khởi tạo được chưa. Tách thành provider để test giả lập có / không có máy chủ.
final firebaseReadyProvider = Provider<bool>((ref) => FirebaseSetup.isReady);

/// Người dùng đang đăng nhập, null nếu chưa (hoặc không có máy chủ).
final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

/// Người dùng hiện tại (null nếu chưa đăng nhập hoặc đang chờ Firebase trả lời).
final currentUserProvider = Provider<AuthUser?>((ref) => ref.watch(authStateProvider).value);

/// Tên đăng nhập của người dùng hiện tại.
final currentUsernameProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider)?.username,
);

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
  ref.listen<AsyncValue<AuthUser?>>(authStateProvider, (previous, next) {
    final uid = next.value?.uid;
    // Chạy sau khi provider dựng xong: Riverpod không cho đổi provider khác (trạng thái đồng
    // bộ) ngay trong lúc đang dựng provider này.
    Future.microtask(() => uid == null ? service.stop() : service.start(uid));
  }, fireImmediately: true);
});

/// Các thao tác tài khoản cho màn đăng nhập, đăng ký và Hồ sơ.
class AccountActions {
  AccountActions(this._ref);

  final Ref _ref;

  /// Chờ lượt tải dữ liệu đầu tiên tối đa chừng này; mạng chậm thì vẫn vào app, đồng bộ chạy tiếp.
  static const Duration firstSyncTimeout = Duration(seconds: 20);

  AuthService get _auth => _ref.read(authServiceProvider);

  /// Đăng nhập rồi chờ tải dữ liệu trên mây về và gộp xong.
  /// Trả về true nếu tài khoản đã làm quiz động lực (khi đó bỏ qua onboarding).
  /// [onSignedIn] được gọi ngay khi Firebase nhận đăng nhập, trước lúc chờ tải dữ liệu, để màn
  /// hình đổi sang "Đang tải dữ liệu của bạn…".
  Future<bool> signIn(String username, String password, {void Function()? onSignedIn}) async {
    final uid = await _auth.signIn(username, password);
    onSignedIn?.call();
    await _waitFirstSync(uid);
    final profiles = _ref.read(profileRepositoryProvider);
    final hasQuiz = profiles.profile?.motivationTypes.isNotEmpty ?? false;
    if (hasQuiz) await profiles.markOnboardingDone();
    reloadLocalData(_ref);
    return hasQuiz;
  }

  /// Tạo tài khoản rồi đẩy dữ liệu đang có trên máy (nếu dùng thử trước đó) lên tài khoản.
  /// Trả về true nếu có dữ liệu được gộp lên.
  Future<bool> signUp(String username, String password) async {
    final hadLocalData = HiveBoxes.synced.any((box) => LocalStore.readAll(box).isNotEmpty);
    final uid = await _auth.signUp(username, password);
    await _waitFirstSync(uid);
    reloadLocalData(_ref);
    return hadLocalData;
  }

  Future<void> _waitFirstSync(String uid) async {
    try {
      await _ref.read(syncServiceProvider).start(uid).timeout(firstSyncTimeout);
    } on TimeoutException {
      // Mạng chậm: vào app trước, đồng bộ vẫn chạy nền.
    }
  }

  /// Đồng bộ lại toàn bộ (nút "Đồng bộ ngay" ở Hồ sơ).
  Future<void> syncNow() => _ref.read(syncServiceProvider).resync();

  /// Đăng xuất: đẩy nốt thay đổi (tối đa vài giây), dừng nghe, xoá thật dữ liệu trên máy (kể cả
  /// guestMode), đăng xuất Firebase. Máy quay về màn chào như mới cài; dữ liệu vẫn còn trên mây.
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
