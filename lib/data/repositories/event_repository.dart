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
  ///
  /// Returns the event id. Passing that [id] again replaces the same record instead of adding a
  /// second one (one record per reel shown, spec 002 edge case "app goes to the background").
  Future<String> logReelWatched({
    required String reelId,
    required int secondsWatched,
    required bool completed,
    bool startedFocus = false,
    String? id,
  }) async {
    final eventId = id ?? newId();
    await save(
      Event(
        id: eventId,
        type: EventType.reelWatched,
        time: DateTime.now(),
        meta: {
          ReelWatchMeta.reelId: reelId,
          ReelWatchMeta.secondsWatched: secondsWatched,
          ReelWatchMeta.completed: completed,
          if (startedFocus) ReelWatchMeta.startedFocus: true,
        },
      ),
    );
    return eventId;
  }

  /// 1.4 Ghi thích, bỏ thích, bình luận, chia sẻ reel (meta chỉ có reelId).
  Future<void> logReelAction(EventType type, String reelId) =>
      log(type, meta: {ReelActionMeta.reelId: reelId});

  /// Spec 002: the motivation step was skipped at reel [position] (1-based).
  Future<void> logMotivationSkipped({required String context, required int position}) {
    return log(
      EventType.motivationSkipped,
      meta: {MotivationSkippedMeta.context: context, MotivationSkippedMeta.position: position},
    );
  }
}
