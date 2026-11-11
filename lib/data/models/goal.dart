// 6.2 Mô hình dữ liệu – mục tiêu.

class Goal {
  const Goal({required this.id, required this.title, required this.reason});

  /// Khoá để Habit tham chiếu tới qua goalId.
  final String id;
  final String title;
  final String reason;

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'reason': reason};

  factory Goal.fromMap(Map<String, dynamic> map) =>
      Goal(id: map['id'] as String, title: map['title'] as String, reason: map['reason'] as String);
}
