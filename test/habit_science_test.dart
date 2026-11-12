// 4.2 Unit test habit_science.dart (hàm thuần, không cần Hive): điểm sức mạnh, streak có
// ngày nghỉ phép, "không bỏ 2 lần liên tiếp", hành trình 66 ngày, thống kê và lịch nhiệt.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/date_utils.dart';
import 'package:focus_app/data/habit_science.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/habit_log.dart';

const Habit _habit = Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 25);
const Habit _other = Habit(id: 'h2', goalId: 'g1', name: 'Đọc sách', minMinutesPerDay: 15);

// Tháng 3/2026: 1/3 là Chủ nhật, 2/3 là Thứ Hai, hôm nay 5/3 là Thứ Năm.
final DateTime _today = DateTime(2026, 3, 5);
DateTime _ago(int days) => addDays(_today, -days);

int _nextId = 0;

HabitLog _log(DateTime day, HabitLogSource source, {Habit habit = _habit, int minutes = 0}) =>
    HabitLog(
      id: 'log_${_nextId++}',
      habitId: habit.id,
      date: day,
      source: source,
      minutes: minutes,
    );

HabitLog _done(DateTime day, {Habit habit = _habit}) =>
    _log(day, HabitLogSource.manual, habit: habit, minutes: habit.minMinutesPerDay);
HabitLog _minimal(DateTime day) => _log(day, HabitLogSource.minimal, minutes: 2);
HabitLog _freeze(DateTime day, {Habit habit = _habit}) =>
    _log(day, HabitLogSource.freeze, habit: habit);
HabitLog _focus(DateTime day, int minutes) => _log(day, HabitLogSource.focus, minutes: minutes);

HabitHistory _history(List<HabitLog> logs) => HabitHistory.of(_habit, logs);
double _strength(List<HabitLog> logs) => HabitScience.strength(_habit, logs, today: _today);
int _streak(List<HabitLog> logs) => HabitScience.habitStreak(_habit, logs, today: _today);

