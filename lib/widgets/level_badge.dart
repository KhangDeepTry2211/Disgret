// 4.2 Thành tích – huy hiệu cấp độ tự vẽ bằng widget: hình lục giác, icon Material và số cấp.
// Đã đạt: nền màu chính (primary), viền màu nhấn (tertiary). Chưa đạt: xám, có ổ khoá.
// Kèm hộp thoại chúc mừng khi lên cấp.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/achievements.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

class LevelBadge extends StatelessWidget {
  const LevelBadge({
    required this.level,
    required this.unlocked,
    this.size = AppHabit.levelBadge,
    super.key,
  });

  /// Cấp 1–9.
  final int level;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fill = unlocked ? scheme.primary : scheme.outlineVariant;
    final border = unlocked ? scheme.tertiary : scheme.outline;
    final foreground = unlocked ? scheme.onPrimary : scheme.onSurfaceVariant;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HexagonPainter(fill: fill, border: border, strokeWidth: size * 0.06),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                unlocked
                    ? AppIcons.levelIcons[(level - 1) % AppIcons.levelIcons.length]
                    : AppIcons.lock,
                size: size * 0.36,
                color: foreground,
              ),
              Text(
                '$level',
                style: theme.textTheme.labelLarge?.copyWith(color: foreground, height: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lục giác đứng (một đỉnh ở trên), bo nhẹ các góc bằng nét viền tròn đầu.
class _HexagonPainter extends CustomPainter {
  const _HexagonPainter({required this.fill, required this.border, required this.strokeWidth});

  final Color fill;
  final Color border;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - strokeWidth;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_HexagonPainter oldDelegate) =>
      fill != oldDelegate.fill ||
      border != oldDelegate.border ||
      strokeWidth != oldDelegate.strokeWidth;
}

/// Hộp thoại chúc mừng khi vừa lên [level] với [total] lần hoàn thành.
Future<void> showLevelUpDialog(BuildContext context, {required int level, required int total}) {
  if (!kIsWeb) HapticFeedback.mediumImpact();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final next = Achievements.nextTarget(total);
      return AlertDialog(
        title: const Text('Chúc mừng! 🎉', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            LevelBadge(level: level, unlocked: true, size: AppHabit.levelBadgeLarge),
            const SizedBox(height: AppSpacing.md),
            Text('Bạn đã lên Cấp $level', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              next == null
                  ? 'Bạn đã hoàn thành thói quen $total lần, đạt cấp cao nhất!'
                  : 'Bạn đã hoàn thành thói quen $total lần. Còn ${next - total} lần nữa '
                        'tới Cấp ${level + 1}.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              GoRouter.of(context).push(AppRoutes.achievements);
            },
            child: const Text('Xem thành tích'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tuyệt!'),
          ),
        ],
      );
    },
  );
}
