// 1.4 Unit test cách tính số giây đã xem và "có xem hết không".
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/services/reel_watch_tracker.dart';

Duration _s(int seconds) => Duration(seconds: seconds);

void main() {
  const video = Duration(seconds: 15);

  test('Chưa phát thì 0 giây, chưa xem hết', () {
    final tracker = ReelWatchTracker();
    expect(tracker.secondsWatched, 0);
    expect(tracker.completed, isFalse);
  });

  test('Cộng dồn theo vị trí phát', () {
    final tracker = ReelWatchTracker();
    tracker.update(_s(3), video);
    tracker.update(_s(7), video);
    expect(tracker.secondsWatched, 7);
    expect(tracker.completed, isFalse);
  });

  test('Tạm dừng: vị trí không đổi thì số giây không tăng', () {
    final tracker = ReelWatchTracker();
    tracker.update(_s(5), video);
    tracker.update(_s(5), video);
    tracker.update(_s(5), video);
    expect(tracker.secondsWatched, 5);
  });

  test('Xem tới sát cuối video thì tính là xem hết', () {
    final tracker = ReelWatchTracker();
    tracker.update(_s(13), video);
    expect(tracker.completed, isFalse);
    tracker.update(_s(14), video);
    expect(tracker.completed, isTrue);
  });

  test('Video lặp lại: vẫn cộng dồn đúng và tính là xem hết', () {
    final tracker = ReelWatchTracker();
    tracker.update(_s(14), video);
    tracker.update(_s(2), video); // 14 -> hết video (15) -> lặp lại tới giây 2.
    expect(tracker.secondsWatched, 17);
    expect(tracker.completed, isTrue);

    tracker.update(_s(6), video);
    expect(tracker.secondsWatched, 21);
    expect(tracker.completed, isTrue);
  });

  test('Bắt đầu từ giữa video thì không tính phần trước đó', () {
    final tracker = ReelWatchTracker(startPosition: _s(10));
    tracker.update(_s(12), video);
    expect(tracker.secondsWatched, 2);
  });

  test('Chưa biết độ dài video thì chưa thể coi là xem hết', () {
    final tracker = ReelWatchTracker();
    tracker.update(Duration.zero, Duration.zero);
    expect(tracker.completed, isFalse);
  });
}
