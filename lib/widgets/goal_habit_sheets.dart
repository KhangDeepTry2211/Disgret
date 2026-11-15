// 4.1 Đặt mục tiêu – bottom sheet thêm/sửa mục tiêu, xoá mục tiêu và thói quen có xác nhận.
// Thêm/sửa thói quen dùng màn Tạo thói quen (habit_form_screen.dart).
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

enum _DeleteChoice { keepHistory, clearHistory }

/// 4.1 Xoá thói quen bằng bottom sheet "Xoá thói quen này?" với 2 lựa chọn:
/// - "Xoá nhưng giữ lịch sử": ẩn thói quen, log vẫn còn để Thống kê tính;
/// - "Xoá cả lịch sử": xoá thói quen và mọi log của nó.
/// Trả về true nếu đã xoá, để màn chi tiết biết mà đóng lại.
Future<bool> confirmDeleteHabit(BuildContext context, WidgetRef ref, Habit habit) async {
  final notifier = ref.read(habitsProvider.notifier);
  final choice = await showAppBottomSheet<_DeleteChoice>(
    context,
    builder: (_) => _DeleteHabitSheet(habit: habit),
  );
  switch (choice) {
    case _DeleteChoice.keepHistory:
      await notifier.archive(habit.id);
    case _DeleteChoice.clearHistory:
      await notifier.remove(habit.id);
    case null:
      return false;
  }
  return true;
}

class _DeleteHabitSheet extends StatelessWidget {
  const _DeleteHabitSheet({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget option({
      required IconData icon,
      required Color iconColor,
      required String title,
      required String subtitle,
      required _DeleteChoice value,
    }) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Material(
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardBorder,
            side: BorderSide(color: scheme.outlineVariant),
          ),
          color: scheme.surfaceContainer,
          child: ListTile(
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
            leading: Icon(icon, color: iconColor),
            title: Text(title),
            subtitle: Text(subtitle),
            onTap: () => Navigator.of(context).pop(value),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Xoá thói quen này?',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(color: scheme.error),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          habit.name,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const Divider(height: AppSpacing.lg),
        option(
          icon: AppIcons.archive,
          iconColor: scheme.tertiary,
          title: 'Xoá nhưng giữ lịch sử',
          subtitle: 'Ẩn thói quen, các ngày đã làm vẫn được tính trong Thống kê.',
          value: _DeleteChoice.keepHistory,
        ),
        option(
          icon: AppIcons.deleteHistory,
          iconColor: scheme.error,
          title: 'Xoá cả lịch sử',
          subtitle: 'Xoá hẳn thói quen và mọi ngày đã ghi nhận. Không thể hoàn tác.',
          value: _DeleteChoice.clearHistory,
        ),
      ],
    );
  }
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
