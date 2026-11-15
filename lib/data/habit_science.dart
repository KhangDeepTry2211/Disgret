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
// 6. Báo cáo: "ngày hoàn hảo" (mọi thói quen đến hạn đều xong) và số lần hoàn thành theo kỳ.
//
// Ngày NGHỈ (isRest) = ngày nghỉ phép được tính, hoặc ngày không có trong lịch của thói quen
// (ví dụ thói quen hằng tuần vào T2, T4, T6 thì T3 là ngày nghỉ, xem habit_schedule.dart).
// Ngày nghỉ không làm đứt chuỗi, không cộng vào chuỗi và giữ nguyên điểm sức mạnh.
import 'dart:math' as math;

import 'date_utils.dart';
import 'habit_progress.dart';
import 'habit_schedule.dart';
import 'models/habit.dart';
import 'models/habit_log.dart';

/// Một huy hiệu trên Hành trình 66 ngày.
typedef HabitBadge = ({int days, String name});

/// 6. Kỳ của biểu đồ trong màn Báo cáo.
enum ReportPeriod { thisWeek, lastWeek, thisMonth, lastMonth, sixMonths, thisYear, allTime }

/// Số liệu của một cột (một kỳ con) trên biểu đồ Báo cáo:
/// [completed] lần hoàn thành, [due] lần phải làm (để tính tỉ lệ completed / due).
typedef ReportBucket = ({String label, DateTime from, DateTime to, int completed, int due});

