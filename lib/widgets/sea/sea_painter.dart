// 5.3 Gret và biển sống: paints the sky, three wave bands, seaweed, bubbles, fish and litter
// (spec 003 FR-007, FR-017), with the living-sea layers of spec 013: sun or moon rays, ripples,
// the sea floor, a fish school and specks by day (A2); stars, plankton and glowing life by night
// (A4). Colours come only from AppSea; the water blends from clear to murky
// as the clarity drops below 70.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../data/mascot_species.dart';
import '../../theme/app_theme.dart';

class SeaPainter extends CustomPainter {
  SeaPainter({
    required this.loop,
    required this.clarity,
    required this.isNight,
    this.place = SeaPlace.home,
    this.skyShare = defaultSkyShare,
  }) : super(repaint: loop);

  /// Which sea (Góc của Gret, spec 004): colours and decorations change, the meaning does not.
  final SeaPlace place;

  /// 0–1, repeating; drives waves, bubbles and fish. Stays at 0 without animations.
  final Animation<double> loop;

  /// 0–100.
  final double clarity;
  final bool isNight;

  static const double defaultSkyShare = 0.30;

  /// Share of the height above the water (Hôm nay's full-screen sea uses less, spec 010).
  final double skyShare;

  /// 0 when the sea is clear (≥ 70), 1 when it is fully murky (0).
  static double _murkOf(double clarity) => ((70 - clarity) / 70).clamp(0.0, 1.0);

  /// Colour of water band [band] (0 top, 2 deepest) for this clarity, time of day and sea.
  static Color bandColour(
    int band, {
    required double clarity,
    required bool isNight,
    SeaPlace place = SeaPlace.home,
  }) {
    final clear = _clearColoursOf(place, isNight);
    final murky = isNight ? AppSea.murkyNight : AppSea.murkyDay;
    return Color.lerp(clear[band], murky[band], _murkOf(clarity))!;
  }

  /// The deepest water: Hôm nay fills the screen with it under the scrolled sea (spec 010).
  static Color deepColour({
    required double clarity,
    required bool isNight,
    SeaPlace place = SeaPlace.home,
  }) => bandColour(2, clarity: clarity, isNight: isNight, place: place);

