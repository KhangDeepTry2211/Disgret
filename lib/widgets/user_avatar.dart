// F3 Avatar người dùng: chữ cái đầu của tên trên nền màu chính; khách dùng thử thì avatar xám.
// ProfileAvatarButton là bản nhỏ trên AppBar Trang chủ, có chấm đám mây báo trạng thái đồng bộ.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/account_providers.dart';
import '../router/app_router.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({required this.username, required this.size, super.key});

  /// null = khách dùng thử.
  final String? username;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = username;
    final isGuest = name == null || name.isEmpty;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: isGuest ? scheme.surfaceContainerHighest : scheme.primary,
      child: isGuest
          ? Icon(AppIcons.guest, size: size * 0.55, color: scheme.onSurfaceVariant)
          : Text(
              name.characters.first.toUpperCase(),
              style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimary,
              ),
            ),
    );
  }
}

/// Icon đám mây và màu theo trạng thái đồng bộ, dùng chung cho AppBar và Hồ sơ.
(IconData, Color) syncIconOf(SyncStatus status, ColorScheme scheme) => switch (status) {
  SyncStatus.synced => (AppIcons.synced, scheme.tertiary),
  SyncStatus.syncing => (AppIcons.syncing, scheme.secondary),
  SyncStatus.offline => (AppIcons.offline, scheme.onSurfaceVariant),
  SyncStatus.error => (AppIcons.syncError, scheme.error),
};

String syncLabelOf(SyncStatus status) => switch (status) {
  SyncStatus.synced => 'Đã đồng bộ',
  SyncStatus.syncing => 'Đang đồng bộ…',
  SyncStatus.offline => 'Offline, sẽ đồng bộ khi có mạng',
  SyncStatus.error => 'Lỗi đồng bộ',
};

class ProfileAvatarButton extends ConsumerWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final username = ref.watch(currentUsernameProvider);
    final status = ref.watch(syncStatusProvider.select((state) => state.status));
    final (icon, color) = syncIconOf(status, scheme);

    return IconButton(
      tooltip: 'Hồ sơ',
      onPressed: () => context.push(AppRoutes.profile),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          UserAvatar(username: username, size: AppAuth.avatarSmall),
          // Khách dùng thử không có đồng bộ nên không hiện đám mây.
          if (username != null)
            Positioned(
              right: -AppSpacing.xs,
              bottom: -AppSpacing.xs,
              child: Container(
                decoration: BoxDecoration(color: scheme.surface, shape: BoxShape.circle),
                padding: const EdgeInsets.all(1),
                child: Icon(icon, size: AppAuth.syncBadge, color: color),
              ),
            ),
        ],
      ),
    );
  }
}
