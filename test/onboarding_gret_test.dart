// 5.3 Gret và biển sống: onboarding as a story told by Gret (spec 003 US2, FR-011, FR-011a; tasks
// T018–T020, T029). The saved data are unchanged apart from the app choice; these tests cover what
// the redesign adds.
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/mascot_mood.dart';
import 'package:focus_app/data/repositories/blocked_apps_repository.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/l10n/app_strings.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/mascot/mascot_bubbles.dart';
import 'package:focus_app/widgets/mascot/mascot_view.dart';
import 'package:focus_app/widgets/sea/sea_scene.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const List<String> _storyLines = [
  AppStrings.storyHello,
  AppStrings.storyScroll,
  AppStrings.storyStudy,
  AppStrings.storyCallBack,
];

Future<void> _enterField(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.widgetWithText(TextFormField, label), text);
  await tester.pump();
}

/// From the first story page to the first quiz question (name left empty, reel length kept).
Future<void> _toQuiz(WidgetTester tester) async {
  await tapAndSettle(tester, find.text(AppStrings.storySkip));
  await tapAndSettle(tester, find.text(AppStrings.continueLabel));
  await tapAndSettle(tester, find.text(AppStrings.continueLabel));
}

/// Gret's question about the name, in its thought bubble (spec 007).
Finder get _nameQuestion =>
    find.descendant(of: find.byType(ThoughtBubble), matching: find.text(AppStrings.nameQuestion));

/// Two "career" and two "prove yourself" answers.
Future<void> _answerQuiz(WidgetTester tester) async {
  await tapAndSettle(tester, find.text('Có công việc mình thật sự muốn làm'));
  await tapAndSettle(tester, find.text('Đang ở đúng vị trí mình mơ ước'));
  await tapAndSettle(tester, find.text('Không muốn thua chính mình'));
  await tapAndSettle(tester, find.text('Niềm tin rằng mình làm được'));
}

/// From the first story page to the first-goal page, keeping the suggested apps.
Future<void> _toFirstGoal(WidgetTester tester) async {
  await _toQuiz(tester);
  await _answerQuiz(tester);
  await tapAndSettle(tester, find.text(AppStrings.continueLabel));
}

Future<void> _fillFirstGoal(WidgetTester tester) async {
  await _enterField(tester, 'Tên mục tiêu', 'Qua môn Toán');
  await _enterField(tester, 'Vì sao bạn muốn điều này?', 'Để ra trường đúng hạn');
  await _enterField(tester, 'Tên thói quen', 'Làm đề');
}

/// Turns the system "remove animations" setting off again (pumpApp turns it on).
Future<void> _animationsOn(WidgetTester tester) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures();
  await tester.pump();
}

MascotMood _gretMood(WidgetTester tester) =>
    tester.widget<MascotView>(find.byType(MascotView)).mood;

double _clarity(WidgetTester tester) => tester.widget<SeaScene>(find.byType(SeaScene)).clarity;

/// A point inside the sea, at [fraction] of its width (story tap zones).
Offset _inSea(WidgetTester tester, double fraction) {
  final rect = tester.getRect(find.byType(SeaScene));
  return Offset(rect.left + rect.width * fraction, rect.top + rect.height * 0.2);
}

