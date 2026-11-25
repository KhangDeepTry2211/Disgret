// 5.3 Hôm nay on a full-screen sea (spec 010): the sea fills the screen and stays still, the cards
// float over it, and the tab bar floats on every tab.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/habit_log.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_log_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/l10n/app_strings.dart';
import 'package:focus_app/widgets/empty_goal_view.dart';
import 'package:focus_app/widgets/gradient_pill_button.dart';
import 'package:focus_app/widgets/mascot/mascot_bubbles.dart';
import 'package:focus_app/widgets/mascot/mascot_view.dart';
import 'package:focus_app/widgets/ripple_add_button.dart';
import 'package:focus_app/widgets/sea/clarity_card.dart';
import 'package:focus_app/widgets/sea/sea_scene.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const Goal _goal = Goal(id: 'g1', title: 'Đỗ đại học', reason: 'Vì tương lai');
const Size _phone = Size(412, 915);

void main() {
  late DateTime now;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    await openMemoryBoxes();
    now = DateTime.now();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
    await ProfileRepository().completeOnboarding(
      const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
    );
  });

  tearDown(() async => Hive.close());

  Future<void> withPlan() async {
    await GoalRepository().save(_goal);
    await HabitRepository().save(
      Habit(id: 'h1', goalId: 'g1', name: 'Ôn Toán', minMinutesPerDay: 30, startDate: now),
    );
  }

  Future<void> openApp(WidgetTester tester, {Size size = _phone}) =>
      pumpApp(tester, size: size, clock: () => now);

  Rect rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder.first);

  group('The sea fills Hôm nay (US1, FR-001, FR-002)', () {
    testWidgets('the sea is the whole screen and stays still while the cards scroll', (
      tester,
    ) async {
      await withPlan();
      // A small phone, so the cards are taller than the space left and the list scrolls.
      await openApp(tester, size: smallPhone);
      final sea = rectOf(tester, find.byType(SeaScene));
      expect(sea, Offset.zero & smallPhone);

      final cardBefore = rectOf(tester, find.byType(ClarityCard));
      await tester.drag(find.byType(ClarityCard), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(rectOf(tester, find.byType(SeaScene)), sea, reason: 'The sea does not scroll');
      expect(rectOf(tester, find.byType(ClarityCard)).top, lessThan(cardBefore.top - 50));
    });

    testWidgets('Gret swims in the upper part and the cards start below Gret', (tester) async {
      await withPlan();
      await openApp(tester);

      final gret = rectOf(tester, find.byType(MascotView));
      expect(gret.center.dy, lessThan(_phone.height * 0.4));
      expect(rectOf(tester, find.byType(ClarityCard)).top, greaterThan(gret.bottom));
    });

    testWidgets('tapping Gret through the empty space still makes Gret talk', (tester) async {
      await withPlan();
      await openApp(tester);

      await tester.tapAt(tester.getCenter(find.byType(MascotView)));
      await tester.pump();

      expect(find.byType(SpeechBubble), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('with no goal yet, the invitation sits on a card over the full sea', (
      tester,
    ) async {
      await openApp(tester);

      expect(rectOf(tester, find.byType(SeaScene)), Offset.zero & _phone);
      final card = find.ancestor(
        of: find.byType(EmptyGoalView),
        matching: find.byKey(const ValueKey('today-empty-card')),
      );
      expect(card, findsOneWidget);
    });
  });

  group('Floating tab bar (US2, FR-003)', () {
    testWidgets('the tab bar is inset from the edges', (tester) async {
      await withPlan();
      await openApp(tester);

      final bar = rectOf(tester, find.byType(NavigationBar));
      expect(bar.left, greaterThanOrEqualTo(16));
      expect(bar.right, lessThanOrEqualTo(_phone.width - 16));
      expect(bar.bottom, lessThanOrEqualTo(_phone.height - 16));
    });

    testWidgets('"Bắt đầu" and the Thói quen "+" stay above the bar', (tester) async {
      await withPlan();
      await openApp(tester);
      final bar = rectOf(tester, find.byType(NavigationBar));

      expect(rectOf(tester, find.byType(GradientPillButton)).bottom, lessThanOrEqualTo(bar.top));

      await tapAndSettle(tester, find.widgetWithText(NavigationDestination, AppStrings.tabHabits));
      expect(rectOf(tester, find.byType(RippleAddButton)).bottom, lessThanOrEqualTo(bar.top));
    });

    testWidgets('a small phone shows Hôm nay and Thói quen without overflow', (tester) async {
      await withPlan();
      await openApp(tester, size: smallPhone);
      expect(tester.takeException(), isNull);

      await tapAndSettle(tester, find.widgetWithText(NavigationDestination, AppStrings.tabHabits));
      expect(tester.takeException(), isNull);
    });
    testWidgets('the end of Tiến độ scrolls above the bar', (tester) async {
      await withPlan();
      await HabitLogRepository().save(
        HabitLog(id: 'l1', habitId: 'h1', date: now, source: HabitLogSource.manual, minutes: 30),
      );
      await openApp(tester);
      await tapAndSettle(
        tester,
        find.widgetWithText(NavigationDestination, AppStrings.tabProgress),
      );

      await tester.drag(find.byType(ListView).last, const Offset(0, -5000));
      await tester.pumpAndSettle();

      final bar = rectOf(tester, find.byType(NavigationBar));
      final footnote = find.textContaining('Ngày hoàn hảo: mọi thói quen');
      expect(rectOf(tester, footnote).bottom, lessThanOrEqualTo(bar.top));
    });
  });
}
