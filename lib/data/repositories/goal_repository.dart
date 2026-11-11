// 6.2 Lưu trữ local – mục tiêu.
import '../hive_boxes.dart';
import '../models/goal.dart';
import 'hive_repository.dart';

class GoalRepository extends HiveRepository<Goal> {
  GoalRepository() : super(HiveBoxes.goals);

  @override
  Goal fromMap(Map<String, dynamic> map) => Goal.fromMap(map);

  @override
  Map<String, dynamic> toMap(Goal item) => item.toMap();

  @override
  String idOf(Goal item) => item.id;
}
