// 4.1, 4.2 Kiểm thử giao diện: màn Báo cáo, "Thói quen của tôi" (kéo để sắp xếp), Thành tích
// và hộp thoại chúc mừng lên cấp.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/mock_data.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/habit_log.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_log_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/habit_check_ring.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

/// Thứ Năm 5/3/2026, 10 giờ sáng.
final DateTime _now = DateTime(2026, 3, 5, 10);

Future<void> _tap(WidgetTester tester, Finder finder) => tapAndSettle(tester, finder);

Future<void> _onboard() => ProfileRepository().completeOnboarding(
  const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
);

Future<void> _openHabitsTab(WidgetTester tester) =>
    _tap(tester, find.widgetWithText(NavigationDestination, 'Thói quen'));

Future<void> _habitsMenu(WidgetTester tester, String item) async {
  await _tap(tester, find.byTooltip('Tuỳ chọn'));
  await _tap(tester, find.text(item));
}

/// Vùng cuộn ngoài cùng của màn đang mở.
Finder get _pageScroll => find.byType(Scrollable).first;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() async {
    await openMemoryBoxes();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  });

  tearDown(() async => Hive.close());

  group('Báo cáo', () {
    testWidgets('4 ô số liệu, biểu đồ cột đổi kỳ, biểu đồ đường, lịch tháng', (tester) async {
      await _onboard();
      await MockData.createDemoData(now: _now);
      await pumpApp(tester, clock: () => _now);
      await _openHabitsTab(tester);
      await _tap(tester, find.byTooltip('Báo cáo'));

      expect(find.bySemanticsLabel('Chuỗi hiện tại: 5 ngày'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Tỉ lệ hoàn thành: \d+%$')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Lần hoàn thành: \d+$')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Ngày hoàn hảo: \d+$')), findsOneWidget);

      // Mặc định "Tuần này", cột hôm nay (ngày 5) được chọn.
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Đang chọn 5: 0 lần')), findsOneWidget);
      await _tap(tester, find.byTooltip('Chọn kỳ: Đã hoàn thành'));
      await _tap(tester, find.text('Năm nay').last);
      expect(find.bySemanticsLabel(RegExp(r'Đang chọn Th3: \d+ lần')), findsOneWidget);

      await tester.scrollUntilVisible(find.byType(LineChart), 200, scrollable: _pageScroll);
      expect(find.bySemanticsLabel(RegExp(r'^Biểu đồ tỉ lệ hoàn thành. Đang chọn Th3')), findsOne);

      // Lịch: hôm qua (4/3) có thói quen xong và có thói quen bỏ nên không đạt 100%.
      await tester.scrollUntilVisible(find.text('Lịch hoàn thành'), 200, scrollable: _pageScroll);
      await tester.scrollUntilVisible(
        find.bySemanticsLabel(RegExp(r'^4/3: \d+%$')),
        100,
        scrollable: _pageScroll,
      );
      expect(find.bySemanticsLabel(RegExp(r'^4/3: \d+%$')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Chế độ tối hiện được, không tràn giao diện', (tester) async {
      await _onboard();
      await MockData.createDemoData(now: _now);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(tester, clock: () => _now);
      await _openHabitsTab(tester);
      await _tap(tester, find.byTooltip('Báo cáo'));
      await tester.scrollUntilVisible(find.text('Lịch hoàn thành'), 300, scrollable: _pageScroll);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Chưa có thói quen nào thì báo trống', (tester) async {
      await _onboard();
      await GoalRepository().save(const Goal(id: 'g1', title: 'A', reason: 'B'));
      await pumpApp(tester, clock: () => _now);
      await _openHabitsTab(tester);
      await _tap(tester, find.byTooltip('Báo cáo'));
      expect(
        find.text('Chưa có thói quen nào. Tạo thói quen và đánh dấu vài ngày để xem báo cáo.'),
        findsOneWidget,
      );
    });
  });

  group('Thói quen của tôi', () {
    testWidgets('2 tab Thói quen / Việc một lần; kéo tay kéo để sắp xếp, lưu sortOrder', (
      tester,
    ) async {
      await _onboard();
      await MockData.createDemoData(now: _now);
      await pumpApp(tester, clock: () => _now);
      await _openHabitsTab(tester);
      await _habitsMenu(tester, 'Thói quen của tôi');

      expect(find.text('Thói quen của tôi'), findsOneWidget);
      expect(find.text('Làm bài tập về nhà'), findsOneWidget);
      expect(find.text('Nộp báo cáo nhóm'), findsNothing);

      // Kéo "Ôn bài" (thứ 2) lên trên "Làm bài tập" (thứ 1).
      final handle = find.bySemanticsLabel('Kéo để sắp xếp Ôn bài Tư Duy Tính Toán');
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 100));
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(0, -40));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      List<String> order() {
        final habits = HabitRepository().getAll()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return habits.map((habit) => habit.id).toList();
      }

      expect(
        order().indexOf('demo_habit_review'),
        lessThan(order().indexOf('demo_habit_exercise')),
      );

      await _tap(tester, find.text('Việc một lần'));
      expect(find.text('Nộp báo cáo nhóm'), findsOneWidget);
      expect(find.text('Làm bài tập về nhà'), findsNothing);

      // Chạm thẻ để mở màn chi tiết.
      await _tap(tester, find.text('Nộp báo cáo nhóm'));
      expect(find.byTooltip('Sửa thói quen'), findsOneWidget);
    });
  });

  group('Thành tích', () {
    testWidgets('Lưới 9 cấp: cấp đã đạt có màu, cấp chưa đạt có ổ khoá', (tester) async {
      await _onboard();
      await MockData.createDemoData(now: _now);
      await pumpApp(tester, clock: () => _now);
      await _openHabitsTab(tester);
      await _habitsMenu(tester, 'Thành tích');

      expect(find.bySemanticsLabel('Cấp 1, 10 lần, đã đạt'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.bySemanticsLabel('Cấp 9, 1000 lần, chưa đạt'),
        200,
        scrollable: _pageScroll,
      );
      expect(find.bySemanticsLabel('Cấp 9, 1000 lần, chưa đạt'), findsOneWidget);
      expect(find.byIcon(AppIcons.lock), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Lên cấp thì chúc mừng một lần; bỏ tick rồi tick lại không chúc mừng nữa', (
      tester,
    ) async {
      await _onboard();
      const habit = Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 25);
      await GoalRepository().save(const Goal(id: 'g1', title: 'A', reason: 'B'));
      await HabitRepository().save(habit);
      // 9 lần hoàn thành trước hôm nay: tick hôm nay là đủ 10 lần, lên Cấp 1.
      for (var i = 1; i <= 9; i++) {
        await HabitLogRepository().setMark(habit, DateTime(2026, 3, 5 - i), HabitLogSource.manual);
      }
      await pumpApp(tester, clock: () => _now);

      await _tap(tester, find.byType(HabitCheckRing));
      expect(find.text('Chúc mừng! 🎉'), findsOneWidget);
      expect(find.text('Bạn đã lên Cấp 1'), findsOneWidget);
      await _tap(tester, find.text('Tuyệt!'));
      expect(ProfileRepository().celebratedLevel, 1);

      // Bỏ tick (xuống 9 lần) rồi tick lại: không chúc mừng lần nữa.
      await _tap(tester, find.byType(HabitCheckRing));
      await _tap(tester, find.byType(HabitCheckRing));
      expect(find.text('Chúc mừng! 🎉'), findsNothing);
    });

    testWidgets('"Xem thành tích" trong hộp thoại mở màn Thành tích', (tester) async {
      await _onboard();
      const habit = Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 25);
      await GoalRepository().save(const Goal(id: 'g1', title: 'A', reason: 'B'));
      await HabitRepository().save(habit);
      for (var i = 1; i <= 9; i++) {
        await HabitLogRepository().setMark(habit, DateTime(2026, 3, 5 - i), HabitLogSource.manual);
      }
      await pumpApp(tester, clock: () => _now);

      await _tap(tester, find.byType(HabitCheckRing));
      await _tap(tester, find.text('Xem thành tích'));
      expect(find.text('Thành tích'), findsOneWidget);
      expect(find.text('Cấp 1'), findsWidgets);
    });

    testWidgets('Tạo dữ liệu mẫu không hiện hộp thoại chúc mừng', (tester) async {
      await _onboard();
      await pumpApp(tester, clock: () => _now);
      await openSettingsFromHome(tester);
      await tester.scrollUntilVisible(find.text('Tạo dữ liệu mẫu'), 200);
      await _tap(tester, find.text('Tạo dữ liệu mẫu'));

      expect(find.text('Chúc mừng! 🎉'), findsNothing);
      expect(ProfileRepository().celebratedLevel, greaterThan(0));
    });
  });
}
