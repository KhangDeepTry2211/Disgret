// 6.2 Lưu trữ local – nhật ký thói quen (4.2 Ghi nhận).
import '../date_utils.dart';
import '../habit_progress.dart';
import '../hive_boxes.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/session.dart';
import 'hive_repository.dart';

class HabitLogRepository extends HiveRepository<HabitLog> {
  HabitLogRepository() : super(HiveBoxes.habitLogs);

  @override
  HabitLog fromMap(Map<String, dynamic> map) => HabitLog.fromMap(map);

  @override
  Map<String, dynamic> toMap(HabitLog item) => item.toMap();

  @override
  String idOf(HabitLog item) => item.id;

  /// Mỗi thói quen có tối đa một log manual mỗi ngày nên id được ghép cố định,
  /// nhờ vậy bấm tick hai lần cũng không tạo log trùng.
  static String manualLogId(String habitId, DateTime day) =>
      markLogId(HabitLogSource.manual, habitId, day);

  /// Id cố định của một đánh dấu cả ngày (manual, minimal, freeze),
  /// ví dụ "minimal_h1_2026-11-12".
  static String markLogId(HabitLogSource source, String habitId, DateTime day) =>
      '${source.name}_${habitId}_${dateKey(day)}';

  /// Tick "Hôm nay đã làm": tick nghĩa là đã làm đủ mức tối thiểu của thói quen.
  Future<void> markDone(Habit habit, DateTime day) => setMark(habit, day, HabitLogSource.manual);

  /// 4.2 Đánh dấu cả ngày: đã làm, làm bản 2 phút, hoặc nghỉ phép. Mỗi ngày chỉ giữ một loại,
  /// nên đánh dấu loại mới thì xoá loại cũ. Đánh dấu lại đúng loại cũ thì giữ nguyên ghi chú.
  Future<void> setMark(Habit habit, DateTime day, HabitLogSource source) async {
    assert(source.isDayMark, 'Log focus chỉ được tạo từ phiên Focus');
    final id = markLogId(source, habit.id, day);
    if (getById(id) != null) return;
    final old = _markOn(habit.id, day);
    await clearMarks(habit.id, day);
    await save(
      HabitLog(
        id: id,
        habitId: habit.id,
        date: day,
        source: source,
        minutes: switch (source) {
          HabitLogSource.manual => habit.minMinutesPerDay,
          HabitLogSource.minimal => HabitProgress.minimalMinutes,
          _ => 0,
        },
        // Đổi từ "đã làm" sang "bản 2 phút" thì vẫn giữ ghi chú đã viết.
        note: source == HabitLogSource.freeze ? '' : old?.note ?? '',
      ),
    );
  }

  /// Bỏ đánh dấu cả ngày; phút học thật từ log focus vẫn được giữ.
  Future<void> clearMarks(String habitId, DateTime day) async {
    for (final source in HabitLogSource.values.where((source) => source.isDayMark)) {
      await delete(markLogId(source, habitId, day));
    }
  }

  /// Bỏ tick: giống [clearMarks], giữ tên cũ cho dễ đọc ở nơi gọi.
  Future<void> unmarkDone(String habitId, DateTime day) => clearMarks(habitId, day);

  /// Lưu ghi chú cho đánh dấu của ngày đó (đã làm hoặc bản 2 phút); chưa có thì không lưu gì.
  Future<void> saveNote(String habitId, DateTime day, String note) async {
    final log = _markOn(habitId, day);
    if (log == null || log.source == HabitLogSource.freeze) return;
    await save(log.copyWith(note: note.trim()));
  }

  HabitLog? _markOn(String habitId, DateTime day) {
    for (final source in HabitLogSource.values.where((source) => source.isDayMark)) {
      final log = getById(markLogId(source, habitId, day));
      if (log != null) return log;
    }
    return null;
  }

  /// 4.2 Dành cho GĐ4: ghi số phút tập trung thực của một phiên Focus.
  /// Id ghép từ id phiên nên gọi lại cho cùng phiên cũng không bị cộng dồn hai lần.
  /// Phiên dưới 1 phút không tạo log. Phiên qua nửa đêm tính cho ngày bắt đầu.
  Future<void> recordSession(Session session) async {
    final minutes = session.focusedSeconds ~/ 60;
    if (minutes == 0) return;
    await save(
      HabitLog(
        id: 'focus_${session.id}',
        habitId: session.habitId,
        date: session.start,
        source: HabitLogSource.focus,
        minutes: minutes,
      ),
    );
  }

  /// Xoá toàn bộ log của một thói quen, dùng khi xoá thói quen đó.
  Future<void> deleteByHabit(String habitId) async {
    for (final log in getAll().where((log) => log.habitId == habitId)) {
      await delete(log.id);
    }
  }
}
