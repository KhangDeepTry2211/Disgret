// 2.2 Nhắc giờ học (spec 009 FR-001): which reminders are planned for the next days.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/reminder_plan.dart';

void main() {
  // Monday 2026-03-02, 18:00.
  final now = DateTime(2026, 3, 2, 18);

  Habit habit({
    String id = 'h1',
    String time = '19:00',
    bool reminder = true,
    bool archived = false,
    HabitRepeat repeat = HabitRepeat.daily,
    List<int> weekdays = const [],
  }) => Habit(
    id: id,
    goalId: 'g1',
    name: 'Ôn Toán',
    minMinutesPerDay: 25,
    repeat: repeat,
    weekdays: weekdays,
    reminderEnabled: reminder,
    reminderTime: time,
    archived: archived,
    startDate: DateTime(2026, 3, 1),
  );

  List<DateTime> times(List<PlannedReminder> plan) => [for (final r in plan) r.at];

  test('a daily habit is reminded at its time on each of the next 7 days', () {
    final plan = ReminderPlan.upcoming(habits: [habit()], doneToday: const {}, now: now);

    expect(times(plan), [
      for (var day = 0; day < ReminderPlan.daysAhead; day++) DateTime(2026, 3, 2 + day, 19),
    ]);
  });

  test('a time already past today starts tomorrow', () {
    final plan = ReminderPlan.upcoming(
      habits: [habit(time: '07:30')],
      doneToday: const {},
      now: now,
    );

    expect(plan.first.at, DateTime(2026, 3, 3, 7, 30));
    expect(plan, hasLength(ReminderPlan.daysAhead - 1));
  });

  test('a habit done today is not reminded today, still tomorrow', () {
    final plan = ReminderPlan.upcoming(habits: [habit()], doneToday: const {'h1'}, now: now);

    expect(plan.first.at, DateTime(2026, 3, 3, 19));
  });

  test('archived habits and switched-off reminders are not reminded', () {
    final plan = ReminderPlan.upcoming(
      habits: [
        habit(id: 'a', archived: true),
        habit(id: 'b', reminder: false),
      ],
      doneToday: const {},
      now: now,
    );

    expect(plan, isEmpty);
  });

  test('a weekly habit on Monday and Wednesday is reminded only on those days', () {
    final plan = ReminderPlan.upcoming(
      habits: [
        habit(repeat: HabitRepeat.weekly, weekdays: const [1, 3]),
      ],
      doneToday: const {},
      now: now,
    );

    expect(times(plan), [DateTime(2026, 3, 2, 19), DateTime(2026, 3, 4, 19)]);
  });

  test('reminders are sorted, capped, and name the habit and its minutes', () {
    final many = [
      for (var i = 0; i < 20; i++) habit(id: 'h$i', time: '19:${i.toString().padLeft(2, '0')}'),
    ];
    final plan = ReminderPlan.upcoming(habits: many, doneToday: const {}, now: now);

    expect(plan, hasLength(ReminderPlan.maxReminders));
    expect(times(plan), [...times(plan)]..sort());
    expect(plan.first.body, contains('Ôn Toán'));
    expect(plan.first.body, contains('25 phút'));
    expect(plan.first.title, isNotEmpty);
  });
}
