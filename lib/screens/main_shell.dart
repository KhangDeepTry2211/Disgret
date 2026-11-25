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
    final theme = Theme.of(context);

    // 5.1 (spec 010): the tab bar floats over the content, inset from the edges with rounded
    // corners; the body runs behind it and screens pad their last controls by
    // MediaQuery.paddingOf(context).bottom.
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(borderRadius: AppRadius.cardBorder, child: const RunningSessionBanner()),
              const SizedBox(height: AppSpacing.xs),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: AppRadius.pillBorder,
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.pillBorder,
                  child: NavigationBar(
                    height: AppShell.tabBarHeight,
                    backgroundColor: AppColors.transparent,
                    elevation: 0,
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: (index) => navigationShell.goBranch(
                      index,
                      // Bấm lại tab đang mở thì quay về đầu tab đó.
                      initialLocation: index == navigationShell.currentIndex,
                    ),
                    destinations: const [
                      NavigationDestination(icon: Icon(AppIcons.home), label: AppStrings.tabToday),
                      NavigationDestination(
                        icon: Icon(AppIcons.habits),
                        label: AppStrings.tabHabits,
                      ),
                      NavigationDestination(
                        icon: Icon(AppIcons.stats),
                        label: AppStrings.tabProgress,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
