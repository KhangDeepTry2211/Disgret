// 4.x Kiểm thử giao diện Habit tracker mới: tạo thói quen 4 bước, giữ lâu để làm bản 2 phút
// hoặc nghỉ phép, nhắc "Đừng bỏ 2 lần liên tiếp", chế độ Tuần/Tháng, màn chi tiết, nút Focus.
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
import 'package:focus_app/widgets/habit_card.dart';
import 'package:focus_app/widgets/habit_check_ring.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const Goal _goal = Goal(id: 'g1', title: 'Đạt điểm A', reason: 'Để xin thực tập');
const Habit _habit = Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 25);

/// Thứ Năm 5/3/2026, 10 giờ sáng. Thứ Hai của tuần này là 2/3.
final DateTime _now = DateTime(2026, 3, 5, 10);

Future<void> _pump(WidgetTester tester, {Brightness? brightness}) async {
  if (brightness != null) {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }
  await pumpApp(tester, clock: () => _now);
}

Future<void> _tap(WidgetTester tester, Finder finder) => tapAndSettle(tester, finder);

Future<void> _onboard() => ProfileRepository().completeOnboarding(
  const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
);

Future<void> _seedSampleData() async {
  await _onboard();
  await MockData.createDemoData(now: _now);
}

Future<void> _openHabitsTab(WidgetTester tester) =>
    _tap(tester, find.widgetWithText(NavigationDestination, 'Thói quen'));

Finder _cardOf(String name) => find.widgetWithText(HabitCard, name);

