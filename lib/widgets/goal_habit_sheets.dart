// 4.1 Đặt mục tiêu – bottom sheet thêm/sửa mục tiêu và thói quen, xoá có xác nhận.
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
import 'habit_form_fields.dart';

typedef _GoalDraft = ({String title, String reason});
typedef _HabitDraft = ({String name, int minutes});

/// Thêm mục tiêu mới, hoặc sửa nếu truyền [goal].
Future<void> showGoalSheet(BuildContext context, WidgetRef ref, {Goal? goal}) async {
  final notifier = ref.read(goalsProvider.notifier);
  final draft = await showAppBottomSheet<_GoalDraft>(
    context,
    builder: (_) => _GoalSheet(goal: goal),
  );
  if (draft == null) return;

  if (goal == null) {
    await notifier.add(title: draft.title, reason: draft.reason);
  } else {
    await notifier.edit(Goal(id: goal.id, title: draft.title, reason: draft.reason));
  }
}

/// Thêm thói quen vào mục tiêu [goalId], hoặc sửa nếu truyền [habit].
Future<void> showHabitSheet(
  BuildContext context,
  WidgetRef ref, {
  required String goalId,
  Habit? habit,
}) async {
  final notifier = ref.read(habitsProvider.notifier);
  final draft = await showAppBottomSheet<_HabitDraft>(
    context,
    builder: (_) => _HabitSheet(habit: habit),
  );
  if (draft == null) return;

  if (habit == null) {
    await notifier.add(goalId: goalId, name: draft.name, minMinutesPerDay: draft.minutes);
  } else {
    await notifier.edit(
      Habit(id: habit.id, goalId: habit.goalId, name: draft.name, minMinutesPerDay: draft.minutes),
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

Future<void> confirmDeleteHabit(BuildContext context, WidgetRef ref, Habit habit) async {
  final notifier = ref.read(habitsProvider.notifier);
  final confirmed = await showConfirmDialog(
    context,
    title: 'Xoá thói quen?',
    message: '"${habit.name}" cùng lịch sử ghi nhận của nó sẽ bị xoá. Không thể hoàn tác.',
    confirmLabel: 'Xoá',
  );
  if (confirmed) await notifier.remove(habit.id);
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

  @override
  void dispose() {
    _title.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop<_GoalDraft>((title: _title.text.trim(), reason: _reason.text.trim()));
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
          GoalFormFields(titleController: _title, reasonController: _reason),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: _submit, child: const Text('Lưu')),
        ],
      ),
    );
  }
}

class _HabitSheet extends StatefulWidget {
  const _HabitSheet({this.habit});

  final Habit? habit;

  @override
  State<_HabitSheet> createState() => _HabitSheetState();
}

class _HabitSheetState extends State<_HabitSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.habit?.name);
  late final TextEditingController _minutes = TextEditingController(
    text: '${widget.habit?.minMinutesPerDay ?? HabitFormFields.defaultMinutes}',
  );

  @override
  void dispose() {
    _name.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context)
        .pop<_HabitDraft>((name: _name.text.trim(), minutes: int.parse(_minutes.text)));
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
            widget.habit == null ? 'Thói quen mới' : 'Sửa thói quen',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          HabitFormFields(nameController: _name, minutesController: _minutes),
          const SizedBox(height: AppSpacing.lg),
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
