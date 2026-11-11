// 1.3 Bộ đề xuất reel theo luật cố định, không dùng AI.
// Toàn bộ là hàm thuần: cùng dữ liệu vào luôn cho cùng kết quả, nên dễ giải thích và dễ test.
import '../data/models/event.dart';
import '../data/models/motivation_type.dart';
import '../data/models/reel.dart';
import '../data/models/user_profile.dart';

class ReelRecommender {
  const ReelRecommender(this.reels);

  /// Trả về tối đa chừng này reel mỗi lượt.
  static const int maxResults = 3;

  /// Reel xem trong khoảng thời gian này được coi là "mới xem".
  static const Duration recentWindow = Duration(hours: 24);

  final List<Reel> reels;

  /// Điểm = 2 × số tag trùng động lực + 1 nếu chưa xem trong 24 giờ qua − 2 nếu vừa xem gần nhất.
  static int score(
    Reel reel, {
    required List<MotivationType> motivationTypes,
    required Set<String> recentlyWatchedIds,
    required String? lastWatchedId,
  }) {
    final matchingTags = reel.tags.where(motivationTypes.contains).length;
    var points = 2 * matchingTags;
    if (!recentlyWatchedIds.contains(reel.id)) points += 1;
    if (reel.id == lastWatchedId) points -= 2;
    return points;
  }

  /// Lọc theo ngữ cảnh rồi lấy các reel điểm cao nhất. Tag chỉ cộng điểm chứ không dùng để lọc,
  /// nên dù không reel nào trùng tag vẫn có reel phù hợp ngữ cảnh để xem.
  /// Điểm bằng nhau thì giữ thứ tự trong reels.json.
  /// Reel ghim cho ngữ cảnh này (trường pinFirst) luôn đứng đầu, bỏ qua điểm và luật
  /// "vừa xem gần nhất"; các chỗ còn lại vẫn xếp theo điểm.
  List<Reel> recommend(UserProfile? profile, String context, List<Event> history, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final watched = history
        .where(
          (event) =>
              event.type == EventType.reelWatched && event.meta[ReelWatchMeta.reelId] is String,
        )
        .toList();

    final recentlyWatchedIds = {
      for (final event in watched)
        if (currentTime.difference(event.time) < recentWindow) _reelIdOf(event),
    };
    final lastWatchedId = _lastWatchedId(watched);

    final motivationTypes = profile?.motivationTypes ?? const <MotivationType>[];
    final pinned = reels.where((reel) => reel.pinFirst.contains(context)).toList();
    final candidates = reels
        .where((reel) => reel.context.contains(context) && !pinned.contains(reel))
        .toList();
    final points = {
      for (final reel in candidates)
        reel.id: score(
          reel,
          motivationTypes: motivationTypes,
          recentlyWatchedIds: recentlyWatchedIds,
          lastWatchedId: lastWatchedId,
        ),
    };

    final ranked = [...candidates]
      ..sort((a, b) {
        final byPoints = points[b.id]!.compareTo(points[a.id]!);
        // Hàm sort của Dart không đảm bảo giữ thứ tự cũ khi bằng điểm nên phải so thêm vị trí.
        return byPoints != 0 ? byPoints : candidates.indexOf(a).compareTo(candidates.indexOf(b));
      });
    return [...pinned, ...ranked].take(maxResults).toList();
  }

  String _reelIdOf(Event event) => event.meta[ReelWatchMeta.reelId] as String;

  String? _lastWatchedId(List<Event> watched) {
    if (watched.isEmpty) return null;
    final latest = watched.reduce((a, b) => a.time.isAfter(b.time) ? a : b);
    return _reelIdOf(latest);
  }
}
