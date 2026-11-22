// 5.1 Hôm nay: kế hoạch cho phiên học tiếp theo (mục tiêu, thói quen, số phút).
// Pure function with unit tests (test/session_plan_test.dart); rules in
// specs/001-today-single-study-entry/data-model.md.
import 'habit_science.dart';
import 'models/goal.dart';
import 'models/habit.dart';
import 'models/habit_log.dart';

/// What Hôm nay shows.
enum SessionPlanState {
  /// No goal yet: show a single "create goal" call.
  noGoal,

  /// A goal but no habit: show a single "add habit" call.
  noHabit,

  /// A habit is due today and not done: show "Bắt đầu".
  ready,

  /// Every habit due today is done: an extra session is a secondary action.
  allDoneToday,

  /// No habit is due today by schedule: an optional session is a secondary action.
  restDay,
}

/// The goal, habit and duration proposed for the next study session. Kept in memory only.
class SessionPlan {
  const SessionPlan({
    required this.state,
    required this.goal,
    required this.habit,
    required this.plannedMinutes,
  });

  /// Used when the habit has no usable minimum (current Focus default).
  static const int defaultMinutes = 25;

  /// Habit minimum minutes count as a planned duration only within this range.
  static const int minPlanMinutes = 5;
  static const int maxMinutes = 480;

  /// "Chỉ 5 phút thôi" always starts a 5-minute session.
  static const int smallStepMinutes = 5;

  final SessionPlanState state;
  final Goal? goal;
  final Habit? habit;
  final int plannedMinutes;

  /// True when a session can be started (there is a habit).
  bool get canStart => habit != null;

  /// Builds the plan for [today].
  ///
  /// - goal: the first goal.
  /// - habit: [overrideHabitId] if that habit is in [habits] and not archived; else the first habit
  ///   due today and not done; else the first habit.
  /// - plannedMinutes: [overrideMinutes] if within 1–480; else the habit's minimum minutes if
  ///   within 5–480; else 25.
  static SessionPlan next({
    required List<Goal> goals,
    required List<Habit> habits,
    required List<HabitLog> logs,
    required DateTime today,
    String? overrideHabitId,
    int? overrideMinutes,
  }) {
    final goal = goals.isEmpty ? null : goals.first;
    final active = [
      for (final habit in habits)
        if (!habit.archived) habit,
    ];

    if (goal == null || active.isEmpty) {
      return SessionPlan(
        state: goal == null ? SessionPlanState.noGoal : SessionPlanState.noHabit,
        goal: goal,
        habit: null,
        plannedMinutes: defaultMinutes,
      );
    }

    Habit? nextDue;
    var anyDue = false;
    for (final habit in active) {
      final history = HabitHistory.of(habit, logs);
      if (!history.isDueOn(today)) continue;
      anyDue = true;
      if (!history.isDone(today)) {
        nextDue = habit;
        break;
      }
    }

    final state = nextDue != null
        ? SessionPlanState.ready
        : (anyDue ? SessionPlanState.allDoneToday : SessionPlanState.restDay);
    final habit = _find(active, overrideHabitId) ?? nextDue ?? active.first;

    return SessionPlan(
      state: state,
      goal: goal,
      habit: habit,
      plannedMinutes: _minutes(habit, overrideMinutes),
    );
  }

  static Habit? _find(List<Habit> habits, String? id) {
    if (id == null) return null;
    for (final habit in habits) {
      if (habit.id == id) return habit;
    }
    return null;
  }

  static int _minutes(Habit habit, int? overrideMinutes) {
    if (overrideMinutes != null && overrideMinutes >= 1 && overrideMinutes <= maxMinutes) {
      return overrideMinutes;
    }
    final habitMinutes = habit.minMinutesPerDay;
    if (habitMinutes >= minPlanMinutes && habitMinutes <= maxMinutes) return habitMinutes;
    return defaultMinutes;
  }
}
