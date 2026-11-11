// 5.2 Nút viên thuốc gradient, chỉ dùng cho nút nổi bật "Bắt đầu".
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class GradientPillButton extends StatelessWidget {
  const GradientPillButton({
    required this.label,
    required this.onPressed,
    this.height = 72,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.white);

    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          height: height,
          decoration: const BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: AppRadius.pillBorder,
          ),
          child: InkWell(
            onTap: onPressed,
            customBorder: const StadiumBorder(),
            child: Center(child: Text(label, style: textStyle)),
          ),
        ),
      ),
    );
  }
}
