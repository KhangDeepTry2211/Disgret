// 5.5 Bản đồ biển (spec 012): where an island's scenery and the open sea's life go, and how each
// piece is drawn. Placement is pure and seeded, so the map looks the same on every open, and no
// piece lands on a landmark or on Gret.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../data/mascot_species.dart';
import '../../theme/app_theme.dart';
import 'sea_world.dart';

enum SceneryKind {
  coral,
  palm,
  starfish,
  iceberg,
  snowMound,
  iceCrack,
  glowCoral,
  vent,
  jellyfish,
  rock,
  bush,
  hut,
  lighthouse,
  kelpTuft,
  lavaRock,
  cone,
  column,
  arch,
  ruinBlock,
  fishSchool,
  turtle,
  whaleTail,
  bubbles,
}

class SceneryItem {
  const SceneryItem(this.kind, this.at, this.size, {this.reef = false});

  final SceneryKind kind;
  final Offset at;

  /// About the width of the drawing.
  final double size;

  /// On the reef ring around the beach rather than on the land.
  final bool reef;
}

/// The scenery of one island: reef pieces around the beach, then the sea's land pieces.
abstract final class IslandScenery {
  static List<SceneryKind> _reef(SeaPlace place) => switch (place) {
    SeaPlace.coral => const [SceneryKind.coral],
    SeaPlace.ice => const [SceneryKind.iceberg],
    SeaPlace.deep => const [SceneryKind.glowCoral, SceneryKind.glowCoral, SceneryKind.jellyfish],
    SeaPlace.home => const [SceneryKind.rock],
    SeaPlace.kelp => const [SceneryKind.kelpTuft],
    SeaPlace.volcano => const [SceneryKind.lavaRock],
    SeaPlace.sunken => const [SceneryKind.ruinBlock],
    SeaPlace.sunset => const [SceneryKind.coral],
  };

  static List<SceneryKind> _land(SeaPlace place) => switch (place) {
    SeaPlace.coral => const [
      SceneryKind.palm,
      SceneryKind.palm,
      SceneryKind.palm,
      SceneryKind.starfish,
      SceneryKind.starfish,
    ],
    SeaPlace.ice => const [
      SceneryKind.snowMound,
      SceneryKind.snowMound,
      SceneryKind.snowMound,
      SceneryKind.iceCrack,
      SceneryKind.iceCrack,
    ],
    SeaPlace.deep => const [SceneryKind.vent, SceneryKind.vent, SceneryKind.rock, SceneryKind.rock],
    SeaPlace.home => const [
      SceneryKind.lighthouse,
      SceneryKind.hut,
      SceneryKind.bush,
      SceneryKind.bush,
      SceneryKind.bush,
    ],
    SeaPlace.kelp => const [
      SceneryKind.kelpTuft,
      SceneryKind.kelpTuft,
      SceneryKind.kelpTuft,
      SceneryKind.rock,
      SceneryKind.rock,
    ],
    SeaPlace.volcano => const [
      SceneryKind.cone,
      SceneryKind.vent,
      SceneryKind.vent,
      SceneryKind.rock,
    ],
    SeaPlace.sunken => const [
      SceneryKind.arch,
      SceneryKind.column,
      SceneryKind.column,
      SceneryKind.ruinBlock,
    ],
    SeaPlace.sunset => const [
      SceneryKind.palm,
      SceneryKind.palm,
      SceneryKind.palm,
      SceneryKind.starfish,
      SceneryKind.starfish,
    ],
  };

  /// Palms, starfish and the lighthouse stand on the beach; the hut and bushes on the grass;
  /// the rest anywhere on the land (shares of the outline).
  static (double, double) _band(SceneryKind kind) => switch (kind) {
    SceneryKind.palm ||
    SceneryKind.starfish ||
    SceneryKind.lighthouse => (AppSeaMap.beachFrom, AppSeaMap.landOuter),
    SceneryKind.hut || SceneryKind.bush => (AppSeaMap.landInner, AppSeaMap.grassTo),
    _ => (AppSeaMap.landInner, AppSeaMap.landOuter),
  };

