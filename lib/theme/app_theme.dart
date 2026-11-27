// 5.2 Design system
// MỘT file duy nhất chứa màu, font, bo góc, khoảng cách và icon của DisGret.
// Màn hình chỉ lấy giá trị từ đây hoặc từ Theme.of(context), không viết mã màu cứng.
import 'package:material_ui/material_ui.dart';

/// 5.2 Bảng màu "Ocean": xanh nước biển + đen.
/// Chế độ tối = phương án A "Biển đêm", chế độ sáng = phương án B "Mực & đại dương".
/// Không dùng gradient: nút, vòng và thanh tiến độ đều tô màu đặc.
class AppColors {
  AppColors._();

  static const Color white = Color(0xFFFFFFFF);

  /// Header over the full-bleed sea on Hôm nay (feature 003).
  static const Color transparent = Color(0x00000000);

  // 5.2 Bảng màu "Biển nắng" (feature 008): sea blue, aqua and sun yellow. Contrast is checked in
  // test/brand_test.dart.

  /// Logo tile, launcher icon and splash background.
  static const Color brand = Color(0xFF1E88E5);

  /// Sun highlight for pearls and celebrations, with the text colour that reads on it.
  static const Color sun = Color(0xFFFFC93C);
  static const Color onSun = Color(0xFF5C3D00);

  // Chế độ tối.
  static const Color darkBackground = Color(0xFF07111F);
  static const Color darkSurface = Color(0xFF0F1C2E);
  static const Color darkDivider = Color(0xFF1F3350);
  static const Color darkText = Color(0xFFE8F1FF);
  static const Color darkTextSecondary = Color(0xFF8FA3BF);
  static const Color darkPrimary = Color(0xFF1B6ED4);
  static const Color darkLink = Color(0xFF6CB6FF);
  static const Color darkAccent = Color(0xFF4DD0E1);
  static const Color darkError = Color(0xFFF2B8B5);

  // Chế độ sáng.
  static const Color lightBackground = Color(0xFFF3F8FD);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFD8E4F0);
  static const Color lightText = Color(0xFF0B0F17);
  static const Color lightTextSecondary = Color(0xFF56677F);
  static const Color lightPrimary = Color(0xFF1565C0);
  static const Color lightLink = Color(0xFF0D47A1);
  static const Color lightAccent = Color(0xFF0097A7);
  static const Color lightError = Color(0xFFB3261E);

  // Lịch nhiệt 4 mức (heat0 = ít nhất, heat3 = nhiều nhất).
  static const List<Color> darkHeat = [
    Color(0xFF10233D),
    Color(0xFF174A80),
    Color(0xFF1B6ED4),
    Color(0xFF4DD0E1),
  ];
  static const List<Color> lightHeat = [
    Color(0xFFE3F2FD),
    Color(0xFF90CAF9),
    Color(0xFF42A5F5),
    Color(0xFF1565C0),
  ];

  /// Lấy 4 màu lịch nhiệt theo chế độ sáng/tối hiện tại.
  static List<Color> heatOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkHeat : lightHeat;

  // Màn Reels: chữ và nút nổi trên video, luôn sáng dù app đang ở chế độ nào.
  static const Color videoBackground = Color(0xFF000000);
  static const Color onVideo = white;
  static const Color onVideoSecondary = Color(0xCCFFFFFF);
  static const Color onVideoTrack = Color(0x4DFFFFFF);
  static const Color onVideoChip = Color(0x33FFFFFF);

  /// Bóng mờ sau icon và nhãn nổi trên video, để đọc rõ cả trên video sáng.
  static const Color onVideoShadow = Color(0x99000000);
  static const Color scrimClear = Color(0x00000000);
  static const Color scrimDark = Color(0xCC000000);
  static const Color scrimTop = Color(0x80000000);

  /// Phủ lên nền mờ của video (đen 45%) để video chính nổi bật.
  static const Color reelBlurScrim = Color(0x73000000);

  /// Lớp mờ đen ở đáy màn Reels để chữ dễ đọc (lớp phủ chức năng, không phải trang trí).
  static const LinearGradient reelScrimGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [scrimClear, scrimDark],
  );

  /// Lớp mờ mỏng ở đỉnh màn Reels để đồng hồ và thanh tiến độ vẫn rõ trên video sáng.
  static const LinearGradient reelTopScrimGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [scrimTop, scrimClear],
  );
}

/// Một màu thẻ thói quen: nền pastel và màu chữ/icon đậm cùng tông để đọc rõ.
typedef HabitColor = ({Color background, Color foreground});

/// 5.2 Bảng 12 màu pastel cho thẻ thói quen, hài hoà với bảng Ocean (xanh biển, ngọc, bạc hà,
/// tím nhạt, hồng, đào, vàng kem...). Dùng chung cho chế độ sáng và tối: nền pastel luôn sáng
/// nên chữ luôn dùng màu đậm đi kèm, không dùng màu chữ của theme.
class AppHabitColors {
  AppHabitColors._();

  static const List<HabitColor> palette = [
    (background: Color(0xFFCFE6FF), foreground: Color(0xFF0B4F9C)), // Xanh trời
    (background: Color(0xFFBFD3F2), foreground: Color(0xFF163E6E)), // Xanh biển
    (background: Color(0xFFC6F1FA), foreground: Color(0xFF0A6680)), // Xanh nước
    (background: Color(0xFFC4EFE9), foreground: Color(0xFF0F6B63)), // Ngọc
    (background: Color(0xFFCFF4DD), foreground: Color(0xFF1E6B45)), // Bạc hà
    (background: Color(0xFFE5F3C4), foreground: Color(0xFF4F6512)), // Chanh non
    (background: Color(0xFFFCEFC0), foreground: Color(0xFF7A5A00)), // Vàng kem
    (background: Color(0xFFFDDCC6), foreground: Color(0xFF94441A)), // Đào
    (background: Color(0xFFFBD5E3), foreground: Color(0xFF9C2F5E)), // Hồng
    (background: Color(0xFFE6DBFB), foreground: Color(0xFF4B3A9E)), // Tím nhạt
    (background: Color(0xFFD7DEFB), foreground: Color(0xFF2F3F9E)), // Xanh oải hương
    (background: Color(0xFFE2E8F0), foreground: Color(0xFF34465F)), // Bạc
  ];

  /// Màu theo vị trí; số ngoài bảng (dữ liệu hỏng) thì quay vòng thay vì báo lỗi.
  static HabitColor of(int index) => palette[index % palette.length];

  /// Màu chấm của lưới Tổng thể theo mức hoàn thành 1–3 (xem HabitScience.heatLevel):
  /// pha nền pastel với màu đậm cùng tông, mức càng cao càng đậm.
  static Color levelColor(int index, int level) {
    const mix = [0.0, 0.2, 0.4, 0.6];
    final color = of(index);
    return Color.lerp(color.background, color.foreground, mix[level.clamp(0, 3)])!;
  }
}

