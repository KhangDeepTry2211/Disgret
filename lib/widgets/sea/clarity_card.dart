// 5.3 Gret và biển sống: ring card with the sea clarity and its label (spec 003 FR-009).
import 'package:material_ui/material_ui.dart';

import '../../data/mascot_mood.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../icon_tile.dart';
import '../motion/count_up_text.dart';

class ClarityCard extends StatelessWidget {
  const ClarityCard({required this.clarity, this.onTap, super.key});

  /// 0–100.
  final double clarity;

  /// Opens more detail; shows the round chevron (spec 015).
  final VoidCallback? onTap;

  static String labelFor(double clarity) => switch (ClarityLevel.of(clarity)) {
    ClarityLevel.clear => AppStrings.clarityClear,
    ClarityLevel.hazy => AppStrings.clarityHazy,
    ClarityLevel.murky => AppStrings.clarityMurky,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final off = MediaQuery.disableAnimationsOf(context);
    final percent = clarity.round();

    return Card(
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
                  SizedBox.square(
                    dimension: AppStatCard.badge,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: off ? clarity / 100 : 0, end: clarity / 100),
                      duration: off ? Duration.zero : AppMotion.ringFill,
                      curve: AppMotion.curve,
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: AppStatCard.ringStroke,
                        strokeCap: StrokeCap.round,
                        color: theme.colorScheme.tertiary,
                        backgroundColor: AppColors.heatOf(context).first,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (onTap != null) const ChevronCircle(),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              CountUpText(
                value: percent,
                format: AppStrings.clarityPercent,
                style: theme.textTheme.titleLarge,
              ),
              Text(
                labelFor(clarity),
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
