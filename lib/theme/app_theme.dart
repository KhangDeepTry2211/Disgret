// 5.2 Design system
// MỘT file duy nhất chứa màu, font, bo góc, khoảng cách và icon của DisGret.
// Màn hình chỉ lấy giá trị từ đây hoặc từ Theme.of(context), không viết mã màu cứng.
import 'dart:math' as math;

import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// 5.2 Bảng màu.
class AppColors {
  AppColors._();

  // Màu thương hiệu (lấy từ logo).
  static const Color navy = Color(0xFF0A2A6B);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color teal = Color(0xFF0891B2);

  // Chế độ sáng.
  static const Color lightBackground = white;
  static const Color lightSurface = Color(0xFFF4F7FC);
  static const Color lightText = navy;
  static const Color lightTextSecondary = Color(0xFF5B6B8C);
  static const Color lightDivider = Color(0xFFE0E4EC);
  static const Color lightError = Color(0xFFB3261E);

  // Chế độ tối.
  static const Color darkBackground = Color(0xFF07142F);
  static const Color darkSurface = Color(0xFF0F2350);
  static const Color darkText = Color(0xFFF4F7FC);
  static const Color darkTextSecondary = Color(0xFF9FB0CF);
  static const Color darkDivider = Color(0xFF24386A);
  static const Color darkError = Color(0xFFF2B8B5);

  // Màn Reels: chữ và nút nổi trên video, luôn sáng dù app đang ở chế độ nào.
  static const Color videoBackground = Color(0xFF000000);
  static const Color onVideo = white;
  static const Color onVideoSecondary = Color(0xCCFFFFFF);
  static const Color onVideoTrack = Color(0x4DFFFFFF);
  static const Color onVideoChip = Color(0x33FFFFFF);
  static const Color scrimClear = Color(0x00000000);
  static const Color scrimDark = Color(0xCC000000);
  static const Color scrimTop = Color(0x80000000);

  /// Phủ lên nền mờ của video (đen 45%) để video chính nổi bật.
  static const Color reelBlurScrim = Color(0x73000000);

  /// Gradient nhấn: chỉ dùng cho nút "Bắt đầu", viền avatar, thanh tiến độ.
  /// Đặt teal ở 60% để chữ trắng giữa nút luôn đủ tương phản (cyan quá sáng).
  static const LinearGradient accentGradient = LinearGradient(
    colors: [navy, teal, cyan],
    stops: [0, 0.6, 1],
  );

  /// Gradient của vòng streak: chạy quanh vòng tròn và khép kín, không bị vết nối.
  static const SweepGradient streakGradient = SweepGradient(
    colors: [navy, teal, cyan, teal, navy],
    transform: GradientRotation(-math.pi / 2),
  );

  /// Gradient của vòng tiến độ quanh đồng hồ: bắt đầu từ đỉnh, sáng dần theo thời gian.
  /// Đoạn cuối quay về navy vì đầu tròn của nét vẽ lấn ra sau điểm đầu, tức là phần cuối của
  /// gradient; nếu vẫn là cyan thì sẽ hiện một chấm sáng ngay đỉnh vòng tròn.
  static const SweepGradient focusRingGradient = SweepGradient(
    colors: [navy, teal, cyan, navy],
    stops: [0, 0.5, 0.98, 0.99],
    transform: GradientRotation(-math.pi / 2),
  );

  /// Bản cho chế độ tối: navy còn tối hơn cả vạch nền nên đầu phiên gần như không thấy tiến độ,
  /// vì vậy bắt đầu từ teal.
  static const SweepGradient focusRingGradientDark = SweepGradient(
    colors: [teal, cyan, teal],
    stops: [0, 0.98, 0.99],
    transform: GradientRotation(-math.pi / 2),
  );

  /// Lớp mờ đen ở đáy màn Reels để chữ dễ đọc.
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
}

/// 5.2 Thông số riêng của màn Reels (1.4).
class AppReels {
  AppReels._();

  /// Nền phía sau video là chính video đó được làm mờ. Máy bị giật thì đặt false,
  /// nền sẽ chỉ là màu đen.
  static const bool blurBackground = true;

  /// Độ mờ của nền.
  static const double blurSigma = 30;

  /// Chiều cao khối chữ và nút ở đáy trang, tính cả trường hợp xấu nhất:
  /// tiêu đề 2 dòng và chip tag xuống 2 hàng trên màn hình hẹp.
  static const double overlayHeight = 210;
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
}

/// 5.2 ThemeData sáng và tối (Material 3, font Be Vietnam Pro).
class AppTheme {
  AppTheme._();

  static final ThemeData light = _build(_lightScheme);
  static final ThemeData dark = _build(_darkScheme);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.navy,
    onPrimary: AppColors.white,
    // Link và trạng thái đang chọn.
    secondary: AppColors.teal,
    onSecondary: AppColors.white,
    tertiary: AppColors.cyan,
    onTertiary: AppColors.navy,
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
    // Nền tối cũng là xanh navy nên nút #0A2A6B sẽ chìm mất:
    // ở chế độ tối, nút chính dùng cyan chữ tối để vẫn nổi rõ.
    primary: AppColors.cyan,
    onPrimary: AppColors.darkBackground,
    secondary: AppColors.cyan,
    onSecondary: AppColors.darkBackground,
    tertiary: AppColors.teal,
    onTertiary: AppColors.white,
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
      // 4.2 Ô tick "Hôm nay đã làm".
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? scheme.secondary : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onSecondary),
        side: BorderSide(color: scheme.onSurfaceVariant, width: 1.5),
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
