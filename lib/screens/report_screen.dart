// 4.2 Màn Báo cáo (bố cục theo design/habit_kit/ ảnh 13–15). Shown in the Tiến độ tab, segment
// "Thói quen" (spec 001 FR-012):
// - 4 ô số liệu: chuỗi hiện tại, tỉ lệ hoàn thành, số lần hoàn thành, số ngày hoàn hảo;
// - biểu đồ cột "Đã hoàn thành" và biểu đồ đường "Tỉ lệ hoàn thành" (fl_chart), mỗi biểu đồ có
//   menu chọn kỳ; cột/điểm đang chọn có bong bóng giá trị;
// - lịch tháng: mỗi ngày một vòng tròn tô theo % hoàn thành.
// Mọi con số lấy từ habit_science.dart; màn hình chỉ hiển thị. Tính cả thói quen đã ẩn.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/habit_science.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/month_calendar.dart';
import '../widgets/progress_ring.dart';

/// Tên tiếng Việt của từng kỳ trên menu chọn kỳ.
const Map<ReportPeriod, String> reportPeriodLabels = {
  ReportPeriod.thisWeek: 'Tuần này',
  ReportPeriod.lastWeek: 'Tuần trước',
  ReportPeriod.thisMonth: 'Tháng này',
  ReportPeriod.lastMonth: 'Tháng trước',
  ReportPeriod.sixMonths: '6 tháng',
  ReportPeriod.thisYear: 'Năm nay',
  ReportPeriod.allTime: 'Tất cả',
};

/// Habit report body without Scaffold; shown in Tiến độ.
class ReportView extends ConsumerStatefulWidget {
  const ReportView({super.key});

