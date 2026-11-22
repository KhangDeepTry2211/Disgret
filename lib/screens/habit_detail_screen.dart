// 4.2 Màn chi tiết một thói quen (bố cục theo design/habit_kit/ ảnh 16):
// - AppBar có nút Sửa và Xoá;
// - đầu trang: icon, tên, câu "Sau khi…, tôi sẽ… tại…", bản 2 phút, câu bản sắc;
// - lưới 6 ô số liệu: chuỗi hiện tại, dài nhất, tỉ lệ 30 ngày, thứ hay bỏ nhất,
//   số lần hoàn thành, điểm sức mạnh;
// - lịch tháng: ngày đã xong tô màu của thói quen;
// - biểu đồ đường điểm sức mạnh 60 ngày (fl_chart);
// - (Hành trình 66 ngày và lịch nhiệt 16 tuần: parked, ADR-0004);
// - dòng thời gian ghi chú.
// Mọi con số lấy từ habit_science.dart; màn hình chỉ hiển thị.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/date_utils.dart';
import '../data/habit_schedule.dart';
import '../data/habit_science.dart';
import '../data/models/goal.dart';
import '../data/models/habit.dart';
import '../data/models/habit_log.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/goal_habit_sheets.dart';
import '../widgets/habit_icon_view.dart';
import '../widgets/month_calendar.dart';

class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({required this.habitId, super.key});

  final String habitId;

  /// Số ngày của biểu đồ điểm sức mạnh.
  static const int chartDays = 60;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habit = ref.watch(habitsProvider).where((habit) => habit.id == habitId).firstOrNull;
    if (habit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thói quen')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Không tìm thấy thói quen này. Có thể nó vừa bị xoá.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final logs = ref.watch(habitLogsProvider);
    final today = ref.watch(todayProvider);
    final goal = ref.watch(goalsProvider).where((goal) => goal.id == habit.goalId).firstOrNull;
    final history = ref.watch(habitHistoriesProvider)[habit.id] ?? HabitHistory.of(habit, logs);
    final strength = HabitScience.strengthHistory(history, today, days: chartDays);

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.editValue),
            tooltip: 'Sửa thói quen',
            onPressed: () => context.push(AppRoutes.habitForm(habit.goalId, habit.id)),
          ),
          IconButton(
            icon: Icon(AppIcons.deleteAll, color: Theme.of(context).colorScheme.error),
            tooltip: 'Xoá thói quen',
            onPressed: () async {
              final deleted = await confirmDeleteHabit(context, ref, habit);
              if (deleted && context.mounted) context.pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _Header(habit: habit, goal: goal),
          const SizedBox(height: AppSpacing.md),
          _StatGrid(history: history, today: today, strength: strength.last),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Lịch tháng',
            child: MonthCalendar(
              today: today,
              dayBuilder: (context, day, isFuture) =>
                  _HabitDay(history: history, day: day, isFuture: isFuture),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Sức mạnh thói quen · $chartDays ngày',
            trailing: '${(strength.last * 100).round()}%',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StrengthChart(values: strength, today: today),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Làm đều 66 ngày thì đạt khoảng 95%. Bỏ một ngày chỉ giảm khoảng 4%, '
                  'nên một lần lỡ không xoá hết công sức.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // The 66-day journey and the 16-week heat map are parked (ADR-0004,
          // docs/architecture/parked-features.md).
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Ghi chú',
            child: _NotesTimeline(
              logs: logs.where((log) => log.habitId == habit.id && log.note.isNotEmpty).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.habit, required this.goal});

  final Habit habit;
  final Goal? goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final identity = goal?.identity ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HabitIconTile(icon: habit.icon, colorIndex: habit.colorIndex),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.name, style: theme.textTheme.titleLarge),
                  Text(
                    [HabitSchedule.describe(habit), ?goal?.title].join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          HabitScience.intentionSentence(
            name: habit.name,
            minutes: habit.minMinutesPerDay,
            cue: habit.cue,
            place: habit.place,
          ),
          style: theme.textTheme.bodyLarge,
        ),
        if (habit.minimalVersion.isNotEmpty)
          _InfoLine(icon: AppIcons.minimal, text: 'Bản 2 phút: ${habit.minimalVersion}'),
        if (identity.isNotEmpty) _InfoLine(icon: AppIcons.identity, text: 'Tôi là người $identity'),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Khung một khối: tiêu đề nhỏ, số nổi bật bên phải (không bắt buộc) và nội dung.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.tertiary),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

