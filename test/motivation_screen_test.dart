// 1.4 Widget tests for the motivation step (spec 002) with the fake video player.
// Replaces the old reels feed tests; layout, background-save and small-screen cases moved here.
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
const String _r6 = 'assets/reels/r6.mp4';

// "Career" profile: r1, r3, r5 match (3 points), r2 and r4 do not (1 point).
const String _titleR1 = 'Bạn đủ thông minh để thay đổi';
const String _titleR3 = 'Làm nhiều hơn người khác';
const String _titleR5 = 'Dù chỉ 1% cơ hội vẫn chiến';

final Finder _stageFinder = find.byKey(const ValueKey('reel-stage'));

Future<void> _seedProfile([List<MotivationType> types = const [MotivationType.career]]) =>
    ProfileRepository().completeOnboarding(
      UserProfile(motivationTypes: types, preferredReelLength: 30),
    );

/// A goal and a 25-minute habit, so the Hôm nay plan can start a session.
Future<void> _seedPlan() async {
  await GoalRepository().save(const Goal(id: 'g1', title: 'Mục tiêu', reason: 'Lý do'));
  await HabitRepository().save(
    const Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 25),
  );
}

/// Opens the motivation step as "Bắt đầu" on Hôm nay does (push, so Back returns).
Future<void> _pushMotivation(WidgetTester tester) async {
  GoRouter.of(tester.element(find.byType(MainShell)))
      .push(AppRoutes.motivationFor(ReelContext.start));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, {Size size = smallPhone, List<Reel>? reels}) async {
  await pumpApp(tester, size: size, reels: reels);
  await _pushMotivation(tester);
}

Future<void> _close(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Đóng'));
  await tester.pumpAndSettle();
}

/// Lets the fake clock pass one video position update (500 ms).
Future<void> _tickVideo(WidgetTester tester) => tester.pump(const Duration(milliseconds: 600));

/// Watches [asset] up to [seconds].
Future<void> _watch(
  WidgetTester tester,
  FakeVideoPlayerPlatform player,
  String asset,
  int seconds,
) async {
  player.setPosition(asset, Duration(seconds: seconds));
  await _tickVideo(tester);
}

List<Event> _events(EventType type) =>
    EventRepository().getAll().where((event) => event.type == type).toList();

List<Event> _watchEvents() => _events(EventType.reelWatched);

