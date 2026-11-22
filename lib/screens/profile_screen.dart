// F3 Trang Hồ sơ kiểu TikTok, mở từ avatar trên AppBar Trang chủ (/profile).
// Đã đăng nhập: avatar chữ cái, @tên, ngày tham gia, 3 số liệu, thẻ trạng thái đồng bộ, Cài đặt,
// Đăng xuất. Dùng thử: avatar xám, "Bạn đang dùng thử", thẻ kêu gọi tạo tài khoản.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/habit_science.dart';
import '../providers/account_providers.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/user_avatar.dart';

String _two(int value) => value.toString().padLeft(2, '0');

String _date(DateTime time) => '${_two(time.day)}/${_two(time.month)}/${time.year}';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Đăng xuất?',
      message: 'Dữ liệu trên máy này sẽ được xoá, dữ liệu vẫn còn trong tài khoản.',
      confirmLabel: 'Đăng xuất',
    );
    if (!confirmed) return;
    await ref.read(accountActionsProvider).signOut();
    if (context.mounted) context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final joined = user?.createdAt?.toLocal();

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Hồ sơ')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: UserAvatar(username: user?.username, size: AppAuth.avatarLarge),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            user == null ? 'Bạn đang dùng thử' : '@${user.username}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          if (joined != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tham gia ngày ${_date(joined)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _StatsRow(),
          const SizedBox(height: AppSpacing.lg),
          if (user == null) const _GuestCallToAction() else const _SyncCard(),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(AppIcons.settings),
                  title: const Text('Cài đặt'),
                  trailing: const Icon(AppIcons.chevron),
                  onTap: () => context.push(AppRoutes.settings),
                ),
                if (user != null) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(AppIcons.logout),
                    iconColor: theme.colorScheme.error,
                    textColor: theme.colorScheme.error,
                    title: const Text('Đăng xuất'),
                    onTap: () => _signOut(context, ref),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 3 số liệu kiểu TikTok: Streak dài nhất · Phiên tập trung · Thói quen.
class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final longest = ref.watch(allHabitHistoriesProvider).fold(0, (best, history) {
      final streak = HabitScience.longestStreak(history, today);
      return streak > best ? streak : best;
    });
    // Phiên học được ghi thẳng xuống Hive khi kết thúc; mở lại Hồ sơ là có số mới.
    ref.watch(habitLogsProvider);
    final sessions = ref.read(sessionRepositoryProvider).getAll().length;
    final habits = ref.watch(habitsProvider).length;

    return Row(
      children: [
        Expanded(
          child: _Stat(value: '$longest', label: 'Streak dài nhất'),
        ),
        Expanded(
          child: _Stat(value: '$sessions', label: 'Phiên tập trung'),
        ),
        Expanded(
          child: _Stat(value: '$habits', label: 'Thói quen'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(value, style: theme.textTheme.titleLarge),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Thẻ trạng thái đồng bộ + nút "Đồng bộ ngay".
class _SyncCard extends ConsumerStatefulWidget {
  const _SyncCard();

  @override
  ConsumerState<_SyncCard> createState() => _SyncCardState();
}

class _SyncCardState extends ConsumerState<_SyncCard> {
  bool _busy = false;

  Future<void> _syncNow() async {
    setState(() => _busy = true);
    await ref.read(accountActionsProvider).syncNow();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sync = ref.watch(syncStatusProvider);
    final (icon, color) = syncIconOf(sync.status, theme.colorScheme);
    final last = sync.lastSyncedAt?.toLocal();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(syncLabelOf(sync.status), style: theme.textTheme.titleMedium)),
              ],
            ),
            if (last != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Gần nhất: ${_two(last.hour)}:${_two(last.minute)} ${_date(last)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (sync.status == SyncStatus.error && sync.error != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                sync.error!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _busy || sync.status == SyncStatus.syncing ? null : _syncNow,
              icon: const Icon(AppIcons.syncNow),
              label: const Text('Đồng bộ ngay'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Khách dùng thử: kêu gọi tạo tài khoản.
class _GuestCallToAction extends ConsumerWidget {
  const _GuestCallToAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ready = ref.watch(firebaseReadyProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tạo tài khoản để lưu dữ liệu và dùng trên nhiều thiết bị',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              ready
                  ? 'Dữ liệu bạn đang có trên máy này sẽ được gộp vào tài khoản.'
                  : '${AuthRules.noServer}. Hãy thử lại khi có mạng.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ready ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: ready ? () => context.push(AppRoutes.signup) : null,
              child: const Text('Tạo tài khoản'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: ready ? () => context.push(AppRoutes.login) : null,
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
