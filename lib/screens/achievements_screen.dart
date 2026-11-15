// 4.2 Màn Thành tích (ảnh 19 chỉ tham khảo bố cục lưới): 9 cấp theo TỔNG số lần hoàn thành
// của mọi thói quen (10, 30, 66, 100, 200, 365, 500, 750, 1000 lần, xem achievements.dart).
// Huy hiệu tự vẽ (level_badge.dart); cấp chưa đạt thì xám, có ổ khoá.
// Tách riêng với 4 huy hiệu Hành trình 66 ngày trong màn chi tiết từng thói quen.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/achievements.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_progress_bar.dart';
import '../widgets/level_badge.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final total = ref.watch(completionTotalProvider);
    final level = Achievements.levelFor(total);
    final next = Achievements.nextTarget(total);

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Thành tích')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  LevelBadge(level: level == 0 ? 1 : level, unlocked: level > 0),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level == 0 ? 'Chưa có cấp nào' : 'Cấp $level',
                          style: theme.textTheme.titleLarge,
                        ),
                        Text('$total lần hoàn thành thói quen', style: theme.textTheme.bodySmall),
                        const SizedBox(height: AppSpacing.sm),
                        GradientProgressBar(value: Achievements.progressToNext(total), height: 6),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          next == null
                              ? 'Bạn đã đạt cấp cao nhất!'
                              : 'Còn ${next - total} lần nữa tới Cấp ${level + 1}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              // Wrap chứ không dùng GridView: ô tự cao theo chữ, không bị tràn khi chữ
              // xuống 2 dòng trên màn hình hẹp hoặc khi người dùng phóng to cỡ chữ.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellWidth = (constraints.maxWidth - 2 * AppSpacing.sm) / 3;
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (var i = 0; i < Achievements.levels.length; i++)
                        SizedBox(
                          width: cellWidth,
                          child: _LevelCell(
                            level: i + 1,
                            target: Achievements.levels[i],
                            total: total,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mỗi thói quen mỗi ngày làm xong được tính 1 lần, cộng dồn mọi thói quen. '
            'Khác với 4 huy hiệu "Hành trình 66 ngày" trong màn chi tiết của từng thói quen.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LevelCell extends StatelessWidget {
  const _LevelCell({required this.level, required this.target, required this.total});

  final int level;
  final int target;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = total >= target;

    return Semantics(
      container: true,
      label: 'Cấp $level, $target lần, ${unlocked ? 'đã đạt' : 'chưa đạt'}',
      excludeSemantics: true,
      child: Column(
        children: [
          LevelBadge(level: level, unlocked: unlocked),
          const SizedBox(height: AppSpacing.sm),
          Text('Cấp $level', style: theme.textTheme.titleSmall),
          Text(
            unlocked ? 'Đã đạt · $target lần' : 'Còn ${target - total} lần',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
