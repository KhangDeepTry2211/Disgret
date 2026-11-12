// 4.2 Habit tracker có cơ sở khoa học – toàn bộ là hàm thuần, có unit test.
//
// 1. Điểm sức mạnh (0–100%): trung bình trượt hàm mũ của việc "có làm hay không" mỗi ngày.
//      điểm(ngày) = điểm(hôm trước) × (1 − α) + α × done(ngày)
//    với α = 1 − 0.05^(1/66) ≈ 0.0444. Làm đều 66 ngày liên tục (mốc trung bình để một hành vi
//    thành tự động, theo Lally và cộng sự, 2010) thì điểm đi từ 0 lên 1 − 0.05 = 95%.
//    Bỏ một ngày chỉ làm điểm giảm khoảng 4%, nên một lần lỡ không xoá sạch công sức trước đó.
// 2. Streak có ngày nghỉ phép: mỗi tuần (T2–CN) tối đa 1 ngày "freeze" không làm đứt chuỗi.
// 3. "Không bỏ 2 lần liên tiếp": hôm qua bỏ thì hôm nay nhắc làm bản 2 phút.
// 4. Hành trình 66 ngày: tổng số ngày hoàn thành, không cần liên tiếp, có 4 huy hiệu.
// 5. Thống kê: chuỗi hiện tại, dài nhất, tỉ lệ 30 ngày, ngày trong tuần hay bỏ nhất.
import 'dart:math' as math;

import 'date_utils.dart';
import 'habit_progress.dart';
import 'models/habit.dart';
import 'models/habit_log.dart';

/// Một huy hiệu trên Hành trình 66 ngày.
typedef HabitBadge = ({int days, String name});

/// Lịch sử của MỘT thói quen, dựng một lần từ danh sách log rồi dùng cho mọi phép tính.
class HabitHistory {
  HabitHistory._({
    required this.habit,
    required this.focusMinutes,
    required this.marks,
    required this.doneDays,
    required this.freezeDays,
    required this.start,
  });

  factory HabitHistory.of(Habit habit, Iterable<HabitLog> logs) {
    final focusMinutes = HabitProgress.focusMinutesByDay(habit, logs);
    final marks = {
      for (final entry in HabitProgress.marksByDay(habit, logs).entries)
        entry.key: entry.value.source,
    };
    final doneDays = HabitProgress.doneDays(habit, logs);
    final requested = {
      for (final entry in marks.entries)
        if (entry.value == HabitLogSource.freeze) entry.key,
    };
    final allDays = [...focusMinutes.keys, ...marks.keys]..sort();
    return HabitHistory._(
      habit: habit,
      focusMinutes: focusMinutes,
      marks: marks,
      doneDays: doneDays,
      freezeDays: HabitScience.validFreezeDays(requested, doneDays),
      start: allDays.isEmpty ? null : allDays.first,
    );
  }

  final Habit habit;
  final Map<DateTime, int> focusMinutes;
  final Map<DateTime, HabitLogSource> marks;
  final Set<DateTime> doneDays;

  /// Ngày nghỉ phép ĐƯỢC TÍNH (đã áp luật mỗi tuần tối đa 1 ngày).
  final Set<DateTime> freezeDays;

  /// Ngày đầu tiên có ghi nhận; null nếu thói quen chưa có ghi nhận nào.
  final DateTime? start;

  bool isDone(DateTime day) => doneDays.contains(dateOnly(day));
  bool isFreeze(DateTime day) => freezeDays.contains(dateOnly(day));

  /// Mức hoàn thành của một ngày, từ 0 đến 1:
  /// tick "đã làm" = 1; bản 2 phút = 0.5; Focus = min(1, phút đã làm / minMinutesPerDay).
  /// Có nhiều nguồn trong một ngày thì lấy mức cao nhất.
  double valueOn(DateTime day) {
    final target = dateOnly(day);
    final minutes = focusMinutes[target] ?? 0;
    var value = math.min(1.0, minutes / habit.minMinutesPerDay);
    switch (marks[target]) {
      case HabitLogSource.manual:
        value = 1;
      case HabitLogSource.minimal:
        value = math.max(value, HabitScience.minimalValue);
      default:
        break;
    }
    return value;
  }
}

class HabitScience {
  HabitScience._();

  /// Số ngày trung bình để một hành vi thành tự động (Lally và cộng sự, 2010).
  static const int habitFormationDays = 66;

  /// Hệ số α của điểm sức mạnh: làm đều [habitFormationDays] ngày thì đạt 95%.
  static final double alpha = 1 - math.pow(0.05, 1 / habitFormationDays).toDouble();

  /// Làm bản 2 phút được tính nửa ngày trong điểm sức mạnh.
  static const double minimalValue = 0.5;

  /// 4 huy hiệu trên Hành trình 66 ngày.
  static const List<HabitBadge> badges = [
    (days: 7, name: 'Khởi động'),
    (days: 21, name: 'Bền bỉ'),
    (days: 40, name: 'Vững vàng'),
    (days: 66, name: 'Thành thói quen'),
  ];

  // ---------- 2. Ngày nghỉ phép ----------

