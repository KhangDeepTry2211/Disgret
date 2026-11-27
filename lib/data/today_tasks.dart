// 2.1 Hôm nay (spec 015): the habits scheduled today, done or not, in the order the day goes.
import 'habit_progress.dart';
import 'habit_schedule.dart';
import 'models/habit.dart';
import 'models/habit_log.dart';

class TodayTask {
  const TodayTask({required this.habit, required this.done});

  final Habit habit;
  final bool done;

  /// "HH:mm" when the habit has its reminder on; null otherwise.
  String? get time => habit.reminderEnabled ? habit.reminderTime : null;
}

abstract final class TodayTasks {
  /// Active habits scheduled on [today]: timed ones first by their time, then by habit order.
  static List<TodayTask> of({
    required List<Habit> habits,
    required Iterable<HabitLog> logs,
    required DateTime today,
  }) {
    final tasks = [
      for (final habit in habits)
        if (!habit.archived && HabitSchedule.isScheduledOn(habit, today))
          TodayTask(habit: habit, done: HabitProgress.isDone(habit, today, logs)),
    ];
    tasks.sort((a, b) {
      final timeA = a.time;
      final timeB = b.time;
      if (timeA != null && timeB != null && timeA != timeB) return timeA.compareTo(timeB);
      if (timeA != null && timeB == null) return -1;
      if (timeA == null && timeB != null) return 1;
      return a.habit.sortOrder.compareTo(b.habit.sortOrder);
    });
    return tasks;
  }
}
