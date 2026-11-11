// 6.2, 8.2 Dữ liệu mẫu cho nút "Tạo dữ liệu mẫu" trong Cài đặt, ghi dữ liệu như người dùng thật.
import 'date_utils.dart';
import 'models/event.dart';
import 'models/goal.dart';
import 'models/habit.dart';
import 'models/habit_log.dart';
import 'models/session.dart';
import 'repositories/event_repository.dart';
import 'repositories/goal_repository.dart';
import 'repositories/habit_log_repository.dart';
import 'repositories/habit_repository.dart';
import 'repositories/session_repository.dart';

/// Một phiên học mẫu của thói quen "Làm bài tập", tính từ hôm nay lùi về trước.
typedef _DemoSession = ({int focusMinutes, int plannedMinutes, List<int> awaySeconds});

class MockData {
  MockData._();

  /// Phiên học mẫu: phần tử đầu là hôm nay, rồi lùi dần về trước.
  /// Mỗi số trong awaySeconds là một lần xao nhãng dài bấy nhiêu giây.
  static const List<_DemoSession> _sessions = [
    (focusMinutes: 10, plannedMinutes: 25, awaySeconds: [100, 80]),
    (focusMinutes: 35, plannedMinutes: 45, awaySeconds: [120]),
    (focusMinutes: 40, plannedMinutes: 45, awaySeconds: [60]),
    (focusMinutes: 30, plannedMinutes: 30, awaySeconds: []),
    (focusMinutes: 15, plannedMinutes: 25, awaySeconds: [90, 120, 90]),
  ];

  /// Tạo 1 mục tiêu, 2 thói quen và lịch sử 5 ngày để demo streak:
  /// - "Ôn bài" tick đủ 5 ngày trước hôm nay: streak 5. Hôm nay để trống, để khi demo
  ///   học xong một phiên thì thấy streak tăng lên 6.
  /// - "Làm bài tập" học bằng Focus: 3 ngày trước đủ 30 phút, ngày thứ 5 thiếu,
  ///   hôm nay mới 10 phút: streak 3, tiến độ hôm nay 10/30.
  /// Kèm phiên học và sự kiện mẫu (8.2) để màn Thống kê có số liệu.
  /// Dùng id cố định nên bấm nhiều lần cũng không sinh dữ liệu trùng.
  static Future<void> createDemoData({required DateTime now}) async {
    final today = dateOnly(now);
    const goal = Goal(
      id: 'demo_goal',
      title: 'Đạt điểm A môn Tư Duy Tính Toán',
      reason: 'Có kết quả tốt để tự tin xin thực tập.',
    );
    const reviewHabit = Habit(
      id: 'demo_habit_review',
      goalId: 'demo_goal',
      name: 'Ôn bài Tư Duy Tính Toán',
      minMinutesPerDay: 25,
    );
    const exerciseHabit = Habit(
      id: 'demo_habit_exercise',
      goalId: 'demo_goal',
      name: 'Làm bài tập về nhà',
      minMinutesPerDay: 30,
    );

    await GoalRepository().save(goal);
    final habits = HabitRepository();
    await habits.save(reviewHabit);
    await habits.save(exerciseHabit);

    final logs = HabitLogRepository();
    for (var daysAgo = 1; daysAgo <= 5; daysAgo++) {
      await logs.markDone(reviewHabit, _day(today, daysAgo));
    }
    await _createSessions(exerciseHabit, now: now, today: today);
    await _createEvents(now);
  }

  static DateTime _day(DateTime today, int daysAgo) =>
      DateTime(today.year, today.month, today.day - daysAgo);

