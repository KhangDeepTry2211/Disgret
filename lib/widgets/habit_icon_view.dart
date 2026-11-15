// 4.1 Hiển thị icon của thói quen: icon Material (theo khoá) hoặc emoji.
// HabitIconTile đặt icon trên ô vuông bo góc tô màu pastel của thói quen (AppHabitColors).
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Icon Material nếu [icon] là khoá trong AppIcons.habitIcons, ngược lại hiện như emoji.
class HabitIconView extends StatelessWidget {
  const HabitIconView({required this.icon, this.size = 24, this.color, super.key});

  final String icon;
  final double size;

  /// Màu của icon Material; emoji giữ màu gốc.
  final Color? color;

  static bool isMaterialIcon(String icon) => AppIcons.habitIcons.containsKey(icon);

  @override
  Widget build(BuildContext context) {
    if (isMaterialIcon(icon)) {
      return Icon(AppIcons.habitIcon(icon), size: size, color: color);
    }
    // Emoji: cỡ chữ nhỏ hơn ô một chút để không bị cắt, căn giữa theo chiều cao dòng.
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        child: Text(icon, textAlign: TextAlign.center, style: const TextStyle(height: 1.15)),
      ),
    );
  }
}

/// Ô vuông bo góc nền pastel, icon màu đậm cùng tông.
class HabitIconTile extends StatelessWidget {
  const HabitIconTile({
    required this.icon,
    required this.colorIndex,
    this.size = AppHabit.iconTile,
    super.key,
  });

  final String icon;
  final int colorIndex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = AppHabitColors.of(colorIndex);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.background, borderRadius: AppRadius.cardBorder),
      child: HabitIconView(icon: icon, size: size * 0.55, color: color.foreground),
    );
  }
}
