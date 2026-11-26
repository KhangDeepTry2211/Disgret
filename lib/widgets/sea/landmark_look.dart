// 5.5 Bản đồ biển (spec 012): which SVG layers draw a habit's landmark at its stage. Every layer
// shares one 120×100 canvas (LandmarkLook.canvas), so the growth layers sit around any landmark.
import 'dart:ui' show Size;

import '../../data/sea_map.dart';

abstract final class LandmarkLook {
  static const String _folder = 'assets/map';
  static const Size canvas = Size(120, 100);

  /// A habit never done: a "?" buoy.
  static const String buoy = '$_folder/buoy.svg';

  /// Growth layers: 7 days seaweed and small corals, 21 a school of fish, 40 a sea creature,
  /// 66 a flag with sparkles (ADR-0010 milestones).
  static const String kelp = '$_folder/growth_kelp.svg';
  static const String fish = '$_folder/growth_fish.svg';
  static const String creature = '$_folder/growth_creature.svg';
  static const String flag = '$_folder/growth_flag.svg';

  static String base(PointKind kind) => switch (kind) {
    PointKind.fishCave => '$_folder/fish_cave.svg',
    PointKind.shipwreck => '$_folder/shipwreck.svg',
    PointKind.kelpGarden => '$_folder/kelp_garden.svg',
    PointKind.treasure => '$_folder/treasure.svg',
    PointKind.coralTemple => '$_folder/coral_temple.svg',
    PointKind.oldAnchor => '$_folder/old_anchor.svg',
  };

  /// Layers from back to front.
  static List<String> layers(PointKind kind, JourneyStage stage) {
    if (stage == JourneyStage.hidden) return const [buoy];
    bool reached(JourneyStage milestone) => stage.index >= milestone.index;
    return [
      if (reached(JourneyStage.warmUp)) kelp,
      base(kind),
      if (reached(JourneyStage.steady)) fish,
      if (reached(JourneyStage.solid)) creature,
      if (reached(JourneyStage.formed)) flag,
    ];
  }
}
