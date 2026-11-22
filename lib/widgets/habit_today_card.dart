// 4.2 Ghi nhận – thẻ một thói quen ở tab "Hôm nay": thẻ bo tròn tô màu pastel riêng,
// emoji/icon bên trái, tên đậm.
// - Chạm: đánh dấu xong (dải ✓ trượt từ trái sang + rung nhẹ, rồi thẻ chuyển xuống "Đã xong").
//   Chạm thẻ đã xong thì bỏ đánh dấu (trừ khi đủ phút nhờ phiên Focus).
// - Vuốt sang phải: xong. Vuốt sang trái: hiện "Bỏ qua" (ghi log skip).
// - Giữ lâu: menu Làm bản 2 phút, Nghỉ phép, Bắt đầu Focus, Xem chi tiết, Sửa, Xoá.
// - Có phút Focus mà chưa đủ: vạch tiến độ phút mỏng ở đáy thẻ.
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/habit_progress.dart';
import '../data/habit_science.dart';
import '../data/models/habit.dart';
import '../data/models/habit_log.dart';
import '../data/models/reel.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import 'app_dialogs.dart';
import 'goal_habit_sheets.dart';
import 'habit_icon_view.dart';

/// Trạng thái hôm nay của một thói quen, quyết định thẻ nằm ở mục nào.
enum TodayStatus { pending, done, skipped }

TodayStatus todayStatusOf(HabitHistory history, DateTime today) {
  if (history.isDone(today)) return TodayStatus.done;
  final mark = history.marks[today];
  if (mark == HabitLogSource.skip || mark == HabitLogSource.freeze) return TodayStatus.skipped;
  return TodayStatus.pending;
}

class HabitTodayCard extends ConsumerStatefulWidget {
  const HabitTodayCard({required this.habit, required this.history, super.key});

  final Habit habit;
  final HabitHistory history;

  @override
  ConsumerState<HabitTodayCard> createState() => _HabitTodayCardState();
}