void main() {
  group('1. Điểm sức mạnh', () {
    final alpha = HabitScience.alpha;

    test('α = 1 − 0.05^(1/66) ≈ 0.0444', () {
      expect(alpha, closeTo(0.0444, 0.0001));
      expect(alpha, closeTo(1 - math.pow(0.05, 1 / 66), 1e-12));
    });

    test('Làm đều 66 ngày liên tiếp từ 0 thì đạt đúng 95%', () {
      final logs = [for (var i = 0; i < 66; i++) _done(_ago(i))];
      expect(_strength(logs), closeTo(0.95, 1e-9));
    });

    test('Chưa có ghi nhận nào thì điểm là 0', () {
      expect(_strength(const []), 0);
    });

    test('Mỗi ngày: điểm = điểm hôm trước × (1 − α) + α × done', () {
      // Ngày 1 làm đủ, ngày 2 bỏ, hôm nay làm đủ.
      final logs = [_done(_ago(2)), _done(_today)];
      final day1 = alpha;
      final day2 = day1 * (1 - alpha);
      final today = day2 * (1 - alpha) + alpha;
      expect(_strength(logs), closeTo(today, 1e-12));
    });

    test('Bản 2 phút tính 0.5, Focus tính theo tỉ lệ phút (tối đa 1)', () {
      expect(_strength([_minimal(_today)]), closeTo(alpha * 0.5, 1e-12));
      expect(_strength([_focus(_today, 10)]), closeTo(alpha * 10 / 25, 1e-12));
      expect(_strength([_focus(_today, 60)]), closeTo(alpha, 1e-12));
    });

    test('Ngày nghỉ phép giữ nguyên điểm, ngày bỏ thì điểm giảm', () {
      final withFreeze = _strength([_done(_ago(2)), _freeze(_ago(1))]);
      final withMiss = _strength([_done(_ago(2)), _focus(_ago(1), 0)]);
      expect(withFreeze, closeTo(alpha, 1e-12));
      expect(withMiss, lessThan(withFreeze));
    });

    test('Hôm nay chưa làm thì chưa bị trừ điểm', () {
      final logs = [_done(_ago(2)), _done(_ago(1))];
      final afterYesterday = alpha * (1 - alpha) + alpha;
      expect(_strength(logs), closeTo(afterYesterday, 1e-12));
    });

    test('Lịch sử 60 ngày: đủ 60 điểm, điểm cuối là hôm nay, các ngày trước khi bắt đầu là 0', () {
      final logs = [_done(_ago(1)), _done(_today)];
      final values = HabitScience.strengthHistory(_history(logs), _today);
      expect(values, hasLength(60));
      expect(values.last, closeTo(_strength(logs), 1e-12));
      expect(values.sublist(0, 58), everyElement(0));
    });

    test('Điểm trung bình của nhiều thói quen', () {
      final logs = [_done(_today), _done(_today, habit: _other)];
      final average = HabitScience.averageStrength([_habit, _other], logs, today: _today);
      expect(average, closeTo(alpha, 1e-12));
      expect(HabitScience.averageStrength(const [], logs, today: _today), 0);
    });
  });

  group('2. Streak có ngày nghỉ phép', () {
    test('Ngày nghỉ phép không làm đứt chuỗi và không cộng vào chuỗi', () {
      // T2 làm, T3 nghỉ phép, T4 làm, hôm nay (T5) chưa làm.
      final logs = [_done(_ago(3)), _freeze(_ago(2)), _done(_ago(1))];
      expect(_streak(logs), 2);
    });

    test('Ngày nghỉ phép thứ hai trong cùng một tuần không được tính: chuỗi đứt', () {
      final logs = [_done(_ago(3)), _freeze(_ago(2)), _freeze(_ago(1)), _done(_today)];
      expect(_streak(logs), 1);
    });

    test('Mỗi tuần một ngày nghỉ phép: hai tuần liền thì cả hai đều được tính', () {
      // T6 27/2 làm, T7 28/2 nghỉ phép, CN 1/3 làm, T2 2/3 nghỉ phép (tuần mới), T3, T4 làm.
      final logs = [
        _done(_ago(6)),
        _freeze(_ago(5)),
        _done(_ago(4)),
        _freeze(_ago(3)),
        _done(_ago(2)),
        _done(_ago(1)),
      ];
      expect(_streak(logs), 4);
    });

    test('Chỉ tính ngày nghỉ phép sớm nhất trong tuần; ngày đã làm thì không cần nghỉ phép', () {
      final valid = HabitScience.validFreezeDays([_ago(1), _ago(2), _ago(3)], {_ago(3)});
      expect(valid, {_ago(2)});
    });

    test('Được xin nghỉ phép khi tuần đó chưa có ngày nghỉ phép nào khác', () {
      final logs = [_freeze(_ago(3))]; // Thứ Hai tuần này.
      expect(HabitScience.canFreeze(_habit, logs, _today), isFalse);
      expect(HabitScience.canFreeze(_habit, logs, _ago(3)), isTrue);
      expect(HabitScience.canFreeze(_habit, logs, addDays(_today, 4)), isTrue); // Tuần sau.
      expect(HabitScience.canFreeze(_other, logs, _today), isTrue); // Thói quen khác.
    });

    test('Chuỗi dài nhất cũng đi qua được ngày nghỉ phép', () {
      final logs = [
        _done(_ago(9)),
        _done(_ago(8)),
        _freeze(_ago(7)),
        _done(_ago(6)),
        // _ago(5) bỏ: chuỗi đứt.
        _done(_ago(4)),
      ];
      final history = _history(logs);
      expect(HabitScience.longestStreakOf(history.doneDays, history.freezeDays), 3);
      expect(HabitScience.longestStreakOf(const {}, const {}), 0);
    });

    test('Streak chung: ngày nghỉ phép của một thói quen cũng giữ chuỗi chung', () {
      final logs = [_done(_ago(2)), _freeze(_ago(1), habit: _other), _done(_today)];
      expect(HabitScience.overallStreak([_habit, _other], logs, today: _today), 2);
    });
  });

  group('3. Không bỏ 2 lần liên tiếp', () {
    test('Hôm qua bỏ và hôm nay chưa làm thì nhắc', () {
      expect(HabitScience.missedYesterday(_history([_done(_ago(3))]), _today), isTrue);
    });

    test('Hôm nay đã làm, hoặc hôm qua đã làm hay nghỉ phép thì không nhắc', () {
      expect(
        HabitScience.missedYesterday(_history([_done(_ago(3)), _done(_today)]), _today),
        false,
      );
      expect(HabitScience.missedYesterday(_history([_done(_ago(1))]), _today), isFalse);
      final freeze = [_done(_ago(3)), _freeze(_ago(1))];
      expect(HabitScience.missedYesterday(_history(freeze), _today), isFalse);
    });

    test('Thói quen mới bắt đầu (chưa có ghi nhận trước hôm qua) thì chưa nhắc', () {
      expect(HabitScience.missedYesterday(_history(const []), _today), isFalse);
      expect(HabitScience.missedYesterday(_history([_focus(_ago(1), 5)]), _today), isFalse);
    });
  });

  group('4. Hành trình 66 ngày', () {
    test(
      'Đếm tổng ngày hoàn thành, không cần liên tiếp; bản 2 phút có tính, nghỉ phép thì không',
      () {
        final logs = [_done(_ago(10)), _minimal(_ago(5)), _freeze(_ago(3)), _done(_today)];
        expect(HabitScience.journeyDays(_history(logs)), 3);
      },
    );

    test('Huy hiệu 7 "Khởi động", 21 "Bền bỉ", 40 "Vững vàng", 66 "Thành thói quen"', () {
      expect(HabitScience.badges.map((badge) => badge.days), [7, 21, 40, 66]);
      expect(HabitScience.nextBadge(0)?.name, 'Khởi động');
      expect(HabitScience.nextBadge(7)?.name, 'Bền bỉ');
      expect(HabitScience.nextBadge(39)?.name, 'Vững vàng');
      expect(HabitScience.nextBadge(65)?.name, 'Thành thói quen');
      expect(HabitScience.nextBadge(66), isNull);
    });
  });

  group('5. Thống kê', () {
    test('Tỉ lệ 30 ngày chỉ tính từ khi bắt đầu, bỏ ngày nghỉ phép và hôm nay chưa làm', () {
      // Bắt đầu 5 ngày trước: làm 3 ngày, bỏ 1 ngày, nghỉ phép 1 ngày; hôm nay chưa làm.
      final logs = [_done(_ago(5)), _done(_ago(4)), _freeze(_ago(3)), _done(_ago(1))];
      final rate = HabitScience.completionRate(_history(logs), _ago(29), _today, today: _today);
      expect(rate, closeTo(3 / 4, 1e-12));
      expect(HabitScience.completionRate(_history(const []), _ago(29), _today, today: _today), 0);
    });

    test('Thứ hay bỏ nhất; bằng nhau thì lấy thứ sớm hơn; chưa bỏ ngày nào thì null', () {
      // Bỏ hai Thứ Tư (25/2 và 4/3) và một Thứ Hai (2/3), các ngày khác đều làm.
      final missed = {_ago(8), _ago(1), _ago(3)};
      final logs = [
        for (var i = 9; i >= 1; i--)
          if (!missed.contains(_ago(i))) _done(_ago(i)),
      ];
      expect(HabitScience.mostMissedWeekday(_history(logs), today: _today), DateTime.wednesday);
      expect(
        HabitScience.mostMissedWeekday(_history([_done(_ago(1)), _done(_today)]), today: _today),
        isNull,
      );
    });
  });

  group('Lịch nhiệt và % theo ngày', () {
    test('4 mức màu: chưa làm, ít, nửa (bản 2 phút), hoàn thành', () {
      expect(HabitScience.heatLevel(0), 0);
      expect(HabitScience.heatLevel(0.2), 1);
      expect(HabitScience.heatLevel(0.5), 2);
      expect(HabitScience.heatLevel(0.9), 2);
      expect(HabitScience.heatLevel(1), 3);
    });

    test('% hoàn thành của một ngày: trung bình các thói quen, bỏ thói quen đang nghỉ phép', () {
      final logs = [_done(_today), _freeze(_today, habit: _other)];
      final histories = [HabitHistory.of(_habit, logs), HabitHistory.of(_other, logs)];
      expect(HabitScience.dayCompletion(histories, _today), 1);
      expect(HabitScience.dayCompletion(histories, _ago(1)), 0);
      expect(HabitScience.dayCompletion(const [], _today), isNull);
    });
  });

  group('Ý định thực hiện', () {
    test('Câu xác nhận đúng mẫu "Sau khi…, tôi sẽ… tại…"', () {
      expect(
        HabitScience.intentionSentence(name: 'Học', minutes: 25, cue: 'ăn tối', place: 'bàn học'),
        'Sau khi ăn tối, tôi sẽ học 25 phút tại bàn học.',
      );
      expect(
        HabitScience.intentionSentence(name: 'Đọc sách', minutes: 15),
        'Mỗi ngày, tôi sẽ đọc sách 15 phút.',
      );
    });
  });

  group('Dữ liệu cũ vẫn đọc được', () {
    test('Habit, Goal cũ không có trường mới thì lấy giá trị mặc định', () {
      final habit = Habit.fromMap({
        'id': 'h1',
        'goalId': 'g1',
        'name': 'Ôn bài',
        'minMinutesPerDay': 25,
      });
      expect(habit.cue, '');
      expect(habit.place, '');
      expect(habit.minimalVersion, '');
      expect(habit.icon, Habit.defaultIcon);

      final goal = Goal.fromMap({'id': 'g1', 'title': 'Đạt A', 'reason': 'Thực tập'});
      expect(goal.identity, '');
    });

    test('Trường mới lưu rồi đọc lại không mất', () {
      const habit = Habit(
        id: 'h1',
        goalId: 'g1',
        name: 'Ôn bài',
        minMinutesPerDay: 25,
        cue: 'ăn tối',
        place: 'bàn học',
        minimalVersion: 'Đọc 1 trang',
        icon: 'code',
      );
      final copy = Habit.fromMap(habit.toMap());
      expect(
        [copy.cue, copy.place, copy.minimalVersion, copy.icon],
        ['ăn tối', 'bàn học', 'Đọc 1 trang', 'code'],
      );
      final log = HabitLog.fromMap(_minimal(_today).toMap());
      expect(log.source, HabitLogSource.minimal);
    });
  });
}
