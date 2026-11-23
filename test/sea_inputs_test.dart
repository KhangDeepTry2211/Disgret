// 5.3 Unit tests for building the sea clarity inputs from stored data (spec 003 FR-003,
// research R1–R3): habit logs give credited minutes per day, distraction events give
// distractions, schedules give the target.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/date_utils.dart';
import 'package:focus_app/data/models/event.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/habit_log.dart';
import 'package:focus_app/providers/sea_providers.dart';

final DateTime _today = DateTime(2026, 11, 23);
DateTime _ago(int days) => addDays(_today, -days);

final Habit _study = Habit(
  id: 'h1',
  goalId: 'g',
  name: 'Ôn bài',
  minMinutesPerDay: 30,
  startDate: _ago(30),
);
final Habit _run = Habit(
  id: 'h2',
  goalId: 'g',
  name: 'Chạy bộ',
  minMinutesPerDay: 20,
  repeat: HabitRepeat.weekly,
  weekdays: [_today.weekday],
  startDate: _ago(30),
);

int _nextId = 0;
HabitLog _log(Habit habit, DateTime day, HabitLogSource source, {int minutes = 0}) =>
    HabitLog(id: 'l${_nextId++}', habitId: habit.id, date: day, source: source, minutes: minutes);

Event _distraction(DateTime time) =>
    Event(id: 'e${time.microsecondsSinceEpoch}', type: EventType.sessionDistracted, time: time);

SeaInputs _inputs({
  List<Habit>? habits,
  List<HabitLog> logs = const [],
  List<Event> events = const [],
}) => SeaInputs.from(habits: habits ?? [_study, _run], logs: logs, events: events, today: _today);

void main() {
  test('target adds up the minimum minutes of habits scheduled that day', () {
    final inputs = _inputs();
    expect(inputs.targetMinutesFor(_today), 30 + 20);
    expect(inputs.targetMinutesFor(_ago(1)), 30);
    expect(inputs.targetMinutesFor(_ago(40)), 0); // before the habits started
  });

  test('a habit ticked as done counts its full minimum, a 2-minute version half', () {
    final inputs = _inputs(
      logs: [
        _log(_study, _ago(1), HabitLogSource.manual),
        _log(_study, _ago(2), HabitLogSource.minimal),
      ],
    );
    expect(inputs.studyMinutesByDay[_ago(1)], 30);
    expect(inputs.studyMinutesByDay[_ago(2)], 15);
  });

  test('focus minutes count as studied, capped at the habit minimum', () {
    final inputs = _inputs(
      logs: [
        _log(_study, _ago(1), HabitLogSource.focus, minutes: 10),
        _log(_study, _ago(1), HabitLogSource.focus, minutes: 12),
        _log(_study, _ago(2), HabitLogSource.focus, minutes: 90),
      ],
    );
    expect(inputs.studyMinutesByDay[_ago(1)], 22);
    expect(inputs.studyMinutesByDay[_ago(2)], 30);
  });

  test('a day off (freeze) removes that habit from the day; a skip counts as not done', () {
    final inputs = _inputs(
      logs: [
        _log(_study, _ago(1), HabitLogSource.freeze),
        _log(_study, _ago(2), HabitLogSource.skip),
      ],
    );
    expect(inputs.targetMinutesFor(_ago(1)), 0);
    expect(inputs.targetMinutesFor(_ago(2)), 30);
    expect(inputs.studyMinutesByDay[_ago(2)] ?? 0, 0);
  });

  test('weekly-by-count habits only count on days they were done', () {
    final gym = Habit(
      id: 'h3',
      goalId: 'g',
      name: 'Gym',
      minMinutesPerDay: 40,
      repeat: HabitRepeat.weekly,
      daysPerWeek: 3,
      startDate: _ago(30),
    );
    final inputs = _inputs(habits: [gym], logs: [_log(gym, _ago(1), HabitLogSource.manual)]);
    expect(inputs.targetMinutesFor(_ago(1)), 40);
    expect(inputs.studyMinutesByDay[_ago(1)], 40);
    expect(inputs.targetMinutesFor(_ago(2)), 0);
  });

  test('archived habits count for past days only', () {
    final old = Habit(
      id: 'h4',
      goalId: 'g',
      name: 'Cũ',
      minMinutesPerDay: 15,
      startDate: _ago(30),
      archived: true,
    );
    final inputs = _inputs(habits: [old]);
    expect(inputs.targetMinutesFor(_ago(1)), 15);
    expect(inputs.targetMinutesFor(_today), 0);
  });

  test('focus on a habit that was not planned that day still counts as study', () {
    final inputs = _inputs(
      habits: [_run],
      logs: [_log(_run, _ago(1), HabitLogSource.focus, minutes: 25)],
    );
    expect(inputs.targetMinutesFor(_ago(1)), 0);
    expect(inputs.studyMinutesByDay[_ago(1)], 20); // capped at the habit minimum
  });

  test('only session_distracted events count as distractions', () {
    final inputs = _inputs(
      events: [
        _distraction(_today.add(const Duration(hours: 10))),
        _distraction(_today.add(const Duration(hours: 11))),
        Event(id: 'x', type: EventType.interventionShown, time: _today),
      ],
    );
    expect(inputs.distractionsByDay[_today], 2);
  });
}
