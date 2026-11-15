// 4.1, 4.2 Unit test habit_schedule.dart (hàm thuần): thói quen "đến hạn hôm nay" theo lịch
// lặp lại và ngày kết thúc; kèm cách streak, điểm sức mạnh dùng lịch; danh mục icon; dữ liệu.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/date_utils.dart';
import 'package:focus_app/data/habit_icon_catalog.dart';
import 'package:focus_app/data/habit_progress.dart';
import 'package:focus_app/data/habit_schedule.dart';
import 'package:focus_app/data/habit_science.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/habit_log.dart';

// Tháng 3/2026: 2/3 là Thứ Hai, 5/3 là Thứ Năm.
final DateTime _monday = DateTime(2026, 3, 2);
DateTime _day(int offset) => addDays(_monday, offset);

Habit _habit({
  HabitType type = HabitType.regular,
  HabitRepeat repeat = HabitRepeat.daily,
  int daysPerWeek = 7,
  List<int> weekdays = const [],
  List<int> monthDays = const [],
  HabitEndRule endRule = HabitEndRule.never,
  DateTime? endDate,
  int endAfterDays = 30,
  DateTime? startDate,
  DateTime? dueDate,
}) => Habit(
  id: 'h1',
  goalId: 'g1',
  name: 'Ôn bài',
  minMinutesPerDay: 25,
  type: type,
  repeat: repeat,
  daysPerWeek: daysPerWeek,
  weekdays: weekdays,
  monthDays: monthDays,
  endRule: endRule,
  endDate: endDate,
  endAfterDays: endAfterDays,
  startDate: startDate,
  dueDate: dueDate,
);

int _nextId = 0;
HabitLog _log(DateTime day, HabitLogSource source) =>
    HabitLog(id: 'log_${_nextId++}', habitId: 'h1', date: day, source: source, minutes: 25);

bool _due(Habit habit, DateTime day, {int doneThisWeek = 0}) =>
    HabitSchedule.isDueOn(habit, day, doneDaysThisWeek: doneThisWeek);

