// 2.1 / 5.2 Farmly-style buttons, icon tiles and cards (spec 015).
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/habit_log.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/session.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_log_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/data/repositories/session_repository.dart';
import 'package:focus_app/data/today_tasks.dart';
import 'package:focus_app/l10n/app_strings.dart';
import 'package:focus_app/screens/sea_map_screen.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/icon_tile.dart';
import 'package:focus_app/widgets/sea/clarity_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

void main() {
  final today = DateTime(2026, 11, 27);
  final now = DateTime(2026, 11, 27, 10);

  Habit habit(
    String id, {
    int order = 0,
    bool reminder = false,
    String time = '07:00',
    bool archived = false,
    List<int> weekdays = const [],
  }) => Habit(
    id: id,
    goalId: 'g1',
    name: 'Thói quen $id',
    minMinutesPerDay: 15,
    startDate: DateTime(2026, 11),
    sortOrder: order,
    reminderEnabled: reminder,
    reminderTime: time,
    archived: archived,
    repeat: weekdays.isEmpty ? HabitRepeat.daily : HabitRepeat.weekly,
    weekdays: weekdays,
  );

  HabitLog doneLog(String habitId) => HabitLog(
    id: 'log_$habitId',
    habitId: habitId,
    date: today,
    source: HabitLogSource.manual,
    minutes: 15,
  );

  group('Việc hôm nay (FR-003)', () {
    test('habits scheduled today, timed ones first by time, then by habit order', () {
      final tasks = TodayTasks.of(
        habits: [
          habit('c', order: 0),
          habit('b', order: 1, reminder: true, time: '19:00'),
          habit('a', order: 2, reminder: true, time: '07:00'),
          habit('gone', archived: true),
          // 27/11/2026 is a Friday (5): not scheduled on Mondays only.
          habit('monday', weekdays: const [1]),
        ],
        logs: [doneLog('a')],
        today: today,
      );

      expect([for (final task in tasks) task.habit.id], ['a', 'b', 'c']);
      expect([for (final task in tasks) task.done], [true, false, false]);
      expect([for (final task in tasks) task.time], ['07:00', '19:00', null]);
    });
  });

  group('IconTile (FR-001)', () {
    setUp(openMemoryBoxes);
    tearDown(() async => Hive.close());

    testWidgets('shows a count badge or a tag, and nothing for zero', (tester) async {
      await pumpStandalone(
        tester,
        Row(
          children: [
            IconTile(icon: AppIcons.map, colour: AppHabitColors.of(0), badge: 2),
            IconTile(icon: AppIcons.wardrobe, colour: AppHabitColors.of(6), tag: '8'),
            IconTile(icon: AppIcons.stats, colour: AppHabitColors.of(4), badge: 0),
          ],
        ),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });
  });

  group('Hôm nay (US1)', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

    setUp(() async {
      await openMemoryBoxes();
      VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
      await ProfileRepository().completeOnboarding(
        const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
      );
      await GoalRepository().save(const Goal(id: 'g1', title: 'Đỗ đại học', reason: 'Vì'));
      await HabitRepository().save(habit('h1', reminder: true));
      await HabitRepository().save(habit('h2', order: 1, reminder: true, time: '19:00'));
      await HabitLogRepository().save(doneLog('h1'));
      await SessionRepository().save(
        Session(
          id: 's',
          habitId: 'h1',
          start: now.subtract(const Duration(hours: 2)),
          plannedMinutes: 25,
          focusedSeconds: 8 * 300,
          distractionCount: 0,
        ),
      );
    });
    tearDown(() async => Hive.close());

    Future<void> open(WidgetTester tester) =>
        pumpApp(tester, size: const Size(412, 915), clock: () => now);

    testWidgets('shortcuts with the pearl tag and the reminder badge, and today\'s tasks', (
      tester,
    ) async {
      await open(tester);
      await tester.scrollUntilVisible(find.text(AppStrings.todayTasks), 200);

      expect(find.text(AppStrings.shortcuts), findsOneWidget);
      // 8 pearls; one reminder still to come today (19:00).
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('shortcut-corner')),
          matching: find.text('8'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('shortcut-reminders')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.todayTasksDone(1, 2)), findsOneWidget);
      expect(find.text(AppStrings.todayTaskLine('Thói quen h2', 15)), findsOneWidget);
      expect(find.text('19:00'), findsOneWidget);
    });

    testWidgets('the map shortcut opens the sea map; the clarity card opens Tiến độ', (
      tester,
    ) async {
      await open(tester);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('shortcut-map')), 200);
      await tapAndSettle(tester, find.byKey(const ValueKey('shortcut-map')));
      expect(find.byType(SeaMapScreen), findsOneWidget);

      await tapAndSettle(tester, find.byTooltip('Quay lại'));
      await tester.scrollUntilVisible(find.byType(ClarityCard), -200);
      await tapAndSettle(tester, find.byType(ClarityCard));
      expect(find.text(AppStrings.tabProgress), findsWidgets);
    });

    testWidgets('a small phone shows Hôm nay without overflow', (tester) async {
      await pumpApp(tester, clock: () => now);
      await tester.scrollUntilVisible(find.text(AppStrings.todayTasks), 200);
      expect(tester.takeException(), isNull);
    });
  });
}
