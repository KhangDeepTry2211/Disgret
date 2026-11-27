// 5.4 Góc của Gret: friends earned by studying (spec 018 user story 2, FR-002).
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/gret_corner_catalog.dart';
import 'package:focus_app/data/habit_science.dart';
import 'package:focus_app/data/mascot_species.dart';
import 'package:focus_app/data/models/event.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/habit_log.dart';
import 'package:focus_app/data/models/session.dart';
import 'package:focus_app/data/study_unlocks.dart';

void main() {
  const reminded = Habit(
    id: 'h1',
    goalId: 'g1',
    name: 'Ôn Toán',
    minMinutesPerDay: 5,
    reminderEnabled: true,
    reminderTime: '19:30',
  );
  const silent = Habit(id: 'h2', goalId: 'g1', name: 'Đọc', minMinutesPerDay: 5);

  Session session(String id, DateTime start, {String habitId = 'h1', int seconds = 600}) => Session(
    id: id,
    habitId: habitId,
    start: start,
    plannedMinutes: 25,
    focusedSeconds: seconds,
    distractionCount: 0,
  );

  HabitHistory doneFor(Habit habit, int days) => HabitHistory.of(habit, [
    for (var d = 0; d < days; d++)
      HabitLog(
        id: '${habit.id}-$d',
        habitId: habit.id,
        date: DateTime(2026, 11, 1).add(Duration(days: d)),
        minutes: 5,
        source: HabitLogSource.manual,
      ),
  ]);

  StudyFacts facts({
    List<Session> sessions = const [],
    List<Event> events = const [],
    List<HabitHistory> histories = const [],
  }) => StudyFacts.from(
    sessions: sessions,
    habits: const [reminded, silent],
    events: events,
    histories: histories,
  );

  group('on-time starts', () {
    test('a session 0 to 10 minutes after the reminder counts', () {
      final result = facts(
        sessions: [
          session('a', DateTime(2026, 11, 20, 19, 30)),
          session('b', DateTime(2026, 11, 21, 19, 40)),
        ],
      );
      expect(result.onTimeStarts, 2);
    });

    test('counts once per habit and day', () {
      final result = facts(
        sessions: [
          session('a', DateTime(2026, 11, 20, 19, 31)),
          session('b', DateTime(2026, 11, 20, 19, 35)),
          session('c', DateTime(2026, 11, 20, 19, 39)),
        ],
      );
      expect(result.onTimeStarts, 1);
    });

    test('not on time when late, early, without a reminder or for an unknown habit', () {
      final result = facts(
        sessions: [
          session('late', DateTime(2026, 11, 20, 19, 41)),
          session('early', DateTime(2026, 11, 21, 19, 29)),
          session('silent', DateTime(2026, 11, 22, 7, 0), habitId: 'h2'),
          session('gone', DateTime(2026, 11, 23, 19, 30), habitId: 'deleted'),
        ],
      );
      expect(result.onTimeStarts, 0);
    });
  });

  test('returns after an intervention count chose_study events', () {
    final result = facts(
      events: [
        Event(id: 'e1', type: EventType.choseStudy, time: DateTime(2026, 11, 20)),
        Event(id: 'e2', type: EventType.choseStudy, time: DateTime(2026, 11, 21)),
        Event(id: 'e3', type: EventType.choseBreak, time: DateTime(2026, 11, 21)),
      ],
    );
    expect(result.interventionReturns, 2);
  });

  test('focused hours add up every session', () {
    final result = facts(
      sessions: [
        session('a', DateTime(2026, 11, 20, 8), seconds: 3 * 3600),
        session('b', DateTime(2026, 11, 21, 8), seconds: 1800),
      ],
    );
    expect(result.focusedSeconds, 3 * 3600 + 1800);
    expect(result.progressOf(const Unlock.focusHours(10)), 3.5);
  });

  test('the best habit is the one with the most done days', () {
    final result = facts(histories: [doneFor(reminded, 12), doneFor(silent, 4)]);
    expect(result.bestHabitDays, 12);
    expect(result.reached(const Unlock.habitDays(21)), isFalse);
    expect(result.progressOf(const Unlock.habitDays(21)), 12);
  });

  test('reached compares each kind with its goal', () {
    const done = StudyFacts(
      onTimeStarts: 5,
      interventionReturns: 4,
      focusedSeconds: 10 * 3600,
      bestHabitDays: 66,
    );
    expect(done.reached(const Unlock.onTimeStarts(5)), isTrue);
    expect(done.reached(const Unlock.interventionReturns(5)), isFalse);
    expect(done.reached(const Unlock.focusHours(10)), isTrue);
    expect(done.reached(const Unlock.focusHours(30)), isFalse);
    expect(done.reached(const Unlock.habitDays(66)), isTrue);
    expect(done.reached(const Unlock.pearls(10)), isFalse);
  });

  group('catalog', () {
    MascotInfo of(MascotSpecies species) => GretCornerCatalog.mascotOf(species);

    test('the crab is called Bơ and still costs 300 pearls', () {
      expect(of(MascotSpecies.crab).name, 'Bơ');
      expect(of(MascotSpecies.crab).unlock.price, 300);
    });

    test('eight friends, six of them earned by studying', () {
      expect(GretCornerCatalog.mascots.map((mascot) => mascot.name), [
        'Gret',
        'Bơ',
        'Tép',
        'Phồng',
        'Mây',
        'Mochi',
        'Bông',
        'Bự',
      ]);
      expect(of(MascotSpecies.seahorse).unlock.kind, UnlockKind.onTimeStarts);
      expect(of(MascotSpecies.pufferfish).unlock.kind, UnlockKind.interventionReturns);
      expect(of(MascotSpecies.jellyfish).unlock.amount, 10);
      expect(of(MascotSpecies.octopus).unlock.kind, UnlockKind.focusHours);
      expect(of(MascotSpecies.octopus).unlock.amount, 30);
      expect(of(MascotSpecies.penguin).unlock.amount, 21);
      expect(of(MascotSpecies.whale).unlock.amount, 66);
      expect(GretCornerCatalog.mascots.where((mascot) => mascot.unlock.isStudy), hasLength(6));
    });
  });
}