  /// Lọc các ngày xin nghỉ phép: ngày đã hoàn thành thì không cần nghỉ phép,
  /// và mỗi tuần (T2–CN) chỉ tính ngày nghỉ phép SỚM NHẤT.
  static Set<DateTime> validFreezeDays(Iterable<DateTime> requested, Set<DateTime> doneDays) {
    final sorted = requested.where((day) => !doneDays.contains(day)).toList()..sort();
    final usedWeeks = <DateTime>{};
    return {
      for (final day in sorted)
        if (usedWeeks.add(weekStart(day))) day,
    };
  }

  /// Có được xin nghỉ phép vào [day] không: tuần đó chưa có ngày nghỉ phép nào khác.
  static bool canFreeze(Habit habit, Iterable<HabitLog> logs, DateTime day) {
    final target = dateOnly(day);
    final week = weekStart(target);
    return !logs.any(
      (log) =>
          log.habitId == habit.id &&
          log.source == HabitLogSource.freeze &&
          log.date != target &&
          weekStart(log.date) == week,
    );
  }

  // ---------- 2. Streak ----------

  /// Đếm lùi từ hôm nay: ngày hoàn thành cộng 1, ngày nghỉ phép bỏ qua (không cộng, không đứt),
  /// ngày khác thì dừng. Hôm nay chưa làm thì chuỗi vẫn giữ, tính từ hôm qua.
  static int currentStreakOf(Set<DateTime> done, Set<DateTime> freezes, DateTime today) {
    var day = dateOnly(today);
    if (!done.contains(day)) day = previousDay(day);

    var streak = 0;
    while (done.contains(day) || freezes.contains(day)) {
      if (done.contains(day)) streak++;
      day = previousDay(day);
    }
    return streak;
  }

