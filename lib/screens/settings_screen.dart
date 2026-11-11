// 5.1 Màn Cài đặt: xem hồ sơ, lối vào Thống kê (8.2), Reset break (7.1, 2.1, 2.3)
// và quản lý dữ liệu.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/user_profile.dart';
import '../providers/app_providers.dart';
import '../providers/focus_session_provider.dart';
import '../router/app_router.dart';
import '../services/focus_session_timer.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Tên app hiện trên màn can thiệp khi bấm thử.
  static const String _demoAppName = 'TikTok';

  Future<void> _createDemoData(BuildContext context, WidgetRef ref) async {
    await ref.read(appDataActionsProvider).createDemoData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo dữ liệu mẫu')));
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(appDataActionsProvider);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xoá toàn bộ dữ liệu?',
      message:
          'Mục tiêu, thói quen, lịch sử ghi nhận và hồ sơ của bạn sẽ bị xoá, '
          'app quay về như mới cài. Không thể hoàn tác.',
      confirmLabel: 'Xoá hết',
    );
    if (!confirmed) return;

    await actions.clearAll();
    ref.invalidate(focusSessionProvider); // Phiên đang chạy (nếu có) cũng bị huỷ.
    if (!context.mounted) return;
    context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider);
    final native = ref.read(nativeBridgeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Động lực của bạn', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final type in profile?.motivationTypes ?? const [])
                Chip(label: Text(type.label)),
            ],
          ),
          // 1.1 Làm lại quiz để đổi hồ sơ động lực.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(AppIcons.replay),
              label: const Text('Làm lại quiz động lực'),
              onPressed: () => context.push(AppRoutes.quiz),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Độ dài reel ưa thích: '
            '${profile?.preferredReelLength ?? UserProfile.defaultReelLength} giây',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          // 8.2 Số liệu để kiểm chứng giả thuyết trong báo cáo.
          Card(
            child: ListTile(
              leading: const Icon(AppIcons.stats),
              title: const Text('Thống kê'),
              subtitle: const Text('Phút tập trung, Reset break, reels và thời gian quay lại'),
              onTap: () => context.push(AppRoutes.stats),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (native.isSupported) ...[
            Text('Reset break', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(AppIcons.permissions),
                    title: const Text('Quyền cho Reset break'),
                    onTap: () => context.push(AppRoutes.resetBreakPermissions),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(AppIcons.blocked),
                    title: const Text('Ứng dụng cần nhắc'),
                    onTap: () => context.push(AppRoutes.blockedApps),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(AppIcons.intervention),
                    title: const Text('Thử màn can thiệp'),
                    subtitle: const Text('Mở ngay màn nhắc để xem thử'),
                    onTap: () => native.showIntervention(_demoAppName),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text('Dữ liệu', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                // 3.1 Chế độ demo để test và trình bày nhanh.
                SwitchListTile(
                  secondary: const Icon(AppIcons.focus),
                  title: const Text('Chế độ demo'),
                  subtitle: const Text(
                    '1 phút của phiên học và giờ nghỉ chỉ dài '
                    '${FocusSessionTimer.demoSecondsPerMinute} giây',
                  ),
                  value: profile?.demoMode ?? false,
                  onChanged: (enabled) => ref.read(profileProvider.notifier).setDemoMode(enabled),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(AppIcons.replay),
                  title: const Text('Xem lại màn giới thiệu'),
                  onTap: () async {
                    await ref.read(profileRepositoryProvider).resetOnboarding();
                    if (!context.mounted) return;
                    context.go(AppRoutes.onboarding);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(AppIcons.demoData),
                  title: const Text('Tạo dữ liệu mẫu'),
                  subtitle: const Text(
                    '1 mục tiêu, 2 thói quen, lịch sử 5 ngày, phiên học và sự kiện cho Thống kê',
                  ),
                  onTap: () => _createDemoData(context, ref),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(AppIcons.deleteAll),
                  iconColor: theme.colorScheme.error,
                  textColor: theme.colorScheme.error,
                  title: const Text('Xoá toàn bộ dữ liệu'),
                  onTap: () => _clearAllData(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