/// 5.2 Khoảng cách.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// 5.2 Bo góc: 16 cho thẻ (feature 003: rounder, friendlier cards), 999 cho nút dạng viên thuốc.
class AppRadius {
  AppRadius._();

  /// Larger corners in the lead's Farmly style (spec 015).
  static const double card = 20;
  static const double pill = 999;

  /// 5.3 Frame of the sea scene (hero illustration) on Hôm nay and the onboarding.
  static const double hero = 24;
  static const BorderRadius heroBorder = BorderRadius.all(Radius.circular(hero));

  /// A sheet whose top corners overlap the full-bleed sea on Hôm nay.
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(hero));

  static const BorderRadius cardBorder = BorderRadius.all(Radius.circular(card));
  static const BorderRadius pillBorder = BorderRadius.all(Radius.circular(pill));

  /// Bottom sheet chỉ bo hai góc trên, cùng độ bo với thẻ.
  static const BorderRadius sheetBorder = BorderRadius.vertical(top: Radius.circular(card));

  /// Ô nhỏ của lịch nhiệt.
  static const double heatCell = 3;
  static const BorderRadius heatCellBorder = BorderRadius.all(Radius.circular(heatCell));

  /// Ô trong lịch tháng, nhãn nhỏ (huy hiệu, nhắc nhở).
  static const double small = 8;
  static const BorderRadius smallBorder = BorderRadius.all(Radius.circular(small));
}

/// 5.2 Kích thước riêng của Habit tracker (4.x).
class AppHabit {
  AppHabit._();

  /// Vòng tiến độ phút trên thẻ thói quen (chạm để tick).
  static const double checkRing = 52;
  static const double checkRingStroke = 5;

  /// Vòng nhỏ của dải 7 ngày.
  static const double dayRing = 36;
  static const double dayRingStroke = 3;

  /// Lịch nhiệt mini 4 tuần trên thẻ.
  static const double miniHeatHeight = 10;
  static const double heatGap = 2;

  /// Ô lớn nhất của lịch nhiệt 16 tuần trong màn chi tiết.
  static const double heatCellMax = 20;

  /// Ô của bảng Tuần.
  static const double weekCell = 28;

  /// Ô icon trên màn chi tiết và nút chọn icon.
  static const double iconTile = 48;

  /// Ô icon nhỏ cạnh tên thói quen trên thẻ.
  static const double smallIconTile = 28;

  /// Thẻ tab "Hôm nay": cỡ emoji/icon và độ dày vạch tiến độ phút.
  static const double todayIcon = 32;
  static const double todayProgress = 4;

  /// Ô tròn T2–CN của tab "Tuần".
  static const double weekCircle = 36;

  /// Chấm lớn nhất của lưới tab "Tổng thể" và số tuần hiển thị.
  static const double overallDotMax = 12;
  static const int overallWeeks = 20;

  /// Thời gian hiệu ứng khi thẻ được đánh dấu xong và khi thẻ xuất hiện ở mục mới.
  static const Duration cardAnimation = Duration(milliseconds: 320);

  /// Ô tròn chọn màu, chọn số ngày/thứ trong tuần, chọn ngày trong tháng (màn tạo thói quen).
  static const double colorDot = 44;
  static const double dayDot = 40;

  /// Chiều cao nút viên thuốc chọn một trong nhiều lựa chọn (Hằng ngày / Hằng tuần...).
  static const double pillChoice = 44;

  /// Ô ngày trong lịch tháng (Báo cáo, màn chi tiết).
  static const double calendarDay = 36;
  static const double calendarRingStroke = 3;

  /// Biểu đồ cột "Đã hoàn thành" trong màn Báo cáo.
  static const double barChartHeight = 200;

  /// Huy hiệu lục giác của màn Thành tích: trong lưới và trong hộp thoại chúc mừng.
  static const double levelBadge = 72;
  static const double levelBadgeLarge = 104;

  /// Biểu đồ đường điểm sức mạnh.
  static const double chartHeight = 180;

  /// Thời gian chạy hiệu ứng vòng đầy khi tick xong.
  static const Duration tickAnimation = Duration(milliseconds: 450);
}

/// 5.2 Thông số riêng của màn Reels (1.4).
class AppReels {
  AppReels._();

  /// Nền phía sau video là chính video đó được làm mờ. Máy bị giật thì đặt false,
  /// nền sẽ chỉ là màu đen.
  static const bool blurBackground = true;

  /// Độ mờ của nền.
  static const double blurSigma = 30;

  /// Chiều cao khối tiêu đề, chip tag và nút ở đáy trang, tính cả trường hợp xấu nhất:
  /// tiêu đề 2 dòng và chip tag xuống 2 hàng trên màn hình hẹp, plus the "Quay lại học" button
  /// after a distraction. The video is lifted above this block when there is room.
  static const double overlayHeight = 240;

  /// Height of the pill buttons under the video and on the end card.
  static const double buttonHeight = 56;

  /// Shadow behind the end-card title, readable on bright video.
  static const List<Shadow> onVideoShadows = [
    Shadow(color: AppColors.onVideoShadow, blurRadius: 8, offset: Offset(0, 1)),
  ];
}

/// 5.3 Colours of the living sea (feature 003). The water blends from the clear to the murky
/// bands as the sea clarity drops (`SeaScene`). Three bands, top to bottom.
class AppSea {
  AppSea._();

  /// The eye of the little fish (spec 019).
  static const Color fishEye = Color(0xFF2A1C14);

  // Day sea (light mode).
  static const Color skyDay = Color(0xFFD9F1FC);
  static const List<Color> clearDay = [Color(0xFF4CC9F0), Color(0xFF1F7AE0), Color(0xFF0A2A6B)];
  static const List<Color> murkyDay = [Color(0xFF9DB8AE), Color(0xFF66857A), Color(0xFF33504A)];

  // Night sea (dark mode).
  static const Color skyNight = AppColors.darkBackground;
  static const Color moon = Color(0xFFFCEFC0);
  static const List<Color> clearNight = [Color(0xFF1E6FC4), Color(0xFF163E6E), Color(0xFF0A1E3F)];
  static const List<Color> murkyNight = [Color(0xFF4E6B63), Color(0xFF36504A), Color(0xFF1E302D)];

  static const Color seaweed = Color(0xFF1E6B45);
  static const Color seaweedDark = Color(0xFF0F6B63);
  static const Color bubble = Color(0xB3FFFFFF);
  static const Color fish = Color(0xFFFFC93C);
  static const Color fishFin = Color(0xFFE8A600);
  static const Color litter = Color(0xFFB4B2A9);
  static const Color litterLabel = Color(0xFF9FE1CB);