/// Tổng số lần hoàn thành và số lần phải làm trong một khoảng ngày.
typedef ReportTally = ({int completed, int due});

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

  /// Ngày có trong lịch của thói quen (xem habit_schedule.dart).
  bool isScheduled(DateTime day) => HabitSchedule.isScheduledOn(habit, day);

  /// Ngày nghỉ: nghỉ phép, hoặc không có trong lịch mà cũng không làm.
  bool isRest(DateTime day) => isFreeze(day) || (!isScheduled(day) && !isDone(day));

  /// Thói quen đến hạn vào [day] (hằng tuần theo số ngày thì xét cả số ngày đã làm trong tuần).
  bool isDueOn(DateTime day) => HabitSchedule.isDueOn(
    habit,
    day,
    doneDaysThisWeek: HabitSchedule.doneDaysInWeekExcept(doneDays, day),
  );

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
  static int currentStreakOf(Set<DateTime> done, Set<DateTime> freezes, DateTime today) =>
      _countBack(done.contains, freezes.contains, today, earliest: _earliest(done, freezes));

  /// Như [currentStreakOf] nhưng cho một thói quen, có tính cả ngày nghỉ theo lịch.
  static int currentStreak(HabitHistory history, DateTime today) =>
      _countBack(history.isDone, history.isRest, today, earliest: history.start);

  /// Phần chung của các hàm đếm chuỗi: đếm lùi, dừng ở ngày không làm mà cũng không nghỉ,
  /// hoặc khi đã lùi quá ngày [earliest] (trước đó không có dữ liệu).
  static int _countBack(
    bool Function(DateTime) isDone,
    bool Function(DateTime) isRest,
    DateTime today, {
    required DateTime? earliest,
  }) {
    if (earliest == null) return 0;
    var day = dateOnly(today);
    if (!isDone(day)) day = previousDay(day);

    var streak = 0;
    while (!day.isBefore(earliest) && (isDone(day) || isRest(day))) {
      if (isDone(day)) streak++;
      day = previousDay(day);
    }
    return streak;
  }

  static DateTime? _earliest(Set<DateTime> done, Set<DateTime> freezes) {
    final all = [...done, ...freezes]..sort();
    return all.isEmpty ? null : all.first;
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

  /// Chuỗi dài nhất của một thói quen, có tính cả ngày nghỉ theo lịch.
  static int longestStreak(HabitHistory history, DateTime today) {
    final start = history.start;
    if (start == null) return 0;
    var best = 0;
    var run = 0;
    for (var day = start; !day.isAfter(today); day = addDays(day, 1)) {
      if (history.isDone(day)) {
        run++;
      } else if (!history.isRest(day) && day != dateOnly(today)) {
        run = 0;
      }
      best = math.max(best, run);
    }
    return best;
  }

  /// Streak riêng của một thói quen.
  static int habitStreak(Habit habit, Iterable<HabitLog> logs, {required DateTime today}) =>
      currentStreak(HabitHistory.of(habit, logs), today);

  /// Streak chung (vòng streak ở Trang chủ): số ngày liên tiếp có ít nhất một thói quen
  /// hoàn thành. Giữ chuỗi qua ngày nghỉ phép của các thói quen (vẫn tối đa 1 ngày mỗi tuần)
  /// và ngày không thói quen nào có lịch.
  static int overallStreak(
    Iterable<Habit> habits,
    Iterable<HabitLog> logs, {
    required DateTime today,
  }) {
    final histories = [for (final habit in habits) HabitHistory.of(habit, logs)];
    final done = <DateTime>{};
    final freezes = <DateTime>{};
    for (final history in histories) {
      done.addAll(history.doneDays);
      freezes.addAll(history.freezeDays);
    }
    final validFreezes = validFreezeDays(freezes, done);
    return _countBack(
      done.contains,
      (day) =>
          validFreezes.contains(day) || histories.every((history) => !history.isScheduled(day)),
      today,
      earliest: _earliest(done, validFreezes),
    );
  }

  // ---------- 1. Điểm sức mạnh ----------

  /// Điểm sức mạnh của từng ngày trong [days] ngày gần nhất (phần tử cuối là hôm nay).
  /// Tính từ ngày đầu tiên có ghi nhận, điểm khởi đầu là 0:
  /// - ngày nghỉ (nghỉ phép hoặc không có lịch): giữ nguyên điểm;
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
      if (tracked && !history.isRest(day)) {
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

  /// Hôm qua bỏ (có lịch mà không làm, không nghỉ phép) và hôm nay có lịch mà chưa làm:
  /// nhắc làm bản 2 phút. Thói quen mới (chưa có ghi nhận trước hôm qua) thì chưa nhắc.
  static bool missedYesterday(HabitHistory history, DateTime today) {
    final day = dateOnly(today);
    final yesterday = previousDay(day);
    final start = history.start;
    if (start == null || !start.isBefore(yesterday)) return false;
    return history.isScheduled(day) &&
        !history.isDone(day) &&
        !history.isDone(yesterday) &&
        !history.isRest(yesterday);
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
  /// ngày nghỉ (nghỉ phép hoặc không có lịch), và hôm nay nếu chưa làm (vì chưa hết ngày).
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
      if (day.isBefore(start) || day.isAfter(end) || history.isRest(day)) continue;
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
  /// Thói quen đang nghỉ ngày đó (nghỉ phép hoặc không có lịch) không tính vào;
  /// null nếu không có thói quen nào để tính.
  static double? dayCompletion(List<HabitHistory> histories, DateTime day) {
    final counted = histories.where((history) => !history.isRest(day)).toList();
    if (counted.isEmpty) return null;
    return counted.fold(0.0, (sum, history) => sum + history.valueOn(day)) / counted.length;
  }

  // ---------- 6. Báo cáo ----------

  /// Ngày bắt đầu tính báo cáo của một thói quen: ngày tạo (startDate) hoặc ngày ghi nhận đầu
  /// tiên, lấy ngày sớm hơn. Chưa có cả hai thì null (thói quen chưa có gì để tính).
  static DateTime? reportStart(HabitHistory history) {
    final created = history.habit.startDate == null ? null : dateOnly(history.habit.startDate!);
    final first = history.start;
    if (created == null) return first;
    if (first == null) return created;
    return first.isBefore(created) ? first : created;
  }

  /// Thói quen có được tính vào báo cáo ngày [day] không: ngày đã làm luôn được tính (kể cả làm
  /// thêm vào ngày không có lịch, để tỉ lệ không vượt 100%); ngày chưa làm chỉ tính khi đã bắt
  /// đầu theo dõi, đến hạn và không nghỉ phép. Thói quen đã "xoá nhưng giữ lịch sử" chỉ còn
  /// được tính các ngày đã làm (không biết ngày ẩn nên không tính ngày bỏ sau đó).
  static bool countsOn(HabitHistory history, DateTime day) {
    if (history.isDone(day)) return true;
    if (history.habit.archived) return false;
    final start = reportStart(history);
    if (start == null || day.isBefore(start)) return false;
    return history.isDueOn(day) && !history.isFreeze(day);
  }

  /// NGÀY HOÀN HẢO: có ít nhất một thói quen được tính vào ngày đó và tất cả đều xong.
  /// Ngày không có thói quen nào đến hạn thì không tính là ngày hoàn hảo.
  static bool isPerfectDay(List<HabitHistory> histories, DateTime day) {
    final counted = histories.where((history) => countsOn(history, day)).toList();
    return counted.isNotEmpty && counted.every((history) => history.isDone(day));
  }

  /// Số ngày hoàn hảo từ [from] đến [to] (không tính các ngày sau [today]).
  static int perfectDays(
    List<HabitHistory> histories,
    DateTime from,
    DateTime to, {
    required DateTime today,
  }) {
    var count = 0;
    for (final day in _days(from, to, today)) {
      if (isPerfectDay(histories, day)) count++;
    }
    return count;
  }

  /// Cộng số lần hoàn thành và số lần phải làm của mọi thói quen từ [from] đến [to].
  static ReportTally tally(
    List<HabitHistory> histories,
    DateTime from,
    DateTime to, {
    required DateTime today,
  }) {
    var completed = 0;
    var due = 0;
    for (final day in _days(from, to, today)) {
      for (final history in histories) {
        if (history.isDone(day)) completed++;
        if (countsOn(history, day)) due++;
      }
    }
    return (completed: completed, due: due);
  }

  /// Tỉ lệ hoàn thành của một ngày (0–1); null nếu ngày đó không có gì phải làm.
  static double? dayRate(List<HabitHistory> histories, DateTime day, {required DateTime today}) {
    final result = tally(histories, day, day, today: today);
    return result.due == 0 ? null : result.completed / result.due;
  }

  /// Ngày sớm nhất có dữ liệu trong mọi thói quen; null nếu chưa có gì.
  static DateTime? earliestStart(List<HabitHistory> histories) {
    final starts = [for (final history in histories) ?reportStart(history)]..sort();
    return starts.isEmpty ? null : starts.first;
  }

  /// Gom số lần hoàn thành theo kỳ để vẽ biểu đồ:
  /// - Tuần này / Tuần trước: 7 cột, mỗi cột một ngày (nhãn là ngày trong tháng);
  /// - Tháng này / Tháng trước: mỗi cột 7 ngày (1–7, 8–14, ...);
  /// - 6 tháng / Năm nay: mỗi cột một tháng (nhãn "Th1"...);
  /// - Tất cả: mỗi cột một tháng từ ngày có dữ liệu đầu tiên (quá 12 tháng thì mỗi cột một năm).
  /// Ngày sau hôm nay không được tính.
  static List<ReportBucket> buckets(
    List<HabitHistory> histories,
    ReportPeriod period,
    DateTime today,
  ) {
    final day = dateOnly(today);
    final ranges = <({String label, DateTime from, DateTime to})>[];

    void addWeek(DateTime monday) {
      for (var i = 0; i < 7; i++) {
        final date = addDays(monday, i);
        ranges.add((label: '${date.day}', from: date, to: date));
      }
    }

    void addMonthInWeeks(DateTime first) {
      final last = DateTime(first.year, first.month + 1, 0);
      for (var start = 1; start <= last.day; start += 7) {
        final end = math.min(start + 6, last.day);
        ranges.add((
          label: start == end ? '$start' : '$start–$end',
          from: DateTime(first.year, first.month, start),
          to: DateTime(first.year, first.month, end),
        ));
      }
    }

    void addMonths(DateTime first, DateTime last) {
      for (var month = first; !month.isAfter(last); month = DateTime(month.year, month.month + 1)) {
        ranges.add((
          label: 'Th${month.month}',
          from: month,
          to: DateTime(month.year, month.month + 1, 0),
        ));
      }
    }

    final thisMonth = DateTime(day.year, day.month);
    switch (period) {
      case ReportPeriod.thisWeek:
        addWeek(weekStart(day));
      case ReportPeriod.lastWeek:
        addWeek(addDays(weekStart(day), -7));
      case ReportPeriod.thisMonth:
        addMonthInWeeks(thisMonth);
      case ReportPeriod.lastMonth:
        addMonthInWeeks(DateTime(day.year, day.month - 1));
      case ReportPeriod.sixMonths:
        addMonths(DateTime(day.year, day.month - 5), thisMonth);
      case ReportPeriod.thisYear:
        addMonths(DateTime(day.year), thisMonth);
      case ReportPeriod.allTime:
        final start = earliestStart(histories) ?? day;
        final first = DateTime(start.year, start.month);
        final months = (day.year - first.year) * 12 + day.month - first.month + 1;
        if (months <= 12) {
          addMonths(first, thisMonth);
        } else {
          for (var year = first.year; year <= day.year; year++) {
            ranges.add((label: '$year', from: DateTime(year), to: DateTime(year, 12, 31)));
          }
        }
    }

    final result = <ReportBucket>[];
    for (final range in ranges) {
      final counts = tally(histories, range.from, range.to, today: day);
      result.add((
        label: range.label,
        from: range.from,
        to: range.to,
        completed: counts.completed,
        due: counts.due,
      ));
    }
    return result;
  }

  /// Các ngày từ [from] đến [to], bỏ những ngày sau [today].
  static Iterable<DateTime> _days(DateTime from, DateTime to, DateTime today) sync* {
    final end = to.isAfter(today) ? dateOnly(today) : dateOnly(to);
    for (var day = dateOnly(from); !day.isAfter(end); day = addDays(day, 1)) {
      yield day;
    }
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
