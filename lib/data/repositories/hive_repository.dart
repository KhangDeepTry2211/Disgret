// 6.2 Lưu trữ local – phần dùng chung của các repository.
// Mỗi đối tượng được lưu trong Hive dưới dạng Map (không cần sinh code TypeAdapter),
// nên chạy được trên cả Android lẫn web.
import 'package:hive/hive.dart';

int _idCounter = 0;

/// Tạo id mới theo thời gian; thêm bộ đếm để hai id tạo cùng lúc không trùng nhau.
String newId() => '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

abstract class HiveRepository<T> {
  HiveRepository(this.boxName);

  final String boxName;

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  // Mỗi repository con chỉ cần cho biết cách đổi đối tượng <-> Map và id của nó.
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T item);
  String idOf(T item);

  List<T> getAll() => _box.values.map(_decode).toList();

  T? getById(String id) {
    final value = _box.get(id);
    return value == null ? null : _decode(value);
  }

  Future<void> save(T item) => _box.put(idOf(item), toMap(item));

  Future<void> delete(String id) => _box.delete(id);

  T _decode(dynamic value) => fromMap(Map<String, dynamic>.from(value as Map));
}
