// 8.2 Màn Thống kê: số liệu để kiểm chứng giả thuyết trong báo cáo.
// Mở từ Cài đặt. Phần tính toán nằm ở services/focus_stats.dart, màn này chỉ hiển thị.
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/app_providers.dart';
import '../services/focus_stats.dart';
import '../services/time_format.dart';
import '../theme/app_theme.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(focusStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _ErrorMessage(),
        data: (stats) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _FocusCard(stats: stats),
            const SizedBox(height: AppSpacing.md),
            _ResetBreakCard(stats: stats),
            const SizedBox(height: AppSpacing.md),
            _ReelsCard(stats: stats),
            const SizedBox(height: AppSpacing.md),
            _ReturnCard(stats: stats),
          ],
        ),
      ),
    );
  }
}

String _percent(double share) => '${(share * 100).round()}%';

/// Khung chung của mỗi thẻ: biểu tượng, tiêu đề, con số chính rồi tới nội dung.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.headline,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String headline;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: secondaryColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(color: secondaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(headline, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Dòng chữ phụ, dùng cho chú thích và hướng dẫn khi chưa có dữ liệu.
class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

/// Một dòng tỉ lệ: nhãn, số lần kèm phần trăm, và thanh ngang.
class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.label, required this.count, required this.share});

  final String label;
  final int count;
  final double share;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
              Text('$count lần · ${_percent(share)}', style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.pillBorder,
            child: LinearProgressIndicator(
              value: share,
              minHeight: 8,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.stats});

  final FocusStats stats;

  @override
  Widget build(BuildContext context) {
    return _StatCard(
      icon: AppIcons.focus,
      title: 'Phút tập trung · ${FocusStats.days} ngày gần nhất',
      headline: '${stats.totalFocusMinutes} phút',
      children: [
        const SizedBox(height: AppSpacing.sm),
        _FocusBarChart(days: stats.dailyFocus),
        const SizedBox(height: AppSpacing.md),
        if (stats.sessionCount == 0)
          const _Hint('Chưa có phiên học nào. Bấm "Bắt đầu" ở Trang chủ để học phiên đầu tiên.')
        else
          _Hint(
            '${stats.sessionCount} phiên học · '
            '${stats.habitDoneDays}/${FocusStats.days} ngày hoàn thành thói quen',
          ),
      ],
    );
  }
}

/// Biểu đồ cột đơn giản vẽ bằng widget: mỗi ngày một cột, cột hôm nay màu nhấn.
class _FocusBarChart extends StatelessWidget {
  const _FocusBarChart({required this.days});

  static const double _maxBarHeight = 120;
  static const double _minBarHeight = 2;
  static const List<String> _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  final List<DayFocus> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxMinutes = math.max(1, days.map((day) => day.minutes).reduce(math.max));
    final summary = [
      for (final day in days) '${_weekdays[day.day.weekday - 1]} ${day.minutes} phút',
    ].join(', ');

    return Semantics(
      container: true,
      label: 'Biểu đồ phút tập trung: $summary',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: _Bar(
                  minutes: days[i].minutes,
                  height: math.max(_minBarHeight, days[i].minutes / maxMinutes * _maxBarHeight),
                  label: _weekdays[days[i].day.weekday - 1],
                  color: i == days.length - 1
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.minutes,
    required this.height,
    required this.label,
    required this.color,
  });

  final int minutes;
  final double height;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$minutes', style: theme.textTheme.labelSmall),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.xs)),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _ResetBreakCard extends StatelessWidget {
  const _ResetBreakCard({required this.stats});

  final FocusStats stats;

  @override
  Widget build(BuildContext context) {
    return _StatCard(
      icon: AppIcons.intervention,
      title: 'Reset break · từ trước tới nay',
      headline: 'Đã chặn ${stats.interventionCount} lần',
      children: [
        if (stats.interventionCount == 0)
          const _Hint(
            'Chưa có lần chặn nào. Bật Reset break khi học, rồi thử mở YouTube '
            'để thấy màn can thiệp.',
          )
        else if (stats.choiceCount == 0)
          const _Hint('Bạn chưa chọn lựa chọn nào trên màn can thiệp.')
        else ...[
          const _Hint('Sau khi bị chặn, bạn đã chọn:'),
          _ShareRow(
            label: 'Quay lại học',
            count: stats.choseStudy,
            share: stats.choiceShare(stats.choseStudy)!,
          ),
          _ShareRow(
            label: 'Xem 1 reel động lực',
            count: stats.choseReel,
            share: stats.choiceShare(stats.choseReel)!,
          ),
          _ShareRow(
            label: 'Nghỉ có chủ đích',
            count: stats.choseBreak,
            share: stats.choiceShare(stats.choseBreak)!,
          ),
        ],
      ],
    );
  }
}

class _ReelsCard extends StatelessWidget {
  const _ReelsCard({required this.stats});

  final FocusStats stats;

  @override
  Widget build(BuildContext context) {
    final rate = stats.startedFocusRate;
    return _StatCard(
      icon: AppIcons.reelStats,
      title: 'Reels động lực · từ trước tới nay',
      headline: 'Đã xem ${stats.reelsWatched} reel',
      children: [
        if (rate == null)
          const _Hint('Chưa xem reel nào. Bấm "Bắt đầu" ở Trang chủ để xem reel trước khi học.')
        else
          _ShareRow(
            label: 'Bấm "Bắt đầu 5 phút" ngay sau khi xem',
            count: stats.reelsStartedFocus,
            share: rate,
          ),
      ],
    );
  }
}

class _ReturnCard extends StatelessWidget {
  const _ReturnCard({required this.stats});

  final FocusStats stats;

  @override
  Widget build(BuildContext context) {
    final average = stats.averageReturn;
    return _StatCard(
      icon: AppIcons.away,
      title: 'Quay lại sau xao nhãng · từ trước tới nay',
      headline: average == null ? 'Chưa có số liệu' : 'Trung bình ${formatSpoken(average)}',
      children: [
        if (average == null)
          const _Hint('Chưa có lần xao nhãng nào trong phiên học.')
        else
          _Hint(
            'Thời gian từ lúc rời app tới lúc quay lại học, '
            'tính trên ${stats.distractionCount} lần xao nhãng.',
          ),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.missing, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Không đọc được số liệu',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Dữ liệu đã lưu có thể bị hỏng. Thử thoát ra rồi mở lại màn này, '
              'hoặc xoá toàn bộ dữ liệu trong Cài đặt.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
