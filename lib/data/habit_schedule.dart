// 4.1, 4.2 Lịch của thói quen: hôm nay có "đến hạn" không. Toàn bộ là hàm thuần, có unit test
// (test/habit_schedule_test.dart).
//
// Một thói quen ĐẾN HẠN vào một ngày khi:
// 1. Ngày đó nằm trong thời gian hiệu lực: từ ngày bắt đầu (startDate) đến ngày kết thúc
//    (endRule: không kết thúc / đến ngày endDate / sau endAfterDays ngày kể cả ngày bắt đầu).
// 2. Ngày đó khớp lịch lặp lại:
//    - Việc một lần: đúng ngày dueDate.
//    - Hằng ngày: ngày nào cũng đến hạn.
//    - Hằng tuần theo thứ: đúng các thứ đã chọn.
//    - Hằng tuần theo số ngày: tuần này (T2–CN) chưa làm đủ daysPerWeek ngày.
//    - Hằng tháng: đúng các ngày đã chọn; chọn ngày 29–31 mà tháng không có thì làm vào ngày
//      cuối tháng.
import 'date_utils.dart';
import 'models/habit.dart';

class HabitSchedule {
  HabitSchedule._();

  /// Ngày cuối cùng còn hiệu lực (tính cả ngày đó); null nếu không kết thúc.
  static DateTime? lastDay(Habit habit) {
    if (habit.type == HabitType.oneTime) return habit.dueDate;
    switch (habit.endRule) {
      case HabitEndRule.never:
        return null;
      case HabitEndRule.onDate:
        return habit.endDate == null ? null : dateOnly(habit.endDate!);
      case HabitEndRule.afterDays:
        final start = habit.startDate;
        // Dữ liệu cũ không có ngày bắt đầu thì không biết đếm từ đâu: coi như không kết thúc.
        return start == null ? null : addDays(dateOnly(start), habit.endAfterDays - 1);
    }
  }

  /// Ngày nằm trong thời gian hiệu lực của thói quen.
  static bool isActiveOn(Habit habit, DateTime day) {
    final target = dateOnly(day);
    final start = habit.startDate;
    if (start != null && target.isBefore(dateOnly(start))) return false;
    final end = lastDay(habit);
    return end == null || !target.isAfter(end);
  }

  /// Ngày khớp LỊCH của thói quen (chưa xét số ngày đã làm trong tuần).
  /// Hằng tuần theo số ngày thì ngày nào cũng có thể làm nên luôn khớp.
  /// Dùng để biết ngày nào là "ngày nghỉ theo lịch": không làm đứt chuỗi, không trừ điểm.
  static bool isScheduledOn(Habit habit, DateTime day) {
    final target = dateOnly(day);
    if (!isActiveOn(habit, target)) return false;
    if (habit.type == HabitType.oneTime) {
      return habit.dueDate != null && dateOnly(habit.dueDate!) == target;
    }
    switch (habit.repeat) {
      case HabitRepeat.daily:
        return true;
      case HabitRepeat.weekly:
        return habit.weekdays.isEmpty || habit.weekdays.contains(target.weekday);
      case HabitRepeat.monthly:
        return matchesMonthDay(habit.monthDays, target);
    }
  }

  /// Thói quen ĐẾN HẠN vào [day]. [doneDaysThisWeek] là số ngày KHÁC [day] trong cùng tuần
  /// (T2–CN) đã hoàn thành; chỉ cần cho hằng tuần theo số ngày.
  static bool isDueOn(Habit habit, DateTime day, {int doneDaysThisWeek = 0}) {
    if (!isScheduledOn(habit, day)) return false;
    if (habit.type == HabitType.regular && habit.isWeeklyByCount) {
      return doneDaysThisWeek < habit.daysPerWeek;
    }
    return true;
  }

  /// Ngày trong tháng có khớp danh sách đã chọn không. Chọn ngày lớn hơn số ngày của tháng
  /// (ví dụ 31 ở tháng 4) thì tính là ngày cuối tháng.
  static bool matchesMonthDay(List<int> monthDays, DateTime day) {
    final lastOfMonth = DateTime(day.year, day.month + 1, 0).day;
    return monthDays.any(
      (selected) => (selected > lastOfMonth ? lastOfMonth : selected) == day.day,
    );
  }

  /// Số ngày khác [day] trong cùng tuần (T2–CN) nằm trong [doneDays].
  static int doneDaysInWeekExcept(Set<DateTime> doneDays, DateTime day) {
    final target = dateOnly(day);
    final monday = weekStart(target);
    var count = 0;
    for (var i = 0; i < 7; i++) {
      final other = addDays(monday, i);
      if (other != target && doneDays.contains(other)) count++;
    }
    return count;
  }

  /// Tần suất lặp lại, ví dụ "Hằng ngày", "5 ngày/tuần", "T2, T4, T6", "Ngày 3, 8 hằng tháng".
  static String describeRepeat(Habit habit) {
    if (habit.type == HabitType.oneTime) {
      final due = habit.dueDate;
      return due == null ? 'Việc một lần' : 'Việc một lần · ${due.day}/${due.month}';
    }
    switch (habit.repeat) {
      case HabitRepeat.daily:
        return 'Hằng ngày';
      case HabitRepeat.weekly:
        return habit.weekdays.isEmpty
            ? '${habit.daysPerWeek} ngày/tuần'
            : ([...habit.weekdays]..sort()).map((day) => weekdayShort[day - 1]).join(', ');
      case HabitRepeat.monthly:
        return 'Ngày ${([...habit.monthDays]..sort()).join(', ')} hằng tháng';
    }
  }

  /// Mô tả ngắn lịch của thói quen để hiện trên thẻ, ví dụ "T2, T4, T6 · Tối".
  static String describe(Habit habit) {
    final parts = [describeRepeat(habit)];
    switch (habit.timeOfDay) {
      case HabitTimeOfDay.morning:
        parts.add('Sáng');
      case HabitTimeOfDay.afternoon:
        parts.add('Chiều');
      case HabitTimeOfDay.evening:
        parts.add('Tối');
      case HabitTimeOfDay.anytime:
        break;
    }
    return parts.join(' · ');
  }
}
