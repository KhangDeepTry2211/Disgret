// 1.4 Phản ứng của người dùng với một reel (thích). Lưu local, chưa có tài khoản.
// Bỏ thích không xoá bản ghi mà đặt liked = false và giữ likedAt, để sau này đồng bộ
// (Firebase) theo luật "bản mới hơn thắng" vẫn biết bản nào mới.

class ReelReaction {
  const ReelReaction({required this.reelId, required this.liked, required this.likedAt});

  final String reelId;
  final bool liked;

  /// Lần đổi trạng thái thích gần nhất.
  final DateTime likedAt;

  Map<String, dynamic> toMap() => {
    'reelId': reelId,
    'liked': liked,
    'likedAt': likedAt.toIso8601String(),
  };

  factory ReelReaction.fromMap(Map<String, dynamic> map) => ReelReaction(
    reelId: map['reelId'] as String,
    liked: map['liked'] as bool? ?? false,
    likedAt: DateTime.parse(map['likedAt'] as String),
  );
}
