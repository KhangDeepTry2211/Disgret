// 5.2 Nút viên thuốc nổi bật "Bắt đầu". Bảng màu Ocean không dùng gradient nên nút tô màu
// đặc (màu chính của theme); giữ tên cũ để không phải sửa các màn đang dùng.
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
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(color: scheme.onPrimary);

    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          height: height,
          decoration: BoxDecoration(color: scheme.primary, borderRadius: AppRadius.pillBorder),
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
