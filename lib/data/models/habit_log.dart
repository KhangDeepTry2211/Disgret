// 6.2 Mô hình dữ liệu – một lần ghi nhận thói quen trong ngày (4.2 Ghi nhận).
import '../date_utils.dart';

/// Nguồn ghi nhận. Tên enum chính là giá trị lưu trong Hive.
/// - manual: tự tick "đã làm" (đủ mức tối thiểu).
/// - focus: số phút thật từ một phiên Focus.
/// - minimal: chỉ làm phiên bản 2 phút; vẫn giữ chuỗi nhưng điểm sức mạnh chỉ cộng một nửa.
/// - freeze: ngày nghỉ phép; không làm đứt chuỗi, điểm sức mạnh giữ nguyên.
/// - skip: chủ động bỏ hôm nay (vẫn tính là không làm); ghi lại để biết là bỏ có chủ đích.
enum HabitLogSource {
  manual,
  focus,
  minimal,
  freeze,
  skip;

  /// Các nguồn được tính là ĐÃ LÀM khi đánh dấu cả ngày.
  bool get countsAsDone => this == manual || this == minimal;

  /// Các nguồn do người dùng tự đánh dấu cho cả ngày; mỗi ngày chỉ có tối đa một loại.
  bool get isDayMark => this != focus;
}

class HabitLog {
  HabitLog({
    required this.id,
    required this.habitId,
    required DateTime date,
    required this.source,
    required this.minutes,
    this.note = '',
  }) : date = dateOnly(date);

  final String id;
  final String habitId;

  /// Chỉ gồm ngày, phần giờ phút luôn bị bỏ khi tạo log.
  final DateTime date;
  final HabitLogSource source;
  final int minutes;

  /// Ghi chú ngắn, không bắt buộc; rỗng nghĩa là không có.
  final String note;

  HabitLog copyWith({String? note}) => HabitLog(
    id: id,
    habitId: habitId,
    date: date,
    source: source,
    minutes: minutes,
    note: note ?? this.note,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'habitId': habitId,
    'date': dateKey(date),
    'source': source.name,
    'minutes': minutes,
    'note': note,
  };

  factory HabitLog.fromMap(Map<String, dynamic> map) => HabitLog(
    id: map['id'] as String,
    habitId: map['habitId'] as String,
    date: DateTime.parse(map['date'] as String),
    source: HabitLogSource.values.byName(map['source'] as String),
    minutes: map['minutes'] as int,
    note: map['note'] as String,
  );
}
