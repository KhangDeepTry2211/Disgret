// 5.2 Vòng tiến độ quanh đồng hồ đếm ngược (3.1), tô màu nhấn (tertiary) đặc.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.progress,
    required this.child,
    this.size = 264,
    this.strokeWidth = 12,
    super.key,
  });

  /// Tiến độ từ 0 đến 1.
  final double progress;
  final Widget child;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Tiến độ phiên học',
      value: '${(progress.clamp(0.0, 1.0) * 100).round()}%',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: progress.clamp(0.0, 1.0),
            strokeWidth: strokeWidth,
            trackColor: theme.colorScheme.outlineVariant,
            color: theme.colorScheme.tertiary,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.color,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ringRect = rect.deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawOval(ringRect, paint..color = trackColor);

    if (progress > 0) {
      paint
        ..strokeCap = StrokeCap.round
        ..color = color;
      // Vẽ từ đỉnh vòng tròn, theo chiều kim đồng hồ.
      canvas.drawArc(ringRect, -math.pi / 2, 2 * math.pi * progress, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      strokeWidth != oldDelegate.strokeWidth ||
      trackColor != oldDelegate.trackColor ||
      color != oldDelegate.color;
}
