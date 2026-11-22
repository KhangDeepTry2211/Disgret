// 5.1 Điều hướng 3 tab, lối vào học duy nhất và đường quay lại phiên đang chạy (spec 001).
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_log_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/providers/focus_session_provider.dart';
import 'package:focus_app/services/native_bridge.dart';
import 'package:focus_app/services/study_starter.dart';
import 'package:focus_app/widgets/gradient_pill_button.dart';
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

  group('US1: Hôm nay and the single study entry', () {
    testWidgets('shows goal, next habit, minutes, streak and exactly one study control', (
      tester,
    ) async {
      await openApp(tester);

      expect(find.text('Đỗ đại học'), findsOneWidget);
      expect(find.text('Ôn Toán'), findsOneWidget);
      expect(find.text('30 phút'), findsOneWidget);
      expect(find.bySemanticsLabel('Chuỗi 0 ngày học liên tiếp'), findsOneWidget);
      // SC-002: one control leads into a session; no habit list, no second start link.
      expect(find.byType(GradientPillButton), findsOneWidget);
      expect(find.textContaining('Bắt đầu'), findsOneWidget);
      expect(find.text('Bỏ qua, vào học luôn'), findsNothing);
      expect(find.text('Đọc sách'), findsNothing);
    });

    testWidgets('"Bắt đầu" opens motivation full screen; "Bỏ qua" runs the plan in 2 taps', (
      tester,
    ) async {
      await openApp(tester);

      await tapAndSettle(tester, find.text('Bắt đầu'));
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Bắt đầu 30 phút'), findsOneWidget);

      await tapAndSettle(tester, find.text('Bỏ qua'));
      expect(session(tester).phase, FocusPhase.running);
      expect(session(tester).habit?.id, _math.id);
      expect(session(tester).plannedMinutes, 30);
      expect(find.text('30:00'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('settings icon opens Cài đặt with its other entries (FR-015)', (tester) async {
      await openApp(tester);

      await tapAndSettle(tester, find.byTooltip('Cài đặt'));
      for (final entry in [
        'Làm lại quiz động lực',
        'Quyền cho Reset break',
        'Ứng dụng cần nhắc',
        'Chế độ demo',
        'Tạo dữ liệu mẫu',
      ]) {
        await tester.scrollUntilVisible(find.text(entry), 200);
        expect(find.text(entry), findsOneWidget, reason: entry);
      }
    });

    testWidgets('noGoal: a single create-goal call and no start button', (tester) async {
      await GoalRepository().delete(_goal.id);
      await openApp(tester);

      expect(find.text('Tạo mục tiêu đầu tiên'), findsOneWidget);
      expect(find.textContaining('Bắt đầu'), findsNothing);
    });

    testWidgets('noHabit: a single add-habit call and no start button', (tester) async {
      await HabitRepository().delete(_math.id);
      await HabitRepository().delete(_read.id);
      await openApp(tester);

      expect(find.text('Thêm thói quen'), findsOneWidget);
      expect(find.textContaining('Bắt đầu'), findsNothing);
    });

    testWidgets('allDoneToday: says so, extra session is a secondary action', (tester) async {
      for (final habit in [_math, _read]) {
        await HabitLogRepository().markDone(habit, now);
      }
      await openApp(tester);

      expect(find.text('Hôm nay bạn đã xong hết!'), findsOneWidget);
      expect(find.byType(GradientPillButton), findsNothing);
      await tapAndSettle(tester, find.text('Học thêm một phiên'));
      expect(find.text('Bắt đầu 30 phút'), findsOneWidget, reason: 'First habit, its minutes');
    });

    testWidgets('restDay: says so and still allows an optional session', (tester) async {
      // Today (2/3/2026) is a Monday; both habits are due only on Tuesdays.
      for (final habit in [_math, _read]) {
        await HabitRepository().save(
          Habit(
            id: habit.id,
            goalId: habit.goalId,
            name: habit.name,
            minMinutesPerDay: habit.minMinutesPerDay,
            repeat: HabitRepeat.weekly,
            weekdays: const [DateTime.tuesday],
          ),
        );
      }
      await openApp(tester);

      expect(find.text('Hôm nay là ngày nghỉ theo lịch'), findsOneWidget);
      expect(find.text('Học thêm một phiên'), findsOneWidget);
    });
  });

  group('US2: way back to a running session', () {
    Future<void> startAndLeave(WidgetTester tester, {FakeNativeBridge? native}) async {
      await openApp(tester, native: native);
      await tapAndSettle(tester, find.text('Bắt đầu'));
      await tapAndSettle(tester, find.text('Bỏ qua'));
      await tapAndSettle(tester, find.byTooltip('Quay lại'));
    }

    Finder banner() => find.byKey(const ValueKey('running-session-banner'));

    testWidgets('banner on every tab shows habit and time, opens the session in 1 tap', (
      tester,
    ) async {
      await startAndLeave(tester);

      for (final tab in ['Hôm nay', 'Thói quen', 'Tiến độ']) {
        await tapAndSettle(tester, find.widgetWithText(NavigationDestination, tab));
        expect(banner(), findsOneWidget, reason: tab);
        expect(find.descendant(of: banner(), matching: find.text('Ôn Toán')), findsOneWidget);
        expect(find.text('Còn 30:00'), findsOneWidget, reason: tab);
      }

      await tapAndSettle(tester, banner());
      expect(find.text('Thời gian còn lại'), findsOneWidget);
    });

    testWidgets('"Bắt đầu" while running opens the running session, no second one', (tester) async {
      final native = FakeNativeBridge();
      await startAndLeave(tester, native: native);

      await tapAndSettle(tester, find.text('Bắt đầu'));
      expect(find.text('Thời gian còn lại'), findsOneWidget);
      expect(native.guardStarts, hasLength(1));
    });

    testWidgets('native resume_focus opens the running session', (tester) async {
      final native = FakeNativeBridge();
      await startAndLeave(tester, native: native);

      native.emit(NativeAction.resumeFocus);
      await tester.pumpAndSettle();
      expect(find.text('Thời gian còn lại'), findsOneWidget);
    });

    testWidgets('native open_reels_distracted opens motivation in its distracted form', (
      tester,
    ) async {
      final native = FakeNativeBridge();
      await startAndLeave(tester, native: native);

      native.emit(NativeAction.openReelsDistracted);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Quay lại học'), findsOneWidget);
      expect(session(tester).isPaused, isTrue, reason: 'Clock pauses while motivating (FR-010)');

      await tapAndSettle(tester, find.text('Quay lại học'));
      expect(find.text('Thời gian còn lại'), findsOneWidget);
      expect(session(tester).isPaused, isFalse);
    });

    testWidgets('native break_ended shows the running session again', (tester) async {
      final native = FakeNativeBridge();
      await startAndLeave(tester, native: native);

      native.emit(NativeAction.breakStarted, minutes: 5);
      await tester.pumpAndSettle();
      expect(find.text('Đang nghỉ'), findsOneWidget);

      now = now.add(const Duration(minutes: 5));
      native.emit(NativeAction.breakEnded);
      await tester.pumpAndSettle();
      expect(find.text('Thời gian còn lại'), findsOneWidget);
    });
  });
}