  // 5.4 Other sea places (Góc của Gret, spec 004). Night versions blend these with the night sky.
  static const Color coralSky = Color(0xFFFFE9D6);
  static const List<Color> coralClear = [Color(0xFF3FD0C9), Color(0xFF1AA39A), Color(0xFF0E5E63)];
  static const Color coralPink = Color(0xFFFF7A8A);
  static const Color coralOrange = Color(0xFFFF9F5A);
  static const Color iceSky = Color(0xFFEEF6FB);
  static const List<Color> iceClear = [Color(0xFFA9DDF2), Color(0xFF5FB3DB), Color(0xFF2B6F9C)];
  static const Color iceberg = Color(0xFFFFFFFF);
  static const Color icebergShade = Color(0xFFCFE8F5);
  static const Color deepSky = Color(0xFF0B1D3A);
  static const List<Color> deepClear = [Color(0xFF1B3F7A), Color(0xFF12295A), Color(0xFF08142E)];
  static const Color plankton = Color(0xFF9FF5E6);
  static const Color jelly = Color(0xB3F4C0D1);

  /// How much of the night sky is mixed into a place's colours at night, and into its sky.
  static const double nightBlend = 0.45;
  static const double nightSkyBlend = 0.88;

  /// Living sea (spec 013): the sun and stars, sun and moon rays (strongest alpha, dimmed as the
  /// water murks), ripples under the surface, the sea floor, rising specks and back seaweed.
  static const Color sun = Color(0xFFFFE9A8);
  static const Color star = Color(0xFFFFFFFF);
  static const Color sunRay = Color(0xFFFFFFFF);
  static const double sunRayAlpha = 0.2;
  static const Color moonRay = Color(0xFFCFE8FF);
  static const double moonRayAlpha = 0.09;
  static const Color ripple = Color(0x66FFFFFF);
  static const Color sand = Color(0xFFF0D39A);
  static const Color pebble = Color(0xFFD9B97A);
  static const Color iceFloor = Color(0xFFDCEEF8);
  static const Color deepFloor = Color(0xFF2A3550);
  static const Color speck = Color(0xB3FFFFFF);
  static const Color seaweedBack = Color(0xFF2F8F5B);

  /// Where the sea floor starts, as a share of the scene height.
  static const double floorTop = 0.91;

  // Pearl seas (spec 014): Rừng tảo bẹ, Núi lửa ngầm, Thành phố chìm, Vịnh hoàng hôn.
  static const Color kelpSky = Color(0xFFE4F4D8);
  static const List<Color> kelpClear = [Color(0xFF7FCBA4), Color(0xFF4FA383), Color(0xFF2F7A63)];
  static const Color kelpGold = Color(0xFFC9A43A);
  static const Color kelpOlive = Color(0xFF8FAF3A);
  static const Color kelpLeaf = Color(0xFFA8C64A);
  static const Color kelpFloor = Color(0xFFD8C08A);
  static const Color volcanoSky = Color(0xFFFBE3D4);
  static const List<Color> volcanoClear = [Color(0xFF4A8FB8), Color(0xFF2F5F86), Color(0xFF1E3B5A)];
  static const Color volcanoRock = Color(0xFF2B2B33);
  static const Color lava = Color(0xFFFF8A3D);
  static const Color volcanoCoral = Color(0xFFE2502C);
  static const Color sunkenSky = Color(0xFFDDF3F2);
  static const List<Color> sunkenClear = [Color(0xFF5CCFC8), Color(0xFF3AA7A9), Color(0xFF277F86)];
  static const Color stone = Color(0xFFEDE3CE);
  static const Color stoneShade = Color(0xFFD9CBB0);
  static const Color moss = Color(0xFF5FA05A);
  static const Color glint = Color(0xFFFFE08A);
  static const Color sunkenFloor = Color(0xFFE6D3A6);
  static const Color sunsetSky = Color(0xFFFFD9C2);
  static const List<Color> sunsetClear = [Color(0xFFE98AA0), Color(0xFFB76A9E), Color(0xFF7C4E8C)];
  static const Color sunsetSun = Color(0xFFFFB067);
  static const Color palmShadow = Color(0xFF4A2E3F);
  static const Color pinkSand = Color(0xFFF2C2A8);
  static const Color shell = Color(0xFFFFF1E6);
}

/// 5.3 Sizes of Gret (feature 003). All mascot layers share one 240×200 canvas so outfits and
/// other species line up (spec FR-020).
class AppMascot {
  AppMascot._();

  static const double canvasWidth = 240;
  static const double canvasHeight = 200;

  /// Gret's desk (spec 019): the desk and prop drawings share a 312×230 canvas in mascot units
  /// (assets/scene, scene_art.py); its top edge at y 64 lines up with this share of the mascot's
  /// height, below the mouth, so the face stays visible.
  static const double deskCanvasWidth = 312;
  static const double deskCanvasHeight = 230;
  static const double deskTopY = 64;
  static const double deskTopOnMascot = 0.76;

  /// Gret's home ledges beside Gret (spec 019): width as a share of the scene, at most this, and
  /// how far below Gret's centre they sit (alignment units).
  static const double homeLedgeShare = 0.33;
  static const double homeLedgeMax = 170;
  static const double homeLedgeDrop = 0.12;

  static const double hero = 132;
  static const double full = 180;
  static const double compact = 120;
  static const double small = 72;

  /// Height of the sea scene variants.
  static const double heroSceneHeight = 210;

  /// Hôm nay (spec 010): the sea fills the whole screen and stays still, with a lower sky
  /// ([todaySkyShare]) so little empty sky shows under the header; Gret swims just under the
  /// surface at about 33% of the height, and the floating cards start at [todayCardsTop] of it.
  static const double todaySkyShare = 0.22;
  static const Alignment todayGretAlignment = Alignment(0, -0.34);
  static const double todayCardsTop = 0.44;
  static const double compactSceneHeight = 170;

  /// Gentle up-and-down movement while idle, with a slight tilt (radians, spec 013).
  static const double bobAmplitude = 4;
  static const double bobTilt = 0.04;

  /// Gret's tail wags around where it meets the body (alignment on the canvas), this far
  /// either way (radians), once per [AppMotion.tailWag].
  static const Alignment tailJoint = Alignment(0.383, 0.12);
  static const double tailWag = 0.14;

  /// Speech-bubble tail and thought-bubble dots.
  static const Size bubbleTail = Size(16, 8);
  static const double thoughtDotLarge = 10;
  static const double thoughtDotSmall = 6;

  /// Gret grows a little while reacting to a quiz answer.
  static const double reactionScale = 1.12;

  /// How far Gret turns (in full turns) when it bats a distraction away.
  static const double wiggleTurns = 0.03;

