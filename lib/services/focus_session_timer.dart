// 3.1 + 3.2 Phần tính toán của một phiên học, là class thuần Dart nhận đồng hồ từ bên ngoài
// nên test được bằng đồng hồ giả.
//
// Mọi con số đều tính từ các mốc thời gian, không cộng dồn từng giây, nên vẫn đúng
// khi app bị ẩn hoặc bộ đếm của Flutter bị dừng trong nền:
//   thời gian đã trôi qua = bây giờ − lúc bắt đầu − thời gian tạm dừng
//   thời gian tập trung   = thời gian đã trôi qua − thời gian ở ngoài app

/// Kết quả khi người dùng quay lại sau một lần xao nhãng.
class FocusReturn {
  const FocusReturn({required this.away, required this.distractionIndex});

  /// Thời gian ở ngoài thật sự, theo giờ thật.
  final Duration away;

  /// Đây là lần xao nhãng thứ mấy của phiên, đếm từ 1.
  final int distractionIndex;
}

class FocusSessionTimer {
  FocusSessionTimer({required this.planned, required DateTime Function() clock, this.timeScale = 1})
    : _clock = clock,
      startedAt = clock();

  /// Rời app dưới mức này thì bỏ qua hoàn toàn, ví dụ lỡ tay chuyển app rồi quay lại ngay.
  static const Duration distractionThreshold = Duration(seconds: 3);

  /// Chế độ demo: đồng hồ chạy nhanh gấp 3 lần, 1 phút của phiên chỉ dài 20 giây thật.
  /// Không nhanh hơn được: thời gian chờ ở màn chặn (10, 15, 20 giây) không chạy nhanh theo,
  /// nên phiên "Bắt đầu 5 phút" cần đủ dài (100 giây) để demo trọn 3 lựa chọn trên màn chặn.
  static const int demoTimeScale = 3;

  /// Số giây thật của 1 phút trong chế độ demo, dùng cho chữ hiển thị.
  static const int demoSecondsPerMinute = 60 ~/ demoTimeScale;

  /// Thời lượng dự định, tính theo thời gian của phiên.
  final Duration planned;

  /// Mỗi giây thật bằng chừng này giây của phiên. Mọi giá trị công khai đều đã nhân hệ số này,
  /// nên số phút lưu lại vẫn khớp với thời lượng đã chọn. Riêng ngưỡng 3 giây luôn theo giờ thật,
  /// vì thao tác rời app của người dùng không thể nhanh hơn được.
  final int timeScale;

  final DateTime startedAt;
  final DateTime Function() _clock;

  DateTime? _endedAt;
  DateTime? _awaySince;
  DateTime? _pausedSince;
  Duration _totalAway = Duration.zero;
  Duration _totalPaused = Duration.zero;
  int _distractionCount = 0;

  DateTime? get endedAt => _endedAt;
  bool get isFinished => _endedAt != null;
  bool get isPaused => _pausedSince != null;
  int get distractionCount => _distractionCount;

  /// Thời lượng theo giờ thật.
  Duration get _realPlanned => planned ~/ timeScale;

  /// Thời điểm hết giờ; mỗi lần tạm dừng sẽ đẩy mốc này lùi lại.
  DateTime get _deadline => startedAt.add(_realPlanned + _totalPaused);

  DateTime get _now => _endedAt ?? _clock();

  /// Thời gian đã trôi qua theo giờ thật, không vượt quá thời lượng dự định.
  Duration get _activeTime {
    final now = _now;
    final pausedNow = _pausedSince == null ? Duration.zero : now.difference(_pausedSince!);
    final active = now.difference(startedAt) - _totalPaused - pausedNow;
    return active > _realPlanned ? _realPlanned : active;
  }

  /// Thời gian ở ngoài theo giờ thật, tính cả lần đang ở ngoài và chỉ tính tới lúc hết giờ.
  Duration get _awayTime {
    final since = _awaySince;
    return since == null ? _totalAway : _totalAway + _awayUntil(since, _now);
  }

  Duration _awayUntil(DateTime since, DateTime until) {
    final end = until.isAfter(_deadline) ? _deadline : until;
    return end.isAfter(since) ? end.difference(since) : Duration.zero;
  }

  bool get isTimeUp => _activeTime >= _realPlanned;

  Duration get elapsed => _activeTime * timeScale;
  Duration get remaining => planned - elapsed;
  Duration get totalAway => _awayTime * timeScale;

  /// focusedSeconds = thời gian đã trôi qua − tổng thời gian ở ngoài.
  Duration get focused {
    final real = _activeTime - _awayTime;
    return real.isNegative ? Duration.zero : real * timeScale;
  }

  /// Tỉ lệ thời gian đã trôi qua, từ 0 đến 1.
  double get progress => elapsed.inMilliseconds / planned.inMilliseconds;

  /// App bị ẩn. Đang tạm dừng thì đồng hồ đã đứng yên nên không tính là rời đi.
  void leave() {
    if (isFinished || isPaused || _awaySince != null) return;
    _awaySince = _clock();
  }

  /// App hiện lại. Trả về kết quả nếu lần rời đi này đủ lâu để tính là một lần xao nhãng.
  FocusReturn? comeBack() {
    final since = _awaySince;
    if (since == null) return null;
    _awaySince = null;

    final now = _clock();
    final away = now.difference(since);
    if (away < distractionThreshold) return null;

    _totalAway += _awayUntil(since, now);
    _distractionCount++;
    return FocusReturn(away: away, distractionIndex: _distractionCount);
  }

  void pause() {
    if (isFinished || isPaused) return;
    _pausedSince = _clock();
  }

  void resume() {
    final since = _pausedSince;
    if (since == null) return;
    _totalPaused += _clock().difference(since);
    _pausedSince = null;
  }

  /// Kết thúc phiên, do hết giờ hoặc kết thúc sớm. Nếu đang ở ngoài thì khép lại lần rời đi đó
  /// và trả về kết quả của nó. Mốc kết thúc không vượt quá lúc hết giờ.
  FocusReturn? finish() {
    if (isFinished) return null;
    final closing = comeBack();
    resume();

    final now = _clock();
    _endedAt = now.isAfter(_deadline) ? _deadline : now;
    return closing;
  }
}
