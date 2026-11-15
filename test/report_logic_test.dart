// 4.2 Unit test phần Báo cáo trong habit_science.dart (ngày hoàn hảo, gom theo kỳ, tỉ lệ)
// và cấp thành tích trong achievements.dart. Hàm thuần, không cần Hive.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/achievements.dart';
import 'package:focus_app/data/date_utils.dart';
import 'package:focus_app/data/habit_science.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/habit_log.dart';

// Tháng 3/2026: 2/3 là Thứ Hai, hôm nay 5/3 là Thứ Năm.
final DateTime _today = DateTime(2026, 3, 5);
DateTime _ago(int days) => addDays(_today, -days);

const Habit _daily = Habit(id: 'a', goalId: 'g', name: 'Ôn bài', minMinutesPerDay: 25);
const Habit _other = Habit(id: 'b', goalId: 'g', name: 'Đọc sách', minMinutesPerDay: 10);

/// Chỉ làm Thứ Hai.
const Habit _mondays = Habit(
  id: 'c',
  goalId: 'g',
  name: 'Chạy bộ',
  minMinutesPerDay: 20,
  repeat: HabitRepeat.weekly,
  weekdays: [DateTime.monday],
);

int _nextId = 0;

HabitLog _log(Habit habit, DateTime day, [HabitLogSource source = HabitLogSource.manual]) =>
    HabitLog(
      id: 'log_${_nextId++}',
      habitId: habit.id,
      date: day,
      source: source,
      minutes: habit.minMinutesPerDay,
    );

List<HabitHistory> _histories(List<Habit> habits, List<HabitLog> logs) => [
  for (final habit in habits) HabitHistory.of(habit, logs),
];

