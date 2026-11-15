// 4.2 Lịch nhiệt (heat map) tự vẽ bằng widget, màu lấy từ AppColors.heatOf(context):
// - HabitHeatCalendar: 16 tuần kiểu GitHub trong màn chi tiết (cột = tuần, hàng = thứ).
// - HeatLegend: chú thích 4 mức màu.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/date_utils.dart';
import '../data/habit_science.dart';
import '../theme/app_theme.dart';

/// Một ô lịch nhiệt. [level] null nghĩa là ngày chưa tới (chỉ có viền).
class HeatCell extends StatelessWidget {
  const HeatCell({required this.level, this.freeze = false, this.size, this.child, super.key});

  final int? level;
  final bool freeze;
  final double? size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final heat = AppColors.heatOf(context);
    final level = this.level;

    final Border? border;
    if (freeze) {
      border = Border.all(color: scheme.tertiary, width: 1.5);
    } else if (level == null) {
      border = Border.all(color: scheme.outlineVariant);
    } else {
      border = null;
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: level == null ? null : heat[level],
        borderRadius: AppRadius.heatCellBorder,
        border: border,
      ),
      child: child,
    );
  }
}

/// Mức màu của một thói quen trong một ngày; null (ô chỉ có viền) nếu ngày chưa tới,
/// hoặc ngày không có trong lịch mà cũng không làm (ví dụ thói quen hằng tuần).
int? habitHeatLevel(HabitHistory history, DateTime day, DateTime today) {
  if (day.isAfter(today)) return null;
  if (!history.isScheduled(day) && !history.isDone(day)) return null;
  return HabitScience.heatLevel(history.valueOn(day));
}

/// Lịch nhiệt [weeks] tuần kiểu GitHub: mỗi cột một tuần (T2 ở trên, CN ở dưới),
/// cột cuối là tuần này. Ô tự co theo chiều rộng màn hình.
class HabitHeatCalendar extends StatelessWidget {
  const HabitHeatCalendar({required this.history, required this.today, this.weeks = 16, super.key});

  final HabitHistory history;
  final DateTime today;
  final int weeks;

  /// Chỉ ghi nhãn T2, T4, T6, CN cho đỡ rối, giống GitHub.
  static const Set<int> _labelledRows = {0, 2, 4, 6};
  static const double _labelWidth = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstMonday = addDays(weekStart(today), -7 * (weeks - 1));
    DateTime dayAt(int week, int row) => addDays(firstMonday, week * 7 + row);
    final doneCount = [for (var i = 0; i < weeks * 7; i++) addDays(firstMonday, i)]
        .where(history.isDone)
        .length;

    return Semantics(
      container: true,
      label: 'Lịch $weeks tuần: hoàn thành $doneCount ngày',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth - _labelWidth;
          final cell = math.min(
            AppHabit.heatCellMax,
            (available - AppHabit.heatGap * (weeks - 1)) / weeks,
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _labelWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var row = 0; row < 7; row++)
                      SizedBox(
                        height: cell + (row < 6 ? AppHabit.heatGap : 0),
                        child: _labelledRows.contains(row)
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(weekdayShort[row], style: theme.textTheme.labelSmall),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
              for (var week = 0; week < weeks; week++) ...[
                if (week > 0) const SizedBox(width: AppHabit.heatGap),
                Column(
                  children: [
                    for (var row = 0; row < 7; row++) ...[
                      if (row > 0) const SizedBox(height: AppHabit.heatGap),
                      HeatCell(
                        size: cell,
                        level: habitHeatLevel(history, dayAt(week, row), today),
                        freeze: history.isFreeze(dayAt(week, row)),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Chú thích: "Ít" 4 ô màu "Nhiều", và ô viền màu nhấn là ngày nghỉ phép.
class HeatLegend extends StatelessWidget {
  const HeatLegend({super.key});

  static const double _size = 12;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ít', style: style),
            for (var level = 0; level < 4; level++) ...[
              const SizedBox(width: AppSpacing.xs),
              HeatCell(level: level, size: _size),
            ],
            const SizedBox(width: AppSpacing.xs),
            Text('Nhiều', style: style),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HeatCell(level: 0, freeze: true, size: _size),
            const SizedBox(width: AppSpacing.xs),
            Text('Nghỉ phép', style: style),
          ],
        ),
      ],
    );
  }
}
