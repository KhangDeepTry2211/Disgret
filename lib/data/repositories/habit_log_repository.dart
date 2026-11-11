// 6.2 Lưu trữ local – nhật ký thói quen (4.2 Ghi nhận).
import '../date_utils.dart';
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
  static String manualLogId(String habitId, DateTime day) => 'manual_${habitId}_${dateKey(day)}';

  /// Tick "Hôm nay đã làm": tick nghĩa là đã làm đủ mức tối thiểu của thói quen.
  Future<void> markDone(Habit habit, DateTime day) async {
    final id = manualLogId(habit.id, day);
    if (getById(id) != null) return; // Đã tick rồi thì giữ nguyên, không mất ghi chú.
    await save(
      HabitLog(
        id: id,
        habitId: habit.id,
        date: day,
        source: HabitLogSource.manual,
        minutes: habit.minMinutesPerDay,
      ),
    );
  }

  /// Bỏ tick: chỉ xoá log manual, phút học thật từ log focus vẫn được giữ.
  Future<void> unmarkDone(String habitId, DateTime day) => delete(manualLogId(habitId, day));

  /// Lưu ghi chú cho log manual của ngày đó; chưa tick thì không có gì để lưu.
  Future<void> saveNote(String habitId, DateTime day, String note) async {
    final log = getById(manualLogId(habitId, day));
    if (log == null) return;
    await save(log.copyWith(note: note.trim()));
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
