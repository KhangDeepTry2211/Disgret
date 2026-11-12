// 6.2 Mô hình dữ liệu – mục tiêu.

class Goal {
  const Goal({required this.id, required this.title, required this.reason, this.identity = ''});

  /// Khoá để Habit tham chiếu tới qua goalId.
  final String id;
  final String title;
  final String reason;

  /// 4.1 Câu bản sắc, phần nối sau "Tôi là người…", ví dụ "học đều mỗi ngày".
  /// Rỗng nghĩa là chưa đặt. Dữ liệu cũ không có trường này nên mặc định rỗng.
  final String identity;

  Goal copyWith({String? title, String? reason, String? identity}) => Goal(
    id: id,
    title: title ?? this.title,
    reason: reason ?? this.reason,
    identity: identity ?? this.identity,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'reason': reason,
    'identity': identity,
  };

  factory Goal.fromMap(Map<String, dynamic> map) => Goal(
    id: map['id'] as String,
    title: map['title'] as String,
    reason: map['reason'] as String,
    identity: map['identity'] as String? ?? '',
  );
}
