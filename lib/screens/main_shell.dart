// 5.1 Khung chính: thanh điều hướng dưới cùng với 4 tab.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/focus_session_provider.dart';
import '../theme/app_theme.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const int _reelsTab = 1;

  @override
  void initState() {
    super.initState();
    _syncReelsTabWithSession();
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex != oldWidget.navigationShell.currentIndex) {
      _syncReelsTabWithSession();
    }
  }

  /// 3.3 Đang ở tab Reels thì đồng hồ của phiên dừng, rời tab thì chạy tiếp.
  /// Riverpod không cho đổi trạng thái khi đang dựng giao diện nên chờ khung hình xong.
  void _syncReelsTabWithSession() {
    final isOnReels = widget.navigationShell.currentIndex == _reelsTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(focusSessionProvider.notifier).setWatchingReels(isOnReels);
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        // Đường kẻ mảnh phân tách thanh tab với nội dung.
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            // Bấm lại tab đang mở thì quay về đầu tab đó.
            // Tab Reels luôn về đường dẫn mặc định, tức ngữ cảnh "start".
            initialLocation: index == navigationShell.currentIndex || index == _reelsTab,
          ),
          destinations: const [
            NavigationDestination(icon: Icon(AppIcons.home), label: 'Trang chủ'),
            NavigationDestination(icon: Icon(AppIcons.reels), label: 'Reels'),
            NavigationDestination(icon: Icon(AppIcons.focus), label: 'Focus'),
            NavigationDestination(icon: Icon(AppIcons.habits), label: 'Thói quen'),
          ],
        ),
      ),
    );
  }
}
