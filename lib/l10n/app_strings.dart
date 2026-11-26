// 5.1 Chuỗi giao diện.
// Vietnamese UI strings for new or modified screens (ADR-0005). Untouched screens keep their
// strings inline until they are edited.

/// Vietnamese UI strings. Interpolated text uses small functions.
class AppStrings {
  AppStrings._();

  // ---------- Common ----------
  static const String appName = 'DisGret';

  /// Launch screen under "DisGret" while the app opens (spec 011).
  static const String launchLine = 'Đang lặn xuống biển…';
  static const String settings = 'Cài đặt';
  static const String close = 'Đóng';
  static const String save = 'Lưu';
  static const String back = 'Quay lại';
  static const String cancel = 'Hủy';
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

  // ---------- 5.1 Tên gọi (spec 007) ----------
  static const String nameQuestion = 'Bạn muốn Gret gọi bạn là gì?';
  static const String nameLabel = 'Tên gọi';
  static const String nameHint = 'Biệt danh cũng được, để trống cũng không sao';
  static const String nameNotSet = 'Chưa đặt';
  static const String namePrivacy = 'Chỉ lưu trên máy này, để Gret chào bạn.';

  // ---------- 2.2 Nhắc giờ học (spec 009) ----------
  static const String reminderTitle = 'Gret đang đợi bạn 🐟';
  static String reminderBody(String habit, int minutes) =>
      'Tới giờ $habit rồi, chỉ $minutes phút thôi. Mình bắt đầu nhé?';
  static const String reminderChannel = 'Nhắc giờ học';
  static const String reminderChannelDescription =
      'Gret nhắc bạn vào giờ học đã đặt cho thói quen.';

  // ---------- Plan sheet ----------
  static const String planSheetTitle = 'Phiên học tiếp theo';
  static const String planHabit = 'Thói quen';
  static const String planDuration = 'Thời lượng';
  static const String planApply = 'Dùng kế hoạch này';

  // ---------- 5.6 Quán San Hô ----------
  static const String planPlace = 'Học ở';
  static const String placeSea = 'Biển của Gret';
  static const String placeCafe = 'Quán San Hô';
  static const String nextPlaceCafe = 'ở Quán San Hô';
  static String cafeSemantics(List<String> names) =>
      'Quán San Hô: Gret đang học cùng ${names.join(', ')}';
  static const String cafeOwnerName = 'Rùa';
  static const String cafeOwnerRole = 'Chủ quán';
  static const String cafeStarfishName = 'Sao';
  static const String subjectMaths = 'Toán';
  static const String subjectLiterature = 'Văn';
  static const String subjectEnglish = 'Tiếng Anh';
  static const String subjectBiology = 'Sinh học';
  static const List<String> cafeStarted = [
    'Chào mừng đến Quán San Hô! Bàn của bạn đây.',
    'Vào đi, cả quán đang học nè.',
  ];
  static const List<String> cafeReturned = [
    'Mừng bạn quay lại! Mình vẫn ở đây.',
    'Quay lại rồi à? Học tiếp cùng nhau nhé.',
    'Không sao, mình cũng hay lạc đề mà.',
  ];
  static const List<String> cafeBreakStarted = [
    'Nghỉ chút thôi, uống ngụm trà nào.',
    'Vươn vai cái đã!',
  ];
  static const List<String> cafeBreakEnded = ['Học tiếp thôi!', 'Hiệp mới, cố lên nào.'];
  static const List<String> cafeHalfway = ['Được nửa đường rồi đó!', 'Bạn đang làm tốt lắm.'];

  /// Ready-made greetings (FR-007) and, at the same index, the replies they can get.
  static const List<String> cafeGreetings = [
    'Chào cả quán!',
    'Cố lên nhé!',
    'Mình nghỉ chút',
    'Cảm ơn nha!',
  ];
  static const List<List<String>> cafeReplies = [
    ['Chào bạn! Ngồi đây nè.', 'Chào bạn, học vui nha!'],
    ['Cùng cố lên!', 'Cố lên, mình cũng đang cố nè.'],
    ['Nghỉ xíu rồi học tiếp nha.', 'Ừ, nghỉ cho khỏe.'],
    ['Không có gì đâu!', 'Có bạn học cùng vui hơn hẳn.'],
  ];

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
  static const String focusRemaining = 'Thời gian còn lại';
  static String focusBreakRemaining(String clock) => 'Đang nghỉ – còn $clock';
  static const String focusedLabel = 'Tập trung thực';
  static const String distractionsLabel = 'Số lần xao nhãng';
  static const String finishEarly = 'Kết thúc sớm';
  static const String finishEarlyTitle = 'Kết thúc sớm?';
  static const String finishEarlyMessage = 'Phiên học vẫn được lưu với thời gian bạn đã tập trung.';
  static const String finishEarlyConfirm = 'Kết thúc';

