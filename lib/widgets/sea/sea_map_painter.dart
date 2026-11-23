// 5.5 Bản đồ biển: the ocean, one island per goal and the fog over what is not explored yet
// (spec 005, ADR-0010). The layout is shared with SeaMapView, which puts the points on top.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../data/mascot_species.dart';
import '../../data/sea_map.dart';
import '../../theme/app_theme.dart';

/// Where one region and its points sit on the map.
class RegionLayout {
  const RegionLayout({
    required this.region,
    required this.index,
    required this.rect,
    required this.points,
  });

  final MapRegion region;
  final int index;
  final Rect rect;

  /// Centres of the points, in the order of [MapRegion.points].
  final List<Offset> points;

  /// Island shape: rounded corners that differ a little per region.
  RRect get shape {
    final big = Radius.circular(rect.shortestSide * 0.32);
    final small = Radius.circular(rect.shortestSide * 0.16);
    return index.isEven
        ? RRect.fromRectAndCorners(
            rect,
            topLeft: big,
            topRight: small,
            bottomLeft: small,
            bottomRight: big,
          )
        : RRect.fromRectAndCorners(
            rect,
            topLeft: small,
            topRight: big,
            bottomLeft: big,
            bottomRight: small,
          );
  }
}

class SeaMapLayout {
  const SeaMapLayout._(this.regions, this.height);

  final List<RegionLayout> regions;
  final double height;

  /// Regions alternate left and right down the map; points sit on a grid inside each region,
  /// nudged a little so the map does not look like a table.
  factory SeaMapLayout.of(SeaMapData data, double width) {
    final regionWidth = width * AppSeaMap.regionWidthShare;
    final side = (width - regionWidth) / 2;
    const columns = AppSeaMap.pointColumns;
    var top = AppSeaMap.regionGap;
    final regions = <RegionLayout>[];

    for (var i = 0; i < data.regions.length; i++) {
      final region = data.regions[i];
      final rows = math.max(1, (region.points.length / columns).ceil());
      final height =
          AppSeaMap.labelHeight + rows * AppSeaMap.pointRowHeight + AppSeaMap.regionPadding;
      final left = i.isEven ? side / 2 : width - regionWidth - side / 2;
      final rect = Rect.fromLTWH(left, top, regionWidth, height);
      final cell = rect.width / columns;
      regions.add(
        RegionLayout(
          region: region,
          index: i,
          rect: rect,
          points: [
            for (var j = 0; j < region.points.length; j++)
              Offset(
                rect.left + (j % columns + 0.5) * cell + ((j * 37) % 21 - 10),
                rect.top +
                    AppSeaMap.labelHeight +
                    (j ~/ columns + 0.4) * AppSeaMap.pointRowHeight +
                    ((j * 53) % 15 - 7),
              ),
          ],
        ),
      );
      top += height + AppSeaMap.regionGap;
    }
    return SeaMapLayout._(regions, top);
  }
}

Color islandColour(SeaPlace place) => switch (place) {
  SeaPlace.coral => AppSeaMap.coral,
  SeaPlace.ice => AppSeaMap.ice,
  SeaPlace.deep => AppSeaMap.deep,
  SeaPlace.home => AppSeaMap.home,
};

class SeaMapPainter extends CustomPainter {
  const SeaMapPainter(this.layout);

  final SeaMapLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppSeaMap.ocean);
    _waves(canvas, size);

    for (final region in layout.regions) {
      final shape = region.shape;
      canvas.drawRRect(shape, Paint()..color = islandColour(region.region.place));

      // Fog over the whole island, with a soft clear circle around each discovered point that
      // grows with its days done.
      canvas.saveLayer(region.rect.inflate(AppSeaMap.fogSoftness), Paint());
      canvas.drawRRect(shape, Paint()..color = AppSeaMap.fog);
      _puffs(canvas, region);
      final clear = Paint()
        ..blendMode = BlendMode.clear
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, AppSeaMap.fogSoftness);
      for (var j = 0; j < region.points.length; j++) {
        final point = region.region.points[j];
        if (!point.discovered) continue;
        final radius =
            AppSeaMap.fogClearMin +
            (AppSeaMap.fogClearMax - AppSeaMap.fogClearMin) * point.progress;
        canvas.drawCircle(region.points[j], radius, clear);
      }
      canvas.restore();

      canvas.drawRRect(
        shape,
        Paint()
          ..color = AppSeaMap.islandEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  /// Soft cloud puffs inside the island, so the fog does not look like a flat card.
  void _puffs(Canvas canvas, RegionLayout region) {
    final rect = region.rect;
    final paint = Paint()
      ..color = AppSeaMap.fogPuff
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, AppSeaMap.fogSoftness);
    canvas.save();
    canvas.clipRRect(region.shape);
    for (var k = 0; k < 7; k++) {
      final x = rect.left + rect.width * (((k * 37 + region.index * 11) % 100) / 100);
      final y = rect.top + rect.height * (((k * 53 + region.index * 29) % 100) / 100);
      canvas.drawCircle(Offset(x, y), rect.shortestSide * (0.18 + (k % 3) * 0.06), paint);
    }
    canvas.restore();
  }

  void _waves(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppSeaMap.oceanLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var y = 40.0; y < size.height; y += 70) {
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 12) {
        path.lineTo(x, y + math.sin(x / 30 + y) * 5);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(SeaMapPainter oldDelegate) => oldDelegate.layout != layout;
}
