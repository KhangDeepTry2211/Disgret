// 2.1 Hôm nay (spec 016): hold the round button 1.5 s to start studying.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/l10n/app_strings.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/hold_to_start_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

void main() {
  final hold = find.byType(HoldToStartButton);

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() async {
    await openMemoryBoxes();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
    await ProfileRepository().completeOnboarding(
      const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
    );
    await GoalRepository().save(const Goal(id: 'g1', title: 'Đỗ đại học', reason: 'Vì'));
    await HabitRepository().save(
      Habit(
        id: 'h1',
        goalId: 'g1',
        name: 'Ôn Toán',
        minMinutesPerDay: 15,
        startDate: DateTime(2026),
      ),
    );
  });
  tearDown(() async => Hive.close());

  testWidgets('Hôm nay shows the bar with the round button', (tester) async {
    await pumpApp(tester);

    expect(hold, findsOneWidget);
    expect(find.text(AppStrings.holdReady), findsOneWidget);
    expect(find.text(AppStrings.holdToStartHint), findsOneWidget);
    expect(find.text(AppStrings.start), findsOneWidget);
  });

  testWidgets('a quick tap only asks to hold longer', (tester) async {
    await pumpApp(tester);

    await tester.tap(hold);
    await tester.pump();

    expect(find.text(AppStrings.holdLonger), findsOneWidget);
    expect(hold, findsOneWidget, reason: 'Still on Hôm nay');
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('letting go early drains the ring and starts nothing', (tester) async {
    await pumpApp(tester);

    final gesture = await tester.startGesture(tester.getCenter(hold));
    await tester.pump();
    await tester.pump(AppMotion.holdToStart ~/ 2);
    expect(find.text(AppStrings.holdLines[1]), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(hold, findsOneWidget);
    expect(find.text(AppStrings.holdToStartHint), findsOneWidget);
  });

  testWidgets('holding 1.5 s opens the study flow', (tester) async {
    await pumpApp(tester);

    await holdToStart(tester);

    expect(hold, findsNothing, reason: 'Left Hôm nay for the study flow');
  });

  testWidgets('a screen reader starts it with a double-tap', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester);

    tester.semantics.tap(find.semantics.byLabel(RegExp('^${AppStrings.holdReady}')));
    await tester.pumpAndSettle();

    expect(hold, findsNothing);
    semantics.dispose();
  });
}
