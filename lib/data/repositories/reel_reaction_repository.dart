// 1.4 Lưu trữ local – lượt thích reel. Mỗi reel một bản ghi, id chính là reelId.
import '../hive_boxes.dart';
import '../models/reel_reaction.dart';
import 'hive_repository.dart';

class ReelReactionRepository extends HiveRepository<ReelReaction> {
  ReelReactionRepository() : super(HiveBoxes.reelReactions);

  @override
  ReelReaction fromMap(Map<String, dynamic> map) => ReelReaction.fromMap(map);

  @override
  Map<String, dynamic> toMap(ReelReaction item) => item.toMap();

  @override
  String idOf(ReelReaction item) => item.reelId;

  /// Id các reel đang được thích.
  Set<String> likedIds() => {
    for (final reaction in getAll())
      if (reaction.liked) reaction.reelId,
  };
}
