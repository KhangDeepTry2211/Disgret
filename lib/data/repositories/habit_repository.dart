// 6.2 Lưu trữ local – thói quen.
import '../hive_boxes.dart';
import '../models/habit.dart';
import 'hive_repository.dart';

class HabitRepository extends HiveRepository<Habit> {
  HabitRepository() : super(HiveBoxes.habits);

  @override
  Habit fromMap(Map<String, dynamic> map) => Habit.fromMap(map);

  @override
  Map<String, dynamic> toMap(Habit item) => item.toMap();

  @override
  String idOf(Habit item) => item.id;

  List<Habit> getByGoal(String goalId) =>
      getAll().where((habit) => habit.goalId == goalId).toList();
}
