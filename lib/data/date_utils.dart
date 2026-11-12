// 6.2 Các hàm xử lý ngày dùng chung: habit tracker chỉ quan tâm "ngày nào", không cần giờ phút.

/// Bỏ phần giờ phút để hai thời điểm trong cùng một ngày so sánh bằng nhau.
DateTime dateOnly(DateTime time) => DateTime(time.year, time.month, time.day);

/// Lùi một ngày theo lịch, tự xử lý qua đầu tháng, đầu năm.
DateTime previousDay(DateTime day) => DateTime(day.year, day.month, day.day - 1);

/// Cộng (hoặc trừ, nếu [days] âm) một số ngày theo lịch.
/// Tạo lại DateTime từ năm/tháng/ngày thay vì cộng 24 giờ để không lệch khi đổi giờ mùa hè.
DateTime addDays(DateTime day, int days) => DateTime(day.year, day.month, day.day + days);

/// Thứ Hai của tuần chứa [day]; tuần tính từ Thứ Hai đến Chủ nhật.
DateTime weekStart(DateTime day) => addDays(dateOnly(day), 1 - day.weekday);

/// Số ngày từ [from] tới [to] (to sau from thì dương).
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Ngày ở dạng 'yyyy-MM-dd' để lưu trong Hive và ghép vào id.
String dateKey(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$date';
}

/// Tên ngắn của thứ trong tuần, theo DateTime.weekday (1 = Thứ Hai ... 7 = Chủ nhật).
const List<String> weekdayShort = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/// Tên đầy đủ của thứ trong tuần, theo DateTime.weekday.
const List<String> weekdayLong = [
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ nhật',
];
