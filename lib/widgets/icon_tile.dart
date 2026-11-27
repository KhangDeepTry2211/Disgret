// 5.2 Icon tile (spec 015, the lead's Farmly style): an outline icon on a pastel rounded square,
// with an optional red count badge or a sun-coloured tag in its top-right corner.
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class IconTile extends StatelessWidget {
  const IconTile({
    required this.icon,
    required this.colour,
    this.size = AppIconTile.size,
    this.badge = 0,
    this.tag,
    super.key,
  });

  final IconData icon;

  /// Pastel background and the deep colour of the same family for the icon.
  final HabitColor colour;
  final double size;

  /// A count shown in a red dot; hidden at 0.
  final int badge;

  /// A short label in a sun-coloured pill, for example the pearl count.
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = tag;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colour.background,
            borderRadius: BorderRadius.circular(size * AppIconTile.cornerShare),
          ),
          child: Icon(icon, color: colour.foreground, size: size * AppIconTile.iconShare),
        ),
        if (badge > 0)
          Positioned(
            top: -AppIconTile.badgeOffset,
            right: -AppIconTile.badgeOffset,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: AppIconTile.badge,
                minHeight: AppIconTile.badge,
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: AppRadius.pillBorder,
              ),
              alignment: Alignment.center,
              child: Text(
                '$badge',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onError),
              ),
            ),
          )
        else if (label != null)
          Positioned(
            top: -AppIconTile.badgeOffset,
            right: -AppIconTile.tagOffset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2),
              decoration: const BoxDecoration(
                color: AppColors.sun,
                borderRadius: AppRadius.pillBorder,
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSun),
              ),
            ),
          ),
      ],
    );
  }
}

/// The small round chevron at the top-right of a Farmly-style stat card.
class ChevronCircle extends StatelessWidget {
  const ChevronCircle({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: AppIconTile.chevron,
      height: AppIconTile.chevron,
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, shape: BoxShape.circle),
      child: Icon(AppIcons.next, size: AppIconTile.chevron * 0.7, color: scheme.onSurfaceVariant),
    );
  }
}
