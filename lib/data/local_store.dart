// F2 Lưu trữ local có đánh dấu để đồng bộ.
// Mọi bản ghi cần đồng bộ là một Map trong Hive, có thêm 2 trường do lớp này tự quản lý:
// - updatedAtMs: lần sửa cuối (millisecondsSinceEpoch, UTC). Dùng để so "bản nào mới hơn".
// - deleted: xoá mềm. Xoá không gỡ khỏi box mà đánh dấu, để lần xoá cũng được đồng bộ.
// Mỗi lần ghi từ app (write, markDeleted) đều báo qua [changes] để sync_service đẩy lên mây.
// Ghi từ mây về (applyRemote) thì KHÔNG báo, tránh đẩy ngược lên lại.
import 'dart:async';

import 'package:hive/hive.dart';

class SyncFields {
  SyncFields._();

  static const String updatedAt = 'updatedAtMs';
  static const String deleted = 'deleted';

  static int updatedAtOf(Map<String, dynamic>? record) =>
      (record?[updatedAt] as num?)?.toInt() ?? 0;

  static bool isDeleted(Map<String, dynamic>? record) => record?[deleted] == true;
}

/// Một bản ghi vừa đổi ở máy này.
typedef LocalChange = ({String box, String id});

class LocalStore {
  LocalStore._();

  /// Đồng hồ dùng để gán updatedAtMs; test thay bằng đồng hồ giả.
  static DateTime Function() clock = DateTime.now;

  static int nowMs() => clock().toUtc().millisecondsSinceEpoch;

  static final StreamController<LocalChange> _changes = StreamController.broadcast();

  /// Hook cho sync_service: báo (box, id) mỗi khi app ghi hoặc xoá một bản ghi.
  static Stream<LocalChange> get changes => _changes.stream;

  static Box<dynamic> _box(String name) => Hive.box<dynamic>(name);

  /// Bản ghi kể cả đã xoá mềm; null nếu chưa từng có.
  static Map<String, dynamic>? readRaw(String box, String id) {
    final value = _box(box).get(id);
    return value is Map ? deepStringKeys(value) : null;
  }

  /// Bản ghi còn sống; đã xoá mềm thì coi như không có.
  static Map<String, dynamic>? read(String box, String id) {
    final value = _box(box).get(id);
    if (value is! Map) return null;
    final record = Map<String, dynamic>.from(value);
    return SyncFields.isDeleted(record) ? null : record;
  }

  /// Mọi bản ghi còn sống của box.
  static List<Map<String, dynamic>> readAll(String box) => [
    for (final value in _box(box).values)
      if (value is Map && value[SyncFields.deleted] != true) Map<String, dynamic>.from(value),
  ];

  /// Mọi bản ghi kể cả đã xoá mềm, theo id. Dùng cho đồng bộ.
  static Map<String, Map<String, dynamic>> readAllRaw(String box) {
    final hive = _box(box);
    return {
      for (final key in hive.keys)
        if (hive.get(key) is Map) key.toString(): deepStringKeys(hive.get(key) as Map),
    };
  }

  /// Ghi từ app: gán updatedAtMs = bây giờ. deleted lấy từ dữ liệu nếu có (ReelComment tự có
  /// trường deleted), không có thì false.
  static Future<void> write(String box, String id, Map<String, dynamic> data) async {
    await _box(box).put(id, {
      ...data,
      SyncFields.updatedAt: nowMs(),
      SyncFields.deleted: data[SyncFields.deleted] == true,
    });
    _changes.add((box: box, id: id));
  }

  /// Xoá mềm. Bản ghi chưa có hoặc đã xoá rồi thì không làm gì.
  static Future<void> markDeleted(String box, String id) async {
    final record = readRaw(box, id);
    if (record == null || SyncFields.isDeleted(record)) return;
    await _box(box).put(id, {...record, SyncFields.deleted: true, SyncFields.updatedAt: nowMs()});
    _changes.add((box: box, id: id));
  }

  /// Xoá mềm mọi bản ghi của box (Xoá toàn bộ dữ liệu khi đã đăng nhập).
  static Future<void> markAllDeleted(String box) async {
    for (final id in readAllRaw(box).keys) {
      await markDeleted(box, id);
    }
  }

  /// Ghi bản từ mây về, giữ nguyên updatedAtMs của nó, không báo thay đổi.
  static Future<void> applyRemote(String box, String id, Map<String, dynamic> record) =>
      _box(box).put(id, record);

  /// Xoá thật mọi bản ghi (khi đăng xuất).
  static Future<void> purge(String box) => _box(box).clear();

  /// Migrate: bản ghi cũ thiếu updatedAtMs thì gán bây giờ, thiếu deleted thì false.
  /// Không báo thay đổi; khi đăng nhập, luật gộp sẽ tự đẩy chúng lên nếu mới hơn bản trên mây.
  static Future<void> addMissingSyncFields(String box) async {
    final hive = _box(box);
    final now = nowMs();
    for (final key in hive.keys.toList()) {
      final value = hive.get(key);
      if (value is! Map) continue;
      final hasTime = value[SyncFields.updatedAt] is num;
      final hasDeleted = value[SyncFields.deleted] is bool;
      if (hasTime && hasDeleted) continue;
      await hive.put(key, {
        ...Map<String, dynamic>.from(value),
        if (!hasTime) SyncFields.updatedAt: now,
        if (!hasDeleted) SyncFields.deleted: false,
      });
    }
  }

  /// Hive trả về `Map<dynamic, dynamic>` lồng nhau; Firestore cần `Map<String, dynamic>`.
  static Map<String, dynamic> deepStringKeys(Map<dynamic, dynamic> map) => {
    for (final entry in map.entries) entry.key.toString(): _deepValue(entry.value),
  };

  static dynamic _deepValue(dynamic value) {
    if (value is Map) return deepStringKeys(value);
    if (value is List) return [for (final item in value) _deepValue(item)];
    return value;
  }
}
