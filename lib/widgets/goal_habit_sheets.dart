// 4.1 Đặt mục tiêu – bottom sheet thêm/sửa mục tiêu, xoá mục tiêu và thói quen có xác nhận.
// Thêm/sửa thói quen dùng màn 4 bước (habit_form_screen.dart).
// 4.2 Ghi nhận – bottom sheet ghi chú ngắn sau khi tick.
// Sheet chỉ thu thập dữ liệu rồi trả về; việc lưu do Notifier làm để màn hình tự cập nhật.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/goal.dart';
import '../data/models/habit.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'app_dialogs.dart';
import 'goal_form_fields.dart';

typedef _GoalDraft = ({String title, String reason, String identity});

/// Thêm mục tiêu mới, hoặc sửa nếu truyền [goal].
Future<void> showGoalSheet(BuildContext context, WidgetRef ref, {Goal? goal}) async {
  final notifier = ref.read(goalsProvider.notifier);
  final draft = await showAppBottomSheet<_GoalDraft>(
    context,
    builder: (_) => _GoalSheet(goal: goal),
  );
  if (draft == null) return;

  if (goal == null) {
    await notifier.add(title: draft.title, reason: draft.reason, identity: draft.identity);
  } else {
    await notifier.edit(
      goal.copyWith(title: draft.title, reason: draft.reason, identity: draft.identity),
    );
  }
}

/// Ghi chú ngắn cho thói quen đã tick hôm nay. Bỏ qua thì giữ nguyên ghi chú cũ.
Future<void> showNoteSheet(
  BuildContext context,
  WidgetRef ref, {
  required Habit habit,
  required String currentNote,
}) async {
  final notifier = ref.read(habitLogsProvider.notifier);
  final note = await showAppBottomSheet<String>(
    context,
    builder: (_) => _NoteSheet(habit: habit, currentNote: currentNote),
  );
  if (note == null) return;
  await notifier.saveNoteToday(habit, note);
}

Future<void> confirmDeleteGoal(BuildContext context, WidgetRef ref, Goal goal) async {
  final notifier = ref.read(goalsProvider.notifier);
  final confirmed = await showConfirmDialog(
    context,
    title: 'Xoá mục tiêu?',
    message:
        '"${goal.title}" cùng các thói quen và lịch sử ghi nhận của nó sẽ bị xoá. '
        'Không thể hoàn tác.',
    confirmLabel: 'Xoá',
  );
  if (confirmed) await notifier.remove(goal.id);
}

/// Trả về true nếu đã xoá, để màn chi tiết biết mà đóng lại.
Future<bool> confirmDeleteHabit(BuildContext context, WidgetRef ref, Habit habit) async {
  final notifier = ref.read(habitsProvider.notifier);
  final confirmed = await showConfirmDialog(
    context,
    title: 'Xoá thói quen?',
    message: '"${habit.name}" cùng lịch sử ghi nhận của nó sẽ bị xoá. Không thể hoàn tác.',
    confirmLabel: 'Xoá',
  );
  if (confirmed) await notifier.remove(habit.id);
  return confirmed;
}

class _GoalSheet extends StatefulWidget {
  const _GoalSheet({this.goal});

  final Goal? goal;

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(text: widget.goal?.title);
  late final TextEditingController _reason = TextEditingController(text: widget.goal?.reason);
  late final TextEditingController _identity = TextEditingController(text: widget.goal?.identity);

  @override
  void dispose() {
    _title.dispose();
    _reason.dispose();
    _identity.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop<_GoalDraft>((
      title: _title.text.trim(),
      reason: _reason.text.trim(),
      identity: _identity.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.goal == null ? 'Mục tiêu mới' : 'Sửa mục tiêu',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          GoalFormFields(
            titleController: _title,
            reasonController: _reason,
            identityController: _identity,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: _submit, child: const Text('Lưu')),
        ],
      ),
    );
  }
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.habit, required this.currentNote});

  final Habit habit;
  final String currentNote;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _note = TextEditingController(text: widget.currentNote);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ghi chú hôm nay', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(widget.habit.name, style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _note,
          autofocus: true,
          maxLength: 140,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Hôm nay thế nào? (không bắt buộc)'),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Bỏ qua'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_note.text.trim()),
                child: const Text('Lưu'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
