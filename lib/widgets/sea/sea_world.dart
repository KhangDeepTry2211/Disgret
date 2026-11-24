// 5.5 Bản đồ biển, full screen: one ocean where every goal is an island with a natural shape,
// unknown seas wait in the dark, and the darkness opens around discovered points as habits are
// done (spec 005, ADR-0010). World coordinates are in logical pixels; the screen pans and zooms.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../data/mascot_species.dart';
import '../../data/sea_map.dart';
import '../../theme/app_theme.dart';

/// One island of the world: its region, outline, label anchor and points.
class IslandLayout {
  const IslandLayout({
    required this.region,
    required this.centre,
    required this.radiusX,
    required this.radiusY,
    required this.seed,
    required this.points,
  });

  /// Null for an unknown sea waiting for a future goal.
  final MapRegion? region;
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

  /// A closed outline that wobbles around an ellipse, different for every island.
  Path outline({double scale = 1}) {
    final path = Path();
    const steps = 64;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps * 2 * math.pi;
      final wobble =
          1 +
          0.10 * math.sin(3 * t + seed) +
          0.07 * math.sin(5 * t + seed * 1.7) +
          0.04 * math.sin(9 * t + seed * 2.3);
      final point = Offset(
        centre.dx + radiusX * scale * wobble * math.cos(t),
        centre.dy + radiusY * scale * wobble * math.sin(t),
      );
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

  factory SeaWorldLayout.of(SeaMapData data) {
    final raw = <IslandLayout>[];
    final count = data.regions.length + AppSeaMap.unknownSeas;
    for (var i = 0; i < count; i++) {
      final region = i < data.regions.length ? data.regions[i] : null;
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
          centre: centre,
          radiusX: region == null ? radiusX * 0.8 : radiusX,
          radiusY: region == null ? radiusY * 0.8 : radiusY,
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

Color _landColour(SeaPlace place) => switch (place) {
  SeaPlace.coral => AppSeaMap.coral,
  SeaPlace.ice => AppSeaMap.ice,
  SeaPlace.deep => AppSeaMap.deep,
  SeaPlace.home => AppSeaMap.home,
};

class SeaWorldPainter extends CustomPainter {
  const SeaWorldPainter({required this.layout, required this.gretGoalId});

  final SeaWorldLayout layout;
  final String? gretGoalId;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppSeaMap.ocean);
    _waves(canvas, size);

    for (final island in layout.islands) {
      final region = island.region;
      final land = region == null ? AppSeaMap.unknownLand : _landColour(region.place);
      // Shallow water ring, the island, then a lighter heart.
      canvas.drawPath(
        island.outline(scale: 1.14),
        Paint()..color = land.withValues(alpha: AppSeaMap.shallowAlpha),
      );
      canvas.drawPath(island.outline(), Paint()..color = land);
      canvas.drawPath(
        island.outline(scale: 0.62),
        Paint()..color = AppSeaMap.islandHeart.withValues(alpha: AppSeaMap.heartAlpha),
      );
      canvas.drawPath(
        island.outline(),
        Paint()
          ..color = AppSeaMap.islandEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
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
