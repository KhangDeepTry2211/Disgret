// 1.3, 1.4 Kiểm thử Tim, Bình luận, Chia sẻ trên Reels: lưu trữ, sự kiện, luật điểm mới của bộ
// đề xuất, giao diện cột nút, chạm đúp, bottom sheet bình luận, dữ liệu mẫu và thống kê.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/mock_data.dart';
import 'package:focus_app/data/models/event.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/reel.dart';
import 'package:focus_app/data/models/reel_comment.dart';
import 'package:focus_app/data/models/reel_reaction.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/event_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/data/repositories/reel_comment_repository.dart';
import 'package:focus_app/data/repositories/reel_reaction_repository.dart';
import 'package:focus_app/providers/app_providers.dart';
import 'package:focus_app/services/focus_stats.dart';
import 'package:focus_app/services/reel_recommender.dart';
import 'package:focus_app/services/reel_share.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/reel_action_column.dart';
import 'package:focus_app/widgets/reel_comments_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const String _r1 = 'assets/reels/r1.mp4';

final DateTime _now = DateTime(2026, 3, 2, 12);

Reel _reel(String id, List<MotivationType> tags) => Reel(
  id: id,
  assetPath: '$id.mp4',
  title: id,
  tags: tags,
  lengthSec: 15,
  context: const [ReelContext.start],
);

List<Event> _events(EventType type) =>
    EventRepository().getAll().where((event) => event.type == type).toList();

Future<void> _seedProfile() => ProfileRepository().completeOnboarding(
  const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
);

Future<void> _openReelsTab(WidgetTester tester) async {
  await _seedProfile();
  await pumpApp(tester);
  await tapAndSettle(tester, find.widgetWithText(NavigationDestination, 'Reels'));
}

Finder get _likeButton => find.byKey(const ValueKey('reel_like'));
Finder get _commentButton => find.byKey(const ValueKey('reel_comment'));
Finder get _shareButton => find.byKey(const ValueKey('reel_share'));

Offset _videoCenter(WidgetTester tester) => tester.getCenter(find.byType(PageView));