  /// Countdown ring over the focus sea: a share of the scene height, within these bounds.
  static const double focusRingShare = 0.42;
  static const double focusRingMin = 140;
  static const double focusRingMax = 220;
}

/// 5.3 Story-style onboarding: progress segments at the top (one per page).
class AppStory {
  AppStory._();

  static const double segmentHeight = 3;
  static const double segmentGap = 4;
}

/// 5.3 Lively buttons (button styles 1–3, 5): raised pill, breathing, bubbles, sticker chips.
class AppButton {
  AppButton._();

  /// Height of the darker edge the raised pill stands on; it sinks by this much when pressed.
  static const double edge = 5;
  static const double edgeDarkness = 0.45;

  /// Hero buttons (Bắt đầu) use the large text from this height up; others are [compact].
  static const double heroHeight = 64;
  static const double compact = 52;
  static const double breathScale = 1.04;
  static const double disabledFace = 0.12;
  static const double disabledText = 0.38;

  static const int bubbleCount = 7;
  static const double bubbleMin = 6;
  static const double bubbleSpread = 7;
  static const double bubbleRise = 70;
  static const double bubbleAlpha = 0.75;

  /// Round "+" button (style F): its size, and the rings that ripple out from it: how many
  /// pulses when there are habits already, how far they grow, how strong they start.
  static const double fab = 60;
  static const int ripplePulses = 3;
  static const double rippleScale = 1.5;
  static const double rippleAlpha = 0.6;
  static const double rippleStroke = 2;

  /// Sticker chips: selected border and how far (radians) they wiggle.
  static const double chipBorder = 2;
  static const double chipWiggle = 0.10;
}

/// 5.2 Font families declared in pubspec.yaml (spec 011).
class AppFonts {
  AppFonts._();

  static const String heading = 'Baloo2';
  static const String body = 'Nunito';
}

/// 5.1 Tab shell (spec 010): the floating tab bar.
class AppShell {
  AppShell._();

  static const double tabBarHeight = 64;
}

/// 5.6 Quán San Hô (feature 006): café colours by day and by night, and where everyone sits
/// (alignments inside the scene; the countdown ring hangs on the wall like a clock).
class AppCafe {
  AppCafe._();

  static const Color wallDay = Color(0xFFF3E3CF);
  static const Color wallNight = Color(0xFF3A2E3F);
  static const Color panelDay = Color(0xFFE2C9A8);
  static const Color panelNight = Color(0xFF2E2434);
  static const Color floorDay = Color(0xFFCFA57E);
  static const Color floorNight = Color(0xFF2A2338);
  static const Color plankDay = Color(0xFFBF9069);
  static const Color plankNight = Color(0xFF231D30);
  static const Color counterDay = Color(0xFFB8714A);
  static const Color counterNight = Color(0xFF7A4A35);
  static const Color counterTop = Color(0xFFE9D2B5);
  static const Color table = Color(0xFFF4EBDD);
  static const Color tableNight = Color(0xFFCFC3B5);
  static const Color frame = Color(0xFFFFFFFF);
  static const Color frameNight = Color(0xFFCFC3B5);
  static const Color lamp = Color(0xFFFFD27A);
  static const Color cord = Color(0xFF6B5B53);
  static const List<Color> bunting = [
    Color(0xFFE8604A),
    Color(0xFFFFB74D),
    Color(0xFF4CC9F0),
    Color(0xFF7FCB98),
    Color(0xFFB48CF0),
  ];

  /// Floor starts at this share of the height; the panel band sits just above it.
  static const double floorTop = 0.42;
  static const double panelHeight = 0.07;

  /// Arched windows on the sea (left edge, top, width, height as shares of the scene).
  static const Rect leftWindow = Rect.fromLTWH(0.04, 0.05, 0.20, 0.26);
  static const Rect rightWindow = Rect.fromLTWH(0.76, 0.05, 0.20, 0.26);

  /// The countdown ring on the wall: a share of the scene height, within these bounds, so it
  /// stays between the windows.
  static const double ringShare = 0.34;
  static const double ringMin = 120;
  static const double ringMax = 180;

  /// Greeting chips use these AppHabitColors, in greeting order.
  static const List<int> greetingColours = [0, 6, 7, 9];
  static const double windowFrame = 4;

  static const Alignment owner = Alignment(-0.80, -0.06);
  static const List<Alignment> seats = [
    Alignment(0.80, -0.06),
    Alignment(-0.74, 0.50),
    Alignment(0.74, 0.50),
  ];
  static const Alignment gret = Alignment(0, 0.44);

  /// A speaker's bubble sits this far (in alignment units) above them.
  static const double bubbleLift = 0.42;
  static const double bubbleMaxShare = 0.62;

  /// Character widths as a share of the scene height, within bounds, so a tall phone shows a
  /// fuller café and a small one still fits.
  static const double friendShare = 0.11;
  static const double friendMin = 52;
  static const double friendMax = 76;
  static const double gretShare = 0.17;
  static const double gretMin = 84;
  static const double gretMax = 120;

  /// Tables are a little wider than whoever sits at them.
  static const double friendTableScale = 1.15;
  static const double gretTableScale = 1.25;
  static const double tableHeight = 0.2;

  /// The counter hides only the owner's flippers.
  static const double counterWidthScale = 1.3;
  static const double counterHeight = 28;
  static const double counterOverlap = 0.85;

  // Cosy café (spec 019 user story 2).
  static const Color wallpaper = Color(0xFFE3B98F);
  static const double wallpaperStep = 26;
  static const double wallpaperDot = 2.2;
  static const Color sunBeam = Color(0x24FFFFFF);
  static const Color lampShade = Color(0xFFE8A23A);
  static const List<double> lampXs = [0.33, 0.67];
  static const Color rug = Color(0xFFE8604A);
  static const Color rugNight = Color(0xFF7A3A3A);
  static const Color rugBorder = Color(0xFFFFC93C);

  /// The rug under Gret's desk: centre height, width and height as shares of the scene.
  static const double rugY = 0.75;
  static const double rugWidth = 0.62;
  static const double rugHeight = 0.10;

  /// Plants: hanging pots between the windows and the lamps, big pots in the floor corners.
  static const List<Alignment> hangingPlants = [Alignment(-0.5, -1), Alignment(0.5, -1)];
  static const double hangingPlantShare = 0.085;
  static const List<Alignment> floorPlants = [Alignment(-1.04, 1.02), Alignment(1.04, 1.02)];
  static const double floorPlantShare = 0.17;