/// Opens the step after a distraction, from a running session.
Future<void> _openDistracted(WidgetTester tester) async {
  await _seedProfile();
  await _seedPlan();
  await pumpApp(tester);
  await holdToStart(tester);
  await tapAndSettle(tester, find.text('Bỏ qua'));
  GoRouter.of(tester.element(find.text('Thời gian còn lại')))
      .go(AppRoutes.motivationFor(ReelContext.distracted));
  await tester.pumpAndSettle();
}

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

  group('Whole video on a blurred background', () {
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
      await _open(tester, size: screen);
    }

    Rect videoRect(WidgetTester tester) => tester.getRect(find.byType(AspectRatio));
    Rect stageRect(WidgetTester tester) => tester.getRect(_stageFinder);

    for (final videoSize in [portrait, fourFive, square, landscape]) {
      testWidgets('Video ${videoSize.width.toInt()}x${videoSize.height.toInt()} '
          'fills the width, keeps its ratio, stays inside the page', (tester) async {
        await openWithVideo(tester, videoSize);

        final video = videoRect(tester);
        final page = stageRect(tester);
        expect(video.width, moreOrLessEquals(page.width));
        expect(video.width / video.height, moreOrLessEquals(videoSize.aspectRatio));
        expect(video.top, greaterThanOrEqualTo(page.top));
        expect(video.bottom, lessThanOrEqualTo(page.bottom));
      });
    }

    testWidgets('A video taller than the page fits its height', (tester) async {
      await openWithVideo(tester, const Size(720, 2000));

      final video = videoRect(tester);
      final page = stageRect(tester);
      expect(video.height, moreOrLessEquals(page.height));
      expect(video.center.dx, moreOrLessEquals(page.center.dx));
    });

    testWidgets('A 9:16 video has no room to avoid the text, so it stays centred', (tester) async {
      await openWithVideo(tester, portrait);

      expect(videoRect(tester).center.dy, moreOrLessEquals(stageRect(tester).center.dy));
    });

    for (final videoSize in [square, landscape]) {
      testWidgets('Video ${videoSize.width.toInt()}x${videoSize.height.toInt()} '
          'is centred and not covered by the title', (tester) async {
        await openWithVideo(tester, videoSize);

        final video = videoRect(tester);
        expect(video.center.dy, moreOrLessEquals(stageRect(tester).center.dy));
        expect(video.bottom, lessThanOrEqualTo(tester.getTopLeft(find.text(_titleR1)).dy));
      });
    }

    testWidgets('A 4:5 video is lifted just enough to clear the title', (tester) async {
      await openWithVideo(tester, fourFive);

      final video = videoRect(tester);
      expect(video.center.dy, lessThan(stageRect(tester).center.dy));
      expect(video.top, greaterThanOrEqualTo(stageRect(tester).top));
      expect(video.bottom, lessThanOrEqualTo(tester.getTopLeft(find.text(_titleR1)).dy));
    });

    testWidgets('A two-line title on a small phone does not cover a square video', (tester) async {
      const longTitle = 'Theo đuổi ước mơ, đừng chạy theo người';

      await openWithVideo(tester, square, screen: smallPhone, types: const [MotivationType.money]);

      final titleRect = tester.getRect(find.text(longTitle));
      expect(titleRect.height, greaterThan(40), reason: 'The title must wrap');
      expect(videoRect(tester).bottom, lessThanOrEqualTo(titleRect.top));
    });

    testWidgets('Blur and main video share one controller; the next reel is preloaded', (
      tester,
    ) async {
      await openWithVideo(tester, square);

      final views = tester.widgetList<VideoPlayer>(find.byType(VideoPlayer)).toList();
      expect(views, hasLength(2));
      expect(identical(views.first.controller, views.last.controller), isTrue);
      expect(find.byType(ImageFiltered), findsOneWidget);
      expect(player.createdAssets, [_r1, _r3], reason: 'Current reel and the preloaded next one');
    });

    testWidgets('The blur sits under the main video with a 45% black scrim', (tester) async {
      await openWithVideo(tester, square);

      final scrim = find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == AppColors.reelBlurScrim,
      );
      expect(scrim, findsOneWidget);
      expect(AppColors.reelBlurScrim.a, moreOrLessEquals(0.45, epsilon: 0.01));
      expect(tester.getRect(scrim), stageRect(tester));
    });

    testWidgets('Tapping the blurred area outside the video pauses and resumes', (tester) async {
      await openWithVideo(tester, landscape);
      final blurArea = Offset(stageRect(tester).center.dx, videoRect(tester).top - 60);

      await tester.tapAt(blurArea);
      await tester.pump();
      expect(player.playingAssets, isEmpty);
      expect(find.byIcon(AppIcons.play), findsOneWidget);

      await tester.tapAt(blurArea);
      await tester.pump();
      expect(player.playingAssets, [_r1]);
      expect(find.byIcon(AppIcons.play), findsNothing);
    });
  });

  group('US1: a bounded dose before studying', () {
    testWidgets('Plays the first of 3 reels once, shows "1/3", preloads only the next one', (
      tester,
    ) async {
      await _seedProfile();
      await _open(tester);

      expect(find.text('1/3'), findsOneWidget);
      expect(find.text(_titleR1), findsOneWidget);
      expect(player.playingAssets, [_r1]);
      expect(player.isLooping(_r1), isFalse, reason: 'FR-003: no loop');
      expect(player.liveAssets, unorderedEquals([_r1, _r3]));
      expect(find.text('Bỏ qua'), findsOneWidget);
      expect(find.text('Tiếp'), findsNothing, reason: '"Tiếp" only on the end card');
    });

    testWidgets('Swiping up, down or sideways changes nothing (FR-001)', (tester) async {
      await _seedProfile();
      await _open(tester);

      for (final offset in const [Offset(0, -400), Offset(0, 400), Offset(-300, 0)]) {
        await tester.fling(_stageFinder, offset, 1000);
        await tester.pumpAndSettle();
      }

      expect(find.text(_titleR1), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(player.playingAssets, [_r1]);
      expect(find.byType(PageView), findsNothing);
      expect(find.byType(Scrollable), findsNothing, reason: 'No scrollable list of reels');
    });

    testWidgets('Tap pauses at once, tap again resumes (FR-006)', (tester) async {
      await _seedProfile();
      await _open(tester);
      final center = tester.getCenter(_stageFinder);

      await tester.tapAt(center);
      await tester.pump();
      expect(player.playingAssets, isEmpty);
      expect(find.byIcon(AppIcons.play), findsOneWidget);

      await tester.tapAt(center);
      await tester.pump();
      expect(player.playingAssets, [_r1]);
    });

    testWidgets('At the end: no restart, end card with start actions and "Tiếp"', (tester) async {
      await _seedPlan();
      await _seedProfile();
      await _open(tester);

      await finishReel(tester);

      expect(player.playingAssets, isEmpty, reason: 'FR-003: the reel does not restart');
      expect(find.byKey(const ValueKey('reel-end-card')), findsOneWidget);
      expect(find.text('Bắt đầu 25 phút'), findsOneWidget);
      expect(find.text('Chỉ 5 phút thôi'), findsOneWidget);
      expect(find.text('Tiếp'), findsOneWidget);
      expect(find.text('Bỏ qua'), findsOneWidget);
      expect(find.byIcon(AppIcons.play), findsNothing);

      // Tapping the ended video does not replay it.
      await tester.tapAt(tester.getTopLeft(_stageFinder) + const Offset(40, 200));
      await tester.pump();
      expect(player.playingAssets, isEmpty);
    });

    testWidgets('"Tiếp" plays the next reel, frees the old one and preloads the one after', (
      tester,
    ) async {
      await _seedProfile();
      await _open(tester);

      await finishReel(tester);
      await tapAndSettle(tester, find.text('Tiếp'));

      expect(find.text('2/3'), findsOneWidget);
      expect(find.text(_titleR3), findsOneWidget);
      expect(player.playingAssets, [_r3]);
      expect(player.liveAssets, unorderedEquals([_r3, _r5]), reason: 'r1 must be freed');
      expect(find.byKey(const ValueKey('reel-end-card')), findsNothing);
    });

    testWidgets('The last reel ends without "Tiếp": only start or leave', (tester) async {
      await _seedProfile();
      await _open(tester);

      for (var i = 0; i < 2; i++) {
        await finishReel(tester);
        await tapAndSettle(tester, find.text('Tiếp'));
      }
      expect(find.text('3/3'), findsOneWidget);
      expect(find.text(_titleR5), findsOneWidget);
      expect(player.liveAssets, [_r5], reason: 'No reel after the last one');

      await finishReel(tester);
      expect(find.text('Tiếp'), findsNothing);
      expect(find.text('Bắt đầu 25 phút'), findsOneWidget);
      expect(find.text('Chỉ 5 phút thôi'), findsOneWidget);
      expect(player.createdAssets.toSet(), {_r1, _r3, _r5}, reason: 'Never more than 3 reels');
    });

    testWidgets('Fewer eligible reels: the label shows the real count', (tester) async {
      await _seedProfile();
      final two = testReels.where((reel) => reel.id == 'r1' || reel.id == 'r3').toList();
      await _open(tester, reels: two);

      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('"Bỏ qua" mid-reel starts the planned session', (tester) async {
      await _seedPlan();
      await _seedProfile();
      await _open(tester);

      await _watch(tester, player, _r1, 4);
      await tapAndSettle(tester, find.text('Bỏ qua'));

      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Ôn bài'), findsOneWidget);
      expect(player.liveAssets, isEmpty, reason: 'Leaving frees every video');
    });

    testWidgets('"Chỉ 5 phút thôi" on the end card starts a 5-minute session', (tester) async {
      await _seedPlan();
      await _seedProfile();
      await _open(tester);

      await finishReel(tester);
      await tester.tap(find.text('Chỉ 5 phút thôi'));
      await tester.pumpAndSettle();

      expect(find.text('05:00'), findsOneWidget);
      expect(player.playingAssets, isEmpty);
    });

    testWidgets('A video that fails shows the end card at once', (tester) async {
      await _seedProfile();
      player.failingAssets.add(_r1);
      await _open(tester);

      expect(find.text('Không phát được video này.'), findsOneWidget);
      expect(find.byKey(const ValueKey('reel-end-card')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tapAndSettle(tester, find.text('Tiếp'));
      expect(player.playingAssets, [_r3]);
    });

    testWidgets('A preloaded reel that failed shows its end card right after "Tiếp"', (
      tester,
    ) async {
      await _seedProfile();
      player.failingAssets.add(_r3);
      await _open(tester);

      await finishReel(tester);
      await tapAndSettle(tester, find.text('Tiếp'));

      expect(find.text('2/3'), findsOneWidget);
      expect(find.byKey(const ValueKey('reel-end-card')), findsOneWidget);
    });

    testWidgets('Close frees every video; opening again starts a new dose', (tester) async {
      await _seedProfile();
      await _open(tester);

      await _close(tester);
      expect(find.byType(MainShell), findsOneWidget);
      expect(player.playingAssets, isEmpty, reason: 'No sound after leaving');
      expect(player.liveAssets, isEmpty);

      await _pushMotivation(tester);
      expect(player.playingAssets, hasLength(1));
      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('System Back returns to Hôm nay without a session', (tester) async {
      await _seedPlan();
      await _seedProfile();
      await _open(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.text('Thời gian còn lại'), findsNothing);
      expect(player.liveAssets, isEmpty);
    });

    testWidgets('No reel matches: the session starts directly', (tester) async {
      await _seedPlan();
      await _seedProfile();
      await _open(tester, reels: const []);

      expect(find.text('25:00'), findsOneWidget);
      expect(_events(EventType.motivationSkipped), isEmpty);
    });

    testWidgets('The progress bar follows the video', (tester) async {
      await _seedProfile();
      await _open(tester);

      GradientProgressBar bar() => tester.widget(find.byType(GradientProgressBar).first);
      expect(bar().value, 0);

      await _watch(tester, player, _r1, 3);
      expect(bar().value, closeTo(0.2, 0.001));
      expect(bar().height, lessThanOrEqualTo(4), reason: 'The bar must be thin');
    });
  });

  group('Content and recommendation', () {
    testWidgets('Shows the title and Vietnamese tag chips', (tester) async {
      await _seedProfile();
      await _open(tester);

      expect(find.text(_titleR1), findsOneWidget);
      expect(find.text('Chứng minh bản thân'), findsOneWidget);
      expect(find.text('Sự nghiệp'), findsOneWidget);
    });

    testWidgets('Chips are translucent with light text, not a white block', (tester) async {
      await _seedProfile();
      await _open(tester);

      expect(find.byType(Chip), findsNothing);
      final label = find.text('Sự nghiệp');
      final pill = tester.widget<Container>(
        find.ancestor(of: label, matching: find.byType(Container)).first,
      );
      expect((pill.decoration! as BoxDecoration).color, AppColors.onVideoChip);
      expect(AppColors.onVideoChip.a, lessThan(0.5));
      expect(tester.widget<Text>(label).style?.color, AppColors.onVideo);
    });

    testWidgets('No like, comment, share, count or social element (FR-007, SC-004)', (
      tester,
    ) async {
      await _seedProfile();
      await _open(tester);
      await finishReel(tester);

      final socialIcons = {
        Icons.favorite,
        Icons.favorite_border,
        Icons.favorite_rounded,
        Icons.favorite_border_rounded,
        Icons.chat_bubble_outline_rounded,
        Icons.mode_comment_outlined,
        Icons.share_outlined,
        Icons.share,
      };
      expect(
        find.byWidgetPredicate((widget) => widget is Icon && socialIcons.contains(widget.icon)),
        findsNothing,
      );
      for (final word in ['Thích', 'Bình luận', 'Chia sẻ']) {
        expect(find.textContaining(word), findsNothing);
        expect(find.byTooltip(word), findsNothing);
      }
    });

    testWidgets('A profile with no matching tag still gets reels', (tester) async {
      await _seedProfile(const [MotivationType.family]);
      await _open(tester);

      expect(player.playingAssets, hasLength(1));
      expect(find.text('Chưa có reel phù hợp.'), findsNothing);
    });

    testWidgets('Opening again recomputes: the reel just watched moves down', (tester) async {
      await _seedProfile();
      await _open(tester);

      await _watch(tester, player, _r1, 7);
      await _close(tester);
      await _pushMotivation(tester);

      expect(find.text(_titleR3), findsOneWidget);
      expect(player.playingAssets, [_r3]);
    });

    testWidgets('The longest title does not overflow a small phone', (tester) async {
      await _seedProfile(const [MotivationType.money]);
      await _open(tester);

      expect(find.text('Theo đuổi ước mơ, đừng chạy theo người'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await finishReel(tester);
      expect(tester.takeException(), isNull, reason: 'End card fits too');
    });
  });

  group('US2: one reel after a distraction', () {
    testWidgets('Exactly one reel, the pinned one; "1/1"; no "Bỏ qua"', (tester) async {
      await _openDistracted(tester);

      expect(find.text('Get back to work!'), findsOneWidget);
      expect(find.text('1/1'), findsOneWidget);
      expect(player.playingAssets, [_r6]);
      expect(player.liveAssets, [_r6], reason: 'Nothing to preload');
      expect(find.text('Bỏ qua'), findsNothing);
      expect(find.text('Quay lại học'), findsOneWidget, reason: 'Leave early, back to the session');
    });

    testWidgets('End card: only "Quay lại học", which resumes the session', (tester) async {
      await _openDistracted(tester);

      await finishReel(tester);
      expect(find.text('Quay lại học'), findsOneWidget);
      expect(find.text('Tiếp'), findsNothing);
      expect(find.text('Bắt đầu 25 phút'), findsNothing);
      expect(find.text('Chỉ 5 phút thôi'), findsNothing);
      expect(find.text('Bỏ qua'), findsNothing);

      await tapAndSettle(tester, find.text('Quay lại học'));
      expect(find.text('Thời gian còn lại'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget, reason: 'Fake clock did not move');
    });

    testWidgets('System Back returns to the running session', (tester) async {
      await _openDistracted(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Thời gian còn lại'), findsOneWidget);
    });

    testWidgets('No reel for the context: straight back to the session', (tester) async {
      await _seedProfile();
      await _seedPlan();
      final startOnly = testReels.where((reel) => reel.id == 'r1').toList();
      await pumpApp(tester, reels: startOnly);
      await holdToStart(tester);
      await tapAndSettle(tester, find.text('Bỏ qua'));

      GoRouter.of(tester.element(find.text('Thời gian còn lại')))
          .go(AppRoutes.motivationFor(ReelContext.distracted));
      await tester.pumpAndSettle();

      expect(find.text('Thời gian còn lại'), findsOneWidget);
    });
  });

  group('US3: watch and skip records', () {
    testWidgets('End-card start: one reel_watched with startedFocus and completed', (tester) async {
      await _seedPlan();
      await _seedProfile();
      await _open(tester);

      await _watch(tester, player, _r1, 9);
      await finishReel(tester);
      await tester.tap(find.text('Bắt đầu 25 phút'));
      await tester.pumpAndSettle();

      final event = _watchEvents().single;
      expect(event.meta[ReelWatchMeta.reelId], 'r1');
      expect(event.meta[ReelWatchMeta.secondsWatched], 15);
      expect(event.meta[ReelWatchMeta.completed], isTrue);
      expect(event.meta[ReelWatchMeta.startedFocus], isTrue);
      expect(_events(EventType.motivationSkipped), isEmpty);
    });

    testWidgets('"Tiếp": one record per reel shown, no startedFocus', (tester) async {
      await _seedPlan();
      await _seedProfile();
      await _open(tester);

      await finishReel(tester);
      await tapAndSettle(tester, find.text('Tiếp'));
      await _watch(tester, player, _r3, 6);
      await finishReel(tester);
      await tester.tap(find.text('Chỉ 5 phút thôi'));
      await tester.pumpAndSettle();

      final events = _watchEvents();
      expect(
        events.map((event) => event.meta[ReelWatchMeta.reelId]),
        unorderedEquals(['r1', 'r3']),
      );
      final r1 = events.singleWhere((event) => event.meta[ReelWatchMeta.reelId] == 'r1');
      final r3 = events.singleWhere((event) => event.meta[ReelWatchMeta.reelId] == 'r3');
      expect(r1.meta[ReelWatchMeta.completed], isTrue);
      expect(r1.meta.containsKey(ReelWatchMeta.startedFocus), isFalse);
      expect(r3.meta[ReelWatchMeta.startedFocus], isTrue);
    });

    testWidgets('"Bỏ qua": motivation_skipped with context and position; watch if ≥1 s', (
      tester,
    ) async {
      await _seedPlan();
      await _seedProfile();
      await _open(tester);

      await finishReel(tester);
      await tapAndSettle(tester, find.text('Tiếp'));
      await _watch(tester, player, _r3, 4);
      await tapAndSettle(tester, find.text('Bỏ qua'));

      final skip = _events(EventType.motivationSkipped).single;
      expect(skip.meta, {'context': 'start', 'position': 2});
      final r3 = _watchEvents().singleWhere((event) => event.meta[ReelWatchMeta.reelId] == 'r3');
      expect(r3.meta[ReelWatchMeta.secondsWatched], 4);
      expect(r3.meta.containsKey(ReelWatchMeta.startedFocus), isFalse);
    });

    testWidgets('"Bỏ qua" at once: a skip record and no watch record', (tester) async {
      await _seedPlan();
      await _seedProfile();
      await _open(tester);

      await tapAndSettle(tester, find.text('Bỏ qua'));

      expect(_events(EventType.motivationSkipped).single.meta, {'context': 'start', 'position': 1});
      expect(_watchEvents(), isEmpty);
    });

    testWidgets('Leaving: under 1 s is not recorded, otherwise exactly once', (tester) async {
      await _seedProfile();
      await _open(tester);
      await _close(tester);
      expect(_watchEvents(), isEmpty);

      await _pushMotivation(tester);
      expect(player.playingAssets, [_r1], reason: 'Nothing recorded, so r1 is still first');
      await _watch(tester, player, _r1, 5);
      await _close(tester);
      expect(_watchEvents().single.meta[ReelWatchMeta.secondsWatched], 5);
    });

    testWidgets('The preloaded reel does not count for the current one', (tester) async {
      await _seedProfile();
      await _open(tester);

      player.setPosition(_r3, const Duration(seconds: 9));
      await _tickVideo(tester);
      await _close(tester);

      expect(_watchEvents(), isEmpty);
    });

    testWidgets('App to background: saved at once, paused on return, never duplicated', (
      tester,
    ) async {
      await _seedPlan();
      await _seedProfile();
      await _open(tester);

      await _watch(tester, player, _r1, 6);
      hideApp(tester);
      await tester.pump();

      expect(_watchEvents().single.meta[ReelWatchMeta.secondsWatched], 6);
      expect(player.playingAssets, isEmpty);

      showApp(tester);
      await tester.pump();
      expect(player.playingAssets, isEmpty, reason: 'Stays paused on the same frame');
      expect(find.byIcon(AppIcons.play), findsOneWidget);

      await tester.tapAt(tester.getCenter(_stageFinder));
      await tester.pump();
      await _watch(tester, player, _r1, 10);
      await tapAndSettle(tester, find.text('Bỏ qua'));

      final event = _watchEvents().single;
      expect(event.meta[ReelWatchMeta.secondsWatched], 10, reason: 'Same record, updated');
    });

    testWidgets('After a distraction: the reel is recorded without startedFocus', (tester) async {
      await _openDistracted(tester);

      await tapAndSettle(tester, find.text('Quay lại học'));

      final event = _watchEvents().single;
      expect(event.meta[ReelWatchMeta.reelId], 'r6');
      expect(event.meta.containsKey(ReelWatchMeta.startedFocus), isFalse);
    });
  });
}
