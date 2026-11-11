// 7.1, 2.1, 2.3 Kiểm thử phần Flutter của Reset break, với phần Kotlin được thay bằng bản giả.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/event.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/blocked_apps_repository.dart';
import 'package:focus_app/data/repositories/event_repository.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/router/app_router.dart';
import 'package:focus_app/screens/main_shell.dart';
import 'package:focus_app/services/native_bridge.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const Size _phone = Size(412, 915);

/// Ảnh PNG 1×1 hợp lệ, đủ để Image.memory không báo lỗi.
final Uint8List _icon = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

InstalledApp _app(String packageName, String name) =>
    InstalledApp(packageName: packageName, name: name, icon: _icon);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    await openMemoryBoxes();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
    await ProfileRepository().completeOnboarding(
      const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
    );
    await GoalRepository().save(const Goal(id: 'g1', title: 'Mục tiêu', reason: 'Lý do'));
    await HabitRepository().save(
      const Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 25),
    );
  });

  tearDown(() async {
    await Hive.close();
  });

  Future<void> openSettings(WidgetTester tester, FakeNativeBridge native) async {
    await pumpApp(tester, size: _phone, native: native);
    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
  }

  group('2.1 Lưu danh sách app cần nhắc', () {
    test('Chưa chỉnh thì dùng danh sách mặc định, có đủ hai package của TikTok', () {
      final packages = BlockedAppsRepository().packages;

      expect(
        packages,
        containsAll(<String>[
          'com.zhiliaoapp.musically',
          'com.ss.android.ugc.trill',
          'com.facebook.katana',
          'com.instagram.android',
          'com.google.android.youtube',
          'com.android.chrome',
        ]),
      );
      expect(packages, hasLength(6));
    });

    test('Đã lưu thì đọc lại đúng, kể cả khi tắt hết', () async {
      final repository = BlockedAppsRepository();

      await repository.save({'com.example.game'});
      expect(repository.packages, {'com.example.game'});

      await repository.save({});
      expect(repository.packages, isEmpty);
    });
  });

  group('5.1 Cài đặt', () {
    testWidgets('Có các lối vào Reset break, nút thử mở màn can thiệp', (tester) async {
      final native = FakeNativeBridge();
      await openSettings(tester, native);

      expect(find.text('Quyền cho Reset break'), findsOneWidget);
      expect(find.text('Ứng dụng cần nhắc'), findsOneWidget);

      await tester.tap(find.text('Thử màn can thiệp'));
      await tester.pumpAndSettle();

      expect(native.opened, ['intervention:TikTok']);
    });

    testWidgets('Trên web không có phần Reset break', (tester) async {
      await openSettings(tester, FakeNativeBridge(supported: false));

      expect(find.text('Reset break'), findsNothing);
      expect(find.text('Thử màn can thiệp'), findsNothing);
      expect(find.text('Chế độ demo'), findsOneWidget);
    });

    testWidgets('Trên web gõ thẳng đường dẫn Reset break thì về Trang chủ', (tester) async {
      await pumpApp(tester, size: _phone, native: FakeNativeBridge(supported: false));

      GoRouter.of(tester.element(find.byType(MainShell))).go(AppRoutes.blockedApps);
      await tester.pumpAndSettle();

      expect(find.text('Ứng dụng cần nhắc'), findsNothing);
      expect(find.text('Bắt đầu'), findsOneWidget);
    });
  });

  group('7.1 Màn quyền', () {
    Future<void> openPermissions(WidgetTester tester, FakeNativeBridge native) async {
      await openSettings(tester, native);
      await tester.tap(find.text('Quyền cho Reset break'));
      await tester.pumpAndSettle();
    }

    Finder statusIcon(String label) =>
        find.byWidgetPredicate((widget) => widget is Icon && widget.semanticLabel == label);

    testWidgets('Hiện đủ 3 quyền với lý do cần và trạng thái', (tester) async {
      await openPermissions(tester, FakeNativeBridge(usageAccess: false));

      expect(find.text('Để biết khi nào bạn mở TikTok'), findsOneWidget);
      expect(find.text('Để hiện màn nhắc đè lên app khác'), findsOneWidget);
      expect(find.text('Để nhắc khi hết giờ nghỉ'), findsOneWidget);
      expect(statusIcon('Chưa bật'), findsOneWidget);
      expect(statusIcon('Đã bật'), findsNWidgets(2));
      expect(find.text('Bật'), findsOneWidget);
    });

    testWidgets('Mỗi nút "Bật" mở đúng nơi cấp quyền', (tester) async {
      final native = FakeNativeBridge(usageAccess: false, overlay: false, notification: false);
      await openPermissions(tester, native);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Bật').at(i));
        await tester.pumpAndSettle();
      }

      expect(native.opened, ['usage', 'overlay', 'notification']);
    });

    testWidgets('Quay về app thì tự kiểm tra lại', (tester) async {
      final native = FakeNativeBridge(usageAccess: false);
      await openPermissions(tester, native);
      expect(find.text('Bật'), findsOneWidget);

      await tester.tap(find.text('Bật'));
      await tester.pumpAndSettle();
      hideApp(tester);
      native.usageAccess = true; // Người dùng bật quyền trong Cài đặt của máy.
      showApp(tester);
      await tester.pumpAndSettle();

      expect(find.text('Bật'), findsNothing);
      expect(statusIcon('Đã bật'), findsNWidgets(3));
    });
  });

  group('2.1 Màn Ứng dụng cần nhắc', () {
    final apps = [
      _app('com.example.zalo', 'Zalo'),
      _app('com.google.android.youtube', 'YouTube'),
      _app('com.example.camera', 'Camera'),
      _app('com.android.chrome', 'Chrome'),
    ];

    Future<void> openBlockedApps(WidgetTester tester) async {
      await openSettings(tester, FakeNativeBridge(apps: apps));
      await tester.tap(find.text('Ứng dụng cần nhắc'));
      await tester.pumpAndSettle();
    }

    List<String> visibleNames(WidgetTester tester) => tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .map((tile) => (tile.title! as Text).data!)
        .toList();

    testWidgets('App đang chặn xếp lên đầu, trong mỗi nhóm theo tên', (tester) async {
      await openBlockedApps(tester);

      expect(visibleNames(tester), ['Chrome', 'YouTube', 'Camera', 'Zalo']);
    });

    testWidgets('App mặc định được bật sẵn', (tester) async {
      await openBlockedApps(tester);

      final tiles = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
      expect(tiles.map((tile) => tile.value), [true, true, false, false]);
    });

    testWidgets('Bật công tắc thì lưu vào Hive, dòng đó không nhảy chỗ', (tester) async {
      await openBlockedApps(tester);

      await tester.tap(find.widgetWithText(SwitchListTile, 'Zalo'));
      await tester.pumpAndSettle();

      expect(BlockedAppsRepository().packages, contains('com.example.zalo'));
      expect(visibleNames(tester), ['Chrome', 'YouTube', 'Camera', 'Zalo']);
    });

    testWidgets('Mở lại màn thì app vừa bật được xếp lên đầu', (tester) async {
      await openBlockedApps(tester);
      await tester.tap(find.widgetWithText(SwitchListTile, 'Zalo'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ứng dụng cần nhắc'));
      await tester.pumpAndSettle();

      expect(visibleNames(tester), ['Chrome', 'YouTube', 'Zalo', 'Camera']);
    });

    testWidgets('Không có ứng dụng nào thì báo rõ', (tester) async {
      await openSettings(tester, FakeNativeBridge());
      await tester.tap(find.text('Ứng dụng cần nhắc'));
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy ứng dụng nào trên máy để nhắc.'), findsOneWidget);
    });

    testWidgets('Đọc danh sách bị lỗi thì báo rõ và chỉ cách xử lý', (tester) async {
      await openSettings(tester, _FailingAppsBridge());
      await tester.tap(find.text('Ứng dụng cần nhắc'));
      await tester.pumpAndSettle();

      expect(
        find.text('Không đọc được danh sách ứng dụng. Hãy thoát ra rồi mở lại màn này.'),
        findsOneWidget,
      );
    });
  });

  group('7.1 Trước khi bắt đầu phiên Focus', () {
    const sheetTitle = 'Bật Reset break để chặn app gây xao nhãng?';

    Future<void> pressStart(WidgetTester tester, FakeNativeBridge native) async {
      await pumpApp(tester, size: _phone, native: native);
      await tester.tap(find.widgetWithText(NavigationDestination, 'Focus'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();
    }

    testWidgets('Đủ quyền thì bắt đầu ngay và bật theo dõi', (tester) async {
      final native = FakeNativeBridge();
      await pressStart(tester, native);

      expect(find.text(sheetTitle), findsNothing);
      expect(find.text('Thời gian còn lại'), findsOneWidget);
      expect(native.isGuarding, isTrue);
    });

    testWidgets('Thiếu quyền thì hỏi trước khi bắt đầu', (tester) async {
      await pressStart(tester, FakeNativeBridge(usageAccess: false));

      expect(find.text(sheetTitle), findsOneWidget);
      expect(find.text('Cấp quyền'), findsOneWidget);
      expect(find.text('Học không cần Reset break'), findsOneWidget);
      expect(find.text('Thời gian còn lại'), findsNothing);
    });

    testWidgets('Chỉ thiếu quyền thông báo thì không hỏi', (tester) async {
      await pressStart(tester, FakeNativeBridge(notification: false));

      expect(find.text(sheetTitle), findsNothing);
      expect(find.text('Thời gian còn lại'), findsOneWidget);
    });

    testWidgets('"Cấp quyền" mở màn Quyền, phiên chưa bắt đầu', (tester) async {
      await pressStart(tester, FakeNativeBridge(overlay: false));

      await tester.tap(find.text('Cấp quyền'));
      await tester.pumpAndSettle();
      expect(find.text('Quyền cho Reset break'), findsOneWidget);

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Bắt đầu'), findsOneWidget);
      expect(find.text('Thời gian còn lại'), findsNothing);
    });

    testWidgets('"Học không cần Reset break" bắt đầu phiên, không bật theo dõi', (tester) async {
      final native = FakeNativeBridge(usageAccess: false);
      await pressStart(tester, native);

      await tester.tap(find.text('Học không cần Reset break'));
      await tester.pumpAndSettle();

      expect(find.text('Thời gian còn lại'), findsOneWidget);
      expect(native.guardStarts, isEmpty);
    });

    testWidgets('Đóng sheet thì chưa bắt đầu', (tester) async {
      await pressStart(tester, FakeNativeBridge(usageAccess: false));

      await tester.tapAt(const Offset(200, 100)); // Bấm vào vùng tối bên ngoài sheet.
      await tester.pumpAndSettle();

      expect(find.text(sheetTitle), findsNothing);
      expect(find.text('Thời gian còn lại'), findsNothing);
      expect(find.text('Bắt đầu'), findsOneWidget);
    });

    testWidgets('Bấm "Bắt đầu" hai lần liền cũng chỉ hỏi một lần', (tester) async {
      final native = FakeNativeBridge(usageAccess: false);
      await pumpApp(tester, size: _phone, native: native);
      await tester.tap(find.widgetWithText(NavigationDestination, 'Focus'));
      await tester.pumpAndSettle();

      // Giữ kết quả kiểm tra quyền lại để sheet chưa hiện khi người dùng bấm lần thứ hai.
      native.permissionsGate = Completer<void>();
      await tester.tap(find.text('Bắt đầu'));
      await tester.tap(find.text('Bắt đầu'));
      native.permissionsGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text(sheetTitle), findsOneWidget);
    });

    testWidgets('Tắt hết app cần nhắc thì không hỏi quyền', (tester) async {
      await BlockedAppsRepository().save({});

      await pressStart(tester, FakeNativeBridge(usageAccess: false));

      expect(find.text(sheetTitle), findsNothing);
      expect(find.text('Thời gian còn lại'), findsOneWidget);
    });

    testWidgets('Bắt đầu nhanh từ reel cũng hỏi khi thiếu quyền', (tester) async {
      await pumpApp(tester, size: _phone, native: FakeNativeBridge(usageAccess: false));

      GoRouter.of(tester.element(find.byType(MainShell))).go(AppRoutes.focusFor(5));
      await tester.pumpAndSettle();

      expect(find.text(sheetTitle), findsOneWidget);
      await tester.tap(find.text('Học không cần Reset break'));
      await tester.pumpAndSettle();
      expect(find.text('05:00'), findsOneWidget);
    });

    testWidgets('Kết thúc sớm trên giao diện thì tắt theo dõi', (tester) async {
      final native = FakeNativeBridge();
      await pressStart(tester, native);
      expect(native.isGuarding, isTrue);

      await tester.tap(find.text('Kết thúc sớm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kết thúc'));
      await tester.pumpAndSettle();

      expect(find.text('Tổng kết'), findsOneWidget);
      expect(native.isGuarding, isFalse);
    });
  });

  group('2.3, 2.4 Hành động từ màn can thiệp', () {
    late DateTime now;
    late FakeNativeBridge native;

    Future<void> tapTab(WidgetTester tester, String label) async {
      await tester.tap(find.widgetWithText(NavigationDestination, label));
      await tester.pumpAndSettle();
    }

    Future<void> startSession(WidgetTester tester) async {
      await pumpApp(tester, size: _phone, clock: () => now, native: native);
      await tapTab(tester, 'Focus');
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();
    }

    /// Rời app, màn chặn hiện lên, và người dùng ở đó một lúc rồi bấm một lựa chọn.
    void openBlockedApp(WidgetTester tester) {
      hideApp(tester);
      native.emit(NativeAction.interventionShown);
      now = now.add(const Duration(seconds: 15));
    }

    /// Đồng hồ giả chạy rồi đợi một nhịp cập nhật.
    Future<void> wait(WidgetTester tester, Duration duration) async {
      now = now.add(duration);
      await tester.pump(const Duration(milliseconds: 300));
    }

    setUp(() {
      now = DateTime(2026, 3, 2, 9);
      native = FakeNativeBridge();
    });

    testWidgets('"Quay lại học": về màn Focus, tính xao nhãng, không hiện sheet hay lời chào', (
      tester,
    ) async {
      await startSession(tester);
      await tapTab(tester, 'Trang chủ');

      for (var count = 1; count <= 2; count++) {
        openBlockedApp(tester);
        native.emit(NativeAction.resumeFocus);
        showApp(tester);
        await tester.pumpAndSettle();

        expect(find.text('Thời gian còn lại'), findsOneWidget);
        expect(find.text('$count'), findsOneWidget, reason: 'Số lần xao nhãng');
        expect(find.text('Xem reel'), findsNothing);
        expect(find.text('Chào mừng quay lại! Tiếp tục nào 💪'), findsNothing);
      }
    });

    testWidgets('Bấm Home ở màn chặn rồi tự mở lại DisGret cũng không nhắc thêm', (tester) async {
      await startSession(tester);
      for (var i = 0; i < 2; i++) {
        openBlockedApp(tester);
        showApp(tester); // Không có resume_focus vì không bấm nút nào trên màn chặn.
        await tester.pumpAndSettle();
      }

      expect(find.text('Xem reel'), findsNothing);
    });

    testWidgets(
      '"Xem 1 reel động lực": tới Reels, đồng hồ dừng, nút dưới video là "Quay lại học"',
      (tester) async {
        await startSession(tester);

        openBlockedApp(tester);
        native.emit(NativeAction.openReelsDistracted);
        showApp(tester);
        await tester.pumpAndSettle();

        expect(find.text('Quay lại học'), findsOneWidget);
        expect(find.text('Xem reel'), findsNothing);

        await wait(tester, const Duration(minutes: 3));
        await tester.tap(find.text('Quay lại học'));
        await tester.pumpAndSettle();

        expect(find.text('24:45'), findsOneWidget, reason: 'Thời gian xem reel không tính');
        expect(find.text('1'), findsOneWidget, reason: 'Mở app bị chặn vẫn là 1 lần xao nhãng');
      },
    );

    testWidgets('Chọn nghỉ: màn Focus hiện giờ nghỉ, hết giờ thì về lại đồng hồ thường', (
      tester,
    ) async {
      await startSession(tester);
      await tapTab(tester, 'Trang chủ');

      openBlockedApp(tester);
      native.emit(NativeAction.breakStarted, minutes: 10);
      showApp(tester);
      await tester.pumpAndSettle();
      await tapTab(tester, 'Focus');
      expect(find.text('Đang nghỉ – còn 10:00'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);

      await tapTab(tester, 'Trang chủ');
      await wait(tester, const Duration(minutes: 10));
      native.emit(NativeAction.breakEnded);
      await tester.pumpAndSettle();

      expect(find.text('Thời gian còn lại'), findsOneWidget, reason: 'Tự về màn Focus');
      expect(find.text('Tiếp tục'), findsNothing);
    });

    testWidgets('Chọn nghỉ rồi hết giờ khi vẫn ở ngoài: quay lại không bị nhắc thêm', (
      tester,
    ) async {
      await startSession(tester);

      for (var i = 0; i < 2; i++) {
        openBlockedApp(tester);
        native.emit(NativeAction.breakStarted, minutes: 5);
        now = now.add(const Duration(minutes: 5));
        native.emit(NativeAction.breakEnded);
        now = now.add(const Duration(seconds: 10));
        native.emit(NativeAction.breakEnded); // Bấm vào thông báo cũng gửi hành động này.
        showApp(tester);
        await tester.pumpAndSettle();
      }

      expect(find.text('Xem reel'), findsNothing);
      expect(find.text('Thời gian còn lại'), findsOneWidget);
    });

    testWidgets('Hết giờ đúng lúc đang ở màn chặn: "Xem reel" không làm mất màn Tổng kết', (
      tester,
    ) async {
      await startSession(tester);
      await tester.tap(find.text('Kết thúc sớm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kết thúc'));
      await tester.pumpAndSettle();

      native.emit(NativeAction.openReelsDistracted);
      await tester.pumpAndSettle();
      native.emit(NativeAction.resumeFocus);
      await tester.pumpAndSettle();

      expect(find.text('Tổng kết'), findsOneWidget);
    });

    testWidgets('Không có phiên (nút thử): "Quay lại học" ở nguyên, "Xem reel" vẫn tới Reels', (
      tester,
    ) async {
      await pumpApp(tester, size: _phone, clock: () => now, native: native);
      await tester.tap(find.byTooltip('Cài đặt'));
      await tester.pumpAndSettle();

      native.emit(NativeAction.resumeFocus);
      await tester.pumpAndSettle();
      expect(find.text('Cài đặt'), findsOneWidget);

      native.emit(NativeAction.openReelsDistracted);
      await tester.pumpAndSettle();
      expect(find.text('Bắt đầu 5 phút'), findsOneWidget);
    });

    group('Màn Tổng kết', () {
      Future<void> finishSession(WidgetTester tester) async {
        await tester.tap(find.text('Kết thúc sớm'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kết thúc'));
        await tester.pumpAndSettle();
      }

      testWidgets('Hiện số lần chặn và số lần nghỉ của phiên', (tester) async {
        await startSession(tester);

        openBlockedApp(tester);
        native.emit(NativeAction.resumeFocus);
        showApp(tester);
        await tester.pumpAndSettle();

        openBlockedApp(tester);
        native.emit(NativeAction.breakStarted, minutes: 5);
        showApp(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tiếp tục'));
        await tester.pumpAndSettle();

        await finishSession(tester);

        expect(find.text('Reset break đã chặn'), findsOneWidget);
        expect(find.text('2 lần'), findsOneWidget);
        expect(find.text('Nghỉ có chủ đích'), findsOneWidget);
        expect(find.text('1 lần'), findsOneWidget);
      });

      testWidgets('Trên web không hiện các dòng này', (tester) async {
        native = FakeNativeBridge(supported: false);
        await startSession(tester);

        await finishSession(tester);

        expect(find.text('Tổng kết'), findsOneWidget);
        expect(find.text('Reset break đã chặn'), findsNothing);
        expect(find.text('Nghỉ có chủ đích'), findsNothing);
      });
    });
  });

  group('8.2 Sự kiện từ phần Kotlin', () {
    final shownAt = DateTime(2026, 3, 2, 9, 30);

    Map<String, dynamic> interventionEvent() => {
      'type': 'intervention_shown',
      'time': shownAt.millisecondsSinceEpoch,
      'meta': {
        InterventionShownMeta.packageName: 'com.google.android.youtube',
        InterventionShownMeta.appLabel: 'YouTube',
        InterventionShownMeta.waitSeconds: 15,
      },
    };

    testWidgets('Lấy về khi mở app và khi quay lại, giữ nguyên loại, thời điểm và meta', (
      tester,
    ) async {
      final native = FakeNativeBridge()..queuedEvents.add(interventionEvent());

      await pumpApp(tester, size: _phone, native: native);
      expect(native.queuedEvents, isEmpty);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));

      final saved = EventRepository().getAll().single;
      expect(saved.type, EventType.interventionShown);
      expect(saved.time, shownAt);
      expect(saved.meta[InterventionShownMeta.packageName], 'com.google.android.youtube');
      expect(saved.meta[InterventionShownMeta.appLabel], 'YouTube');
      expect(saved.meta[InterventionShownMeta.waitSeconds], 15);

      native.queuedEvents.addAll([
        {
          'type': 'chose_study',
          'time': shownAt.millisecondsSinceEpoch,
          'meta': <String, dynamic>{},
        },
        {
          'type': 'chose_break',
          'time': shownAt.millisecondsSinceEpoch,
          'meta': {ChoseBreakMeta.minutes: 10},
        },
        {'type': 'chose_reel', 'time': shownAt.millisecondsSinceEpoch, 'meta': <String, dynamic>{}},
      ]);
      hideApp(tester);
      showApp(tester);
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));

      final events = EventRepository().getAll();
      expect(events, hasLength(4));
      expect(native.queuedEvents, isEmpty);
      expect(events.where((event) => event.type == EventType.choseBreak).single.meta, {
        ChoseBreakMeta.minutes: 10,
      });
      expect(events.where((event) => event.type == EventType.choseStudy), hasLength(1));
      expect(events.where((event) => event.type == EventType.choseReel), hasLength(1));
    });

    test('Chuỗi JSON của Kotlin được giải mã đúng kiểu', () async {
      final repository = EventRepository();
      final decoded = (jsonDecode(jsonEncode([interventionEvent()])) as List<dynamic>)
          .cast<Map<String, dynamic>>();

      await repository.saveNativeEvents(decoded);

      expect(repository.getAll().single.meta[InterventionShownMeta.waitSeconds], 15);
    });
  });
}

/// Phần Kotlin giả bị lỗi khi đọc danh sách app.
class _FailingAppsBridge extends FakeNativeBridge {
  @override
  Future<List<InstalledApp>> getLaunchableApps() async =>
      throw PlatformException(code: 'loi', message: 'Không đọc được');
}