  // "Phòng mô hình" look (spec 019 user story 3): backdrop, window sea and where everyone stands
  // on the isometric floor (CafeDioramaPainter's corners).
  static const Color dioramaSky = Color(0xFFDDF3FB);
  static const Color dioramaFloorBg = Color(0xFFF6E7F2);
  static const Color dioramaSkyNight = Color(0xFF1B2440);
  static const Color dioramaFloorBgNight = Color(0xFF2B2140);
  static const Color dioramaWindowSea = Color(0xFF2E9BD6);
  static const Color dioramaWindowSeaNight = Color(0xFF123A6B);
  static const Alignment dioramaOwner = Alignment(-0.42, 0.0);
  static const List<Alignment> dioramaSeats = [
    Alignment(0.42, 0.0),
    Alignment(-0.62, 0.34),
    Alignment(0.62, 0.34),
  ];
  static const Alignment dioramaGret = Alignment(0, 0.56);
  static const double dioramaScale = 0.85;
}

/// 5.5 Bản đồ biển (feature 005): ocean, islands per terrain, fog, and layout sizes.
class AppSeaMap {
  AppSeaMap._();

  static const Color ocean = Color(0xFF04142E);
  static const Color oceanLine = Color(0x264CC9F0);

  /// Island bands (spec 012), from the outside in: shallow water ([shallowScale] of the outline),
  /// beach (the outline, with a foam line [islandEdge]) and inner land ([innerScale]).
  static const Color coralShallow = Color(0xFF4CC9F0);
  static const Color coralBeach = Color(0xFFF3E3C3);
  static const Color coralInner = Color(0xFF7FD8E0);
  static const Color iceShallow = Color(0xFFB5D4F4);
  static const Color iceBeach = Color(0xFFF4F8FC);
  static const Color iceInner = Color(0xFFCFE8F5);
  static const Color deepShallow = Color(0xFF3B5BA0);
  static const Color deepBeach = Color(0xFF3A4152);
  static const Color deepInner = Color(0xFF262B38);
  static const Color homeShallow = Color(0xFF4CC9F0);
  static const Color homeBeach = Color(0xFFF3E3C3);
  static const Color homeInner = Color(0xFF7CB868);
  static const Color kelpShallow = Color(0xFF7FCBA4);
  static const Color kelpBeach = Color(0xFFD8C08A);
  static const Color kelpInner = Color(0xFF8FBF6A);
  static const Color volcanoShallow = Color(0xFF4A8FB8);
  static const Color volcanoBeach = Color(0xFF3A3A44);
  static const Color volcanoInner = Color(0xFF2B2B33);
  static const Color sunkenShallow = Color(0xFF5CCFC8);
  static const Color sunkenBeach = Color(0xFFE6D3A6);
  static const Color sunkenInner = Color(0xFFB9DCCB);
  static const Color sunsetShallow = Color(0xFFE98AA0);
  static const Color sunsetBeach = Color(0xFFF2C2A8);
  static const Color sunsetInner = Color(0xFFF7D8B8);
  static const Color unknownLand = Color(0xFF2C3E5A);
  static const Color islandEdge = Color(0x66FFFFFF);

  /// The fog opens this far around a bought sea's island (times its larger radius, spec 014).
  static const double boughtClear = 1.35;
  static const double shallowAlpha = 0.35;
  static const double shallowScale = 1.14;
  static const double innerScale = 0.62;

  /// Scenery and sea life colours (spec 012); corals, icebergs, plankton, jellyfish, fish and
  /// bubbles reuse [AppSea].
  static const Color palmTrunk = Color(0xFF8B5A2B);
  static const Color palmLeaf = Color(0xFF1E6B45);
  static const Color coconut = Color(0xFF6B4423);
  static const Color iceShade = Color(0xFFA9CBE3);
  static const Color rock = Color(0xFF6E7480);
  static const Color rockLight = Color(0xFF9AA0AB);
  static const Color ventGlow = Color(0xFFFF9F5A);
  static const Color bush = Color(0xFF4E9A3E);
  static const Color bushLight = Color(0xFF6FB85A);
  static const Color hutWall = Color(0xFFE9D7B0);
  static const Color hutRoof = Color(0xFFB5573A);
  static const Color lighthouse = Color(0xFFF1EFE8);
  static const Color lighthouseBand = Color(0xFFD85A30);
  static const Color lamp = Color(0xFFFFC93C);
  static const Color turtleShell = Color(0xFF3B6D11);
  static const Color turtleSkin = Color(0xFF7BB33A);
  static const Color whale = Color(0xFF2D4A7A);
  static const Color fishEye = Color(0xFF0A2A6B);

  /// Scenery placement (spec 012): [reefPieces] on [reefScale] of the outline; land scenery
  /// between [landInner] and [landOuter] (beach pieces from [beachFrom], grass up to [grassTo]);
  /// nothing within [sceneryClearance] of a landmark or Gret,
  /// land pieces [sceneryGap] apart. Sea life: a few just off each island ([nearSeaScale]) and
  /// one in about [openSeaChance] of the [openSeaCell] squares of open water.
  static const int reefPieces = 12;
  static const double reefScale = 1.07;
  static const double reefSize = 18;
  static const double landSize = 22;
  static const double landInner = 0.2;
  static const double grassTo = 0.52;
  static const double beachFrom = 0.7;
  static const double landOuter = 0.9;
  static const double sceneryClearance = 56;
  static const double sceneryGap = 30;
  static const double seaLifeSize = 22;
  static const double nearSeaScale = 1.4;
  static const double openSeaCell = 260;
  static const double openSeaChance = 0.4;
  static const int openSeaSeed = 11;

  /// Darkness over what is not explored yet, and the soft circles that open it.
  static const Color worldFog = Color(0xC7020A18);

  /// The ocean under [worldFog]: the screen behind the world, so its edge does not show.
  static const Color fogOcean = Color(0xFF030C1D);
  static const double worldFogSoftness = 22;
  static const double worldClearMin = 70;
  static const double worldClearMax = 230;
  static const double gretClear = 80;

  static const Color pointFound = Color(0xFFE1F5EE);
  static const Color pointFoundIcon = Color(0xFF085041);
  static const Color pointHidden = Color(0xFF5F5E5A);
  static const Color pointHiddenIcon = Color(0xFFF1EFE8);
  static const Color labelBg = Color(0xBF04142E);
  static const Color labelTitle = Color(0xFFE6F1FB);
  static const Color labelSub = Color(0xFFB5D4F4);
  static const Color unknownLabel = Color(0xFF8A9BB5);
  static const Color controlBg = Color(0x29FFFFFF);
  static const Color controlIcon = Color(0xFFE6F1FB);

  /// World layout: islands on slots around the centre, two unknown seas after the last goal.
  static const double worldSpacing = 440;
  static const double worldMargin = 240;
  static const double islandRadius = 150;
  static const double islandRowGrowth = 46;
  static const int unknownSeas = 2;
  static const int pointColumns = 3;

  /// Width of a habit's landmark drawing (spec 012).
  static const double landmarkSize = 76;
  static const double gretSize = 56;

