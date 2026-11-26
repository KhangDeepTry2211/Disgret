// 5.5 Bản đồ biển, full screen: one ocean where every goal is an island with a natural shape,
// unknown seas wait in the dark, and the darkness opens around discovered points as habits are
// done (spec 005, ADR-0010). Each island has a reef, a beach and inner land with its sea's
// scenery, and sea life swims around (spec 012). World coordinates are in logical pixels; the
// screen pans and zooms.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../data/mascot_species.dart';
import '../../data/sea_map.dart';
import '../../theme/app_theme.dart';
import 'sea_scenery.dart';

/// One island of the world: its region, outline, label anchor and points.
class IslandLayout {
  const IslandLayout({
    required this.region,
    required this.centre,
    required this.radiusX,
    required this.radiusY,
    required this.seed,
    required this.points,
    this.sea,
  });

  /// Null for a bought sea or an unknown sea waiting for a future goal.
  final MapRegion? region;

  /// A pearl sea Gret owns, shown as its own island (spec 014); null for goals and unknown seas.
  final SeaPlace? sea;

  /// The sea this island is drawn as; null for an unknown sea.
  SeaPlace? get place => region?.place ?? sea;
  final Offset centre;
  final double radiusX;
  final double radiusY;
  final int seed;

  /// Pin positions, in the order of [MapRegion.points].
  final List<Offset> points;

  Rect get bounds => Rect.fromCenter(center: centre, width: radiusX * 2.3, height: radiusY * 2.3);

  /// Where the name and exploration label sit: just above the island.
  Offset get labelAnchor => Offset(centre.dx, centre.dy - radiusY * 1.12);

  /// Where Gret stands on the island.
  Offset get gretSpot => Offset(centre.dx - radiusX * 0.78, centre.dy + radiusY * 0.5);

  /// The point of the outline (at [scale] of its size) in the direction [angle] from the centre.
  Offset edgeAt(double angle, double scale) {
    final wobble =
        1 +
        0.10 * math.sin(3 * angle + seed) +
        0.07 * math.sin(5 * angle + seed * 1.7) +
        0.04 * math.sin(9 * angle + seed * 2.3);
    return Offset(
      centre.dx + radiusX * scale * wobble * math.cos(angle),
      centre.dy + radiusY * scale * wobble * math.sin(angle),
    );
  }

  /// A closed outline that wobbles around an ellipse, different for every island.
  Path outline({double scale = 1}) {
    final path = Path();
    const steps = 64;
    for (var i = 0; i <= steps; i++) {
      final point = edgeAt(i / steps * 2 * math.pi, scale);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }
}

class SeaWorldLayout {
  const SeaWorldLayout._({required this.islands, required this.size});

  /// Known islands first (goal order), then the unknown seas.
  final List<IslandLayout> islands;
  final Size size;

  Iterable<IslandLayout> get known => islands.where((island) => island.region != null);

  /// Islands of the pearl seas Gret owns (spec 014).
  Iterable<IslandLayout> get bought => islands.where((island) => island.sea != null);

  IslandLayout? islandOf(String goalId) {
    for (final island in known) {
      if (island.region!.goal.id == goalId) return island;
    }
    return null;
  }

  /// Slots around the centre of the world, in the order islands appear. More goals than slots
  /// continue on a widening ring.
  static Offset _slot(int i) {
    const slots = [
      Offset(0, 0),
      Offset(1.05, 0.6),
      Offset(-1.0, 0.8),
      Offset(0.1, 1.55),
      Offset(-1.05, -0.75),
      Offset(1.15, -0.8),
      Offset(2.0, 1.4),
      Offset(-2.0, 0.05),
      Offset(0.95, 2.4),
      Offset(-1.05, 2.25),
      Offset(2.15, -0.1),
      Offset(-0.1, -1.6),
    ];
    if (i < slots.length) return slots[i];
    final ring = 3 + (i - slots.length) ~/ 8;
    final angle = (i - slots.length) % 8 / 8 * 2 * math.pi + ring;
    return Offset(math.cos(angle) * ring, math.sin(angle) * ring);
  }

