// 6.2 Lưu trữ local – phiên học.
import '../hive_boxes.dart';
import '../models/session.dart';
import 'hive_repository.dart';

class SessionRepository extends HiveRepository<Session> {
  SessionRepository() : super(HiveBoxes.sessions);

  @override
  Session fromMap(Map<String, dynamic> map) => Session.fromMap(map);

  @override
  Map<String, dynamic> toMap(Session item) => item.toMap();

  @override
  String idOf(Session item) => item.id;
}