Finder _storyLine(String line) =>
    find.descendant(of: find.byType(SpeechBubble), matching: find.text(line));

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    await openMemoryBoxes();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  });

  tearDown(() async {
    await Hive.close();
  });

  group('Story', () {
    testWidgets('First page: progress, brand, Gret says hello in the sea, skip and continue', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.byKey(const ValueKey('story-progress')), findsOneWidget);
      expect(find.text(AppStrings.appName), findsOneWidget);
      expect(find.text(AppStrings.headlineTop), findsOneWidget);
      expect(find.text(AppStrings.headlineBottom), findsOneWidget);
      expect(_storyLine(AppStrings.storyHello), findsOneWidget);
      expect(find.byType(SeaScene), findsOneWidget);
      expect(_gretMood(tester), MascotMood.happy);
      expect(find.text(AppStrings.storySkip), findsOneWidget);
      expect(find.text(AppStrings.continueLabel), findsOneWidget);
    });

    testWidgets('"Tiếp tục" tells the four pages; the sea murks, then clears', (tester) async {
      await pumpApp(tester);

      final moods = [MascotMood.happy, MascotMood.sad, MascotMood.happy, MascotMood.focused];
      for (var page = 0; page < _storyLines.length; page++) {
        expect(_storyLine(_storyLines[page]), findsOneWidget);
        expect(_gretMood(tester), moods[page]);
        if (page == 1) expect(_clarity(tester), lessThan(40), reason: 'Litter in the water');
        if (page == 2) expect(_clarity(tester), greaterThanOrEqualTo(70), reason: 'Fish return');
        await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      }
      expect(_nameQuestion, findsOneWidget);

      // System Back goes one page back.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_storyLine(AppStrings.storyCallBack), findsOneWidget);
    });

    testWidgets('A tap on the right goes forward, on the left goes back', (tester) async {
      await pumpApp(tester);

      await tester.tapAt(_inSea(tester, 0.85));
      await tester.pumpAndSettle();
      expect(_storyLine(AppStrings.storyScroll), findsOneWidget);

      await tester.tapAt(_inSea(tester, 0.1));
      await tester.pumpAndSettle();
      expect(_storyLine(AppStrings.storyHello), findsOneWidget);
    });

    testWidgets('"Bỏ qua" jumps to the first question', (tester) async {
      await pumpApp(tester);

      await tapAndSettle(tester, find.text(AppStrings.storySkip));
      expect(_nameQuestion, findsOneWidget);
      expect(find.text(AppStrings.storySkip), findsNothing);
    });

    testWidgets('With animations on, a page turns after 4 s; holding a finger pauses it', (
      tester,
    ) async {
      await pumpApp(tester);
      await _animationsOn(tester);

      await tester.pump(AppMotion.storyPage - const Duration(milliseconds: 200));
      expect(_storyLine(AppStrings.storyHello), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(_storyLine(AppStrings.storyScroll), findsOneWidget);

      final hold = await tester.startGesture(_inSea(tester, 0.85));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await tester.pump(AppMotion.storyPage * 2);
      expect(_storyLine(AppStrings.storyScroll), findsOneWidget, reason: 'Paused while held');

      await hold.up();
      await tester.pump(); // The resumed clock starts counting from this frame.
      await tester.pump(AppMotion.storyPage + const Duration(milliseconds: 100));
      await tester.pump();
      expect(_storyLine(AppStrings.storyStudy), findsOneWidget);

      await tester.pumpWidget(const SizedBox()); // Remove the looping scene before the test ends.
    });

    testWidgets('With "remove animations" on, story pages wait for the user', (tester) async {
      await pumpApp(tester);

      await tester.pump(AppMotion.storyPage * 3);
      expect(_storyLine(AppStrings.storyHello), findsOneWidget);
    });
  });

  group('Questions', () {
    testWidgets('Gret asks for a name after the story; it is saved when onboarding ends', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapAndSettle(tester, find.text(AppStrings.storySkip));
      expect(_nameQuestion, findsOneWidget);

      await tester.enterText(find.byType(TextField), '  Khôi ');
      await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      await _answerQuiz(tester);
      await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      await _fillFirstGoal(tester);
      await tapAndSettle(tester, find.text(AppStrings.enterApp));

      expect(ProfileRepository().profile?.displayName, 'Khôi');
      expect(find.textContaining(', Khôi'), findsOneWidget, reason: 'Hôm nay greets by name');
    });

    testWidgets('The reel length is asked by Gret, kept when going back and saved at the end', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapAndSettle(tester, find.text(AppStrings.storySkip));
      await tapAndSettle(tester, find.text(AppStrings.continueLabel)); // No name.
      expect(
        find.descendant(
          of: find.byType(ThoughtBubble),
          matching: find.text(AppStrings.reelLengthQuestion),
        ),
        findsOneWidget,
      );
      await tapAndSettle(tester, find.text('60 giây'));
      await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      expect(find.text('Câu 1/4'), findsOneWidget);

      await tapAndSettle(tester, find.text(AppStrings.back));
      expect(tester.getSemantics(find.text('60 giây')), isSemantics(isSelected: true));

      await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      await _answerQuiz(tester);
      await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      expect(find.text(AppStrings.gretGoalPrompt), findsOneWidget);
      await _fillFirstGoal(tester);
      await tapAndSettle(tester, find.text(AppStrings.enterApp));

      expect(find.text(AppStrings.start), findsOneWidget);
      expect(ProfileRepository().profile?.preferredReelLength, 60);
      expect(ProfileRepository().profile?.displayName, '');
      expect(GoalRepository().getAll().single.title, 'Qua môn Toán');
      expect(HabitRepository().getAll().single.name, 'Làm đề');
    });

    testWidgets('Quiz: the question is in Gret\'s thought bubble, with step dots', (tester) async {
      await pumpApp(tester);
      await _toQuiz(tester);

      expect(
        find.descendant(
          of: find.byType(ThoughtBubble),
          matching: find.text('Điều gì khiến bạn muốn cố gắng nhất?'),
        ),
        findsOneWidget,
      );
      expect(find.text('Câu 1/4'), findsOneWidget);
      expect(find.byKey(const ValueKey('quiz-step-dots')), findsOneWidget);
      expect(_gretMood(tester), MascotMood.neutral);
    });

    testWidgets('Quiz: Gret is happy for a moment before the next question', (tester) async {
      await pumpApp(tester);
      await _toQuiz(tester);
      await _animationsOn(tester);

      await tester.tap(find.text('Có công việc mình thật sự muốn làm'));
      await tester.pump();
      expect(
        find.text('Câu 1/4'),
        findsOneWidget,
        reason: 'Still on the question during the reaction',
      );
      expect(_gretMood(tester), MascotMood.happy);

      // A second tap during the reaction does not answer twice.
      await tester.tap(find.text('Làm người thân tự hào và yên tâm'));
      await tester.pump(AppMotion.reaction);
      await tester.pump();
      expect(find.text('Câu 2/4'), findsOneWidget);
      expect(_gretMood(tester), MascotMood.neutral);

      // Back shows the first answer, not the second tap.
      await tester.tap(find.text(AppStrings.back));
      await tester.pump();
      expect(
        tester.getSemantics(find.text('Có công việc mình thật sự muốn làm')),
        isSemantics(isSelected: true),
      );

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Apps: the reminder list is preselected; the choice is saved only at the end', (
      tester,
    ) async {
      await pumpApp(tester);
      await _toQuiz(tester);
      await _answerQuiz(tester);

      expect(find.text(AppStrings.appsQuestion), findsOneWidget);
      for (final app in BlockedAppsRepository.onboardingApps.keys) {
        expect(tester.getSemantics(find.text(app)), isSemantics(isSelected: true), reason: app);
      }

      await tapAndSettle(tester, find.text('TikTok'));
      await tapAndSettle(tester, find.text('Chrome'));
      expect(tester.getSemantics(find.text('TikTok')), isSemantics(isSelected: false));
      expect(
        BlockedAppsRepository().packages,
        BlockedAppsRepository.defaultPackages,
        reason: 'Nothing is saved before the last page',
      );

      await tapAndSettle(tester, find.text(AppStrings.continueLabel));
      await _fillFirstGoal(tester);
      await tapAndSettle(tester, find.text(AppStrings.enterApp));

      expect(BlockedAppsRepository().packages, {
        'com.facebook.katana',
        'com.instagram.android',
        'com.google.android.youtube',
      });
    });

    testWidgets('Without the reminder feature (web) there is no app page', (tester) async {
      await pumpApp(tester, native: FakeNativeBridge(supported: false));
      await _toQuiz(tester);
      await _answerQuiz(tester);

      expect(find.text(AppStrings.appsQuestion), findsNothing);
      expect(find.text(AppStrings.gretGoalPrompt), findsOneWidget);
    });
  });

  group('Finish', () {
    testWidgets('Finishing shows "your sea is ready" with a happy Gret, then Hôm nay', (
      tester,
    ) async {
      await pumpApp(tester);
      await _toFirstGoal(tester);
      await _fillFirstGoal(tester);
      await _animationsOn(tester);

      await tester.tap(find.text(AppStrings.enterApp));
      await tester.pump();
      await tester.pump(AppMotion.entrance);
      expect(find.text(AppStrings.seaReady), findsOneWidget);
      expect(_gretMood(tester), MascotMood.happy);
      // Everything is saved before the moment, so closing the app now loses nothing.
      expect(ProfileRepository().isOnboardingDone, isTrue);
      expect(GoalRepository().getAll(), hasLength(1));

      await tester.pump(AppMotion.seaReady);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(AppStrings.seaReady), findsNothing);
      expect(find.text(AppStrings.start), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('With "remove animations" on, finishing goes straight to Hôm nay', (tester) async {
      await pumpApp(tester);
      await _toFirstGoal(tester);
      await _fillFirstGoal(tester);
      await tapAndSettle(tester, find.text(AppStrings.enterApp));

      expect(find.text(AppStrings.seaReady), findsNothing);
      expect(find.text(AppStrings.start), findsOneWidget);
    });
  });
}
