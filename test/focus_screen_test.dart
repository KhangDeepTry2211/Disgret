// 3.1–3.4 Kiểm thử giao diện phiên học: kế hoạch trên Hôm nay, bắt đầu qua bước động lực,
// phản hồi nhắc, động lực trong phiên, màn Tổng kết (spec 001).
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/event.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/reel.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/event_repository.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/data/repositories/session_repository.dart';
import 'package:focus_app/router/app_router.dart';
import 'package:focus_app/screens/main_shell.dart';
import 'package:focus_app/widgets/progress_ring.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const Goal _goal = Goal(id: 'g1', title: 'Mục tiêu', reason: 'Lý do');
const Habit _habit = Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 25);
const Habit _otherHabit = Habit(id: 'h2', goalId: 'g1', name: 'Làm đề', minMinutesPerDay: 5);

/// Điện thoại cỡ thường để các nút nằm gọn trong màn hình.
const Size _phone = Size(412, 915);

void main() {
  late DateTime now;
  late List<bool> screenAwakeCalls;
  late List<MethodCall> platformCalls;

  /// Cho đồng hồ giả chạy rồi đợi một nhịp cập nhật.
  Future<void> wait(WidgetTester tester, Duration duration) async {
    now = now.add(duration);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> openApp(WidgetTester tester) =>
      pumpApp(tester, size: _phone, clock: () => now, onScreenAwakeChanged: screenAwakeCalls.add);

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(NavigationDestination, label));
    await tester.pumpAndSettle();
  }

  /// Đổi số phút của phiên tiếp theo ở Hôm nay ("Đổi thói quen hoặc thời lượng").
  Future<void> changePlanMinutes(WidgetTester tester, int minutes) async {
    await tapAndSettle(tester, find.text('Đổi thói quen hoặc thời lượng'));
    await tapAndSettle(tester, find.text('$minutes phút').last);
    await tapAndSettle(tester, find.text('Dùng kế hoạch này'));
  }

  /// Hôm nay → "Bắt đầu" → bước động lực → "Bỏ qua": phiên chạy với kế hoạch của Hôm nay.
  Future<void> startSession(WidgetTester tester, {int minutes = 25}) async {
    await openApp(tester);
    if (minutes != 25) await changePlanMinutes(tester, minutes);
    await tapAndSettle(tester, find.text('Bắt đầu'));
    await tapAndSettle(tester, find.text('Bỏ qua'));
  }

  /// Chạm dải "phiên đang chạy" trên thanh tab.
  Future<void> openRunningSession(WidgetTester tester) =>
      tapAndSettle(tester, find.byKey(const ValueKey('running-session-banner')));

  /// Rời app rồi quay lại sau khoảng thời gian cho trước.
  Future<void> leaveAppFor(WidgetTester tester, Duration duration) async {
    hideApp(tester);
    now = now.add(duration);
    showApp(tester);
    await tester.pumpAndSettle();
  }

  /// Tạo đủ số lần xao nhãng, đóng các sheet nhắc ở giữa.
  Future<void> distract(WidgetTester tester, int times) async {
    for (var i = 0; i < times; i++) {
      await leaveAppFor(tester, const Duration(seconds: 10));
      if (i < times - 1 && find.text('Học tiếp').evaluate().isNotEmpty) {
        await tester.tap(find.text('Học tiếp'));
        await tester.pumpAndSettle();
      }
    }
  }

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    await openMemoryBoxes();
    now = DateTime(2026, 3, 2, 9);
    screenAwakeCalls = [];
    platformCalls = [];
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
    await ProfileRepository().completeOnboarding(
      const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
    );
    await GoalRepository().save(_goal);
    await HabitRepository().save(_habit);
    await HabitRepository().save(_otherHabit);
  });

  tearDown(() async {
    await Hive.close();
  });

  /// Các kiểu rung đã gửi xuống hệ thống.
  List<Object?> vibrations() => platformCalls
      .where((call) => call.method == 'HapticFeedback.vibrate')
      .map((call) => call.arguments)
      .toList();

  /// Ghi lại các lệnh rung và âm báo gửi xuống hệ thống.
  void recordPlatformCalls(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      platformCalls.add(call);
      return null;
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
  }

  group('3.1 Kế hoạch phiên trên Hôm nay', () {
    testWidgets('Sheet đổi kế hoạch: thói quen hôm nay, 25 phút, các mức 5/25/45', (tester) async {
      await openApp(tester);
      expect(find.text('25 phút'), findsOneWidget);

      await tapAndSettle(tester, find.text('Đổi thói quen hoặc thời lượng'));
      expect(find.text('Phiên học tiếp theo'), findsOneWidget);
      expect(find.text('Ôn bài'), findsWidgets);
      expect(find.text('5 phút'), findsOneWidget);
      expect(find.text('45 phút'), findsOneWidget);
      expect(find.text('Tự nhập'), findsOneWidget);
      expect(find.text('Dùng kế hoạch này'), findsOneWidget);
    });

    testWidgets('Chọn thói quen khác và thời lượng rồi bắt đầu (chỉ cho một phiên)', (
      tester,
    ) async {
      await openApp(tester);
      await tapAndSettle(tester, find.text('Đổi thói quen hoặc thời lượng'));
      await tapAndSettle(tester, find.byType(DropdownButtonFormField<String>));
      await tapAndSettle(tester, find.text('Làm đề').last);
      await tapAndSettle(tester, find.text('45 phút'));
      await tapAndSettle(tester, find.text('Dùng kế hoạch này'));

      expect(find.text('Làm đề'), findsOneWidget);
      expect(find.text('45 phút'), findsOneWidget);

      await tapAndSettle(tester, find.text('Bắt đầu'));
      await finishReel(tester);
      expect(find.text('Bắt đầu 45 phút'), findsOneWidget);
      await tapAndSettle(tester, find.text('Bắt đầu 45 phút'));

      expect(find.text('Làm đề'), findsOneWidget);
      expect(find.text('45:00'), findsOneWidget);
      expect(find.text('Thời gian còn lại'), findsOneWidget);

      // Lựa chọn chỉ dùng cho phiên này: Hôm nay quay về kế hoạch mặc định.
      await tapAndSettle(tester, find.byTooltip('Quay lại'));
      expect(find.text('Ôn bài'), findsOneWidget);
      expect(find.text('25 phút'), findsOneWidget);
    });

    testWidgets('Tự nhập số phút: chặn giá trị sai, nhận giá trị đúng', (tester) async {
      await openApp(tester);
      await tapAndSettle(tester, find.text('Đổi thói quen hoặc thời lượng'));
      await tapAndSettle(tester, find.text('Tự nhập'));

      for (final invalid in ['', '0', '481']) {
        await tester.enterText(find.widgetWithText(TextFormField, 'Số phút'), invalid);
        await tapAndSettle(tester, find.text('Dùng kế hoạch này'));
        expect(find.text('Nhập số phút từ 1 đến 480'), findsOneWidget, reason: 'nhập "$invalid"');
      }

      await tester.enterText(find.widgetWithText(TextFormField, 'Số phút'), '7');
      await tapAndSettle(tester, find.text('Dùng kế hoạch này'));
      expect(find.text('7 phút'), findsOneWidget);

      await tapAndSettle(tester, find.text('Bắt đầu'));
      await tapAndSettle(tester, find.text('Bỏ qua'));
      expect(find.text('07:00'), findsOneWidget);
    });

    testWidgets('Không có phiên thì không mở được màn phiên học, về Hôm nay', (tester) async {
      await openApp(tester);

      GoRouter.of(tester.element(find.byType(MainShell))).go(AppRoutes.focus);
      await tester.pumpAndSettle();

      expect(find.text('Thời gian còn lại'), findsNothing);
      expect(find.text('Bắt đầu'), findsOneWidget);
    });

    testWidgets('Đồng hồ chạy theo mốc thời gian, vòng tiến độ tăng dần', (tester) async {
      await startSession(tester);
      expect(find.text('25:00'), findsOneWidget);
      expect(tester.widget<ProgressRing>(find.byType(ProgressRing)).progress, 0);

      await wait(tester, const Duration(minutes: 10));

      expect(find.text('15:00'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget, reason: 'Tập trung thực');
      expect(tester.widget<ProgressRing>(find.byType(ProgressRing)).progress, closeTo(0.4, 0.001));
    });

    testWidgets('Thời gian còn lại và tập trung thực cộng lại đúng bằng thời lượng', (
      tester,
    ) async {
      await startSession(tester);

      await wait(tester, const Duration(minutes: 2, seconds: 19, milliseconds: 500));

      expect(find.text('22:41'), findsOneWidget, reason: 'Còn 22:40,5 làm tròn lên');
      expect(find.text('02:19'), findsOneWidget, reason: 'Đã qua 2:19,5 cắt phần lẻ');
    });

    testWidgets('Giữ màn hình sáng khi chạy, tắt khi kết thúc', (tester) async {
      await startSession(tester);
      expect(screenAwakeCalls.last, isTrue);

      await wait(tester, const Duration(minutes: 25));
      await tester.pumpAndSettle();
      expect(screenAwakeCalls.last, isFalse);
    });

    testWidgets('Rời màn phiên sang các tab: phiên vẫn chạy, dải trên thanh tab đưa về', (
      tester,
    ) async {
      await startSession(tester);

      await tapAndSettle(tester, find.byTooltip('Quay lại'));
      await tapTab(tester, 'Thói quen');
      now = now.add(const Duration(minutes: 5));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Còn 20:00'), findsOneWidget);

      await openRunningSession(tester);
      expect(find.text('20:00'), findsOneWidget);
    });

    testWidgets('Hết giờ khi đang ở tab khác vẫn chuyển sang Tổng kết', (tester) async {
      await startSession(tester);
      await tapAndSettle(tester, find.byTooltip('Quay lại'));
      await tapTab(tester, 'Thói quen');

      now = now.add(const Duration(minutes: 25));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Tổng kết'), findsOneWidget);
    });

    testWidgets('Kết thúc sớm: hỏi xác nhận, Huỷ thì chạy tiếp, đồng ý thì sang Tổng kết', (
      tester,
    ) async {
      await startSession(tester);
      await wait(tester, const Duration(minutes: 3));

      await tapAndSettle(tester, find.text('Kết thúc sớm'));
      expect(find.text('Kết thúc sớm?'), findsOneWidget);
      await tapAndSettle(tester, find.text('Huỷ'));
      expect(find.text('Thời gian còn lại'), findsOneWidget);

      await tapAndSettle(tester, find.text('Kết thúc sớm'));
      await tapAndSettle(tester, find.text('Kết thúc'));

      expect(find.text('Tổng kết'), findsOneWidget);
      expect(find.text('Đã ghi nhận phiên học'), findsOneWidget);
      expect(find.text('3 phút'), findsOneWidget, reason: 'Thời gian tập trung');
      expect(find.text('25 phút'), findsOneWidget, reason: 'Thời lượng đã đặt');
    });
  });

  group('Bắt đầu từ bước động lực', () {
    testWidgets('"Chỉ 5 phút thôi" bắt đầu phiên 5 phút cho thói quen của Hôm nay', (tester) async {
      await openApp(tester);
      await tapAndSettle(tester, find.text('Bắt đầu'));
      await finishReel(tester);
      await tapAndSettle(tester, find.text('Chỉ 5 phút thôi'));

      expect(find.text('05:00'), findsOneWidget);
      expect(find.text('Ôn bài'), findsOneWidget);
    });

    testWidgets('"Bắt đầu N phút" dùng đúng số phút của kế hoạch', (tester) async {
      await openApp(tester);
      await tapAndSettle(tester, find.text('Bắt đầu'));
      await finishReel(tester);
      await tester.tap(find.text('Bắt đầu 25 phút'));
      await tester.pumpAndSettle();

      expect(find.text('25:00'), findsOneWidget);
    });

    testWidgets('Đóng bước động lực thì về Hôm nay, không bắt đầu phiên', (tester) async {
      await openApp(tester);
      await tapAndSettle(tester, find.text('Bắt đầu'));
      await tapAndSettle(tester, find.byTooltip('Đóng'));

      expect(find.text('Bắt đầu'), findsOneWidget);
      expect(find.byKey(const ValueKey('running-session-banner')), findsNothing);
    });

    testWidgets('Đang có phiên thì "Bắt đầu" trên Hôm nay mở đúng phiên đó', (tester) async {
      await startSession(tester);
      await wait(tester, const Duration(minutes: 5));
      await tapAndSettle(tester, find.byTooltip('Quay lại'));

      await tapAndSettle(tester, find.text('Bắt đầu'));

      expect(find.text('20:00'), findsOneWidget);
      expect(SessionRepository().getAll(), isEmpty);
    });

    testWidgets('Xong phiên, về Hôm nay không tự bắt đầu phiên mới', (tester) async {
      await startSession(tester, minutes: 5);
      now = now.add(const Duration(minutes: 5));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('Về Hôm nay'));

      expect(find.text('Bắt đầu'), findsOneWidget);
      expect(find.byType(ProgressRing), findsNothing);
      expect(find.byKey(const ValueKey('running-session-banner')), findsNothing);
    });
  });

  group('3.2 Hiện số liệu lơ là', () {
    testWidgets('Rời 1 phút: đếm 1 lần xao nhãng, tập trung thực không tính phần ở ngoài', (
      tester,
    ) async {
      await startSession(tester);
      await wait(tester, const Duration(minutes: 5));

      await leaveAppFor(tester, const Duration(minutes: 1));

      expect(find.text('19:00'), findsOneWidget, reason: 'Đồng hồ vẫn chạy khi app bị ẩn');
      expect(find.text('05:00'), findsOneWidget, reason: 'Tập trung thực');
      expect(find.text('1'), findsOneWidget, reason: 'Số lần xao nhãng');
    });

    testWidgets('Rời 2 giây: không đếm, không nhắc gì', (tester) async {
      await startSession(tester);

      await leaveAppFor(tester, const Duration(seconds: 2));

      expect(find.text('0'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      // "Bỏ qua" logs motivation_skipped (spec 002); no distraction is logged.
      expect(
        EventRepository().getAll().where((event) => event.type == EventType.sessionDistracted),
        isEmpty,
      );
    });

    testWidgets('Kéo thanh thông báo (chỉ inactive, không hidden) thì không tính', (tester) async {
      await startSession(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      now = now.add(const Duration(seconds: 30));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('3.3 Phản hồi nhắc', () {
    testWidgets('Lần 1: rung nhẹ và SnackBar, không có bottom sheet', (tester) async {
      recordPlatformCalls(tester);
      await startSession(tester);

      await leaveAppFor(tester, const Duration(seconds: 10));

      expect(find.text('Chào mừng quay lại! Tiếp tục nào 💪'), findsOneWidget);
      expect(find.text('Học tiếp'), findsNothing);
      expect(vibrations(), contains('HapticFeedbackType.lightImpact'));
    });

    testWidgets('Lần 2: bottom sheet hỏi, ghi rõ thời gian đã rời đi', (tester) async {
      await startSession(tester);
      await distract(tester, 1);

      await leaveAppFor(tester, const Duration(minutes: 2));

      expect(find.text('Bạn vừa rời đi 2 phút. Xem 1 reel động lực rồi quay lại?'), findsOneWidget);
      expect(find.text('Xem reel'), findsOneWidget);
      expect(find.text('Học tiếp'), findsOneWidget);
      expect(find.text('Có vẻ bạn mệt rồi, nghỉ 5 phút nhé?'), findsNothing);
    });

    testWidgets('Rời dưới 1 phút thì ghi bằng giây, không ghi "0 phút"', (tester) async {
      await startSession(tester);
      await distract(tester, 1);

      await leaveAppFor(tester, const Duration(seconds: 45));

      expect(
        find.text('Bạn vừa rời đi 45 giây. Xem 1 reel động lực rồi quay lại?'),
        findsOneWidget,
      );
    });

    testWidgets('"Học tiếp" đóng sheet, phiên chạy tiếp', (tester) async {
      await startSession(tester);
      await distract(tester, 2);

      await tapAndSettle(tester, find.text('Học tiếp'));

      expect(find.text('Thời gian còn lại'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('Lại rời đi khi sheet đang mở: không chồng thêm sheet', (tester) async {
      await startSession(tester);
      await distract(tester, 2);

      await leaveAppFor(tester, const Duration(seconds: 10));

      expect(find.text('Xem reel'), findsOneWidget);
    });

    testWidgets('Lần 4: có thêm gợi ý nghỉ; chọn nghỉ thì phiên tạm dừng, bấm tiếp tục thì chạy', (
      tester,
    ) async {
      await startSession(tester);
      await distract(tester, 4);

      expect(find.text('Có vẻ bạn mệt rồi, nghỉ 5 phút nhé?'), findsOneWidget);

      await tapAndSettle(tester, find.text('Nghỉ 5 phút'));
      expect(find.text('Đang nghỉ – còn 05:00'), findsOneWidget);
      final remaining = tester.widgetList<Text>(find.textContaining(':')).first.data;

      await wait(tester, const Duration(minutes: 3));
      expect(find.text(remaining!), findsOneWidget, reason: 'Đồng hồ đứng yên khi nghỉ');
      expect(find.text('Đang nghỉ – còn 02:00'), findsOneWidget);

      await tapAndSettle(tester, find.text('Tiếp tục'));
      expect(find.text('Thời gian còn lại'), findsOneWidget);
    });

    testWidgets('Ghi sự kiện session_distracted cho từng lần', (tester) async {
      await startSession(tester);
      await distract(tester, 2);

      final events = EventRepository()
          .getAll()
          .where((event) => event.type == EventType.sessionDistracted)
          .toList();
      expect(events.map((event) => event.meta[SessionDistractedMeta.distractionIndex]), [1, 2]);
      expect(events.first.meta[SessionDistractedMeta.awaySeconds], 10);
    });
  });

  group('3.3 Xem reel trong phiên', () {
    Future<void> openReelFromNudge(WidgetTester tester) async {
      await startSession(tester);
      await wait(tester, const Duration(minutes: 1));
      await distract(tester, 2);
      await tapAndSettle(tester, find.text('Xem reel'));
    }

    testWidgets('Mở bước động lực ngữ cảnh "distracted", nút đổi thành "Quay lại học"', (
      tester,
    ) async {
      await openReelFromNudge(tester);

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Quay lại học'), findsOneWidget);
      expect(find.text('Bắt đầu 25 phút'), findsNothing);
      expect(find.text('Chỉ 5 phút thôi'), findsNothing);
      expect(find.text('Bỏ qua'), findsNothing);
      // Ngữ cảnh distracted: r6 được ghim nên luôn đứng đầu, không phải r1 của ngữ cảnh start.
      expect(find.text('Get back to work!'), findsOneWidget);
    });

    testWidgets('Xem reel: đồng hồ dừng; "Quay lại học" về đúng phiên cũ, không tạo phiên mới', (
      tester,
    ) async {
      await openReelFromNudge(tester);
      // 1 phút ở trong + 2 lần rời 10 giây = còn 23:40.

      now = now.add(const Duration(minutes: 3));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Quay lại học'));
      await tester.pumpAndSettle();

      expect(find.text('23:40'), findsOneWidget);
      expect(find.text('2'), findsOneWidget, reason: 'Xem reel không thêm lần xao nhãng');
      expect(find.text('Thời gian còn lại'), findsOneWidget);
    });

    testWidgets('Đóng bước động lực bằng nút X thay vì nút: đồng hồ cũng chạy lại', (tester) async {
      await openReelFromNudge(tester);

      await tapAndSettle(tester, find.byTooltip('Đóng'));
      now = now.add(const Duration(minutes: 1));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('22:40'), findsOneWidget);
    });

    testWidgets('Bắt đầu từ thẻ thói quen khi đang có phiên: về phiên, không mở động lực', (
      tester,
    ) async {
      await startSession(tester);
      await tapAndSettle(tester, find.byTooltip('Quay lại'));
      await tapTab(tester, 'Thói quen');

      await tester.longPress(find.text('Làm đề'));
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('Bắt đầu Focus'));

      expect(find.text('Quay lại học'), findsNothing);
      expect(find.text('Ôn bài'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);
    });

    testWidgets('Xem động lực trong phiên (native "open_reels_distracted"): dừng đồng hồ', (
      tester,
    ) async {
      await startSession(tester);

      GoRouter.of(tester.element(find.text('Thời gian còn lại')))
          .go(AppRoutes.motivationFor(ReelContext.distracted));
      await tester.pumpAndSettle();
      expect(find.text('Quay lại học'), findsOneWidget);
      now = now.add(const Duration(minutes: 3));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Quay lại học'));
      await tester.pumpAndSettle();

      expect(find.text('25:00'), findsOneWidget);
    });

    testWidgets('Không có phiên: thẻ kết thúc có "Bắt đầu N phút", "Chỉ 5 phút thôi" và "Bỏ qua"', (
      tester,
    ) async {
      await openApp(tester);
      await tapAndSettle(tester, find.text('Bắt đầu'));
      await finishReel(tester);

      expect(find.text('Bắt đầu 25 phút'), findsOneWidget);
      expect(find.text('Chỉ 5 phút thôi'), findsOneWidget);
      expect(find.text('Bỏ qua'), findsOneWidget);
      expect(find.text('Quay lại học'), findsNothing);
    });

    testWidgets('Lượt xem reel trong phiên không được ghi startedFocus', (tester) async {
      await openReelFromNudge(tester);

      await tester.tap(find.text('Quay lại học'));
      await tester.pumpAndSettle();

      final watched = EventRepository().getAll().where(
        (event) => event.type == EventType.reelWatched,
      );
      expect(watched.where((event) => event.meta.containsKey(ReelWatchMeta.startedFocus)), isEmpty);
    });
  });

  group('3.4 Tổng kết phiên', () {
    Future<void> finishSession(WidgetTester tester, {int minutes = 25}) async {
      await wait(tester, Duration(minutes: minutes));
      await tester.pumpAndSettle();
    }

    testWidgets('Hết giờ: báo rung và chuyển sang Tổng kết với số liệu thật', (tester) async {
      recordPlatformCalls(tester);
      await startSession(tester);
      await wait(tester, const Duration(minutes: 5));
      await leaveAppFor(tester, const Duration(minutes: 1));
      await finishSession(tester, minutes: 19);

      expect(find.text('Làm tốt lắm!'), findsOneWidget);
      expect(find.text('24 phút'), findsOneWidget, reason: 'Thời gian tập trung');
      expect(find.text('25 phút'), findsOneWidget, reason: 'Thời lượng đã đặt');
      expect(find.text('1'), findsOneWidget);
      expect(find.text('1 phút'), findsOneWidget);
      expect(vibrations(), contains('HapticFeedbackType.heavyImpact'));
    });

    testWidgets('Kết thúc sớm thì không có âm báo hết giờ', (tester) async {
      recordPlatformCalls(tester);
      await startSession(tester);

      await tapAndSettle(tester, find.text('Kết thúc sớm'));
      await tapAndSettle(tester, find.text('Kết thúc'));

      expect(find.text('Tổng kết'), findsOneWidget);
      expect(vibrations(), isNot(contains('HapticFeedbackType.heavyImpact')));
    });

    testWidgets('Đánh giá sao và ghi chú, bấm Lưu thì lưu phiên và hiện +1 ngày streak', (
      tester,
    ) async {
      await startSession(tester);
      await finishSession(tester);
      expect(find.bySemanticsLabel('Chuỗi 0 ngày học liên tiếp'), findsOneWidget);
      expect(SessionRepository().getAll(), isEmpty, reason: 'Chưa bấm Lưu');

      await tapAndSettle(tester, find.byTooltip('4 sao'));
      await tester.enterText(find.byType(TextField), 'Học rất tốt');
      await tapAndSettle(tester, find.text('Lưu'));

      final session = SessionRepository().getAll().single;
      expect(session.selfRating, 4);
      expect(session.note, 'Học rất tốt');
      expect(session.focusedSeconds, 25 * 60);

      expect(find.text('+1 ngày streak 🔥'), findsOneWidget);
      expect(find.bySemanticsLabel('Chuỗi 1 ngày học liên tiếp'), findsOneWidget);
      expect(find.text('Lưu'), findsNothing, reason: 'Đã lưu thì không lưu lại nữa');
    });

    testWidgets('Phiên chưa đủ phút tối thiểu: không báo +1, streak giữ nguyên', (tester) async {
      await startSession(tester, minutes: 5);
      await finishSession(tester, minutes: 5);

      await tapAndSettle(tester, find.text('Lưu'));

      expect(find.text('+1 ngày streak 🔥'), findsNothing);
      expect(find.bySemanticsLabel('Chuỗi 0 ngày học liên tiếp'), findsOneWidget);
    });

    testWidgets('Về Hôm nay mà chưa bấm Lưu: vẫn lưu, không mất giờ học', (tester) async {
      await startSession(tester);
      await finishSession(tester);

      await tapAndSettle(tester, find.text('Về Hôm nay'));

      expect(SessionRepository().getAll(), hasLength(1));
      // "Ôn bài" đã đủ phút nên kế hoạch chuyển sang thói quen tiếp theo.
      expect(find.text('Làm đề'), findsOneWidget);
      expect(find.text('Bắt đầu'), findsOneWidget);
    });

    testWidgets('Nút Back của hệ thống cũng lưu và về Hôm nay, không quay lại phiên', (
      tester,
    ) async {
      await startSession(tester);
      await finishSession(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(SessionRepository().getAll(), hasLength(1));
      expect(find.text('Tổng kết'), findsNothing);
      expect(find.text('Bắt đầu'), findsOneWidget);
    });

    testWidgets('Không có phiên vừa xong thì không vào được màn Tổng kết', (tester) async {
      await openApp(tester);

      GoRouter.of(tester.element(find.byType(MainShell))).go(AppRoutes.summary);
      await tester.pumpAndSettle();

      expect(find.text('Tổng kết'), findsNothing);
      expect(find.text('Bắt đầu'), findsOneWidget);
    });
  });

  group('Chế độ demo', () {
    testWidgets('Bật trong Cài đặt: 1 phút chỉ dài 20 giây, hết giờ và cộng streak như thật', (
      tester,
    ) async {
      await openApp(tester);
      await tapAndSettle(tester, find.byTooltip('Cài đặt'));
      await tester.scrollUntilVisible(find.text('Chế độ demo'), 200);
      await tapAndSettle(tester, find.text('Chế độ demo'));
      expect(ProfileRepository().profile?.demoMode, isTrue);
      await tapAndSettle(tester, find.byTooltip('Quay lại'));

      expect(find.text('Chế độ demo: 1 phút chỉ dài 20 giây'), findsOneWidget);
      await tapAndSettle(tester, find.text('Bắt đầu'));
      await tapAndSettle(tester, find.text('Bỏ qua'));

      await wait(tester, const Duration(seconds: 20));
      expect(find.text('24:00'), findsOneWidget);

      await wait(tester, const Duration(seconds: 480));
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('Lưu'));

      expect(find.text('25 phút'), findsNWidgets(2), reason: 'Tập trung đủ thời lượng đã đặt');
      expect(find.text('+1 ngày streak 🔥'), findsOneWidget);
    });
  });

  testWidgets('Màn nhỏ không bị tràn giao diện ở các bước của phiên', (tester) async {
    await HabitRepository().save(
      const Habit(
        id: 'h0',
        goalId: 'g1',
        name: 'Một thói quen có tên rất dài ',
        minMinutesPerDay: 5,
      ),
    );
    await pumpApp(tester, clock: () => now);
    expect(tester.takeException(), isNull);

    await tapAndSettle(tester, find.text('Bắt đầu'));
    expect(tester.takeException(), isNull);
    await tapAndSettle(tester, find.text('Bỏ qua'));
    expect(tester.takeException(), isNull);

    await tapAndSettle(tester, find.text('Kết thúc sớm'));
    await tapAndSettle(tester, find.text('Kết thúc'));
    expect(find.text('Tổng kết'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
