// 5.6 Quán San Hô: the room itself (spec 006 FR-003), redrawn cosy in the soft 3D look of the
// mascots (spec 019 user story 2): a shaded wall with a dotted wallpaper, a wood wainscot with a
// moulding, a plank floor with staggered joints, sun beams from the windows by day and warm pools
// of lamp light by night, bunting on a string (with little lights at night), shaded pendant lamps
// and a round rug under Gret's desk. Windows, the counter, tables, plants and characters are
// widgets on top (sea_cafe_scene).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

class SeaCafePainter extends CustomPainter {
  const SeaCafePainter({required this.isNight});

  final bool isNight;

  @override
  void paint(Canvas canvas, Size size) {
    final floorTop = size.height * AppCafe.floorTop;
    final panelTop = floorTop - size.height * AppCafe.panelHeight;
    final wall = isNight ? AppCafe.wallNight : AppCafe.wallDay;

    // Wall: lighter towards the ceiling, with a soft dotted wallpaper.
    final wallRect = Rect.fromLTRB(0, 0, size.width, panelTop);
    canvas.drawRect(
      wallRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(wall, Colors.white, 0.18)!, wall],
        ).createShader(wallRect),
    );
    final dot = Paint()..color = Color.lerp(wall, AppCafe.wallpaper, isNight ? 0.25 : 0.5)!;
    const step = AppCafe.wallpaperStep;
    for (var y = step; y < panelTop - step / 2; y += step) {
      final shift = (y ~/ step).isEven ? 0.0 : step / 2;
      for (var x = shift; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), AppCafe.wallpaperDot, dot);
      }
    }

    // Wainscot: wood panels under a moulding.
    final panel = isNight ? AppCafe.panelNight : AppCafe.panelDay;
    final panelRect = Rect.fromLTRB(0, panelTop, size.width, floorTop);
    canvas.drawRect(panelRect, Paint()..color = panel);
    final seam = Paint()
      ..color = Color.lerp(panel, Colors.black, 0.12)!
      ..strokeWidth = 1.5;
    for (var x = size.width / 8; x < size.width; x += size.width / 4) {
      canvas.drawLine(Offset(x, panelTop + 6), Offset(x, floorTop - 4), seam);
    }
    canvas.drawRect(
      Rect.fromLTRB(0, panelTop - 3, size.width, panelTop + 3),
      Paint()..color = Color.lerp(panel, Colors.white, 0.3)!,
    );

    // Floor: lighter at the back, planks that open towards the viewer, staggered joints.
    final floor = isNight ? AppCafe.floorNight : AppCafe.floorDay;
    final floorRect = Rect.fromLTRB(0, floorTop, size.width, size.height);
    canvas.drawRect(
      floorRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(floor, Colors.white, 0.12)!, floor],
        ).createShader(floorRect),
    );
    final plank = Paint()
      ..color = isNight ? AppCafe.plankNight : AppCafe.plankDay
      ..strokeWidth = 2;
    var previous = floorTop;
    for (var i = 1; i < 6; i++) {
      final y = floorTop + (size.height - floorTop) * i * i / 30;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), plank);
      for (var x = (i.isEven ? 0.2 : 0.45) * size.width; x < size.width; x += size.width / 2) {
        canvas.drawLine(Offset(x, previous), Offset(x, y), plank..strokeWidth = 1.5);
      }
      plank.strokeWidth = 2;
      previous = y;
    }

    if (isNight) {
      for (final x in AppCafe.lampXs) {
        _glow(canvas, Offset(size.width * x, floorTop + size.height * 0.06), size.width * 0.3);
      }
    } else {
      for (final window in const [AppCafe.leftWindow, AppCafe.rightWindow]) {
        _beam(canvas, size, window, floorTop);
      }
    }

    // A round rug under Gret's desk at the front.
    final rug = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * AppCafe.rugY),
      width: size.width * AppCafe.rugWidth,
      height: size.height * AppCafe.rugHeight,
    );
    canvas.drawOval(rug, Paint()..color = isNight ? AppCafe.rugNight : AppCafe.rug);
    canvas.drawOval(
      rug.deflate(size.width * 0.03),
      Paint()
        ..color = AppCafe.rugBorder.withValues(alpha: isNight ? 0.5 : 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    _bunting(canvas, size);
    for (final x in AppCafe.lampXs) {
      _lamp(canvas, Offset(size.width * x, size.height * 0.12));
    }
  }

  /// Daylight falling from a window across the floor.
  void _beam(Canvas canvas, Size size, Rect window, double floorTop) {
    final left = window.left * size.width;
    final right = window.right * size.width;
    final towardsCentre = (0.5 - window.center.dx) * size.width * 0.6;
    final path = Path()
      ..moveTo(left, floorTop)
      ..lineTo(right, floorTop)
      ..lineTo(right + towardsCentre + size.width * 0.08, size.height)
      ..lineTo(left + towardsCentre - size.width * 0.04, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppCafe.sunBeam);
  }

  void _glow(Canvas canvas, Offset centre, double radius) {
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [AppCafe.lamp.withValues(alpha: 0.28), AppCafe.lamp.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  void _bunting(Canvas canvas, Size size) {
    const flags = 11;
    final step = size.width / flags;
    final height = size.height * 0.05;
    final string = Path()..moveTo(0, 2);
    for (var i = 0; i < flags; i++) {
      string.quadraticBezierTo(i * step + step / 2, 6, (i + 1) * step, 2);
    }
    canvas.drawPath(
      string,
      Paint()
        ..color = AppCafe.cord
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (var i = 0; i < flags; i++) {
      final left = i * step;
      final colour = AppCafe.bunting[i % AppCafe.bunting.length];
      final path = Path()
        ..moveTo(left + 2, 3)
        ..lineTo(left + step - 2, 3)
        ..lineTo(left + step / 2, height)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(colors: [Color.lerp(colour, Colors.white, 0.25)!, colour])
              .createShader(path.getBounds()),
      );
      if (isNight) {
        final bulb = Offset(left + step, 3);
        canvas.drawCircle(bulb, 6, Paint()..color = AppCafe.lamp.withValues(alpha: 0.35));
        canvas.drawCircle(bulb, 2.2, Paint()..color = AppCafe.lamp);
      }
    }
  }

  void _lamp(Canvas canvas, Offset bottom) {
    canvas.drawLine(
      Offset(bottom.dx, 0),
      bottom,
      Paint()
        ..color = AppCafe.cord
        ..strokeWidth = 2,
    );
    if (isNight) _glow(canvas, bottom.translate(0, 14), 46);
    final shade = Rect.fromCenter(center: bottom.translate(0, 8), width: 30, height: 24);
    canvas.drawArc(
      shade,
      math.pi,
      math.pi,
      true,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.6),
          colors: [Color.lerp(AppCafe.lamp, Colors.white, 0.5)!, AppCafe.lampShade],
        ).createShader(shade),
    );
    canvas.drawCircle(
      bottom.translate(0, 10),
      4,
      Paint()..color = isNight ? Colors.white : AppCafe.lamp,
    );
  }

  @override
  bool shouldRepaint(SeaCafePainter oldDelegate) => oldDelegate.isNight != isNight;
}