  /// Chuỗi dài nhất từng có, cùng luật với [currentStreakOf].
  static int longestStreakOf(Set<DateTime> done, Set<DateTime> freezes) {
    if (done.isEmpty) return 0;
    final days = {...done, ...freezes}.toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final day in days) {
      // Có khoảng trống giữa hai ngày thì chuỗi đứt.
      if (previous != null && daysBetween(previous, day) > 1) run = 0;
      if (done.contains(day)) run++;
      best = math.max(best, run);
      previous = day;
    }
    return best;
  }

  /// Streak riêng của một thói quen.
  static int habitStreak(Habit habit, Iterable<HabitLog> logs, {required DateTime today}) {
    final history = HabitHistory.of(habit, logs);
    return currentStreakOf(history.doneDays, history.freezeDays, today);
  }

  /// Streak chung (vòng streak ở Trang chủ): số ngày liên tiếp có ít nhất một thói quen
  /// hoàn thành. Ngày nghỉ phép của các thói quen cũng giữ chuỗi, vẫn tối đa 1 ngày mỗi tuần.
  static int overallStreak(
    Iterable<Habit> habits,
    Iterable<HabitLog> logs, {
    required DateTime today,
  }) {
    final done = <DateTime>{};
    final freezes = <DateTime>{};
    for (final habit in habits) {
      final history = HabitHistory.of(habit, logs);
      done.addAll(history.doneDays);
      freezes.addAll(history.freezeDays);
    }
    return currentStreakOf(done, validFreezeDays(freezes, done), today);
  }

  // ---------- 1. Điểm sức mạnh ----------

  /// Điểm sức mạnh của từng ngày trong [days] ngày gần nhất (phần tử cuối là hôm nay).
  /// Tính từ ngày đầu tiên có ghi nhận, điểm khởi đầu là 0:
  /// - ngày nghỉ phép: giữ nguyên điểm;
  /// - ngày khác: điểm = điểm × (1 − α) + α × mức hoàn thành.
  /// Hôm nay chưa hết ngày nên chỉ được cộng, không bị trừ khi chưa làm.
  static List<double> strengthHistory(HabitHistory history, DateTime today, {int days = 60}) {
    final end = dateOnly(today);
    final firstShown = addDays(end, 1 - days);
    final result = <double>[];
    var score = 0.0;

    final start = history.start;
    if (start == null || start.isAfter(end)) return List.filled(days, 0);

    var day = start.isBefore(firstShown) ? start : firstShown;
    while (!day.isAfter(end)) {
      final tracked = !day.isBefore(start);
      if (tracked && !history.isFreeze(day)) {
        final next = score * (1 - alpha) + alpha * history.valueOn(day);
        score = day == end ? math.max(score, next) : next;
      }
      if (!day.isBefore(firstShown)) result.add(score);
      day = addDays(day, 1);
    }
    return result;
  }

  /// Điểm sức mạnh hôm nay, từ 0 đến 1.
  static double strength(Habit habit, Iterable<HabitLog> logs, {required DateTime today}) =>
      strengthHistory(HabitHistory.of(habit, logs), today, days: 1).last;

  /// Điểm sức mạnh trung bình của các thói quen (Trang chủ); chưa có thói quen thì 0.
  static double averageStrength(
    Iterable<Habit> habits,
    Iterable<HabitLog> logs, {
    required DateTime today,
  }) {
    if (habits.isEmpty) return 0;
    final total = habits.fold(0.0, (sum, habit) => sum + strength(habit, logs, today: today));
    return total / habits.length;
  }

  // ---------- 3. Không bỏ 2 lần liên tiếp ----------

  /// Hôm qua bỏ (không làm, không nghỉ phép) và hôm nay chưa làm: nhắc làm bản 2 phút.
  /// Thói quen mới (chưa có ghi nhận trước hôm qua) thì chưa nhắc.
  static bool missedYesterday(HabitHistory history, DateTime today) {
    final day = dateOnly(today);
    final yesterday = previousDay(day);
    final start = history.start;
    if (start == null || !start.isBefore(yesterday)) return false;
    return !history.isDone(day) && !history.isDone(yesterday) && !history.isFreeze(yesterday);
  }

  // ---------- 4. Hành trình 66 ngày ----------

  /// Tổng số ngày hoàn thành (kể cả bản 2 phút), không cần liên tiếp.
  static int journeyDays(HabitHistory history) => history.doneDays.length;

  /// Huy hiệu kế tiếp chưa đạt; null nếu đã đạt đủ 4 huy hiệu.
  static HabitBadge? nextBadge(int journeyDays) {
    for (final badge in badges) {
      if (journeyDays < badge.days) return badge;
    }
    return null;
  }

  // ---------- 5. Thống kê ----------

  /// Các ngày dùng để tính tỉ lệ, từ [from] đến [to]: bỏ các ngày trước khi bắt đầu theo dõi,
  /// ngày nghỉ phép, và hôm nay nếu chưa làm (vì hôm nay chưa kết thúc).
  static List<DateTime> trackedDays(
    HabitHistory history,
    DateTime from,
    DateTime to, {
    required DateTime today,
  }) {
    final start = history.start;
    if (start == null) return const [];
    final end = dateOnly(today);
    final days = <DateTime>[];
    for (var day = dateOnly(from); !day.isAfter(to); day = addDays(day, 1)) {
      if (day.isBefore(start) || day.isAfter(end) || history.isFreeze(day)) continue;
      if (day == end && !history.isDone(day)) continue;
      days.add(day);
    }
    return days;
  }

  /// Tỉ lệ ngày hoàn thành trong khoảng [from]–[to], từ 0 đến 1.
  static double completionRate(
    HabitHistory history,
    DateTime from,
    DateTime to, {
    required DateTime today,
  }) {
    final days = trackedDays(history, from, to, today: today);
    if (days.isEmpty) return 0;
    return days.where(history.isDone).length / days.length;
  }

  /// Thứ trong tuần hay bỏ nhất (DateTime.monday ... DateTime.sunday) trên toàn bộ lịch sử;
  /// bằng nhau thì lấy thứ sớm hơn trong tuần. null nếu chưa bỏ ngày nào.
  static int? mostMissedWeekday(HabitHistory history, {required DateTime today}) {
    final start = history.start;
    if (start == null) return null;
    final misses = List.filled(7, 0);
    for (final day in trackedDays(history, start, today, today: today)) {
      if (!history.isDone(day)) misses[day.weekday - 1]++;
    }
    final most = misses.reduce(math.max);
    return most == 0 ? null : misses.indexOf(most) + 1;
  }

  // ---------- Lịch nhiệt ----------

  /// Đổi mức hoàn thành (0–1) thành 4 mức màu của lịch nhiệt:
  /// 0 = chưa làm, 1 = làm được ít, 2 = làm được nửa (bản 2 phút), 3 = hoàn thành.
  static int heatLevel(double value) {
    if (value <= 0) return 0;
    if (value < minimalValue) return 1;
    if (value < 1) return 2;
    return 3;
  }

  /// Mức hoàn thành trung bình của nhiều thói quen trong một ngày, từ 0 đến 1.
  /// Thói quen đang nghỉ phép ngày đó không tính vào; null nếu không có thói quen nào để tính.
  static double? dayCompletion(List<HabitHistory> histories, DateTime day) {
    final counted = histories.where((history) => !history.isFreeze(day)).toList();
    if (counted.isEmpty) return null;
    return counted.fold(0.0, (sum, history) => sum + history.valueOn(day)) / counted.length;
  }

  // ---------- Ý định thực hiện ----------

  /// Câu xác nhận ở bước cuối khi tạo thói quen, ví dụ
  /// "Sau khi ăn tối, tôi sẽ học 25 phút tại bàn học."
  static String intentionSentence({
    required String name,
    required int minutes,
    String cue = '',
    String place = '',
  }) {
    final action = name.trim();
    final verb = action.isEmpty ? 'làm' : action[0].toLowerCase() + action.substring(1);
    final buffer = StringBuffer();
    if (cue.trim().isNotEmpty) {
      buffer.write('Sau khi ${cue.trim()}, tôi sẽ');
    } else {
      buffer.write('Mỗi ngày, tôi sẽ');
    }
    buffer.write(' $verb $minutes phút');
    if (place.trim().isNotEmpty) buffer.write(' tại ${place.trim()}');
    buffer.write('.');
    return buffer.toString();
  }
}
