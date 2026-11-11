// 2.1 Danh sách app – màn "Ứng dụng cần nhắc", mở từ Cài đặt.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/app_providers.dart';
import '../services/native_bridge.dart';
import '../theme/app_theme.dart';

class BlockedAppsScreen extends ConsumerStatefulWidget {
  const BlockedAppsScreen({super.key});

  @override
  ConsumerState<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class _BlockedAppsScreenState extends ConsumerState<BlockedAppsScreen> {
  /// Chỉ sắp xếp một lần lúc mở màn: nếu xếp lại ngay khi bật công tắc,
  /// dòng vừa bấm sẽ nhảy đi chỗ khác dưới tay người dùng.
  List<InstalledApp>? _sortedApps;

  List<InstalledApp> _sortOnce(List<InstalledApp> apps) {
    return _sortedApps ??= _blockedFirst(apps, ref.read(blockedAppsProvider));
  }

  /// App đang chặn xếp lên đầu, trong mỗi nhóm xếp theo tên.
  static List<InstalledApp> _blockedFirst(List<InstalledApp> apps, Set<String> blocked) {
    return [...apps]..sort((a, b) {
      final aBlocked = blocked.contains(a.packageName);
      final bBlocked = blocked.contains(b.packageName);
      if (aBlocked != bBlocked) return aBlocked ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(installedAppsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ứng dụng cần nhắc')),
      body: switch (apps) {
        AsyncData(:final value) when value.isNotEmpty => _AppList(apps: _sortOnce(value)),
        AsyncData() => const _Message('Không tìm thấy ứng dụng nào trên máy để nhắc.'),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        _ => const _Message('Không đọc được danh sách ứng dụng. Hãy thoát ra rồi mở lại màn này.'),
      },
    );
  }
}

class _AppList extends ConsumerWidget {
  const _AppList({required this.apps});

  final List<InstalledApp> apps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final blocked = ref.watch(blockedAppsProvider);

    return ListView.builder(
      itemCount: apps.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'DisGret sẽ nhắc bạn khi mở các ứng dụng đang bật, chỉ trong lúc có phiên học.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final app = apps[index - 1];
        return SwitchListTile(
          secondary: Image.memory(app.icon, width: 40, height: 40, gaplessPlayback: true),
          title: Text(app.name),
          value: blocked.contains(app.packageName),
          onChanged: (value) =>
              ref.read(blockedAppsProvider.notifier).setBlocked(app.packageName, blocked: value),
        );
      },
    );
  }
}

/// Thông báo ở giữa màn khi không có gì để hiện.
class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
