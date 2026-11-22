// 5.1 Khung chính.
// Bottom bar with three tabs: Hôm nay / Thói quen / Tiến độ (ADR-0002). While a session runs, the
// running-session banner sits just above the bar (spec 001 FR-008). The level-up dialog is parked
// (ADR-0004).
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/running_session_banner.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RunningSessionBanner(),
          DecoratedBox(
            // Đường kẻ mảnh phân tách thanh tab với nội dung.
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(
                index,
                // Bấm lại tab đang mở thì quay về đầu tab đó.
                initialLocation: index == navigationShell.currentIndex,
              ),
              destinations: const [
                NavigationDestination(icon: Icon(AppIcons.home), label: AppStrings.tabToday),
                NavigationDestination(icon: Icon(AppIcons.habits), label: AppStrings.tabHabits),
                NavigationDestination(icon: Icon(AppIcons.stats), label: AppStrings.tabProgress),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
