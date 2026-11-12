// 4.2 Ghi nhận – một thói quen trong một ngày: đã làm chưa, được bao nhiêu phút.
// Toàn bộ là hàm thuần: nhận dữ liệu vào, trả kết quả ra, không đụng tới Hive,
// nên dễ giải thích và dễ viết unit test. Điểm sức mạnh, streak, hành trình 66 ngày
// nằm ở habit_science.dart và dựa trên các hàm ở đây.
import 'date_utils.dart';
import 'models/habit.dart';
import 'models/habit_log.dart';

class HabitProgress {
  HabitProgress._();

  /// Số phút ghi cho một lần "làm bản 2 phút".
  static const int minimalMinutes = 2;

  /// Tổng phút Focus của thói quen theo từng ngày.
  static Map<DateTime, int> focusMinutesByDay(Habit habit, Iterable<HabitLog> logs) {
    final minutes = <DateTime, int>{};
    for (final log in logs) {
      if (log.habitId == habit.id && log.source == HabitLogSource.focus) {
        minutes[log.date] = (minutes[log.date] ?? 0) + log.minutes;
      }
    }
    return minutes;
  }

  /// Đánh dấu cả ngày (đã làm, bản 2 phút, nghỉ phép) theo từng ngày.
  static Map<DateTime, HabitLog> marksByDay(Habit habit, Iterable<HabitLog> logs) => {
    for (final log in logs)
      if (log.habitId == habit.id && log.source.isDayMark) log.date: log,
  };

  /// Các ngày một thói quen được tính là HOÀN THÀNH (giữ chuỗi):
  /// có tick "đã làm", có làm bản 2 phút, hoặc tổng phút Focus trong ngày >= minMinutesPerDay.
  /// Ngày nghỉ phép KHÔNG phải ngày hoàn thành; việc nó giữ chuỗi do habit_science.dart xử lý.
  static Set<DateTime> doneDays(Habit habit, Iterable<HabitLog> logs) {
    final done = <DateTime>{};
    for (final entry in marksByDay(habit, logs).entries) {
      if (entry.value.source != HabitLogSource.freeze) done.add(entry.key);
    }
    for (final entry in focusMinutesByDay(habit, logs).entries) {
      if (entry.value >= habit.minMinutesPerDay) done.add(entry.key);
    }
    return done;
  }

  static bool isDone(Habit habit, DateTime day, Iterable<HabitLog> logs) =>
      doneDays(habit, logs).contains(dateOnly(day));

  /// Đánh dấu của thói quen trong ngày (manual, minimal hoặc freeze); null nếu chưa có.
  static HabitLog? markLogOn(Habit habit, DateTime day, Iterable<HabitLog> logs) {
    final target = dateOnly(day);
    for (final log in logs) {
      if (log.habitId == habit.id && log.date == target && log.source.isDayMark) return log;
    }
    return null;
  }

  /// Số phút hiện dưới vòng tiến độ. Tick "đã làm" thì ít nhất là mức tối thiểu,
  /// làm bản 2 phút thì ít nhất 2 phút. Phút Focus đã có không bị cộng thêm
  /// vào phần đánh dấu (tránh tính hai lần).
  static int minutesOn(Habit habit, DateTime day, Iterable<HabitLog> logs) {
    final target = dateOnly(day);
    final focusMinutes = focusMinutesByDay(habit, logs)[target] ?? 0;
    final markMinutes = switch (markLogOn(habit, target, logs)?.source) {
      HabitLogSource.manual => habit.minMinutesPerDay,
      HabitLogSource.minimal => minimalMinutes,
      _ => 0,
    };
    return focusMinutes > markMinutes ? focusMinutes : markMinutes;
  }
}
