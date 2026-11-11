// 6.2 Các hàm xử lý ngày dùng chung: habit tracker chỉ quan tâm "ngày nào", không cần giờ phút.

/// Bỏ phần giờ phút để hai thời điểm trong cùng một ngày so sánh bằng nhau.
DateTime dateOnly(DateTime time) => DateTime(time.year, time.month, time.day);

/// Lùi một ngày theo lịch, tự xử lý qua đầu tháng, đầu năm.
DateTime previousDay(DateTime day) => DateTime(day.year, day.month, day.day - 1);

/// Ngày ở dạng 'yyyy-MM-dd' để lưu trong Hive và ghép vào id.
String dateKey(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$date';
}
