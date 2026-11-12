// 4.2 Ghi nhận – thẻ một thói quen, dùng ở tab Thói quen (đầy đủ) và Trang chủ (gọn):
// - vòng tiến độ phút: chạm để tick, giữ lâu để chọn "Làm bản 2 phút" / "Nghỉ phép";
// - icon, tên, "Sau khi… · tại…", streak và điểm sức mạnh (4.2);
// - nhắc "Đừng bỏ 2 lần liên tiếp" khi hôm qua bỏ;
// - lịch nhiệt mini 4 tuần và nút "Focus" (bản đầy đủ);
// - ghi chú sau khi tick. Chạm vào thẻ để mở màn chi tiết.
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/habit_progress.dart';
import '../data/habit_science.dart';
import '../data/models/habit.dart';
import '../data/models/habit_log.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import 'app_dialogs.dart';
import 'edit_delete_menu.dart';
import 'goal_habit_sheets.dart';
import 'habit_check_ring.dart';
import 'habit_heat_map.dart';

class HabitCard extends ConsumerWidget {
  const HabitCard({required this.habit, this.compact = false, super.key});

  final Habit habit;

  /// Bản gọn cho Trang chủ: không có menu, lịch nhiệt mini và nút Focus.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logs = ref.watch(habitLogsProvider);
    final today = ref.watch(todayProvider);
    final history = ref.watch(habitHistoriesProvider)[habit.id] ?? HabitHistory.of(habit, logs);

    final markLog = HabitProgress.markLogOn(habit, today, logs);
    final mark = markLog?.source;
    final isDone = history.isDone(today);
    final minutes = HabitProgress.minutesOn(habit, today, logs);
    final streak = HabitScience.currentStreakOf(history.doneDays, history.freezeDays, today);
    final strength = HabitScience.strengthHistory(history, today, days: 1).last;
    final missedYesterday = HabitScience.missedYesterday(history, today);

    // Đạt nhờ phút Focus thì vòng khoá lại: bỏ tick không được xoá phút học thật.
    final lockedByFocus = isDone && mark == null;
    final notifier = ref.read(habitLogsProvider.notifier);

    void toggle() {
      final willBeDone = mark == null;
      if (willBeDone && !kIsWeb) HapticFeedback.lightImpact();
      notifier.setDoneToday(habit, done: willBeDone);
    }

    final subtitle = [
      if (habit.cue.isNotEmpty) 'Sau khi ${habit.cue}',
      if (habit.place.isNotEmpty) 'tại ${habit.place}',
    ].join(' · ');

