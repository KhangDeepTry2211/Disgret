// 5.1 Màn onboarding: chỉ hiện ở lần mở app đầu tiên, gồm 3 phần theo thứ tự:
// giới thiệu, quiz động lực (1.1), mục tiêu đầu tiên và 1 thói quen (4.1).
// Tất cả chỉ được lưu vào Hive khi hoàn thành bước cuối.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/motivation_type.dart';
import '../data/models/user_profile.dart';
import '../data/motivation_quiz.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/goal_form_fields.dart';
import '../widgets/habit_form_fields.dart';
import '../widgets/quiz_question_view.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const List<int> _reelLengths = [15, 30, 60];

  // Các bước đánh số liên tiếp: 0 là giới thiệu, sau đó mỗi câu quiz một bước, cuối là mục tiêu.
  static const int _introStep = 0;
  static final int _goalStep = motivationQuestions.length + 1;

  final _formKey = GlobalKey<FormState>();
  final _goalTitle = TextEditingController();
  final _goalReason = TextEditingController();
  final _habitName = TextEditingController();
  final _habitMinutes = TextEditingController(text: '${HabitFormFields.defaultMinutes}');
  final List<MotivationType?> _answers = List.filled(motivationQuestions.length, null);

  late int _reelLength;

  /// Xem lại onboarding từ Cài đặt khi đã có mục tiêu thì không hỏi lại bước cuối.
  late final bool _needsFirstGoal;
  int _step = _introStep;
  bool _saving = false;

  int get _questionIndex => _step - 1;

  @override
  void initState() {
    super.initState();
    _reelLength = ref.read(profileProvider)?.preferredReelLength ?? UserProfile.defaultReelLength;
    _needsFirstGoal = ref.read(goalsProvider).isEmpty;
  }

  @override
  void dispose() {
    _goalTitle.dispose();
    _goalReason.dispose();
    _habitName.dispose();
    _habitMinutes.dispose();
    super.dispose();
  }

  void _goBack() => setState(() => _step--);

  void _selectAnswer(MotivationType type) {
    if (_saving) return;
    _answers[_questionIndex] = type;

    final isLastQuestion = _step == _goalStep - 1;
    if (isLastQuestion && !_needsFirstGoal) {
      _finish();
    } else {
      setState(() => _step++);
    }
  }

  Future<void> _finish() async {
    if (_step == _goalStep && !_formKey.currentState!.validate()) return;
    setState(() => _saving = true); // Khoá nút để bấm hai lần không tạo trùng mục tiêu.

    if (_needsFirstGoal) {
      final goal = await ref
          .read(goalsProvider.notifier)
          .add(title: _goalTitle.text.trim(), reason: _goalReason.text.trim());
      await ref
          .read(habitsProvider.notifier)
          .add(
            goalId: goal.id,
            name: _habitName.text.trim(),
            minMinutesPerDay: int.parse(_habitMinutes.text),
          );
    }
    // Đánh dấu xong sau cùng: lỡ tắt app giữa chừng thì lần sau vẫn vào lại onboarding.
    await ref
        .read(profileProvider.notifier)
        .completeOnboarding(
          UserProfile(
            motivationTypes: topMotivationTypes(_answers.nonNulls.toList()),
            preferredReelLength: _reelLength,
            // Xem lại onboarding không được tắt chế độ demo đang bật.
            demoMode: ref.read(profileProvider)?.demoMode ?? false,
          ),
        );
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    // Từ bước thứ hai trở đi, nút Back của hệ thống về bước trước thay vì thoát app.
    return PopScope(
      canPop: _step == _introStep,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_saving) _goBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                // Dùng SingleChildScrollView: ô nhập luôn được dựng nên Form kiểm tra đủ mọi ô.
                // Mỗi bước một khoá riêng để bước mới luôn hiện từ trên cùng.
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _buildStep(context),
                ),
              ),
              Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: _buildButtons()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    if (_step == _introStep) return _buildIntroStep(context);
    if (_step == _goalStep) return _buildFirstGoalStep(context);
    return QuizQuestionView(
      questionIndex: _questionIndex,
      selected: _answers[_questionIndex],
      onSelected: _selectAnswer,
    );
  }

  Widget _buildIntroStep(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        const Center(child: AppLogo(size: 96)),
        const SizedBox(height: AppSpacing.md),
        Text('DisGret', textAlign: TextAlign.center, style: theme.textTheme.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Bắt đầu học, và quay lại tập trung mỗi khi bị xao nhãng.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Bạn thích reel dài bao nhiêu?', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (final seconds in _reelLengths)
              ButtonSegment(value: seconds, label: Text('$seconds giây')),
          ],
          selected: {_reelLength},
          onSelectionChanged: (selection) => setState(() => _reelLength = selection.first),
        ),
      ],
    );
  }

  Widget _buildFirstGoalStep(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mục tiêu đầu tiên của bạn', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Đặt một mục tiêu và một thói quen nhỏ để bắt đầu ngay hôm nay.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          GoalFormFields(titleController: _goalTitle, reasonController: _goalReason),
          const SizedBox(height: AppSpacing.md),
          HabitFormFields(nameController: _habitName, minutesController: _habitMinutes),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    if (_step == _introStep) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: _goNext, child: const Text('Tiếp tục')),
      );
    }

    return Row(
      children: [
        OutlinedButton(onPressed: _saving ? null : _goBack, child: const Text('Quay lại')),
        // Ở bước quiz, chọn thẻ là tự sang câu tiếp nên không cần nút đi tiếp.
        if (_step == _goalStep) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FilledButton(
              onPressed: _saving ? null : _finish,
              child: const Text('Vào DisGret'),
            ),
          ),
        ],
      ],
    );
  }

  void _goNext() => setState(() => _step++);
}