  @override
  void paint(Canvas canvas, Size size) {
    final t = loop.value;
    final w = size.width;
    final h = size.height;
    final surface = h * skyShare;
    // Light reaching into the water: full when clear, fading as the sea murks.
    final light = 1 - _murkOf(clarity);

    // Sky: the sun by day; the moon and a few stars by night (spec 013).
    canvas.drawRect(Offset.zero & size, Paint()..color = _skyColour());
    // Sized by the width and the sky, so a tall full-screen sea does not get a huge sun.
    final orb = math.min(w * 0.06, surface * 0.25);
    final orbAt = Offset(w * 0.8, surface * 0.7);
    if (isNight) {
      _orb(canvas, orbAt, orb, AppSea.moon);
      final star = Paint()..color = AppSea.star;
      for (final (x, y) in const [(0.12, 0.2), (0.34, 0.12), (0.58, 0.3), (0.68, 0.1)]) {
        canvas.drawCircle(Offset(w * x, surface * y), 1.2, star);
      }
    } else if (place == SeaPlace.sunset) {
      // Vịnh hoàng hôn: a big low sun half in the water (spec 014).
      canvas.drawCircle(Offset(w * 0.5, surface), orb * 1.8, Paint()..color = AppSea.sunsetSun);
    } else {
      _orb(canvas, orbAt, orb, AppSea.sun);
    }

    // Three wave bands, each drifting at its own speed.
    final tops = [skyShare, 0.50, 0.72];
    for (var i = 0; i < 3; i++) {
      final colour = bandColour(i, clarity: clarity, isNight: isNight, place: place);
      final phase = 2 * math.pi * t * (i.isEven ? 1 : -1) + i;
      _wave(canvas, size, top: h * tops[i], amplitude: h * 0.025, phase: phase, colour: colour);
    }

    _rays(canvas, size, t, light);
    if (!isNight) _ripples(canvas, size, t, light);
    _floor(canvas, size);

    // Seaweed behind the place's own decorations.
    if (place == SeaPlace.home || place == SeaPlace.coral) {
      _seaweed(canvas, Offset(w * 0.30, h), h * 0.16, t, 0.7, colour: AppSea.seaweedBack);
      _seaweed(canvas, Offset(w * 0.72, h), h * 0.13, t, 2.6, colour: AppSea.seaweedBack);
    }

    final glow = isNight;
    switch (place) {
      case SeaPlace.home:
        _seaweed(canvas, Offset(w * 0.10, h), h * 0.30, t, 0);
        _seaweed(canvas, Offset(w * 0.16, h), h * 0.22, t, 1.3);
        _seaweed(canvas, Offset(w * 0.88, h), h * 0.26, t, 2.1);
      case SeaPlace.coral:
        _coral(canvas, Offset(w * 0.12, h), h * 0.24, glow ? AppSea.plankton : AppSea.coralPink);
        _coral(canvas, Offset(w * 0.84, h), h * 0.30, glow ? AppSea.plankton : AppSea.coralOrange);
        _coral(canvas, Offset(w * 0.93, h), h * 0.18, AppSea.coralPink);
        _seaweed(canvas, Offset(w * 0.22, h), h * 0.20, t, 2.1);
      case SeaPlace.ice:
        _iceberg(canvas, Offset(w * 0.18, surface), h * 0.16, t, 0);
        _iceberg(canvas, Offset(w * 0.86, surface), h * 0.11, t, 1.7);
      case SeaPlace.kelp:
        for (final (x, height, offset, colour) in [
          (0.08, 0.62, 0.0, AppSea.kelpGold),
          (0.2, 0.5, 1.4, AppSea.kelpOlive),
          (0.86, 0.66, 2.2, AppSea.kelpGold),
          (0.95, 0.45, 3.1, AppSea.kelpOlive),
        ]) {
          _kelp(canvas, Offset(w * x, h), h * height, t, offset, colour);
        }
      case SeaPlace.volcano:
        _volcano(canvas, size, t);
      case SeaPlace.sunken:
        _ruins(canvas, size, t);
      case SeaPlace.sunset:
        _sunsetBay(canvas, size, t);
      case SeaPlace.deep:
        _plankton(canvas, size, t);
        _jellyfish(
          canvas,
          Offset(w * 0.82, h * (0.55 + 0.05 * math.sin(t * 2 * math.pi))),
          math.min(w, h),
        );
    }

    if (isNight) {
      // A4: glowing coral, twinkling plankton and a jellyfish drifting up.
      if (place != SeaPlace.coral) _coral(canvas, Offset(w * 0.78, h), h * 0.16, AppSea.plankton);
      _twinkles(canvas, size, t);
      if (place != SeaPlace.deep) {
        final rise = (t * 0.8) % 1;
        final centre = Offset(
          w * 0.16 + math.sin(rise * 2 * math.pi) * 6,
          h - rise * (h - surface),
        );
        canvas.drawCircle(
          centre,
          math.min(w, h) * 0.085,
          Paint()..color = AppSea.jelly.withValues(alpha: 0.15),
        );
        _jellyfish(canvas, centre, math.min(w, h));
      }
    } else {
      _specks(canvas, size, t);
    }

    // Bubbles rise from the bottom; fewer when the sea is murky.
    final bubbles = clarity >= 70 ? 7 : (clarity >= 40 ? 4 : 2);
    final bubbleFill = Paint()..color = AppSea.bubble.withValues(alpha: 0.25);
    final bubbleRing = Paint()
      ..color = AppSea.bubble
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final bubbleShine = Paint()..color = Colors.white;
    for (var i = 0; i < bubbles; i++) {
      final progress = (t + i / bubbles) % 1;
      final x = w * (0.2 + 0.6 * ((i * 37) % 100) / 100) + math.sin(progress * 6 + i) * 4;
      final y = h - progress * h * (1 - skyShare);
      final r = 2.5 + (i % 3);
      canvas.drawCircle(Offset(x, y), r, bubbleFill);
      canvas.drawCircle(Offset(x, y), r, bubbleRing);
      canvas.drawCircle(Offset(x - r * 0.35, y - r * 0.35), r * 0.3, bubbleShine);
    }

    if (clarity >= 70 && place != SeaPlace.deep) {
      // A school of four crossing together, and one more lower down.
      for (final (dx, dy, scale) in const [
        (0.0, 0.0, 1.0),
        (-0.06, 0.03, 0.85),
        (-0.03, -0.035, 0.8),
        (-0.1, -0.01, 0.75),
      ]) {
        _fish(canvas, size, progress: (t + dx) % 1, row: 0.62 + dy, scale: scale);
      }
      _fish(canvas, size, progress: (t + 0.5) % 1, row: 0.82, scale: 0.75);
    }
    if (clarity < 40) {
      _bottle(canvas, Offset(w * 0.22, h * 0.56 + math.sin(t * 2 * math.pi) * 3));
      _bag(canvas, Offset(w * 0.80, h * 0.66 + math.cos(t * 2 * math.pi) * 3));
    }
  }

