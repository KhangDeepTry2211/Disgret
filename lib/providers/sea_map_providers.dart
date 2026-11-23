// 5.5 Bản đồ biển: the map built from goals, habits and habit logs (spec 005, ADR-0010).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mascot_species.dart';
import '../data/models/habit_log.dart';
import '../data/sea_map.dart';
import 'app_providers.dart';
import 'focus_session_provider.dart';

/// Regions, points and Gret's place. Archived habits keep their point (their history is kept).
final seaMapProvider = Provider<SeaMapData>((ref) {
  final histories = ref.watch(allHabitHistoriesProvider);
  final running = ref.watch(
    focusSessionProvider.select((session) => session.isRunning ? session.habit?.id : null),
  );
  return SeaMap.build(
    goals: ref.watch(goalsProvider),
    habits: ref.watch(allHabitsProvider),
    daysDoneByHabit: {for (final history in histories) history.habit.id: history.doneDays.length},
    latestHabitId: running ?? _latestStudiedHabitId(ref.watch(habitLogsProvider)),
  );
});

/// The habit of the most recent log that counts as studying (not a day off or a skip).
String? _latestStudiedHabitId(List<HabitLog> logs) {
  HabitLog? latest;
  for (final log in logs) {
    final studied = switch (log.source) {
      HabitLogSource.manual || HabitLogSource.minimal || HabitLogSource.focus => true,
      HabitLogSource.freeze || HabitLogSource.skip => false,
    };
    if (studied && (latest == null || log.date.isAfter(latest.date))) latest = log;
  }
  return latest?.habitId;
}

/// The sea of the running (or just finished) session: the terrain of its habit's region
/// (spec 005 FR-005). Null without a session habit.
final sessionSeaPlaceProvider = Provider<SeaPlace?>((ref) {
  final goalId = ref.watch(focusSessionProvider.select((session) => session.habit?.goalId));
  if (goalId == null) return null;
  return ref.watch(seaMapProvider).regionOf(goalId)?.place;
});
