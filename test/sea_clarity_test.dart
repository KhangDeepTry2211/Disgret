// 5.3 Unit tests for the sea clarity rule (spec 003 FR-001…FR-005, data-model.md).
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/date_utils.dart';
import 'package:focus_app/data/sea_clarity.dart';

final DateTime _today = DateTime(2026, 11, 23);
DateTime _ago(int days) => addDays(_today, -days);

/// Every day asks for 25 minutes (one daily habit of 25 minutes).
int _daily25(DateTime day) => 25;

/// Nothing is ever scheduled.
int _nothing(DateTime day) => 0;

SeaClarityResult _compute({
  Map<DateTime, int> focus = const {},
  Map<DateTime, int> distractions = const {},
  int Function(DateTime day) target = _daily25,
  int liveFocusMinutes = 0,
}) {
  return SeaClarity.compute(
    studyMinutesByDay: focus,
    distractionsByDay: distractions,
    targetMinutesFor: target,
    today: _today,
    liveFocusMinutes: liveFocusMinutes,
  );
}

void main() {
  group('day score', () {
    test('full, partial and empty days', () {
      expect(SeaClarity.dayScore(studyMinutes: 25, targetMinutes: 25, distractions: 0), 1);
      expect(SeaClarity.dayScore(studyMinutes: 50, targetMinutes: 25, distractions: 0), 1);
      expect(SeaClarity.dayScore(studyMinutes: 10, targetMinutes: 25, distractions: 0), 0.4);
      expect(SeaClarity.dayScore(studyMinutes: 0, targetMinutes: 25, distractions: 0), 0);
    });

    test('each distraction removes 0.1, never below 0', () {
      expect(
        SeaClarity.dayScore(studyMinutes: 25, targetMinutes: 25, distractions: 3),
        closeTo(0.7, 1e-9),
      );
      expect(SeaClarity.dayScore(studyMinutes: 5, targetMinutes: 25, distractions: 5), 0);
    });

    test('a session on a day with nothing due is measured against 25 minutes', () {
      expect(SeaClarity.dayScore(studyMinutes: 25, targetMinutes: 0, distractions: 0), 1);
    });
  });

  test('a new user with no history starts at 70', () {
    final result = _compute(target: _nothing);
    expect(result.yesterday, 70);
    expect(result.today, 70);
  });

  test('rest days (nothing due, no session) keep the value', () {
    final withRest = _compute(focus: {_ago(5): 25}, target: _nothing);
    // One studied day 5 days ago, then 4 rest days: 70 × 0.7 + 30 = 79.
    expect(withRest.yesterday, closeTo(79, 1e-9));
  });

  test('a scheduled day without studying lowers the sea', () {
    final result = _compute(target: (day) => day == _ago(1) ? 25 : 0);
    expect(result.yesterday, closeTo(70 * 0.7, 1e-9));
  });

  test('three full days from about 40 reach at least 70 (SC-001)', () {
    // Scheduled only from 5 days ago: one empty day and one 5-minute day bring 70 down to ~40.
    int target(DateTime day) => day.isBefore(_ago(5)) ? 0 : 25;
    final low = _compute(focus: {_ago(4): 5}, target: (day) => day.isBefore(_ago(5)) ? 0 : 25);
    final lowAt = _compute(
      focus: {_ago(4): 5},
      target: (day) => day.isBefore(_ago(5)) || day.isAfter(_ago(4)) ? 0 : 25,
    );
    expect(lowAt.yesterday, inInclusiveRange(35, 45));
    expect(low.today, lessThan(40));

    final result = _compute(
      focus: {_ago(4): 5, _ago(3): 25, _ago(2): 25, _ago(1): 25},
      target: target,
    );
    expect(result.today, greaterThanOrEqualTo(70));
  });

  test('a day replay starting from 40 reaches 70 after three full days', () {
    var value = 40.0;
    for (var i = 0; i < 3; i++) {
      value = SeaClarity.next(value, 1);
    }
    expect(value, greaterThanOrEqualTo(70));
  });

  group('today', () {
    test('not studying yet never lowers today below yesterday', () {
      final result = _compute(focus: {_ago(1): 25});
      expect(result.today, result.yesterday);
    });

    test('studying today raises the value', () {
      final result = _compute(focus: {_ago(1): 10, _today: 25});
      expect(result.today, greaterThan(result.yesterday));
    });

    test('the running session counts as studying today', () {
      final saved = _compute(focus: {_today: 25});
      final live = _compute(liveFocusMinutes: 25);
      expect(live.today, saved.today);
    });

    test('each distraction today removes 5 points at once', () {
      final calm = _compute(focus: {_ago(1): 25});
      final distracted = _compute(focus: {_ago(1): 25}, distractions: {_today: 2});
      expect(distracted.today, closeTo(calm.today - 10, 1e-9));
    });

    test('three distractions in a good session do not turn a happy sea sad', () {
      final result = _compute(
        focus: {for (var i = 1; i <= 10; i++) _ago(i): 25, _today: 25},
        distractions: {_today: 3},
      );
      expect(result.today, greaterThanOrEqualTo(70));
    });
  });

  test('the value stays within 0 and 100', () {
    final high = _compute(focus: {for (var i = 0; i <= 60; i++) _ago(i): 100});
    expect(high.today, lessThanOrEqualTo(100));
    final low = _compute(distractions: {for (var i = 0; i <= 60; i++) _ago(i): 30});
    expect(low.today, 0);
    expect(low.yesterday, greaterThanOrEqualTo(0));
  });

  test('days older than the 60-day window are ignored', () {
    final old = _compute(focus: {_ago(200): 25}, target: _nothing);
    expect(old.today, 70);
  });

  test('gain of a session = clarity with it minus clarity without it', () {
    final withSession = _compute(focus: {_ago(1): 10, _today: 25});
    final without = _compute(focus: {_ago(1): 10});
    expect(withSession.today - without.today, greaterThan(0));
  });
}