  // ---------- 3.4 Tổng kết (restyled by feature 003) ----------
  static const String summaryTitle = 'Tổng kết';
  static const String summaryWellDone = 'Làm tốt lắm!';
  static const String summaryRecorded = 'Đã ghi nhận phiên học';
  static const String summaryStreakGained = '+1 ngày streak 🔥';
  static const String summaryHabitDone = 'Đã hoàn thành thói quen hôm nay';
  static const String summaryFocused = 'Thời gian tập trung';
  static const String summaryPlanned = 'Thời lượng đã đặt';
  static String summaryMinutes(int minutes) => '$minutes phút';
  static const String summaryAway = 'Thời gian ở ngoài';
  static const String summaryBlocked = 'Reset break đã chặn';
  static const String summaryBreaks = 'Nghỉ có chủ đích';
  static String summaryTimes(int times) => '$times lần';
  static const String summaryRatingPrompt = 'Bạn đánh giá phiên này thế nào?';
  static String summaryStars(int stars) => '$stars sao';
  static const String summaryNote = 'Ghi chú ngắn (không bắt buộc)';
  static String pearlGain(int pearls) => '+$pearls ngọc trai';

  // ---------- Tiến độ ----------
  static const String progressHabits = 'Thói quen';
  static const String progressSessions = 'Phiên học';
  static const String progressEmpty = 'Tiến độ sẽ hiện ở đây sau phiên học đầu tiên.';
  static const String reelsFollowedByStart = 'Bắt đầu học ngay sau khi xem';

  // ---------- Thói quen ----------
  static const String habitsByDay = 'Theo ngày';

  // ---------- 5.3 Gret và biển sống (feature 003) ----------
  static const String seaTitle = 'Biển của Gret';
  static const String greetingMorning = 'Chào buổi sáng';
  static const String greetingAfternoon = 'Chào buổi chiều';
  static const String greetingEvening = 'Chào buổi tối';

  /// Greeting by time of day: before 11:00 morning, before 18:00 afternoon, then evening.
  /// 5.1 The header greeting, followed by the student's name when there is one (spec 007).
  static String greetingFor(DateTime now, String name) =>
      name.isEmpty ? greeting(now) : '${greeting(now)}, $name';

  static String greeting(DateTime now) => now.hour < 11
      ? greetingMorning
      : now.hour < 18
      ? greetingAfternoon
      : greetingEvening;

  static const String clarityClear = 'Biển trong';
  static const String clarityHazy = 'Hơi đục';
  static const String clarityMurky = 'Đục';
  static const String streakLabel = 'chuỗi ngày';
  static String streakDays(int days) => '$days ngày';

  /// Screen-reader label of the streak (same wording as the former streak ring).
  static String streakSemantics(int days) => 'Chuỗi $days ngày học liên tiếp';
  static String clarityPercent(int percent) => '$percent%';
  static String clarityGain(int points) => '+$points% độ trong';
  static const String seaReady = 'Biển của bạn đã sẵn sàng';

  static const String headlineTop = 'Bớt lướt.';
  static const String headlineBottom = 'Học nhiều hơn.';
  static const String gretGoalPrompt = 'Đặt mục tiêu đầu tiên nhé!';

  // ---------- Onboarding (5.1, restyled by feature 003) ----------
  static const String storySkip = 'Bỏ qua';
  static const String storyHello = 'Chào bạn! Mình là Gret. Biển này là biển của bạn đó.';
  static const String storyScroll =
      'Mỗi lần bạn lướt reel quá lâu, biển của mình lại đục đi một chút…';
  static const String storyStudy = 'Còn mỗi phút bạn học, biển lại trong xanh, cá bơi về đông vui.';
  static const String storyCallBack =
      'Lỡ bị app khác kéo đi giữa giờ học? Mình sẽ gọi bạn quay lại.';

