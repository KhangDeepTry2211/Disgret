// 5.2 Vòng streak gradient: số ngày học liên tiếp nằm giữa vòng.
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class StreakRing extends StatelessWidget {
  const StreakRing({required this.days, this.size = 176, this.ringWidth = 10, super.key});

  final int days;
  final double size;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Hai hình tròn lồng nhau: hình ngoài tô gradient, hình trong tô màu nền.
    return Semantics(
      label: 'Chuỗi $days ngày học liên tiếp',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(ringWidth),
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.streakGradient),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.surface),
          // Thu nhỏ chữ nếu người dùng đặt cỡ chữ hệ thống quá lớn.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$days', style: theme.textTheme.displayMedium),
                Text('ngày liên tiếp', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
