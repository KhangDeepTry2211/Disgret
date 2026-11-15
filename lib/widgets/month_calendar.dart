// 4.2 Lịch một tháng có nút chuyển tháng trước/sau, dùng ở màn Báo cáo (vòng tròn theo %
// hoàn thành) và màn chi tiết thói quen (ngày đã xong tô màu thói quen). Ô mỗi ngày do nơi dùng
// tự vẽ qua [dayBuilder]; widget này chỉ lo phần khung, tiêu đề thứ và ngày trống đầu tháng.
import 'package:material_ui/material_ui.dart';

import '../data/date_utils.dart';
import '../theme/app_theme.dart';

class MonthCalendar extends StatefulWidget {
  const MonthCalendar({required this.today, required this.dayBuilder, super.key});

  final DateTime today;

  /// Vẽ ô của một ngày; [isFuture] là ngày sau hôm nay.
  final Widget Function(BuildContext context, DateTime day, bool isFuture) dayBuilder;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  /// Ngày 1 của tháng đang xem.
  late DateTime _month = DateTime(widget.today.year, widget.today.month);

  bool get _isCurrentMonth =>
      _month.year == widget.today.year && _month.month == widget.today.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = _month.weekday - 1;

    return Column(
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
              // Không xem trước các tháng chưa tới.
              onPressed: _isCurrentMonth
                  ? null
                  : () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.xs,
          crossAxisSpacing: AppSpacing.xs,
          children: [
            for (final label in weekdayShort)
              Center(child: Text(label, style: theme.textTheme.bodySmall)),
            for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
            for (var d = 1; d <= daysInMonth; d++)
              Center(
                child: widget.dayBuilder(
                  context,
                  DateTime(_month.year, _month.month, d),
                  DateTime(_month.year, _month.month, d).isAfter(widget.today),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
