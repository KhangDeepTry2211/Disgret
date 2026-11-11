// 6.2 Mô hình dữ liệu – một phiên học.

class Session {
  const Session({
    required this.id,
    required this.habitId,
    required this.start,
    this.end,
    required this.plannedMinutes,
    required this.focusedSeconds,
    required this.distractionCount,
    this.awaySeconds = 0,
    this.selfRating,
    this.note = '',
  });

  final String id;
  final String habitId;
  final DateTime start;

  /// Null khi phiên học chưa kết thúc.
  final DateTime? end;
  final int plannedMinutes;
  final int focusedSeconds;
  final int distractionCount;

  /// 3.4 Tổng thời gian ở ngoài app trong phiên.
  final int awaySeconds;

  /// Tự đánh giá sau phiên học; null khi chưa đánh giá.
  final int? selfRating;

  /// 3.4 Ghi chú ngắn sau phiên học, không bắt buộc; rỗng nghĩa là không có.
  final String note;

  Map<String, dynamic> toMap() => {
    'id': id,
    'habitId': habitId,
    'start': start.toIso8601String(),
    'end': end?.toIso8601String(),
    'plannedMinutes': plannedMinutes,
    'focusedSeconds': focusedSeconds,
    'distractionCount': distractionCount,
    'awaySeconds': awaySeconds,
    'selfRating': selfRating,
    'note': note,
  };

  factory Session.fromMap(Map<String, dynamic> map) => Session(
    id: map['id'] as String,
    habitId: map['habitId'] as String,
    start: DateTime.parse(map['start'] as String),
    end: map['end'] == null ? null : DateTime.parse(map['end'] as String),
    plannedMinutes: map['plannedMinutes'] as int,
    focusedSeconds: map['focusedSeconds'] as int,
    distractionCount: map['distractionCount'] as int,
    // Dữ liệu lưu từ trước khi có hai trường này thì dùng giá trị mặc định.
    awaySeconds: map['awaySeconds'] as int? ?? 0,
    selfRating: map['selfRating'] as int?,
    note: map['note'] as String? ?? '',
  );
}