  /// Goal islands first, then one island per bought pearl sea ([boughtSeas]), then the unknown
  /// seas.
  factory SeaWorldLayout.of(SeaMapData data, {List<SeaPlace> boughtSeas = const []}) {
    final raw = <IslandLayout>[];
    final count = data.regions.length + boughtSeas.length + AppSeaMap.unknownSeas;
    for (var i = 0; i < count; i++) {
      final region = i < data.regions.length ? data.regions[i] : null;
      final seaIndex = i - data.regions.length;
      final sea = seaIndex >= 0 && seaIndex < boughtSeas.length ? boughtSeas[seaIndex] : null;
      final unknown = region == null && sea == null;
      final slot = _slot(i);
      final centre = Offset(
        slot.dx * AppSeaMap.worldSpacing,
        slot.dy * AppSeaMap.worldSpacing * 0.85,
      );
      final pointCount = region?.points.length ?? 0;
      final rows = math.max(1, (pointCount / AppSeaMap.pointColumns).ceil());
      final radiusX = AppSeaMap.islandRadius;
      final radiusY = AppSeaMap.islandRadius * 0.62 + rows * AppSeaMap.islandRowGrowth;
      final innerWidth = radiusX * 1.2;
      final innerHeight = radiusY * 0.95;
      raw.add(
        IslandLayout(
          region: region,
          sea: sea,
          centre: centre,
          radiusX: unknown ? radiusX * 0.8 : radiusX,
          radiusY: unknown ? radiusY * 0.8 : radiusY,
          seed: i * 7 + 3,
          points: [
            for (var j = 0; j < pointCount; j++)
              Offset(
                centre.dx -
                    innerWidth / 2 +
                    (j % AppSeaMap.pointColumns + 0.5) * innerWidth / AppSeaMap.pointColumns +
                    ((j * 37) % 21 - 10),
                centre.dy -
                    innerHeight / 2 +
                    (j ~/ AppSeaMap.pointColumns + 0.6) * innerHeight / rows +
                    ((j * 53) % 15 - 7),
              ),
          ],
        ),
      );
    }

    // Shift everything so the world starts at (0, 0) with a margin of open sea.
    var bounds = raw.first.bounds;
    for (final island in raw.skip(1)) {
      bounds = bounds.expandToInclude(island.bounds);
    }
    bounds = bounds.inflate(AppSeaMap.worldMargin);
    final shift = -bounds.topLeft;
    return SeaWorldLayout._(
      size: bounds.size,
      islands: [
        for (final island in raw)
          IslandLayout(
            region: island.region,
            sea: island.sea,
            centre: island.centre + shift,
            radiusX: island.radiusX,
            radiusY: island.radiusY,
            seed: island.seed,
            points: [for (final point in island.points) point + shift],
          ),
      ],
    );
  }
}

/// Shallow water, beach and inner land of each sea (spec 012); unknown seas are a plain islet.
({Color shallow, Color beach, Color? inner}) _bands(SeaPlace? place) => switch (place) {
  SeaPlace.coral => (
    shallow: AppSeaMap.coralShallow,
    beach: AppSeaMap.coralBeach,
    inner: AppSeaMap.coralInner,
  ),
  SeaPlace.ice => (
    shallow: AppSeaMap.iceShallow,
    beach: AppSeaMap.iceBeach,
    inner: AppSeaMap.iceInner,
  ),
  SeaPlace.deep => (
    shallow: AppSeaMap.deepShallow,
    beach: AppSeaMap.deepBeach,
    inner: AppSeaMap.deepInner,
  ),
  SeaPlace.home => (
    shallow: AppSeaMap.homeShallow,
    beach: AppSeaMap.homeBeach,
    inner: AppSeaMap.homeInner,
  ),
  SeaPlace.kelp => (
    shallow: AppSeaMap.kelpShallow,
    beach: AppSeaMap.kelpBeach,
    inner: AppSeaMap.kelpInner,
  ),
  SeaPlace.volcano => (
    shallow: AppSeaMap.volcanoShallow,
    beach: AppSeaMap.volcanoBeach,
    inner: AppSeaMap.volcanoInner,
  ),
  SeaPlace.sunken => (
    shallow: AppSeaMap.sunkenShallow,
    beach: AppSeaMap.sunkenBeach,
    inner: AppSeaMap.sunkenInner,
  ),
  SeaPlace.sunset => (
    shallow: AppSeaMap.sunsetShallow,
    beach: AppSeaMap.sunsetBeach,
    inner: AppSeaMap.sunsetInner,
  ),
  null => (shallow: AppSeaMap.unknownLand, beach: AppSeaMap.unknownLand, inner: null),
};

class SeaWorldPainter extends CustomPainter {
  const SeaWorldPainter({required this.layout, required this.gretGoalId});

  final SeaWorldLayout layout;
  final String? gretGoalId;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppSeaMap.ocean);
    _waves(canvas, size);
    for (final item in OpenSea.of(layout)) {
      SceneryArt.draw(canvas, item);
    }

    for (final island in layout.islands) {
      final bands = _bands(island.place);
      // Shallow water, the beach with its foam line, the inner land, then the scenery.
      canvas.drawPath(
        island.outline(scale: AppSeaMap.shallowScale),
        Paint()..color = bands.shallow.withValues(alpha: AppSeaMap.shallowAlpha),
      );
      canvas.drawPath(island.outline(), Paint()..color = bands.beach);
      canvas.drawPath(
        island.outline(),
        Paint()
          ..color = AppSeaMap.islandEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      final inner = bands.inner;
      if (inner != null) {
        canvas.drawPath(island.outline(scale: AppSeaMap.innerScale), Paint()..color = inner);
      }
      for (final item in IslandScenery.of(island)) {
        SceneryArt.draw(canvas, item);
      }
    }

    // Darkness over the whole world, opened in soft circles around discovered points and Gret.
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = AppSeaMap.worldFog);
    final clear = Paint()
      ..blendMode = BlendMode.clear
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, AppSeaMap.worldFogSoftness);
    for (final island in layout.known) {
      final region = island.region!;
      for (var j = 0; j < region.points.length; j++) {
        final point = region.points[j];
        if (!point.discovered) continue;
        final radius =
            AppSeaMap.worldClearMin +
            (AppSeaMap.worldClearMax - AppSeaMap.worldClearMin) * point.progress;
        canvas.drawCircle(island.points[j], radius, clear);
      }
      if (region.goal.id == gretGoalId) {
        canvas.drawCircle(island.gretSpot, AppSeaMap.gretClear, clear);
      }
    }
    // Bought seas are Gret's own: always in the clear (spec 014).
    for (final island in layout.bought) {
      canvas.drawCircle(
        island.centre,
        math.max(island.radiusX, island.radiusY) * AppSeaMap.boughtClear,
        clear,
      );
    }
    canvas.restore();
  }

  void _waves(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppSeaMap.oceanLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var y = 60.0; y < size.height; y += 90) {
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 16) {
        path.lineTo(x, y + math.sin(x / 40 + y) * 6);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(SeaWorldPainter oldDelegate) =>
      oldDelegate.layout != layout || oldDelegate.gretGoalId != gretGoalId;
}
