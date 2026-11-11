// 4.2 Ghi nhận – một dòng thói quen: ô tick "Hôm nay đã làm", streak riêng,
// thanh tiến độ phút hôm nay và ghi chú. Dùng ở Trang chủ và màn Thói quen.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/habit_progress.dart';
import '../data/models/habit.dart';
import '../data/models/habit_log.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'edit_delete_menu.dart';
import 'goal_habit_sheets.dart';
import 'gradient_progress_bar.dart';

class HabitTile extends ConsumerWidget {
  const HabitTile({required this.habit, this.showMenu = false, super.key});

  final Habit habit;

  /// Hiện menu Sửa/Xoá; chỉ màn Thói quen mới cần.
  final bool showMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logs = ref.watch(habitLogsProvider);
    final today = ref.watch(todayProvider);

    final isDone = HabitProgress.isDone(habit, today, logs);
    final manualLog = HabitProgress.manualLogOn(habit, today, logs);
    final minutes = HabitProgress.minutesOn(habit, today, logs);
    final streak = HabitProgress.habitStreak(habit, logs, today: today);

    // Đạt nhờ phút Focus thì ô tick khoá lại: bỏ tick không được xoá phút học thật.
    final lockedByFocus = isDone && manualLog == null;

    void toggle() => ref.read(habitLogsProvider.notifier).setDoneToday(habit, done: !isDone);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isDone,
                onChanged: lockedByFocus ? null : (_) => toggle(),
                semanticLabel: 'Hôm nay đã làm: ${habit.name}',
              ),
              Expanded(
                child: InkWell(
                  onTap: lockedByFocus ? null : toggle,
                  borderRadius: AppRadius.cardBorder,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.name, style: theme.textTheme.titleSmall),
                      Text(
                        lockedByFocus ? 'Đã đủ phút từ phiên Focus' : 'Hôm nay đã làm',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StreakLabel(days: streak),
              if (showMenu)
                EditDeleteMenu(
                  tooltip: 'Tuỳ chọn thói quen',
                  onEdit: () => showHabitSheet(context, ref, goalId: habit.goalId, habit: habit),
                  onDelete: () => confirmDeleteHabit(context, ref, habit),
                )
              else
                const SizedBox(width: AppSpacing.md),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientProgressBar(value: minutes / habit.minMinutesPerDay),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$minutes/${habit.minMinutesPerDay} phút hôm nay',
                  style: theme.textTheme.bodySmall,
                ),
                if (manualLog != null) _NoteRow(habit: habit, log: manualLog),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakLabel extends StatelessWidget {
  const _StreakLabel({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return Semantics(
      container: true, // Tách thành nút riêng để trình đọc màn hình đọc đúng nhãn này.
      label: 'Chuỗi $days ngày',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.streak, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text('$days ngày', style: theme.textTheme.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Sau khi tick: liên kết "Thêm ghi chú", có ghi chú rồi thì hiện nội dung, bấm để sửa.
class _NoteRow extends ConsumerWidget {
  const _NoteRow({required this.habit, required this.log});

  final Habit habit;
  final HabitLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasNote = log.note.isNotEmpty;
    final color = hasNote ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.secondary;
    final style = hasNote ? theme.textTheme.bodySmall : theme.textTheme.labelMedium;

    return InkWell(
      onTap: () => showNoteSheet(context, ref, habit: habit, currentNote: log.note),
      borderRadius: AppRadius.cardBorder,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(AppIcons.note, size: 16, color: color),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                hasNote ? log.note : 'Thêm ghi chú',
                style: style?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