  /// 3.4 Phiên học của "Làm bài tập" và log phút tập trung tương ứng của từng ngày.
  /// Mỗi lần xao nhãng cũng có một sự kiện session_distracted, như khi học thật.
  static Future<void> _createSessions(
    Habit habit, {
    required DateTime now,
    required DateTime today,
  }) async {
    final sessions = SessionRepository();
    final logs = HabitLogRepository();
    final events = EventRepository();

    for (var daysAgo = 0; daysAgo < _sessions.length; daysAgo++) {
      final demo = _sessions[daysAgo];
      final day = _day(today, daysAgo);
      final awayTotal = demo.awaySeconds.fold(0, (sum, seconds) => sum + seconds);
      final length = Duration(minutes: demo.focusMinutes, seconds: awayTotal);

      // Các ngày trước học lúc 20 giờ; hôm nay thì vừa học xong (nhưng không trước 0 giờ).
      var start = daysAgo == 0 ? now.subtract(length) : day.add(const Duration(hours: 20));
      if (start.isBefore(day)) start = day;

      await sessions.save(
        Session(
          id: 'demo_session_${dateKey(day)}',
          habitId: habit.id,
          start: start,
          end: start.add(length),
          plannedMinutes: demo.plannedMinutes,
          focusedSeconds: demo.focusMinutes * 60,
          distractionCount: demo.awaySeconds.length,
          awaySeconds: awayTotal,
          selfRating: 4,
        ),
      );
      await logs.save(
        HabitLog(
          id: 'demo_focus_${dateKey(day)}',
          habitId: habit.id,
          date: day,
          source: HabitLogSource.focus,
          minutes: demo.focusMinutes,
        ),
      );

      for (var i = 0; i < demo.awaySeconds.length; i++) {
        await events.save(
          Event(
            id: 'demo_distracted_${dateKey(day)}_$i',
            type: EventType.sessionDistracted,
            time: start.add(Duration(minutes: 5 * (i + 1))),
            meta: {
              SessionDistractedMeta.awaySeconds: demo.awaySeconds[i],
              SessionDistractedMeta.distractionIndex: i + 1,
            },
          ),
        );
      }
    }
  }

  /// 8.2 Lượt xem reel và các lần Reset break chặn trong 4 ngày trước.
  /// Mốc thời gian lùi từ lúc bấm tạo, sớm nhất là 24 giờ 40 phút trước: không có lượt xem nào
  /// trong 24 giờ qua, để thứ tự đề xuất reel lúc demo không bị lệch.
  static Future<void> _createEvents(DateTime now) async {
    final events = EventRepository();
    var count = 0;
    Future<void> add(EventType type, int daysAgo, Map<String, dynamic> meta) {
      final time = now.subtract(Duration(days: daysAgo, hours: 1)).add(Duration(minutes: count));
      return events.save(Event(id: 'demo_event_${count++}', type: type, time: time, meta: meta));
    }

    // 8 lượt xem, 3 lượt bấm "Bắt đầu 5 phút" ngay từ reel.
    const watches = [
      (daysAgo: 4, reelId: 'r1', seconds: 23, startedFocus: true),
      (daysAgo: 4, reelId: 'r3', seconds: 6, startedFocus: false),
      (daysAgo: 3, reelId: 'r5', seconds: 14, startedFocus: true),
      (daysAgo: 3, reelId: 'r2', seconds: 15, startedFocus: false),
      (daysAgo: 2, reelId: 'r4', seconds: 9, startedFocus: false),
      (daysAgo: 2, reelId: 'r1', seconds: 23, startedFocus: true),
      (daysAgo: 1, reelId: 'r3', seconds: 4, startedFocus: false),
      (daysAgo: 1, reelId: 'r6', seconds: 13, startedFocus: false),
    ];
    for (final watch in watches) {
      final lengthSec = watch.reelId == 'r1' ? 23 : 15;
      await add(EventType.reelWatched, watch.daysAgo, {
        ReelWatchMeta.reelId: watch.reelId,
        ReelWatchMeta.secondsWatched: watch.seconds,
        ReelWatchMeta.completed: watch.seconds >= lengthSec,
        if (watch.startedFocus) ReelWatchMeta.startedFocus: true,
      });
    }

    // 6 lần Reset break chặn: 3 lần quay lại học, 2 lần xem reel, 1 lần nghỉ 5 phút.
    const blocks = [
      (daysAgo: 4, app: 'YouTube', package: 'com.google.android.youtube', wait: 10),
      (daysAgo: 4, app: 'TikTok', package: 'com.zhiliaoapp.musically', wait: 15),
      (daysAgo: 3, app: 'YouTube', package: 'com.google.android.youtube', wait: 10),
      (daysAgo: 2, app: 'Chrome', package: 'com.android.chrome', wait: 10),
      (daysAgo: 2, app: 'TikTok', package: 'com.zhiliaoapp.musically', wait: 15),
      (daysAgo: 1, app: 'YouTube', package: 'com.google.android.youtube', wait: 10),
    ];
    const choices = [
      EventType.choseStudy,
      EventType.choseReel,
      EventType.choseStudy,
      EventType.choseBreak,
      EventType.choseReel,
      EventType.choseStudy,
    ];
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      await add(EventType.interventionShown, block.daysAgo, {
        InterventionShownMeta.packageName: block.package,
        InterventionShownMeta.appLabel: block.app,
        InterventionShownMeta.waitSeconds: block.wait,
      });
      await add(choices[i], block.daysAgo, {
        if (choices[i] == EventType.choseBreak) ChoseBreakMeta.minutes: 5,
      });
    }
  }
}