void main() {
  group('Đến hạn theo lịch lặp lại', () {
    test('Hằng ngày: ngày nào cũng đến hạn', () {
      final habit = _habit();
      for (var i = 0; i < 14; i++) {
        expect(_due(habit, _day(i)), isTrue, reason: '${_day(i)}');
      }
    });

    test('Hằng tuần theo thứ: chỉ đúng các thứ đã chọn', () {
      final habit = _habit(
        repeat: HabitRepeat.weekly,
        weekdays: [DateTime.monday, DateTime.wednesday, DateTime.friday],
      );
      final due = [for (var i = 0; i < 7; i++) _due(habit, _day(i))];
      expect(due, [true, false, true, false, true, false, false]);
    });

    test('Hằng tuần theo số ngày: đến hạn cho tới khi tuần này làm đủ số ngày', () {
      final habit = _habit(repeat: HabitRepeat.weekly, daysPerWeek: 3);
      expect(_due(habit, _day(3), doneThisWeek: 0), isTrue);
      expect(_due(habit, _day(3), doneThisWeek: 2), isTrue);
      expect(_due(habit, _day(3), doneThisWeek: 3), isFalse);
      // Lịch thì ngày nào cũng khớp, vì ngày nào cũng có thể làm.
      expect(HabitSchedule.isScheduledOn(habit, _day(6)), isTrue);
    });

    test('Đếm số ngày đã làm trong tuần (T2–CN), không tính chính ngày đang xét', () {
      final done = {_day(-1), _day(0), _day(2), _day(3), _day(7)}; // CN tuần trước, T2 tuần sau.
      expect(HabitSchedule.doneDaysInWeekExcept(done, _day(3)), 2);
      expect(HabitSchedule.doneDaysInWeekExcept(done, _day(4)), 3);
    });

    test('Hằng tháng: đúng các ngày đã chọn', () {
      final habit = _habit(repeat: HabitRepeat.monthly, monthDays: [3, 8]);
      expect(_due(habit, DateTime(2026, 3, 3)), isTrue);
      expect(_due(habit, DateTime(2026, 3, 8)), isTrue);
      expect(_due(habit, DateTime(2026, 3, 4)), isFalse);
      expect(_due(habit, DateTime(2026, 4, 8)), isTrue);
    });

    test('Hằng tháng: chọn ngày 31 mà tháng không có thì làm vào ngày cuối tháng', () {
      final habit = _habit(repeat: HabitRepeat.monthly, monthDays: [31]);
      expect(_due(habit, DateTime(2026, 3, 31)), isTrue);
      expect(_due(habit, DateTime(2026, 4, 30)), isTrue);
      expect(_due(habit, DateTime(2026, 2, 28)), isTrue);
      expect(_due(habit, DateTime(2026, 3, 30)), isFalse);
      // Chọn cả 30 và 31: tháng 4 chỉ đến hạn một lần vào ngày 30.
      final both = _habit(repeat: HabitRepeat.monthly, monthDays: [30, 31]);
      expect(_due(both, DateTime(2026, 4, 30)), isTrue);
      expect(_due(both, DateTime(2026, 4, 29)), isFalse);
    });

    test('Việc một lần: chỉ đến hạn đúng ngày hạn; không có ngày hạn thì không bao giờ', () {
      final task = _habit(type: HabitType.oneTime, dueDate: _day(3));
      expect(_due(task, _day(3)), isTrue);
      expect(_due(task, _day(2)), isFalse);
      expect(_due(task, _day(4)), isFalse);
      expect(_due(_habit(type: HabitType.oneTime), _day(3)), isFalse);
    });
  });

  group('Ngày bắt đầu và ngày kết thúc', () {
    test(
      'Chưa tới ngày bắt đầu thì chưa đến hạn; dữ liệu cũ không có ngày bắt đầu thì luôn có',
      () {
        final habit = _habit(startDate: _day(3));
        expect(_due(habit, _day(2)), isFalse);
        expect(_due(habit, _day(3)), isTrue);
        expect(_due(_habit(), DateTime(2000)), isTrue);
      },
    );

    test('Không kết thúc: còn hạn mãi', () {
      expect(HabitSchedule.lastDay(_habit(startDate: _day(0))), isNull);
      expect(_due(_habit(startDate: _day(0)), DateTime(2030)), isTrue);
    });

    test('Đến ngày: còn hạn tới hết ngày đó', () {
      final habit = _habit(endRule: HabitEndRule.onDate, endDate: _day(4));
      expect(_due(habit, _day(4)), isTrue);
      expect(_due(habit, _day(5)), isFalse);
    });

    test('Sau N ngày: tính cả ngày bắt đầu', () {
      final habit = _habit(endRule: HabitEndRule.afterDays, endAfterDays: 3, startDate: _day(0));
      expect(HabitSchedule.lastDay(habit), _day(2));
      expect(_due(habit, _day(2)), isTrue);
      expect(_due(habit, _day(3)), isFalse);
    });

    test('Sau N ngày mà không có ngày bắt đầu (dữ liệu cũ) thì coi như không kết thúc', () {
      final habit = _habit(endRule: HabitEndRule.afterDays, endAfterDays: 3);
      expect(HabitSchedule.lastDay(habit), isNull);
    });

    test('Hết hạn thì hằng tuần theo thứ cũng không còn đến hạn', () {
      final habit = _habit(
        repeat: HabitRepeat.weekly,
        weekdays: [DateTime.monday],
        endRule: HabitEndRule.onDate,
        endDate: _day(6),
      );
      expect(_due(habit, _day(0)), isTrue);
      expect(_due(habit, _day(7)), isFalse);
    });
  });

  group('Streak và điểm sức mạnh theo lịch', () {
    // Thói quen T2, T4, T6. Hôm nay là T2 tuần sau (_day(7)), chưa làm.
    final weekly = _habit(
      repeat: HabitRepeat.weekly,
      weekdays: [DateTime.monday, DateTime.wednesday, DateTime.friday],
    );

    test('Ngày không có lịch không làm đứt chuỗi', () {
      final logs = [
        _log(_day(0), HabitLogSource.manual),
        _log(_day(2), HabitLogSource.manual),
        _log(_day(4), HabitLogSource.manual),
      ];
      expect(HabitScience.habitStreak(weekly, logs, today: _day(7)), 3);
      final history = HabitHistory.of(weekly, logs);
      expect(HabitScience.longestStreak(history, _day(7)), 3);
    });

    test('Bỏ một ngày có lịch thì chuỗi đứt', () {
      final logs = [_log(_day(0), HabitLogSource.manual), _log(_day(4), HabitLogSource.manual)];
      expect(HabitScience.habitStreak(weekly, logs, today: _day(7)), 1);
    });

    test('Ngày không có lịch giữ nguyên điểm sức mạnh', () {
      final logs = [_log(_day(4), HabitLogSource.manual)]; // Làm T6, rồi T7, CN không có lịch.
      final values = HabitScience.strengthHistory(HabitHistory.of(weekly, logs), _day(6), days: 3);
      expect(values[1], values[0]);
      expect(values[2], values[0]);
    });

    test('Bỏ qua có chủ đích (skip) vẫn tính là chưa làm', () {
      final logs = [_log(_day(3), HabitLogSource.skip)];
      expect(HabitProgress.isDone(_habit(), _day(3), logs), isFalse);
      expect(HabitProgress.minutesOn(_habit(), _day(3), logs), 0);
      expect(HabitProgress.markLogOn(_habit(), _day(3), logs)?.source, HabitLogSource.skip);
    });

    test('Việc một lần: hoàn thành vào ngày hạn thì chuỗi là 1, không bị kéo dài vô hạn', () {
      final task = _habit(type: HabitType.oneTime, dueDate: _day(3));
      final logs = [_log(_day(3), HabitLogSource.manual)];
      expect(HabitScience.habitStreak(task, logs, today: _day(10)), 1);
    });
  });

  group('Mô tả lịch trên thẻ', () {
    test('Hằng ngày, theo thứ, theo số ngày, hằng tháng, việc một lần, kèm buổi', () {
      expect(HabitSchedule.describe(_habit()), 'Hằng ngày');
      expect(
        HabitSchedule.describe(
          _habit(repeat: HabitRepeat.weekly, weekdays: [DateTime.friday, DateTime.monday]),
        ),
        'T2, T6',
      );
      expect(
        HabitSchedule.describe(_habit(repeat: HabitRepeat.weekly, daysPerWeek: 3)),
        '3 ngày/tuần',
      );
      expect(
        HabitSchedule.describe(_habit(repeat: HabitRepeat.monthly, monthDays: [8, 3])),
        'Ngày 3, 8 hằng tháng',
      );
      expect(
        HabitSchedule.describe(_habit(type: HabitType.oneTime, dueDate: _day(3))),
        'Việc một lần · 5/3',
      );
      final evening = Habit.fromMap({..._habit().toMap(), 'timeOfDay': 'evening'});
      expect(HabitSchedule.describe(evening), 'Hằng ngày · Tối');
    });
  });

  group('Danh mục icon', () {
    test('Bỏ dấu tiếng Việt và chữ hoa khi tìm', () {
      expect(HabitIconCatalog.foldVietnamese('Đọc Sách Ở Thư Viện'), 'doc sach o thu vien');
      final found = HabitIconCatalog.search(HabitIconCatalog.emojis, 'chay');
      expect(found.map((option) => option.value), contains('🏃'));
      expect(HabitIconCatalog.search(HabitIconCatalog.icons, '  '), HabitIconCatalog.icons);
      expect(HabitIconCatalog.search(HabitIconCatalog.icons, 'xyz'), isEmpty);
    });

    test('Mọi lựa chọn chọn nhanh đều có trong danh mục', () {
      final all = {
        ...HabitIconCatalog.icons.map((option) => option.value),
        ...HabitIconCatalog.emojis.map((option) => option.value),
      };
      expect(all, containsAll(HabitIconCatalog.quickPicks));
    });
  });

  group('Dữ liệu thói quen', () {
    test('Dữ liệu cũ không có trường mới thì lấy mặc định', () {
      final habit = Habit.fromMap({
        'id': 'h1',
        'goalId': 'g1',
        'name': 'Ôn bài',
        'minMinutesPerDay': 25,
      });
      expect(habit.type, HabitType.regular);
      expect(habit.repeat, HabitRepeat.daily);
      expect(habit.colorIndex, 0);
      expect(habit.timeOfDay, HabitTimeOfDay.anytime);
      expect(habit.endRule, HabitEndRule.never);
      expect(habit.reminderEnabled, isFalse);
      expect(habit.sortOrder, 0);
      expect(habit.startDate, isNull);
      expect(habit.archived, isFalse);
      expect(_due(habit, _day(0)), isTrue);
    });

    test('Giá trị lạ trong Hive (enum không còn) thì lấy mặc định thay vì lỗi', () {
      final habit = Habit.fromMap({..._habit().toMap(), 'repeat': 'yearly', 'type': '?'});
      expect(habit.repeat, HabitRepeat.daily);
      expect(habit.type, HabitType.regular);
    });

    test('Mọi trường mới lưu rồi đọc lại không mất', () {
      final habit = Habit(
        id: 'h1',
        goalId: 'g1',
        name: 'Chạy',
        minMinutesPerDay: 20,
        icon: '🏃',
        type: HabitType.regular,
        colorIndex: 4,
        repeat: HabitRepeat.weekly,
        daysPerWeek: 3,
        weekdays: const [1, 3],
        monthDays: const [5],
        timeOfDay: HabitTimeOfDay.morning,
        endRule: HabitEndRule.onDate,
        endDate: DateTime(2026, 12, 31),
        endAfterDays: 90,
        reminderEnabled: true,
        reminderTime: '06:30',
        sortOrder: 2,
        startDate: DateTime(2026, 3, 1),
        dueDate: DateTime(2026, 3, 9),
        archived: true,
      );
      expect(Habit.fromMap(habit.toMap()).toMap(), habit.toMap());
    });
  });
}
