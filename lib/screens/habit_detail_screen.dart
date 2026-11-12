// 4.2 Màn chi tiết một thói quen:
// - đầu trang: icon, tên, câu "Sau khi…, tôi sẽ… tại…", bản 2 phút, câu bản sắc;
// - lưới 4 ô số liệu: chuỗi hiện tại, dài nhất, tỉ lệ 30 ngày, thứ hay bỏ nhất;
// - biểu đồ đường điểm sức mạnh 60 ngày (fl_chart);
// - Hành trình 66 ngày với 4 huy hiệu;
// - lịch nhiệt 16 tuần kiểu GitHub;
// - dòng thời gian ghi chú.
// Mọi con số lấy từ habit_science.dart; màn hình chỉ hiển thị.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/date_utils.dart';
import '../data/habit_science.dart';
import '../data/models/goal.dart';
import '../data/models/habit.dart';
import '../data/models/habit_log.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/edit_delete_menu.dart';
import '../widgets/goal_habit_sheets.dart';
import '../widgets/gradient_progress_bar.dart';
import '../widgets/habit_heat_map.dart';

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
          EditDeleteMenu(
            tooltip: 'Tuỳ chọn thói quen',
            onEdit: () => context.push(AppRoutes.habitForm(habit.goalId, habit.id)),
            onDelete: () async {
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
          _StatGrid(history: history, today: today),
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
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Hành trình ${HabitScience.habitFormationDays} ngày',
            child: _Journey(days: HabitScience.journeyDays(history)),
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Lịch 16 tuần',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HabitHeatCalendar(history: history, today: today),
                const SizedBox(height: AppSpacing.md),
                const HeatLegend(),
              ],
            ),
          ),
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
    final scheme = theme.colorScheme;
    final identity = goal?.identity ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: AppHabit.iconTile,
              height: AppHabit.iconTile,
              decoration: BoxDecoration(
                color: scheme.tertiary.withValues(alpha: 0.14),
                borderRadius: AppRadius.cardBorder,
              ),
              child: Icon(AppIcons.habitIcon(habit.icon), color: scheme.tertiary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.name, style: theme.textTheme.titleLarge),
                  if (goal != null) Text(goal!.title, style: theme.textTheme.bodySmall),
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

/// Lưới 2×2 ô số liệu.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.history, required this.today});

  final HabitHistory history;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final current = HabitScience.currentStreakOf(history.doneDays, history.freezeDays, today);
    final longest = HabitScience.longestStreakOf(history.doneDays, history.freezeDays);
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

/// Thanh Hành trình 66 ngày và 4 huy hiệu: đạt thì màu nhấn, chưa đạt thì xám.
class _Journey extends StatelessWidget {
  const _Journey({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const total = HabitScience.habitFormationDays;
    final next = HabitScience.nextBadge(days);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${days.clamp(0, total)}/$total ngày hoàn thành', style: theme.textTheme.titleMedium),
        Text(
          next == null
              ? 'Bạn đã đi hết hành trình. Thói quen này đã thành của bạn!'
              : 'Còn ${next.days - days} ngày nữa tới huy hiệu "${next.name}". '
                    'Không cần liên tiếp.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        GradientProgressBar(value: days / total),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final badge in HabitScience.badges)
              Expanded(
                child: Semantics(
                  container: true,
                  label:
                      'Huy hiệu ${badge.name}, ${badge.days} ngày, '
                      '${days >= badge.days ? 'đã đạt' : 'chưa đạt'}',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Container(
                        width: AppHabit.iconTile,
                        height: AppHabit.iconTile,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: days >= badge.days ? scheme.tertiary : null,
                          border: days >= badge.days
                              ? null
                              : Border.all(color: scheme.outlineVariant, width: 1.5),
                        ),
                        child: Icon(
                          AppIcons.badge,
                          color: days >= badge.days ? scheme.onTertiary : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        badge.name,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: days >= badge.days ? scheme.onSurface : scheme.onSurfaceVariant,
                        ),
                      ),
                      Text('${badge.days} ngày', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
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
