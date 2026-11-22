// F2 Đồng bộ Hive ⇄ Firestore. Đường dẫn: users/{uid}/{box}/{id}, xem HiveBoxes.synced.
//
// Khi đăng nhập ([start]):
//   1. Tải toàn bộ dữ liệu trên mây về, gộp với dữ liệu trên máy theo luật trong sync_merge.dart.
//   2. Đẩy những bản trên máy mới hơn lên.
//   3. Nghe thay đổi trên mây (snapshots) để cập nhật máy này ngay khi máy khác sửa.
// Trong lúc chạy: mỗi lần app ghi Hive, LocalStore báo (box, id); gom khoảng 1 giây rồi ghi
// một lượt bằng WriteBatch. Firestore có cache offline nên mất mạng thì nó tự đẩy khi có lại.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/hive_boxes.dart';
import '../data/local_store.dart';
import 'sync_merge.dart';

enum SyncStatus { offline, syncing, synced, error }

class SyncState {
  const SyncState({this.status = SyncStatus.offline, this.lastSyncedAt, this.error});

  final SyncStatus status;

  /// Lần gần nhất máy này và mây khớp nhau.
  final DateTime? lastSyncedAt;
  final String? error;
}

class SyncService {
  SyncService({required this.onDataChanged, required this.onStateChanged});

  /// Gọi khi dữ liệu trên máy vừa đổi do bản từ mây về, để giao diện tải lại.
  final void Function() onDataChanged;
  final void Function(SyncState state) onStateChanged;

  /// Gom các thay đổi trong khoảng này rồi mới ghi một lượt.
  static const Duration debounce = Duration(seconds: 1);

  /// Firestore cho tối đa 500 thao tác mỗi batch; để dư cho an toàn.
  static const int batchLimit = 400;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String? _uid;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Set<LocalChange> _pending = {};
  Timer? _debounceTimer;
  int _commitsInFlight = 0;
  bool _offline = false;
  bool _starting = false;
  String? _error;
  DateTime? _lastSyncedAt;

  bool get isRunning => _uid != null;

  CollectionReference<Map<String, dynamic>> _collection(String uid, String box) =>
      _db.collection('users').doc(uid).collection(box);

  Future<void> start(String uid) async {
    if (_uid == uid) return;
    await stop();
    _uid = uid;
    _starting = true;
    _error = null;
    _emit();

    // Nghe thay đổi trên máy ngay từ đầu để không sót lần sửa nào trong lúc đang tải về.
    _subscriptions.add(LocalStore.changes.listen(_onLocalChange));
    try {
      for (final box in HiveBoxes.synced) {
        final snapshot = await _collection(uid, box).get();
        if (_uid != uid) return; // Đã đăng xuất giữa chừng.
        final remote = {for (final doc in snapshot.docs) doc.id: doc.data()};
        final plan = SyncMerge.plan(LocalStore.readAllRaw(box), remote);
        for (final entry in plan.toApply.entries) {
          await LocalStore.applyRemote(box, entry.key, entry.value);
        }
        _pending.addAll(plan.toPush.map((id) => (box: box, id: id)));
      }
      onDataChanged();
      await _flush();
      for (final box in HiveBoxes.synced) {
        _subscriptions.add(
          _collection(uid, box)
              .snapshots(includeMetadataChanges: true)
              .listen((snapshot) => _onSnapshot(box, snapshot), onError: _onError),
        );
      }
      _starting = false;
      _lastSyncedAt = DateTime.now();
      _emit();
    } catch (error) {
      _starting = false;
      _onError(error);
    }
  }

  /// Dừng nghe (đăng xuất). Thay đổi chưa đẩy thì bỏ; muốn đẩy hết trước thì gọi [flushNow].
  Future<void> stop() async {
    final wasRunning = _uid != null;
    _uid = null;
    _debounceTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _pending.clear();
    _commitsInFlight = 0;
    _offline = false;
    _starting = false;
    if (wasRunning) onStateChanged(const SyncState());
  }

  /// Đẩy ngay các thay đổi đang chờ, đợi tối đa [timeout] (mất mạng thì không chờ mãi).
  Future<void> flushNow({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      await _flush().timeout(timeout);
    } on TimeoutException {
      // Hết giờ: Firestore vẫn giữ trong cache và đẩy sau nếu còn đăng nhập.
    }
  }

  void _onLocalChange(LocalChange change) {
    if (!HiveBoxes.synced.contains(change.box)) return;
    _pending.add(change);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, _flush);
  }

  Future<void> _flush() async {
    _debounceTimer?.cancel();
    final uid = _uid;
    if (uid == null || _pending.isEmpty) return;

    final changes = _pending.toList();
    _pending.clear();
    final commits = <Future<void>>[];
    for (var start = 0; start < changes.length; start += batchLimit) {
      final batch = _db.batch();
      var count = 0;
      for (final change in changes.skip(start).take(batchLimit)) {
        // Đọc bản mới nhất lúc ghi; bản ghi xoá mềm cũng được đẩy như bình thường.
        final record = LocalStore.readRaw(change.box, change.id);
        if (record == null) continue;
        batch.set(_collection(uid, change.box).doc(change.id), record);
        count++;
      }
      if (count > 0) commits.add(batch.commit());
    }
    if (commits.isEmpty) return;

    _commitsInFlight++;
    _emit();
    try {
      // Mất mạng thì commit chỉ xong khi có mạng lại; trong lúc đó trạng thái là offline.
      await Future.wait(commits);
      _lastSyncedAt = DateTime.now();
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _commitsInFlight--;
      _emit();
    }
  }

  Future<void> _onSnapshot(String box, QuerySnapshot<Map<String, dynamic>> snapshot) async {
    _offline = snapshot.metadata.isFromCache;
    var changed = false;
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.removed) continue; // Không bao giờ xoá thật trên mây.
      final doc = change.doc;
      if (doc.metadata.hasPendingWrites) continue; // Chính máy này vừa ghi, chưa lên tới mây.
      final remote = doc.data();
      if (remote == null) continue;
      final local = LocalStore.readRaw(box, doc.id);
      if (SyncMerge.pick(local, remote) == MergeWinner.remote) {
        await LocalStore.applyRemote(box, doc.id, remote);
        changed = true;
      }
    }
    if (changed) onDataChanged();
    if (!_offline && _commitsInFlight == 0) _lastSyncedAt = DateTime.now();
    _emit();
  }

  void _onError(Object error) {
    _error = error.toString();
    _emit();
  }

  void _emit() {
    if (_uid == null) return;
    final status = _error != null
        ? SyncStatus.error
        : _offline
        ? SyncStatus.offline
        : _starting || _commitsInFlight > 0
        ? SyncStatus.syncing
        : SyncStatus.synced;
    onStateChanged(SyncState(status: status, lastSyncedAt: _lastSyncedAt, error: _error));
  }
}