  /// Screen-reader label of the story progress segments.
  static String storyProgress(int page, int total) => 'Trang $page/$total';
  static const String appsQuestion = 'App nào hay kéo bạn đi nhất?';
  static const String appsHint =
      'Mở mấy app này lúc đang học, Gret sẽ gọi bạn quay lại. Đổi lại được trong Cài đặt.';
  static const String reelLengthQuestion = 'Bạn thích reel dài bao nhiêu?';
  static String reelSeconds(int seconds) => '$seconds giây';
  static const String continueLabel = 'Tiếp tục';
  static const String firstGoalTitle = 'Mục tiêu đầu tiên của bạn';
  static const String firstGoalMessage =
      'Đặt một mục tiêu và một thói quen nhỏ để bắt đầu ngay hôm nay.';
  static const String enterApp = 'Vào DisGret';
  static String quizStep(int number, int total) => 'Câu $number/$total';

  // ---------- 5.4 Góc của Gret (feature 004) ----------
  static const String cornerTitle = 'Góc của Gret';
  static const String cornerOpen = 'Mở Góc của Gret';
  static String cornerPearls(int pearls) => '$pearls ngọc trai';
  static const String cornerPearlsHint = 'Mỗi 5 phút tập trung được 1 ngọc trai.';
  static const String cornerTabWardrobe = 'Tủ đồ';
  static const String cornerTabSea = 'Biển';
  static const String cornerTabMascots = 'Linh vật';
  static const String cornerFilterAll = 'Tất cả';
  static const String cornerFilterOwned = 'Đã có';
  static const String cornerFilterPearls = 'Ngọc trai';
  static const String cornerFilterStreak = 'Chuỗi ngày';
  static const String cornerFilterShop = 'Cửa hàng';
  static const String rarityCommon = 'Thường';
  static const String rarityRare = 'Hiếm';
  static const String raritySpecial = 'Đặc biệt';
  static const String cornerWearing = 'Đang mặc';
  static const String cornerChosen = 'Đang chọn';
  static const String cornerOwned = 'Đã có';
  static const String cornerFree = 'Có sẵn';
  static const String cornerSoon = 'Sắp có';
  static String cornerPrice(int pearls) => '$pearls ngọc';
  static String cornerStreak(int days) => 'Chuỗi $days ngày';
  static String cornerOwnedCount(int owned, int total) => '$owned/$total món';
  static const String cornerNothingWorn = 'Gret chưa mặc gì';
  static String cornerWornList(String names) => 'Đang mặc: $names';
  static const String cornerGretOnly = 'Đồ trong tủ chỉ dành cho Gret. Chọn Gret để mặc thử.';
  static String cornerObtain(int pearls) => 'Đổi $pearls ngọc trai';
  static const String cornerWear = 'Mặc';
  static const String cornerTakeOff = 'Cởi ra';
  static const String cornerChoose = 'Chọn';
  static String cornerMissing(int pearls) => 'Còn thiếu $pearls ngọc trai. Học thêm nhé!';
  static String cornerNeedStreak(int days) => 'Mở khi bạn đạt chuỗi $days ngày học.';
  static const String cornerPremium = 'Món này sẽ bán bằng tiền thật. Sắp có!';
  static String cornerGot(String name) => '$name đã là của bạn!';
  static String cornerSeaLocked(int days) => 'Mở ở chuỗi $days ngày';
  static const String cornerPreviousSea = 'Biển trước';
  static const String cornerNextSea = 'Biển sau';

  // ---------- 5.5 Bản đồ biển (feature 005) ----------
  static const String mapView = 'Bản đồ';
  static const String mapTitle = 'Bản đồ biển';
  static String mapExploration(String sea, int percent) => '$sea · Độ khám phá $percent%';
  static const String mapUnknown = 'Vùng chưa biết';