  static List<SceneryItem> of(IslandLayout island) {
    final place = island.place;
    if (place == null) return const [];
    final random = math.Random(island.seed);
    final avoid = [...island.points, island.gretSpot];
    bool clear(Offset at) =>
        avoid.every((spot) => (spot - at).distance >= AppSeaMap.sceneryClearance);

    final items = <SceneryItem>[];
    final reef = _reef(place);
    for (var i = 0; i < AppSeaMap.reefPieces; i++) {
      final angle = (i + random.nextDouble() * 0.6) / AppSeaMap.reefPieces * 2 * math.pi;
      final grow = 0.8 + random.nextDouble() * 0.4;
      final at = island.edgeAt(angle, AppSeaMap.reefScale);
      if (clear(at)) {
        items.add(SceneryItem(reef[i % reef.length], at, AppSeaMap.reefSize * grow, reef: true));
      }
    }

    for (final kind in _land(place)) {
      for (var attempt = 0; attempt < 60; attempt++) {
        // Its own band first; anywhere on the land when landmarks fill that band.
        final (from, to) = attempt < 30 ? _band(kind) : (AppSeaMap.landInner, AppSeaMap.landOuter);
        final angle = random.nextDouble() * 2 * math.pi;
        final at = island.edgeAt(angle, from + random.nextDouble() * (to - from));
        final apart = items.every(
          (item) => item.reef || (item.at - at).distance >= AppSeaMap.sceneryGap,
        );
        if (clear(at) && apart) {
          items.add(SceneryItem(kind, at, AppSeaMap.landSize));
          break;
        }
      }
    }
    return items;
  }
}

/// Sea life in the water: a few just off each known island, and some across the open sea.
abstract final class OpenSea {
  static const List<SceneryKind> _near = [
    SceneryKind.fishSchool,
    SceneryKind.turtle,
    SceneryKind.bubbles,
  ];
  static const List<SceneryKind> _far = [
    SceneryKind.fishSchool,
    SceneryKind.turtle,
    SceneryKind.whaleTail,
    SceneryKind.bubbles,
    SceneryKind.fishSchool,
  ];

  static List<SceneryItem> of(SeaWorldLayout layout) {
    final random = math.Random(AppSeaMap.openSeaSeed);
    final shores = [
      for (final island in layout.islands) island.outline(scale: AppSeaMap.shallowScale + 0.1),
    ];
    final keepClear = [
      for (final island in layout.islands) ...[island.gretSpot, island.labelAnchor],
    ];
    bool free(Offset at) =>
        shores.every((shore) => !shore.contains(at)) &&
        keepClear.every((spot) => (spot - at).distance > AppSeaMap.sceneryClearance);

    final items = <SceneryItem>[];
    for (final island in layout.known) {
      for (var i = 0; i < _near.length; i++) {
        final at = island.edgeAt(random.nextDouble() * 2 * math.pi, AppSeaMap.nearSeaScale);
        if (free(at)) items.add(SceneryItem(_near[i], at, AppSeaMap.seaLifeSize));
      }
    }

    const cell = AppSeaMap.openSeaCell;
    for (var y = 0.0; y < layout.size.height; y += cell) {
      for (var x = 0.0; x < layout.size.width; x += cell) {
        final chance = random.nextDouble();
        final at = Offset(x + random.nextDouble() * cell, y + random.nextDouble() * cell);
        final kind = _far[random.nextInt(_far.length)];
        if (chance < AppSeaMap.openSeaChance && free(at)) {
          items.add(SceneryItem(kind, at, AppSeaMap.seaLifeSize));
        }
      }
    }
    return items;
  }
}

/// Draws one piece of scenery centred on its spot, with simple flat shapes.
abstract final class SceneryArt {
  static Paint _fill(Color colour) => Paint()..color = colour;

  static Paint _line(Color colour, double width) => Paint()
    ..color = colour
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;

  static Rect _oval(double x, double y, double width, double height) =>
      Rect.fromCenter(center: Offset(x, y), width: width, height: height);

