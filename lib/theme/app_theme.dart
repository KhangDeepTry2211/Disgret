// 5.2 Design system
// MỘT file duy nhất chứa màu, font, bo góc, khoảng cách và icon của DisGret.
// Màn hình chỉ lấy giá trị từ đây hoặc từ Theme.of(context), không viết mã màu cứng.
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// 5.2 Bảng màu "Ocean": xanh nước biển + đen.
/// Chế độ tối = phương án A "Biển đêm", chế độ sáng = phương án B "Mực & đại dương".
/// Không dùng gradient: nút, vòng và thanh tiến độ đều tô màu đặc.
class AppColors {
  AppColors._();

  static const Color white = Color(0xFFFFFFFF);

  // Chế độ tối (A – Biển đêm).
  static const Color darkBackground = Color(0xFF06090F);
  static const Color darkSurface = Color(0xFF0E1726);
  static const Color darkDivider = Color(0xFF1C2940);
  static const Color darkText = Color(0xFFE8F1FF);
  static const Color darkTextSecondary = Color(0xFF8A9BB5);
  static const Color darkPrimary = Color(0xFF1F7AE0);
  static const Color darkAccent = Color(0xFF4CC9F0);
  static const Color darkError = Color(0xFFF2B8B5);

  // Chế độ sáng (B – Mực & đại dương).
  static const Color lightBackground = Color(0xFFF4F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFDCE3EE);
  static const Color lightText = Color(0xFF0B0F17);
  static const Color lightTextSecondary = Color(0xFF5A6B85);
  static const Color lightPrimary = Color(0xFF0B4F9C);
  static const Color lightAccent = Color(0xFF1E9BD7);
  static const Color lightError = Color(0xFFB3261E);

  // Lịch nhiệt 4 mức (heat0 = ít nhất, heat3 = nhiều nhất).
  static const List<Color> darkHeat = [
    Color(0xFF12233D),
    Color(0xFF163E6E),
    Color(0xFF1F7AE0),
    Color(0xFF4CC9F0),
  ];
  static const List<Color> lightHeat = [
    Color(0xFFE3ECF7),
    Color(0xFFA9C8EA),
    Color(0xFF3D86D1),
    Color(0xFF0B4F9C),
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

/// 5.2 Bo góc: 12 cho thẻ, 999 cho nút dạng viên thuốc.
class AppRadius {
  AppRadius._();

  static const double card = 12;
  static const double pill = 999;

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

/// 5.2 Icon nét mảnh dùng trong app. Gom một chỗ để sau này đổi bộ icon chỉ sửa ở đây.
class AppIcons {
  AppIcons._();

  static const IconData home = Icons.home_outlined;
  static const IconData reels = Icons.play_circle_outline_rounded;
  static const IconData focus = Icons.timer_outlined;
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

  static final ThemeData light = _build(_lightScheme);
  static final ThemeData dark = _build(_darkScheme);

  // primary: nút chính. secondary: chữ link, tab/chip/ô tick đang chọn (cần đủ tương phản
  // để đọc). tertiary: màu nhấn cho vòng streak, vòng/thanh tiến độ, điểm sức mạnh.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.lightPrimary,
    onPrimary: AppColors.white,
    // Xanh nhấn #1E9BD7 hơi nhạt để làm chữ trên nền trắng, nên chữ và trạng thái đang chọn
    // dùng xanh biển đậm.
    secondary: AppColors.lightPrimary,
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
    secondary: AppColors.darkAccent,
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

  /// Tiêu đề đậm 600–700, nội dung 400.
  /// Phải gọi GoogleFonts cho từng kiểu chữ để app tải đúng độ đậm của font;
  /// vì vậy màn hình chỉ nên đổi màu chữ, không tự đổi fontWeight.
  static TextTheme _textTheme(ColorScheme scheme) {
    TextStyle font(double size, FontWeight weight, {Color? color, double? height}) {
      return GoogleFonts.beVietnamPro(
        fontSize: size,
        fontWeight: weight,
        color: color ?? scheme.onSurface,
        height: height,
        // Bỏ giãn chữ mặc định của Material để chữ gọn, dấu tiếng Việt không bị thưa.
        letterSpacing: 0,
      );
    }

    const heading = FontWeight.w700;
    const title = FontWeight.w600;
    const body = FontWeight.w400;

    return TextTheme(
      displayLarge: font(56, heading, height: 1.1),
      displayMedium: font(44, heading, height: 1.1),
      displaySmall: font(36, heading, height: 1.15),
      headlineLarge: font(30, heading, height: 1.25),
      headlineMedium: font(26, heading, height: 1.25),
      headlineSmall: font(22, heading, height: 1.3),
      titleLarge: font(20, title, height: 1.3),
      titleMedium: font(16, title, height: 1.35),
      titleSmall: font(14, title, height: 1.35),
      bodyLarge: font(16, body, height: 1.45),
      bodyMedium: font(14, body, height: 1.45),
      bodySmall: font(12, body, color: scheme.onSurfaceVariant, height: 1.4),
      labelLarge: font(14, title, height: 1.3),
      labelMedium: font(12, title, height: 1.3),
      labelSmall: font(11, title, height: 1.3),
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
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
          side: thinLine,
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
