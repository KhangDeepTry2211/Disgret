// 5.1 Màn Thói quen, có SegmentedButton "Hôm nay / Tuần / Tháng".
// - Hôm nay: dải 7 ngày, rồi từng mục tiêu (câu bản sắc) với các thẻ thói quen (4.2).
// - Tuần: bảng thói quen × 7 ngày, cuối hàng là % tuần (4.2).
// - Tháng: lịch nhiệt cả tháng, chạm vào ngày để xem chi tiết (4.2).
// 4.1 Đặt mục tiêu: thêm, sửa, xoá mục tiêu bằng bottom sheet; thêm thói quen bằng màn 4 bước.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/date_utils.dart';
import '../data/habit_progress.dart';
import '../data/habit_science.dart';
import '../data/models/goal.dart';
import '../data/models/habit.dart';
import '../data/models/habit_log.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/edit_delete_menu.dart';
import '../widgets/empty_goal_view.dart';
import '../widgets/goal_habit_sheets.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_heat_map.dart';

enum _HabitsView { today, week, month }

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  _HabitsView _view = _HabitsView.today;

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thói quen'),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.add),
            tooltip: 'Thêm mục tiêu',
            onPressed: () => showGoalSheet(context, ref),
          ),
        ],
      ),
      body: goals.isEmpty
          ? const EmptyGoalView()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<_HabitsView>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: _HabitsView.today, label: Text('Hôm nay')),
                        ButtonSegment(value: _HabitsView.week, label: Text('Tuần')),
                        ButtonSegment(value: _HabitsView.month, label: Text('Tháng')),
                      ],
                      selected: {_view},
                      onSelectionChanged: (selected) => setState(() => _view = selected.first),
                    ),
                  ),
                ),
                Expanded(
                  child: switch (_view) {
                    _HabitsView.today => _TodayView(goals: goals),
                    _HabitsView.week => const _WeekView(),
                    _HabitsView.month => const _MonthView(),
                  },
                ),
              ],
            ),
    );
  }
}

// ---------- Hôm nay ----------

class _TodayView extends ConsumerWidget {
  const _TodayView({required this.goals});

