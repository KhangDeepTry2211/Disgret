// 7.1 Quyền truy cập – màn "Quyền cho Reset break", mở từ Cài đặt.
// Người dùng cấp quyền trong Cài đặt của máy nên phải kiểm tra lại mỗi khi họ quay về app.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/app_providers.dart';
import '../services/native_bridge.dart';
import '../theme/app_theme.dart';

class ResetBreakPermissionsScreen extends ConsumerStatefulWidget {
  const ResetBreakPermissionsScreen({super.key});

  @override
  ConsumerState<ResetBreakPermissionsScreen> createState() => _ResetBreakPermissionsScreenState();
}

class _ResetBreakPermissionsScreenState extends ConsumerState<ResetBreakPermissionsScreen> {
  late final AppLifecycleListener _lifecycleListener;
  GuardPermissions? _permissions;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _refresh);
    _refresh();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final permissions = await ref.read(nativeBridgeProvider).checkPermissions();
    if (mounted) setState(() => _permissions = permissions);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final native = ref.read(nativeBridgeProvider);
    final permissions = _permissions;

    return Scaffold(
      appBar: AppBar(title: const Text('Quyền cho Reset break')),
      body: permissions == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  'Các quyền này chỉ được dùng trong lúc bạn đang học, '
                  'không có dữ liệu nào được gửi đi.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _PermissionCard(
                  title: 'Biết app đang mở',
                  reason: 'Để biết khi nào bạn mở TikTok',
                  granted: permissions.usageAccess,
                  onEnable: native.openUsageAccessSettings,
                ),
                const SizedBox(height: AppSpacing.sm),
                _PermissionCard(
                  title: 'Hiện trên app khác',
                  reason: 'Để hiện màn nhắc đè lên app khác',
                  granted: permissions.overlay,
                  onEnable: native.openOverlaySettings,
                ),
                const SizedBox(height: AppSpacing.sm),
                _PermissionCard(
                  title: 'Gửi thông báo',
                  reason: 'Để nhắc khi hết giờ nghỉ',
                  granted: permissions.notification,
                  onEnable: native.requestNotificationPermission,
                ),
              ],
            ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.title,
    required this.reason,
    required this.granted,
    required this.onEnable,
  });

  final String title;
  final String reason;
  final bool granted;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              granted ? AppIcons.check : AppIcons.missing,
              color: granted ? theme.colorScheme.secondary : theme.colorScheme.error,
              semanticLabel: granted ? 'Đã bật' : 'Chưa bật',
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  Text(reason, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (!granted) ...[
              const SizedBox(width: AppSpacing.sm),
              FilledButton(onPressed: onEnable, child: const Text('Bật')),
            ],
          ],
        ),
      ),
    );
  }
}