class _HabitTodayCardState extends ConsumerState<HabitTodayCard>
    with SingleTickerProviderStateMixin {
  /// Dải ✓ trượt từ trái sang khi vừa chạm "xong" (giống ảnh 03 của kit).
  late final AnimationController _check = AnimationController(
    vsync: this,
    duration: AppHabit.cardAnimation,
  );

  @override
  void dispose() {
    _check.dispose();
    super.dispose();
  }

  Habit get _habit => widget.habit;
  HabitLogsNotifier get _logs => ref.read(habitLogsProvider.notifier);

  Future<void> _markDone() async {
    if (!kIsWeb) HapticFeedback.lightImpact();
    await _check.forward(from: 0);
    if (!mounted) return;
    await _logs.setDoneToday(_habit, done: true);
  }

  Future<void> _undo() => _logs.setDoneToday(_habit, done: false);

  Future<void> _skip() async {
    if (!kIsWeb) HapticFeedback.selectionClick();
    await _logs.setMarkToday(_habit, HabitLogSource.skip);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = ref.watch(todayProvider);
    final logs = ref.watch(habitLogsProvider);
    final color = AppHabitColors.of(_habit.colorIndex);
    final status = todayStatusOf(widget.history, today);
    final mark = widget.history.marks[today];
    final minutes = HabitProgress.minutesOn(_habit, today, logs);
    // Đủ phút nhờ phiên Focus thì không cho bỏ đánh dấu: bỏ tick không xoá được phút học thật.
    final lockedByFocus = status == TodayStatus.done && mark == null;

    final String? note = switch (status) {
      TodayStatus.done when mark == HabitLogSource.minimal => 'Đã làm bản 2 phút',
      TodayStatus.done when lockedByFocus => 'Đủ phút từ phiên Focus',
      TodayStatus.skipped when mark == HabitLogSource.freeze => 'Nghỉ phép',
      TodayStatus.skipped => 'Bỏ qua hôm nay',
      TodayStatus.pending when minutes > 0 => '$minutes/${_habit.minMinutesPerDay} phút',
      _ => null,
    };

    VoidCallback? onTap;
    String stateLabel;
    switch (status) {
      case TodayStatus.pending:
        onTap = _markDone;
        stateLabel = 'chưa làm';
      case TodayStatus.done:
        onTap = lockedByFocus ? null : _undo;
        stateLabel = 'đã xong';
      case TodayStatus.skipped:
        onTap = _undo;
        stateLabel = mark == HabitLogSource.freeze ? 'nghỉ phép' : 'bỏ qua';
    }

    Widget card = Material(
      color: color.background,
      borderRadius: AppRadius.cardBorder,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => showHabitActionsSheet(context, ref, habit: _habit),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md - 2,
              ),
              child: Row(
                children: [
                  HabitIconView(
                    icon: _habit.icon,
                    size: AppHabit.todayIcon,
                    color: color.foreground,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _habit.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(color: color.foreground),
                        ),
                        if (note != null)
                          Text(
                            note,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: color.foreground.withValues(alpha: 0.75),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (status == TodayStatus.done)
                    Container(
                      width: AppSpacing.lg,
                      height: AppSpacing.lg,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color.foreground),
                      child: Icon(AppIcons.done, size: 16, color: color.background),
                    ),
                ],
              ),
            ),
            // Vạch tiến độ phút mỏng ở đáy thẻ khi đã có phút Focus mà chưa đủ.
            if (status == TodayStatus.pending && minutes > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: (minutes / _habit.minMinutesPerDay).clamp(0.0, 1.0),
                  minHeight: AppHabit.todayProgress,
                  color: color.foreground,
                  backgroundColor: color.foreground.withValues(alpha: 0.15),
                ),
              ),
            // Dải ✓ trượt vào khi vừa chạm "xong".
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _check,
                  builder: (context, _) => _check.value == 0
                      ? const SizedBox.shrink()
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: Curves.easeOut.transform(_check.value),
                            heightFactor: 1,
                            child: ColoredBox(
                              color: scheme.tertiary,
                              child: Icon(AppIcons.done, color: scheme.onTertiary),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    card = Semantics(
      button: true,
      label: '${_habit.name}, $stateLabel',
      hint: status == TodayStatus.pending
          ? 'Chạm để đánh dấu xong, vuốt trái để bỏ qua, giữ lâu để xem thêm'
          : 'Giữ lâu để xem thêm',
      child: card,
    );

    if (status == TodayStatus.skipped) card = Opacity(opacity: 0.6, child: card);
    if (status != TodayStatus.pending) return card;

    // Vuốt: phải = xong, trái = bỏ qua. Luôn trả false để thẻ không bị gỡ khỏi cây widget;
    // trạng thái mới tự đưa thẻ sang mục khác.
    return Dismissible(
      key: ValueKey('swipe_${_habit.id}'),
      direction: DismissDirection.horizontal,
      background: _SwipeBackground(
        color: scheme.tertiary,
        foreground: scheme.onTertiary,
        icon: AppIcons.done,
        label: 'Xong',
        alignLeft: true,
      ),
      secondaryBackground: _SwipeBackground(
        color: scheme.error,
        foreground: scheme.onError,
        icon: AppIcons.arrowForward,
        label: 'Bỏ qua',
        alignLeft: false,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (!kIsWeb) HapticFeedback.lightImpact();
          await _logs.setDoneToday(_habit, done: true);
        } else {
          await _skip();
        }
        return false;
      },
      child: card,
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.foreground,
    required this.icon,
    required this.label,
    required this.alignLeft,
  });

  final Color color;
  final Color foreground;
  final IconData icon;
  final String label;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground);
    final children = alignLeft
        ? [
            Icon(icon, color: foreground),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: style),
          ]
        : [
            Text(label, style: style),
            const SizedBox(width: AppSpacing.sm),
            Icon(icon, color: foreground),
          ];

    return Container(
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.cardBorder),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Hiệu ứng nhẹ khi một thẻ vừa xuất hiện (ví dụ vừa chuyển xuống "Đã xong"):
/// mờ dần hiện ra và trượt xuống một chút.
class AppearAnimation extends StatelessWidget {
  const AppearAnimation({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppHabit.cardAnimation,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * -AppSpacing.md), child: child),
      ),
      child: child,
    );
  }
}