    // Dòng phút luôn hiện; thêm một dòng trạng thái khi hôm nay có đánh dấu đặc biệt.
    final String? status = switch (mark) {
      HabitLogSource.freeze => 'Hôm nay nghỉ phép',
      HabitLogSource.minimal => 'Đã làm bản 2 phút',
      _ => lockedByFocus ? 'Đã đủ phút từ phiên Focus' : null,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.habitDetail(habit.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, 0, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HabitCheckRing(
                    habitName: habit.name,
                    progress: history.valueOn(today),
                    done: isDone,
                    minimal: mark == HabitLogSource.minimal,
                    freeze: mark == HabitLogSource.freeze,
                    onTap: lockedByFocus ? null : toggle,
                    onLongPress: lockedByFocus
                        ? null
                        : () => showDayMarkSheet(context, ref, habit: habit),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              AppIcons.habitIcon(habit.icon),
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                habit.name,
                                style: theme.textTheme.titleSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _StreakLabel(days: streak),
                            _StrengthLabel(value: strength),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$minutes/${habit.minMinutesPerDay} phút hôm nay',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (status != null)
                          Text(
                            status,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!compact)
                    EditDeleteMenu(
                      tooltip: 'Tuỳ chọn thói quen',
                      onEdit: () => context.push(AppRoutes.habitForm(habit.goalId, habit.id)),
                      onDelete: () => confirmDeleteHabit(context, ref, habit),
                    )
                  else
                    const SizedBox(width: AppSpacing.md),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (missedYesterday) _MissedTwiceNudge(habit: habit),
                    if (!compact) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: MiniHeatStrip(history: history, today: today),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _FocusButton(habit: habit),
                        ],
                      ),
                    ],
                    if (markLog != null && mark != HabitLogSource.freeze)
                      _NoteRow(habit: habit, log: markLog),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 4.2 Giữ lâu vòng tiến độ: chọn "Làm bản 2 phút", "Nghỉ phép" hoặc bỏ đánh dấu hôm nay.
Future<void> showDayMarkSheet(BuildContext context, WidgetRef ref, {required Habit habit}) {
  return showAppBottomSheet<void>(context, builder: (_) => _DayMarkSheet(habit: habit));
}

class _DayMarkSheet extends ConsumerWidget {
  const _DayMarkSheet({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logs = ref.watch(habitLogsProvider);
    final today = ref.watch(todayProvider);
    final mark = HabitProgress.markLogOn(habit, today, logs)?.source;
    final canFreeze = HabitScience.canFreeze(habit, logs, today);
    final notifier = ref.read(habitLogsProvider.notifier);

    Future<void> choose(Future<void> Function() action) async {
      Navigator.of(context).pop();
      await action();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Hôm nay với "${habit.name}"', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(AppIcons.minimal),
          title: const Text('Làm bản 2 phút'),
          subtitle: Text(
            habit.minimalVersion.isEmpty
                ? 'Làm một phần thật nhỏ để không đứt chuỗi'
                : habit.minimalVersion,
          ),
          selected: mark == HabitLogSource.minimal,
          onTap: () => choose(() {
            if (!kIsWeb) HapticFeedback.lightImpact();
            return notifier.setMarkToday(habit, HabitLogSource.minimal);
          }),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(AppIcons.freeze),
          title: const Text('Nghỉ phép'),
          subtitle: Text(
            canFreeze
                ? 'Không đứt chuỗi, điểm sức mạnh giữ nguyên. Mỗi tuần 1 ngày.'
                : 'Tuần này bạn đã dùng ngày nghỉ phép rồi.',
          ),
          enabled: canFreeze,
          selected: mark == HabitLogSource.freeze,
          onTap: () => choose(() => notifier.setMarkToday(habit, HabitLogSource.freeze)),
        ),
        if (mark != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(AppIcons.clearMark),
            title: const Text('Bỏ đánh dấu hôm nay'),
            onTap: () => choose(() => notifier.setDoneToday(habit, done: false)),
          ),
      ],
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

/// 4.2 Điểm sức mạnh 0–100%, tô màu nhấn.
class _StrengthLabel extends StatelessWidget {
  const _StrengthLabel({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.tertiary;
    final percent = (value * 100).round();

    return Semantics(
      container: true,
      label: 'Sức mạnh thói quen $percent%',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.strength, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text('$percent%', style: theme.textTheme.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// 4.2 "Không bỏ 2 lần liên tiếp": hôm qua bỏ thì gợi ý làm bản 2 phút ngay trên thẻ.
class _MissedTwiceNudge extends ConsumerWidget {
  const _MissedTwiceNudge({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Material(
        color: scheme.tertiary.withValues(alpha: 0.12),
        borderRadius: AppRadius.smallBorder,
        child: InkWell(
          borderRadius: AppRadius.smallBorder,
          onTap: () =>
              ref.read(habitLogsProvider.notifier).setMarkToday(habit, HabitLogSource.minimal),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(AppIcons.reminder, size: 18, color: scheme.tertiary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Đừng bỏ 2 lần liên tiếp – làm bản 2 phút nhé',
                    style: theme.textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mở màn Focus với thói quen này được chọn sẵn.
class _FocusButton extends ConsumerWidget {
  const _FocusButton({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        visualDensity: VisualDensity.compact,
      ),
      icon: const Icon(AppIcons.focus, size: 18),
      label: const Text('Focus'),
      onPressed: () {
        ref.read(focusHabitChoiceProvider.notifier).choose(habit.id);
        context.go(AppRoutes.focus);
      },
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
        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
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
