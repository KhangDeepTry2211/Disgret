// 5.1 Chuỗi giao diện tiếng Việt cho các màn mới hoặc vừa sửa (ADR-0005).
// Màn cũ chưa đụng tới vẫn giữ chuỗi tại chỗ; khi sửa màn nào thì chuyển chuỗi của màn đó vào đây.

/// Vietnamese UI strings. Interpolated text uses small functions.
class AppStrings {
  AppStrings._();

  // ---------- Common ----------
  static const String appName = 'DisGret';
  static const String settings = 'Cài đặt';
  static const String close = 'Đóng';
  static const String save = 'Lưu';
  static const String back = 'Quay lại';

  // ---------- Tabs (5.1) ----------
  static const String tabToday = 'Hôm nay';
  static const String tabHabits = 'Thói quen';
  static const String tabProgress = 'Tiến độ';

  // ---------- Hôm nay ----------
  static const String todayGoalLabel = 'Mục tiêu hôm nay';
  static const String nextHabitLabel = 'Học tiếp';
  static const String start = 'Bắt đầu';
  static const String changePlan = 'Đổi thói quen hoặc thời lượng';
  static const String noHabitTitle = 'Chưa có thói quen nào';
  static const String noHabitMessage = 'Thêm một thói quen để biết hôm nay cần học gì.';
  static const String addHabit = 'Thêm thói quen';
  static const String allDoneTitle = 'Hôm nay bạn đã xong hết!';
  static const String allDoneMessage = 'Muốn học thêm thì vẫn có thể bắt đầu một phiên nữa.';
  static const String restDayTitle = 'Hôm nay là ngày nghỉ theo lịch';
  static const String restDayMessage = 'Nghỉ cũng được. Muốn học thì vẫn có thể bắt đầu một phiên.';
  static const String extraSession = 'Học thêm một phiên';
  static String identity(String identity) => 'Tôi là người $identity';
  static String minutes(int n) => '$n phút';
  static String streakDays(int n) => 'Chuỗi $n ngày';

  // ---------- Đổi kế hoạch ----------
  static const String planSheetTitle = 'Phiên học tiếp theo';
  static const String planHabit = 'Thói quen';
  static const String planDuration = 'Thời lượng';
  static const String planApply = 'Dùng kế hoạch này';

  // ---------- Động lực (bước trước phiên) ----------
  static String startMinutes(int n) => 'Bắt đầu $n phút';
  static const String smallStep = 'Chỉ 5 phút thôi';
  static const String skip = 'Bỏ qua';
  static const String backToStudy = 'Quay lại học';

  // ---------- Phiên đang chạy ----------
  static const String focusTitle = 'Phiên học';
  static const String sessionOnBreak = 'Đang nghỉ';
  static String sessionRemaining(String clock) => 'Còn $clock';
  static const String openSession = 'Mở phiên học đang chạy';

  // ---------- Tiến độ ----------
  static const String progressHabits = 'Thói quen';
  static const String progressSessions = 'Phiên học';
  static const String progressEmpty = 'Tiến độ sẽ hiện ở đây sau phiên học đầu tiên.';

  // ---------- Thói quen ----------
  static const String habitsByDay = 'Theo ngày';
}
