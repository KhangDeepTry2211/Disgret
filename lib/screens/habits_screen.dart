// 5.1 Màn Thói quen (bố cục theo design/habit_kit/ ảnh 01–06):
// - Đầu màn: logo nhỏ, tiêu đề, nút Báo cáo, menu (Thói quen của tôi, Thành tích,
//   Thêm mục tiêu, Quản lý mục tiêu); 3 tab
//   "Hôm nay / Tuần / Tổng thể"; chip lọc "Tất cả / Sáng / Chiều / Tối" theo buổi (timeOfDay).
// - Hôm nay: thẻ pastel cho thói quen đến hạn; mục "Đã xong" và "Đã bỏ qua" ở dưới (4.2).
// - Tuần: thẻ có 7 ô T2–CN chạm để đổi trạng thái (4.2).
// - Tổng thể: thẻ có lưới chấm 20 tuần (4.2).
// - Nút tròn "+" nổi góc dưới phải mở màn Tạo thói quen (4.1).
// 5.5 (feature 005): the map button in the app bar opens the full-screen sea map (/sea-map).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/habit_science.dart';
import '../data/models/goal.dart';
import '../data/models/habit.dart';
import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_logo.dart';
import '../widgets/edit_delete_menu.dart';
import '../widgets/empty_goal_view.dart';
import '../widgets/goal_habit_sheets.dart';
import '../widgets/habit_today_card.dart';
import '../widgets/habit_week_card.dart';

enum _HabitsView { today, week, overall }

enum _MenuAction { myHabits, addGoal, manageGoals }

/// Bộ lọc theo buổi; null là "Tất cả".
const Map<HabitTimeOfDay?, String> _timeFilters = {
  null: 'Tất cả',
  HabitTimeOfDay.morning: 'Sáng',
  HabitTimeOfDay.afternoon: 'Chiều',
  HabitTimeOfDay.evening: 'Tối',
};

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  _HabitsView _view = _HabitsView.today;
  HabitTimeOfDay? _filter;

  void _onMenu(_MenuAction action) {
    switch (action) {
      case _MenuAction.myHabits:
        context.push(AppRoutes.myHabits);
      case _MenuAction.addGoal:
        showGoalSheet(context, ref);
      case _MenuAction.manageGoals:
        showAppBottomSheet<void>(context, builder: (_) => const _GoalsSheet());
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsProvider);
    final habits = ref.watch(habitsProvider);
    final histories = ref.watch(habitHistoriesProvider);
    final filtered = [
      for (final habit in habits)
        if (_filter == null || habit.timeOfDay == _filter) habit,
    ];

    final Widget body;
    if (goals.isEmpty) {
      body = const EmptyGoalView();
    } else if (habits.isEmpty) {
      body = _EmptyState(
        emoji: '🌱',
        title: 'Chưa có thói quen nào',
        message: 'Bắt đầu với một việc thật nhỏ, ví dụ đọc 1 trang sách mỗi tối.',
        actionLabel: 'Tạo thói quen đầu tiên',
        onAction: () => context.push(AppRoutes.habitForm(goals.first.id)),
      );
    } else {
      body = Column(
        children: [
          _Header(
            view: _view,
            filter: _filter,
            onView: (view) => setState(() => _view = view),
            onFilter: (filter) => setState(() => _filter = filter),
          ),
          Expanded(
            child: switch (_view) {
              _HabitsView.today => _TodayView(
                habits: filtered,
                histories: histories,
                filter: _filter,
                onClearFilter: () => setState(() => _filter = null),
              ),
              _HabitsView.week || _HabitsView.overall =>
                filtered.isEmpty
                    ? _FilterEmpty(filter: _filter, onClear: () => setState(() => _filter = null))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.xxl * 2,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) => _view == _HabitsView.week
                            ? HabitWeekCard(
                                key: ValueKey('week_${filtered[i].id}'),
                                habit: filtered[i],
                                history: histories[filtered[i].id]!,
                              )
                            : HabitOverallCard(
                                key: ValueKey('overall_${filtered[i].id}'),
                                habit: filtered[i],
                                history: histories[filtered[i].id]!,
                              ),
                      ),
            },
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.all(AppSpacing.md - 2),
          child: AppLogo(size: 28),
        ),
        title: const Text('Thói quen'),
        actions: [
          // 5.5 The sea map, full screen (spec 005 FR-004).
          if (goals.isNotEmpty && habits.isNotEmpty)
            IconButton(
              icon: const Icon(AppIcons.map),
              tooltip: AppStrings.mapView,
              onPressed: () => context.push(AppRoutes.seaMap),
            ),
          PopupMenuButton<_MenuAction>(
            icon: const Icon(AppIcons.more),
            tooltip: 'Tuỳ chọn',
            onSelected: _onMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(value: _MenuAction.myHabits, child: Text('Thói quen của tôi')),
              PopupMenuItem(value: _MenuAction.addGoal, child: Text('Thêm mục tiêu')),
              PopupMenuItem(value: _MenuAction.manageGoals, child: Text('Quản lý mục tiêu')),
            ],
          ),
        ],
      ),
      body: body,
      floatingActionButton: goals.isEmpty
          ? null
          : FloatingActionButton(
              tooltip: 'Tạo thói quen',
              onPressed: () => context.push(AppRoutes.habitForm(goals.first.id)),
              child: const Icon(AppIcons.add),
            ),
    );
  }
}

