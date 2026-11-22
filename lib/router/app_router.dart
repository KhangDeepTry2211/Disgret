// 5.1 Điều hướng bằng go_router.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/reel.dart';
import '../providers/account_providers.dart';
import '../providers/app_providers.dart';
import '../providers/focus_session_provider.dart';
import '../screens/blocked_apps_screen.dart';
import '../screens/focus_screen.dart';
import '../screens/habit_detail_screen.dart';
import '../screens/habit_form_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_flow.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/habits_screen.dart';
import '../screens/my_habits_screen.dart';
import '../screens/report_screen.dart';
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

  // F3 Màn chào, đăng nhập, đăng ký, hồ sơ.
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String profile = '/profile';
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
  static const String habitDetailPath = '/habit/:id';
  static const String habitFormPath = '/habit-form';
  static const String report = '/report';
  static const String myHabits = '/my-habits';
  static const String achievements = '/achievements';

  /// 1.4 Mở Reels với ngữ cảnh cho trước; không có tham số thì mặc định là "start".
  static String reelsFor(String reelContext) => '$reels?context=$reelContext';

  /// 4.2 Màn chi tiết một thói quen.
  static String habitDetail(String habitId) => '/habit/$habitId';

  /// 4.1 Tạo thói quen mới trong mục tiêu [goalId], hoặc sửa nếu có [habitId].
  static String habitForm(String goalId, [String? habitId]) =>
      Uri(path: habitFormPath, queryParameters: {'goal': goalId, 'habit': ?habitId}).toString();

  /// Mở Focus với số phút cho trước.
  static String focusFor(int minutes) => '$focus?minutes=$minutes';
}

/// Navigator gốc, để phản hồi nhắc (3.3) hiện được dù người dùng đang ở màn nào.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final profile = ref.read(profileRepositoryProvider);

  // F3 Đăng nhập / đăng xuất thì chạy lại redirect (ví dụ đăng xuất xong về màn chào).
  final authChanged = ValueNotifier<int>(0);
  ref.listen(currentUserProvider, (previous, next) => authChanged.value++);
  ref.onDispose(authChanged.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: authChanged,
    // Đường dẫn không tồn tại (chỉ gặp trên web) thì đưa về Trang chủ.
    onException: (context, state, router) => router.go(AppRoutes.home),
    redirect: (context, state) {
      final location = state.matchedLocation;
      // F3 Chưa đăng nhập, chưa chọn "Dùng thử" và chưa từng vào app (onboarding) → màn chào.
      final passedWelcome =
          ref.read(currentUserProvider) != null || profile.isGuestMode || profile.isOnboardingDone;
      final atAuth =
          location == AppRoutes.welcome ||
          location == AppRoutes.login ||
          location == AppRoutes.signup;
      if (!passedWelcome) return atAuth ? null : AppRoutes.welcome;
      // Màn đăng nhập / đăng ký tự chuyển trang khi xong (còn màn chờ tải dữ liệu, bước Chào
      // mừng), nên không đẩy đi giữa chừng dù đã đăng nhập.
      if (location == AppRoutes.login || location == AppRoutes.signup) return null;
      // Quiz động lực (onboarding) chạy sau khi đăng ký hoặc chọn dùng thử, nếu chưa làm.
      final atOnboarding = location == AppRoutes.onboarding;
      if (!profile.isOnboardingDone && !atOnboarding) return AppRoutes.onboarding;
      if (profile.isOnboardingDone && (atOnboarding || location == AppRoutes.welcome)) {
        return AppRoutes.home;
      }
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
      GoRoute(path: AppRoutes.welcome, builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (context, state) => const SignupFlow()),
      GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen()),
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
      GoRoute(path: AppRoutes.report, builder: (context, state) => const ReportScreen()),
      GoRoute(path: AppRoutes.myHabits, builder: (context, state) => const MyHabitsScreen()),
      GoRoute(
        path: AppRoutes.achievements,
        builder: (context, state) => const AchievementsScreen(),
      ),
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
