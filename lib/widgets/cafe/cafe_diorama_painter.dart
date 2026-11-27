// 5.6 Quán San Hô, "Phòng mô hình" look (spec 019 user story 3): the café as a small isometric
// room cut open at the front and floating on a soft backdrop, like a toy diorama. Two walls with
// a window onto the sea each, a tiled floor, a rug, bunting along the walls and a base slab.
// The counter, tables, friends and Gret's desk are widgets on top (sea_cafe_scene).
import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

class CafeDioramaPainter extends CustomPainter {
  const CafeDioramaPainter({required this.isNight});

  final bool isNight;

  /// Corners of the floor diamond (back, left, front, right) as shares of the scene.
  static const Offset back = Offset(0.5, 0.40);
  static const Offset left = Offset(0.03, 0.64);
  static const Offset front = Offset(0.5, 0.90);
  static const Offset right = Offset(0.97, 0.64);

  /// Wall height and base slab thickness as shares of the scene height.
  static const double wallHeight = 0.18;
  static const double slab = 0.035;

  @override
  void paint(Canvas canvas, Size size) {
    Offset at(Offset share) => Offset(share.dx * size.width, share.dy * size.height);
    final up = Offset(0, -wallHeight * size.height);
    final down = Offset(0, slab * size.height);
    final b = at(back), l = at(left), f = at(front), r = at(right);

    // Backdrop and the room's shadow.
    final backdrop = Offset.zero & size;
    canvas.drawRect(
      backdrop,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isNight
              ? const [AppCafe.dioramaSkyNight, AppCafe.dioramaFloorBgNight]
              : const [AppCafe.dioramaSky, AppCafe.dioramaFloorBg],
        ).createShader(backdrop),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: f.translate(0, size.height * 0.05),
        width: size.width * 0.9,
        height: size.height * 0.06,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    // Base slab under the floor's front edges.
    final panel = isNight ? AppCafe.panelNight : AppCafe.panelDay;
    canvas.drawPath(_poly([l, f, f + down, l + down]), Paint()..color = _shade(panel, 0.1));
    canvas.drawPath(_poly([f, r, r + down, f + down]), Paint()..color = _shade(panel, 0.22));

    // Walls: the left one in light, the right one a touch darker.
    final wall = isNight ? AppCafe.wallNight : AppCafe.wallDay;
    canvas.drawPath(_poly([l, b, b + up, l + up]), Paint()..color = wall);
    canvas.drawPath(_poly([b, r, r + up, b + up]), Paint()..color = _shade(wall, 0.08));
    // Wainscot along the bottom of each wall.
    final low = up * 0.3;
    canvas.drawPath(_poly([l, b, b + low, l + low]), Paint()..color = panel);
    canvas.drawPath(_poly([b, r, r + low, b + low]), Paint()..color = _shade(panel, 0.08));

    // The walls' cut edges: a thick light cap along the top and a darker edge at each end, so
    // they read as walls of a cut-open room rather than a roof.
    canvas.drawPath(
      Path()
        ..moveTo((l + up).dx, (l + up).dy)
        ..lineTo((b + up).dx, (b + up).dy)
        ..lineTo((r + up).dx, (r + up).dy),
      Paint()
        ..color = Color.lerp(wall, Colors.white, 0.45)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeJoin = StrokeJoin.round,
    );
    final edge = Paint()
      ..color = _shade(wall, 0.25)
      ..strokeWidth = 3;
    canvas.drawLine(l, l + up, edge);
    canvas.drawLine(r, r + up, edge);
    canvas.drawLine(
      b,
      b + up,
      Paint()
        ..color = _shade(wall, 0.15)
        ..strokeWidth = 1.5,
    );

    // A window on each wall, looking out on the sea.
    _window(canvas, l, b, up, 0.3, 0.62);
    _window(canvas, b, r, up, 0.38, 0.7);

    // Floor with a diamond tile grid.
    final floor = isNight ? AppCafe.floorNight : AppCafe.floorDay;
    canvas.drawPath(_poly([b, r, f, l]), Paint()..color = floor);
    final tile = Paint()
      ..color = isNight ? AppCafe.plankNight : AppCafe.plankDay
      ..strokeWidth = 1.2;
    for (var i = 1; i < 6; i++) {
      final t = i / 6;
      canvas.drawLine(Offset.lerp(b, l, t)!, Offset.lerp(r, f, t)!, tile);
      canvas.drawLine(Offset.lerp(b, r, t)!, Offset.lerp(l, f, t)!, tile);
    }

    // A rug in front of Gret's desk.
    final rugCentre = Offset.lerp(b, f, 0.72)!;
    canvas.drawOval(
      Rect.fromCenter(center: rugCentre, width: size.width * 0.42, height: size.height * 0.08),
      Paint()..color = isNight ? AppCafe.rugNight : AppCafe.rug,
    );

    // Bunting along the top of both walls.
    for (final (from, to) in [(l + up, b + up), (b + up, r + up)]) {
      const flags = 6;
      for (var i = 0; i < flags; i++) {
        final a = Offset.lerp(from, to, i / flags)!;
        final c = Offset.lerp(from, to, (i + 1) / flags)!;
        final tip = Offset.lerp(a, c, 0.5)!.translate(0, size.height * 0.03);
        canvas.drawPath(
          _poly([a, c, tip]),
          Paint()..color = AppCafe.bunting[i % AppCafe.bunting.length],
        );
        if (isNight) canvas.drawCircle(c, 2.2, Paint()..color = AppCafe.lamp);
      }
    }
  }

  /// A window on the wall from [a] to [b], between shares [from] and [to] along it.
  void _window(Canvas canvas, Offset a, Offset b, Offset up, double from, double to) {
    final bottom = up * 0.42;
    final top = up * 0.88;
    final p1 = Offset.lerp(a, b, from)! + bottom;
    final p2 = Offset.lerp(a, b, to)! + bottom;
    final p3 = Offset.lerp(a, b, to)! + top;
    final p4 = Offset.lerp(a, b, from)! + top;
    final glass = _poly([p1, p2, p3, p4]);
    canvas.drawPath(
      glass,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isNight
              ? const [AppSea.skyNight, AppCafe.dioramaWindowSeaNight]
              : const [AppSea.skyDay, AppCafe.dioramaWindowSea],
        ).createShader(glass.getBounds()),
    );
    canvas.drawPath(
      glass,
      Paint()
        ..color = isNight ? AppCafe.frameNight : AppCafe.frame
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  static Path _poly(List<Offset> points) => Path()..addPolygon(points, true);

  static Color _shade(Color colour, double amount) => Color.lerp(colour, Colors.black, amount)!;

  @override
  bool shouldRepaint(CafeDioramaPainter oldDelegate) => oldDelegate.isNight != isNight;
}
