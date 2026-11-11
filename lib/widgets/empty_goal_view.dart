// 4.1 Đặt mục tiêu – màn trống khi chưa có mục tiêu, dùng ở Trang chủ và Thói quen.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'goal_habit_sheets.dart';

class EmptyGoalView extends ConsumerWidget {
  const EmptyGoalView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.goal, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chưa có mục tiêu nào',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Đặt một mục tiêu nhỏ để bắt đầu. Mỗi ngày chỉ cần tiến thêm một chút.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => showGoalSheet(context, ref),
              child: const Text('Tạo mục tiêu đầu tiên'),
            ),
          ],
        ),
      ),
    );
  }
}
