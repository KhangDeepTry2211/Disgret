// 5.1 Chuỗi giao diện.
// Vietnamese UI strings for new or modified screens (ADR-0005). Untouched screens keep their
// strings inline until they are edited.

/// Vietnamese UI strings. Interpolated text uses small functions.
class AppStrings {
  AppStrings._();

  // ---------- Common ----------
  static const String appName = 'DisGret';
  static const String settings = 'Cài đặt';
  static const String close = 'Đóng';
  static const String save = 'Lưu';
  static const String back = 'Quay lại';
  static const String backToToday = 'Về Hôm nay';

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
  static String demoHint(int seconds) => 'Chế độ demo: 1 phút chỉ dài $seconds giây';

  // ---------- Plan sheet ----------
  static const String planSheetTitle = 'Phiên học tiếp theo';
  static const String planHabit = 'Thói quen';
  static const String planDuration = 'Thời lượng';
  static const String planApply = 'Dùng kế hoạch này';

  // ---------- Motivation step ----------
  static String startMinutes(int n) => 'Bắt đầu $n phút';
  static const String smallStep = 'Chỉ 5 phút thôi';
  static const String skip = 'Bỏ qua';
  static const String backToStudy = 'Quay lại học';
  static const String nextReel = 'Tiếp';

  /// Position of the current reel in the playlist, e.g. "1/3".
  static String reelPosition(int current, int total) => '$current/$total';
  static String reelPositionLabel(int current, int total) => 'Reel $current trên $total';
  static const String endCardStartTitle = 'Giờ đến lượt bạn';
  static const String endCardBackTitle = 'Quay lại phiên học nhé';
  static const String reelsLoadError = 'Không tải được danh sách reel.';
  static const String reelPlayError = 'Không phát được video này.';
  static const String noMatchingReel = 'Chưa có reel phù hợp.';

  // ---------- Running session ----------
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
