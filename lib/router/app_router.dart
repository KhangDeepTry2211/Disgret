// 5.1 Điều hướng bằng go_router.
// Three tabs (Hôm nay / Thói quen / Tiến độ); motivation, focus session and summary are full
// screen (ADR-0002, specs/001-today-single-study-entry/contracts/navigation.md).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/reel.dart';
import '../providers/app_providers.dart';
import '../providers/focus_session_provider.dart';
import '../screens/blocked_apps_screen.dart';
import '../screens/focus_screen.dart';
import '../screens/habit_detail_screen.dart';
import '../screens/habit_form_screen.dart';
import '../screens/habits_screen.dart';
import '../screens/my_habits_screen.dart';
import '../screens/main_shell.dart';
import '../screens/gret_corner_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/sea_map_screen.dart';
import '../screens/motivation_screen.dart';
import '../screens/reset_break_permissions_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/summary_screen.dart';
import '../screens/today_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/onboarding';

  // 3 tabs (contracts/navigation.md).
  static const String today = '/today';
  static const String habits = '/habits';
  static const String progress = '/progress';

  // Full-screen routes, no tab bar.
  static const String motivation = '/motivation';
  static const String focus = '/focus';
  static const String summary = '/summary';

  static const String settings = '/settings';
  static const String quiz = '/quiz';
  static const String resetBreakPermissions = '/reset-break-permissions';
  static const String blockedApps = '/blocked-apps';
  static const String habitDetailPath = '/habit/:id';
  static const String habitFormPath = '/habit-form';
  static const String myHabits = '/my-habits';

  /// 5.4 Góc của Gret: wardrobe, seas and mascots (spec 004).
  static const String gretCorner = '/gret-corner';

  /// 5.5 Bản đồ biển, full screen (spec 005).
  static const String seaMap = '/sea-map';

  /// 1.4 Motivation step with a context: "start" (before a session) or "distracted" (after one).
  static String motivationFor(String reelContext) => '$motivation?context=$reelContext';

  /// 4.2 Màn chi tiết một thói quen.
  static String habitDetail(String habitId) => '/habit/$habitId';

  /// 4.1 Tạo thói quen mới trong mục tiêu [goalId], hoặc sửa nếu có [habitId].
  static String habitForm(String goalId, [String? habitId]) =>
      Uri(path: habitFormPath, queryParameters: {'goal': goalId, 'habit': ?habitId}).toString();
}

/// Navigator gốc, để phản hồi nhắc (3.3) hiện được dù người dùng đang ở màn nào.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final profile = ref.read(profileRepositoryProvider);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.today,
    // Unknown paths (removed routes, or typed on web) go to Hôm nay.
    onException: (context, state, router) => router.go(AppRoutes.today),
    // First launch goes to onboarding; later launches go straight to Hôm nay.
    redirect: (context, state) {
      final location = state.matchedLocation;
      final atOnboarding = location == AppRoutes.onboarding;
      if (!profile.isOnboardingDone && !atOnboarding) return AppRoutes.onboarding;
      if (profile.isOnboardingDone && atOnboarding) return AppRoutes.today;

      final phase = ref.read(focusSessionProvider).phase;
      // Màn Tổng kết chỉ có nghĩa khi vừa có phiên học kết thúc.
      if (location == AppRoutes.summary && phase != FocusPhase.finished) return AppRoutes.today;
      // The session screen only opens while a session runs (breaks included).
      if (location == AppRoutes.focus && phase != FocusPhase.running) return AppRoutes.today;
      if (location == AppRoutes.motivation) {
        final isDistracted = state.uri.queryParameters['context'] == ReelContext.distracted;
        // "distracted" needs a running session; "start" while running goes to that session.
        if (isDistracted && phase != FocusPhase.running) return AppRoutes.today;
        if (!isDistracted && phase == FocusPhase.running) return AppRoutes.focus;
      }
      // Reset break exists on Android only; typed on web it goes to Hôm nay.
      final isResetBreakRoute =
          location == AppRoutes.resetBreakPermissions || location == AppRoutes.blockedApps;
      if (isResetBreakRoute && !ref.read(nativeBridgeProvider).isSupported) return AppRoutes.today;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.onboarding, builder: (context, state) => const OnboardingScreen()),
      // Three bottom tabs (ADR-0002); each keeps its state when switching.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.today, builder: (context, state) => const TodayScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.habits, builder: (context, state) => const HabitsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
        ],
      ),
      // Các màn này nằm ngoài tab nên chiếm toàn màn hình.
      // Motivation step: a bounded dose of reels (spec 002).
      GoRoute(
        path: AppRoutes.motivation,
        builder: (context, state) => MotivationScreen(
          reelContext: state.uri.queryParameters['context'] ?? ReelContext.start,
        ),
      ),
      GoRoute(path: AppRoutes.focus, builder: (context, state) => const FocusScreen()),
      GoRoute(path: AppRoutes.summary, builder: (context, state) => const SummaryScreen()),
      GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
      GoRoute(path: AppRoutes.quiz, builder: (context, state) => const QuizScreen()),
      GoRoute(
        path: AppRoutes.resetBreakPermissions,
        builder: (context, state) => const ResetBreakPermissionsScreen(),
      ),
      GoRoute(path: AppRoutes.blockedApps, builder: (context, state) => const BlockedAppsScreen()),
      GoRoute(path: AppRoutes.myHabits, builder: (context, state) => const MyHabitsScreen()),
      GoRoute(path: AppRoutes.gretCorner, builder: (context, state) => const GretCornerScreen()),
      GoRoute(path: AppRoutes.seaMap, builder: (context, state) => const SeaMapScreen()),
      GoRoute(
        path: AppRoutes.habitDetailPath,
        builder: (context, state) => HabitDetailScreen(habitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.habitFormPath,
        builder: (context, state) => HabitFormScreen(
          goalId: state.uri.queryParameters['goal'] ?? '',
          habitId: state.uri.queryParameters['habit'],
        ),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