  @override
  ConsumerState<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends ConsumerState<ReportView> {
  ReportPeriod _barPeriod = ReportPeriod.thisWeek;
  ReportPeriod _ratePeriod = ReportPeriod.sixMonths;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final histories = ref.watch(allHabitHistoriesProvider);
    final today = ref.watch(todayProvider);

    if (histories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Chưa có thói quen nào. Tạo thói quen và đánh dấu vài ngày để xem báo cáo.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    final start = HabitScience.earliestStart(histories) ?? today;
    final total = HabitScience.tally(histories, start, today, today: today);
    final rate = total.due == 0 ? 0.0 : total.completed / total.due;
    final perfect = HabitScience.perfectDays(histories, start, today, today: today);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        // The floating tab bar covers the bottom of the screen (spec 010).
        AppSpacing.md + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: _NumberTile(
                value: '${ref.watch(overallStreakProvider)} ngày',
                label: 'Chuỗi hiện tại',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _NumberTile(value: '${(rate * 100).round()}%', label: 'Tỉ lệ hoàn thành'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _NumberTile(
                value: '${ref.watch(completionTotalProvider)}',
                label: 'Lần hoàn thành',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _NumberTile(value: '$perfect', label: 'Ngày hoàn hảo'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ChartCard(
          title: 'Đã hoàn thành',
          period: _barPeriod,
          onPeriod: (period) => setState(() => _barPeriod = period),
          child: _CompletedBarChart(
            key: ValueKey(_barPeriod),
            buckets: HabitScience.buckets(histories, _barPeriod, today),
            today: today,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ChartCard(
          title: 'Tỉ lệ hoàn thành',
          period: _ratePeriod,
          onPeriod: (period) => setState(() => _ratePeriod = period),
          child: _RateLineChart(
            key: ValueKey(_ratePeriod),
            buckets: HabitScience.buckets(histories, _ratePeriod, today),
            today: today,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ChartCard(
          title: 'Lịch hoàn thành',
          child: MonthCalendar(
            today: today,
            dayBuilder: (context, day, isFuture) => _RateDay(
              day: day,
              rate: isFuture ? null : HabitScience.dayRate(histories, day, today: today),
              isToday: day == today,
              isFuture: isFuture,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Ngày hoàn hảo: mọi thói quen đến hạn hôm đó đều xong. Ngày không có thói quen nào '
          'đến hạn thì không tính.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Ô số liệu: số to ở trên, nhãn nhỏ ở dưới (như ảnh 13).
class _NumberTile extends StatelessWidget {
  const _NumberTile({required this.value, required this.label});

  final String value;
  final String label;

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
              Text(value, style: theme.textTheme.titleLarge, maxLines: 1),
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Khung một biểu đồ: tiêu đề, menu chọn kỳ (nếu có), đường kẻ và nội dung.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child, this.period, this.onPeriod});

  final String title;
  final Widget child;
  final ReportPeriod? period;
  final ValueChanged<ReportPeriod>? onPeriod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = period;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
                if (selected != null)
                  PopupMenuButton<ReportPeriod>(
                    tooltip: 'Chọn kỳ: $title',
                    onSelected: onPeriod,
                    itemBuilder: (context) => [
                      for (final entry in reportPeriodLabels.entries)
                        PopupMenuItem(value: entry.key, child: Text(entry.value)),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs + 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.pillBorder,
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(reportPeriodLabels[selected]!, style: theme.textTheme.labelMedium),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(AppIcons.dropdown, size: 18),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

/// Vị trí mặc định được chọn: cột chứa hôm nay, không có thì cột cuối.
int _defaultIndex(List<ReportBucket> buckets, DateTime today) {
  final index = buckets.indexWhere(
    (bucket) => !today.isBefore(bucket.from) && !today.isAfter(bucket.to),
  );
  return index >= 0 ? index : buckets.length - 1;
}

/// Kiểu bong bóng giá trị dùng chung cho hai biểu đồ.
TextStyle? _bubbleStyle(ThemeData theme) =>
    theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSecondary);

class _CompletedBarChart extends StatefulWidget {
  const _CompletedBarChart({required this.buckets, required this.today, super.key});

  final List<ReportBucket> buckets;
  final DateTime today;

  @override
  State<_CompletedBarChart> createState() => _CompletedBarChartState();
}

class _CompletedBarChartState extends State<_CompletedBarChart> {
  late int _selected = _defaultIndex(widget.buckets, widget.today);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final buckets = widget.buckets;
    final maxCount = buckets.fold(
      0,
      (max, bucket) => bucket.completed > max ? bucket.completed : max,
    );
    final maxY = (maxCount < 1 ? 1 : maxCount) * 1.3;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final selected = buckets[_selected];

    return Semantics(
      container: true,
      label:
          'Biểu đồ cột số lần hoàn thành. Đang chọn ${selected.label}: '
          '${selected.completed} lần',
      child: SizedBox(
        height: AppHabit.barChartHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = (constraints.maxWidth / buckets.length * 0.55).clamp(6.0, 36.0);
            return BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        // Chỉ ghi các số nguyên, không ghi ở đỉnh trục (phần chừa cho bong bóng).
                        if (value != value.roundToDouble() || value > maxCount) {
                          return const SizedBox.shrink();
                        }
                        return Text('${value.toInt()}', style: labelStyle);
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(buckets[value.toInt()].label, style: labelStyle),
                      ),
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  handleBuiltInTouches: false,
                  touchCallback: (event, response) {
                    final spot = response?.spot;
                    if (event is FlTapUpEvent && spot != null) {
                      setState(() => _selected = spot.touchedBarGroupIndex);
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => scheme.secondary,
                    tooltipBorderRadius: AppRadius.cardBorder,
                    fitInsideHorizontally: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem('${rod.toY.toInt()} lần', _bubbleStyle(theme)!),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < buckets.length; i++)
                    BarChartGroupData(
                      x: i,
                      showingTooltipIndicators: i == _selected ? [0] : const [],
                      barRods: [
                        BarChartRodData(
                          toY: buckets[i].completed.toDouble(),
                          width: barWidth,
                          color: i == _selected
                              ? scheme.tertiary
                              : scheme.tertiary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(barWidth / 2)),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RateLineChart extends StatefulWidget {
  const _RateLineChart({required this.buckets, required this.today, super.key});

  final List<ReportBucket> buckets;
  final DateTime today;

  @override
  State<_RateLineChart> createState() => _RateLineChartState();
}

class _RateLineChartState extends State<_RateLineChart> {
  late int _selected = _defaultIndex(widget.buckets, widget.today);

  /// Tỉ lệ (0–100) của một kỳ; null nếu kỳ đó không có gì phải làm.
  double? _percent(ReportBucket bucket) =>
      bucket.due == 0 ? null : bucket.completed / bucket.due * 100;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final buckets = widget.buckets;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final spots = [
      for (var i = 0; i < buckets.length; i++)
        _percent(buckets[i]) == null
            ? FlSpot.nullSpot
            : FlSpot(i.toDouble(), _percent(buckets[i])!),
    ];
    final bar = LineChartBarData(
      spots: spots,
      color: scheme.tertiary,
      barWidth: 2.5,
      preventCurveOverShooting: true,
      dotData: FlDotData(
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: index == _selected ? 6 : 4,
          color: scheme.surfaceContainer,
          strokeWidth: 2.5,
          strokeColor: scheme.tertiary,
        ),
      ),
      belowBarData: BarAreaData(show: true, color: scheme.tertiary.withValues(alpha: 0.14)),
    );
    final selectedPercent = _percent(buckets[_selected]);
    final showBubble = selectedPercent != null;

    return Semantics(
      container: true,
      label:
          'Biểu đồ tỉ lệ hoàn thành. Đang chọn ${buckets[_selected].label}: '
          '${selectedPercent == null ? 'chưa có số liệu' : '${selectedPercent.round()}%'}',
      child: SizedBox(
        height: AppHabit.chartHeight + AppSpacing.xl,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (buckets.length - 1).toDouble().clamp(1, double.infinity),
            minY: 0,
            maxY: 125,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: 25,
              checkToShowHorizontalLine: (value) => value <= 100,
              getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 25,
                  getTitlesWidget: (value, meta) => value > 100
                      ? const SizedBox.shrink()
                      : Text('${value.toInt()}%', style: labelStyle),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= buckets.length || value != index.toDouble()) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                      child: Text(buckets[index].label, style: labelStyle),
                    );
                  },
                ),
              ),
            ),
            showingTooltipIndicators: showBubble
                ? [
                    ShowingTooltipIndicators([LineBarSpot(bar, 0, spots[_selected])]),
                  ]
                : const [],
            lineTouchData: LineTouchData(
              handleBuiltInTouches: false,
              touchCallback: (event, response) {
                final spot = response?.lineBarSpots?.firstOrNull;
                if (event is FlTapUpEvent && spot != null) {
                  setState(() => _selected = spot.spotIndex);
                }
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => scheme.secondary,
                tooltipBorderRadius: AppRadius.cardBorder,
                // The latest month sits at the right edge: keep its bubble inside the card.
                fitInsideHorizontally: true,
                getTooltipItems: (touched) => [
                  for (final spot in touched)
                    LineTooltipItem('${spot.y.round()}%', _bubbleStyle(theme)!),
                ],
              ),
            ),
            lineBarsData: [bar],
          ),
        ),
      ),
    );
  }
}

/// Một ngày trong lịch Báo cáo: vòng tròn tô theo % hoàn thành của ngày đó.
class _RateDay extends StatelessWidget {
  const _RateDay({
    required this.day,
    required this.rate,
    required this.isToday,
    required this.isFuture,
  });

  final DateTime day;
  final double? rate;
  final bool isToday;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = rate == null ? null : (rate! * 100).round();

    return Semantics(
      container: true,
      label: '${day.day}/${day.month}: ${percent == null ? 'không có gì phải làm' : '$percent%'}',
      excludeSemantics: true,
      child: Opacity(
        opacity: isFuture ? 0.4 : 1,
        child: ProgressRing(
          progress: rate ?? 0,
          size: AppHabit.calendarDay,
          strokeWidth: AppHabit.calendarRingStroke,
          child: Text(
            '${day.day}',
            style: isToday ? theme.textTheme.labelLarge : theme.textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}
