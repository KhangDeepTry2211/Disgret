// 5.3 Gret và biển sống: providers that feed the sea clarity rule with real data
// (spec 003, research R1–R3, R7). Widgets read seaStateProvider / clarityGainProvider only.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/date_utils.dart';
import '../data/habit_schedule.dart';
import '../data/mascot_mood.dart';
import '../data/models/event.dart';
import '../data/models/habit.dart';
import '../data/models/habit_log.dart';
import '../data/sea_clarity.dart';
import '../data/sea_time.dart';
import 'app_providers.dart';
import 'focus_session_provider.dart';
import 'gret_emote_provider.dart';

/// What the sea shows right now.
class SeaState {
  const SeaState({required this.clarity, required this.mood});

  /// 0–100.
  final double clarity;
  final MascotMood mood;

  ClarityLevel get level => ClarityLevel.of(clarity);

  /// Whole percent for display.
  int get percent => clarity.round();
}

/// Plain per-day inputs of [SeaClarity.compute], built once from habits, habit logs and events
/// (spec 003 FR-003, research R1–R3).
class SeaInputs {
  const SeaInputs({
    required this.studyMinutesByDay,
    required this.distractionsByDay,
    required this.targetByDay,
  });

  /// Minutes credited to habits each day: a tick counts the habit's full minimum, a 2-minute
  /// version half of it, focus sessions their real minutes; each habit is capped at its minimum.
  final Map<DateTime, int> studyMinutesByDay;
  final Map<DateTime, int> distractionsByDay;

  /// Sum of the minimum minutes of habits planned each day of the replay window.
  final Map<DateTime, int> targetByDay;

  /// Target of one day (0 outside the replay window).
  int targetMinutesFor(DateTime day) => targetByDay[dateOnly(day)] ?? 0;

  /// Rules per habit and day:
  /// - a day off (freeze) removes the habit from that day;
  /// - weekly-by-count habits are planned only on the days they were done;
  /// - archived habits count for past days (they were planned then) but not for [today];
  /// - a habit studied on a day it was not planned adds its minutes without a target.
  /// [excludeLogId] leaves one log out (the summary's "without this session" value).
  factory SeaInputs.from({
    required List<Habit> habits,
    required Iterable<HabitLog> logs,
    required Iterable<Event> events,
    required DateTime today,
    String? excludeLogId,
  }) {
    final todayKey = dateOnly(today);
    final logsByHabitDay = <String, List<HabitLog>>{};
    for (final log in logs) {
      if (log.id == excludeLogId) continue;
      logsByHabitDay.putIfAbsent('${log.habitId}|${dateKey(log.date)}', () => []).add(log);
    }

    final study = <DateTime, int>{};
    final target = <DateTime, int>{};
    for (var offset = SeaClarity.windowDays; offset >= 0; offset--) {
      final day = addDays(todayKey, -offset);
      var dayTarget = 0;
      var dayStudy = 0;
      for (final habit in habits) {
        if (habit.archived && !day.isBefore(todayKey)) continue;
        final dayLogs = logsByHabitDay['${habit.id}|${dateKey(day)}'] ?? const <HabitLog>[];
        if (dayLogs.any((log) => log.source == HabitLogSource.freeze)) continue;
        final credited = _credited(habit, dayLogs);
        final planned = habit.isWeeklyByCount
            ? credited > 0 && HabitSchedule.isActiveOn(habit, day)
            : HabitSchedule.isScheduledOn(habit, day);
        if (planned) dayTarget += habit.minMinutesPerDay;
        dayStudy += credited;
      }
      if (dayTarget > 0) target[day] = dayTarget;
      if (dayStudy > 0) study[day] = dayStudy;
    }

    final distractions = <DateTime, int>{};
    for (final event in events) {
      if (event.type != EventType.sessionDistracted) continue;
      final day = dateOnly(event.time);
      distractions[day] = (distractions[day] ?? 0) + 1;
    }

    return SeaInputs(
      studyMinutesByDay: study,
      distractionsByDay: distractions,
      targetByDay: target,
    );
  }

  /// Minutes one habit earns on one day, capped at its minimum.
  static int _credited(Habit habit, List<HabitLog> dayLogs) {
    final minimum = habit.minMinutesPerDay;
    var minutes = 0;
    for (final log in dayLogs) {
      minutes += switch (log.source) {
        HabitLogSource.manual => minimum,
        HabitLogSource.minimal => minimum ~/ 2,
        HabitLogSource.focus => log.minutes,
        HabitLogSource.freeze || HabitLogSource.skip => 0,
      };
    }
    return minutes.clamp(0, minimum);
  }

