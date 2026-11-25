// 5.3 Gret và biển sống: paints the sky, three wave bands, seaweed, bubbles, fish and litter
// (spec 003 FR-007, FR-017). Colours come only from AppSea; the water blends from clear to murky
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
  double get _murk => ((70 - clarity) / 70).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final t = loop.value;
    final w = size.width;
    final h = size.height;
    final clear = _clearColours();
    final murky = isNight ? AppSea.murkyNight : AppSea.murkyDay;

    // Sky.
    canvas.drawRect(Offset.zero & size, Paint()..color = _skyColour());
    if (isNight) {
      canvas.drawCircle(Offset(w * 0.82, h * 0.12), h * 0.06, Paint()..color = AppSea.moon);
    }

    // Three wave bands, each drifting at its own speed.
    final tops = [skyShare, 0.50, 0.72];
    for (var i = 0; i < 3; i++) {
      final colour = Color.lerp(clear[i], murky[i], _murk)!;
      final phase = 2 * math.pi * t * (i.isEven ? 1 : -1) + i;
      _wave(canvas, size, top: h * tops[i], amplitude: h * 0.025, phase: phase, colour: colour);
    }

    switch (place) {
      case SeaPlace.home:
        _seaweed(canvas, Offset(w * 0.10, h), h * 0.30, t, 0);
        _seaweed(canvas, Offset(w * 0.16, h), h * 0.22, t, 1.3);
        _seaweed(canvas, Offset(w * 0.88, h), h * 0.26, t, 2.1);
      case SeaPlace.coral:
        _coral(canvas, Offset(w * 0.12, h), h * 0.24, AppSea.coralPink);
        _coral(canvas, Offset(w * 0.84, h), h * 0.30, AppSea.coralOrange);
        _coral(canvas, Offset(w * 0.93, h), h * 0.18, AppSea.coralPink);
        _seaweed(canvas, Offset(w * 0.22, h), h * 0.20, t, 2.1);
      case SeaPlace.ice:
        _iceberg(canvas, Offset(w * 0.18, h * skyShare), h * 0.16, t, 0);
        _iceberg(canvas, Offset(w * 0.86, h * skyShare), h * 0.11, t, 1.7);
      case SeaPlace.deep:
        _plankton(canvas, size, t);
        _jellyfish(canvas, Offset(w * 0.82, h * (0.55 + 0.05 * math.sin(t * 2 * math.pi))), h);
    }

    // Bubbles rise from the bottom; fewer when the sea is murky.
    final bubbles = clarity >= 70 ? 7 : (clarity >= 40 ? 4 : 2);
    final bubblePaint = Paint()..color = AppSea.bubble;
    for (var i = 0; i < bubbles; i++) {
      final progress = (t + i / bubbles) % 1;
      final x = w * (0.2 + 0.6 * ((i * 37) % 100) / 100) + math.sin(progress * 6 + i) * 4;
      final y = h - progress * h * (1 - skyShare);
      canvas.drawCircle(Offset(x, y), 2.0 + (i % 3), bubblePaint);
    }

    if (clarity >= 70 && place != SeaPlace.deep) {
      _fish(canvas, size, progress: t, row: 0.62, scale: 1);
      _fish(canvas, size, progress: (t + 0.5) % 1, row: 0.82, scale: 0.75);
    }
    if (clarity < 40) {
      _bottle(canvas, Offset(w * 0.22, h * 0.56 + math.sin(t * 2 * math.pi) * 3));
      _bag(canvas, Offset(w * 0.80, h * 0.66 + math.cos(t * 2 * math.pi) * 3));
    }
  }

  Color _night(Color colour) => Color.lerp(colour, AppSea.skyNight, AppSea.nightBlend)!;

  Color _skyColour() {
    final day = switch (place) {
      SeaPlace.home => AppSea.skyDay,
      SeaPlace.coral => AppSea.coralSky,
      SeaPlace.ice => AppSea.iceSky,
      SeaPlace.deep => AppSea.deepSky,
    };
    if (!isNight) return day;
    return place == SeaPlace.home ? AppSea.skyNight : _night(day);
  }

  List<Color> _clearColours() {
    final day = switch (place) {
      SeaPlace.home => AppSea.clearDay,
      SeaPlace.coral => AppSea.coralClear,
      SeaPlace.ice => AppSea.iceClear,
      SeaPlace.deep => AppSea.deepClear,
    };
    if (!isNight) return day;
    return place == SeaPlace.home ? AppSea.clearNight : [for (final c in day) _night(c)];
  }

  /// A branching coral on the sea floor.
  void _coral(Canvas canvas, Offset base, double height, Color colour) {
    final paint = Paint()
      ..color = colour
      ..strokeWidth = height * 0.12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final top = Offset(base.dx, base.dy - height);
    canvas.drawLine(base, top, paint);
    for (final side in [-1.0, 1.0]) {
      final joint = Offset(base.dx, base.dy - height * (side < 0 ? 0.45 : 0.62));
      canvas.drawLine(joint, joint.translate(side * height * 0.35, -height * 0.3), paint);
    }
    canvas.drawCircle(top, height * 0.09, Paint()..color = colour);
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

  /// A jellyfish: a dome with four wavy tentacles.
  void _jellyfish(Canvas canvas, Offset centre, double sceneHeight) {
    final r = sceneHeight * 0.06;
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
  }

  void _seaweed(Canvas canvas, Offset base, double height, double t, double offset) {
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
    canvas.drawPath(path, Paint()..color = offset > 1 ? AppSea.seaweedDark : AppSea.seaweed);
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
    canvas.drawOval(body, Paint()..color = AppSea.fish);
    final tail = Path()
      ..moveTo(body.left + 2, y)
      ..lineTo(body.left - 7 * scale, y - 5 * scale)
      ..lineTo(body.left - 7 * scale, y + 5 * scale)
      ..close();
    canvas.drawPath(tail, Paint()..color = AppSea.fishFin);
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
