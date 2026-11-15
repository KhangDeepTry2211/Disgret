// 1.4 Lưu trữ local – bình luận reel. Xoá là xoá mềm (deleted = true), xem ReelComment.
import '../hive_boxes.dart';
import '../models/reel_comment.dart';
import 'hive_repository.dart';

class ReelCommentRepository extends HiveRepository<ReelComment> {
  ReelCommentRepository() : super(HiveBoxes.reelComments);

  @override
  ReelComment fromMap(Map<String, dynamic> map) => ReelComment.fromMap(map);

  @override
  Map<String, dynamic> toMap(ReelComment item) => item.toMap();

  @override
  String idOf(ReelComment item) => item.id;
}