void main() {
  late FakeVideoPlayerPlatform player;
  final originalShareSheet = ReelShare.openShareSheet;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() async {
    await openMemoryBoxes();
    player = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = player;
  });

  tearDown(() async {
    ReelShare.openShareSheet = originalShareSheet;
    await Hive.close();
  });

  group('Thích', () {
    test('Thích rồi bỏ thích: lưu đúng và ghi sự kiện reel_liked / reel_unliked', () async {
      final container = ProviderContainer(overrides: [clockProvider.overrideWithValue(() => _now)]);
      addTearDown(container.dispose);
      final likes = container.read(reelLikesProvider.notifier);

      await likes.toggle('r1');
      expect(container.read(reelLikesProvider), {'r1'});
      expect(ReelReactionRepository().likedIds(), {'r1'});
      expect(ReelReactionRepository().getById('r1')!.likedAt, _now);
      expect(_events(EventType.reelLiked).single.meta[ReelActionMeta.reelId], 'r1');

      await likes.toggle('r1');
      expect(container.read(reelLikesProvider), isEmpty);
      expect(ReelReactionRepository().likedIds(), isEmpty);
      // Giữ bản ghi với liked = false để sau này đồng bộ.
      expect(ReelReactionRepository().getById('r1')!.liked, isFalse);
      expect(_events(EventType.reelUnliked), hasLength(1));
    });

    test('Thích reel đã thích (chạm đúp) không đổi gì và không ghi thêm sự kiện', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final likes = container.read(reelLikesProvider.notifier);

      expect(await likes.setLiked('r1', liked: true), isTrue);
      expect(await likes.setLiked('r1', liked: true), isFalse);
      expect(container.read(reelLikesProvider), {'r1'});
      expect(_events(EventType.reelLiked), hasLength(1));
      expect(_events(EventType.reelUnliked), isEmpty);
    });

    test('ReelReaction đọc ghi qua Map', () {
      final reaction = ReelReaction(reelId: 'r2', liked: true, likedAt: _now);
      final copy = ReelReaction.fromMap(reaction.toMap());
      expect(copy.reelId, 'r2');
      expect(copy.liked, isTrue);
      expect(copy.likedAt, _now);
    });
  });

  group('Bình luận', () {
    test('Thêm bình luận: cắt khoảng trắng, không nhận chuỗi rỗng, ghi reel_commented', () async {
      final container = ProviderContainer(overrides: [clockProvider.overrideWithValue(() => _now)]);
      addTearDown(container.dispose);
      final comments = container.read(reelCommentsProvider.notifier);

      expect(await comments.add('r1', '   '), isFalse);
      expect(await comments.add('r1', '  Hay quá  '), isTrue);

      final list = container.read(reelCommentsProvider);
      expect(list.single.text, 'Hay quá');
      expect(list.single.isMine, isTrue);
      expect(list.single.createdAt, _now);
      expect(list.single.updatedAt, _now);
      expect(ReelCommentRepository().getAll(), hasLength(1));
      expect(_events(EventType.reelCommented).single.meta[ReelActionMeta.reelId], 'r1');
    });

    test('Bình luận quá 300 ký tự bị cắt còn 300', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(reelCommentsProvider.notifier).add('r1', 'a' * 500);
      expect(container.read(reelCommentsProvider).single.text, hasLength(ReelComment.maxLength));
    });

    test('Xoá là xoá mềm: biến khỏi danh sách nhưng bản ghi còn, deleted = true', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final comments = container.read(reelCommentsProvider.notifier);
      await comments.add('r1', 'Một');
      await comments.add('r1', 'Hai');
      final first = container.read(reelCommentsProvider).first;

      await comments.delete(first.id);

      expect(container.read(reelCommentsProvider).map((c) => c.text), ['Hai']);
      // getById bỏ qua bản đã xoá mềm; bản ghi thô vẫn còn trong box để đồng bộ.
      expect(ReelCommentRepository().getById(first.id), isNull);
      final stored = ReelCommentRepository().getAllRaw()[first.id]!;
      expect(stored['deleted'], isTrue);
      expect(stored['text'], 'Một');

      // Mở lại app (tạo provider mới) vẫn không thấy bình luận đã xoá.
      final reopened = ProviderContainer();
      addTearDown(reopened.dispose);
      expect(reopened.read(reelCommentsProvider).map((c) => c.text), ['Hai']);
    });

    test('Thời gian dạng "2 phút trước"', () {
      String ago(Duration d) => timeAgo(_now, _now.subtract(d));
      expect(ago(const Duration(seconds: 20)), 'vừa xong');
      expect(ago(const Duration(minutes: 2)), '2 phút trước');
      expect(ago(const Duration(hours: 3)), '3 giờ trước');
      expect(ago(const Duration(days: 5)), '5 ngày trước');
      expect(timeAgo(_now, DateTime(2025, 12, 25)), '25/12/2025');
    });
  });

  group('Luật điểm "tag trùng reel đã thích"', () {
    final liked = _reel('liked', [MotivationType.money]);
    final sameTag = _reel('same', [MotivationType.money, MotivationType.freedom]);
    final otherTag = _reel('other', [MotivationType.family]);

    int score(Reel reel, {Set<MotivationType> likedTags = const {}}) => ReelRecommender.score(
      reel,
      motivationTypes: const [],
      recentlyWatchedIds: const {},
      lastWatchedId: null,
      likedTags: likedTags,
    );

    test('+1 điểm nếu có tag trùng, chỉ cộng một lần dù trùng nhiều tag', () {
      expect(score(sameTag), 1);
      expect(score(sameTag, likedTags: {MotivationType.money}), 2);
      expect(score(sameTag, likedTags: {MotivationType.money, MotivationType.freedom}), 2);
      expect(score(otherTag, likedTags: {MotivationType.money}), 1);
    });

    test('Không có reel đã thích: thứ tự như cũ (theo reels.json)', () {
      final result = ReelRecommender([otherTag, sameTag, liked]).recommend(null, 'start', const []);
      expect(result.map((r) => r.id), ['other', 'same', 'liked']);
    });

    test('Có reel đã thích: reel cùng tag được đưa lên trước', () {
      final result = ReelRecommender([otherTag, sameTag, liked])
          .recommend(null, 'start', const [], likedReelIds: {'liked'});
      // "same" và "liked" cùng có tag money nên +1, "other" thì không.
      expect(result.map((r) => r.id), ['same', 'liked', 'other']);
    });

    test('Reel ghim vẫn đứng đầu dù có reel khác được cộng điểm', () {
      final pinned = Reel(
        id: 'pinned',
        assetPath: 'pinned.mp4',
        title: 'pinned',
        tags: const [MotivationType.family],
        lengthSec: 15,
        context: const [ReelContext.start],
        pinFirst: const [ReelContext.start],
      );
      final result = ReelRecommender([sameTag, pinned])
          .recommend(null, 'start', const [], likedReelIds: {'same'});
      expect(result.first.id, 'pinned');
    });
  });

  group('Thống kê, dữ liệu mẫu, xoá dữ liệu', () {
    test('FocusStats đếm reel đang được thích (không đếm reel đã bỏ thích)', () {
      final stats = FocusStats.from(
        events: const [],
        sessions: const [],
        habits: const [],
        logs: const [],
        today: _now,
        reactions: [
          ReelReaction(reelId: 'r1', liked: true, likedAt: _now),
          ReelReaction(reelId: 'r2', liked: false, likedAt: _now),
          ReelReaction(reelId: 'r3', liked: true, likedAt: _now),
        ],
      );
      expect(stats.reelsLiked, 2);
    });

    test(
      'Tạo dữ liệu mẫu thêm lượt thích và bình luận của "Người dùng mẫu", không trùng',
      () async {
        await MockData.createDemoData(now: _now);
        await MockData.createDemoData(now: _now);

        expect(ReelReactionRepository().likedIds(), {'r1', 'r3'});
        final comments = ReelCommentRepository().getAll();
        expect(comments, isNotEmpty);
        expect(comments.every((c) => c.author == ReelComment.demoAuthor && !c.isMine), isTrue);
        expect(comments.map((c) => c.id).toSet(), hasLength(comments.length));
      },
    );

    test('Xoá toàn bộ dữ liệu xoá cả thích và bình luận', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(appDataActionsProvider).createDemoData();
      expect(container.read(reelLikesProvider), isNotEmpty);
      expect(container.read(reelCommentsProvider), isNotEmpty);

      await container.read(appDataActionsProvider).clearAll();

      expect(ReelReactionRepository().getAll(), isEmpty);
      expect(ReelCommentRepository().getAll(), isEmpty);
      expect(container.read(reelLikesProvider), isEmpty);
      expect(container.read(reelCommentsProvider), isEmpty);
    });
  });

  group('Giao diện Reels', () {
    testWidgets('Cột nút hiện đủ Tim, Bình luận, Chia sẻ phía trên nút Bắt đầu', (tester) async {
      await _openReelsTab(tester);

      expect(find.byType(ReelActionColumn), findsOneWidget);
      expect(_likeButton, findsOneWidget);
      expect(_commentButton, findsOneWidget);
      expect(_shareButton, findsOneWidget);
      expect(find.bySemanticsLabel('Thích'), findsOneWidget);
      expect(find.bySemanticsLabel('Bình luận'), findsOneWidget);
      expect(find.bySemanticsLabel('Chia sẻ'), findsOneWidget);
      // Chưa có bình luận thì không hiện số.
      expect(find.text('0'), findsNothing);

      final start = tester.getRect(find.text('Bắt đầu 5 phút'));
      expect(tester.getRect(_shareButton).bottom, lessThanOrEqualTo(start.top));
      // Nằm bên phải, không che tiêu đề và chip tag.
      final title = tester.getRect(find.text('Bạn đủ thông minh để thay đổi'));
      expect(tester.getRect(_likeButton).left, greaterThanOrEqualTo(title.right));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Chạm nút Tim: thích rồi bỏ thích, icon đổi đặc / rỗng', (tester) async {
      await _openReelsTab(tester);
      expect(find.byIcon(AppIcons.like), findsOneWidget);

      await tester.tap(_likeButton);
      await tester.pumpAndSettle();
      expect(find.byIcon(AppIcons.likeFilled), findsOneWidget);
      expect(find.bySemanticsLabel('Bỏ thích'), findsOneWidget);
      expect(ReelReactionRepository().likedIds(), {'r1'});

      await tester.tap(_likeButton);
      await tester.pumpAndSettle();
      expect(find.byIcon(AppIcons.like), findsOneWidget);
      expect(ReelReactionRepository().likedIds(), isEmpty);
    });

    testWidgets('Chạm đơn tạm dừng ngay; chạm đúp thích, hiện tim lớn, không bỏ thích', (
      tester,
    ) async {
      await _openReelsTab(tester);
      expect(player.playingAssets, [_r1]);
      final spot = _videoCenter(tester) - const Offset(0, 120);

      // Chạm đơn: dừng ngay, không phải chờ xem có chạm thứ hai hay không.
      await tester.tapAt(spot);
      await tester.pump();
      expect(player.playingAssets, isEmpty);
      expect(ReelReactionRepository().likedIds(), isEmpty);
      expect(find.byType(BurstHeart), findsNothing);

      // Chạm lần hai ngay sau đó = chạm đúp: thích, trạng thái phát về như trước chạm đầu.
      await tester.tapAt(spot);
      await tester.pump();
      expect(find.byType(BurstHeart), findsOneWidget);
      expect(ReelReactionRepository().likedIds(), {'r1'});
      expect(player.playingAssets, [_r1]);

      // Trái tim bay rồi biến mất.
      await tester.pumpAndSettle();
      expect(find.byType(BurstHeart), findsNothing);

      // Chạm đúp lần nữa vẫn là thích, không bỏ thích.
      await tester.pump(const Duration(seconds: 1));
      await tester.tapAt(spot);
      await tester.pump();
      await tester.tapAt(spot);
      await tester.pumpAndSettle();
      expect(ReelReactionRepository().likedIds(), {'r1'});
      expect(_events(EventType.reelLiked), hasLength(1));
      expect(_events(EventType.reelUnliked), isEmpty);
    });

    testWidgets('Bình luận: mở sheet thì dừng video, gửi được, hiện số, đóng thì phát lại', (
      tester,
    ) async {
      await _openReelsTab(tester);

      await tester.tap(_commentButton);
      await tester.pumpAndSettle();
      expect(
        find.text('Chưa có bình luận. Viết cảm nhận của bạn về video này nhé!'),
        findsOneWidget,
      );
      expect(player.playingAssets, isEmpty, reason: 'Sheet mở thì không phát tiếng ngầm');

      // Chuỗi rỗng hoặc toàn khoảng trắng: nút gửi bị khoá.
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      await tester.tap(find.byTooltip('Gửi bình luận'));
      await tester.pump();
      expect(ReelCommentRepository().getAll(), isEmpty);

      await tester.enterText(find.byType(TextField), 'Hay quá');
      await tester.pump();
      await tester.tap(find.byTooltip('Gửi bình luận'));
      await tester.pumpAndSettle();
      expect(find.text('Hay quá'), findsOneWidget);
      expect(find.text('Bạn'), findsNothing); // "Bạn" nằm chung dòng với thời gian.
      expect(find.textContaining('vừa xong'), findsOneWidget);
      expect(find.text('Chưa có bình luận. Viết cảm nhận của bạn về video này nhé!'), findsNothing);

      // Đóng sheet bằng cách chạm ra ngoài.
      await tester.tapAt(const Offset(180, 20));
      await tester.pumpAndSettle();
      expect(find.byType(ReelCommentsSheet), findsNothing);
      expect(player.playingAssets, [_r1]);
      expect(find.bySemanticsLabel('Bình luận, 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Ô nhập giới hạn 300 ký tự', (tester) async {
      await _openReelsTab(tester);
      await tester.tap(_commentButton);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'b' * 400);
      await tester.pump();
      await tester.tap(find.byTooltip('Gửi bình luận'));
      await tester.pumpAndSettle();

      expect(ReelCommentRepository().getAll().single.text, hasLength(ReelComment.maxLength));
    });

    testWidgets('Nhấn giữ bình luận của mình để xoá (có xác nhận); Huỷ thì giữ lại', (
      tester,
    ) async {
      await _openReelsTab(tester);
      await tester.tap(_commentButton);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Xoá tôi đi');
      await tester.pump();
      await tester.tap(find.byTooltip('Gửi bình luận'));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Xoá tôi đi'));
      await tester.pumpAndSettle();
      expect(find.text('Xoá bình luận?'), findsOneWidget);
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect(find.text('Xoá tôi đi'), findsOneWidget);

      await tester.longPress(find.text('Xoá tôi đi'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Xoá'));
      await tester.pumpAndSettle();
      expect(find.text('Xoá tôi đi'), findsNothing);
      expect(ReelCommentRepository().getAll(), isEmpty);
      expect(ReelCommentRepository().getAllRaw().values.single['deleted'], isTrue);
      expect(
        find.text('Chưa có bình luận. Viết cảm nhận của bạn về video này nhé!'),
        findsOneWidget,
      );
    });

    testWidgets('Bình luận mẫu hiện tác giả "Người dùng mẫu" và không xoá được bằng nhấn giữ', (
      tester,
    ) async {
      await _seedProfile();
      await MockData.createDemoData(now: DateTime.now());
      await pumpApp(tester);
      await tapAndSettle(tester, find.widgetWithText(NavigationDestination, 'Reels'));

      await tester.tap(_commentButton);
      await tester.pumpAndSettle();
      expect(find.textContaining(ReelComment.demoAuthor), findsWidgets);
      expect(find.text('Xem xong là muốn học ngay!'), findsOneWidget);

      await tester.longPress(find.text('Xem xong là muốn học ngay!'));
      await tester.pumpAndSettle();
      expect(find.text('Xoá bình luận?'), findsNothing);
    });

    testWidgets('Chia sẻ: không mở được bảng chia sẻ thì chép clipboard và hiện SnackBar', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
        call,
      ) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      ReelShare.openShareSheet = (text) async => throw PlatformException(code: 'unavailable');
      await _openReelsTab(tester);

      await tester.tap(_shareButton);
      await tester.pumpAndSettle();

      expect(find.text('Đã chép nội dung chia sẻ'), findsOneWidget);
      expect(copied, contains('Bạn đủ thông minh để thay đổi'));
      expect(copied, contains('DisGret'));
      expect(_events(EventType.reelShared).single.meta[ReelActionMeta.reelId], 'r1');
    });

    testWidgets('Màn nhỏ không tràn giao diện, cả sáng lẫn tối', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _openReelsTab(tester);
      await tester.tap(_commentButton);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
