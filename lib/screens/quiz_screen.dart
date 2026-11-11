// 1.1 Hồ sơ động lực – màn "Làm lại quiz động lực", mở từ Cài đặt.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/motivation_type.dart';
import '../data/motivation_quiz.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/quiz_question_view.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final List<MotivationType?> _answers = List.filled(motivationQuestions.length, null);
  int _index = 0;
  bool _saving = false;

  Future<void> _selectAnswer(MotivationType type) async {
    if (_saving) return; // Bấm đúp ở câu cuối không được lưu và đóng màn hai lần.
    _answers[_index] = type;

    if (_index < motivationQuestions.length - 1) {
      setState(() => _index++);
      return;
    }

    _saving = true;
    final top = topMotivationTypes(_answers.nonNulls.toList());
    await ref.read(profileProvider.notifier).updateMotivationTypes(top);
    if (!mounted) return;

    final labels = top.map((type) => type.label).join(', ');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Động lực chính của bạn: $labels')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    // Từ câu thứ hai trở đi, nút quay lại về câu trước thay vì thoát khỏi quiz.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _index--);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Quiz động lực')),
        body: SingleChildScrollView(
          // Mỗi câu một khoá riêng để câu mới luôn hiện từ trên cùng.
          key: ValueKey(_index),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: QuizQuestionView(
            questionIndex: _index,
            selected: _answers[_index],
            onSelected: _selectAnswer,
          ),
        ),
      ),
    );
  }
}
