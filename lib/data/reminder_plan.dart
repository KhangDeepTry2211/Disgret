// 2.2 Nhắc giờ học (spec 009 FR-001, ADR-0006): which reminders to schedule for the next days.
// Pure: the reminder service replaces every pending reminder with this list at app start and
// whenever habits or habit logs change, so today's reminder disappears once the habit is done.
import '../l10n/app_strings.dart';
import 'date_utils.dart';
import 'habit_schedule.dart';
import 'models/habit.dart';

class PlannedReminder {
  const PlannedReminder({
    required this.habitId,
    required this.at,
    required this.title,
    required this.body,
  });

  final String habitId;

  /// Local date and time to notify at.
  final DateTime at;
  final String title;
  final String body;
}

abstract final class ReminderPlan {
  /// Days planned ahead, today included; the plan is rebuilt every time the app starts.
  static const int daysAhead = 7;

  /// Stays far below Android's limit on pending alarms.
  static const int maxReminders = 60;

  /// Reminders of [habits] from [now] on, earliest first. Habits in [doneToday] are not reminded
  /// today.
  static List<PlannedReminder> upcoming({
    required List<Habit> habits,
    required Set<String> doneToday,
    required DateTime now,
  }) {
    final today = dateOnly(now);
    final reminders = <PlannedReminder>[];
    for (final habit in habits) {
      if (habit.archived || !habit.reminderEnabled) continue;
      final (hour, minute) = parseTime(habit.reminderTime);
      for (var offset = 0; offset < daysAhead; offset++) {
        final day = addDays(today, offset);
        if (!HabitSchedule.isScheduledOn(habit, day)) continue;
        if (offset == 0 && doneToday.contains(habit.id)) continue;
        final at = DateTime(day.year, day.month, day.day, hour, minute);
        if (!at.isAfter(now)) continue;
        reminders.add(
          PlannedReminder(
            habitId: habit.id,
            at: at,
            title: AppStrings.reminderTitle,
            body: AppStrings.reminderBody(habit.name, habit.minMinutesPerDay),
          ),
        );
      }
    }
    reminders.sort((a, b) => a.at.compareTo(b.at));
    return reminders.take(maxReminders).toList();
  }

  /// "HH:mm"; anything unreadable falls back to the default reminder time.
  static (int, int) parseTime(String raw) {
    final parts = raw.split(':');
    final hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return parseTime(Habit.defaultReminderTime);
    }
    return (hour, minute);
  }
}
