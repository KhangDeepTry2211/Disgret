// 4.2 Hành trình 66 ngày.
// PARKED (ADR-0004, docs/architecture/parked-features.md): no screen shows it; kept with its test
// so it can return. Restore by rendering `HabitJourney(days: HabitScience.journeyDays(history))`
// in a section of habit_detail_screen.dart.
import 'package:material_ui/material_ui.dart';

import '../data/habit_science.dart';
import '../theme/app_theme.dart';
import 'gradient_progress_bar.dart';

/// Thanh Hành trình 66 ngày và 4 huy hiệu: đạt thì màu nhấn, chưa đạt thì xám.
class HabitJourney extends StatelessWidget {
  const HabitJourney({required this.days, super.key});

  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const total = HabitScience.habitFormationDays;
    final next = HabitScience.nextBadge(days);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${days.clamp(0, total)}/$total ngày hoàn thành', style: theme.textTheme.titleMedium),
        Text(
          next == null
              ? 'Bạn đã đi hết hành trình. Thói quen này đã thành của bạn!'
              : 'Còn ${next.days - days} ngày nữa tới huy hiệu "${next.name}". '
                    'Không cần liên tiếp.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        GradientProgressBar(value: days / total),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final badge in HabitScience.badges)
              Expanded(
                child: Semantics(
                  container: true,
                  label:
                      'Huy hiệu ${badge.name}, ${badge.days} ngày, '
                      '${days >= badge.days ? 'đã đạt' : 'chưa đạt'}',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Container(
                        width: AppHabit.iconTile,
                        height: AppHabit.iconTile,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: days >= badge.days ? scheme.tertiary : null,
                          border: days >= badge.days
                              ? null
                              : Border.all(color: scheme.outlineVariant, width: 1.5),
                        ),
                        child: Icon(
                          AppIcons.badge,
                          color: days >= badge.days ? scheme.onTertiary : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        badge.name,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: days >= badge.days ? scheme.onSurface : scheme.onSurfaceVariant,
                        ),
                      ),
                      Text('${badge.days} ngày', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
