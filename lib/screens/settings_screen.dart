// 5.1 Màn Cài đặt: xem hồ sơ, lối vào Thống kê (8.2), Reset break (7.1, 2.1, 2.3)
// và quản lý dữ liệu.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/user_profile.dart';
import '../l10n/app_strings.dart';
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

  /// 5.1 Edits the name in a small dialog; "Hủy" keeps it as it was.
  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: current),
    );
    if (name != null) await ref.read(profileProvider.notifier).setDisplayName(name);
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
          // 5.1 Tên gọi (spec 007): only for the greeting on Hôm nay.
          Card(
            child: ListTile(
              leading: const Icon(AppIcons.name),
              title: const Text(AppStrings.nameLabel),
              subtitle: Text(
                (profile?.displayName ?? '').isEmpty ? AppStrings.nameNotSet : profile!.displayName,
              ),
              onTap: () => _editName(context, ref, profile?.displayName ?? ''),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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

/// 5.1 Tên gọi (spec 007): returns the typed name on "Lưu", null on "Hủy". Owns its text controller
/// so it lives as long as the dialog, closing animation included.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.nameLabel),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: UserProfile.maxNameLength,
        decoration: const InputDecoration(
          hintText: AppStrings.nameHint,
          helperText: AppStrings.namePrivacy,
          helperMaxLines: 2,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