/// 3 tab và hàng chip lọc theo buổi.
class _Header extends StatelessWidget {
  const _Header({
    required this.view,
    required this.filter,
    required this.onView,
    required this.onFilter,
  });

  final _HabitsView view;
  final HabitTimeOfDay? filter;
  final ValueChanged<_HabitsView> onView;
  final ValueChanged<HabitTimeOfDay?> onFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_HabitsView>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _HabitsView.today, label: Text(AppStrings.habitsByDay)),
                ButtonSegment(value: _HabitsView.week, label: Text('Tuần')),
                ButtonSegment(value: _HabitsView.overall, label: Text('Tổng thể')),
              ],
              selected: {view},
              onSelectionChanged: (selected) => onView(selected.first),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final entry in _timeFilters.entries) ...[
                  ChoiceChip(
                    label: Text(entry.value),
                    showCheckmark: false,
                    selected: filter == entry.key,
                    onSelected: (_) => onFilter(entry.key),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Hôm nay ----------

class _TodayView extends ConsumerWidget {
  const _TodayView({
    required this.habits,
    required this.histories,
    required this.filter,
    required this.onClearFilter,
  });

  final List<Habit> habits;
  final Map<String, HabitHistory> histories;
  final HabitTimeOfDay? filter;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final pending = <Habit>[];
    final done = <Habit>[];
    final skipped = <Habit>[];

    for (final habit in habits) {
      final history = histories[habit.id]!;
      final status = todayStatusOf(history, today);
      // Thói quen không đến hạn hôm nay vẫn hiện nếu hôm nay đã làm hoặc đã đánh dấu.
      if (status == TodayStatus.pending && !history.isDueOn(today)) continue;
      switch (status) {
        case TodayStatus.pending:
          pending.add(habit);
        case TodayStatus.done:
          done.add(habit);
        case TodayStatus.skipped:
          skipped.add(habit);
      }
    }

    if (pending.isEmpty && done.isEmpty && skipped.isEmpty) {
      return filter == null
          ? const _EmptyState(
              emoji: '🎉',
              title: 'Hôm nay không có thói quen nào đến hạn',
              message: 'Nghỉ ngơi một chút, hoặc bấm + để thêm việc mới.',
            )
          : _FilterEmpty(filter: filter, onClear: onClearFilter);
    }

    Widget cardOf(Habit habit, String section) => Padding(
      key: ValueKey('${section}_${habit.id}'),
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppearAnimation(
        child: HabitTodayCard(habit: habit, history: histories[habit.id]!),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxl * 2,
      ),
      children: [
        for (final habit in pending) cardOf(habit, 'pending'),
        if (pending.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: _AllDoneBanner(),
          ),
        if (done.isNotEmpty) ...[
          _SectionDivider(label: 'Đã xong (${done.length})'),
          for (final habit in done) cardOf(habit, 'done'),
        ],
        if (skipped.isNotEmpty) ...[
          _SectionDivider(label: 'Đã bỏ qua (${skipped.length})'),
          for (final habit in skipped) cardOf(habit, 'skipped'),
        ],
      ],
    );
  }
}

class _AllDoneBanner extends StatelessWidget {
  const _AllDoneBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Xong hết việc hôm nay rồi! 💪',
      textAlign: TextAlign.center,
      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.tertiary),
    );
  }
}

/// Dòng "Đã xong ———" ngăn các mục.
class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// ---------- Trạng thái trống ----------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: theme.textTheme.displayMedium),
            const SizedBox(height: AppSpacing.md),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bộ lọc theo buổi không có kết quả.
class _FilterEmpty extends StatelessWidget {
  const _FilterEmpty({required this.filter, required this.onClear});

  final HabitTimeOfDay? filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final part = _timeFilters[filter]!.toLowerCase();
    return _EmptyState(
      emoji: '🔍',
      title: 'Không có thói quen nào vào buổi $part',
      message: 'Khi tạo hoặc sửa thói quen, chọn "Làm vào" để xếp nó vào buổi $part.',
      actionLabel: 'Xem tất cả',
      onAction: onClear,
    );
  }
}

// ---------- Quản lý mục tiêu ----------

/// 4.1 Danh sách mục tiêu: tên, câu bản sắc, lý do và menu Sửa/Xoá.
class _GoalsSheet extends ConsumerWidget {
  const _GoalsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final goals = ref.watch(goalsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Mục tiêu', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        if (goals.isEmpty) Text('Chưa có mục tiêu nào.', style: theme.textTheme.bodyMedium),
        for (final goal in goals) _GoalTile(key: ValueKey(goal.id), goal: goal),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          icon: const Icon(AppIcons.add),
          label: const Text('Thêm mục tiêu'),
          onPressed: () => showGoalSheet(context, ref),
        ),
      ],
    );
  }
}

class _GoalTile extends ConsumerWidget {
  const _GoalTile({required this.goal, super.key});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Icon(AppIcons.goal, color: theme.colorScheme.tertiary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title, style: theme.textTheme.titleMedium),
                  if (goal.identity.isNotEmpty)
                    Text(
                      'Tôi là người ${goal.identity}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
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
      ),
    );
  }
}
