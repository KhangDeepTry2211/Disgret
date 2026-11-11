// 5.1 Màn Trang chủ: vòng streak, mục tiêu hôm nay, thói quen hôm nay và nút "Bắt đầu".
// Toàn bộ lấy từ dữ liệu thật; chưa có mục tiêu thì hiện màn trống.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/goal.dart';
import '../data/models/habit.dart';
import '../data/models/reel.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/empty_goal_view.dart';
import '../widgets/goal_habit_sheets.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/habit_tile.dart';
import '../widgets/streak_ring.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(todayGoalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppLogo(size: 32),
            SizedBox(width: AppSpacing.sm),
            Text('DisGret'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.settings),
            tooltip: 'Cài đặt',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: goal == null ? const EmptyGoalView() : _TodayView(goal: goal),
    );
  }
}

class _TodayView extends ConsumerWidget {
  const _TodayView({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final streak = ref.watch(overallStreakProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Center(child: StreakRing(days: streak, size: 144)),
              const SizedBox(height: AppSpacing.lg),
              _TodayGoalCard(goal: goal),
              const SizedBox(height: AppSpacing.md),
              _TodayHabitsCard(goal: goal, habits: habits),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          child: SizedBox(
            width: double.infinity,
            child: GradientPillButton(
              label: 'Bắt đầu',
              // Theo vòng chính: xem 1–3 reel lấy động lực rồi mới vào học.
              onPressed: () => context.go(AppRoutes.reelsFor(ReelContext.start)),
            ),
          ),
        ),
        TextButton(
          onPressed: () => context.go(AppRoutes.focus),
          child: const Text('Bỏ qua, vào học luôn'),
        ),
      ],
    );
  }
}

class _TodayGoalCard extends StatelessWidget {
  const _TodayGoalCard({required this.goal});

  final Goal goal;

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
                Icon(AppIcons.goal, size: 20, color: secondaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Mục tiêu hôm nay',
                  style: theme.textTheme.labelLarge?.copyWith(color: secondaryColor),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(goal.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(goal.reason, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TodayHabitsCard extends ConsumerWidget {
  const _TodayHabitsCard({required this.goal, required this.habits});

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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              'Thói quen hôm nay',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (habits.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chưa có thói quen nào.', style: theme.textTheme.bodyMedium),
                  TextButton.icon(
                    icon: const Icon(AppIcons.add),
                    label: const Text('Thêm thói quen'),
                    onPressed: () => showHabitSheet(context, ref, goalId: goal.id),
                  ),
                ],
              ),
            ),
          for (var i = 0; i < habits.length; i++) ...[
            if (i > 0) const Divider(),
            HabitTile(key: ValueKey(habits[i].id), habit: habits[i]),
          ],
        ],
      ),
    );
  }
}