  /// Zoom: the opening glide ends at [focusScale] on Gret's island.
  static const double minScale = 0.2;
  static const double maxScale = 2.5;
  static const double focusScale = 1.0;
  static const double zoomStep = 1.4;
}

/// 5.4 Góc của Gret (feature 004): rarity colours and preview sizes.
class AppCorner {
  /// The café look preview under "Kiểu quán" (spec 019).
  static const double cafePreviewHeight = 120;

  AppCorner._();

  /// The sea picture in the sheet that buys a pearl sea (spec 014).
  static const double sheetSeaWidth = 224;
  static const double sheetSeaHeight = 140;

  static const Color rare = Color(0xFF7F77DD);
  static const Color special = Color(0xFFE8A600);
  static const double cardMascot = 76;
  static const double sheetMascot = 140;
  static const double seaThumbWidth = 104;
  static const double seaThumbHeight = 68;
  static const double cardAspect = 0.72;
}

/// 5.3 Small stat cards next to each other on Hôm nay (clarity ring, streak).
/// 2.1 Hold to start (spec 016): the round button, its blue core, the ring and how far the glow
/// grows.
class AppHold {
  AppHold._();

  static const double button = 76;
  static const double core = 54;
  static const double ring = 5;
  static const double glow = 8;
}

/// 5.2 Icon tiles (spec 015, Farmly style): pastel squares behind outline icons.
class AppIconTile {
  AppIconTile._();

  static const double size = 44;
  static const double small = 34;
  static const double cornerShare = 0.32;
  static const double iconShare = 0.5;
  static const double badge = 18;
  static const double badgeOffset = 5;
  static const double tagOffset = 10;
  static const double chevron = 24;
}

class AppStatCard {
  AppStatCard._();

  static const double padding = 12;
  static const double badge = 40;
  static const double ringStroke = 5;
  static const double icon = 22;

  /// How much the streak flame grows when it pops once.
  static const double popScale = 0.25;
}

/// 5.3 Launch screen (spec 011): Gret swims across the brand blue while DisGret opens.
class AppLaunch {
  AppLaunch._();

  /// Same blue as the system splash, so the hand-over is seamless.
  static const Color background = AppColors.brand;
  static const Color title = AppColors.white;
  static const Color bubble = AppSea.bubble;

  /// Gret's width. Its centre swims from [startX] to [endX] (shares of the screen width) along a
  /// gentle wave of [wave] pixels; with animations removed it rests in the middle.
  static const double gret = AppMascot.full;
  static const double startX = 1.3;
  static const double endX = 0.38;
  static const double wave = 10;
}

/// 5.3 Motion tokens (feature 003, research R6). Every animated widget renders its end state at
/// once when the system asks to remove animations (spec FR-015).
class AppMotion {
  AppMotion._();

  static const Duration entrance = Duration(milliseconds: 280);
  static const Duration entranceStep = Duration(milliseconds: 60);
  static const double entranceOffset = 12;
  static const Duration countUp = Duration(milliseconds: 600);
  static const Duration ringFill = Duration(milliseconds: 700);
  static const Duration seaColour = Duration(milliseconds: 800);
  static const Duration seaLoop = Duration(seconds: 8);
  static const Duration bob = Duration(milliseconds: 2400);
  static const Duration tailWag = Duration(milliseconds: 700);
  static const Duration blink = Duration(milliseconds: 120);
  static const int blinkMinSeconds = 3;
  static const int blinkMaxSeconds = 6;
  static const Duration reaction = Duration(milliseconds: 400);
  static const Duration speechBubble = Duration(seconds: 3);

  /// How long an emote (love, wink, proud, surprised) shows before Gret's mood returns (spec 018).
  static const Duration emote = Duration(milliseconds: 2500);

  /// One loop of Gret's work at the desk: the pen crossing the notebook, a page turning (spec 019).
  static const Duration deskLoop = Duration(milliseconds: 3000);

  /// Quán San Hô: a friend replies this long after Gret greets (feature 006).
  static const Duration cafeReplyDelay = Duration(milliseconds: 1500);
  static const Duration seaReady = Duration(milliseconds: 1200);

  /// A story page of the onboarding turns by itself after this long.
  static const Duration storyPage = Duration(seconds: 4);

  /// Focus session: a distraction drifts towards Gret this often, takes [distractionDrift] to
  /// reach Gret and pop; coming back after a real distraction bursts several in
  /// [distractionBurst]. Gret's swat wiggle lasts [wiggle].
  static const Duration distractionEvery = Duration(seconds: 12);
  static const Duration distractionDrift = Duration(milliseconds: 2200);
  static const Duration distractionBurst = Duration(milliseconds: 900);
  static const Duration wiggle = Duration(milliseconds: 420);

  /// Buttons: the raised pill sinks in [press]; bubbles rise for [bubbleBurst].
  static const Duration press = Duration(milliseconds: 70);
  static const Duration bubbleBurst = Duration(milliseconds: 900);

  /// One ring rippling out of the round "+" button (style F).
  static const Duration ripple = Duration(milliseconds: 1800);

  /// Sea map: opening the map glides from the whole world to Gret's island; buttons glide faster.
  static const Duration mapOpen = Duration(milliseconds: 1600);
  static const Duration mapGlide = Duration(milliseconds: 600);

  /// Hold to start (spec 016): hold this long to start; a press shorter than [holdTapLimit]
  /// counts as a tap and shows the hint.
  static const Duration holdToStart = Duration(milliseconds: 1500);
  static const Duration holdTapLimit = Duration(milliseconds: 250);

  /// Launch screen (spec 011): Gret swims for [launch], then the screen fades for [launchFade].
  static const Duration launch = Duration(milliseconds: 1400);
  static const Duration launchFade = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeOutCubic;
}

/// 5.2 Icon nét mảnh dùng trong app. Gom một chỗ để sau này đổi bộ icon chỉ sửa ở đây.
class AppIcons {
  AppIcons._();

  static const IconData home = Icons.home_outlined;
  static const IconData reels = Icons.play_circle_outline_rounded;
  static const IconData focus = Icons.timer_outlined;
  static const IconData name = Icons.badge_outlined;

