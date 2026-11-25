// 2.2 Nhắc giờ học (spec 009 FR-002, FR-004): the app keeps the scheduled reminders in step with
// the habits and asks once for the notification permission.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/data/repositories/reminder_settings_repository.dart';
import 'package:focus_app/providers/app_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const Goal _goal = Goal(id: 'g1', title: 'Mục tiêu', reason: 'Lý do');

Habit _habit({bool reminder = true}) => Habit(
  id: 'h1',
  goalId: 'g1',
  name: 'Ôn Toán',
  minMinutesPerDay: 25,
  reminderEnabled: reminder,
  reminderTime: '19:00',
  startDate: DateTime(2026, 3, 1),
);

void main() {
  final morning = DateTime(2026, 3, 2, 9);
  late FakeReminderService reminders;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    await openMemoryBoxes();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
    reminders = FakeReminderService();
    await ProfileRepository().completeOnboarding(
      const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
    );
    await GoalRepository().save(_goal);
  });

  tearDown(() async => Hive.close());

  Future<void> openApp(WidgetTester tester) =>
      pumpApp(tester, clock: () => morning, reminders: reminders);

  testWidgets('saved reminders are scheduled when the app opens', (tester) async {
    await HabitRepository().save(_habit());
    await openApp(tester);

    expect(reminders.plans.last, isNotEmpty);
    expect(reminders.plans.last.first.at, DateTime(2026, 3, 2, 19));
    expect(reminders.plans.last.every((reminder) => reminder.habitId == 'h1'), isTrue);
  });

  testWidgets('the permission is asked once, when the first reminder exists', (tester) async {
    await openApp(tester);
    expect(reminders.permissionRequests, 0, reason: 'No reminder yet');

    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    await container.read(habitsProvider.notifier).edit(_habit());
    await tester.pumpAndSettle();
    expect(reminders.permissionRequests, 1);
    expect(ReminderSettingsRepository().permissionAsked, isTrue);

    await container.read(habitsProvider.notifier).edit(_habit(reminder: false));
    await tester.pumpAndSettle();
    await container.read(habitsProvider.notifier).edit(_habit());
    await tester.pumpAndSettle();
    expect(reminders.permissionRequests, 1, reason: 'Asked only once');
  });

  testWidgets('switching the reminder off removes it', (tester) async {
    await HabitRepository().save(_habit());
    await openApp(tester);

    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    await container.read(habitsProvider.notifier).edit(_habit(reminder: false));
    await tester.pumpAndSettle();

    expect(reminders.plans.last, isEmpty);
  });

  testWidgets('tapping a reminder opens Hôm nay', (tester) async {
    await HabitRepository().save(_habit());
    await openApp(tester);
    await tapAndSettle(tester, find.widgetWithText(NavigationDestination, 'Thói quen'));
    expect(find.text('Học tiếp'), findsNothing);

    reminders.tap();
    await tester.pumpAndSettle();

    expect(find.text('Học tiếp'), findsOneWidget);
  });
}
