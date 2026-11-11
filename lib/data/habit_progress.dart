// 4.2 Ghi nhận – quy tắc hoàn thành và streak.
// Toàn bộ là hàm thuần: nhận dữ liệu vào, trả kết quả ra, không đụng tới Hive,
// nên dễ giải thích và dễ viết unit test.
import 'date_utils.dart';
import 'models/habit.dart';
import 'models/habit_log.dart';

class HabitProgress {
  HabitProgress._();

  /// Các ngày một thói quen được tính là HOÀN THÀNH:
  /// có log manual, hoặc tổng phút từ log focus trong ngày >= minMinutesPerDay.
  static Set<DateTime> doneDays(Habit habit, Iterable<HabitLog> logs) {
    final done = <DateTime>{};
    final focusMinutes = <DateTime, int>{};

    for (final log in logs.where((log) => log.habitId == habit.id)) {
      if (log.source == HabitLogSource.manual) {
        done.add(log.date);
      } else {
        final total = (focusMinutes[log.date] ?? 0) + log.minutes;
        focusMinutes[log.date] = total;
        if (total >= habit.minMinutesPerDay) done.add(log.date);
      }
    }
    return done;
  }

  static bool isDone(Habit habit, DateTime day, Iterable<HabitLog> logs) =>
      doneDays(habit, logs).contains(dateOnly(day));

  /// Log tick tay của thói quen trong ngày; null nếu chưa tick.
  static HabitLog? manualLogOn(Habit habit, DateTime day, Iterable<HabitLog> logs) {
    final target = dateOnly(day);
    for (final log in logs) {
      if (log.habitId == habit.id && log.date == target && log.source == HabitLogSource.manual) {
        return log;
      }
    }
    return null;
  }

  /// Số phút hiện trên thanh tiến độ. Có tick thì ít nhất là mức tối thiểu,
  /// phút focus đã có không bị cộng thêm vào phần tick (tránh tính hai lần).
  static int minutesOn(Habit habit, DateTime day, Iterable<HabitLog> logs) {
    final target = dateOnly(day);
    var focusMinutes = 0;
    var ticked = false;

    for (final log in logs.where((log) => log.habitId == habit.id && log.date == target)) {
      if (log.source == HabitLogSource.manual) {
        ticked = true;
      } else {
        focusMinutes += log.minutes;
      }
    }

    if (ticked && focusMinutes < habit.minMinutesPerDay) return habit.minMinutesPerDay;
    return focusMinutes;
  }

  /// Streak riêng của một thói quen.
  static int habitStreak(Habit habit, Iterable<HabitLog> logs, {required DateTime today}) =>
      _countStreak(doneDays(habit, logs), today);

  /// Streak chung: số ngày liên tiếp có ít nhất một thói quen hoàn thành.
  static int overallStreak(
    Iterable<Habit> habits,
    Iterable<HabitLog> logs, {
    required DateTime today,
  }) {
    final done = <DateTime>{};
    for (final habit in habits) {
      done.addAll(doneDays(habit, logs));
    }
    return _countStreak(done, today);
  }

  /// Đếm lùi từ hôm nay. Hôm nay chưa làm thì chuỗi vẫn giữ, tính từ hôm qua.
  static int _countStreak(Set<DateTime> done, DateTime today) {
    var day = dateOnly(today);
    if (!done.contains(day)) day = previousDay(day);

    var streak = 0;
    while (done.contains(day)) {
      streak++;
      day = previousDay(day);
    }
    return streak;
  }
}