  /// 5.6 Study places: Gret's sea and Quán San Hô.
  static const IconData sea = Icons.waves_rounded;
  static const IconData cafe = Icons.local_cafe_outlined;
  static const IconData habits = Icons.task_alt_rounded;
  static const IconData settings = Icons.settings_outlined;
  static const IconData goal = Icons.flag_outlined;
  static const IconData play = Icons.play_arrow_rounded;
  static const IconData star = Icons.star_outline_rounded;
  static const IconData starFilled = Icons.star_rounded;
  static const IconData blocked = Icons.block_outlined;
  static const IconData distraction = Icons.notifications_paused_outlined;
  static const IconData away = Icons.logout_rounded;
  static const IconData schedule = Icons.schedule_rounded;
  static const IconData replay = Icons.restart_alt_rounded;
  static const IconData check = Icons.check_circle_outline_rounded;
  static const IconData missing = Icons.highlight_off_rounded;
  static const IconData permissions = Icons.shield_outlined;
  static const IconData intervention = Icons.front_hand_outlined;
  static const IconData breakTime = Icons.coffee_outlined;
  static const IconData add = Icons.add_rounded;
  static const IconData more = Icons.more_vert_rounded;
  static const IconData streak = Icons.local_fire_department_outlined;
  static const IconData note = Icons.edit_note_rounded;
  static const IconData demoData = Icons.auto_awesome_outlined;
  static const IconData deleteAll = Icons.delete_forever_outlined;
  static const IconData stats = Icons.bar_chart_rounded;
  static const IconData reelStats = Icons.movie_outlined;

  // 4.1, 4.2 Habit tracker.
  static const IconData done = Icons.check_rounded;
  static const IconData freeze = Icons.ac_unit_rounded;
  static const IconData minimal = Icons.hourglass_bottom_rounded;
  static const IconData strength = Icons.trending_up_rounded;
  static const IconData badge = Icons.military_tech_outlined;
  static const IconData identity = Icons.person_outline_rounded;
  static const IconData place = Icons.place_outlined;
  static const IconData cue = Icons.link_rounded;
  static const IconData reminder = Icons.info_outline_rounded;
  static const IconData clearMark = Icons.undo_rounded;
  static const IconData previous = Icons.chevron_left_rounded;
  static const IconData next = Icons.chevron_right_rounded;
  static const IconData close = Icons.close_rounded;

  /// 1.1 Quiz answer cards, one icon per motivation type.
  static const IconData motivationMoney = Icons.savings_outlined;
  static const IconData motivationFamily = Icons.family_restroom_rounded;
  static const IconData motivationCareer = Icons.work_outline_rounded;
  static const IconData motivationProveYourself = Icons.emoji_events_outlined;
  static const IconData motivationFreedom = Icons.explore_outlined;

  /// 5.4 Góc của Gret: the wardrobe button and pearls.
  static const IconData wardrobe = Icons.checkroom_rounded;
  static const IconData pearl = Icons.bubble_chart_outlined;
  static const IconData clarity = Icons.water_drop_outlined;

  /// 5.5 Bản đồ biển: the map segment and the discovery points.
  static const IconData map = Icons.map_outlined;
  static const IconData zoomOut = Icons.remove_rounded;
  static const IconData locate = Icons.my_location_rounded;

  /// Sticker chips: time of day filters.
  static const IconData allDay = Icons.apps_rounded;
  static const IconData morning = Icons.wb_sunny_outlined;
  static const IconData afternoon = Icons.wb_twilight_rounded;
  static const IconData evening = Icons.nightlight_outlined;
  static const IconData pointHidden = Icons.question_mark_rounded;
  static const IconData fishCave = Icons.set_meal_outlined;
  static const IconData shipwreck = Icons.sailing_outlined;
  static const IconData kelpGarden = Icons.grass_rounded;
  static const IconData treasure = Icons.diamond_outlined;
  static const IconData coralTemple = Icons.account_balance_outlined;
  static const IconData oldAnchor = Icons.anchor_rounded;

  /// 5.3 Where Gret pops a distraction.
  static const IconData sparkle = Icons.auto_awesome_rounded;

  /// 5.3 Distractions Gret bats away during a focus session: a reel, a notification, a message.
  static const List<IconData> distractions = [
    Icons.play_circle_outline_rounded,
    Icons.notifications_none_rounded,
    Icons.chat_bubble_outline_rounded,
  ];

  /// Icon chọn cho thói quen. Thói quen chỉ lưu tên (khoá) để bản release lược được font icon;
  /// khoá "book" là icon mặc định (Habit.defaultIcon).
  /// Thói quen cũng có thể dùng emoji thay cho icon, xem lib/data/habit_icon_catalog.dart.
  static const Map<String, IconData> habitIcons = {
    'book': Icons.menu_book_rounded,
    'edit': Icons.edit_outlined,
    'reading': Icons.auto_stories_outlined,
    'code': Icons.code_rounded,
    'language': Icons.translate_rounded,
    'math': Icons.calculate_outlined,
    'science': Icons.science_outlined,
    'idea': Icons.lightbulb_outline_rounded,
    'school': Icons.school_outlined,
    'laptop': Icons.laptop_mac_rounded,
    'brush': Icons.brush_outlined,
    'camera': Icons.photo_camera_outlined,
    'music': Icons.music_note_outlined,
    'headphones': Icons.headphones_rounded,
    'fitness': Icons.fitness_center_rounded,
    'run': Icons.directions_run_rounded,
    'bike': Icons.directions_bike_rounded,
    'walk': Icons.directions_walk_rounded,
    'meditation': Icons.self_improvement_rounded,
    'water': Icons.water_drop_outlined,
    'food': Icons.restaurant_outlined,
    'sleep': Icons.bedtime_outlined,
    'sun': Icons.wb_sunny_outlined,
    'heart': Icons.favorite_outline_rounded,
    'money': Icons.savings_outlined,
    'clean': Icons.cleaning_services_outlined,
    'plant': Icons.local_florist_outlined,
    'phone_off': Icons.phonelink_erase_rounded,
    'call': Icons.call_outlined,
    'task': Icons.task_alt_rounded,
  };

  static IconData habitIcon(String key) => habitIcons[key] ?? habitIcons['book']!;

  // Màn tạo/sửa thói quen (4.1).
  static const IconData calendar = Icons.calendar_month_outlined;
  static const IconData repeatDays = Icons.autorenew_rounded;
  static const IconData alarm = Icons.alarm_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData arrowForward = Icons.arrow_forward_rounded;
  static const IconData bell = Icons.notifications_none_rounded;
  static const IconData archive = Icons.inventory_2_outlined;
  static const IconData deleteHistory = Icons.delete_sweep_outlined;
  static const IconData skip = Icons.skip_next_rounded;
  static const IconData editValue = Icons.edit_outlined;
  static const IconData skipDash = Icons.remove_rounded;
  static const IconData report = Icons.insert_chart_outlined_rounded;
  static const IconData dragHandle = Icons.drag_indicator_rounded;
  static const IconData lock = Icons.lock_outline_rounded;
  static const IconData trophy = Icons.emoji_events_outlined;
  static const IconData myHabits = Icons.format_list_bulleted_rounded;
  static const IconData dropdown = Icons.keyboard_arrow_down_rounded;

