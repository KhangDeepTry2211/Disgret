// 5.3 Gret và biển sống: compact streak card next to the clarity card (spec 003 FR-009,
// FR-013). `highlight` makes the flame pop once, for example after a session that grew the streak.
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'icon_tile.dart';
import 'motion/count_up_text.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({required this.days, this.highlight = false, this.onTap, super.key});

  final int days;
  final bool highlight;

  /// Opens more detail; shows the round chevron (spec 015).
  final VoidCallback? onTap;

  /// Peach from the pastel habit palette: warm colours are kept for streaks and rewards.
  static const int _paletteIndex = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = AppHabitColors.of(_paletteIndex);
    final off = MediaQuery.disableAnimationsOf(context);

    final flame = IconTile(icon: AppIcons.streak, colour: colour, size: AppStatCard.badge);

    return Semantics(
      container: true,
      label: AppStrings.streakSemantics(days),
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppStatCard.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (highlight && !off)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: AppMotion.ringFill,
                        builder: (context, t, child) => Transform.scale(
                          scale: 1 + AppStatCard.popScale * (1 - (2 * t - 1).abs()),
                          child: child,
                        ),
                        child: flame,
                      )
                    else
                      flame,
                    const Spacer(),
                    if (onTap != null) const ChevronCircle(),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                CountUpText(
                  value: days,
                  format: AppStrings.streakDays,
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  AppStrings.streakLabel,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