  /// A pearl sea Gret owns, as its own island (spec 014).
  static const String mapGretSea = 'Biển của Gret';
  static const String mapChooseSea = 'Chọn làm biển của Gret';
  static const String mapSeaInUse = 'Đang dùng';
  static String mapSeaSemantics(String sea) => '$sea, biển của Gret';
  static const String mapZoomIn = 'Phóng to';
  static const String mapZoomOut = 'Thu nhỏ';
  static const String mapToGret = 'Về chỗ Gret';
  static String mapExplored(int percent) => 'Đã khám phá $percent%';
  static const String mapHint = 'Sương mù tan dần mỗi ngày bạn làm thói quen.';
  static String mapRegionLine(String sea, int percent) => '$sea · $percent%';
  static String mapDays(int days, int total) => '$days/$total';
  static String mapDaysLong(int days, int total) => '$days/$total ngày';
  static const String mapStageHidden = 'Chưa khám phá';
  static const String mapStageFound = 'Đã tìm thấy';
  static const String mapStageWarmUp = 'Khởi động';
  static const String mapStageSteady = 'Bền bỉ';
  static const String mapStageSolid = 'Vững vàng';
  static const String mapStageFormed = 'Thành thói quen';
  static const String mapFishCave = 'Hang cá';
  static const String mapShipwreck = 'Tàu đắm';
  static const String mapKelpGarden = 'Vườn tảo';
  static const String mapTreasure = 'Kho báu';
  static const String mapCoralTemple = 'Đền san hô';
  static const String mapOldAnchor = 'Mỏ neo cổ';
  static String mapDiscoverHint(String habit) => 'Làm "$habit" lần đầu để khám phá điểm này.';
  static const String mapEmptyRegion = 'Vùng này chưa có điểm nào. Thêm một thói quen để khám phá.';
  static const String mapGretHere = 'Gret đang ở đây';
  static String mapRegionSemantics(String goal, String sea, int percent) =>
      'Vùng $goal, $sea, đã khám phá $percent%';
  static String mapPointSemantics(String habit, String kind, String progress) =>
      '$habit: $kind, $progress';
  static String mapHiddenSemantics(String habit) => '$habit: chưa khám phá';

  static const String moodHappy = 'đang vui';
  static const String moodNeutral = 'đang bình thường';
  static const String moodSad = 'đang buồn';
  static const String moodFocused = 'đang tập trung';
  static const String moodSleeping = 'đang ngủ';
  static const String moodCelebrating = 'đang ăn mừng';

  /// Screen-reader description of a sea scene (spec FR-018).
  static String seaSemantics(String mood, int percent) => 'Gret $mood. Biển trong $percent%.';

  /// What Gret says when tapped, by mood. Encouraging, never blaming (spec FR-008).
  static const List<String> gretHappy = [
    'Biển trong veo luôn! Hôm nay mình bơi được xa ghê.',
    'Bạn học đều quá, mình thấy rõ cả san hô dưới đáy!',
    'Cảm ơn bạn đã giữ biển sạch nha.',
    'Hôm nay mình vui lắm. Học thêm chút nữa không?',
    'Nước trong thế này, mình muốn nhảy lên khỏi mặt biển luôn!',
  ];
  static const List<String> gretNeutral = [
    'Biển hơi lăn tăn. Một phiên ngắn là trong lại ngay.',
    'Mình ổn! Học 5 phút với mình không?',
    'Hôm nay mình đợi bạn đó.',
    'Mỗi phút học là một chút nước trong hơn.',
    'Bắt đầu nhỏ thôi cũng được mà.',
  ];
  static const List<String> gretSad = [
    'Biển hơi đục rồi… Học 5 phút với mình nhé?',
    'Không sao đâu, mình bắt đầu lại từ hôm nay.',
    'Mình nhớ bạn. Quay lại học chút nha?',
    'Chỉ cần một phiên là biển đỡ đục nhiều rồi.',
    'Từng chút một thôi, mình đi cùng bạn.',
  ];
  static const List<String> gretFocused = [
    'Mình đang tập trung cùng bạn đây!',
    'Biển đang trong dần lên kìa.',
    'Cố lên, sắp xong rồi!',
  ];
  static const List<String> gretSleeping = [
    'Zzz… Nghỉ ngơi cũng là một phần của học.',
    'Hết giờ nghỉ mình gọi bạn nha.',
  ];
  static const List<String> gretCelebrating = [
    'Tuyệt vời! Biển trong hơn hẳn rồi!',
    'Bạn làm được rồi, mình tự hào lắm!',
  ];
}