Finder _ringOf(String name) =>
    find.descendant(of: _cardOf(name), matching: find.byType(HabitCheckRing));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() async {
    await openMemoryBoxes();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  });

  tearDown(() async {
    await Hive.close();
  });

  group('Tạo thói quen 4 bước', () {
    testWidgets('Đủ 4 bước có gợi ý, bước cuối hiện câu xác nhận, lưu đủ trường mới', (
      tester,
    ) async {
      await _onboard();
      await GoalRepository().save(_goal);
      await _pump(tester);
      await _openHabitsTab(tester);
      await _tap(tester, find.text('Thêm thói quen'));

      // Bước 1: bản sắc.
      expect(find.text('Bước 1/4 · Bản sắc'), findsOneWidget);
      await _tap(tester, find.text('học đều mỗi ngày'));
      await _tap(tester, find.text('Tiếp'));

      // Bước 2: tên, phút, icon.
      expect(find.text('Bước 2/4 · Thói quen'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Tên thói quen'), 'Học');
      await _tap(tester, find.bySemanticsLabel('Biểu tượng code'));
      await _tap(tester, find.text('Tiếp'));

      // Bước 3: "Sau khi…" và "Tại…".
      expect(find.text('Bước 3/4 · Khi nào, ở đâu'), findsOneWidget);
      await _tap(tester, find.text('ăn tối'));
      await _tap(tester, find.text('bàn học'));

      // Quay lại bước trước vẫn giữ những gì đã nhập.
      await _tap(tester, find.text('Quay lại'));
      expect(find.widgetWithText(TextFormField, 'Học'), findsOneWidget);
      await _tap(tester, find.text('Tiếp'));
      await _tap(tester, find.text('Tiếp'));

      // Bước 4: bản 2 phút và câu xác nhận.
      expect(find.text('Bước 4/4 · Bản 2 phút'), findsOneWidget);
      await _tap(tester, find.text('Làm 1 câu bài tập'));
      expect(find.text('Sau khi ăn tối, tôi sẽ học 25 phút tại bàn học.'), findsOneWidget);
      expect(find.text('Vì tôi là người học đều mỗi ngày.'), findsOneWidget);
      await _tap(tester, find.text('Lưu thói quen'));

      final habit = HabitRepository().getAll().single;
      expect(habit.name, 'Học');
      expect(habit.cue, 'ăn tối');
      expect(habit.place, 'bàn học');
      expect(habit.minimalVersion, 'Làm 1 câu bài tập');
      expect(habit.icon, 'code');
      expect(GoalRepository().getById('g1')?.identity, 'học đều mỗi ngày');

      // Về lại tab Thói quen, thẻ có dòng "Sau khi… · tại…" và câu bản sắc của mục tiêu.
      expect(find.text('Sau khi ăn tối · tại bàn học'), findsOneWidget);
      expect(find.text('Tôi là người học đều mỗi ngày'), findsOneWidget);
    });

    testWidgets('Đóng giữa chừng thì không lưu gì', (tester) async {
      await _onboard();
      await GoalRepository().save(_goal);
      await _pump(tester);
      await _openHabitsTab(tester);
      await _tap(tester, find.text('Thêm thói quen'));
      await _tap(tester, find.text('học đều mỗi ngày'));
      await _tap(tester, find.byTooltip('Đóng'));

      expect(HabitRepository().getAll(), isEmpty);
      expect(GoalRepository().getById('g1')?.identity, '');
    });
  });

  group('Giữ lâu vòng tiến độ', () {
    testWidgets('Làm bản 2 phút rồi đổi sang nghỉ phép; mỗi ngày chỉ giữ một loại', (tester) async {
      await _onboard();
      await GoalRepository().save(_goal);
      await HabitRepository().save(_habit.copyWith(minimalVersion: 'Đọc 1 trang'));
      await _pump(tester);
      await _openHabitsTab(tester);

      await tester.longPress(_ringOf('Ôn bài'));
      await tester.pumpAndSettle();
      expect(find.text('Đọc 1 trang'), findsOneWidget);
      await _tap(tester, find.text('Làm bản 2 phút'));

      expect(HabitLogRepository().getAll().single.source, HabitLogSource.minimal);
      expect(find.text('Đã làm bản 2 phút'), findsOneWidget);
      expect(tester.widget<HabitCheckRing>(_ringOf('Ôn bài')).done, isTrue);
      expect(find.bySemanticsLabel('Chuỗi 1 ngày'), findsOneWidget);

      await tester.longPress(_ringOf('Ôn bài'));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Nghỉ phép'));

      expect(HabitLogRepository().getAll().single.source, HabitLogSource.freeze);
      expect(find.text('Hôm nay nghỉ phép'), findsOneWidget);
      expect(tester.widget<HabitCheckRing>(_ringOf('Ôn bài')).done, isFalse);

      // Chạm vào vòng khi đang nghỉ phép thì bỏ đánh dấu.
      await _tap(tester, _ringOf('Ôn bài'));
      expect(HabitLogRepository().getAll(), isEmpty);
    });

    testWidgets('Tuần này đã nghỉ phép thì không chọn được nữa', (tester) async {
      await _onboard();
      await GoalRepository().save(_goal);
      await HabitRepository().save(_habit);
      await HabitLogRepository().setMark(_habit, DateTime(2026, 3, 2), HabitLogSource.freeze);
      await _pump(tester);
      await _openHabitsTab(tester);

      await tester.longPress(_ringOf('Ôn bài'));
      await tester.pumpAndSettle();
      expect(find.text('Tuần này bạn đã dùng ngày nghỉ phép rồi.'), findsOneWidget);
      final freezeTile = tester.widget<ListTile>(find.widgetWithText(ListTile, 'Nghỉ phép'));
      expect(freezeTile.enabled, isFalse);
    });
  });

  group('Với dữ liệu mẫu', () {
    testWidgets('Hôm qua bỏ thì nhắc "Đừng bỏ 2 lần liên tiếp", bấm vào là làm bản 2 phút', (
      tester,
    ) async {
      await _seedSampleData();
      await _pump(tester);
      await _openHabitsTab(tester);

      const nudge = 'Đừng bỏ 2 lần liên tiếp – làm bản 2 phút nhé';
      expect(
        find.descendant(of: _cardOf('Đọc sách 10 trang'), matching: find.text(nudge)),
        findsOne,
      );
      expect(find.text(nudge), findsOneWidget, reason: 'Hai thói quen kia hôm qua có làm');

      await _tap(tester, find.text(nudge));
      final log = HabitLogRepository().getAll().where(
        (log) => log.habitId == MockData.readingHabit.id && log.date == DateTime(2026, 3, 5),
      );
      expect(log.single.source, HabitLogSource.minimal);
      expect(find.text(nudge), findsNothing);
    });

    testWidgets('Tuần: bảng thói quen × 7 ngày, cuối hàng là % tuần', (tester) async {
      await _seedSampleData();
      await _pump(tester);
      await _openHabitsTab(tester);
      await _tap(tester, find.text('Tuần'));

      expect(find.text('Tuần 2/3 – 8/3'), findsOneWidget);
      // "Ôn bài" làm đủ T2, T3, T4; hôm nay chưa làm nên chưa tính: 100%.
      expect(find.bySemanticsLabel('Tuần này Ôn bài Tư Duy Tính Toán đạt 100%'), findsOneWidget);
      // "Đọc sách" làm T2, T3; hôm qua (T4) bỏ: 2/3 = 67%.
      expect(find.bySemanticsLabel('Tuần này Đọc sách 10 trang đạt 67%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tháng: lịch nhiệt cả tháng, chạm vào ngày xem chi tiết', (tester) async {
      await _seedSampleData();
      await _pump(tester);
      await _openHabitsTab(tester);
      await _tap(tester, find.text('Tháng'));

      expect(find.text('Tháng 3/2026'), findsOneWidget);
      // Tháng hiện tại thì không sang được tháng sau.
      expect(
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, AppIcons.next)).onPressed,
        isNull,
      );

      await _tap(tester, find.bySemanticsLabel('4/3'));
      expect(find.text('Thứ Tư, 4/3/2026'), findsOneWidget);
      expect(find.text('Hoàn thành · Ôn xong chương 4, mai làm đề.'), findsOneWidget);
      expect(find.text('Chưa làm'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10)); // Chạm ra ngoài để đóng sheet.
      await tester.pumpAndSettle();

      await _tap(tester, find.byTooltip('Tháng trước'));
      expect(find.text('Tháng 2/2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Màn chi tiết: số liệu, biểu đồ sức mạnh, hành trình, lịch 16 tuần, ghi chú', (
      tester,
    ) async {
      await _seedSampleData();
      await _pump(tester);
      await _openHabitsTab(tester);
      // "Ôn bài" là thẻ cuối (Hive sắp theo id) nên phải cuộn xuống.
      await tester.scrollUntilVisible(find.text('Ôn bài Tư Duy Tính Toán'), 200);
      await _tap(tester, find.text('Ôn bài Tư Duy Tính Toán'));

      expect(
        find.text('Sau khi ăn tối, tôi sẽ ôn bài Tư Duy Tính Toán 25 phút tại bàn học.'),
        findsOne,
      );
      expect(find.text('Bản 2 phút: Đọc lại 1 trang ghi chú'), findsOneWidget);
      expect(find.text('Tôi là người học đều mỗi ngày, không học dồn'), findsOneWidget);
      expect(find.bySemanticsLabel('Chuỗi hiện tại: 5 ngày'), findsOneWidget);
      expect(find.bySemanticsLabel('Dài nhất: 22 ngày'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Tỉ lệ 30 ngày: \d+%$')), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);

      await tester.scrollUntilVisible(find.text('40/66 ngày hoàn thành'), 200);
      await tester.scrollUntilVisible(find.text('Thành thói quen'), 100);
      expect(find.bySemanticsLabel('Huy hiệu Vững vàng, 40 ngày, đã đạt'), findsOneWidget);
      expect(find.bySemanticsLabel('Huy hiệu Thành thói quen, 66 ngày, chưa đạt'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Ôn xong chương 4, mai làm đề.'), 200);
      expect(find.bySemanticsLabel(RegExp(r'^Lịch 16 tuần: hoàn thành')), findsOneWidget);
      expect(find.text('Mệt nên chỉ đọc lại ghi chú.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Xoá thói quen ở màn chi tiết thì quay về danh sách', (tester) async {
      await _seedSampleData();
      await _pump(tester);
      await _openHabitsTab(tester);
      await _tap(tester, find.text('Đọc sách 10 trang'));

      await _tap(tester, find.byTooltip('Tuỳ chọn thói quen'));
      await _tap(tester, find.text('Xoá'));
      await _tap(tester, find.text('Xoá'));

      expect(find.byType(HabitCard), findsNWidgets(2));
      expect(HabitRepository().getById(MockData.readingHabit.id), isNull);
    });

    testWidgets('Nút Focus trên thẻ mở màn Focus với đúng thói quen đó', (tester) async {
      await _seedSampleData();
      await _pump(tester);
      await _openHabitsTab(tester);

      await _tap(
        tester,
        find.descendant(
          of: _cardOf('Đọc sách 10 trang'),
          matching: find.widgetWithText(OutlinedButton, 'Focus'),
        ),
      );

      expect(find.text('Chỉ cần cam kết 5 phút đầu'), findsOneWidget);
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(dropdown.initialValue, MockData.readingHabit.id);
    });

    testWidgets('Mọi chế độ và màn chi tiết hiện được ở chế độ tối, không tràn giao diện', (
      tester,
    ) async {
      await _seedSampleData();
      await _pump(tester, brightness: Brightness.dark);
      await _openHabitsTab(tester);
      expect(tester.takeException(), isNull);

      for (final view in ['Tuần', 'Tháng', 'Hôm nay']) {
        await _tap(tester, find.text(view));
        expect(tester.takeException(), isNull, reason: view);
      }
      await _tap(tester, find.text('Làm bài tập về nhà'));
      await tester.scrollUntilVisible(find.text('Ghi chú'), 300);
      expect(tester.takeException(), isNull);
    });
  });
}