/// Lưới 2×3 ô số liệu.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.history, required this.today, required this.strength});

  final HabitHistory history;
  final DateTime today;

  /// Điểm sức mạnh hôm nay, 0–1.
  final double strength;

  @override
  Widget build(BuildContext context) {
    final current = HabitScience.currentStreak(history, today);
    final longest = HabitScience.longestStreak(history, today);
    final rate = HabitScience.completionRate(history, addDays(today, -29), today, today: today);
    final weekday = HabitScience.mostMissedWeekday(history, today: today);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: AppIcons.streak,
                label: 'Chuỗi hiện tại',
                value: '$current ngày',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(icon: AppIcons.badge, label: 'Dài nhất', value: '$longest ngày'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: AppIcons.check,
                label: 'Tỉ lệ 30 ngày',
                value: '${(rate * 100).round()}%',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                icon: AppIcons.missing,
                label: 'Hay bỏ nhất',
                value: weekday == null ? 'Chưa bỏ' : weekdayLong[weekday - 1],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: AppIcons.done,
                label: 'Lần hoàn thành',
                value: '${history.doneDays.length}',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                icon: AppIcons.strength,
                label: 'Sức mạnh',
                value: '${(strength * 100).round()}%',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.tertiary),
              const SizedBox(height: AppSpacing.sm),
              Text(value, style: theme.textTheme.titleLarge, maxLines: 1),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một ngày trong lịch tháng: đã xong thì tô màu pastel của thói quen; bỏ qua có gạch;
/// không có lịch thì mờ.
class _HabitDay extends StatelessWidget {
  const _HabitDay({required this.history, required this.day, required this.isFuture});

  final HabitHistory history;
  final DateTime day;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = AppHabitColors.of(history.habit.colorIndex);
    final done = history.isDone(day);
    final skipped = history.marks[day] == HabitLogSource.skip;
    final restDay = !done && !history.isScheduled(day);
    final state = done
        ? 'đã xong'
        : skipped
        ? 'bỏ qua'
        : isFuture
        ? 'chưa tới'
        : restDay
        ? 'không có lịch'
        : 'chưa làm';

    return Semantics(
      container: true,
      label: '${day.day}/${day.month}: $state',
      excludeSemantics: true,
      child: Opacity(
        opacity: isFuture || restDay ? 0.4 : 1,
        child: Container(
          width: AppHabit.calendarDay,
          height: AppHabit.calendarDay,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? color.background : null,
            border: done ? null : Border.all(color: scheme.outlineVariant),
          ),
          child: Text(
            '${day.day}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: done ? color.foreground : scheme.onSurface,
              decoration: skipped ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Biểu đồ đường điểm sức mạnh, trục dọc 0–100%.
class _StrengthChart extends StatelessWidget {
  const _StrengthChart({required this.values, required this.today});

  final List<double> values;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final last = values.length - 1;
    final first = (values.first * 100).round();
    final now = (values.last * 100).round();

    String bottomLabel(int index) {
      if (index == last) return 'Hôm nay';
      return '${last - index} ngày trước';
    }

    return Semantics(
      container: true,
      label: 'Biểu đồ sức mạnh: ${values.length} ngày trước $first%, hôm nay $now%',
      excludeSemantics: true,
      child: SizedBox(
        height: AppHabit.chartHeight,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: last.toDouble(),
            minY: 0,
            maxY: 100,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: 50,
                  getTitlesWidget: (value, meta) => Text('${value.round()}%', style: labelStyle),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    // Chỉ ghi nhãn ở đầu, giữa và cuối cho đỡ rối.
                    if (index != 0 && index != last ~/ 2 && index != last) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      // Giữ nhãn đầu và cuối nằm gọn trong biểu đồ, không bị cắt ở mép.
                      fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                      child: Text(bottomLabel(index), style: labelStyle),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => scheme.onSurface,
                getTooltipItems: (spots) => [
                  for (final spot in spots)
                    LineTooltipItem(
                      '${bottomLabel(spot.x.round())}\n${spot.y.round()}%',
                      theme.textTheme.labelMedium!.copyWith(color: scheme.surface),
                    ),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i] * 100),
                ],
                isCurved: true,
                preventCurveOverShooting: true,
                color: scheme.tertiary,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: scheme.tertiary.withValues(alpha: 0.14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dòng thời gian các ghi chú, mới nhất ở trên.
class _NotesTimeline extends StatelessWidget {
  const _NotesTimeline({required this.logs});

  final List<HabitLog> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (logs.isEmpty) {
      return Text(
        'Chưa có ghi chú nào. Sau khi tick, bấm "Thêm ghi chú" trên thẻ thói quen để ghi lại '
        'hôm nay thế nào.',
        style: theme.textTheme.bodySmall,
      );
    }

    final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
    return Column(
      children: [
        for (var i = 0; i < sorted.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Chấm tròn và đường dọc nối các ghi chú.
                SizedBox(
                  width: AppSpacing.md,
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        width: AppSpacing.sm + 2,
                        height: AppSpacing.sm + 2,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.tertiary),
                      ),
                      if (i < sorted.length - 1)
                        Expanded(child: VerticalDivider(color: scheme.outlineVariant, width: 2)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weekdayLong[sorted[i].date.weekday - 1]}, '
                          '${sorted[i].date.day}/${sorted[i].date.month}'
                          '${sorted[i].source == HabitLogSource.minimal ? ' · bản 2 phút' : ''}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(sorted[i].note, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
