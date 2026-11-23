// 5.3 Gret và biển sống: sea clarity rule (spec 003 FR-001…FR-005, data-model.md).
// Pure function over plain values so it can be unit-tested without Hive. Nothing is stored: the
// value is recomputed from sessions, distraction events and the habits due each day.
import 'dart:math' as math;

import 'date_utils.dart';

/// Clarity of yesterday (end of day) and of today (live), both in 0–100.
class SeaClarityResult {
  const SeaClarityResult({required this.yesterday, required this.today});

  final double yesterday;
  final double today;
}

class SeaClarity {
  SeaClarity._();

  /// Clarity of a user with no history.
  static const double start = 70;

  /// Weight of the previous value in the daily moving average.
  static const double decay = 0.7;

  /// Points a perfect day adds on top of `previous × decay`.
  static const double gain = 30;

  /// Removed from a past day's score for each distraction.
  static const double distractionDayPenalty = 0.1;

  /// Points removed at once for each distraction today.
  static const double distractionLivePenalty = 5;

  /// Target when nothing was due but the user still studied.
  static const int fallbackTargetMinutes = 25;

  /// Days replayed before today; older days cannot change the result (0.7^60 ≈ 0).
  static const int windowDays = 60;

  /// Score of one day in 0–1: share of the target minutes studied, minus 0.1 per distraction.
  static double dayScore({
    required int studyMinutes,
    required int targetMinutes,
    required int distractions,
  }) {
    final target = targetMinutes > 0 ? targetMinutes : fallbackTargetMinutes;
    final reached = math.min(1.0, studyMinutes / target);
    return (reached - distractionDayPenalty * distractions).clamp(0.0, 1.0);
  }

  /// Clarity after a day with [score], starting from [previous].
  static double next(double previous, double score) =>
      (previous * decay + gain * score).clamp(0.0, 100.0);

  /// Replays the last [windowDays] days, then applies today's live rule:
  /// `max(y, next(y, scoreSoFar)) − 5 × distractions today`, kept within 0–100.
  ///
  /// [studyMinutesByDay] (minutes credited to habits: ticks, 2-minute versions, focus sessions)
  /// and [distractionsByDay] use date-only keys. [liveFocusMinutes] adds the
  /// running (not yet saved) session to today.
  static SeaClarityResult compute({
    required Map<DateTime, int> studyMinutesByDay,
    required Map<DateTime, int> distractionsByDay,
    required int Function(DateTime day) targetMinutesFor,
    required DateTime today,
    int liveFocusMinutes = 0,
  }) {
    final day0 = dateOnly(today);
    var value = start;

    for (var offset = windowDays; offset >= 1; offset--) {
      final day = addDays(day0, -offset);
      final focus = studyMinutesByDay[day] ?? 0;
      final distractions = distractionsByDay[day] ?? 0;
      final target = targetMinutesFor(day);
      // Rest day: nothing planned and nothing happened.
      if (target == 0 && focus == 0 && distractions == 0) continue;
      value = next(
        value,
        dayScore(studyMinutes: focus, targetMinutes: target, distractions: distractions),
      );
    }

    final yesterday = value;
    final todayFocus = (studyMinutesByDay[day0] ?? 0) + liveFocusMinutes;
    final todayTarget = targetMinutesFor(day0);
    final scoreSoFar = todayFocus == 0
        ? 0.0
        : dayScore(studyMinutes: todayFocus, targetMinutes: todayTarget, distractions: 0);
    final todayDistractions = distractionsByDay[day0] ?? 0;
    final todayValue =
        math.max(yesterday, next(yesterday, scoreSoFar)) -
        distractionLivePenalty * todayDistractions;

    return SeaClarityResult(yesterday: yesterday, today: todayValue.clamp(0.0, 100.0));
  }
}
