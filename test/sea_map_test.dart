// 5.5 Bản đồ biển: regions per goal, discovery points per habit, progress by days done
// (spec 005 FR-001–FR-003, ADR-0010).
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/mascot_species.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/sea_map.dart';

const Goal _math = Goal(id: 'g1', title: 'Qua môn Toán', reason: '');
const Goal _english = Goal(id: 'g2', title: 'IELTS 7.0', reason: '');

Habit _habit(String id, String goalId, {int sortOrder = 0, bool archived = false}) => Habit(
  id: id,
  goalId: goalId,
  name: 'Thói quen $id',
  minMinutesPerDay: 15,
  sortOrder: sortOrder,
  archived: archived,
);

SeaMapData _build({
  List<Goal> goals = const [_math, _english],
  required List<Habit> habits,
  Map<String, int> days = const {},
  String? latest,
}) => SeaMap.build(goals: goals, habits: habits, daysDoneByHabit: days, latestHabitId: latest);

void main() {
  test('one region per goal, in goal order, terrain cycling coral, ice, deep, home', () {
    final goals = [for (var i = 0; i < 5; i++) Goal(id: 'g$i', title: 'Mục tiêu $i', reason: '')];
    final map = _build(goals: goals, habits: const []);

    expect(map.regions.map((r) => r.goal.id), ['g0', 'g1', 'g2', 'g3', 'g4']);
    expect(map.regions.map((r) => r.place), [
      SeaPlace.coral,
      SeaPlace.ice,
      SeaPlace.deep,
      SeaPlace.home,
      SeaPlace.coral,
    ]);
  });

  test('each habit of the goal is a point, archived ones too, ordered by sortOrder', () {
    final map = _build(
      habits: [
        _habit('b', 'g1', sortOrder: 2),
        _habit('a', 'g1', sortOrder: 1),
        _habit('old', 'g1', sortOrder: 3, archived: true),
        _habit('x', 'g2'),
      ],
    );

    final math = map.regions.first;
    expect(math.points.map((p) => p.habit.id), ['a', 'b', 'old']);
    expect(math.points.map((p) => p.kind), [
      PointKind.fishCave,
      PointKind.shipwreck,
      PointKind.kelpGarden,
    ]);
    expect(map.regions.last.points.single.habit.id, 'x');
  });

  test('a point is hidden until done once, then shows n/66 and clears with the days', () {
    final map = _build(habits: [_habit('a', 'g1'), _habit('b', 'g1')], days: {'a': 30});
    final points = map.regions.first.points;

    expect(points[0].discovered, isTrue);
    expect(points[0].daysDone, 30);
    expect(points[0].progress, closeTo(30 / 66, 1e-9));
    expect(points[1].discovered, isFalse);
    expect(points[1].progress, 0);
  });

  test('region percentage is the mean of points capped at 66 days (66 + 0 = 50%)', () {
    final map = _build(
      habits: [_habit('a', 'g1'), _habit('b', 'g1'), _habit('c', 'g2')],
      days: {'a': 120, 'b': 0, 'c': 33},
    );

    expect(map.regions.first.progress, closeTo(0.5, 1e-9), reason: 'Days above 66 do not count');
    expect(map.regions.last.progress, closeTo(0.5, 1e-9));
    expect(map.progress, closeTo((66 + 0 + 33) / (66 * 3), 1e-9));
  });

  test('a goal without habits is an empty region at 0%; no points means 0% overall', () {
    final map = _build(habits: const []);
    expect(map.regions.first.points, isEmpty);
    expect(map.regions.first.progress, 0);
    expect(map.progress, 0);
  });

  test('milestones: hidden, found, 7 Khởi động, 21 Bền bỉ, 40 Vững vàng, 66 Thành thói quen', () {
    expect(SeaMap.stageFor(0), JourneyStage.hidden);
    expect(SeaMap.stageFor(1), JourneyStage.found);
    expect(SeaMap.stageFor(6), JourneyStage.found);
    expect(SeaMap.stageFor(7), JourneyStage.warmUp);
    expect(SeaMap.stageFor(21), JourneyStage.steady);
    expect(SeaMap.stageFor(40), JourneyStage.solid);
    expect(SeaMap.stageFor(65), JourneyStage.solid);
    expect(SeaMap.stageFor(66), JourneyStage.formed);
    expect(SeaMap.stageFor(200), JourneyStage.formed);
  });

  test('Gret stands in the region of the latest habit, else the first region', () {
    final habits = [_habit('a', 'g1'), _habit('x', 'g2')];
    expect(_build(habits: habits, latest: 'x').gretGoalId, 'g2');
    expect(_build(habits: habits, latest: 'gone').gretGoalId, 'g1');
    expect(_build(habits: habits).gretGoalId, 'g1');
    expect(_build(goals: const [], habits: const []).gretGoalId, isNull);
  });

  test('regionOf finds the region of a goal', () {
    final map = _build(habits: const []);
    expect(map.regionOf('g2')?.place, SeaPlace.ice);
    expect(map.regionOf('nope'), isNull);
  });
}
