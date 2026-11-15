// 4.2 Ghi nhận – thẻ của tab "Tuần" và tab "Tổng thể".
// - HabitWeekCard: tên, tần suất ("Hằng ngày", "5 ngày/tuần") và 7 ô tròn T2–CN của tuần này.
//   Xong: tô màu thói quen có ✓; bỏ qua: gạch ngang; chưa làm: chỉ có viền; ngày không có lịch
//   thì viền mờ. Chạm ô để đổi: chưa làm → xong → bỏ qua → chưa làm. Ngày tương lai không chạm được.
// - HabitOverallCard: lưới chấm khoảng 20 tuần kiểu bảng đóng góp GitHub, chấm đậm/nhạt theo
//   mức hoàn thành, dùng màu của chính thói quen đó.
// Chạm phần đầu thẻ để mở màn chi tiết.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/date_utils.dart';
import '../data/habit_schedule.dart';
import '../data/habit_science.dart';
import '../data/models/habit.dart';
import '../data/models/habit_log.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import 'habit_heat_map.dart';
import 'habit_icon_view.dart';

/// Phần đầu chung của hai loại thẻ: icon, tên đậm, tần suất bên phải.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: AppRadius.smallBorder,
      onTap: () => context.push(AppRoutes.habitDetail(habit.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            HabitIconTile(
              icon: habit.icon,
              colorIndex: habit.colorIndex,
              size: AppHabit.smallIconTile,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                habit.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(HabitSchedule.describeRepeat(habit), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.habit, required this.child});

  final Habit habit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CardHeader(habit: habit),
            const Divider(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------- Tuần ----------

/// Trạng thái một ngày trên bảng Tuần.
enum WeekDayState { future, rest, empty, done, skipped, frozen, lockedDone }

WeekDayState weekDayStateOf(HabitHistory history, DateTime day, DateTime today) {
  if (day.isAfter(today)) return WeekDayState.future;
  final mark = history.marks[day];
  if (history.isDone(day)) {
    // Đủ phút nhờ phiên Focus (không có đánh dấu tay) thì khoá, để không xoá nhầm phút học thật.
    return mark == null ? WeekDayState.lockedDone : WeekDayState.done;
  }
  if (mark == HabitLogSource.skip) return WeekDayState.skipped;
  if (mark == HabitLogSource.freeze) return WeekDayState.frozen;
  if (!history.isScheduled(day)) return WeekDayState.rest;
  return WeekDayState.empty;
}

class HabitWeekCard extends ConsumerWidget {
  const HabitWeekCard({required this.habit, required this.history, super.key});

  final Habit habit;
  final HabitHistory history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final monday = weekStart(today);

    return _CardFrame(
      habit: habit,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < 7; i++)
            Column(
              children: [
                Text(
                  weekdayShort[i],
                  style: addDays(monday, i) == today
                      ? theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.secondary)
                      : theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                _WeekDayCircle(
                  habit: habit,
                  day: addDays(monday, i),
                  state: weekDayStateOf(history, addDays(monday, i), today),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _WeekDayCircle extends ConsumerWidget {
  const _WeekDayCircle({required this.habit, required this.day, required this.state});

  final Habit habit;
  final DateTime day;
  final WeekDayState state;

  /// Chạm để đổi: chưa làm (hoặc ngày không có lịch) → xong → bỏ qua → chưa làm.
  Future<void> _cycle(WidgetRef ref) async {
    final logs = ref.read(habitLogsProvider.notifier);
    if (!kIsWeb) HapticFeedback.selectionClick();
    switch (state) {
      case WeekDayState.empty:
      case WeekDayState.rest:
        await logs.setMarkOn(habit, day, HabitLogSource.manual);
      case WeekDayState.done:
        await logs.setMarkOn(habit, day, HabitLogSource.skip);
      case WeekDayState.skipped:
      case WeekDayState.frozen:
        await logs.clearMarksOn(habit, day);
      case WeekDayState.future:
      case WeekDayState.lockedDone:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final color = AppHabitColors.of(habit.colorIndex);
    final tappable = state != WeekDayState.future && state != WeekDayState.lockedDone;
    final done = state == WeekDayState.done || state == WeekDayState.lockedDone;

    final Widget? icon = switch (state) {
      WeekDayState.done ||
      WeekDayState.lockedDone => Icon(AppIcons.done, size: 18, color: color.foreground),
      WeekDayState.skipped => Icon(AppIcons.skipDash, size: 18, color: scheme.onSurfaceVariant),
      WeekDayState.frozen => Icon(AppIcons.freeze, size: 16, color: scheme.tertiary),
      _ => null,
    };

    final label = switch (state) {
      WeekDayState.future => 'chưa tới',
      WeekDayState.rest => 'không có lịch',
      WeekDayState.empty => 'chưa làm',
      WeekDayState.done => 'đã xong',
      WeekDayState.lockedDone => 'đã xong nhờ phiên Focus',
      WeekDayState.skipped => 'bỏ qua',
      WeekDayState.frozen => 'nghỉ phép',
    };

    return Semantics(
      container: true,
      button: tappable,
      label: '${habit.name} ${weekdayLong[day.weekday - 1]}: $label',
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: tappable ? () => _cycle(ref) : null,
        child: Opacity(
          opacity: state == WeekDayState.future || state == WeekDayState.rest ? 0.45 : 1,
          child: Container(
            width: AppHabit.weekCircle,
            height: AppHabit.weekCircle,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? color.background : null,
              border: done ? null : Border.all(color: scheme.outlineVariant, width: 1.5),
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}

// ---------- Tổng thể ----------

class HabitOverallCard extends ConsumerWidget {
  const HabitOverallCard({required this.habit, required this.history, super.key});

  final Habit habit;
  final HabitHistory history;

  static const double _labelWidth = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = ref.watch(todayProvider);
    const weeks = AppHabit.overallWeeks;
    final firstMonday = addDays(weekStart(today), -7 * (weeks - 1));
    DateTime dayAt(int week, int row) => addDays(firstMonday, week * 7 + row);
    final doneCount = [for (var i = 0; i < weeks * 7; i++) addDays(firstMonday, i)]
        .where(history.isDone)
        .length;

    Color? dotColor(DateTime day) {
      if (day.isAfter(today)) return null;
      final level = habitHeatLevel(history, day, today);
      // Ngày không có lịch: chấm rất mờ; ngày có lịch mà chưa làm: chấm xám.
      if (level == null) return scheme.outlineVariant.withValues(alpha: 0.4);
      if (level == 0) return scheme.outlineVariant;
      return AppHabitColors.levelColor(habit.colorIndex, level);
    }

    return _CardFrame(
      habit: habit,
      child: Semantics(
        container: true,
        label: 'Lịch $weeks tuần của ${habit.name}: hoàn thành $doneCount ngày',
        excludeSemantics: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cell = math.min(
              AppHabit.overallDotMax + AppHabit.heatGap * 2,
              (constraints.maxWidth - _labelWidth) / weeks,
            );
            final dot = cell - AppHabit.heatGap * 2;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _labelWidth,
                  child: Column(
                    children: [
                      for (var row = 0; row < 7; row++)
                        SizedBox(
                          height: cell,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              child: Text(weekdayShort[row], style: theme.textTheme.labelSmall),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                for (var week = 0; week < weeks; week++)
                  Column(
                    children: [
                      for (var row = 0; row < 7; row++)
                        SizedBox(
                          width: cell,
                          height: cell,
                          child: Center(
                            child: Container(
                              width: dot,
                              height: dot,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dotColor(dayAt(week, row)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
