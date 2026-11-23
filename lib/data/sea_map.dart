// 5.5 Bản đồ biển: one sea region per goal, one discovery point per habit, explored by the days the
// habit was done (spec 005, ADR-0010). Pure functions over existing data: nothing is stored, and
// progress never goes down with time alone.
import 'dart:math' as math;

import 'mascot_species.dart';
import 'models/goal.dart';
import 'models/habit.dart';

/// What a habit's point looks like once discovered. Assigned in habit order inside the goal.
enum PointKind { fishCave, shipwreck, kelpGarden, treasure, coralTemple, oldAnchor }

/// The 66-day journey of one habit (ADR-0010).
enum JourneyStage {
  /// Never done: a "?" in the fog.
  hidden,

  /// Done at least once.
  found,

  /// 7 days: "Khởi động".
  warmUp,

  /// 21 days: "Bền bỉ".
  steady,

  /// 40 days: "Vững vàng".
  solid,

  /// 66 days: "Thành thói quen", fully explored.
  formed,
}

class MapPoint {
  const MapPoint({required this.habit, required this.kind, required this.daysDone});

  final Habit habit;
  final PointKind kind;
  final int daysDone;

  bool get discovered => daysDone > 0;

  /// 0–1: how much fog around the point has cleared.
  double get progress => math.min(daysDone, SeaMap.fullDays) / SeaMap.fullDays;

  JourneyStage get stage => SeaMap.stageFor(daysDone);
}

class MapRegion {
  const MapRegion({required this.goal, required this.place, required this.points});

  final Goal goal;
  final SeaPlace place;
  final List<MapPoint> points;

  /// 0–1: the mean progress of its points.
  double get progress => SeaMap.progressOf(points);
}

class SeaMapData {
  const SeaMapData({required this.regions, required this.gretGoalId});

  final List<MapRegion> regions;

  /// The goal whose region Gret stands in; null without goals.
  final String? gretGoalId;

  /// 0–1 over every point of the map.
  double get progress => SeaMap.progressOf([for (final region in regions) ...region.points]);

  MapRegion? regionOf(String goalId) {
    for (final region in regions) {
      if (region.goal.id == goalId) return region;
    }
    return null;
  }
}

class SeaMap {
  SeaMap._();

  /// Days done for a point to be fully explored (Lally et al., 2010).
  static const int fullDays = 66;

  /// Terrain of the regions, in goal order.
  static const List<SeaPlace> terrains = [
    SeaPlace.coral,
    SeaPlace.ice,
    SeaPlace.deep,
    SeaPlace.home,
  ];

  static JourneyStage stageFor(int daysDone) {
    if (daysDone <= 0) return JourneyStage.hidden;
    if (daysDone < 7) return JourneyStage.found;
    if (daysDone < 21) return JourneyStage.warmUp;
    if (daysDone < 40) return JourneyStage.steady;
    if (daysDone < fullDays) return JourneyStage.solid;
    return JourneyStage.formed;
  }

  static double progressOf(List<MapPoint> points) {
    if (points.isEmpty) return 0;
    final explored = points.fold(0.0, (sum, point) => sum + point.progress);
    return explored / points.length;
  }

  /// [habits] include archived ones (their history is kept); [daysDoneByHabit] counts each habit's
  /// completed days; [latestHabitId] is the habit studied most recently (or the running session's).
  static SeaMapData build({
    required List<Goal> goals,
    required List<Habit> habits,
    required Map<String, int> daysDoneByHabit,
    String? latestHabitId,
  }) {
    final regions = <MapRegion>[];
    for (var i = 0; i < goals.length; i++) {
      final goal = goals[i];
      final own = habits.where((habit) => habit.goalId == goal.id).toList()
        ..sort((a, b) {
          final byOrder = a.sortOrder.compareTo(b.sortOrder);
          return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
        });
      regions.add(
        MapRegion(
          goal: goal,
          place: terrains[i % terrains.length],
          points: [
            for (var j = 0; j < own.length; j++)
              MapPoint(
                habit: own[j],
                kind: PointKind.values[j % PointKind.values.length],
                daysDone: daysDoneByHabit[own[j].id] ?? 0,
              ),
          ],
        ),
      );
    }

    String? gretGoalId;
    for (final habit in habits) {
      if (habit.id == latestHabitId && regions.any((region) => region.goal.id == habit.goalId)) {
        gretGoalId = habit.goalId;
      }
    }
    gretGoalId ??= regions.isEmpty ? null : regions.first.goal.id;
    return SeaMapData(regions: regions, gretGoalId: gretGoalId);
  }
}
