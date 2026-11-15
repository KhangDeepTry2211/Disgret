// 1.4 Bình luận của người dùng dưới một reel. Lưu local, chưa có tài khoản.
// updatedAt và deleted (xoá mềm) có sẵn để sau này đồng bộ Firebase theo luật "bản mới hơn thắng".

class ReelComment {
  const ReelComment({
    required this.id,
    required this.reelId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
    this.author,
  });

  /// Số ký tự tối đa của một bình luận.
  static const int maxLength = 300;

  /// Tác giả của bình luận mẫu (dữ liệu mẫu). Bình luận của chính người dùng có author = null.
  static const String demoAuthor = 'Người dùng mẫu';

  /// Tên hiện cho bình luận của chính người dùng.
  static const String selfLabel = 'Bạn';

  final String id;
  final String reelId;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;

  /// null = của chính người dùng.
  final String? author;

  bool get isMine => author == null;
  String get authorLabel => author ?? selfLabel;

  ReelComment copyWith({String? text, DateTime? updatedAt, bool? deleted}) => ReelComment(
    id: id,
    reelId: reelId,
    text: text ?? this.text,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    author: author,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'reelId': reelId,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deleted': deleted,
    'author': author,
  };

  factory ReelComment.fromMap(Map<String, dynamic> map) => ReelComment(
    id: map['id'] as String,
    reelId: map['reelId'] as String,
    text: map['text'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
    deleted: map['deleted'] as bool? ?? false,
    author: map['author'] as String?,
  );
}
