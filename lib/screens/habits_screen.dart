// 5.1 Màn Thói quen.
// 4.1 Đặt mục tiêu: thêm, sửa, xoá mục tiêu và thói quen bằng bottom sheet.
// 4.2 Ghi nhận: tick "Hôm nay đã làm" ngay trên từng thói quen.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/goal.dart';
import '../data/models/habit.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/edit_delete_menu.dart';
import '../widgets/empty_goal_view.dart';
import '../widgets/goal_habit_sheets.dart';
import '../widgets/habit_tile.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final habits = ref.watch(habitsProvider);

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
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final goal in goals) ...[
                  _GoalCard(
                    key: ValueKey(goal.id),
                    goal: goal,
                    habits: habits.where((habit) => habit.goalId == goal.id).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal, required this.habits, super.key});

  final Goal goal;
  final List<Habit> habits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, 0, AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.title, style: theme.textTheme.titleMedium),
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
            ),
          ),
          const Divider(),
          for (final habit in habits) ...[
            HabitTile(key: ValueKey(habit.id), habit: habit, showMenu: true),
            const Divider(),
          ],
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: TextButton.icon(
              icon: const Icon(AppIcons.add),
              label: const Text('Thêm thói quen'),
              onPressed: () => showHabitSheet(context, ref, goalId: goal.id),
            ),
          ),
        ],
      ),
    );
  }
}
