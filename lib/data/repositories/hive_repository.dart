// 6.2 Lưu trữ local – phần dùng chung của các repository.
// Mỗi đối tượng được lưu trong Hive dưới dạng Map (không cần sinh code TypeAdapter),
// nên chạy được trên cả Android lẫn web.
// F2: việc ghi đi qua LocalStore để có updatedAtMs và xoá mềm, phục vụ đồng bộ Firestore.
// Chữ ký các hàm giữ nguyên nên màn hình và Notifier không phải sửa.
import '../local_store.dart';

int _idCounter = 0;

/// Tạo id mới theo thời gian; thêm bộ đếm để hai id tạo cùng lúc không trùng nhau.
String newId() => '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

abstract class HiveRepository<T> {
  HiveRepository(this.boxName);

  final String boxName;

  // Mỗi repository con chỉ cần cho biết cách đổi đối tượng <-> Map và id của nó.
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T item);
  String idOf(T item);

  /// Các bản ghi còn sống (bỏ qua bản đã xoá mềm).
  List<T> getAll() => LocalStore.readAll(boxName).map(fromMap).toList();

  T? getById(String id) {
    final record = LocalStore.read(boxName, id);
    return record == null ? null : fromMap(record);
  }

  /// Lưu và tự gán updatedAtMs = bây giờ.
  Future<void> save(T item) => LocalStore.write(boxName, idOf(item), toMap(item));

  /// Xoá mềm: đánh dấu deleted = true, không gỡ khỏi box, để lần xoá cũng được đồng bộ.
  Future<void> delete(String id) => LocalStore.markDeleted(boxName, id);

  // ---------- Dành cho đồng bộ (sync_service) ----------

  /// Mọi bản ghi kể cả đã xoá mềm, dạng Map.
  Map<String, Map<String, dynamic>> getAllRaw() => LocalStore.readAllRaw(boxName);

  /// Ghi bản từ mây về, không kích hoạt đẩy lên lại.
  Future<void> applyRemote(String id, Map<String, dynamic> record) =>
      LocalStore.applyRemote(boxName, id, record);

  /// Xoá thật cả box, dùng khi đăng xuất.
  Future<void> purgeAll() => LocalStore.purge(boxName);
}
