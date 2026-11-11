// 1.4 Kiểm thử màn Reels với trình phát video giả.
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
import 'package:focus_app/router/app_router.dart';
import 'package:focus_app/screens/main_shell.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/gradient_progress_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const String _r1 = 'assets/reels/r1.mp4';
const String _r3 = 'assets/reels/r3.mp4';
const String _r5 = 'assets/reels/r5.mp4';

// Hồ sơ "sự nghiệp": r1, r3, r5 trùng tag (3 điểm), r2 và r4 không trùng (1 điểm).
const String _titleR1 = 'Bạn đủ thông minh để thay đổi';
const String _titleR3 = 'Làm nhiều hơn người khác';

Future<void> _seedProfile([List<MotivationType> types = const [MotivationType.career]]) =>
    ProfileRepository().completeOnboarding(
      UserProfile(motivationTypes: types, preferredReelLength: 30),
    );

Future<void> _openReelsTab(WidgetTester tester) async {
  await pumpApp(tester);
  await tapAndSettle(tester, find.widgetWithText(NavigationDestination, 'Reels'));
}

/// Bấm trực tiếp, không dùng tapAndSettle: ensureVisible sẽ cuộn luôn PageView sang trang khác.
Future<void> _tapStartFocus(WidgetTester tester) async {
  await tester.tap(find.text('Bắt đầu 5 phút'));
  await tester.pumpAndSettle();
}

Future<void> _swipeToNextReel(WidgetTester tester) async {
  await tester.fling(find.byType(PageView), const Offset(0, -400), 1000);
  await tester.pumpAndSettle();
}

/// Cho đồng hồ chạy qua một nhịp cập nhật vị trí của video (500ms).
Future<void> _tickVideo(WidgetTester tester) => tester.pump(const Duration(milliseconds: 600));

List<Event> _watchEvents() =>
    EventRepository().getAll().where((event) => event.type == EventType.reelWatched).toList();