  SeaClarityResult compute(
    DateTime today, {
    int liveFocusMinutes = 0,
    Map<DateTime, int>? distractions,
  }) => SeaClarity.compute(
    studyMinutesByDay: studyMinutesByDay,
    distractionsByDay: distractions ?? distractionsByDay,
    targetMinutesFor: targetMinutesFor,
    today: today,
    liveFocusMinutes: liveFocusMinutes,
  );
}

/// The parts of the focus session that change the sea; selecting them avoids recomputing on
/// every clock tick.
typedef _SessionSlice = ({FocusPhase phase, bool onBreak, int distractions, int focusedMinutes});

_SessionSlice _slice(FocusSessionState s) => (
  phase: s.phase,
  onBreak: s.breakRemaining != null,
  distractions: s.distractionCount,
  focusedMinutes: s.focused.inMinutes,
);

/// Habits, habit logs and events, re-read whenever logs change (a saved session records a focus
/// log), today changes, or the running session gains a distraction.
final seaInputsProvider = Provider<SeaInputs>((ref) {
  ref.watch(focusSessionProvider.select((s) => (s.distractionCount, s.phase)));
  return SeaInputs.from(
    habits: ref.watch(allHabitsProvider),
    logs: ref.watch(habitLogsProvider),
    events: _readEvents(ref),
    today: ref.watch(todayProvider),
  );
});

/// Events, or none when a stored event cannot be read: a broken record must not take Hôm nay
/// down (the statistics screen reports it instead).
List<Event> _readEvents(Ref ref) {
  try {
    return ref.read(eventRepositoryProvider).getAll();
  } on Object catch (error) {
    debugPrint('Sea clarity: events unreadable, ignoring distractions ($error)');
    return const [];
  }
}

/// Clarity and Gret's mood for Hôm nay and the focus session (spec FR-001…FR-006).
final seaStateProvider = Provider<SeaState>((ref) {
  final inputs = ref.watch(seaInputsProvider);
  final today = ref.watch(todayProvider);
  final session = ref.watch(focusSessionProvider.select(_slice));
  final isRunning = session.phase == FocusPhase.running;
  // Only a running session is unsaved for sure; a finished one may already be in the repository.
  final result = inputs.compute(today, liveFocusMinutes: isRunning ? session.focusedMinutes : 0);
  // A short emote (spec 018) shows over the mood of the sea; during a session Gret stays
  // focused, except for the proud return from the intervention screen.
  final emote = ref.watch(gretEmoteProvider);
  final showEmote = emote != null && (!isRunning || emote == MascotMood.proud);
  // Late at night Gret sleeps by its house, outside a session (spec 019).
  final asleep = !isRunning && SeaTime.isLateNight(ref.watch(clockProvider)());
  return SeaState(
    clarity: result.today,
    mood: showEmote
        ? emote
        : asleep
        ? MascotMood.sleeping
        : moodFor(clarity: result.today, isSessionRunning: isRunning, isOnBreak: session.onBreak),
  );
});

/// Today's clarity with and without the finished session (research R7); null when no session
/// has just finished. The same before and after the session is saved: its focus log is left out
/// and its minutes are added back as live minutes.
final _finishedSessionSeaProvider = Provider<({double withSession, double withoutSession})?>((ref) {
  final session = ref.watch(focusSessionProvider);
  if (session.phase != FocusPhase.finished) return null;
  final today = ref.watch(todayProvider);
  final sessionId = ref.read(focusSessionProvider.notifier).sessionId;
  final inputs = SeaInputs.from(
    habits: ref.watch(allHabitsProvider),
    logs: ref.watch(habitLogsProvider),
    events: _readEvents(ref),
    today: today,
    excludeLogId: sessionId == null ? null : 'focus_$sessionId',
  );
  final withSession = inputs.compute(today, liveFocusMinutes: session.focused.inMinutes).today;

  final todayKey = dateOnly(today);
  final withoutDistractions = Map<DateTime, int>.of(inputs.distractionsByDay);
  final todayCount = withoutDistractions[todayKey] ?? 0;
  withoutDistractions[todayKey] = (todayCount - session.distractionCount).clamp(0, todayCount);
  final withoutSession = inputs.compute(today, distractions: withoutDistractions).today;
  return (withSession: withSession, withoutSession: withoutSession);
});

/// Clarity points the finished session added today (summary "+N%", research R7). Same value
/// before and after the session is saved; 0 when there is no finished session.
final clarityGainProvider = Provider<int>((ref) {
  final sea = ref.watch(_finishedSessionSeaProvider);
  if (sea == null) return 0;
  final gain = (sea.withSession - sea.withoutSession).round();
  return gain > 0 ? gain : 0;
});

/// The sea right after the finished session, saved or not (summary, spec 003 US4).
final clarityAfterSessionProvider = Provider<double>(
  (ref) =>
      ref.watch(_finishedSessionSeaProvider)?.withSession ?? ref.watch(seaStateProvider).clarity,
);
