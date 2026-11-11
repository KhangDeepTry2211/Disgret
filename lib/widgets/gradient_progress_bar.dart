// 5.2 Thanh tiến độ gradient.
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({required this.value, this.height = 8, this.trackColor, super.key});

  /// Tiến độ từ 0 đến 1; giá trị ngoài khoảng này sẽ được chặn lại.
  final double value;
  final double height;

  /// Màu phần chưa chạy; mặc định là màu đường kẻ của theme.
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);

    return Semantics(
      label: 'Tiến độ',
      value: '${(progress * 100).round()}%',
      child: ClipRRect(
        borderRadius: AppRadius.pillBorder,
        child: Container(
          height: height,
          alignment: Alignment.centerLeft,
          color: trackColor ?? Theme.of(context).colorScheme.outlineVariant,
          child: FractionallySizedBox(
            widthFactor: progress,
            // Bắt buộc có: alignment của Container nới lỏng chiều cao,
            // thiếu dòng này phần tô sẽ cao 0 và không nhìn thấy.
            heightFactor: 1,
            child: const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.accentGradient),
            ),
          ),
        ),
      ),
    );
  }
}
