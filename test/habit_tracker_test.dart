// 4.1, 4.2 Kiểm thử giao diện Habit tracker: màn tạo/sửa thói quen, chọn icon, xoá; tab Thói quen
// (Hôm nay: chạm, vuốt, giữ lâu, lọc theo buổi; Tuần; Tổng thể); màn chi tiết; nhắc ở Trang chủ.
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
import 'package:focus_app/widgets/habit_card.dart';
import 'package:focus_app/widgets/habit_today_card.dart';
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

/// Vùng cuộn ngoài cùng của màn đang mở (bên trong còn lưới lịch, hàng chip cũng cuộn được).
Finder get _pageScroll => find.byType(Scrollable).first;

/// Thẻ của một thói quen ở tab "Hôm nay".
Finder _todayCard(String name) => find.widgetWithText(HabitTodayCard, name);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() async {
    await openMemoryBoxes();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  });

  tearDown(() async {
    await Hive.close();
  });

  group('Màn tạo thói quen', () {
    Future<void> openForm(WidgetTester tester) async {
      await _onboard();
      await GoalRepository().save(_goal);
      await _pump(tester);
      await _openHabitsTab(tester);
      await _tap(tester, find.byTooltip('Tạo thói quen'));
      expect(find.text('Tạo thói quen'), findsWidgets);
    }

    /// Gõ tên rồi bỏ con trỏ, để trang không tự cuộn ngược về ô tên.
    Future<void> typeName(WidgetTester tester, String hint, String name) async {
      await tester.enterText(find.widgetWithText(TextFormField, hint), name);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
    }

    testWidgets('Hằng tuần theo thứ, buổi tối, màu, nhắc nhở, kết thúc sau N ngày', (tester) async {
      await openForm(tester);
      await typeName(tester, 'Ví dụ: Ôn bài', 'Học');

      await _tap(tester, find.bySemanticsLabel('Màu Đào'));
      await _tap(tester, find.text('Hằng tuần'));
      await _tap(tester, find.text('Thứ cố định'));
      for (final day in ['Thứ Hai', 'Thứ Tư', 'Thứ Sáu']) {
        await _tap(tester, find.bySemanticsLabel(day));
      }
      await _tap(tester, find.text('Tối'));

      // Kết thúc sau N ngày: bật công tắc, chọn "Sau số ngày", nhập 66.
      await _tap(tester, find.byType(Switch).first);
      await _tap(tester, find.text('Sau số ngày'));
      await _tap(tester, find.text('Sau 30 ngày'));
      await tester.enterText(find.byType(TextFormField).last, '66');
      await _tap(tester, find.text('Xong'));
      expect(find.text('Sau 66 ngày'), findsOneWidget);

      await _tap(tester, find.byType(Switch).last);
      expect(find.text('07:00'), findsOneWidget);
      expect(find.text('Bản này mới lưu giờ nhắc, chưa gửi thông báo.'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sau khi ăn tối'),
        'Sau khi ăn tối',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Việc thật nhỏ cho ngày mệt, ví dụ: Đọc 1 trang'),
        'Đọc 1 trang',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await _tap(tester, find.text('Lưu'));

      final habit = HabitRepository().getAll().single;
      expect(habit.name, 'Học');
      expect(habit.type, HabitType.regular);
      expect(habit.colorIndex, 7);
      expect(habit.repeat, HabitRepeat.weekly);
      expect(habit.weekdays, [DateTime.monday, DateTime.wednesday, DateTime.friday]);
      expect(habit.timeOfDay, HabitTimeOfDay.evening);
      expect(habit.endRule, HabitEndRule.afterDays);
      expect(habit.endAfterDays, 66);
      expect(habit.reminderEnabled, isTrue);
      expect(habit.reminderTime, '07:00');
      expect(habit.cue, 'ăn tối');
      expect(habit.minimalVersion, 'Đọc 1 trang');
      expect(habit.startDate, DateTime(2026, 3, 5));

      // Hôm nay (Thứ Năm) không có lịch nên tab Hôm nay trống; tab Tuần ghi tần suất.
      expect(find.text('Hôm nay không có thói quen nào đến hạn'), findsOneWidget);
      await _tap(tester, find.text('Tuần'));
      expect(find.text('T2, T4, T6'), findsOneWidget);
    });

    testWidgets('Hằng tuần theo số ngày và hằng tháng theo ngày', (tester) async {
      await openForm(tester);
      await typeName(tester, 'Ví dụ: Ôn bài', 'Chạy bộ');
      await _tap(tester, find.text('Hằng tuần'));
      expect(find.text('5 ngày mỗi tuần'), findsOneWidget);
      await _tap(tester, find.bySemanticsLabel('3 ngày mỗi tuần'));
      expect(find.text('3 ngày mỗi tuần'), findsOneWidget);

      // Đổi sang hằng tháng: chưa chọn ngày nào thì không lưu được.
      await _tap(tester, find.text('Hằng tháng'));
      await _tap(tester, find.text('Lưu'));
      expect(find.text('Chọn ít nhất một ngày trong tháng'), findsOneWidget);
      expect(HabitRepository().getAll(), isEmpty);

      await _tap(tester, find.bySemanticsLabel('Ngày 1'));
      await _tap(tester, find.bySemanticsLabel('Ngày 15'));
      expect(find.text('Hằng tháng vào ngày 1, 15'), findsOneWidget);
      await _tap(tester, find.text('Lưu'));

      final habit = HabitRepository().getAll().single;
      expect(habit.repeat, HabitRepeat.monthly);
      expect(habit.monthDays, [1, 15]);
      expect(habit.weekdays, isEmpty);
    });

    testWidgets('Việc một lần: có ngày hạn, không có phần lặp lại và kết thúc', (tester) async {
      await openForm(tester);
      await _tap(tester, find.text('Việc một lần'));
      expect(find.text('Tên việc'), findsOneWidget);
      expect(find.text('Lặp lại'), findsNothing);
      expect(find.text('Kết thúc vào'), findsNothing);
      expect(find.text('Hôm nay, 5/3/2026'), findsOneWidget);

      await typeName(tester, 'Ví dụ: Nộp bài tập lớn', 'Nộp bài tập lớn');
      await _tap(tester, find.text('Lưu'));

      final task = HabitRepository().getAll().single;
      expect(task.type, HabitType.oneTime);
      expect(task.dueDate, DateTime(2026, 3, 5));
      // Hạn hôm nay nên hiện ở tab Hôm nay.
      expect(_todayCard('Nộp bài tập lớn'), findsOneWidget);
    });

    testWidgets('Chọn icon: tìm không dấu, đổi tab Emoji, Huỷ thì giữ icon cũ', (tester) async {
      await openForm(tester);
      await _tap(tester, find.text('Xem tất cả'));
      expect(find.text('Chọn biểu tượng'), findsOneWidget);

      // Đang chọn emoji 📚 nên mở sẵn tab Emoji; tìm "chay" (không dấu) ra emoji chạy bộ.
      await tester.enterText(find.byType(TextField).last, 'chay');
      await tester.pumpAndSettle();
      // Chỉ xét lưới của màn chọn icon (hàng chọn nhanh phía sau cũng có 🏃 và 📚).
      Finder inPicker(String icon) => find.descendant(
        of: find.byType(GridView).last,
        matching: find.bySemanticsLabel('Biểu tượng $icon'),
      );
      expect(inPicker('🏃'), findsOneWidget);
      expect(inPicker('📚'), findsNothing);

      await tester.enterText(find.byType(TextField).last, 'xyz');
      await tester.pumpAndSettle();
      expect(find.text('Không có biểu tượng nào khớp "xyz".'), findsOneWidget);
      await _tap(tester, find.text('Huỷ'));

      await _tap(tester, find.text('Xem tất cả'));
      await _tap(tester, find.text('Icon'));
      await _tap(
        tester,
        find.descendant(
          of: find.byType(GridView).last,
          matching: find.bySemanticsLabel('Biểu tượng code'),
        ),
      );
      await _tap(tester, find.text('Chọn'));

      await typeName(tester, 'Ví dụ: Ôn bài', 'Lập trình');
      await _tap(tester, find.text('Lưu'));
      expect(HabitRepository().getAll().single.icon, 'code');
    });

    testWidgets('Sửa thói quen: mở sẵn mọi lựa chọn đã lưu', (tester) async {
      await _onboard();
      await GoalRepository().save(_goal);
      await HabitRepository().save(
        const Habit(
          id: 'h1',
          goalId: 'g1',
          name: 'Ôn bài',
          minMinutesPerDay: 25,
          repeat: HabitRepeat.monthly,
          monthDays: [3, 8],
          timeOfDay: HabitTimeOfDay.morning,
        ),
      );
      await _pump(tester);
      await _openHabitsTab(tester);
      // Hằng tháng ngày 3, 8 nên hôm nay (5/3) không hiện ở Hôm nay: mở từ tab Tuần → chi tiết.
      await _tap(tester, find.text('Tuần'));
      await _tap(tester, find.text('Ôn bài'));
      await _tap(tester, find.byTooltip('Sửa thói quen'));

      expect(find.text('Sửa thói quen'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Ôn bài'), findsOneWidget);
      expect(find.text('Hằng tháng vào ngày 3, 8'), findsOneWidget);

      await _tap(tester, find.bySemanticsLabel('Ngày 8'));
      await _tap(tester, find.text('Lưu'));
      final habit = HabitRepository().getById('h1')!;
      expect(habit.monthDays, [3]);
      expect(habit.timeOfDay, HabitTimeOfDay.morning);
    });

    testWidgets('Đóng giữa chừng thì không lưu gì', (tester) async {
      await openForm(tester);
      await typeName(tester, 'Ví dụ: Ôn bài', 'Học');
      await _tap(tester, find.byTooltip('Đóng'));
      expect(HabitRepository().getAll(), isEmpty);
    });
  });

  group('Tab Hôm nay', () {
    Future<void> seed({Habit habit = _habit}) async {
      await _onboard();
      await GoalRepository().save(_goal);
      await HabitRepository().save(habit);
    }

    testWidgets('Chạm thẻ: đánh dấu xong, thẻ chuyển xuống "Đã xong"; chạm lại thì bỏ', (
      tester,
    ) async {
      await seed();
      await _pump(tester);
      await _openHabitsTab(tester);
      expect(find.text('Đã xong (1)'), findsNothing);

      await _tap(tester, _todayCard('Ôn bài'));
      expect(HabitLogRepository().getAll().single.source, HabitLogSource.manual);
      expect(find.text('Đã xong (1)'), findsOneWidget);
      expect(find.text('Xong hết việc hôm nay rồi! 💪'), findsOneWidget);

      await _tap(tester, _todayCard('Ôn bài'));
      expect(HabitLogRepository().getAll(), isEmpty);
      expect(find.text('Đã xong (1)'), findsNothing);
    });

    testWidgets('Vuốt trái: bỏ qua (log skip); vuốt phải: xong', (tester) async {
      await seed();
      await HabitRepository().save(
        const Habit(id: 'h2', goalId: 'g1', name: 'Đọc sách', minMinutesPerDay: 10),
      );
      await _pump(tester);
      await _openHabitsTab(tester);

      await tester.drag(_todayCard('Ôn bài'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      final skip = HabitLogRepository().getAll().single;
      expect(skip.habitId, 'h1');
      expect(skip.source, HabitLogSource.skip);
      expect(find.text('Đã bỏ qua (1)'), findsOneWidget);
      expect(find.text('Bỏ qua hôm nay'), findsOneWidget);

      await tester.drag(_todayCard('Đọc sách'), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(
        HabitLogRepository().getAll().singleWhere((log) => log.habitId == 'h2').source,
        HabitLogSource.manual,
      );
      expect(find.text('Đã xong (1)'), findsOneWidget);
    });

    testWidgets('Giữ lâu: làm bản 2 phút; tuần này đã nghỉ phép thì không chọn được nữa', (
      tester,
    ) async {
      await seed(habit: _habit.copyWith(minimalVersion: 'Đọc 1 trang'));
      await HabitLogRepository().setMark(_habit, DateTime(2026, 3, 2), HabitLogSource.freeze);
      await _pump(tester);
      await _openHabitsTab(tester);

      await tester.longPress(_todayCard('Ôn bài'));
      await tester.pumpAndSettle();
      expect(find.text('Đọc 1 trang'), findsOneWidget);
      expect(find.text('Tuần này bạn đã dùng ngày nghỉ phép rồi.'), findsOneWidget);
      expect(tester.widget<ListTile>(find.widgetWithText(ListTile, 'Nghỉ phép')).enabled, isFalse);

      await _tap(tester, find.text('Làm bản 2 phút'));
      final today = HabitLogRepository().getAll().where((log) => log.date == DateTime(2026, 3, 5));
      expect(today.single.source, HabitLogSource.minimal);
      expect(find.text('Đã làm bản 2 phút'), findsOneWidget);
      expect(find.text('Đã xong (1)'), findsOneWidget);
    });

    testWidgets('Giữ lâu → "Bắt đầu Focus" mở Focus với đúng thói quen đó', (tester) async {
      await seed();
      await HabitRepository().save(
        const Habit(id: 'h2', goalId: 'g1', name: 'Đọc sách', minMinutesPerDay: 10),
      );
      await _pump(tester);
      await _openHabitsTab(tester);

      await tester.longPress(_todayCard('Đọc sách'));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Bắt đầu Focus'));

      expect(find.text('Chỉ cần cam kết 5 phút đầu'), findsOneWidget);
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(dropdown.initialValue, 'h2');
    });

    testWidgets('Có phút Focus mà chưa đủ: thẻ hiện số phút và vạch tiến độ mỏng', (tester) async {
      await seed();
      await HabitLogRepository().save(
        HabitLog(
          id: 'focus_1',
          habitId: 'h1',
          date: DateTime(2026, 3, 5),
          source: HabitLogSource.focus,
          minutes: 10,
        ),
      );
      await _pump(tester);
      await _openHabitsTab(tester);

      expect(find.text('10/25 phút'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(bar.value, closeTo(0.4, 0.001));
    });

    testWidgets('Thói quen không đến hạn hôm nay thì không hiện; không còn gì thì báo trống', (
      tester,
    ) async {
      // Hôm nay Thứ Năm; thói quen chỉ làm Thứ Hai.
      await seed(
        habit: const Habit(
          id: 'h1',
          goalId: 'g1',
          name: 'Ôn bài',
          minMinutesPerDay: 25,
          repeat: HabitRepeat.weekly,
          weekdays: [DateTime.monday],
        ),
      );
      await _pump(tester);
      await _openHabitsTab(tester);

      expect(find.text('Hôm nay không có thói quen nào đến hạn'), findsOneWidget);
      await _tap(tester, find.text('Tuần'));
      expect(find.text('Ôn bài'), findsOneWidget);
      expect(find.text('T2'), findsWidgets);
    });

    testWidgets('Lọc theo buổi; buổi không có thói quen thì báo trống và có nút "Xem tất cả"', (
      tester,
    ) async {
      await _seedSampleData();
      await _pump(tester);
      await _openHabitsTab(tester);

      await _tap(tester, find.widgetWithText(ChoiceChip, 'Tối'));
      expect(find.text('Ôn bài Tư Duy Tính Toán'), findsOneWidget);
      expect(find.text('Đọc sách 10 trang'), findsOneWidget);
      expect(find.text('Làm bài tập về nhà'), findsNothing);

      await _tap(tester, find.widgetWithText(ChoiceChip, 'Chiều'));
      expect(find.text('Làm bài tập về nhà'), findsOneWidget);
      expect(find.text('Nộp báo cáo nhóm'), findsOneWidget);
      expect(find.text('Ôn bài Tư Duy Tính Toán'), findsNothing);

      await _tap(tester, find.widgetWithText(ChoiceChip, 'Tất cả'));
      expect(find.text('Uống đủ 2 lít nước'), findsOneWidget);
    });

    testWidgets('Bộ lọc không có kết quả thì báo trống, "Xem tất cả" để bỏ lọc', (tester) async {
      await seed();
      await _pump(tester);
      await _openHabitsTab(tester);

      await _tap(tester, find.widgetWithText(ChoiceChip, 'Sáng'));
      expect(find.text('Không có thói quen nào vào buổi sáng'), findsOneWidget);
      await _tap(tester, find.text('Xem tất cả'));
      expect(find.text('Ôn bài'), findsOneWidget);
    });
  });

  group('Với dữ liệu mẫu', () {
    testWidgets('Trang chủ: hôm qua bỏ thì nhắc "Đừng bỏ 2 lần liên tiếp", bấm là làm bản 2 phút', (
      tester,
    ) async {
      await _seedSampleData();
      await _pump(tester);

      const nudge = 'Đừng bỏ 2 lần liên tiếp – làm bản 2 phút nhé';
      await tester.scrollUntilVisible(find.text(nudge), 200);
      expect(
        find.descendant(
          of: find.widgetWithText(HabitCard, 'Đọc sách 10 trang'),
          matching: find.text(nudge),
        ),
        findsOne,
      );

      await _tap(tester, find.text(nudge));
      final log = HabitLogRepository().getAll().where(
        (log) => log.habitId == MockData.readingHabit.id && log.date == DateTime(2026, 3, 5),
      );
      expect(log.single.source, HabitLogSource.minimal);
    });

    testWidgets('Tuần: 7 ô T2–CN, chạm để đổi xong → bỏ qua → chưa làm; ngày tới thì khoá', (
      tester,
    ) async {
      await _seedSampleData();
      await _pump(tester);
      await _openHabitsTab(tester);
      await _tap(tester, find.text('Tuần'));

      Finder cell(String name, String day, String state) =>
          find.bySemanticsLabel('$name $day: $state');

      // "Ôn bài" làm đủ T2, T3, T4; hôm nay (T5) chưa làm; T6 chưa tới.
      expect(cell('Ôn bài Tư Duy Tính Toán', 'Thứ Hai', 'đã xong'), findsOneWidget);
      expect(cell('Ôn bài Tư Duy Tính Toán', 'Thứ Năm', 'chưa làm'), findsOneWidget);
      expect(cell('Ôn bài Tư Duy Tính Toán', 'Thứ Sáu', 'chưa tới'), findsOneWidget);
      // "Làm bài tập" đủ phút nhờ phiên Focus thì khoá.
      expect(cell('Làm bài tập về nhà', 'Thứ Tư', 'đã xong nhờ phiên Focus'), findsOneWidget);

      // "Đọc sách" bỏ hôm qua (T4): chạm lần lượt để đổi trạng thái.
      bool readingWednesday(HabitLogSource source) => HabitLogRepository().getAll().any(
        (log) =>
            log.habitId == MockData.readingHabit.id &&
            log.date == DateTime(2026, 3, 4) &&
            log.source == source,
      );
      // Màn có 2 vùng cuộn (hàng chip ngang và danh sách dọc): chỉ rõ vùng dọc.
      await tester.scrollUntilVisible(
        cell('Đọc sách 10 trang', 'Thứ Tư', 'chưa làm'),
        200,
        scrollable: find.byWidgetPredicate(
          (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
        ),
      );
      await _tap(tester, cell('Đọc sách 10 trang', 'Thứ Tư', 'chưa làm'));
      expect(readingWednesday(HabitLogSource.manual), isTrue);
      await _tap(tester, cell('Đọc sách 10 trang', 'Thứ Tư', 'đã xong'));
      expect(readingWednesday(HabitLogSource.skip), isTrue);
      await _tap(tester, cell('Đọc sách 10 trang', 'Thứ Tư', 'bỏ qua'));
      expect(readingWednesday(HabitLogSource.skip), isFalse);
      expect(readingWednesday(HabitLogSource.manual), isFalse);

      expect(find.text('Hằng ngày'), findsWidgets);
      expect(find.text('5 ngày/tuần'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tổng thể: mỗi thói quen một lưới 20 tuần', (tester) async {
      await _seedSampleData();
      await _pump(tester);
      await _openHabitsTab(tester);
      await _tap(tester, find.text('Tổng thể'));

      expect(
        find.bySemanticsLabel(
          RegExp(r'^Lịch 20 tuần của Ôn bài Tư Duy Tính Toán: hoàn thành \d+ ngày$'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Màn chi tiết: số liệu, biểu đồ sức mạnh, hành trình, lịch 16 tuần, ghi chú', (
      tester,
    ) async {
      await _seedSampleData();
      await _pump(tester);
      await _openHabitsTab(tester);
      await tester.longPress(_todayCard('Ôn bài Tư Duy Tính Toán'));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Xem chi tiết'));

      expect(
        find.text('Sau khi ăn tối, tôi sẽ ôn bài Tư Duy Tính Toán 25 phút tại bàn học.'),
        findsOne,
      );
      expect(find.text('Bản 2 phút: Đọc lại 1 trang ghi chú'), findsOneWidget);
      expect(find.text('Tôi là người học đều mỗi ngày, không học dồn'), findsOneWidget);
      expect(find.bySemanticsLabel('Chuỗi hiện tại: 5 ngày'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Dài nhất: \d+ ngày$')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Tỉ lệ 30 ngày: \d+%$')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Lần hoàn thành: \d+$')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Sức mạnh: \d+%$')), findsOneWidget);
      // Lịch tháng: hôm qua (4/3) "Ôn bài" đã xong.
      expect(find.bySemanticsLabel('4/3: đã xong'), findsOneWidget);
      await tester.scrollUntilVisible(find.byType(LineChart), 200, scrollable: _pageScroll);
      expect(find.byType(LineChart), findsOneWidget);

      // Đủ 66 ngày nên có đủ 4 huy hiệu.
      await tester.scrollUntilVisible(
        find.text('66/66 ngày hoàn thành'),
        200,
        scrollable: _pageScroll,
      );
      await tester.scrollUntilVisible(find.text('Thành thói quen'), 100, scrollable: _pageScroll);
      expect(find.bySemanticsLabel('Huy hiệu Thành thói quen, 66 ngày, đã đạt'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Ôn xong chương 4, mai làm đề.'),
        200,
        scrollable: _pageScroll,
      );
      expect(find.bySemanticsLabel(RegExp(r'^Lịch 16 tuần: hoàn thành')), findsOneWidget);
      expect(find.text('Mệt nên chỉ đọc lại ghi chú.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Xoá thói quen ở màn chi tiết thì quay về danh sách', (tester) async {
      await _seedSampleData();
      await _pump(tester);
      await _openHabitsTab(tester);
      await _tap(tester, find.text('Tuần'));
      await _tap(tester, find.text('Đọc sách 10 trang'));

      await _tap(tester, find.byTooltip('Xoá thói quen'));
      expect(find.text('Xoá thói quen này?'), findsOneWidget);
      await _tap(tester, find.text('Xoá nhưng giữ lịch sử'));

      expect(find.text('Đọc sách 10 trang'), findsNothing);
      expect(find.text('Tuần'), findsOneWidget);
      expect(HabitRepository().getById(MockData.readingHabit.id)?.archived, isTrue);
      // Lịch sử vẫn còn để Thống kê tính.
      expect(
        HabitLogRepository().getAll().where((log) => log.habitId == MockData.readingHabit.id),
        isNotEmpty,
      );
    });

    testWidgets('Mọi chế độ và màn chi tiết hiện được ở chế độ tối, không tràn giao diện', (
      tester,
    ) async {
      await _seedSampleData();
      await _pump(tester, brightness: Brightness.dark);
      await _openHabitsTab(tester);
      expect(tester.takeException(), isNull);

      for (final view in ['Tuần', 'Tổng thể', 'Hôm nay']) {
        await _tap(tester, find.text(view));
        expect(tester.takeException(), isNull, reason: view);
      }
      await tester.longPress(_todayCard('Làm bài tập về nhà'));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Xem chi tiết'));
      await tester.scrollUntilVisible(find.text('Ghi chú'), 300, scrollable: _pageScroll);
      expect(tester.takeException(), isNull);
    });
  });
}
