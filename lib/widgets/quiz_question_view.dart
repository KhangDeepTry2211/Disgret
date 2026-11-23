// 1.1 Hồ sơ động lực – một câu hỏi quiz dạng thẻ chọn, dùng ở onboarding và màn làm lại quiz.
// 5.3 (feature 003, FR-011): the question sits in Gret's thought bubble, answers are large cards
// with an icon, and Gret is happy for a moment after an answer before the next question. With
// "remove animations" on, the answer goes through at once.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../data/mascot_mood.dart';
import '../data/models/motivation_type.dart';
import '../data/motivation_quiz.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'mascot/mascot_bubbles.dart';
import 'mascot/mascot_view.dart';

class QuizQuestionView extends StatefulWidget {
  const QuizQuestionView({
    required this.questionIndex,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final int questionIndex;

  /// Đáp án đã chọn trước đó, nếu người dùng quay lại câu này.
  final MotivationType? selected;
  final ValueChanged<MotivationType> onSelected;

  @override
  State<QuizQuestionView> createState() => _QuizQuestionViewState();
}

class _QuizQuestionViewState extends State<QuizQuestionView> {
  /// The answer Gret is reacting to; further taps wait until it has gone through.
  MotivationType? _picked;
  Timer? _reaction;

  @override
  void didUpdateWidget(QuizQuestionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionIndex != widget.questionIndex) {
      _reaction?.cancel();
      _picked = null;
    }
  }

  @override
  void dispose() {
    _reaction?.cancel();
    super.dispose();
  }

  void _pick(MotivationType type) {
    if (_picked != null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onSelected(type);
      return;
    }
    setState(() => _picked = type);
    _reaction = Timer(AppMotion.reaction, () {
      if (mounted) widget.onSelected(type);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = motivationQuestions[widget.questionIndex];
    final total = motivationQuestions.length;
    final shown = _picked ?? widget.selected;
    final reacting = _picked != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _StepDots(
              key: const ValueKey('quiz-step-dots'),
              current: widget.questionIndex,
              total: total,
            ),
            const Spacer(),
            Text(
              AppStrings.quizStep(widget.questionIndex + 1, total),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedScale(
              scale: reacting ? AppMascot.reactionScale : 1,
              duration: AppMotion.entrance,
              curve: Curves.easeOutBack,
              child: MascotView(
                mood: reacting ? MascotMood.happy : MascotMood.neutral,
                size: AppMascot.small,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ThoughtBubble(text: question.text, style: theme.textTheme.titleMedium),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final answer in question.answers) ...[
          _AnswerCard(
            answer: answer,
            isSelected: answer.type == shown,
            onTap: () => _pick(answer.type),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// One dot per question: done and current in the primary colour, the current one wider.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total, super.key});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // The "Câu n/N" text next to the dots already tells screen readers the step.
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Container(
                width: i == current ? AppSpacing.lg : AppSpacing.sm,
                height: AppSpacing.sm,
                decoration: BoxDecoration(
                  color: i <= current ? scheme.primary : scheme.outlineVariant,
                  borderRadius: AppRadius.pillBorder,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer, required this.isSelected, required this.onTap});

  final QuizAnswer answer;
  final bool isSelected;
  final VoidCallback onTap;

  static IconData _iconFor(MotivationType type) => switch (type) {
    MotivationType.money => AppIcons.motivationMoney,
    MotivationType.family => AppIcons.motivationFamily,
    MotivationType.career => AppIcons.motivationCareer,
    MotivationType.proveYourself => AppIcons.motivationProveYourself,
    MotivationType.freedom => AppIcons.motivationFreedom,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = scheme.secondary;

    // One node per answer: label, tap and "selected" together for screen readers.
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isSelected,
        child: Card(
          clipBehavior: Clip.antiAlias,
          color: isSelected ? scheme.secondaryContainer : null,
          // Đáp án đang chọn được làm nổi bằng viền màu nhấn.
          shape: isSelected
              ? RoundedRectangleBorder(
                  borderRadius: AppRadius.cardBorder,
                  side: BorderSide(color: accent, width: 1.5),
                )
              : null,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: AppStatCard.badge,
                    height: AppStatCard.badge,
                    decoration: BoxDecoration(
                      color: isSelected ? accent : scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconFor(answer.type),
                      size: AppStatCard.icon,
                      color: isSelected ? scheme.onSecondary : scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(answer.text, style: theme.textTheme.bodyLarge)),
                  if (isSelected) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(AppIcons.check, color: accent),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