void main() {
  group('Ngày hoàn hảo', () {
    test('Mọi thói quen đến hạn đều xong thì là ngày hoàn hảo; thiếu một cái thì không', () {
      final logs = [
        _log(_daily, _ago(3)),
        _log(_other, _ago(3)),
        _log(_daily, _ago(2)), // Ngày 2: "Đọc sách" chưa làm.
      ];
      final histories = _histories([_daily, _other], logs);
      expect(HabitScience.isPerfectDay(histories, _ago(3)), isTrue);
      expect(HabitScience.isPerfectDay(histories, _ago(2)), isFalse);
      expect(HabitScience.perfectDays(histories, _ago(3), _today, today: _today), 1);
    });

    test('Ngày không có thói quen nào đến hạn thì không tính', () {
      // Chỉ có thói quen Thứ Hai: Thứ Ba (3/3) không có gì đến hạn.
      final histories = _histories([_mondays], [_log(_mondays, _ago(3))]);
      expect(HabitScience.isPerfectDay(histories, _ago(3)), isTrue); // Thứ Hai đã chạy.
      expect(HabitScience.isPerfectDay(histories, _ago(2)), isFalse); // Thứ Ba: không tính.
      expect(HabitScience.perfectDays(histories, _ago(3), _today, today: _today), 1);
    });

    test('Thói quen đang nghỉ phép không làm hỏng ngày hoàn hảo', () {
      final logs = [
        _log(_daily, _ago(2)),
        _log(_other, _ago(3)),
        _log(_other, _ago(2), HabitLogSource.freeze),
      ];
      expect(HabitScience.isPerfectDay(_histories([_daily, _other], logs), _ago(2)), isTrue);
    });

    test('Bỏ qua (skip) vẫn tính là chưa làm', () {
      final logs = [_log(_daily, _ago(2)), _log(_other, _ago(2), HabitLogSource.skip)];
      expect(HabitScience.isPerfectDay(_histories([_daily, _other], logs), _ago(2)), isFalse);
    });

    test('Không đếm các ngày sau hôm nay', () {
      final histories = _histories([_daily], [_log(_daily, _ago(1))]);
      expect(HabitScience.perfectDays(histories, _ago(1), addDays(_today, 5), today: _today), 1);
    });
  });

  group('Số lần hoàn thành và tỉ lệ', () {
    test('Tỉ lệ = số lần xong / số lần phải làm; trước khi bắt đầu thì không tính', () {
      // Bắt đầu 3 ngày trước: 2 thói quen × 4 ngày (kể cả hôm nay) = 8 lần phải làm, xong 5.
      final logs = [
        _log(_daily, _ago(3)),
        _log(_daily, _ago(2)),
        _log(_daily, _ago(1)),
        _log(_other, _ago(3)),
        _log(_other, _today),
      ];
      final result = HabitScience.tally(
        _histories([_daily, _other], logs),
        _ago(10),
        _today,
        today: _today,
      );
      expect(result.completed, 5);
      expect(result.due, 8);
    });

    test('Làm thêm vào ngày không có lịch vẫn tính, tỉ lệ không vượt 100%', () {
      final histories = _histories([_mondays], [_log(_mondays, _ago(3)), _log(_mondays, _ago(2))]);
      final result = HabitScience.tally(histories, _ago(3), _ago(2), today: _today);
      expect(result.completed, 2);
      expect(result.due, 2);
      expect(HabitScience.dayRate(histories, _ago(1), today: _today), isNull);
    });

    test('Thói quen đã ẩn chỉ còn tính các ngày đã làm', () {
      final archived = _daily.copyWith(archived: true);
      final histories = _histories([archived], [_log(archived, _ago(3))]);
      final result = HabitScience.tally(histories, _ago(3), _today, today: _today);
      expect(result.completed, 1);
      expect(result.due, 1);
    });

    test('Tỉ lệ một ngày; ngày không có gì phải làm thì null', () {
      final histories = _histories(
        [_daily, _other],
        [_log(_daily, _ago(1)), _log(_other, _ago(2))],
      );
      expect(HabitScience.dayRate(histories, _ago(1), today: _today), 0.5);
      expect(HabitScience.dayRate(histories, _ago(5), today: _today), isNull);
    });
  });

  group('Gom theo kỳ cho biểu đồ', () {
    final logs = [for (var i = 0; i < 40; i++) _log(_daily, _ago(i))];
    final histories = _histories([_daily], logs);

    test('Tuần này: 7 cột T2–CN, nhãn là ngày, ngày tương lai bằng 0', () {
      final buckets = HabitScience.buckets(histories, ReportPeriod.thisWeek, _today);
      expect(buckets.map((bucket) => bucket.label), ['2', '3', '4', '5', '6', '7', '8']);
      expect(buckets.map((bucket) => bucket.completed), [1, 1, 1, 1, 0, 0, 0]);
    });

    test('Tuần trước: 7 cột của tuần trước, đủ 7 lần', () {
      final buckets = HabitScience.buckets(histories, ReportPeriod.lastWeek, _today);
      expect(buckets.first.from, DateTime(2026, 2, 23));
      expect(buckets.fold(0, (sum, bucket) => sum + bucket.completed), 7);
    });

    test('Tháng này: mỗi cột 7 ngày (1–7, 8–14, ...), hết tháng thì cột cuối ngắn hơn', () {
      final buckets = HabitScience.buckets(histories, ReportPeriod.thisMonth, _today);
      expect(buckets.map((bucket) => bucket.label), ['1–7', '8–14', '15–21', '22–28', '29–31']);
      expect(buckets.first.completed, 5); // 1/3 đến 5/3.
    });

    test('Tháng trước: tháng 2/2026 có 28 ngày, 4 cột', () {
      final buckets = HabitScience.buckets(histories, ReportPeriod.lastMonth, _today);
      expect(buckets, hasLength(4));
      expect(buckets.last.to, DateTime(2026, 2, 28));
    });

    test('6 tháng và Năm nay: mỗi cột một tháng', () {
      final six = HabitScience.buckets(histories, ReportPeriod.sixMonths, _today);
      expect(six.map((bucket) => bucket.label), ['Th10', 'Th11', 'Th12', 'Th1', 'Th2', 'Th3']);
      final year = HabitScience.buckets(histories, ReportPeriod.thisYear, _today);
      expect(year.map((bucket) => bucket.label), ['Th1', 'Th2', 'Th3']);
      expect(year.fold(0, (sum, bucket) => sum + bucket.completed), 40);
    });

    test('Tất cả: từ tháng có dữ liệu đầu tiên tới nay', () {
      final buckets = HabitScience.buckets(histories, ReportPeriod.allTime, _today);
      expect(buckets.first.from, DateTime(2026, 1));
      expect(buckets.fold(0, (sum, bucket) => sum + bucket.completed), 40);
    });

    test('Tất cả quá 12 tháng thì mỗi cột một năm', () {
      final old = _histories([_daily], [_log(_daily, DateTime(2024, 6, 1))]);
      final buckets = HabitScience.buckets(old, ReportPeriod.allTime, _today);
      expect(buckets.map((bucket) => bucket.label), ['2024', '2025', '2026']);
    });
  });

  group('Thành tích', () {
    test('9 cấp theo tổng số lần hoàn thành', () {
      expect(Achievements.levels, [10, 30, 66, 100, 200, 365, 500, 750, 1000]);
      expect(Achievements.levelFor(0), 0);
      expect(Achievements.levelFor(9), 0);
      expect(Achievements.levelFor(10), 1);
      expect(Achievements.levelFor(65), 2);
      expect(Achievements.levelFor(66), 3);
      expect(Achievements.levelFor(1000), 9);
      expect(Achievements.levelFor(5000), 9);
    });

    test('Cấp kế tiếp và tiến độ tới cấp đó', () {
      expect(Achievements.nextTarget(0), 10);
      expect(Achievements.nextTarget(10), 30);
      expect(Achievements.nextTarget(1000), isNull);
      expect(Achievements.progressToNext(5), 0.5);
      expect(Achievements.progressToNext(20), 0.5); // Từ 10 tới 30.
      expect(Achievements.progressToNext(1200), 1);
    });

    test('Tổng số lần hoàn thành cộng mọi thói quen, mỗi ngày làm xong là 1 lần', () {
      final logs = [
        _log(_daily, _ago(1)),
        _log(_daily, _ago(2)),
        _log(_other, _ago(1)),
        _log(_other, _ago(2), HabitLogSource.skip),
      ];
      expect(Achievements.totalCompletions(_histories([_daily, _other], logs)), 3);
    });
  });
}
