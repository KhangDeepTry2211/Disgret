// 5.5 Bản đồ biển (spec 012 FR-001, FR-003): where an island's scenery and the open sea's life go.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/mascot_species.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/sea_map.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/sea/sea_scenery.dart';
import 'package:focus_app/widgets/sea/sea_world.dart';

MapRegion _region(String id, SeaPlace place, int habits) => MapRegion(
  goal: Goal(id: id, title: 'Mục tiêu $id', reason: 'Vì'),
  place: place,
  points: [
    for (var i = 0; i < habits; i++)
      MapPoint(
        habit: Habit(
          id: '$id-h$i',
          goalId: id,
          name: 'Thói quen $i',
          minMinutesPerDay: 15,
          startDate: DateTime(2026, 11),
        ),
        kind: PointKind.values[i % PointKind.values.length],
        daysDone: i * 10,
      ),
  ],
);

void main() {
  final layout = SeaWorldLayout.of(
    SeaMapData(
      regions: [
        _region('g1', SeaPlace.coral, 2),
        _region('g2', SeaPlace.ice, 4),
        _region('g3', SeaPlace.deep, 1),
        _region('g4', SeaPlace.home, 6),
      ],
      gretGoalId: 'g1',
    ),
  );
  final known = layout.known.toList();
  Set<SceneryKind> kindsOf(IslandLayout island) => {
    for (final item in IslandScenery.of(island)) item.kind,
  };

  test('the same island gets the same scenery every time', () {
    for (final island in layout.islands) {
      final first = IslandScenery.of(island);
      final again = IslandScenery.of(island);
      expect(
        [for (final item in again) (item.kind, item.at)],
        [for (final item in first) (item.kind, item.at)],
      );
    }
  });

  test('each sea has its own scenery; unknown seas have none', () {
    expect(kindsOf(known[0]), containsAll([SceneryKind.coral, SceneryKind.palm]));
    expect(kindsOf(known[1]), containsAll([SceneryKind.iceberg, SceneryKind.snowMound]));
    expect(kindsOf(known[2]), containsAll([SceneryKind.glowCoral, SceneryKind.vent]));
    expect(kindsOf(known[3]), containsAll([SceneryKind.hut, SceneryKind.lighthouse]));
    for (final island in layout.islands.where((island) => island.region == null)) {
      expect(IslandScenery.of(island), isEmpty);
    }
  });

  test('scenery keeps clear of every landmark and of Gret', () {
    for (final island in known) {
      for (final item in IslandScenery.of(island)) {
        for (final spot in [...island.points, island.gretSpot]) {
          expect(
            (item.at - spot).distance,
            greaterThanOrEqualTo(AppSeaMap.sceneryClearance),
            reason: '${item.kind} at ${item.at} on ${island.region!.goal.id}',
          );
        }
      }
    }
  });

  test('land scenery stays on the island, reef pieces on the reef ring', () {
    for (final island in known) {
      final items = IslandScenery.of(island);
      expect(items.where((item) => item.reef), isNotEmpty);
      for (final item in items) {
        if (item.reef) {
          expect(island.outline(scale: 1.14).contains(item.at), isTrue, reason: '${item.kind}');
          expect(island.outline(scale: 0.98).contains(item.at), isFalse, reason: '${item.kind}');
        } else {
          expect(island.outline().contains(item.at), isTrue, reason: '${item.kind}');
        }
      }
    }
  });

  test('sea life swims in open water, never on an island', () {
    final life = OpenSea.of(layout);
    expect(life, isNotEmpty);
    expect(life.map((item) => item.kind).toSet(), contains(SceneryKind.fishSchool));
    for (final item in life) {
      for (final island in layout.islands) {
        expect(island.outline(scale: 1.14).contains(item.at), isFalse, reason: '${item.kind}');
      }
      expect((item.at - known[0].gretSpot).distance, greaterThan(AppSeaMap.sceneryClearance));
    }
    expect(
      [for (final item in OpenSea.of(layout)) (item.kind, item.at)],
      [for (final item in life) (item.kind, item.at)],
    );
  });

  test('bought pearl seas are islands after the goals, before the unknown seas (spec 014)', () {
    final world = SeaWorldLayout.of(
      SeaMapData(regions: [_region('g1', SeaPlace.coral, 3)], gretGoalId: 'g1'),
      boughtSeas: const [SeaPlace.kelp, SeaPlace.volcano, SeaPlace.sunken, SeaPlace.sunset],
    );
    final islands = world.islands;
    expect(islands.first.region?.goal.id, 'g1');
    expect(
      [for (final island in islands.skip(1).take(4)) island.sea],
      [SeaPlace.kelp, SeaPlace.volcano, SeaPlace.sunken, SeaPlace.sunset],
    );
    expect(islands.skip(5).every((island) => island.region == null && island.sea == null), isTrue);
    expect(islands.skip(5), hasLength(AppSeaMap.unknownSeas));
    expect(world.bought, hasLength(4));

    for (var i = 0; i < islands.length; i++) {
      for (var j = i + 1; j < islands.length; j++) {
        expect(islands[i].bounds.overlaps(islands[j].bounds), isFalse, reason: '$i and $j');
      }
    }

    Set<SceneryKind> kinds(SeaPlace place) => {
      for (final item in IslandScenery.of(world.bought.firstWhere((i) => i.sea == place)))
        item.kind,
    };
    expect(kinds(SeaPlace.kelp), contains(SceneryKind.kelpTuft));
    expect(kinds(SeaPlace.volcano), contains(SceneryKind.cone));
    expect(kinds(SeaPlace.sunken), contains(SceneryKind.column));
    expect(kinds(SeaPlace.sunset), contains(SceneryKind.palm));
  });
}
