// 6.2 Mô hình dữ liệu – nhật ký sự kiện để thống kê hành vi.

enum EventType {
  reelWatched('reel_watched'),
  interventionShown('intervention_shown'),
  choseStudy('chose_study'),
  choseReel('chose_reel'),
  choseBreak('chose_break'),
  sessionDistracted('session_distracted');

  const EventType(this.value);

  /// Tên sự kiện lưu trong Hive, đúng theo mô hình dữ liệu 6.2.
  final String value;

  static EventType fromValue(String value) => values.firstWhere((type) => type.value == value);
}

/// Tên các khoá trong meta của sự kiện reel_watched.
class ReelWatchMeta {
  ReelWatchMeta._();

  static const String reelId = 'reelId';
  static const String secondsWatched = 'secondsWatched';
  static const String completed = 'completed';

  /// Chỉ có khi người dùng bấm "Bắt đầu 5 phút" ngay từ reel này.
  static const String startedFocus = 'startedFocus';
}

/// Tên các khoá trong meta của sự kiện session_distracted.
class SessionDistractedMeta {
  SessionDistractedMeta._();

  static const String awaySeconds = 'awaySeconds';
  static const String distractionIndex = 'distractionIndex';
}

/// 8.2 Tên các khoá trong meta của sự kiện intervention_shown, do phần Kotlin ghi.
class InterventionShownMeta {
  InterventionShownMeta._();

  static const String packageName = 'packageName';
  static const String appLabel = 'appLabel';
  static const String waitSeconds = 'waitSeconds';
}

/// 8.2 Tên khoá trong meta của sự kiện chose_break, do phần Kotlin ghi.
class ChoseBreakMeta {
  ChoseBreakMeta._();

  static const String minutes = 'minutes';
}

class Event {
  const Event({required this.id, required this.type, required this.time, this.meta = const {}});

  final String id;
  final EventType type;
  final DateTime time;

  /// Thông tin thêm tuỳ loại sự kiện, ví dụ {'reelId': 'r1'}.
  final Map<String, dynamic> meta;

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.value,
    'time': time.toIso8601String(),
    'meta': meta,
  };

  factory Event.fromMap(Map<String, dynamic> map) => Event(
    id: map['id'] as String,
    type: EventType.fromValue(map['type'] as String),
    time: DateTime.parse(map['time'] as String),
    meta: Map<String, dynamic>.from(map['meta'] as Map),
  );
}
