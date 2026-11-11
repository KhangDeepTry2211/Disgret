// 1.1 Hồ sơ động lực – một câu hỏi quiz dạng thẻ chọn, dùng ở onboarding và màn làm lại quiz.
import 'package:material_ui/material_ui.dart';

import '../data/models/motivation_type.dart';
import '../data/motivation_quiz.dart';
import '../theme/app_theme.dart';
import 'gradient_progress_bar.dart';

class QuizQuestionView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = motivationQuestions[questionIndex];
    final total = motivationQuestions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Câu ${questionIndex + 1}/$total',
          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        GradientProgressBar(value: (questionIndex + 1) / total, height: 4),
        const SizedBox(height: AppSpacing.lg),
        Text(question.text, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        for (final answer in question.answers) ...[
          _AnswerCard(
            answer: answer,
            isSelected: answer.type == selected,
            onTap: () => onSelected(answer.type),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer, required this.isSelected, required this.onTap});

  final QuizAnswer answer;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;

    return Semantics(
      button: true,
      selected: isSelected,
      child: Card(
        clipBehavior: Clip.antiAlias,
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
    );
  }
}
