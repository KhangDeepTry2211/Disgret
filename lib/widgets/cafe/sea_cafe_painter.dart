// 5.6 Quán San Hô: the room itself (spec 006 FR-003): wall with bunting and lamps, a panel band,
// a plank floor. Windows, the counter, tables and characters are widgets on top (sea_cafe_scene).
import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

class SeaCafePainter extends CustomPainter {
  const SeaCafePainter({required this.isNight});

  final bool isNight;

  @override
  void paint(Canvas canvas, Size size) {
    final floorTop = size.height * AppCafe.floorTop;
    final panelTop = floorTop - size.height * AppCafe.panelHeight;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = isNight ? AppCafe.wallNight : AppCafe.wallDay,
    );
    canvas.drawRect(
      Rect.fromLTRB(0, panelTop, size.width, floorTop),
      Paint()..color = isNight ? AppCafe.panelNight : AppCafe.panelDay,
    );
    canvas.drawRect(
      Rect.fromLTRB(0, floorTop, size.width, size.height),
      Paint()..color = isNight ? AppCafe.floorNight : AppCafe.floorDay,
    );

    // Floor planks: a few lines that open towards the viewer.
    final plank = Paint()
      ..color = isNight ? AppCafe.plankNight : AppCafe.plankDay
      ..strokeWidth = 2;
    for (var i = 1; i < 4; i++) {
      final y = floorTop + (size.height - floorTop) * i * i / 16;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), plank);
    }

    _bunting(canvas, size);
    for (final x in const [0.33, 0.67]) {
      _lamp(canvas, Offset(size.width * x, size.height * 0.12));
    }
  }

  void _bunting(Canvas canvas, Size size) {
    const flags = 11;
    final step = size.width / flags;
    final height = size.height * 0.05;
    for (var i = 0; i < flags; i++) {
      final left = i * step;
      final path = Path()
        ..moveTo(left + 2, 0)
        ..lineTo(left + step - 2, 0)
        ..lineTo(left + step / 2, height)
        ..close();
      canvas.drawPath(path, Paint()..color = AppCafe.bunting[i % AppCafe.bunting.length]);
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
    if (isNight) {
      canvas.drawCircle(
        bottom.translate(0, 6),
        26,
        Paint()
          ..color = AppCafe.lamp.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
    canvas.drawArc(
      Rect.fromCenter(center: bottom.translate(0, 8), width: 26, height: 22),
      3.1416,
      3.1416,
      true,
      Paint()..color = AppCafe.lamp,
    );
  }

  @override
  bool shouldRepaint(SeaCafePainter oldDelegate) => oldDelegate.isNight != isNight;
}
