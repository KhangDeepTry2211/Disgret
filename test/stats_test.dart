// 8.2 Kiểm thử phần tính Thống kê và màn Thống kê.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/hive_boxes.dart';
import 'package:focus_app/data/models/event.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/habit_log.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/session.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/services/focus_stats.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import 'test_helpers.dart';

final DateTime _today = DateTime(2026, 3, 10);

Session _session(String id, DateTime start, {int focusedMinutes = 25}) => Session(
  id: id,
  habitId: 'h1',
  start: start,
  plannedMinutes: 25,
  focusedSeconds: focusedMinutes * 60,
  distractionCount: 0,
);

Event _event(EventType type, {Map<String, dynamic> meta = const {}}) => Event(
  id: '${type.value}_${meta.hashCode}_${DateTime.now().microsecondsSinceEpoch}',
  type: type,
  time: _today,
  meta: meta,
);

FocusStats _stats({
  List<Event> events = const [],
  List<Session> sessions = const [],
  List<Habit> habits = const [],
  List<HabitLog> logs = const [],
}) {
  return FocusStats.from(
    events: events,
    sessions: sessions,
    habits: habits,
    logs: logs,
    today: _today,
  );
}

void main() {
  group('Tính số liệu', () {
    test('Chưa có dữ liệu: 7 ngày đều 0 phút, các tỉ lệ chưa có', () {
      final stats = _stats();

      expect(stats.dailyFocus, hasLength(7));
      expect(stats.dailyFocus.last.day, _today);
      expect(stats.dailyFocus.first.day, DateTime(2026, 3, 4));
      expect(stats.totalFocusMinutes, 0);
      expect(stats.sessionCount, 0);
      expect(stats.choiceShare(0), isNull);
      expect(stats.startedFocusRate, isNull);
      expect(stats.averageReturn, isNull);
    });

    test('Cộng phút tập trung theo ngày bắt đầu phiên, bỏ phiên ngoài 7 ngày', () {
      final stats = _stats(
        sessions: [
          _session('a', DateTime(2026, 3, 10, 8), focusedMinutes: 20),
          _session('b', DateTime(2026, 3, 10, 21), focusedMinutes: 15),
          // Qua nửa đêm vẫn tính cho ngày bắt đầu.
          _session('c', DateTime(2026, 3, 9, 23, 50), focusedMinutes: 30),
          _session('d', DateTime(2026, 3, 4, 9), focusedMinutes: 10),
          _session('cu', DateTime(2026, 3, 3, 9), focusedMinutes: 60),
        ],
      );

      expect(stats.dailyFocus.last.minutes, 35);
      expect(stats.dailyFocus[5].minutes, 30);
      expect(stats.dailyFocus.first.minutes, 10);
      expect(stats.totalFocusMinutes, 75);
      expect(stats.sessionCount, 4);
    });

    test('Số ngày hoàn thành thói quen chỉ tính trong 7 ngày', () {
      const habit = Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 10);
      HabitLog manual(DateTime day) => HabitLog(
        id: 'm$day',
        habitId: 'h1',
        date: day,
        source: HabitLogSource.manual,
        minutes: 10,
      );

      final stats = _stats(
        habits: [habit],
        logs: [
          manual(DateTime(2026, 3, 10)),
          manual(DateTime(2026, 3, 8)),
          manual(DateTime(2026, 3, 1)),
        ],
      );
      expect(stats.habitDoneDays, 2);
    });

    test('Reset break: đếm số lần chặn và tỉ lệ từng lựa chọn', () {
      final stats = _stats(
        events: [
          for (var i = 0; i < 5; i++) _event(EventType.interventionShown, meta: {'i': i}),
          _event(EventType.choseStudy, meta: {'i': 1}),
          _event(EventType.choseStudy, meta: {'i': 2}),
          _event(EventType.choseReel),
          _event(EventType.choseBreak, meta: {ChoseBreakMeta.minutes: 5}),
        ],
      );

      expect(stats.interventionCount, 5);
      expect(stats.choiceCount, 4, reason: 'Một lần thoát ra mà không chọn');
      expect(stats.choiceShare(stats.choseStudy), 0.5);
      expect(stats.choiceShare(stats.choseReel), 0.25);
      expect(stats.choiceShare(stats.choseBreak), 0.25);
    });

    test('Reels: tỉ lệ lượt xem dẫn tới bắt đầu học', () {
      Event watched(String id, {bool startedFocus = false}) => _event(
        EventType.reelWatched,
        meta: {
          ReelWatchMeta.reelId: id,
          ReelWatchMeta.secondsWatched: 10,
          if (startedFocus) ReelWatchMeta.startedFocus: true,
        },
      );

      final stats = _stats(
        events: [watched('r1', startedFocus: true), watched('r2'), watched('r3'), watched('r4')],
      );
      expect(stats.reelsWatched, 4);
      expect(stats.reelsStartedFocus, 1);
      expect(stats.startedFocusRate, 0.25);
    });

    test('Thời gian quay lại trung bình lấy từ session_distracted, làm tròn tới giây', () {
      Event distracted(int seconds) => _event(
        EventType.sessionDistracted,
        meta: {
          SessionDistractedMeta.awaySeconds: seconds,
          SessionDistractedMeta.distractionIndex: 1,
        },
      );

      final stats = _stats(events: [distracted(30), distracted(61), distracted(90)]);
      expect(stats.distractionCount, 3);
      expect(stats.averageReturn, const Duration(seconds: 60));
    });
  });

  group('Màn Thống kê', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

    setUp(() async {
      await openMemoryBoxes();
      await ProfileRepository().completeOnboarding(
        const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
      );
    });

    tearDown(() async => Hive.close());

    Future<void> openStats(WidgetTester tester, {bool createDemoData = false}) async {
      await pumpApp(tester, clock: () => DateTime(2026, 3, 10, 21));
      await tapAndSettle(tester, find.byTooltip('Cài đặt'));
      if (createDemoData) {
        // Danh sách chỉ dựng mục đang hiện trên màn nên phải cuộn tới trước.
        await tester.scrollUntilVisible(find.text('Tạo dữ liệu mẫu'), 200);
        await tapAndSettle(tester, find.text('Tạo dữ liệu mẫu'));
        await tester.scrollUntilVisible(find.text('Thống kê'), -200);
      }
      await tapAndSettle(tester, find.text('Thống kê'));
    }

    testWidgets('Chưa có dữ liệu: mỗi thẻ có hướng dẫn, không lỗi giao diện', (tester) async {
      await openStats(tester);

      expect(find.text('0 phút'), findsOneWidget);
      expect(find.textContaining('Chưa có phiên học nào'), findsOneWidget);
      expect(find.text('Đã chặn 0 lần'), findsOneWidget);
      expect(find.textContaining('Chưa có lần chặn nào'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Chưa có số liệu'), 200);
      expect(find.textContaining('Chưa xem reel nào'), findsOneWidget);
      expect(find.text('Chưa có lần xao nhãng nào trong phiên học.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sau "Tạo dữ liệu mẫu": đủ số liệu cho cả 4 thẻ', (tester) async {
      await openStats(tester, createDemoData: true);

      // Phiên mẫu: 10 + 35 + 40 + 30 + 15 phút trong 5 ngày gần nhất.
      expect(find.text('130 phút'), findsOneWidget);
      expect(find.text('5 phiên học · 5/7 ngày hoàn thành thói quen'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Biểu đồ phút tập trung: .*T3 10 phút$')),
        findsOneWidget,
        reason: '10/03/2026 là thứ Ba, cột cuối là hôm nay',
      );

      expect(find.text('Đã chặn 6 lần'), findsOneWidget);
      expect(find.text('3 lần · 50%'), findsOneWidget);
      expect(find.text('2 lần · 33%'), findsOneWidget);
      expect(find.text('1 lần · 17%'), findsOneWidget);

      await tester.scrollUntilVisible(find.textContaining('tính trên 7 lần xao nhãng'), 200);
      expect(find.text('Đã xem 8 reel'), findsOneWidget);
      expect(find.text('3 lần · 38%'), findsOneWidget);
      // (100 + 80 + 120 + 60 + 90 + 120 + 90) / 7 = 94 giây.
      expect(find.text('Trung bình 1 phút 34 giây'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Dữ liệu hỏng thì báo lỗi dễ hiểu thay vì màn đỏ', (tester) async {
      await Hive.box<dynamic>(HiveBoxes.events).put('hong', {
        'id': 'hong',
        'type': 'loai_khong_ton_tai',
        'time': DateTime(2026, 3, 10).toIso8601String(),
        'meta': <String, dynamic>{},
      });

      await openStats(tester);

      expect(find.text('Không đọc được số liệu'), findsOneWidget);
    });
  });
}
