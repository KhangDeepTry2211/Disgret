// 5.4 Góc của Gret: friends earned by studying (spec 018 FR-002). Pure: counts what is already
// stored (sessions, events, habits and their done days), so nothing new is saved to earn a friend.
import 'dart:math' as math;

import 'date_utils.dart';
import 'gret_corner_catalog.dart';
import 'habit_schedule.dart';
import 'habit_science.dart';
import 'models/event.dart';
import 'models/habit.dart';
import 'models/session.dart';
import 'reminder_plan.dart';

abstract final class StudyUnlocks {
  /// A session started this long after a habit's reminder still counts as on time.
  static const Duration onTimeWindow = Duration(minutes: 10);
}

/// What the study unlocks count.
class StudyFacts {
  const StudyFacts({
    this.onTimeStarts = 0,
    this.interventionReturns = 0,
    this.focusedSeconds = 0,
    this.bestHabitDays = 0,
  });

  factory StudyFacts.from({
    required Iterable<Session> sessions,
    required Iterable<Habit> habits,
    required Iterable<Event> events,
    required Iterable<HabitHistory> histories,
  }) {
    final byId = {for (final habit in habits) habit.id: habit};
    // One per habit and day, so several starts in one reminder window count once.
    final onTime = <String>{};
    var focused = 0;
    for (final session in sessions) {
      focused += session.focusedSeconds;
      final habit = byId[session.habitId];
      if (habit != null && _startedOnTime(habit, session.start)) {
        onTime.add('${habit.id}/${dateKey(session.start)}');
      }
    }
    return StudyFacts(
      onTimeStarts: onTime.length,
      interventionReturns: events.where((event) => event.type == EventType.choseStudy).length,
      focusedSeconds: focused,
      bestHabitDays: histories.map(HabitScience.journeyDays).fold(0, math.max),
    );
  }

  /// Sessions started 0–10 minutes after the habit's reminder, on days it is reminded.
  final int onTimeStarts;

  /// Times "Quay lại học" was chosen on the intervention screen.
  final int interventionReturns;
  final int focusedSeconds;

  /// Done days of the habit with the most.
  final int bestHabitDays;

  /// Progress toward [unlock] in its own unit (hours for focus, otherwise a count); 0 for unlocks
  /// that are not earned by studying.
  double progressOf(Unlock unlock) => switch (unlock.kind) {
    UnlockKind.onTimeStarts => onTimeStarts.toDouble(),
    UnlockKind.interventionReturns => interventionReturns.toDouble(),
    UnlockKind.focusHours => focusedSeconds / Duration.secondsPerHour,
    UnlockKind.habitDays => bestHabitDays.toDouble(),
    UnlockKind.free || UnlockKind.pearls || UnlockKind.streak || UnlockKind.premium => 0,
  };

  /// Whether a study unlock's goal is met.
  bool reached(Unlock unlock) => unlock.isStudy && progressOf(unlock) >= unlock.amount;

  static bool _startedOnTime(Habit habit, DateTime start) {
    if (!habit.reminderEnabled || !HabitSchedule.isScheduledOn(habit, dateOnly(start))) {
      return false;
    }
    final (hour, minute) = ReminderPlan.parseTime(habit.reminderTime);
    final reminder = DateTime(start.year, start.month, start.day, hour, minute);
    final late = start.difference(reminder);
    return !late.isNegative && late <= StudyUnlocks.onTimeWindow;
  }
}