  final List<Goal> goals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final histories = ref.watch(habitHistoriesProvider);
    final today = ref.watch(todayProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: WeekStrip(histories: histories.values.toList(), today: today),
          ),
        ),
        for (final goal in goals) ...[
          const SizedBox(height: AppSpacing.lg),
          _GoalHeader(key: ValueKey(goal.id), goal: goal),
          const SizedBox(height: AppSpacing.sm),
          for (final habit in habits.where((habit) => habit.goalId == goal.id)) ...[
            HabitCard(key: ValueKey(habit.id), habit: habit),
            const SizedBox(height: AppSpacing.sm),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(AppIcons.add),
              label: const Text('Thêm thói quen'),
              onPressed: () => context.push(AppRoutes.habitForm(goal.id)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tên mục tiêu, câu bản sắc, lý do và menu Sửa/Xoá.
class _GoalHeader extends ConsumerWidget {
  const _GoalHeader({required this.goal, super.key});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title, style: theme.textTheme.titleMedium),
                if (goal.identity.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(AppIcons.identity, size: 16, color: theme.colorScheme.tertiary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Tôi là người ${goal.identity}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(goal.reason, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        EditDeleteMenu(
          tooltip: 'Tuỳ chọn mục tiêu',
          onEdit: () => showGoalSheet(context, ref, goal: goal),
          onDelete: () => confirmDeleteGoal(context, ref, goal),
        ),
      ],
    );
  }
}

// ---------- Tuần ----------

class _WeekView extends ConsumerWidget {
  const _WeekView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habits = ref.watch(habitsProvider);
    final histories = ref.watch(habitHistoriesProvider);
    final today = ref.watch(todayProvider);
    final monday = weekStart(today);
    final sunday = addDays(monday, 6);
    final days = [for (var i = 0; i < 7; i++) addDays(monday, i)];

    if (habits.isEmpty) {
      return const _EmptyHabits();
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Tuần ${monday.day}/${monday.month} – ${sunday.day}/${sunday.month}',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // Hàng tiêu đề: T2 ... CN, hôm nay in đậm màu nhấn.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final day in days)
                      SizedBox(
                        width: AppHabit.weekCell,
                        child: Text(
                          weekdayShort[day.weekday - 1],
                          textAlign: TextAlign.center,
                          style: day == today
                              ? theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                )
                              : theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
                for (final habit in habits) ...[
                  const Divider(height: AppSpacing.lg),
                  _WeekRow(
                    habit: habit,
                    history: histories[habit.id]!,
                    days: days,
                    today: today,
                    rate: HabitScience.completionRate(
                      histories[habit.id]!,
                      monday,
                      sunday,
                      today: today,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const HeatLegend(),
      ],
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.habit,
    required this.history,
    required this.days,
    required this.today,
    required this.rate,
  });

  final Habit habit;
  final HabitHistory history;
  final List<DateTime> days;
  final DateTime today;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = (rate * 100).round();

    return InkWell(
      onTap: () => context.push(AppRoutes.habitDetail(habit.id)),
      borderRadius: AppRadius.smallBorder,
      child: Column(
        children: [
          Row(
            children: [
              Icon(AppIcons.habitIcon(habit.icon), size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  habit.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Semantics(
                container: true,
                label: 'Tuần này ${habit.name} đạt $percent%',
                excludeSemantics: true,
                child: Text(
                  '$percent%',
                  style: theme.textTheme.labelLarge?.copyWith(color: scheme.tertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in days)
                HeatCell(
                  size: AppHabit.weekCell,
                  level: habitHeatLevel(history, day, today),
                  freeze: history.isFreeze(day),
                  child: _cellIcon(context, day),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _cellIcon(BuildContext context, DateTime day) {
    final scheme = Theme.of(context).colorScheme;
    if (history.isFreeze(day)) return Icon(AppIcons.freeze, size: 14, color: scheme.tertiary);
    if (history.marks[day] == HabitLogSource.minimal) {
      return Icon(AppIcons.minimal, size: 14, color: scheme.onPrimary);
    }
    if (history.isDone(day)) return Icon(AppIcons.done, size: 16, color: scheme.onTertiary);
    return null;
  }
}

// ---------- Tháng ----------

class _MonthView extends ConsumerStatefulWidget {
  const _MonthView();

  @override
  ConsumerState<_MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends ConsumerState<_MonthView> {
  /// Ngày 1 của tháng đang xem.
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final today = ref.read(todayProvider);
    _month = DateTime(today.year, today.month);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habits = ref.watch(habitsProvider);
    final histories = ref.watch(habitHistoriesProvider).values.toList();
    final today = ref.watch(todayProvider);
    final isCurrentMonth = _month.year == today.year && _month.month == today.month;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = _month.weekday - 1;
    final doneDays = [for (var d = 1; d <= daysInMonth; d++) DateTime(_month.year, _month.month, d)]
        .where((day) => histories.any((history) => history.isDone(day)))
        .length;

    if (habits.isEmpty) return const _EmptyHabits();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(AppIcons.previous),
              tooltip: 'Tháng trước',
              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
            ),
            Expanded(
              child: Text(
                'Tháng ${_month.month}/${_month.year}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(AppIcons.next),
              tooltip: 'Tháng sau',
              onPressed: isCurrentMonth
                  ? null
                  : () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
            ),
          ],
        ),
        Text(
          'Có thói quen hoàn thành $doneDays ngày trong tháng',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: GridView.count(
              crossAxisCount: 7,
              mainAxisSpacing: AppSpacing.xs,
              crossAxisSpacing: AppSpacing.xs,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final label in weekdayShort)
                  Center(child: Text(label, style: theme.textTheme.bodySmall)),
                for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
                for (var d = 1; d <= daysInMonth; d++)
                  _MonthDay(
                    day: DateTime(_month.year, _month.month, d),
                    histories: histories,
                    today: today,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const HeatLegend(),
      ],
    );
  }
}

class _MonthDay extends StatelessWidget {
  const _MonthDay({required this.day, required this.histories, required this.today});

  final DateTime day;
  final List<HabitHistory> histories;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isFuture = day.isAfter(today);
    final completion = isFuture ? null : HabitScience.dayCompletion(histories, day);
    final level = isFuture ? null : HabitScience.heatLevel(completion ?? 0);
    final allFrozen = !isFuture && completion == null && histories.isNotEmpty;

    final Color textColor = switch (level) {
      3 => scheme.onTertiary,
      2 => scheme.onPrimary,
      _ => scheme.onSurface,
    };

    return Semantics(
      button: !isFuture,
      label: '${day.day}/${day.month}',
      value: isFuture ? 'chưa tới' : '${((completion ?? 0) * 100).round()}%',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: AppRadius.heatCellBorder,
        onTap: isFuture ? null : () => _showDaySheet(context, day),
        child: HeatCell(
          level: level,
          freeze: allFrozen,
          child: Text(
            '${day.day}',
            style: (day == today ? theme.textTheme.labelLarge : theme.textTheme.bodySmall)
                ?.copyWith(color: isFuture ? scheme.onSurfaceVariant : textColor),
          ),
        ),
      ),
    );
  }
}

/// Chi tiết một ngày trong lịch tháng: trạng thái từng thói quen và ghi chú.
Future<void> _showDaySheet(BuildContext context, DateTime day) {
  return showAppBottomSheet<void>(context, builder: (_) => _DaySheet(day: day));
}

class _DaySheet extends ConsumerWidget {
  const _DaySheet({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habits = ref.watch(habitsProvider);
    final logs = ref.watch(habitLogsProvider);
    final histories = ref.watch(habitHistoriesProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${weekdayLong[day.weekday - 1]}, ${day.day}/${day.month}/${day.year}',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final habit in habits)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(AppIcons.habitIcon(habit.icon)),
            title: Text(habit.name),
            subtitle: Text(_dayStatus(habit, histories[habit.id]!, logs)),
          ),
      ],
    );
  }

  String _dayStatus(Habit habit, HabitHistory history, List<HabitLog> logs) {
    final note = HabitProgress.markLogOn(habit, day, logs)?.note ?? '';
    final String status;
    if (history.isFreeze(day)) {
      status = 'Nghỉ phép';
    } else if (history.marks[day] == HabitLogSource.minimal) {
      status = 'Làm bản 2 phút';
    } else if (history.isDone(day)) {
      status = 'Hoàn thành';
    } else {
      final minutes = HabitProgress.minutesOn(habit, day, logs);
      status = minutes == 0 ? 'Chưa làm' : '$minutes/${habit.minMinutesPerDay} phút';
    }
    return note.isEmpty ? status : '$status · $note';
  }
}

class _EmptyHabits extends StatelessWidget {
  const _EmptyHabits();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Chưa có thói quen nào. Vào "Hôm nay" và bấm "Thêm thói quen" để bắt đầu.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
