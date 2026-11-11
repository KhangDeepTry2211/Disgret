// 3.1, 3.4 Hiển thị thời gian trên màn Focus và Tổng kết.

/// Dạng đồng hồ "mm:ss", làm tròn lên để bắt đầu đúng ở 25:00 và chạm 00:00 đúng lúc hết giờ.
String formatClock(Duration duration) {
  final totalSeconds = (duration.inMilliseconds + 999) ~/ 1000;
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Dạng lời nói: "45 giây", "25 phút", "12 phút 30 giây".
String formatSpoken(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  if (minutes == 0) return '$seconds giây';
  return seconds == 0 ? '$minutes phút' : '$minutes phút $seconds giây';
}
