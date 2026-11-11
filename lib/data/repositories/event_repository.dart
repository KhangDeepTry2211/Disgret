// 6.2 Lưu trữ local – nhật ký sự kiện.
import '../hive_boxes.dart';
import '../models/event.dart';
import 'hive_repository.dart';

class EventRepository extends HiveRepository<Event> {
  EventRepository() : super(HiveBoxes.events);

  @override
  Event fromMap(Map<String, dynamic> map) => Event.fromMap(map);

  @override
  Map<String, dynamic> toMap(Event item) => item.toMap();

  @override
  String idOf(Event item) => item.id;

  /// Ghi nhanh một sự kiện xảy ra ngay lúc này.
  Future<void> log(EventType type, {Map<String, dynamic> meta = const {}}) =>
      save(Event(id: newId(), type: type, time: DateTime.now(), meta: meta));

  /// 8.2 Lưu các sự kiện phần Kotlin đã ghi, giữ nguyên thời điểm chúng xảy ra.
  Future<void> saveNativeEvents(List<Map<String, dynamic>> events) async {
    for (final event in events) {
      await save(
        Event(
          id: newId(),
          type: EventType.fromValue(event['type'] as String),
          time: DateTime.fromMillisecondsSinceEpoch(event['time'] as int),
          meta: event['meta'] as Map<String, dynamic>,
        ),
      );
    }
  }

  /// 3.3 Ghi lại một lần xao nhãng, để sau này đo thời gian quay lại.
  Future<void> logSessionDistracted({required int awaySeconds, required int distractionIndex}) {
    return log(
      EventType.sessionDistracted,
      meta: {
        SessionDistractedMeta.awaySeconds: awaySeconds,
        SessionDistractedMeta.distractionIndex: distractionIndex,
      },
    );
  }

  /// 1.4 Ghi lại một lượt xem reel, để sau này đo reel nào khiến người dùng bắt đầu học.
  Future<void> logReelWatched({
    required String reelId,
    required int secondsWatched,
    required bool completed,
    bool startedFocus = false,
  }) {
    return log(
      EventType.reelWatched,
      meta: {
        ReelWatchMeta.reelId: reelId,
        ReelWatchMeta.secondsWatched: secondsWatched,
        ReelWatchMeta.completed: completed,
        if (startedFocus) ReelWatchMeta.startedFocus: true,
      },
    );
  }
}
