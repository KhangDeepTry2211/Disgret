// 4.2 Unit test logic hoàn thành và streak (hàm thuần, không cần Hive).
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/habit_progress.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/habit_log.dart';

const Habit _habit = Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 25);
const Habit _otherHabit = Habit(id: 'h2', goalId: 'g1', name: 'Bài tập', minMinutesPerDay: 25);

/// Ngày 2/3 để các chuỗi đi lùi qua đầu tháng (28/2 là ngày cuối tháng 2/2026).
final DateTime _today = DateTime(2026, 3, 2, 9, 30);
final DateTime _yesterday = DateTime(2026, 3, 1);
final DateTime _twoDaysAgo = DateTime(2026, 2, 28);
final DateTime _threeDaysAgo = DateTime(2026, 2, 27);

int _nextId = 0;

HabitLog _manual(DateTime day, {Habit habit = _habit}) => HabitLog(
  id: 'log_${_nextId++}',
  habitId: habit.id,
  date: day,
  source: HabitLogSource.manual,
  minutes: habit.minMinutesPerDay,
);

HabitLog _focus(DateTime day, int minutes, {Habit habit = _habit}) => HabitLog(
  id: 'log_${_nextId++}',
  habitId: habit.id,
  date: day,
  source: HabitLogSource.focus,
  minutes: minutes,
);

void main() {
  group('Thói quen hoàn thành trong ngày', () {
    test('Không có log thì chưa hoàn thành', () {
      expect(HabitProgress.isDone(_habit, _today, const []), isFalse);
    });

    test('Có log manual thì hoàn thành', () {
      expect(HabitProgress.isDone(_habit, _today, [_manual(_today)]), isTrue);
    });

    test('Log focus chưa đủ phút thì chưa hoàn thành', () {
      expect(HabitProgress.isDone(_habit, _today, [_focus(_today, 24)]), isFalse);
    });

    test('Log focus đủ đúng số phút tối thiểu thì hoàn thành', () {
      expect(HabitProgress.isDone(_habit, _today, [_focus(_today, 25)]), isTrue);
    });

    test('Nhiều log focus trong ngày được cộng dồn', () {
      final logs = [_focus(_today, 10), _focus(_today, 15)];
      expect(HabitProgress.isDone(_habit, _today, logs), isTrue);
    });

    test('Phút focus của hai ngày khác nhau không cộng dồn', () {
      final logs = [_focus(_yesterday, 20), _focus(_today, 20)];
      expect(HabitProgress.isDone(_habit, _today, logs), isFalse);
      expect(HabitProgress.isDone(_habit, _yesterday, logs), isFalse);
    });

    test('Log của thói quen khác không được tính', () {
      final logs = [_manual(_today, habit: _otherHabit), _focus(_today, 60, habit: _otherHabit)];
      expect(HabitProgress.isDone(_habit, _today, logs), isFalse);
    });

    test('Giờ trong ngày không ảnh hưởng tới kết quả', () {
      final lateNight = DateTime(2026, 3, 2, 23, 59);
      final logs = [_manual(DateTime(2026, 3, 2, 0, 1))];
      expect(HabitProgress.isDone(_habit, lateNight, logs), isTrue);
    });
  });

  group('Số phút trên thanh tiến độ', () {
    test('Không có log thì 0 phút', () {
      expect(HabitProgress.minutesOn(_habit, _today, const []), 0);
    });

    test('Cộng dồn phút focus trong ngày', () {
      final logs = [_focus(_today, 5), _focus(_today, 7), _focus(_yesterday, 30)];
      expect(HabitProgress.minutesOn(_habit, _today, logs), 12);
    });

    test('Có tick thì đạt mức tối thiểu', () {
      expect(HabitProgress.minutesOn(_habit, _today, [_manual(_today)]), 25);
    });

    test('Tick khi đã có ít phút focus thì không cộng trùng', () {
      final logs = [_focus(_today, 10), _manual(_today)];
      expect(HabitProgress.minutesOn(_habit, _today, logs), 25);
    });

    test('Tick khi phút focus đã vượt mức thì giữ số phút thật', () {
      final logs = [_focus(_today, 40), _manual(_today)];
      expect(HabitProgress.minutesOn(_habit, _today, logs), 40);
    });
  });

  group('Streak riêng của một thói quen', () {
    int streak(List<HabitLog> logs) => HabitProgress.habitStreak(_habit, logs, today: _today);

    test('Không có log thì bằng 0', () {
      expect(streak(const []), 0);
    });

    test('Chuỗi liên tiếp, đếm được cả qua đầu tháng', () {
      expect(streak([_manual(_today), _manual(_yesterday), _manual(_twoDaysAgo)]), 3);
    });

    test('Đứt một ngày thì chỉ đếm tới chỗ đứt', () {
      expect(streak([_manual(_today), _manual(_twoDaysAgo), _manual(_threeDaysAgo)]), 1);
    });

    test('Hôm nay chưa làm thì chuỗi vẫn giữ, tính từ hôm qua', () {
      expect(streak([_manual(_yesterday), _manual(_twoDaysAgo)]), 2);
    });

    test('Cả hôm nay và hôm qua đều chưa làm thì chuỗi về 0', () {
      expect(streak([_manual(_twoDaysAgo), _manual(_threeDaysAgo)]), 0);
    });

    test('Log focus chưa đủ phút làm đứt chuỗi', () {
      expect(streak([_manual(_today), _focus(_yesterday, 24), _manual(_twoDaysAgo)]), 1);
    });

    test('Log focus đủ phút được tính vào chuỗi', () {
      expect(streak([_manual(_today), _focus(_yesterday, 25), _manual(_twoDaysAgo)]), 3);
    });

    test('Hôm nay mới học chưa đủ phút thì chuỗi vẫn giữ từ hôm qua', () {
      expect(streak([_focus(_today, 10), _manual(_yesterday)]), 1);
    });
  });

  group('Streak chung của cả app', () {
    int streak(List<Habit> habits, List<HabitLog> logs) =>
        HabitProgress.overallStreak(habits, logs, today: _today);

    test('Không có thói quen, không có log thì bằng 0', () {
      expect(streak(const [], const []), 0);
      expect(streak(const [_habit], const []), 0);
    });

    test('Mỗi ngày chỉ cần một thói quen hoàn thành, không nhất thiết cùng một thói quen', () {
      final logs = [
        _manual(_today),
        _manual(_yesterday, habit: _otherHabit),
        _focus(_twoDaysAgo, 30),
      ];
      expect(streak(const [_habit, _otherHabit], logs), 3);
    });

    test('Đứt một ngày thì chỉ đếm tới chỗ đứt', () {
      final logs = [_manual(_today), _manual(_twoDaysAgo, habit: _otherHabit)];
      expect(streak(const [_habit, _otherHabit], logs), 1);
    });

    test('Hôm nay chưa làm thì chuỗi vẫn giữ, tính từ hôm qua', () {
      final logs = [_manual(_yesterday), _manual(_twoDaysAgo, habit: _otherHabit)];
      expect(streak(const [_habit, _otherHabit], logs), 2);
    });

    test('Phút focus của hai thói quen khác nhau không cộng chung', () {
      final logs = [_focus(_today, 15), _focus(_today, 15, habit: _otherHabit)];
      expect(streak(const [_habit, _otherHabit], logs), 0);
    });

    test('Log còn sót của thói quen đã xoá không được tính', () {
      expect(streak(const [_habit], [_manual(_today, habit: _otherHabit)]), 0);
    });
  });
}
