// 1.4 Thẻ kết thúc reel.
// Shown when a reel ends or fails (spec 002 FR-004). Before a session: "Bắt đầu N phút" (primary),
// "Chỉ 5 phút thôi" and, while reels remain, "Tiếp". After a distraction: only "Quay lại học".
// The screen decides what each action does (logging, StudyStarter), so this widget only renders.
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../services/motivation_dose.dart';
import '../theme/app_theme.dart';
import 'gradient_pill_button.dart';

class ReelEndCard extends StatelessWidget {
  const ReelEndCard({
    required this.actions,
    required this.plannedMinutes,
    required this.onAction,
    super.key,
  });

  /// From [MotivationDose.endCardActions], in display order.
  final List<EndCardAction> actions;

  /// N in "Bắt đầu N phút".
  final int plannedMinutes;
  final ValueChanged<EndCardAction> onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isBackToSession = actions.contains(EndCardAction.backToSession);

    return Column(
      key: const ValueKey('reel-end-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isBackToSession ? AppStrings.endCardBackTitle : AppStrings.endCardStartTitle,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.onVideo,
            shadows: AppReels.onVideoShadows,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final action in actions) _button(action),
      ],
    );
  }

  Widget _button(EndCardAction action) {
    void onPressed() => onAction(action);
    return switch (action) {
      EndCardAction.startPlanned => GradientPillButton(
        label: AppStrings.startMinutes(plannedMinutes),
        height: AppReels.buttonHeight,
        onPressed: onPressed,
      ),
      EndCardAction.backToSession => GradientPillButton(
        label: AppStrings.backToStudy,
        height: AppReels.buttonHeight,
        onPressed: onPressed,
      ),
      EndCardAction.smallStep => TextButton(
        style: TextButton.styleFrom(foregroundColor: AppColors.onVideo),
        onPressed: onPressed,
        child: const Text(AppStrings.smallStep),
      ),
      EndCardAction.next => OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onVideo,
          side: const BorderSide(color: AppColors.onVideoSecondary),
          minimumSize: const Size.fromHeight(AppReels.buttonHeight),
          shape: const StadiumBorder(),
        ),
        onPressed: onPressed,
        child: const Text(AppStrings.nextReel),
      ),
    };
  }
}
