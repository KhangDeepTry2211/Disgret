// 5.1 Điều hướng 3 tab, lối vào học duy nhất và đường quay lại phiên đang chạy (spec 001).
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/providers/focus_session_provider.dart';
import 'package:focus_app/services/study_starter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const Goal _goal = Goal(id: 'g1', title: 'Đỗ đại học', reason: 'Vì tương lai');
const Habit _math = Habit(id: 'h1', goalId: 'g1', name: 'Ôn Toán', minMinutesPerDay: 30);
const Habit _read = Habit(id: 'h2', goalId: 'g1', name: 'Đọc sách', minMinutesPerDay: 15);

/// Regular phone so every control fits.
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
    await HabitRepository().save(_math);
    await HabitRepository().save(_read);
  });

  tearDown(() async {
    await Hive.close();
  });

  Future<void> openApp(WidgetTester tester, {FakeNativeBridge? native}) =>
      pumpApp(tester, size: _phone, clock: () => now, native: native);

  /// A mounted Consumer below the router: usable both as BuildContext and as WidgetRef.
  Element consumer(WidgetTester tester) => find
      .byWidgetPredicate((widget) => widget is ConsumerWidget || widget is ConsumerStatefulWidget)
      .evaluate()
      .last;

  FocusSessionState session(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
          .read(focusSessionProvider);

  group('StudyStarter', () {
    testWidgets('starts one session for the plan habit and opens the running session', (
      tester,
    ) async {
      await openApp(tester);
      final element = consumer(tester);

      await StudyStarter.start(element, element as WidgetRef, minutes: 30);
      await tester.pumpAndSettle();

      expect(session(tester).phase, FocusPhase.running);
      expect(session(tester).habit?.id, _math.id);
      expect(session(tester).plannedMinutes, 30);
      expect(find.text('Thời gian còn lại'), findsOneWidget);
    });

    testWidgets('called twice never creates a second session', (tester) async {
      final native = FakeNativeBridge()..permissionsGate = Completer<void>();
      await openApp(tester, native: native);
      final element = consumer(tester);
      final ref = element as WidgetRef;

      final first = StudyStarter.start(element, ref, minutes: 30);
      final second = StudyStarter.start(element, ref, minutes: 5);
      native.permissionsGate!.complete();
      await first;
      await second;
      await tester.pumpAndSettle();

      expect(session(tester).plannedMinutes, 30);
      expect(native.guardStarts, hasLength(1));

      // Calling again while running only opens the session.
      final current = consumer(tester);
      await StudyStarter.start(current, current as WidgetRef, minutes: 5);
      await tester.pumpAndSettle();
      expect(session(tester).plannedMinutes, 30);
      expect(native.guardStarts, hasLength(1));
    });
  });
}
