// 4.1 Màn "Thói quen của tôi" (bố cục theo design/habit_kit/ ảnh 17), mở từ menu tab Thói quen:
// 2 tab Thói quen / Việc một lần; mỗi thói quen là một thẻ màu pastel có tay kéo bên phải để
// sắp xếp lại. Thứ tự mới được lưu vào sortOrder (HabitsNotifier.reorderWithinType).
// Chạm thẻ để mở màn chi tiết.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/habit_schedule.dart';
import '../data/models/habit.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_icon_view.dart';

class MyHabitsScreen extends ConsumerStatefulWidget {
  const MyHabitsScreen({super.key});

  @override
  ConsumerState<MyHabitsScreen> createState() => _MyHabitsScreenState();
}

class _MyHabitsScreenState extends ConsumerState<MyHabitsScreen> {
  HabitType _type = HabitType.regular;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habits = ref.watch(habitsProvider).where((habit) => habit.type == _type).toList();

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Thói quen của tôi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<HabitType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: HabitType.regular, label: Text('Thói quen')),
                  ButtonSegment(value: HabitType.oneTime, label: Text('Việc một lần')),
                ],
                selected: {_type},
                onSelectionChanged: (selected) => setState(() => _type = selected.first),
              ),
            ),
          ),
          if (habits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Giữ và kéo biểu tượng ⋮⋮ để sắp xếp lại.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: habits.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        _type == HabitType.regular
                            ? 'Chưa có thói quen nào.'
                            : 'Chưa có việc một lần nào.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    buildDefaultDragHandles: false,
                    itemCount: habits.length,
                    // onReorderItem đã tự trừ đi chỗ của phần tử vừa gỡ ra khỏi newIndex.
                    onReorderItem: (oldIndex, newIndex) => ref
                        .read(habitsProvider.notifier)
                        .reorderWithinType(_type, oldIndex, newIndex),
                    itemBuilder: (context, index) => Padding(
                      key: ValueKey(habits[index].id),
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _HabitRow(habit: habits[index], index: index),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.habit, required this.index});

  final Habit habit;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppHabitColors.of(habit.colorIndex);

    return Material(
      color: color.background,
      borderRadius: AppRadius.cardBorder,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.habitDetail(habit.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md - 2,
            AppSpacing.xs,
            AppSpacing.md - 2,
          ),
          child: Row(
            children: [
              HabitIconView(icon: habit.icon, size: AppHabit.todayIcon, color: color.foreground),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(color: color.foreground),
                    ),
                    Text(
                      HabitSchedule.describe(habit),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color.foreground.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Semantics(
                  container: true,
                  label: 'Kéo để sắp xếp ${habit.name}',
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Icon(AppIcons.dragHandle, color: color.foreground),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
