// 6.2 Mô hình dữ liệu – một lần ghi nhận thói quen trong ngày (4.2 Ghi nhận).
import '../date_utils.dart';

/// Nguồn ghi nhận: tự tick tay, hoặc từ một phiên Focus.
/// Tên enum chính là giá trị lưu trong Hive: "manual" và "focus".
enum HabitLogSource { manual, focus }

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