  /// Icon trên huy hiệu của 9 cấp thành tích (màn Thành tích, 4.2).
  static const List<IconData> levelIcons = [
    Icons.eco_outlined,
    Icons.local_florist_outlined,
    Icons.park_outlined,
    Icons.directions_run_rounded,
    Icons.bolt_rounded,
    Icons.local_fire_department_outlined,
    Icons.diamond_outlined,
    Icons.workspace_premium_outlined,
    Icons.emoji_events_outlined,
  ];
  static const IconData details = Icons.insights_rounded;
}

/// 5.2 ThemeData sáng và tối (Material 3, font Be Vietnam Pro).
class AppTheme {
  AppTheme._();

  /// For text and controls drawn on the sea's sky or the café wall, which follow the clock
  /// rather than dark mode (spec 013): light by day, dark by night.
  static ThemeData forSky({required bool night}) => night ? dark : light;

  static final ThemeData light = _build(_lightScheme);
  static final ThemeData dark = _build(_darkScheme);

  // primary: nút chính. secondary: chữ link, tab/chip/ô tick đang chọn (cần đủ tương phản
  // để đọc). tertiary: màu nhấn cho vòng streak, vòng/thanh tiến độ, điểm sức mạnh.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.lightPrimary,
    onPrimary: AppColors.white,
    // Links and selected items use a deeper blue so they read on the light background.
    secondary: AppColors.lightLink,
    onSecondary: AppColors.white,
    tertiary: AppColors.lightAccent,
    onTertiary: AppColors.white,
    error: AppColors.lightError,
    onError: AppColors.white,
    surface: AppColors.lightBackground,
    onSurface: AppColors.lightText,
    onSurfaceVariant: AppColors.lightTextSecondary,
    surfaceContainerLowest: AppColors.lightSurface,
    surfaceContainerLow: AppColors.lightSurface,
    surfaceContainer: AppColors.lightSurface,
    surfaceContainerHigh: AppColors.lightSurface,
    surfaceContainerHighest: AppColors.lightSurface,
    outline: AppColors.lightDivider,
    outlineVariant: AppColors.lightDivider,
    surfaceTint: Colors.transparent,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.darkPrimary,
    onPrimary: AppColors.white,
    secondary: AppColors.darkLink,
    onSecondary: AppColors.darkBackground,
    tertiary: AppColors.darkAccent,
    onTertiary: AppColors.darkBackground,
    error: AppColors.darkError,
    onError: AppColors.darkBackground,
    surface: AppColors.darkBackground,
    onSurface: AppColors.darkText,
    onSurfaceVariant: AppColors.darkTextSecondary,
    surfaceContainerLowest: AppColors.darkSurface,
    surfaceContainerLow: AppColors.darkSurface,
    surfaceContainer: AppColors.darkSurface,
    surfaceContainerHigh: AppColors.darkSurface,
    surfaceContainerHighest: AppColors.darkSurface,
    outline: AppColors.darkDivider,
    outlineVariant: AppColors.darkDivider,
    surfaceTint: Colors.transparent,
  );

  /// 5.2 (spec 011): Baloo 2 for display, headline and title styles (rounded, lively), Nunito for
  /// body and label styles (easy to read). Both are variable fonts bundled in assets/fonts/; each
  /// style picks its weight on the `wght` axis, so screens should only change the colour, never
  /// the fontWeight.
  static TextTheme _textTheme(ColorScheme scheme) {
    TextStyle font(String family, double size, FontWeight weight, {Color? color, double? height}) {
      return TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        fontVariations: [FontVariation.weight(weight.value.toDouble())],
        color: color ?? scheme.onSurface,
        height: height,
        // Bỏ giãn chữ mặc định của Material để chữ gọn, dấu tiếng Việt không bị thưa.
        letterSpacing: 0,
      );
    }

    const heading = FontWeight.w700;
    const title = FontWeight.w600;
    const body = FontWeight.w400;
    const label = FontWeight.w700;
    const h = AppFonts.heading;
    const b = AppFonts.body;

    return TextTheme(
      displayLarge: font(h, 56, heading, height: 1.1),
      displayMedium: font(h, 44, heading, height: 1.1),
      displaySmall: font(h, 36, heading, height: 1.15),
      headlineLarge: font(h, 30, heading, height: 1.25),
      headlineMedium: font(h, 26, heading, height: 1.25),
      headlineSmall: font(h, 22, heading, height: 1.3),
      titleLarge: font(h, 20, title, height: 1.3),
      titleMedium: font(h, 16, title, height: 1.35),
      titleSmall: font(h, 14, title, height: 1.35),
      bodyLarge: font(b, 16, body, height: 1.45),
      bodyMedium: font(b, 14, body, height: 1.45),
      bodySmall: font(b, 12, body, color: scheme.onSurfaceVariant, height: 1.4),
      labelLarge: font(b, 14, label, height: 1.3),
      labelMedium: font(b, 12, label, height: 1.3),
      labelSmall: font(b, 11, label, height: 1.3),
    );
  }

  static ThemeData _build(ColorScheme scheme) {
    final text = _textTheme(scheme);
    final thinLine = BorderSide(color: scheme.outlineVariant);

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      dividerColor: scheme.outlineVariant,
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: scheme.onSurface),
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        shape: Border(bottom: thinLine),
      ),
      // Thẻ không đổ bóng, phân tách bằng đường kẻ mảnh.
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder, side: thinLine),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
          textStyle: text.titleMedium,
        ),
      ),
      // Farmly style (spec 015): a white pill with a blue border and blue text.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          backgroundColor: scheme.surface,
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.45), width: 1.5),
          textStyle: text.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.secondary, textStyle: text.labelLarge),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.secondary,
        checkmarkColor: scheme.onSecondary,
        side: thinLine,
        shape: const StadiumBorder(),
        labelStyle: text.labelLarge?.copyWith(
          color: WidgetStateColor.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? scheme.onSecondary : scheme.onSurface,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          selectedBackgroundColor: scheme.secondary,
          selectedForegroundColor: scheme.onSecondary,
          side: thinLine,
          textStyle: text.labelLarge,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
      ),
      // 4.1 Bottom sheet, ô nhập, hộp thoại xác nhận của màn Thói quen.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainer,
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        counterStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        border: OutlineInputBorder(borderRadius: AppRadius.cardBorder, borderSide: thinLine),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.cardBorder, borderSide: thinLine),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardBorder,
          borderSide: BorderSide(color: scheme.secondary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardBorder,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardBorder,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder, side: thinLine),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder, side: thinLine),
        labelTextStyle: WidgetStatePropertyAll(text.bodyMedium),
      ),
      // 4.1 Nút tròn "+" nổi ở tab Thói quen: màu chính, bóng rất nhẹ.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 3,
        shape: const CircleBorder(),
      ),
      // 4 tab dưới cùng: không có nền chỉ báo, tab đang chọn đổi sang màu nhấn.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.secondary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.secondary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