void main() {
  late FakeVideoPlayerPlatform player;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    await openMemoryBoxes();
    player = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = player;
  });

  tearDown(() async {
    await Hive.close();
  });

  group('Hiện trọn video', () {
    const phone = Size(411, 914);
    const portrait = Size(720, 1280);
    const fourFive = Size(720, 900);
    const square = Size(720, 720);
    const landscape = Size(960, 720);

    Future<void> openWithVideo(
      WidgetTester tester,
      Size videoSize, {
      Size screen = phone,
      List<MotivationType> types = const [MotivationType.career],
    }) async {
      player = FakeVideoPlayerPlatform(videoSize: videoSize);
      VideoPlayerPlatform.instance = player;
      await _seedProfile(types);
      await pumpApp(tester, size: screen);
      await tapAndSettle(tester, find.widgetWithText(NavigationDestination, 'Reels'));
    }

    Rect videoRect(WidgetTester tester) => tester.getRect(find.byType(AspectRatio));
    Rect pageRect(WidgetTester tester) => tester.getRect(find.byType(PageView));

    for (final videoSize in [portrait, fourFive, square, landscape]) {
      testWidgets('Video ${videoSize.width.toInt()}x${videoSize.height.toInt()} '
          'đủ cả chiều ngang, đúng tỉ lệ, không tràn ra ngoài trang', (tester) async {
        await openWithVideo(tester, videoSize);

        final video = videoRect(tester);
        final page = pageRect(tester);
        expect(video.width, moreOrLessEquals(page.width));
        expect(video.width / video.height, moreOrLessEquals(videoSize.aspectRatio));
        expect(video.top, greaterThanOrEqualTo(page.top));
        expect(video.bottom, lessThanOrEqualTo(page.bottom));
      });
    }

    testWidgets('Video cao hơn cả trang thì co theo chiều cao, vẫn không tràn', (tester) async {
      await openWithVideo(tester, const Size(720, 2000));

      final video = videoRect(tester);
      final page = pageRect(tester);
      expect(video.height, moreOrLessEquals(page.height));
      expect(video.center.dx, moreOrLessEquals(page.center.dx));
    });

    testWidgets('Video 9:16 không đủ chỗ tránh chữ nên giữ ở giữa', (tester) async {
      await openWithVideo(tester, portrait);

      expect(videoRect(tester).center.dy, moreOrLessEquals(pageRect(tester).center.dy));
    });

    for (final videoSize in [square, landscape]) {
      testWidgets('Video ${videoSize.width.toInt()}x${videoSize.height.toInt()} '
          'nằm giữa trang và không bị chữ đè', (tester) async {
        await openWithVideo(tester, videoSize);

        final video = videoRect(tester);
        expect(video.center.dy, moreOrLessEquals(pageRect(tester).center.dy));
        expect(video.bottom, lessThanOrEqualTo(tester.getTopLeft(find.text(_titleR1)).dy));
      });
    }

    testWidgets('Video 4:5 được đẩy lên vừa đủ để không bị chữ đè', (tester) async {
      await openWithVideo(tester, fourFive);

      final video = videoRect(tester);
      expect(video.center.dy, lessThan(pageRect(tester).center.dy));
      expect(video.top, greaterThanOrEqualTo(pageRect(tester).top));
      expect(video.bottom, lessThanOrEqualTo(tester.getTopLeft(find.text(_titleR1)).dy));
    });

    testWidgets('Tiêu đề 2 dòng trên điện thoại nhỏ vẫn không đè lên video vuông', (tester) async {
      const longTitle = 'Theo đuổi ước mơ, đừng chạy theo người';

      await openWithVideo(tester, square, screen: smallPhone, types: const [MotivationType.money]);

      final titleRect = tester.getRect(find.text(longTitle));
      expect(titleRect.height, greaterThan(40), reason: 'Tiêu đề phải xuống dòng');
      expect(videoRect(tester).bottom, lessThanOrEqualTo(titleRect.top));
    });

    testWidgets('Nền mờ và video chính dùng chung một controller, không tạo thêm', (tester) async {
      await openWithVideo(tester, square);

      final views = tester.widgetList<VideoPlayer>(find.byType(VideoPlayer)).toList();
      expect(views, hasLength(2));
      expect(identical(views.first.controller, views.last.controller), isTrue);
      expect(find.byType(ImageFiltered), findsOneWidget);
      expect(player.createdAssets, [_r1, _r3], reason: 'Mỗi trang chỉ có một controller');
    });

    testWidgets('Nền mờ nằm dưới video chính và được phủ lớp đen 45%', (tester) async {
      await openWithVideo(tester, square);

      final scrim = find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == AppColors.reelBlurScrim,
      );
      expect(scrim, findsOneWidget);
      expect(AppColors.reelBlurScrim.a, moreOrLessEquals(0.45, epsilon: 0.01));
      expect(tester.getRect(scrim), pageRect(tester));
    });

    testWidgets('Chạm vào vùng nền mờ, ngoài video chính, vẫn tạm dừng và phát lại', (
      tester,
    ) async {
      await openWithVideo(tester, landscape);
      final blurArea = Offset(pageRect(tester).center.dx, videoRect(tester).top - 60);

      await tester.tapAt(blurArea);
      await tester.pump();
      expect(player.playingAssets, isEmpty);
      expect(find.byIcon(AppIcons.play), findsOneWidget);

      await tester.tapAt(blurArea);
      await tester.pump();
      expect(player.playingAssets, [_r1]);
      expect(find.byIcon(AppIcons.play), findsNothing);
    });

    testWidgets('Chạm vào giữa video chính cũng tạm dừng được', (tester) async {
      await openWithVideo(tester, square);

      await tester.tapAt(videoRect(tester).center);
      await tester.pump();

      expect(player.playingAssets, isEmpty);
    });
  });

  group('Phát video', () {
    testWidgets('Tự phát và lặp lại video đầu; chỉ khởi tạo trang hiện tại và trang kế', (
      tester,
    ) async {
      await _seedProfile();
      await _openReelsTab(tester);

      expect(player.liveAssets, unorderedEquals([_r1, _r3]));
      expect(player.playingAssets, [_r1]);
      expect(player.isLooping(_r1), isTrue);
      expect(find.text(_titleR1), findsOneWidget);
    });

    testWidgets('Vuốt sang trang mới: phát video mới, dừng video cũ, giải phóng trang xa', (
      tester,
    ) async {
      await _seedProfile();
      await _openReelsTab(tester);

      await _swipeToNextReel(tester);
      expect(find.text(_titleR3), findsOneWidget);
      expect(player.playingAssets, [_r3]);
      expect(player.liveAssets, unorderedEquals([_r3, _r5]), reason: 'r1 phải được giải phóng');

      await _swipeToNextReel(tester);
      expect(player.playingAssets, [_r5]);
      expect(player.liveAssets, [_r5], reason: 'Trang cuối không có trang kế');
    });

    testWidgets('Vuốt ngược lại thì tạo lại video đã giải phóng và tự phát', (tester) async {
      await _seedProfile();
      await _openReelsTab(tester);
      await _swipeToNextReel(tester);
      expect(player.liveAssets, isNot(contains(_r1)));

      await tester.fling(find.byType(PageView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(find.text(_titleR1), findsOneWidget);
      expect(player.playingAssets, [_r1]);
      expect(player.liveAssets, unorderedEquals([_r1, _r3]));
    });

    testWidgets('Chạm để tạm dừng, chạm lần nữa để phát tiếp', (tester) async {
      await _seedProfile();
      await _openReelsTab(tester);
      final center = tester.getCenter(find.byType(PageView));

      await tester.tapAt(center);
      await tester.pump();
      expect(player.playingAssets, isEmpty);
      expect(find.byIcon(AppIcons.play), findsOneWidget);

      await tester.tapAt(center);
      await tester.pump();
      expect(player.playingAssets, [_r1]);
      expect(find.byIcon(AppIcons.play), findsNothing);
    });

    testWidgets('Rời tab thì dừng và giải phóng hết video, quay lại thì phát lại', (tester) async {
      await _seedProfile();
      await _openReelsTab(tester);
      expect(player.playingAssets, isNotEmpty);

      await tapAndSettle(tester, find.widgetWithText(NavigationDestination, 'Trang chủ'));
      expect(player.playingAssets, isEmpty, reason: 'Không được phát tiếng khi đã rời tab');
      expect(player.liveAssets, isEmpty);

      await tapAndSettle(tester, find.widgetWithText(NavigationDestination, 'Reels'));
      expect(player.playingAssets, hasLength(1));
      expect(player.liveAssets, hasLength(2));
    });

    testWidgets('Thanh tiến độ chạy theo vị trí video', (tester) async {
      await _seedProfile();
      await _openReelsTab(tester);

      GradientProgressBar bar() => tester.widget(find.byType(GradientProgressBar).first);
      expect(bar().value, 0);

      player.setPosition(_r1, const Duration(seconds: 3));
      await _tickVideo(tester);
      expect(bar().value, closeTo(0.2, 0.001));
      expect(bar().height, lessThanOrEqualTo(4), reason: 'Thanh phải mảnh');
    });

    testWidgets('Video lỗi thì báo lỗi, không làm hỏng màn và vẫn vuốt tiếp được', (tester) async {
      await _seedProfile();
      player.failingAssets.add(_r1);
      await _openReelsTab(tester);

      expect(find.text('Không phát được video này.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _swipeToNextReel(tester);
      expect(player.playingAssets, [_r3]);
    });
  });

  group('Nội dung và đề xuất', () {
    testWidgets('Hiện tiêu đề và chip tag bằng tiếng Việt', (tester) async {
      await _seedProfile();
      await _openReelsTab(tester);

      expect(find.text(_titleR1), findsOneWidget);
      expect(find.text('Chứng minh bản thân'), findsOneWidget);
      expect(find.text('Sự nghiệp'), findsOneWidget);
    });

    testWidgets('Chip tag có nền trong suốt và chữ sáng, không thành khối trắng che mất chữ', (
      tester,
    ) async {
      await _seedProfile();
      await _openReelsTab(tester);

      // Chip của Material có lớp nền trắng bên dưới, từng làm mất chữ khi chạy thật.
      expect(find.byType(Chip), findsNothing);

      final label = find.text('Sự nghiệp');
      final pill = tester.widget<Container>(
        find.ancestor(of: label, matching: find.byType(Container)).first,
      );
      expect((pill.decoration! as BoxDecoration).color, AppColors.onVideoChip);
      expect(AppColors.onVideoChip.a, lessThan(0.5), reason: 'Nền phải trong suốt');
      expect(tester.widget<Text>(label).style?.color, AppColors.onVideo);
    });

    testWidgets('Tối đa 3 reel dù kho có nhiều hơn', (tester) async {
      await _seedProfile();
      await _openReelsTab(tester);

      await _swipeToNextReel(tester);
      await _swipeToNextReel(tester);
      await _swipeToNextReel(tester); // Vuốt thêm không còn trang nào.

      expect(player.playingAssets, [_r5]);
      expect(player.createdAssets.toSet(), {_r1, _r3, _r5});
    });

    testWidgets('Hồ sơ không trùng tag nào vẫn có reel để xem', (tester) async {
      await _seedProfile(const [MotivationType.family]);
      await _openReelsTab(tester);

      expect(player.playingAssets, hasLength(1));
      expect(find.text('Chưa có reel phù hợp.'), findsNothing);
    });

    testWidgets('Quay lại tab thì đề xuất lại: reel vừa xem bị đẩy xuống', (tester) async {
      await _seedProfile();
      await _openReelsTab(tester);
      expect(find.text(_titleR1), findsOneWidget);

      player.setPosition(_r1, const Duration(seconds: 7));
      await _tickVideo(tester);
      await tapAndSettle(tester, find.widgetWithText(NavigationDestination, 'Trang chủ'));
      await tapAndSettle(tester, find.widgetWithText(NavigationDestination, 'Reels'));

      expect(find.text(_titleR3), findsOneWidget);
      expect(player.playingAssets, [_r3]);
    });

    testWidgets('Route nhận tham số context; bấm tab Reels lại về "start"', (tester) async {
      await _seedProfile();
      await pumpApp(tester);

      GoRouter.of(tester.element(find.byType(MainShell)))
          .go(AppRoutes.reelsFor(ReelContext.distracted));
      await tester.pumpAndSettle();

      // Chỉ r2, r5, r6 có ngữ cảnh distracted; r6 được ghim nên luôn đứng đầu.
      expect(find.text('Get back to work!'), findsOneWidget);
      expect(player.playingAssets, ['assets/reels/r6.mp4']);
      expect(player.createdAssets, isNot(contains(_r1)));

      await tapAndSettle(tester, find.widgetWithText(NavigationDestination, 'Trang chủ'));
      await tapAndSettle(tester, find.widgetWithText(NavigationDestination, 'Reels'));
      expect(find.text(_titleR1), findsOneWidget);
      expect(player.playingAssets, [_r1]);
    });
  });

  group('Nút "Bắt đầu 5 phút" và sự kiện', () {
    testWidgets('Mở Focus với 5 phút và thói quen hôm nay, dừng video, ghi startedFocus', (
      tester,
    ) async {
      await _seedProfile();
      await GoalRepository().save(const Goal(id: 'g1', title: 'Mục tiêu', reason: 'Lý do'));
      await HabitRepository().save(
        const Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 25),
      );
      await _openReelsTab(tester);

      player.setPosition(_r1, const Duration(seconds: 4));
      await _tickVideo(tester);
      await _tapStartFocus(tester);

      expect(find.text('05:00'), findsOneWidget);
      expect(find.text('Ôn bài'), findsOneWidget);
      expect(player.playingAssets, isEmpty);

      final event = _watchEvents().single;
      expect(event.meta[ReelWatchMeta.reelId], 'r1');
      expect(event.meta[ReelWatchMeta.secondsWatched], 4);
      expect(event.meta[ReelWatchMeta.completed], isFalse);
      expect(event.meta[ReelWatchMeta.startedFocus], isTrue);
    });

    testWidgets('Bấm ngay khi chưa xem giây nào vẫn ghi lại để đo reel nào khiến người dùng học', (
      tester,
    ) async {
      await _seedProfile();
      await _openReelsTab(tester);

      await _tapStartFocus(tester);

      final event = _watchEvents().single;
      expect(event.meta[ReelWatchMeta.secondsWatched], 0);
      expect(event.meta[ReelWatchMeta.startedFocus], isTrue);
    });

    testWidgets('Vuốt đi: ghi đúng số giây của reel vừa xem, không có startedFocus', (
      tester,
    ) async {
      await _seedProfile();
      await _openReelsTab(tester);

      player.setPosition(_r1, const Duration(seconds: 7));
      await _tickVideo(tester);
      await _swipeToNextReel(tester);

      final event = _watchEvents().single;
      expect(event.meta[ReelWatchMeta.reelId], 'r1');
      expect(event.meta[ReelWatchMeta.secondsWatched], 7);
      expect(event.meta[ReelWatchMeta.completed], isFalse);
      expect(event.meta.containsKey(ReelWatchMeta.startedFocus), isFalse);
    });

    testWidgets('Xem hết và lặp lại: số giây cộng dồn, đánh dấu đã xem hết', (tester) async {
      await _seedProfile();
      await _openReelsTab(tester);

      player.setPosition(_r1, const Duration(seconds: 14));
      await _tickVideo(tester);
      player.setPosition(_r1, const Duration(seconds: 2));
      await _tickVideo(tester);
      await _swipeToNextReel(tester);

      final event = _watchEvents().single;
      expect(event.meta[ReelWatchMeta.secondsWatched], 17);
      expect(event.meta[ReelWatchMeta.completed], isTrue);
    });

    testWidgets('Lướt qua dưới 1 giây thì không tính là đã xem', (tester) async {
      await _seedProfile();
      await _openReelsTab(tester);

      await _swipeToNextReel(tester);
      expect(_watchEvents(), isEmpty);
    });

    testWidgets('Video trang kế chạy ngầm không được tính cho trang hiện tại', (tester) async {
      await _seedProfile();
      await _openReelsTab(tester);

      player.setPosition(_r3, const Duration(seconds: 9));
      await _tickVideo(tester);
      await tapAndSettle(tester, find.widgetWithText(NavigationDestination, 'Trang chủ'));

      expect(_watchEvents(), isEmpty);
    });

    testWidgets('Rời tab: ghi lượt đang xem đúng một lần', (tester) async {
      await _seedProfile();
      await _openReelsTab(tester);

      player.setPosition(_r1, const Duration(seconds: 5));
      await _tickVideo(tester);
      await tapAndSettle(tester, find.widgetWithText(NavigationDestination, 'Thói quen'));

      expect(_watchEvents(), hasLength(1));
      expect(_watchEvents().single.meta[ReelWatchMeta.reelId], 'r1');
    });

    testWidgets('App bị đưa xuống nền: lưu lượt xem ngay, phòng khi hệ thống đóng app', (
      tester,
    ) async {
      await _seedProfile();
      await _openReelsTab(tester);

      player.setPosition(_r1, const Duration(seconds: 6));
      await _tickVideo(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(_watchEvents().single.meta[ReelWatchMeta.secondsWatched], 6);
      expect(player.playingAssets, isEmpty, reason: 'video_player tự dừng khi app xuống nền');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(player.playingAssets, [_r1]);
    });
  });

  testWidgets('Màn nhỏ không bị tràn giao diện với tiêu đề dài nhất', (tester) async {
    await _seedProfile(const [MotivationType.money]);
    await _openReelsTab(tester);

    expect(find.text('Theo đuổi ước mơ, đừng chạy theo người'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
