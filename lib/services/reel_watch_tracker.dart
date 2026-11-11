// 1.4 Theo dõi một lượt xem reel: đã xem bao nhiêu giây, có xem hết không.
// Video lặp lại nên vị trí phát sẽ quay về 0: không thể lấy vị trí làm số giây đã xem,
// mà phải cộng dồn phần vị trí tăng thêm sau mỗi lần cập nhật.
class ReelWatchTracker {
  ReelWatchTracker({Duration startPosition = Duration.zero}) : _lastPosition = startPosition;

  /// Còn dưới chừng này là hết video thì coi như đã xem hết,
  /// vì vị trí chỉ được cập nhật vài lần mỗi giây nên có thể không chạm đúng điểm cuối.
  static const Duration _endTolerance = Duration(seconds: 1);

  Duration _lastPosition;
  Duration _duration = Duration.zero;
  Duration _watched = Duration.zero;
  bool _looped = false;

  Duration get lastPosition => _lastPosition;

  int get secondsWatched => _watched.inSeconds;

  bool get completed =>
      _looped || (_duration > Duration.zero && _lastPosition >= _duration - _endTolerance);

  void update(Duration position, Duration duration) {
    _duration = duration;
    if (position >= _lastPosition) {
      _watched += position - _lastPosition;
    } else {
      // Vị trí lùi lại nghĩa là video vừa phát hết và lặp lại từ đầu.
      _watched += (duration - _lastPosition) + position;
      _looped = true;
    }
    _lastPosition = position;
  }
}