enum _HabitAction { minimal, freeze, focus, details, edit, delete, clear }

/// 4.2 Giữ lâu một thẻ: Làm bản 2 phút, Nghỉ phép, Bắt đầu Focus, Xem chi tiết, Sửa, Xoá.
/// Sheet chỉ trả về lựa chọn; thao tác chạy sau khi sheet đóng, bằng [context] và [ref] của
/// màn bên dưới (của sheet thì đã bị huỷ).
Future<void> showHabitActionsSheet(
  BuildContext context,
  WidgetRef ref, {
  required Habit habit,
}) async {
  final action = await showAppBottomSheet<_HabitAction>(
    context,
    builder: (_) => _HabitActionsSheet(habit: habit),
  );
  if (action == null || !context.mounted) return;

  final logs = ref.read(habitLogsProvider.notifier);
  switch (action) {
    case _HabitAction.minimal:
      if (!kIsWeb) HapticFeedback.lightImpact();
      await logs.setMarkToday(habit, HabitLogSource.minimal);
    case _HabitAction.freeze:
      await logs.setMarkToday(habit, HabitLogSource.freeze);
    case _HabitAction.clear:
      await logs.clearMarksOn(habit, ref.read(todayProvider));
    case _HabitAction.focus:
      // Single study entry (ADR-0002): set the plan habit, then go through motivation.
      // If a session already runs, the router sends this to that session.
      ref.read(sessionPlanOverrideProvider.notifier).chooseHabit(habit.id);
      await context.push(AppRoutes.motivationFor(ReelContext.start));
    case _HabitAction.details:
      await context.push(AppRoutes.habitDetail(habit.id));
    case _HabitAction.edit:
      await context.push(AppRoutes.habitForm(habit.goalId, habit.id));
    case _HabitAction.delete:
      await confirmDeleteHabit(context, ref, habit);
  }
}

class _HabitActionsSheet extends ConsumerWidget {
  const _HabitActionsSheet({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logs = ref.watch(habitLogsProvider);
    final today = ref.watch(todayProvider);
    final mark = HabitProgress.markLogOn(habit, today, logs)?.source;
    final canFreeze = HabitScience.canFreeze(habit, logs, today);

    Widget item(
      IconData icon,
      String title,
      _HabitAction action, {
      String? subtitle,
      bool enabled = true,
    }) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        enabled: enabled,
        onTap: () => Navigator.of(context).pop(action),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            HabitIconTile(icon: habit.icon, colorIndex: habit.colorIndex, size: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(habit.name, style: theme.textTheme.titleLarge)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        item(
          AppIcons.minimal,
          'Làm bản 2 phút',
          _HabitAction.minimal,
          subtitle: habit.minimalVersion.isEmpty
              ? 'Làm một phần thật nhỏ để không đứt chuỗi'
              : habit.minimalVersion,
        ),
        item(
          AppIcons.freeze,
          'Nghỉ phép',
          _HabitAction.freeze,
          subtitle: canFreeze
              ? 'Không đứt chuỗi, điểm sức mạnh giữ nguyên. Mỗi tuần 1 ngày.'
              : 'Tuần này bạn đã dùng ngày nghỉ phép rồi.',
          enabled: canFreeze,
        ),
        item(AppIcons.focus, 'Bắt đầu Focus', _HabitAction.focus),
        item(AppIcons.details, 'Xem chi tiết', _HabitAction.details),
        item(AppIcons.editValue, 'Sửa', _HabitAction.edit),
        item(AppIcons.deleteAll, 'Xoá', _HabitAction.delete),
        if (mark != null) item(AppIcons.clearMark, 'Bỏ đánh dấu hôm nay', _HabitAction.clear),
      ],
    );
  }
}
