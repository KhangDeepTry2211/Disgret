// 5.6 Quán San Hô on screen: choosing where to study, the café scene and the café during a focus
// session (spec 006 user stories 1–4).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/gret_corner_catalog.dart';
import 'package:focus_app/data/mascot_mood.dart';
import 'package:focus_app/data/mascot_species.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/data/repositories/session_repository.dart';
import 'package:focus_app/data/repositories/study_place_repository.dart';
import 'package:focus_app/data/sea_cafe.dart';
import 'package:focus_app/data/study_place.dart';
import 'package:focus_app/providers/app_providers.dart';
import 'package:focus_app/providers/sea_cafe_providers.dart';
import 'package:focus_app/l10n/app_strings.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/cafe/sea_cafe_scene.dart';
import 'package:focus_app/widgets/mascot/mascot_view.dart';
import 'package:focus_app/widgets/sea/sea_scene.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const Goal _goal = Goal(id: 'g1', title: 'Mục tiêu', reason: 'Lý do');
const Habit _habit = Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 25);

/// A regular phone, so every control fits on screen.
const Size _phone = Size(412, 915);

void main() {
  late DateTime now;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    await openMemoryBoxes();
    now = DateTime(2026, 3, 2, 9);
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
    await ProfileRepository().completeOnboarding(
      const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
    );
    await GoalRepository().save(_goal);
    await HabitRepository().save(_habit);
  });

  tearDown(() async => Hive.close());

  Future<void> openApp(WidgetTester tester) => pumpApp(tester, size: _phone, clock: () => now);

  StudyPlace storedPlace(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
          .read(studyPlaceProvider);

  group('Choosing where to study (US4, FR-002)', () {
    testWidgets('Học tiếp says the café until the sea is chosen', (tester) async {
      await openApp(tester);
      expect(find.text('ở Quán San Hô'), findsOneWidget);

      await tapAndSettle(tester, find.text('Đổi thói quen hoặc thời lượng'));
      expect(find.text('Biển của Gret'), findsOneWidget);
      expect(find.text('Quán San Hô'), findsOneWidget);

      await tapAndSettle(tester, find.text('Biển của Gret'));
      await tapAndSettle(tester, find.text('Dùng kế hoạch này'));

      expect(storedPlace(tester), StudyPlace.sea);
      expect(find.text('ở Quán San Hô'), findsNothing);
    });

    testWidgets('closing the sheet without applying keeps the place', (tester) async {
      await openApp(tester);
      await tapAndSettle(tester, find.text('Đổi thói quen hoặc thời lượng'));
      await tapAndSettle(tester, find.text('Biển của Gret'));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(storedPlace(tester), StudyPlace.cafe);
      expect(find.text('ở Quán San Hô'), findsOneWidget);
    });
  });

  group('Café scene (FR-003–FR-005, FR-009)', () {
    final friends = SeaCafe.seated(MascotSpecies.gret);

    SeaCafeScene scene({CafeLine? line, String? gretLine, Widget? overlay}) => SeaCafeScene(
      clarity: 80,
      windowPlace: SeaPlace.coral,
      look: const GretLook(),
      gretMood: MascotMood.focused,
      friendMood: MascotMood.focused,
      friends: friends,
      line: line,
      gretLine: gretLine,
      overlay: overlay,
    );

    Future<void> pumpScene(WidgetTester tester, Widget child, {Size size = smallPhone}) =>
        pumpStandalone(tester, Scaffold(body: child), size: size);

    testWidgets('the owner, three friends with their labels and Gret are there', (tester) async {
      await pumpScene(tester, scene());

      expect(find.text('Rùa · Chủ quán'), findsOneWidget);
      expect(find.text('Bơ · Toán'), findsOneWidget);
      expect(find.text('Mochi · Văn'), findsOneWidget);
      expect(find.text('Sao · Tiếng Anh'), findsOneWidget);
      expect(find.byType(MascotView), findsNWidgets(5));
    });

    testWidgets("a line shows in a bubble on its speaker's side", (tester) async {
      final centre = smallPhone.width / 2;

      await pumpScene(
        tester,
        scene(
          line: CafeLine(speaker: SeaCafe.owner, text: 'Chào nha'),
        ),
      );
      expect(tester.getCenter(find.text('Chào nha')).dx, lessThan(centre));

      await pumpScene(
        tester,
        scene(
          line: CafeLine(speaker: friends.last, text: 'Cố lên'),
        ),
      );
      expect(find.text('Chào nha'), findsNothing);
      expect(tester.getCenter(find.text('Cố lên')).dx, greaterThan(centre));
    });

    testWidgets("Gret's own line shows above Gret", (tester) async {
      await pumpScene(tester, scene(gretLine: 'Chào cả quán!'));

      expect(find.text('Chào cả quán!'), findsOneWidget);
    });

    testWidgets('screen readers hear the café and who is in it', (tester) async {
      await pumpScene(tester, scene());

      // The friends' name labels follow in the same node.
      expect(
        tester.getSemantics(find.byType(SeaCafeScene)).label,
        startsWith('Quán San Hô: Gret đang học cùng Rùa, Bơ, Mochi, Sao'),
      );
    });

    testWidgets('fits a small phone at night with a long habit name', (tester) async {
      // Night comes from the clock (spec 013).
      DateTime night() => DateTime(2026, 11, 25, 21);
      await pumpStandalone(tester, const SizedBox(), clock: night);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [clockProvider.overrideWithValue(night)],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: SizedBox(
                height: 330,
                child: scene(
                  line: CafeLine(speaker: friends.first, text: SeaCafe.greetings.first),
                  overlay: const Text('Ôn tập chương ba môn Hóa học thật kỹ trước kỳ thi cuối kỳ'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('with "remove animations" on, nothing keeps moving', (tester) async {
      await pumpScene(
        tester,
        scene(
          line: CafeLine(speaker: SeaCafe.owner, text: 'Chào'),
        ),
      );

      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('The café during a focus session (US1–US3, FR-003, FR-006–FR-008)', () {
    Future<void> wait(WidgetTester tester, Duration duration) async {
      now = now.add(duration);
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> startSession(WidgetTester tester) async {
      await openApp(tester);
      await holdToStart(tester);
      await tapAndSettle(tester, find.text('Bỏ qua'));
    }

    /// Lets the current speech bubble go away.
    Future<void> quiet(WidgetTester tester) async {
      await tester.pump(AppMotion.speechBubble);
      await tester.pumpAndSettle();
    }

    Future<void> leaveAppFor(WidgetTester tester, Duration duration) async {
      hideApp(tester);
      now = now.add(duration);
      showApp(tester);
      await tester.pumpAndSettle();
    }

    /// Exactly one of [variants] is on screen.
    void expectOneOf(List<String> variants) => expect(
      variants.where((text) => find.text(text).evaluate().isNotEmpty),
      hasLength(1),
      reason: 'one of $variants should show',
    );

    void expectNoneOf(List<String> variants) {
      for (final text in variants) {
        expect(find.text(text), findsNothing);
      }
    }

    /// Distracted four times, then "Nghỉ 5 phút" on the sheet.
    Future<void> takeBreak(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await leaveAppFor(tester, const Duration(seconds: 10));
        if (i < 3 && find.text('Học tiếp').evaluate().isNotEmpty) {
          await tapAndSettle(tester, find.text('Học tiếp'));
        }
      }
      await tapAndSettle(tester, find.text('Nghỉ 5 phút'));
    }

    testWidgets('a new student studies in the café and the owner greets them', (tester) async {
      await startSession(tester);

      expect(find.byType(SeaCafeScene), findsOneWidget);
      expect(find.byType(SeaScene), findsNothing);
      expect(find.text('Rùa · Chủ quán'), findsOneWidget);
      expect(find.text(AppStrings.cafeStarted.first), findsOneWidget);

      await quiet(tester);
      expectNoneOf(AppStrings.cafeStarted);
    });

    testWidgets('a friend welcomes the student back after a distraction', (tester) async {
      await startSession(tester);
      await quiet(tester);

      await leaveAppFor(tester, const Duration(seconds: 10));

      expectOneOf(AppStrings.cafeReturned);
    });

    testWidgets('friends talk when a break starts and when it ends', (tester) async {
      await startSession(tester);
      await takeBreak(tester);
      expectOneOf(AppStrings.cafeBreakStarted);

      await tapAndSettle(tester, find.text('Tiếp tục'));
      expectOneOf(AppStrings.cafeBreakEnded);
    });

    testWidgets('a friend cheers halfway through', (tester) async {
      await startSession(tester);
      await quiet(tester);

      await wait(tester, const Duration(minutes: 13));
      await tester.pumpAndSettle();

      expectOneOf(AppStrings.cafeHalfway);
    });

    testWidgets('greetings show in the first minute and on a break only', (tester) async {
      await startSession(tester);
      expect(find.text(SeaCafe.greetings.first), findsOneWidget);

      await wait(tester, const Duration(seconds: 61));
      await tester.pumpAndSettle();
      expect(find.text(SeaCafe.greetings.first), findsNothing);

      await takeBreak(tester);
      expect(find.text(SeaCafe.greetings.first), findsOneWidget);
    });

    testWidgets('a greeting is said by Gret and gets a reply', (tester) async {
      await startSession(tester);
      await quiet(tester);

      await tapAndSettle(tester, find.text(SeaCafe.greetings.first));
      expect(find.text(SeaCafe.greetings.first), findsNWidgets(2), reason: 'chip and bubble');
      expectNoneOf(AppStrings.cafeReplies.first);

      // A short exchange: the friend replies once Gret has spoken, so the bubbles never overlap.
      await tester.pump(AppMotion.cafeReplyDelay);
      await tester.pumpAndSettle();
      expect(find.text(SeaCafe.greetings.first), findsOneWidget, reason: 'only the chip');
      expectOneOf(AppStrings.cafeReplies.first);
    });

    testWidgets('coming back to the session later does not greet again', (tester) async {
      await startSession(tester);
      await quiet(tester);
      await wait(tester, const Duration(minutes: 2));

      await tapAndSettle(tester, find.byTooltip('Quay lại'));
      await tapAndSettle(tester, find.byKey(const ValueKey('running-session-banner')));

      expect(find.byType(SeaCafeScene), findsOneWidget);
      expectNoneOf(AppStrings.cafeStarted);
    });

    testWidgets("with Gret's sea chosen, the session takes place in the sea", (tester) async {
      await StudyPlaceRepository().save(StudyPlace.sea);
      await startSession(tester);

      expect(find.byType(SeaScene), findsOneWidget);
      expect(find.byType(SeaCafeScene), findsNothing);
    });

    testWidgets('a session saved in the café records it', (tester) async {
      await startSession(tester);
      await wait(tester, const Duration(minutes: 26));
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('Lưu'));

      expect(SessionRepository().getAll().single.place, StudyPlace.cafe);
    });
  });
}