  /// Slanting sun rays by day, pale moon rays by night; they sway, pulse and fade as the sea murks.
  void _rays(Canvas canvas, Size size, double t, double light) {
    if (light <= 0) return;
    final w = size.width;
    final h = size.height;
    final surface = h * skyShare;
    final pulse = 0.6 + 0.4 * math.sin(t * 2 * math.pi * 2);
    final colour = isNight
        ? AppSea.moonRay.withValues(alpha: AppSea.moonRayAlpha * pulse * light)
        : AppSea.sunRay.withValues(alpha: AppSea.sunRayAlpha * pulse * light);
    final sway = math.sin(t * 2 * math.pi) * w * 0.04;
    final paint = Paint()..color = colour;
    for (final x in isNight ? const [0.56, 0.8] : const [0.2, 0.5, 0.8]) {
      final top = w * x;
      canvas.drawPath(
        Path()
          ..moveTo(top - w * 0.035, surface)
          ..lineTo(top + w * 0.035, surface)
          ..lineTo(top + w * 0.2 + sway + h * 0.06, h)
          ..lineTo(top - w * 0.1 + sway + h * 0.06, h)
          ..close(),
        paint,
      );
    }
  }

  /// Light ripples drifting just under the surface by day.
  void _ripples(Canvas canvas, Size size, double t, double light) {
    if (light <= 0) return;
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = AppSea.ripple.withValues(alpha: AppSea.ripple.a * light)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final x = (w * ((i * 0.23 + t * 0.15) % 1)) - w * 0.04;
      final y = h * (skyShare + 0.04 + (i % 3) * 0.035);
      final segment = w * 0.05;
      canvas.drawPath(
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + segment / 2, y - 3, x + segment, y)
          ..quadraticBezierTo(x + segment * 1.5, y + 3, x + segment * 2, y),
        paint,
      );
    }
  }

  /// The sea floor with a few pebbles; sand, ice or dark rock depending on the sea.
  void _floor(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final top = h * AppSea.floorTop;
    final day = switch (place) {
      SeaPlace.home || SeaPlace.coral => AppSea.sand,
      SeaPlace.ice => AppSea.iceFloor,
      SeaPlace.deep => AppSea.deepFloor,
      SeaPlace.kelp => AppSea.kelpFloor,
      SeaPlace.volcano => AppSea.volcanoRock,
      SeaPlace.sunken => AppSea.sunkenFloor,
      SeaPlace.sunset => AppSea.pinkSand,
    };
    final colour = isNight ? _night(day) : day;
    final path = Path()..moveTo(0, top);
    path
      ..quadraticBezierTo(w * 0.25, top - h * 0.02, w * 0.5, top)
      ..quadraticBezierTo(w * 0.75, top + h * 0.02, w, top - h * 0.01)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(colour, Colors.white, 0.25)!, colour],
        ).createShader(Rect.fromLTRB(0, top - h * 0.02, w, h)),
    );
    final ripple = Paint()
      ..color = Color.lerp(colour, Colors.black, 0.12)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final (x, y) in const [(0.12, 0.95), (0.46, 0.975), (0.72, 0.94), (0.9, 0.985)]) {
      final at = Offset(w * x, h * y);
      canvas.drawArc(
        Rect.fromCenter(center: at, width: w * 0.1, height: h * 0.012),
        3.4,
        2.6,
        false,
        ripple,
      );
    }
    final shell = isNight ? _night(AppSea.pebble) : AppSea.pebble;
    for (final (x, y) in const [(0.2, 0.965), (0.63, 0.975)]) {
      final at = Offset(w * x, h * y);
      final r = h * 0.012;
      canvas.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.4),
            colors: [Color.lerp(shell, Colors.white, 0.6)!, shell],
          ).createShader(Rect.fromCircle(center: at, radius: r)),
      );
    }
    _star(
      canvas,
      Offset(w * 0.84, h * 0.955),
      h * 0.014,
      isNight ? _night(AppSea.coralOrange) : AppSea.coralOrange,
    );
  }

  /// A little starfish on the sand.
  void _star(Canvas canvas, Offset centre, double radius, Color colour) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = centre + Offset(math.cos(angle) * r, math.sin(angle) * r);
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = colour);
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.lerp(colour, Colors.black, 0.3)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  /// Tiny specks rising slowly through the day water.
  void _specks(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;
    for (var i = 0; i < 6; i++) {
      final progress = (t * 0.6 + i / 6) % 1;
      final fade = math.sin(progress * math.pi);
      canvas.drawCircle(
        Offset(w * (0.08 + ((i * 41) % 90) / 100), h - progress * h * (1 - skyShare)),
        1.4,
        Paint()..color = AppSea.speck.withValues(alpha: AppSea.speck.a * fade),
      );
    }
  }

  /// Plankton twinkling in place at night.
  void _twinkles(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;
    for (var i = 0; i < 9; i++) {
      final glow = 0.15 + 0.85 * math.sin((t * 3 + i / 9) * math.pi).abs();
      final y = skyShare + 0.08 + ((i * 29) % 80) / 100 * (AppSea.floorTop - skyShare - 0.1);
      canvas.drawCircle(
        Offset(w * (0.06 + ((i * 47) % 88) / 100), h * y),
        1.6 + (i % 2) * 0.6,
        Paint()..color = AppSea.plankton.withValues(alpha: glow),
      );
    }
  }

  static Color _night(Color colour) => Color.lerp(colour, AppSea.skyNight, AppSea.nightBlend)!;

  Color _skyColour() {
    final day = switch (place) {
      SeaPlace.home => AppSea.skyDay,
      SeaPlace.coral => AppSea.coralSky,
      SeaPlace.ice => AppSea.iceSky,
      SeaPlace.deep => AppSea.deepSky,
      SeaPlace.kelp => AppSea.kelpSky,
      SeaPlace.volcano => AppSea.volcanoSky,
      SeaPlace.sunken => AppSea.sunkenSky,
      SeaPlace.sunset => AppSea.sunsetSky,
    };
    if (!isNight) return day;
    // A real night sky over every sea, only tinted by the place (spec 013).
    return place == SeaPlace.home
        ? AppSea.skyNight
        : Color.lerp(day, AppSea.skyNight, AppSea.nightSkyBlend)!;
  }

  static List<Color> _clearColoursOf(SeaPlace place, bool isNight) {
    final day = switch (place) {
      SeaPlace.home => AppSea.clearDay,
      SeaPlace.coral => AppSea.coralClear,
      SeaPlace.ice => AppSea.iceClear,
      SeaPlace.deep => AppSea.deepClear,
      SeaPlace.kelp => AppSea.kelpClear,
      SeaPlace.volcano => AppSea.volcanoClear,
      SeaPlace.sunken => AppSea.sunkenClear,
      SeaPlace.sunset => AppSea.sunsetClear,
    };
    if (!isNight) return day;
    return place == SeaPlace.home ? AppSea.clearNight : [for (final c in day) _night(c)];
  }

  /// A branching coral on the sea floor.
  void _coral(Canvas canvas, Offset base, double height, Color colour) {
    final outline = Paint()
      ..color = Color.lerp(colour, Colors.black, 0.35)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final stem = Paint()
      ..color = Color.lerp(colour, Colors.black, 0.15)!
      ..strokeWidth = height * 0.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, base.translate(0, -height * 0.6), stem);
    for (final (dx, dy, r) in const [
      (0.0, 0.78, 0.2),
      (-0.26, 0.55, 0.16),
      (0.24, 0.62, 0.17),
      (-0.12, 0.32, 0.13),
      (0.16, 0.3, 0.12),
    ]) {
      final centre = base.translate(dx * height, -dy * height);
      final radius = r * height;
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.4),
            colors: [Color.lerp(colour, Colors.white, 0.55)!, colour],
          ).createShader(Rect.fromCircle(center: centre, radius: radius)),
      );
      canvas.drawCircle(centre, radius, outline);
    }
  }

  /// Rừng tảo bẹ: a tall kelp stalk swaying towards the light, with a few leaves.
  void _kelp(Canvas canvas, Offset base, double height, double t, double offset, Color colour) {
    final sway = math.sin(t * 2 * math.pi + offset) * height * 0.05;
    final top = Offset(base.dx + sway, base.dy - height);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..cubicTo(
          base.dx - height * 0.08,
          base.dy - height * 0.35,
          top.dx + height * 0.08,
          base.dy - height * 0.65,
          top.dx,
          top.dy,
        ),
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = height * 0.035
        ..strokeCap = StrokeCap.round,
    );
    final leaf = Paint()..color = AppSea.kelpLeaf;
    for (var i = 1; i <= 3; i++) {
      final at = Offset.lerp(base, top, i / 4)!;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(i.isEven ? 0.5 : -0.5);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset((i.isEven ? 1 : -1) * height * 0.03, 0),
          width: height * 0.07,
          height: height * 0.025,
        ),
        leaf,
      );
      canvas.restore();
    }
  }

  /// Núi lửa ngầm: black rock, lava cracks that glow (brighter at night), bubble columns rising
  /// from the vents, a red coral.
  void _volcano(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;
    final rock = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.86)
      ..lineTo(w * 0.13, h * 0.82)
      ..lineTo(w * 0.23, h * 0.71)
      ..lineTo(w * 0.32, h * 0.7)
      ..lineTo(w * 0.4, h * 0.82)
      ..lineTo(w * 0.57, h * 0.85)
      ..lineTo(w * 0.7, h * 0.74)
      ..lineTo(w * 0.8, h * 0.73)
      ..lineTo(w * 0.87, h * 0.83)
      ..lineTo(w, h * 0.86)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      rock,
      Paint()..color = isNight ? _night(AppSea.volcanoRock) : AppSea.volcanoRock,
    );
    final glow = isNight ? 1.0 : 0.55 + 0.45 * math.sin(t * 2 * math.pi * 3).abs();
    final lava = Paint()
      ..color = AppSea.lava.withValues(alpha: glow)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.012
      ..strokeCap = StrokeCap.round;
    final bubble = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final (x, top) in const [(0.275, 0.705), (0.75, 0.735)]) {
      final vent = Offset(w * x, h * top);
      canvas.drawPath(
        Path()
          ..moveTo(vent.dx - w * 0.02, vent.dy)
          ..lineTo(vent.dx, vent.dy + h * 0.03)
          ..lineTo(vent.dx + w * 0.02, vent.dy),
        lava,
      );
      for (var i = 0; i < 3; i++) {
        final progress = (t * 3 + i / 3 + x) % 1;
        bubble.color = AppSea.bubble.withValues(alpha: AppSea.bubble.a * (1 - progress));
        canvas.drawCircle(
          Offset(
            vent.dx + math.sin(progress * 8) * 3,
            vent.dy - progress * (vent.dy - h * skyShare),
          ),
          2 + i.toDouble(),
          bubble,
        );
      }
    }
    _coral(canvas, Offset(w * 0.5, h * 0.85), h * 0.12, AppSea.volcanoCoral);
    canvas.drawCircle(Offset(w * 0.6, h * 0.84), h * 0.025, Paint()..color = AppSea.coralOrange);
  }

  /// Thành phố chìm: faded far ruins (their windows light up at night), near columns under an
  /// arch, a fallen block and a treasure glint.
  void _ruins(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;
    final floor = h * AppSea.floorTop;
    final far = Paint()
      ..color = (isNight ? _night(AppSea.stoneShade) : AppSea.stoneShade).withValues(alpha: 0.5);
    canvas.drawRect(Rect.fromLTRB(w * 0.64, h * 0.46, w * 0.69, floor), far);
    canvas.drawRect(Rect.fromLTRB(w * 0.76, h * 0.5, w * 0.81, floor), far);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.62, h * 0.47)
        ..lineTo(w * 0.725, h * 0.4)
        ..lineTo(w * 0.83, h * 0.47)
        ..close(),
      far,
    );
    if (isNight) {
      final window = Paint()..color = AppSea.glint.withValues(alpha: 0.85);
      canvas.drawRect(Rect.fromLTWH(w * 0.705, h * 0.55, w * 0.035, h * 0.03), window);
      canvas.drawRect(Rect.fromLTWH(w * 0.705, h * 0.66, w * 0.035, h * 0.03), window);
    }
    final stone = Paint()..color = isNight ? _night(AppSea.stone) : AppSea.stone;
    canvas.drawRect(Rect.fromLTRB(w * 0.07, h * 0.66, w * 0.115, floor), stone);
    canvas.drawRect(Rect.fromLTRB(w * 0.19, h * 0.72, w * 0.235, floor), stone);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.09, h * 0.665)
        ..quadraticBezierTo(w * 0.15, h * 0.6, w * 0.212, h * 0.725),
      Paint()
        ..color = stone.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, floor - h * 0.03, w * 0.12, h * 0.03),
        const Radius.circular(2),
      ),
      stone,
    );
    final moss = Paint()..color = AppSea.moss;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.092, h * 0.66), width: w * 0.06, height: h * 0.012),
      moss,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.212, h * 0.72), width: w * 0.05, height: h * 0.01),
      moss,
    );
    final sparkle = math.sin(t * 2 * math.pi * 2).abs();
    final glint = Offset(w * 0.38, floor - h * 0.045);
    final r = h * 0.012;
    canvas.drawPath(
      Path()
        ..moveTo(glint.dx, glint.dy - r * 2)
        ..lineTo(glint.dx + r * 0.5, glint.dy - r * 0.5)
        ..lineTo(glint.dx + r * 2, glint.dy)
        ..lineTo(glint.dx + r * 0.5, glint.dy + r * 0.5)
        ..lineTo(glint.dx, glint.dy + r * 2)
        ..lineTo(glint.dx - r * 0.5, glint.dy + r * 0.5)
        ..lineTo(glint.dx - r * 2, glint.dy)
        ..lineTo(glint.dx - r * 0.5, glint.dy - r * 0.5)
        ..close(),
      Paint()..color = AppSea.glint.withValues(alpha: sparkle),
    );
  }

  /// Vịnh hoàng hôn: a palm leaning over the water, a starfish and a shell on the pink sand, and
  /// a shooting star at night.
  void _sunsetBay(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;
    final surface = h * skyShare;
    final palm = Paint()
      ..color = AppSea.palmShadow
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.012
      ..strokeCap = StrokeCap.round;
    final crown = Offset(w * 0.86, surface * 0.35);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.93, surface + h * 0.01)
        ..quadraticBezierTo(w * 0.9, surface * 0.7, crown.dx, crown.dy),
      palm,
    );
    for (final angle in const [-2.8, -2.0, -0.9, -0.2, 0.5]) {
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawPath(
        Path()
          ..moveTo(crown.dx, crown.dy)
          ..quadraticBezierTo(
            crown.dx + direction.dx * w * 0.05,
            crown.dy + direction.dy * w * 0.05 - h * 0.01,
            crown.dx + direction.dx * w * 0.09,
            crown.dy + direction.dy * w * 0.09 + h * 0.012,
          ),
        palm,
      );
    }
    final star = Path();
    final centre = Offset(w * 0.2, h * 0.955);
    for (var i = 0; i < 10; i++) {
      final radius = (i.isEven ? 1 : 0.45) * h * 0.022;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = centre + Offset(radius * math.cos(angle), radius * math.sin(angle));
      i == 0 ? star.moveTo(point.dx, point.dy) : star.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(star..close(), Paint()..color = AppSea.coralPink);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.72, h * 0.962), width: h * 0.03, height: h * 0.018),
      Paint()..color = AppSea.shell,
    );
    if (isNight) {
      final progress = (t * 1.5) % 1;
      if (progress < 0.3) {
        final head = Offset(
          w * (0.1 + 0.6 * progress / 0.3),
          surface * (0.15 + 0.3 * progress / 0.3),
        );
        canvas.drawLine(
          head,
          head - Offset(w * 0.08, surface * 0.04),
          Paint()
            ..color = AppSea.star.withValues(alpha: 1 - progress / 0.3)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  /// An iceberg floating at the waterline, bobbing gently.
  void _iceberg(Canvas canvas, Offset waterline, double height, double t, double offset) {
    final bob = math.sin(t * 2 * math.pi + offset) * 2;
    final x = waterline.dx;
    final y = waterline.dy + bob;
    final above = Path()
      ..moveTo(x - height * 0.8, y)
      ..lineTo(x - height * 0.3, y - height * 0.7)
      ..lineTo(x + height * 0.1, y - height * 0.45)
      ..lineTo(x + height * 0.35, y - height)
      ..lineTo(x + height * 0.9, y)
      ..close();
    canvas.drawPath(above, Paint()..color = AppSea.iceberg);
    final below = Path()
      ..moveTo(x - height * 0.8, y)
      ..lineTo(x + height * 0.9, y)
      ..lineTo(x + height * 0.5, y + height * 0.9)
      ..lineTo(x - height * 0.5, y + height * 0.7)
      ..close();
    canvas.drawPath(below, Paint()..color = AppSea.icebergShade.withValues(alpha: 0.6));
  }

  /// Glowing dots drifting up in the deep sea.
  void _plankton(Canvas canvas, Size size, double t) {
    final paint = Paint()..color = AppSea.plankton;
    for (var i = 0; i < 12; i++) {
      final progress = (t * 0.5 + i / 12) % 1;
      final x = size.width * (((i * 53) % 100) / 100) + math.sin(progress * 5 + i) * 6;
      final y = size.height - progress * size.height * (1 - skyShare);
      canvas.drawCircle(Offset(x, y), 1.5 + (i % 2), paint);
    }
  }

  /// A jellyfish: a dome with four wavy tentacles, sized by the scene's shorter side.
  void _jellyfish(Canvas canvas, Offset centre, double side) {
    final r = side * 0.06;
    final paint = Paint()..color = AppSea.jelly;
    canvas.drawArc(Rect.fromCircle(center: centre, radius: r), math.pi, math.pi, true, paint);
    final tentacle = Paint()
      ..color = AppSea.jelly
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final x = centre.dx - r * 0.6 + i * r * 0.4;
      final path = Path()
        ..moveTo(x, centre.dy)
        ..quadraticBezierTo(x - 4, centre.dy + r * 0.8, x, centre.dy + r * 1.6);
      canvas.drawPath(path, tentacle);
    }
  }

  void _wave(
    Canvas canvas,
    Size size, {
    required double top,
    required double amplitude,
    required double phase,
    required Color colour,
  }) {
    final path = Path()..moveTo(0, size.height);
    const steps = 24;
    for (var s = 0; s <= steps; s++) {
      final x = size.width * s / steps;
      final y = top + amplitude * math.sin(phase + s / steps * 2 * math.pi * 1.5);
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = colour);
    final crest = Path();
    for (var s = 0; s <= steps; s++) {
      final x = size.width * s / steps;
      final y = top + amplitude * math.sin(phase + s / steps * 2 * math.pi * 1.5);
      s == 0 ? crest.moveTo(x, y) : crest.lineTo(x, y);
    }
    canvas.drawPath(
      crest,
      Paint()
        ..color = Color.lerp(colour, Colors.white, 0.35)!.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// The sun or the moon: a soft glow, a shaded disc and a highlight (spec 019).
  void _orb(Canvas canvas, Offset centre, double radius, Color colour) {
    canvas.drawCircle(
      centre,
      radius * 2.2,
      Paint()
        ..shader = RadialGradient(
          colors: [colour.withValues(alpha: 0.45), colour.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: centre, radius: radius * 2.2)),
    );
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: [Color.lerp(colour, Colors.white, 0.6)!, colour],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  void _seaweed(
    Canvas canvas,
    Offset base,
    double height,
    double t,
    double offset, {
    Color? colour,
  }) {
    final sway = math.sin(t * 2 * math.pi + offset) * 6;
    final path = Path()
      ..moveTo(base.dx - 4, base.dy)
      ..quadraticBezierTo(
        base.dx - 10 + sway,
        base.dy - height / 2,
        base.dx + sway,
        base.dy - height,
      )
      ..quadraticBezierTo(base.dx + 10 + sway, base.dy - height / 2, base.dx + 4, base.dy)
      ..close();
    final fill = colour ?? (offset > 1 ? AppSea.seaweedDark : AppSea.seaweed);
    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(colors: [fill, Color.lerp(fill, Colors.white, 0.3)!, fill])
            .createShader(bounds),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.lerp(fill, Colors.black, 0.3)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _fish(
    Canvas canvas,
    Size size, {
    required double progress,
    required double row,
    required double scale,
  }) {
    final x = -20 + (size.width + 40) * progress;
    final y = size.height * row;
    final body = Rect.fromCenter(center: Offset(x, y), width: 18 * scale, height: 10 * scale);
    final tail = Path()
      ..moveTo(body.left + 2, y)
      ..lineTo(body.left - 7 * scale, y - 5 * scale)
      ..lineTo(body.left - 7 * scale, y + 5 * scale)
      ..close();
    final outline = Paint()
      ..color = Color.lerp(AppSea.fishFin, Colors.black, 0.35)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(tail, Paint()..color = AppSea.fishFin);
    canvas.drawPath(tail, outline);
    canvas.drawOval(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.5),
          colors: [Color.lerp(AppSea.fish, Colors.white, 0.5)!, AppSea.fish],
        ).createShader(body),
    );
    canvas.drawOval(body, outline);
    canvas.drawCircle(
      Offset(body.right - 4 * scale, y - scale),
      1.2 * scale,
      Paint()..color = AppSea.fishEye,
    );
  }

  void _bottle(Canvas canvas, Offset centre) {
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(-0.5);
    final paint = Paint()..color = AppSea.litter;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 10, height: 24),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.drawRect(Rect.fromCenter(center: const Offset(0, -14), width: 5, height: 6), paint);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 10, height: 7),
      Paint()..color = AppSea.litterLabel,
    );
    canvas.restore();
  }

  void _bag(Canvas canvas, Offset centre) {
    final path = Path()
      ..moveTo(centre.dx - 10, centre.dy - 8)
      ..quadraticBezierTo(centre.dx, centre.dy - 14, centre.dx + 10, centre.dy - 8)
      ..lineTo(centre.dx + 12, centre.dy + 10)
      ..quadraticBezierTo(centre.dx, centre.dy + 14, centre.dx - 12, centre.dy + 10)
      ..close();
    canvas.drawPath(path, Paint()..color = AppSea.litter.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(SeaPainter oldDelegate) =>
      oldDelegate.clarity != clarity ||
      oldDelegate.isNight != isNight ||
      oldDelegate.loop != loop ||
      oldDelegate.place != place ||
      oldDelegate.skyShare != skyShare;
}
