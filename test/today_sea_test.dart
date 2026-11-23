// 5.3 Hôm nay with the living sea (spec 003 US1, FR-009, FR-010; spec 001 SC-002 still holds).
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/event_repository.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/l10n/app_strings.dart';
import 'package:focus_app/screens/today_screen.dart';
import 'package:focus_app/widgets/gradient_pill_button.dart';
import 'package:focus_app/widgets/mascot/mascot_bubbles.dart';
import 'package:focus_app/widgets/mascot/mascot_view.dart';
import 'package:focus_app/widgets/sea/clarity_card.dart';
import 'package:focus_app/widgets/sea/sea_scene.dart';
import 'package:focus_app/widgets/streak_card.dart';
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
    await GoalRepository().save(_goal);
    // Created today, so a brand-new user: no missed days yet.
    await HabitRepository().save(
      Habit(id: 'h1', goalId: 'g1', name: 'Ôn Toán', minMinutesPerDay: 30, startDate: now),
    );
  });

  tearDown(() async {
    await Hive.close();
  });

  Future<void> openApp(WidgetTester tester) => pumpApp(tester, size: _phone, clock: () => now);

  testWidgets('shows the sea, a 70% clarity card and the streak card for a new user', (
    tester,
  ) async {
    await openApp(tester);

    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.byType(SeaScene), findsOneWidget);
    expect(find.byType(MascotView), findsOneWidget);
    expect(find.byType(StreakCard), findsOneWidget);
    expect(
      find.descendant(of: find.byType(ClarityCard), matching: find.text('70%')),
      findsOneWidget,
    );
    expect(find.text(AppStrings.clarityClear), findsOneWidget);
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.bySemanticsLabel('Chuỗi 0 ngày học liên tiếp'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Gret đang vui')), findsOneWidget);
  });

  testWidgets('still exactly one control leads into a session (spec 001 SC-002)', (tester) async {
    await openApp(tester);

    expect(find.byType(GradientPillButton), findsOneWidget);
    expect(find.text(AppStrings.start), findsOneWidget);
  });

  testWidgets('tapping Gret shows a line and starts nothing', (tester) async {
    await openApp(tester);

    await tester.tap(find.byType(MascotView));
    await tester.pump();

    expect(find.byType(TodayScreen), findsOneWidget);
    final happyLines = find.byWidgetPredicate(
      (widget) => widget is Text && AppStrings.gretHappy.contains(widget.data),
    );
    expect(happyLines, findsOneWidget);

    // The line disappears after a few seconds.
    await tester.pump(const Duration(seconds: 4));
    expect(happyLines, findsNothing);
  });

  testWidgets('the sea fills the top behind the header; the wardrobe button never covers Gret', (
    tester,
  ) async {
    await openApp(tester);

    final sea = tester.getRect(find.byType(SeaScene));
    expect(sea.top, 0, reason: 'Full bleed: the sea starts under the status bar and header');
    expect(sea.width, _phone.width);
    expect(tester.widget<SeaScene>(find.byType(SeaScene)).variant, SeaSceneVariant.full);

    final corner = find.byTooltip(AppStrings.cornerOpen);
    expect(find.descendant(of: find.byType(AppBar), matching: corner), findsOneWidget);

    await tester.tap(find.byType(MascotView));
    await tester.pump();
    final bubble = tester.getRect(find.byType(SpeechBubble));
    final header = tester.getRect(find.byType(AppBar));
    expect(bubble.top, greaterThanOrEqualTo(header.bottom), reason: 'Gret speaks below the header');
    expect(bubble.overlaps(tester.getRect(corner)), isFalse);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('a distraction today lowers the clarity by 5 points', (tester) async {
    await EventRepository().logSessionDistracted(awaySeconds: 30, distractionIndex: 1);
    await openApp(tester);

    expect(
      find.descendant(of: find.byType(ClarityCard), matching: find.text('65%')),
      findsOneWidget,
    );
    expect(find.text(AppStrings.clarityHazy), findsOneWidget);
  });
}
