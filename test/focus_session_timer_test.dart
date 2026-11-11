// 3.2 Unit test phần tính toán của phiên học, dùng đồng hồ giả.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/services/focus_session_timer.dart';

void main() {
  late DateTime now;

  void wait(Duration duration) => now = now.add(duration);

  FocusSessionTimer createTimer({int minutes = 25, int timeScale = 1}) => FocusSessionTimer(
    planned: Duration(minutes: minutes),
    clock: () => now,
    timeScale: timeScale,
  );

  /// Rời app trong khoảng thời gian cho trước rồi quay lại.
  FocusReturn? leaveFor(FocusSessionTimer timer, Duration duration) {
    timer.leave();
    wait(duration);
    return timer.comeBack();
  }

  setUp(() => now = DateTime(2026, 3, 2, 9));

  group('Không rời app', () {
    test('Mới bắt đầu: còn đủ thời gian, chưa có gì', () {
      final timer = createTimer();

      expect(timer.remaining, const Duration(minutes: 25));
      expect(timer.elapsed, Duration.zero);
      expect(timer.focused, Duration.zero);
      expect(timer.progress, 0);
      expect(timer.isTimeUp, isFalse);
    });

    test('Thời gian tập trung bằng thời gian đã trôi qua', () {
      final timer = createTimer();
      wait(const Duration(minutes: 10));

      expect(timer.elapsed, const Duration(minutes: 10));
      expect(timer.focused, const Duration(minutes: 10));
      expect(timer.remaining, const Duration(minutes: 15));
      expect(timer.progress, closeTo(0.4, 0.001));
      expect(timer.distractionCount, 0);
      expect(timer.totalAway, Duration.zero);
    });

    test('Hết giờ: dừng đúng ở thời lượng dự định dù trôi qua lâu hơn', () {
      final timer = createTimer();
      wait(const Duration(minutes: 90));

      expect(timer.isTimeUp, isTrue);
      expect(timer.elapsed, const Duration(minutes: 25));
      expect(timer.focused, const Duration(minutes: 25));
      expect(timer.remaining, Duration.zero);
      expect(timer.progress, 1);
    });
  });

  group('Rời 2 giây (dưới ngưỡng)', () {
    test('Không tính xao nhãng và không trừ thời gian tập trung', () {
      final timer = createTimer();
      wait(const Duration(minutes: 1));

      expect(leaveFor(timer, const Duration(seconds: 2)), isNull);

      expect(timer.distractionCount, 0);
      expect(timer.totalAway, Duration.zero);
      expect(timer.focused, const Duration(minutes: 1, seconds: 2));
    });

    test('Mốc ngưỡng: 2,999 giây chưa tính, đúng 3 giây thì tính', () {
      final timer = createTimer();

      expect(leaveFor(timer, const Duration(milliseconds: 2999)), isNull);
      expect(timer.distractionCount, 0);

      expect(leaveFor(timer, const Duration(seconds: 3)), isNotNull);
      expect(timer.distractionCount, 1);
    });
  });

  group('Rời 1 phút', () {
    test('Tính 1 lần xao nhãng, trừ đúng 1 phút; đồng hồ vẫn chạy trong lúc ở ngoài', () {
      final timer = createTimer();
      wait(const Duration(minutes: 5));

      final result = leaveFor(timer, const Duration(minutes: 1));

      expect(result?.away, const Duration(minutes: 1));
      expect(result?.distractionIndex, 1);
      expect(timer.distractionCount, 1);
      expect(timer.totalAway, const Duration(minutes: 1));
      expect(timer.elapsed, const Duration(minutes: 6));
      expect(timer.remaining, const Duration(minutes: 19));
      expect(timer.focused, const Duration(minutes: 5));
    });

    test('Đang ở ngoài: thời gian tập trung không tăng, đồng hồ vẫn đếm', () {
      final timer = createTimer();
      wait(const Duration(minutes: 5));
      timer.leave();
      wait(const Duration(minutes: 2));

      expect(timer.focused, const Duration(minutes: 5));
      expect(timer.totalAway, const Duration(minutes: 2));
      expect(timer.remaining, const Duration(minutes: 18));
    });
  });

  group('Rời nhiều lần', () {
    test('Cộng dồn đúng, số thứ tự tăng dần, lần dưới ngưỡng không làm lệch số đếm', () {
      final timer = createTimer();

      wait(const Duration(minutes: 1));
      expect(leaveFor(timer, const Duration(seconds: 30))?.distractionIndex, 1);

      wait(const Duration(minutes: 1));
      expect(leaveFor(timer, const Duration(seconds: 2)), isNull);

      wait(const Duration(minutes: 1));
      expect(leaveFor(timer, const Duration(minutes: 2))?.distractionIndex, 2);

      expect(leaveFor(timer, const Duration(seconds: 10))?.distractionIndex, 3);

      expect(timer.distractionCount, 3);
      expect(timer.totalAway, const Duration(minutes: 2, seconds: 40));
      // 3 phút ở trong + 30 giây + 2 giây (bỏ qua) + 2 phút + 10 giây = 5 phút 42 giây đã trôi qua.
      expect(timer.elapsed, const Duration(minutes: 5, seconds: 42));
      expect(timer.focused, const Duration(minutes: 3, seconds: 2));
    });

    test('Báo ẩn hai lần liên tiếp thì giữ mốc rời đi đầu tiên', () {
      final timer = createTimer();
      timer.leave();
      wait(const Duration(seconds: 5));
      timer.leave();
      wait(const Duration(seconds: 5));

      expect(timer.comeBack()?.away, const Duration(seconds: 10));
    });

    test('Quay lại mà chưa từng rời đi thì không có gì xảy ra', () {
      final timer = createTimer();
      expect(timer.comeBack(), isNull);
      expect(timer.distractionCount, 0);
    });
  });

  group('Kết thúc sớm', () {
    test('Giữ đúng thời gian thực tế, không trôi tiếp sau khi kết thúc', () {
      final timer = createTimer();
      wait(const Duration(minutes: 7));
      expect(leaveFor(timer, const Duration(minutes: 1))?.distractionIndex, 1);
      wait(const Duration(minutes: 2));

      timer.finish();
      final end = now;
      wait(const Duration(hours: 1));

      expect(timer.isFinished, isTrue);
      expect(timer.endedAt, end);
      expect(timer.elapsed, const Duration(minutes: 10));
      expect(timer.focused, const Duration(minutes: 9));
      expect(timer.totalAway, const Duration(minutes: 1));
      expect(timer.isTimeUp, isFalse);
    });

    test('Kết thúc ngay khi vừa bắt đầu thì mọi số liệu bằng 0', () {
      final timer = createTimer();
      timer.finish();

      expect(timer.focused, Duration.zero);
      expect(timer.distractionCount, 0);
    });

    test('Kết thúc khi đang ở ngoài: khép lại lần rời đi và tính xao nhãng', () {
      final timer = createTimer();
      wait(const Duration(minutes: 5));
      timer.leave();
      wait(const Duration(minutes: 1));

      expect(timer.finish()?.distractionIndex, 1);
      expect(timer.focused, const Duration(minutes: 5));
      expect(timer.totalAway, const Duration(minutes: 1));
    });

    test('Gọi kết thúc hai lần thì giữ mốc đầu tiên', () {
      final timer = createTimer();
      wait(const Duration(minutes: 3));
      timer.finish();
      final end = timer.endedAt;
      wait(const Duration(minutes: 3));
      timer.finish();

      expect(timer.endedAt, end);
    });
  });

  group('Hết giờ khi đang ở ngoài', () {
    test('Chỉ tính thời gian ở ngoài tới lúc hết giờ, tập trung không bị âm', () {
      final timer = createTimer(minutes: 5);
      wait(const Duration(minutes: 4));
      timer.leave();
      wait(const Duration(minutes: 30));

      final result = timer.finish();

      expect(timer.endedAt, DateTime(2026, 3, 2, 9, 5));
      expect(timer.elapsed, const Duration(minutes: 5));
      expect(timer.focused, const Duration(minutes: 4));
      expect(timer.totalAway, const Duration(minutes: 1));
      expect(timer.distractionCount, 1);
      // Số báo lại vẫn là thời gian ở ngoài thật, để đo thời gian quay lại.
      expect(result?.away, const Duration(minutes: 30));
    });

    test('Rời đi sau khi đã hết giờ cũng không làm thời gian ở ngoài bị âm', () {
      final timer = createTimer(minutes: 5);
      wait(const Duration(minutes: 6));
      timer.leave();
      wait(const Duration(minutes: 1));
      timer.comeBack();

      expect(timer.totalAway, Duration.zero);
      expect(timer.focused, const Duration(minutes: 5));
    });
  });

  group('Tạm dừng', () {
    test('Đồng hồ đứng yên, không tính tập trung và không tính xao nhãng', () {
      final timer = createTimer();
      wait(const Duration(minutes: 5));

      timer.pause();
      wait(const Duration(minutes: 3));
      expect(timer.isPaused, isTrue);
      expect(timer.elapsed, const Duration(minutes: 5));
      expect(timer.remaining, const Duration(minutes: 20));

      timer.resume();
      expect(timer.isPaused, isFalse);
      wait(const Duration(minutes: 1));

      expect(timer.elapsed, const Duration(minutes: 6));
      expect(timer.focused, const Duration(minutes: 6));
      expect(timer.distractionCount, 0);
    });

    test('Tạm dừng thì mốc hết giờ lùi lại tương ứng', () {
      final timer = createTimer(minutes: 5);
      timer.pause();
      wait(const Duration(minutes: 10));
      expect(timer.isTimeUp, isFalse, reason: 'Đang tạm dừng thì không thể hết giờ');

      timer.resume();
      wait(const Duration(minutes: 4));
      expect(timer.isTimeUp, isFalse);

      wait(const Duration(minutes: 1));
      expect(timer.isTimeUp, isTrue);
    });

    test('Rời app khi đang tạm dừng thì không tính là xao nhãng', () {
      final timer = createTimer();
      timer.pause();

      expect(leaveFor(timer, const Duration(minutes: 5)), isNull);
      expect(timer.distractionCount, 0);
      expect(timer.totalAway, Duration.zero);
    });

    test('Kết thúc khi đang tạm dừng: không tính phần tạm dừng vào thời gian học', () {
      final timer = createTimer();
      wait(const Duration(minutes: 5));
      timer.pause();
      wait(const Duration(minutes: 3));

      timer.finish();

      expect(timer.elapsed, const Duration(minutes: 5));
      expect(timer.focused, const Duration(minutes: 5));
      expect(timer.isPaused, isFalse);
    });
  });

  group('Chế độ demo: 1 phút chỉ dài 20 giây', () {
    FocusSessionTimer demoTimer({int minutes = 5}) =>
        createTimer(minutes: minutes, timeScale: FocusSessionTimer.demoTimeScale);

    test('Phiên 5 phút hết sau đúng 100 giây thật', () {
      final timer = demoTimer();
      wait(const Duration(seconds: 99));
      expect(timer.isTimeUp, isFalse);
      wait(const Duration(seconds: 1));
      expect(timer.isTimeUp, isTrue);
      expect(timer.elapsed, const Duration(minutes: 5));
      expect(timer.focused, const Duration(minutes: 5));
    });

    test('20 giây thật bằng 1 phút của phiên', () {
      final timer = demoTimer();
      wait(const Duration(seconds: 20));

      expect(timer.elapsed, const Duration(minutes: 1));
      expect(timer.remaining, const Duration(minutes: 4));
    });

    test('Ngưỡng 3 giây vẫn theo giờ thật, không bị nhân lên', () {
      final timer = demoTimer();

      expect(leaveFor(timer, const Duration(seconds: 2)), isNull);
      expect(timer.distractionCount, 0);

      expect(leaveFor(timer, const Duration(seconds: 3)), isNotNull);
      expect(timer.distractionCount, 1);
    });

    test('Thời gian ở ngoài được quy đổi theo phiên; số báo lại vẫn là giờ thật', () {
      final timer = demoTimer();
      wait(const Duration(seconds: 20));

      final result = leaveFor(timer, const Duration(seconds: 20));

      expect(result?.away, const Duration(seconds: 20));
      expect(timer.totalAway, const Duration(minutes: 1));
      expect(timer.focused, const Duration(minutes: 1));
      expect(timer.elapsed, const Duration(minutes: 2));
    });
  });
}