  static void draw(Canvas canvas, SceneryItem item) {
    final u = item.size / 20;
    canvas.save();
    canvas.translate(item.at.dx, item.at.dy);
    switch (item.kind) {
      case SceneryKind.coral:
        final colour = (item.at.dx ~/ 7 + item.at.dy ~/ 11).isEven
            ? AppSea.coralPink
            : AppSea.coralOrange;
        _branches(canvas, u, _line(colour, 2.2 * u));
      case SceneryKind.glowCoral:
        canvas.drawCircle(Offset.zero, 7 * u, _fill(AppSea.plankton.withValues(alpha: 0.22)));
        _branches(canvas, u, _line(AppSea.plankton, 1.8 * u));
      case SceneryKind.palm:
        _palm(canvas, u);
      case SceneryKind.starfish:
        canvas.drawPath(_star(4 * u, 1.8 * u), _fill(AppSea.coralOrange));
      case SceneryKind.iceberg:
        canvas.drawPath(
          Path()
            ..moveTo(-7 * u, 5 * u)
            ..lineTo(-4 * u, -4 * u)
            ..lineTo(0, -8 * u)
            ..lineTo(5 * u, -2 * u)
            ..lineTo(7 * u, 5 * u)
            ..close(),
          _fill(AppSea.iceberg),
        );
        canvas.drawPath(
          Path()
            ..moveTo(0, -8 * u)
            ..lineTo(5 * u, -2 * u)
            ..lineTo(7 * u, 5 * u)
            ..lineTo(u, 5 * u)
            ..close(),
          _fill(AppSeaMap.iceShade),
        );
      case SceneryKind.snowMound:
        canvas.drawOval(_oval(0, 0, 16 * u, 7 * u), _fill(AppSea.iceberg));
        canvas.drawOval(_oval(2 * u, 1.6 * u, 10 * u, 3 * u), _fill(AppSeaMap.iceShade));
      case SceneryKind.iceCrack:
        canvas.drawPath(
          Path()
            ..moveTo(-7 * u, -2 * u)
            ..lineTo(-3 * u, u)
            ..lineTo(0, -u)
            ..lineTo(4 * u, 2 * u)
            ..lineTo(7 * u, 0),
          _line(AppSeaMap.iceShade, 1.2 * u),
        );
      case SceneryKind.vent:
        canvas.drawOval(_oval(0, 0, 12 * u, 6 * u), _fill(AppSeaMap.rock));
        canvas.drawOval(_oval(0, 0, 6 * u, 3 * u), _fill(AppSeaMap.ventGlow));
        final bubble = _line(AppSea.bubble, 0.9 * u);
        canvas.drawCircle(Offset(u, -5 * u), 1.6 * u, bubble);
        canvas.drawCircle(Offset(-u, -9 * u), 1.1 * u, bubble);
      case SceneryKind.jellyfish:
        canvas.drawArc(_oval(0, -u, 10 * u, 10 * u), math.pi, math.pi, true, _fill(AppSea.jelly));
        final tentacle = _line(AppSea.jelly, 1.2 * u);
        for (final x in [-3.0, 0.0, 3.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(x * u, -u)
              ..quadraticBezierTo((x - 1.5) * u, 2 * u, x * u, 4 * u)
              ..quadraticBezierTo((x + 1.5) * u, 6 * u, x * u, 8 * u),
            tentacle,
          );
        }
      case SceneryKind.rock:
        canvas.drawOval(_oval(0, 0, 12 * u, 8 * u), _fill(AppSeaMap.rock));
        canvas.drawOval(_oval(-2 * u, -1.6 * u, 5 * u, 2.5 * u), _fill(AppSeaMap.rockLight));
      case SceneryKind.bush:
        final leaves = _fill(AppSeaMap.bush);
        canvas.drawCircle(Offset(-3 * u, u), 4 * u, leaves);
        canvas.drawCircle(Offset(3 * u, u), 4 * u, leaves);
        canvas.drawCircle(Offset(0, -2 * u), 4.5 * u, leaves);
        canvas.drawCircle(Offset(-u, -3 * u), 1.8 * u, _fill(AppSeaMap.bushLight));
      case SceneryKind.hut:
        canvas.drawRect(Rect.fromLTWH(-6 * u, -2 * u, 12 * u, 9 * u), _fill(AppSeaMap.hutWall));
        canvas.drawPath(
          Path()
            ..moveTo(-8 * u, -2 * u)
            ..lineTo(0, -9 * u)
            ..lineTo(8 * u, -2 * u)
            ..close(),
          _fill(AppSeaMap.hutRoof),
        );
        canvas.drawRect(Rect.fromLTWH(-1.5 * u, 2 * u, 3 * u, 5 * u), _fill(AppSeaMap.coconut));
      case SceneryKind.lighthouse:
        canvas.drawPath(
          Path()
            ..moveTo(-3.5 * u, 9 * u)
            ..lineTo(-2.2 * u, -7 * u)
            ..lineTo(2.2 * u, -7 * u)
            ..lineTo(3.5 * u, 9 * u)
            ..close(),
          _fill(AppSeaMap.lighthouse),
        );
        final band = _fill(AppSeaMap.lighthouseBand);
        canvas.drawRect(Rect.fromLTWH(-3.1 * u, 2 * u, 6.2 * u, 2.4 * u), band);
        canvas.drawRect(Rect.fromLTWH(-2.6 * u, -3.5 * u, 5.2 * u, 2.4 * u), band);
        canvas.drawCircle(Offset(0, -8.6 * u), 2.4 * u, _fill(AppSeaMap.lamp));
      case SceneryKind.kelpTuft:
        for (final (x, colour) in const [
          (-3.0, AppSea.kelpGold),
          (0.0, AppSea.kelpOlive),
          (3.0, AppSea.kelpGold),
        ]) {
          canvas.drawPath(
            Path()
              ..moveTo(x * u, 7 * u)
              ..quadraticBezierTo((x - 3) * u, 0, x * u, -4 * u)
              ..quadraticBezierTo((x + 3) * u, -7 * u, x * u, -10 * u),
            _line(colour, 1.8 * u),
          );
        }
      case SceneryKind.lavaRock:
        canvas.drawOval(_oval(0, 0, 13 * u, 8 * u), _fill(AppSea.volcanoRock));
        canvas.drawPath(
          Path()
            ..moveTo(-3 * u, -2 * u)
            ..lineTo(0, u)
            ..lineTo(3 * u, -u),
          _line(AppSea.lava, 1.2 * u),
        );
      case SceneryKind.cone:
        canvas.drawPath(
          Path()
            ..moveTo(-10 * u, 7 * u)
            ..lineTo(-3 * u, -6 * u)
            ..lineTo(3 * u, -6 * u)
            ..lineTo(10 * u, 7 * u)
            ..close(),
          _fill(AppSea.volcanoRock),
        );
        canvas.drawOval(_oval(0, -6 * u, 7 * u, 2.4 * u), _fill(AppSea.lava));
        canvas.drawPath(
          Path()
            ..moveTo(-u, -5 * u)
            ..lineTo(-2 * u, 0)
            ..lineTo(0, 3 * u),
          _line(AppSea.lava, u),
        );
      case SceneryKind.column:
        canvas.drawRect(Rect.fromLTWH(-2 * u, -8 * u, 4 * u, 15 * u), _fill(AppSea.stone));
        canvas.drawRect(
          Rect.fromLTWH(-3.2 * u, -9.5 * u, 6.4 * u, 2 * u),
          _fill(AppSea.stoneShade),
        );
        canvas.drawOval(_oval(0, -9.5 * u, 5 * u, 1.4 * u), _fill(AppSea.moss));
      case SceneryKind.arch:
        final stone = _fill(AppSea.stone);
        canvas.drawRect(Rect.fromLTWH(-8 * u, -4 * u, 3.4 * u, 11 * u), stone);
        canvas.drawRect(Rect.fromLTWH(4.6 * u, -4 * u, 3.4 * u, 11 * u), stone);
        canvas.drawArc(
          _oval(0, -4 * u, 13 * u, 10 * u),
          math.pi,
          math.pi,
          false,
          _line(AppSea.stone, 3 * u),
        );
      case SceneryKind.ruinBlock:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-6 * u, -3 * u, 12 * u, 6 * u), Radius.circular(u)),
          _fill(AppSea.stoneShade),
        );
        canvas.drawOval(_oval(-2 * u, -3 * u, 6 * u, 1.6 * u), _fill(AppSea.moss));
      case SceneryKind.fishSchool:
        for (final (x, y) in const [(-6.0, -3.0), (2.0, -5.0), (-1.0, 2.0), (6.0, 0.0)]) {
          _fish(canvas, Offset(x * u, y * u), u);
        }
      case SceneryKind.turtle:
        final skin = _fill(AppSeaMap.turtleSkin);
        for (final (x, y) in const [(-5.0, -4.0), (-5.0, 4.0), (4.0, -4.5), (4.0, 4.5)]) {
          canvas.drawOval(_oval(x * u, y * u, 4.5 * u, 2.6 * u), skin);
        }
        canvas.drawCircle(Offset(8 * u, 0), 2.4 * u, skin);
        canvas.drawOval(_oval(0, 0, 14 * u, 10 * u), _fill(AppSeaMap.turtleShell));
      case SceneryKind.whaleTail:
        canvas.drawOval(_oval(0, 6 * u, 18 * u, 5 * u), _line(AppSeaMap.islandEdge, u));
        canvas.drawPath(
          Path()
            ..moveTo(-u, 6 * u)
            ..lineTo(-u, 0)
            ..quadraticBezierTo(-6 * u, -2 * u, -9 * u, -6 * u)
            ..quadraticBezierTo(-4 * u, -5 * u, 0, -2 * u)
            ..quadraticBezierTo(4 * u, -5 * u, 9 * u, -6 * u)
            ..quadraticBezierTo(6 * u, -2 * u, u, 0)
            ..lineTo(u, 6 * u)
            ..close(),
          _fill(AppSeaMap.whale),
        );
      case SceneryKind.bubbles:
        final ring = _line(AppSea.bubble, 1.2 * u);
        canvas.drawCircle(Offset.zero, 2.6 * u, ring);
        canvas.drawCircle(Offset(3 * u, -5 * u), 1.8 * u, ring);
        canvas.drawCircle(Offset(-2 * u, -9 * u), 1.3 * u, ring);
    }
    canvas.restore();
  }

  /// A small branching coral.
  static void _branches(Canvas canvas, double u, Paint paint) {
    canvas.drawLine(Offset(0, 7 * u), Offset(0, -6 * u), paint);
    canvas.drawLine(Offset(0, 2 * u), Offset(-5 * u, -4 * u), paint);
    canvas.drawLine(Offset(0, 0), Offset(5 * u, -6 * u), paint);
    canvas.drawLine(Offset(-5 * u, -4 * u), Offset(-6 * u, -8 * u), paint);
  }

  static void _palm(Canvas canvas, double u) {
    canvas.drawOval(
      _oval(0, 8.5 * u, 10 * u, 3 * u),
      _fill(AppSeaMap.coconut.withValues(alpha: 0.2)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-u, 8 * u)
        ..quadraticBezierTo(-2 * u, 0, 2 * u, -7 * u),
      _line(AppSeaMap.palmTrunk, 2.4 * u),
    );
    final top = Offset(2 * u, -7 * u);
    final leaf = _line(AppSeaMap.palmLeaf, 2.6 * u);
    for (final angle in const [-2.9, -2.1, -1.0, -0.2, 0.6, 2.5]) {
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(
            top.dx + direction.dx * 5 * u,
            top.dy + direction.dy * 5 * u - 2 * u,
            top.dx + direction.dx * 9 * u,
            top.dy + direction.dy * 9 * u + 2 * u,
          ),
        leaf,
      );
    }
    final nut = _fill(AppSeaMap.coconut);
    canvas.drawCircle(top + Offset(-u, 1.6 * u), 1.3 * u, nut);
    canvas.drawCircle(top + Offset(1.4 * u, 1.6 * u), 1.3 * u, nut);
  }

  static Path _star(double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = Offset(radius * math.cos(angle), radius * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  static void _fish(Canvas canvas, Offset at, double u) {
    canvas.drawPath(
      Path()
        ..moveTo(at.dx + 2.2 * u, at.dy)
        ..lineTo(at.dx + 4.6 * u, at.dy - 1.6 * u)
        ..lineTo(at.dx + 4.6 * u, at.dy + 1.6 * u)
        ..close(),
      _fill(AppSea.fishFin),
    );
    canvas.drawOval(Rect.fromCenter(center: at, width: 5 * u, height: 3 * u), _fill(AppSea.fish));
    canvas.drawCircle(at + Offset(-1.2 * u, -0.3 * u), 0.5 * u, _fill(AppSeaMap.fishEye));
  }
}
