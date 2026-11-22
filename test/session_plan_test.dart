// 5.1 Kế hoạch phiên học tiếp theo trên Hôm nay (spec 001, data-model.md SessionPlan).
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/habit_log.dart';
import 'package:focus_app/data/session_plan.dart';

// 2/3/2026 is a Monday.
final DateTime _today = DateTime(2026, 3, 2);

const Goal _goal = Goal(id: 'g1', title: 'Đỗ đại học', reason: 'Vì tương lai');
const Goal _otherGoal = Goal(id: 'g2', title: 'Học tiếng Anh', reason: 'Du học');
const Habit _math = Habit(id: 'h1', goalId: 'g1', name: 'Ôn Toán', minMinutesPerDay: 30);
const Habit _read = Habit(id: 'h2', goalId: 'g1', name: 'Đọc sách', minMinutesPerDay: 15);

/// Due only on Tuesdays, so not due on [_today].
const Habit _tuesdayOnly = Habit(
  id: 'h3',
  goalId: 'g1',
  name: 'Luyện nghe',
  minMinutesPerDay: 20,
  repeat: HabitRepeat.weekly,
  weekdays: [DateTime.tuesday],
);

int _nextId = 0;

HabitLog _done(Habit habit, [DateTime? day]) => HabitLog(
  id: 'log_${_nextId++}',
  habitId: habit.id,
  date: day ?? _today,
  source: HabitLogSource.manual,
  minutes: habit.minMinutesPerDay,
);

SessionPlan _plan({
  List<Goal> goals = const [_goal],
  List<Habit> habits = const [_math, _read],
  List<HabitLog> logs = const [],
  String? overrideHabitId,
  int? overrideMinutes,
}) => SessionPlan.next(
  goals: goals,
  habits: habits,
  logs: logs,
  today: _today,
  overrideHabitId: overrideHabitId,
  overrideMinutes: overrideMinutes,
);

void main() {
  group('SessionPlan.state', () {
    test('noGoal when there is no goal', () {
      final plan = _plan(goals: const [], habits: const []);
      expect(plan.state, SessionPlanState.noGoal);
      expect(plan.goal, isNull);
      expect(plan.habit, isNull);
    });

    test('noHabit when a goal exists but no habit', () {
      final plan = _plan(habits: const []);
      expect(plan.state, SessionPlanState.noHabit);
      expect(plan.goal, _goal);
      expect(plan.habit, isNull);
    });

    test('ready when a habit is due and not done', () {
      expect(_plan().state, SessionPlanState.ready);
    });

    test('allDoneToday when every due habit is done', () {
      final plan = _plan(logs: [_done(_math), _done(_read)]);
      expect(plan.state, SessionPlanState.allDoneToday);
    });

    test('restDay when no habit is due today', () {
      final plan = _plan(habits: const [_tuesdayOnly]);
      expect(plan.state, SessionPlanState.restDay);
    });

    test('a done habit plus a not-due habit is allDoneToday, not restDay', () {
      final plan = _plan(habits: const [_tuesdayOnly, _math], logs: [_done(_math)]);
      expect(plan.state, SessionPlanState.allDoneToday);
    });
  });

  group('SessionPlan.goal', () {
    test('is the first goal', () {
      expect(_plan(goals: const [_goal, _otherGoal]).goal, _goal);
    });
  });

  group('SessionPlan.habit', () {
    test('is the first habit due and not done', () {
      expect(_plan().habit, _math);
      expect(_plan(logs: [_done(_math)]).habit, _read);
    });

    test('skips habits not due today', () {
      expect(_plan(habits: const [_tuesdayOnly, _read]).habit, _read);
    });

    test('falls back to the first habit when all are done', () {
      expect(_plan(logs: [_done(_math), _done(_read)]).habit, _math);
    });

    test('falls back to the first habit on a rest day', () {
      expect(_plan(habits: const [_tuesdayOnly]).habit, _tuesdayOnly);
    });

    test('a log from yesterday does not count as done today', () {
      final yesterday = DateTime(2026, 3, 1);
      expect(_plan(logs: [_done(_math, yesterday)]).habit, _math);
    });

    test('override habit wins when it exists and is not archived', () {
      expect(_plan(overrideHabitId: _read.id).habit, _read);
    });

    test('override habit is ignored when it no longer exists', () {
      expect(_plan(overrideHabitId: 'deleted').habit, _math);
    });

    test('override habit is ignored when it is archived', () {
      final archived = _read.copyWith(archived: true);
      expect(_plan(habits: [_math, archived], overrideHabitId: _read.id).habit, _math);
    });
  });

  group('SessionPlan.plannedMinutes', () {
    test('uses the habit minimum minutes when within 5–480', () {
      expect(_plan().plannedMinutes, 30);
      expect(_plan(overrideHabitId: _read.id).plannedMinutes, 15);
    });

    test('falls back to 25 when the habit minutes are below 5', () {
      final tiny = _math.copyWith(minMinutesPerDay: 2);
      expect(_plan(habits: [tiny]).plannedMinutes, SessionPlan.defaultMinutes);
      expect(SessionPlan.defaultMinutes, 25);
    });

    test('falls back to 25 when the habit minutes are above 480', () {
      final huge = _math.copyWith(minMinutesPerDay: 600);
      expect(_plan(habits: [huge]).plannedMinutes, 25);
    });

    test('accepts the bounds 5 and 480', () {
      expect(_plan(habits: [_math.copyWith(minMinutesPerDay: 5)]).plannedMinutes, 5);
      expect(_plan(habits: [_math.copyWith(minMinutesPerDay: 480)]).plannedMinutes, 480);
    });

    test('override minutes win', () {
      expect(_plan(overrideMinutes: 45).plannedMinutes, 45);
      expect(_plan(overrideMinutes: 1).plannedMinutes, 1);
    });

    test('override minutes outside 1–480 are ignored', () {
      expect(_plan(overrideMinutes: 0).plannedMinutes, 30);
      expect(_plan(overrideMinutes: 481).plannedMinutes, 30);
    });

    test('is 25 when there is no habit', () {
      expect(_plan(habits: const []).plannedMinutes, 25);
    });
  });

  test('small step is always 5 minutes', () {
    expect(SessionPlan.smallStepMinutes, 5);
  });
}
