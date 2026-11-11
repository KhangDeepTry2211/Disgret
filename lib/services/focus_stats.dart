// 8.2 Thống kê để kiểm chứng giả thuyết trong báo cáo.
// Toàn bộ là hàm thuần: nhận dữ liệu đã lưu, trả về các con số, không đụng tới Hive,
// nên dễ giải thích và dễ test.
import '../data/date_utils.dart';
import '../data/habit_progress.dart';
import '../data/models/event.dart';
import '../data/models/habit.dart';
import '../data/models/habit_log.dart';
import '../data/models/session.dart';

/// Số phút tập trung của một ngày.
class DayFocus {
  const DayFocus({required this.day, required this.minutes});

  final DateTime day;
  final int minutes;
}

class FocusStats {
  const FocusStats({
    required this.dailyFocus,
    required this.sessionCount,
    required this.habitDoneDays,
    required this.interventionCount,
    required this.choseStudy,
    required this.choseReel,
    required this.choseBreak,
    required this.reelsWatched,
    required this.reelsStartedFocus,
    required this.distractionCount,
    required this.averageReturn,
  });

  /// Biểu đồ và các số liệu học tập tính trong chừng này ngày, tính cả hôm nay.
  static const int days = 7;

  // ---------- Học tập, 7 ngày gần nhất ----------

  /// Phút tập trung từng ngày, từ cũ tới mới; phần tử cuối là hôm nay.
  final List<DayFocus> dailyFocus;

  /// Số phiên học bắt đầu trong 7 ngày.
  final int sessionCount;

  /// Số ngày có ít nhất một thói quen hoàn thành.
  final int habitDoneDays;

  // ---------- Hành vi, từ trước tới nay ----------

  /// 2.3 Số lần màn can thiệp Reset break hiện lên.
  final int interventionCount;

  /// Số lần chọn từng lựa chọn trên màn can thiệp.
  final int choseStudy;
  final int choseReel;
  final int choseBreak;

  /// 1.4 Số lượt xem reel, và số lượt bấm "Bắt đầu 5 phút" ngay từ reel đó.
  final int reelsWatched;
  final int reelsStartedFocus;

  /// 3.2 Số lần xao nhãng trong phiên học.
  final int distractionCount;

  /// Thời gian trung bình từ lúc rời app tới lúc quay lại học; null khi chưa xao nhãng lần nào.
  final Duration? averageReturn;

  int get totalFocusMinutes => dailyFocus.fold(0, (sum, day) => sum + day.minutes);

  /// Tổng số lần đã chọn trên màn can thiệp (có thể ít hơn số lần chặn nếu người dùng thoát ra).
  int get choiceCount => choseStudy + choseReel + choseBreak;

  /// Tỉ lệ của một lựa chọn trên tổng số lần chọn; null khi chưa chọn lần nào.
  double? choiceShare(int count) => choiceCount == 0 ? null : count / choiceCount;

  /// Tỉ lệ reel dẫn tới bắt đầu học; null khi chưa xem reel nào.
  double? get startedFocusRate => reelsWatched == 0 ? null : reelsStartedFocus / reelsWatched;

  factory FocusStats.from({
    required Iterable<Event> events,
    required Iterable<Session> sessions,
    required Iterable<Habit> habits,
    required Iterable<HabitLog> logs,
    required DateTime today,
  }) {
    final lastDay = dateOnly(today);
    final dayList = [
      for (var i = days - 1; i >= 0; i--) DateTime(lastDay.year, lastDay.month, lastDay.day - i),
    ];
    final firstDay = dayList.first;
    bool inRange(DateTime time) {
      final day = dateOnly(time);
      return !day.isBefore(firstDay) && !day.isAfter(lastDay);
    }

    // Phiên qua nửa đêm tính cho ngày bắt đầu, giống cách ghi log thói quen.
    final recentSessions = sessions.where((session) => inRange(session.start)).toList();
    final focusSeconds = <DateTime, int>{};
    for (final session in recentSessions) {
      final day = dateOnly(session.start);
      focusSeconds[day] = (focusSeconds[day] ?? 0) + session.focusedSeconds;
    }

    final doneDays = <DateTime>{};
    for (final habit in habits) {
      doneDays.addAll(HabitProgress.doneDays(habit, logs).where(inRange));
    }

    int countOf(EventType type) => events.where((event) => event.type == type).length;
    final watched = events.where((event) => event.type == EventType.reelWatched);
    final awaySeconds = [
      for (final event in events)
        if (event.type == EventType.sessionDistracted)
          event.meta[SessionDistractedMeta.awaySeconds] as int,
    ];

    return FocusStats(
      dailyFocus: [
        for (final day in dayList) DayFocus(day: day, minutes: (focusSeconds[day] ?? 0) ~/ 60),
      ],
      sessionCount: recentSessions.length,
      habitDoneDays: doneDays.length,
      interventionCount: countOf(EventType.interventionShown),
      choseStudy: countOf(EventType.choseStudy),
      choseReel: countOf(EventType.choseReel),
      choseBreak: countOf(EventType.choseBreak),
      reelsWatched: watched.length,
      reelsStartedFocus: watched
          .where((event) => event.meta[ReelWatchMeta.startedFocus] == true)
          .length,
      distractionCount: awaySeconds.length,
      averageReturn: awaySeconds.isEmpty
          ? null
          : Duration(
              seconds: (awaySeconds.fold(0, (sum, s) => sum + s) / awaySeconds.length).round(),
            ),
    );
  }
}
