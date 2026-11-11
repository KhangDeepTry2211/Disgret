// 1.3 Unit test bộ đề xuất reel.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/event.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/reel.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/services/reel_recommender.dart';

import 'test_helpers.dart';

final DateTime _now = DateTime(2026, 3, 2, 12);

Reel _reel(
  String id, {
  List<MotivationType> tags = const [],
  List<String> context = const [ReelContext.start],
  List<String> pinFirst = const [],
}) {
  return Reel(
    id: id,
    assetPath: '$id.mp4',
    title: id,
    tags: tags,
    lengthSec: 15,
    context: context,
    pinFirst: pinFirst,
  );
}

UserProfile _profile(List<MotivationType> types) =>
    UserProfile(motivationTypes: types, preferredReelLength: 30);

int _nextEventId = 0;

Event _watched(String reelId, {required Duration ago}) => Event(
  id: 'e${_nextEventId++}',
  type: EventType.reelWatched,
  time: _now.subtract(ago),
  meta: {ReelWatchMeta.reelId: reelId, ReelWatchMeta.secondsWatched: 10},
);

List<String> _ids(List<Reel> reels) => reels.map((reel) => reel.id).toList();

void main() {
  group('Công thức tính điểm', () {
    int score(
      Reel reel, {
      List<MotivationType> types = const [],
      Set<String> recent = const {},
      String? last,
    }) {
      return ReelRecommender.score(
        reel,
        motivationTypes: types,
        recentlyWatchedIds: recent,
        lastWatchedId: last,
      );
    }

    final reel = _reel('a', tags: [MotivationType.money, MotivationType.career]);

    test('Không trùng tag và chưa xem: chỉ được 1 điểm', () {
      expect(score(reel, types: [MotivationType.family]), 1);
    });

    test('Mỗi tag trùng được 2 điểm', () {
      expect(score(reel, types: [MotivationType.money]), 3);
      expect(score(reel, types: [MotivationType.money, MotivationType.career]), 5);
    });

    test('Đã xem trong 24 giờ thì mất điểm cộng', () {
      expect(score(reel, types: [MotivationType.money], recent: {'a'}), 2);
    });

    test('Vừa xem gần nhất thì bị trừ 2 điểm, có thể ra số âm', () {
      expect(score(reel, types: [MotivationType.money], recent: {'a'}, last: 'a'), 0);
      expect(score(reel, recent: {'a'}, last: 'a'), -2);
    });

    test('Vừa xem gần nhất nhưng đã quá 24 giờ thì vẫn được điểm cộng', () {
      expect(score(reel, last: 'a'), -1);
    });
  });

  group('Đề xuất', () {
    test('Chỉ lấy reel đúng ngữ cảnh', () {
      final recommender = ReelRecommender([
        _reel('start_only'),
        _reel('distracted_only', context: [ReelContext.distracted]),
        _reel('both', context: [ReelContext.start, ReelContext.distracted]),
      ]);

      expect(_ids(recommender.recommend(null, ReelContext.start, const [], now: _now)), [
        'start_only',
        'both',
      ]);
      expect(_ids(recommender.recommend(null, ReelContext.distracted, const [], now: _now)), [
        'distracted_only',
        'both',
      ]);
    });

    test('Không có reel đúng ngữ cảnh thì trả về rỗng', () {
      final recommender = ReelRecommender([_reel('a')]);
      expect(recommender.recommend(null, ReelContext.distracted, const [], now: _now), isEmpty);
    });

    test('Trả về tối đa 3 reel, điểm cao đứng trước', () {
      final recommender = ReelRecommender([
        _reel('zero'),
        _reel('one', tags: [MotivationType.money]),
        _reel('two', tags: [MotivationType.money, MotivationType.career]),
        _reel('other'),
      ]);
      final profile = _profile([MotivationType.money, MotivationType.career]);

      expect(_ids(recommender.recommend(profile, ReelContext.start, const [], now: _now)), [
        'two',
        'one',
        'zero',
      ]);
    });

    test('Bằng điểm thì giữ thứ tự trong danh sách gốc', () {
      final recommender = ReelRecommender([_reel('a'), _reel('b'), _reel('c'), _reel('d')]);
      expect(_ids(recommender.recommend(null, ReelContext.start, const [], now: _now)), [
        'a',
        'b',
        'c',
      ]);
    });

    test('Không reel nào trùng tag thì vẫn trả reel phù hợp ngữ cảnh', () {
      final recommender = ReelRecommender([
        _reel('a', tags: [MotivationType.money]),
        _reel('b', tags: [MotivationType.career]),
      ]);
      final profile = _profile([MotivationType.family]);

      expect(_ids(recommender.recommend(profile, ReelContext.start, const [], now: _now)), [
        'a',
        'b',
      ]);
    });

    test('Chưa có hồ sơ vẫn đề xuất được', () {
      final recommender = ReelRecommender([_reel('a')]);
      expect(_ids(recommender.recommend(null, ReelContext.start, const [], now: _now)), ['a']);
    });

    test('Reel đã xem trong 24 giờ bị xếp sau reel chưa xem', () {
      final recommender = ReelRecommender([_reel('watched'), _reel('fresh'), _reel('last')]);
      final history = [
        _watched('watched', ago: const Duration(hours: 5)),
        _watched('last', ago: const Duration(hours: 1)),
      ];

      expect(_ids(recommender.recommend(null, ReelContext.start, history, now: _now)), [
        'fresh',
        'watched',
        'last',
      ]);
    });

    test('Mốc 24 giờ: còn trong khoảng thì mất điểm cộng, đúng 24 giờ thì được lại', () {
      final recommender = ReelRecommender([_reel('a'), _reel('b')]);
      final newer = [
        _watched('a', ago: const Duration(hours: 23, minutes: 59)),
        _watched('b', ago: const Duration(minutes: 1)),
      ];
      final older = [
        _watched('a', ago: const Duration(hours: 24)),
        _watched('b', ago: const Duration(minutes: 1)),
      ];

      // a: 0 điểm; b: vừa xem gần nhất nên -2.
      expect(_ids(recommender.recommend(null, ReelContext.start, newer, now: _now)), ['a', 'b']);
      // a: 1 điểm vì đã qua 24 giờ.
      final scoreA = ReelRecommender.score(
        recommender.reels.first,
        motivationTypes: const [],
        recentlyWatchedIds: {'b'},
        lastWatchedId: 'b',
      );
      expect(scoreA, 1);
      expect(_ids(recommender.recommend(null, ReelContext.start, older, now: _now)), ['a', 'b']);
    });

    test('Reel vừa xem gần nhất bị trừ điểm dù hợp động lực nhất', () {
      final recommender = ReelRecommender([
        _reel('best', tags: [MotivationType.money]),
        _reel('fresh'),
      ]);
      final profile = _profile([MotivationType.money]);
      final history = [_watched('best', ago: const Duration(minutes: 1))];

      // best: 2 + 0 - 2 = 0; fresh: 0 + 1 = 1.
      expect(_ids(recommender.recommend(profile, ReelContext.start, history, now: _now)), [
        'fresh',
        'best',
      ]);
    });

    test('"Gần nhất" dựa vào thời gian xem, không phụ thuộc thứ tự trong lịch sử', () {
      final recommender = ReelRecommender([_reel('a'), _reel('b')]);
      final history = [
        _watched('b', ago: const Duration(minutes: 1)),
        _watched('a', ago: const Duration(hours: 2)),
      ];

      // a: 0; b: -2. Nếu lấy nhầm phần tử cuối thì a mới bị trừ điểm.
      expect(_ids(recommender.recommend(null, ReelContext.start, history, now: _now)), ['a', 'b']);
    });

    test('Bỏ qua sự kiện khác loại và sự kiện thiếu reelId', () {
      final recommender = ReelRecommender([_reel('a'), _reel('b')]);
      final history = [
        Event(
          id: 'x',
          type: EventType.choseReel,
          time: _now,
          meta: const {ReelWatchMeta.reelId: 'a'},
        ),
        Event(id: 'y', type: EventType.reelWatched, time: _now),
      ];

      // Không có lượt xem hợp lệ nào nên a và b bằng điểm, giữ nguyên thứ tự.
      expect(_ids(recommender.recommend(null, ReelContext.start, history, now: _now)), ['a', 'b']);
    });
  });

  group('Ghim reel (pinFirst)', () {
    const both = [ReelContext.start, ReelContext.distracted];
    final pinnedReel = _reel('ghim', context: both, pinFirst: const [ReelContext.distracted]);
    final reels = [
      _reel('a', tags: [MotivationType.money], context: both),
      _reel('b', tags: [MotivationType.money], context: both),
      pinnedReel,
      _reel('c', tags: [MotivationType.money], context: both),
    ];
    final recommender = ReelRecommender(reels);
    final profile = _profile([MotivationType.money]);

    test('Ngữ cảnh được ghim: reel ghim đứng đầu dù ít điểm nhất', () {
      expect(_ids(recommender.recommend(profile, ReelContext.distracted, const [], now: _now)), [
        'ghim',
        'a',
        'b',
      ]);
    });

    test('Reel ghim vẫn đứng đầu dù vừa xem gần nhất', () {
      final history = [_watched('ghim', ago: const Duration(minutes: 1))];
      expect(
        _ids(recommender.recommend(profile, ReelContext.distracted, history, now: _now)).first,
        'ghim',
      );
    });

    test('Các reel còn lại vẫn xếp theo điểm, tổng tối đa 3', () {
      // a vừa xem nên bị trừ điểm, b và c lên trước.
      final history = [_watched('a', ago: const Duration(minutes: 1))];
      expect(_ids(recommender.recommend(profile, ReelContext.distracted, history, now: _now)), [
        'ghim',
        'b',
        'c',
      ]);
    });

    test('Ngữ cảnh khác không bị ảnh hưởng: reel ghim chỉ xếp theo điểm', () {
      expect(_ids(recommender.recommend(profile, ReelContext.start, const [], now: _now)), [
        'a',
        'b',
        'c',
      ]);
    });

    test('Không reel nào ghim thì kết quả giữ nguyên như trước', () {
      final unpinned = ReelRecommender([
        for (final reel in reels)
          if (reel != pinnedReel) reel,
      ]);
      expect(_ids(unpinned.recommend(profile, ReelContext.distracted, const [], now: _now)), [
        'a',
        'b',
        'c',
      ]);
    });
  });

  group('Với dữ liệu thật trong reels.json', () {
    final recommender = ReelRecommender(testReels);

    test('r6 "Get back to work!" được ghim cho ngữ cảnh sau khi xao nhãng', () {
      final r6 = testReels.singleWhere((reel) => reel.id == 'r6');
      expect(r6.title, 'Get back to work!');
      expect(r6.pinFirst, [ReelContext.distracted]);
      expect(testReels.where((reel) => reel.pinFirst.isNotEmpty), [r6]);
    });

    test('Sau khi xao nhãng: r6 luôn đứng đầu, kể cả khi vừa xem', () {
      final profile = _profile([MotivationType.proveYourself]);
      final history = [_watched('r6', ago: const Duration(minutes: 1))];

      expect(_ids(recommender.recommend(profile, ReelContext.distracted, history, now: _now)), [
        'r6',
        'r2',
        'r5',
      ]);
    });

    test('Trước khi học: r6 không xuất hiện, kết quả không đổi', () {
      final profile = _profile([MotivationType.proveYourself]);
      expect(
        _ids(recommender.recommend(profile, ReelContext.start, const [], now: _now)),
        isNot(contains('r6')),
      );
    });

    test('Hồ sơ tiền bạc + tự do: r4 trùng 2 tag đứng đầu, rồi r2 trùng 1 tag', () {
      final profile = _profile([MotivationType.money, MotivationType.freedom]);
      expect(_ids(recommender.recommend(profile, ReelContext.start, const [], now: _now)), [
        'r4',
        'r2',
        'r1',
      ]);
    });

    test('Vừa xem r4 thì r2 lên đầu', () {
      final profile = _profile([MotivationType.money, MotivationType.freedom]);
      final history = [_watched('r4', ago: const Duration(minutes: 1))];

      // r2: 3 điểm; r4: 4 + 0 - 2 = 2; r1: 1 điểm.
      expect(_ids(recommender.recommend(profile, ReelContext.start, history, now: _now)), [
        'r2',
        'r4',
        'r1',
      ]);
    });

    test('Ngữ cảnh sau khi xao nhãng chỉ có r2, r5, r6', () {
      final profile = _profile([MotivationType.proveYourself]);
      expect(
        _ids(recommender.recommend(profile, ReelContext.distracted, const [], now: _now)),
        unorderedEquals(['r2', 'r5', 'r6']),
      );
    });

    test('Hồ sơ gia đình: kho hiện không có reel tag gia đình nhưng vẫn có reel để xem', () {
      final profile = _profile([MotivationType.family]);
      expect(recommender.recommend(profile, ReelContext.start, const [], now: _now), hasLength(3));
    });
  });
}
