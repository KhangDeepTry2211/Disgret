// 5.1 Điều hướng bằng go_router.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/reel.dart';
import '../providers/app_providers.dart';
import '../providers/focus_session_provider.dart';
import '../screens/blocked_apps_screen.dart';
import '../screens/focus_screen.dart';
import '../screens/habits_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_shell.dart';
import '../screens/onboarding_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/reels_screen.dart';
import '../screens/reset_break_permissions_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/summary_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String reels = '/reels';
  static const String focus = '/focus';
  static const String habits = '/habits';
  static const String summary = '/summary';
  static const String settings = '/settings';
  static const String quiz = '/quiz';
  static const String resetBreakPermissions = '/reset-break-permissions';
  static const String blockedApps = '/blocked-apps';
  static const String stats = '/stats';

  /// 1.4 Mở Reels với ngữ cảnh cho trước; không có tham số thì mặc định là "start".
  static String reelsFor(String reelContext) => '$reels?context=$reelContext';

  /// Mở Focus với số phút cho trước.
  static String focusFor(int minutes) => '$focus?minutes=$minutes';
}

/// Navigator gốc, để phản hồi nhắc (3.3) hiện được dù người dùng đang ở màn nào.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final profile = ref.read(profileRepositoryProvider);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    // Đường dẫn không tồn tại (chỉ gặp trên web) thì đưa về Trang chủ.
    onException: (context, state, router) => router.go(AppRoutes.home),
    // Lần đầu mở app thì vào onboarding, các lần sau vào thẳng home.
    redirect: (context, state) {
      final atOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (!profile.isOnboardingDone && !atOnboarding) return AppRoutes.onboarding;
      if (profile.isOnboardingDone && atOnboarding) return AppRoutes.home;
      // Màn Tổng kết chỉ có nghĩa khi vừa có phiên học kết thúc.
      final hasFinishedSession = ref.read(focusSessionProvider).phase == FocusPhase.finished;
      if (state.matchedLocation == AppRoutes.summary && !hasFinishedSession) return AppRoutes.home;
      // Reset break chỉ có trên Android; trên web gõ thẳng đường dẫn thì về Trang chủ.
      final isResetBreakRoute =
          state.matchedLocation == AppRoutes.resetBreakPermissions ||
          state.matchedLocation == AppRoutes.blockedApps;
      if (isResetBreakRoute && !ref.read(nativeBridgeProvider).isSupported) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.onboarding, builder: (context, state) => const OnboardingScreen()),
      // 4 tab dưới cùng. Mỗi tab tự giữ trạng thái khi chuyển qua lại.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reels,
                builder: (context, state) => ReelsScreen(
                  reelContext: state.uri.queryParameters['context'] ?? ReelContext.start,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.focus,
                builder: (context, state) => FocusScreen(
                  startMinutes: int.tryParse(state.uri.queryParameters['minutes'] ?? ''),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.habits, builder: (context, state) => const HabitsScreen()),
            ],
          ),
        ],
      ),
      // Các màn này nằm ngoài tab nên chiếm toàn màn hình.
      GoRoute(path: AppRoutes.summary, builder: (context, state) => const SummaryScreen()),
      GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
      GoRoute(path: AppRoutes.quiz, builder: (context, state) => const QuizScreen()),
      GoRoute(
        path: AppRoutes.resetBreakPermissions,
        builder: (context, state) => const ResetBreakPermissionsScreen(),
      ),
      GoRoute(path: AppRoutes.blockedApps, builder: (context, state) => const BlockedAppsScreen()),
      GoRoute(path: AppRoutes.stats, builder: (context, state) => const StatsScreen()),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
