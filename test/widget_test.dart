// Kiểm thử giao diện: onboarding, Trang chủ, màn Thói quen, Cài đặt và vòng chính.
import 'package:flutter_test/flutter_test.dart';
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
import 'package:focus_app/widgets/gradient_progress_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const Goal _goal = Goal(id: 'g1', title: 'Đạt điểm A', reason: 'Để xin thực tập');
const Habit _habit = Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 25);

Future<void> _pumpApp(WidgetTester tester, {Size size = smallPhone}) => pumpApp(tester, size: size);

Future<void> _tap(WidgetTester tester, Finder finder) => tapAndSettle(tester, finder);

/// Bấm một mục trong màn Cài đặt: danh sách dài nên trên màn nhỏ phải cuộn tới trước.
Future<void> _tapSettingsItem(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(find.text(label), 200);
  await _tap(tester, find.text(label));
}

Future<void> _enterField(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.widgetWithText(TextFormField, label), text);
  await tester.pump();
}

/// Trả lời đủ 4 câu quiz: 2 câu "sự nghiệp", 2 câu "chứng minh bản thân".
Future<void> _answerQuiz(WidgetTester tester) async {
  await _tap(tester, find.text('Có công việc mình thật sự muốn làm'));
  await _tap(tester, find.text('Đang ở đúng vị trí mình mơ ước'));
  await _tap(tester, find.text('Không muốn thua chính mình'));
  await _tap(tester, find.text('Niềm tin rằng mình làm được'));
}

Future<void> _completeOnboarding() => ProfileRepository().completeOnboarding(
  const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
);

/// Người dùng đã qua onboarding, có sẵn 1 mục tiêu và 1 thói quen.
Future<void> _seedGoalAndHabit() async {
  await _completeOnboarding();
  await GoalRepository().save(_goal);
  await HabitRepository().save(_habit);
}

Future<void> _addFocusLog(int minutes) => HabitLogRepository().save(
  HabitLog(
    id: 'focus_test',
    habitId: _habit.id,
    date: DateTime.now(),
    source: HabitLogSource.focus,
    minutes: minutes,
  ),
);

void main() {
  setUpAll(() {
    // Môi trường test không có mạng nên không tải font.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    await openMemoryBoxes();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  });

  tearDown(() async {
    await Hive.close();
  });

  group('Onboarding', () {
    testWidgets('Lần đầu mở app: giới thiệu, quiz 4 câu, nhập mục tiêu rồi vào Trang chủ', (
      tester,
    ) async {
      await _pumpApp(tester);

      expect(find.text('DisGret'), findsOneWidget);
      expect(find.bySemanticsLabel('Logo DisGret'), findsOneWidget);
      expect(find.text('Bắt đầu'), findsNothing);

      await _tap(tester, find.text('Tiếp tục'));
      expect(find.text('Câu 1/4'), findsOneWidget);
      expect(find.text('Điều gì khiến bạn muốn cố gắng nhất?'), findsOneWidget);

      await _answerQuiz(tester);
      expect(find.text('Mục tiêu đầu tiên của bạn'), findsOneWidget);

      // Để trống thì báo lỗi và chưa lưu gì.
      await _tap(tester, find.text('Vào DisGret'));
      expect(find.text('Hãy đặt tên cho mục tiêu'), findsOneWidget);
      expect(find.text('Hãy ghi lại lý do của bạn'), findsOneWidget);
      expect(find.text('Hãy đặt tên cho thói quen'), findsOneWidget);
      expect(GoalRepository().getAll(), isEmpty);
      expect(ProfileRepository().isOnboardingDone, isFalse);

      await _enterField(tester, 'Tên mục tiêu', 'Qua môn Toán');
      await _enterField(tester, 'Vì sao bạn muốn điều này?', 'Để ra trường đúng hạn');
      await _enterField(tester, 'Tên thói quen', 'Làm đề');
      await _tap(tester, find.text('15 phút'));
      await _tap(tester, find.text('Vào DisGret'));

      expect(find.text('Bắt đầu'), findsOneWidget);
      expect(find.text('Qua môn Toán'), findsOneWidget);
      expect(find.text('Để ra trường đúng hạn'), findsOneWidget);
      expect(find.text('Làm đề'), findsOneWidget);
      expect(find.text('0/15 phút hôm nay'), findsOneWidget);

      // Đã lưu thật xuống Hive, động lực là 2 loại điểm cao nhất của quiz.
      expect(GoalRepository().getAll().single.title, 'Qua môn Toán');
      expect(HabitRepository().getAll().single.minMinutesPerDay, 15);
      expect(ProfileRepository().profile?.motivationTypes, [
        MotivationType.career,
        MotivationType.proveYourself,
      ]);
      expect(ProfileRepository().isOnboardingDone, isTrue);
    });

    testWidgets('Quay lại câu trước thấy đáp án đã chọn, đổi đáp án thì tính theo đáp án mới', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tap(tester, find.text('Tiếp tục'));
      await _tap(tester, find.text('Có thu nhập tốt, không phải lo chuyện tiền'));
      expect(find.text('Câu 2/4'), findsOneWidget);

      await _tap(tester, find.text('Quay lại'));
      expect(find.text('Câu 1/4'), findsOneWidget);
      expect(find.byIcon(AppIcons.check), findsOneWidget);

      await _tap(tester, find.text('Được tự quyết định cuộc sống của mình'));
      await _tap(tester, find.text('Làm việc ở đâu, lúc nào là do mình chọn'));
      await _tap(tester, find.text('Không muốn cả đời làm theo ý người khác'));
      await _tap(tester, find.text('Nhiều lựa chọn hơn cho tương lai'));

      await _enterField(tester, 'Tên mục tiêu', 'A');
      await _enterField(tester, 'Vì sao bạn muốn điều này?', 'B');
      await _enterField(tester, 'Tên thói quen', 'C');
      await _tap(tester, find.text('Vào DisGret'));

      expect(ProfileRepository().profile?.motivationTypes, [MotivationType.freedom]);
    });

    testWidgets('Ở bước cuối, nút Back quay lại câu quiz trước và giữ nguyên chữ đã nhập', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tap(tester, find.text('Tiếp tục'));
      await _answerQuiz(tester);
      await _enterField(tester, 'Tên mục tiêu', 'Giữ lại');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Câu 4/4'), findsOneWidget);

      await _tap(tester, find.text('Niềm tin rằng mình làm được'));
      expect(find.text('Giữ lại'), findsOneWidget);
    });

    testWidgets('Xem lại onboarding khi đã có mục tiêu thì không hỏi lại và không tạo trùng', (
      tester,
    ) async {
      await _seedGoalAndHabit();
      await _pumpApp(tester);

      await _tap(tester, find.byTooltip('Cài đặt'));
      await _tapSettingsItem(tester, 'Xem lại màn giới thiệu');
      await _tap(tester, find.text('Tiếp tục'));
      await _answerQuiz(tester);

      expect(find.text('Bắt đầu'), findsOneWidget);
      expect(GoalRepository().getAll(), hasLength(1));
      expect(ProfileRepository().profile?.motivationTypes, [
        MotivationType.career,
        MotivationType.proveYourself,
      ]);
    });
  });

  group('Làm lại quiz động lực', () {
    testWidgets('Mở từ Cài đặt, làm xong thì hồ sơ đổi ngay và giữ độ dài reel', (tester) async {
      await ProfileRepository().completeOnboarding(
        const UserProfile(motivationTypes: [MotivationType.money], preferredReelLength: 60),
      );
      await _pumpApp(tester);
      await _tap(tester, find.byTooltip('Cài đặt'));
      expect(find.widgetWithText(Chip, 'Tiền bạc'), findsOneWidget);

      await _tap(tester, find.text('Làm lại quiz động lực'));
      expect(find.text('Câu 1/4'), findsOneWidget);
      await _answerQuiz(tester);

      expect(find.text('Cài đặt'), findsOneWidget);
      // Hàng chip nằm đầu danh sách, có thể đã bị cuộn khỏi màn lúc bấm nút làm lại quiz.
      await tester.scrollUntilVisible(find.widgetWithText(Chip, 'Sự nghiệp'), -200);
      expect(find.widgetWithText(Chip, 'Tiền bạc'), findsNothing);
      expect(find.widgetWithText(Chip, 'Sự nghiệp'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Chứng minh bản thân'), findsOneWidget);
      expect(find.text('Động lực chính của bạn: Sự nghiệp, Chứng minh bản thân'), findsOneWidget);

      final saved = ProfileRepository().profile;
      expect(saved?.motivationTypes, [MotivationType.career, MotivationType.proveYourself]);
      expect(saved?.preferredReelLength, 60);
    });

    testWidgets('Nút quay lại về câu trước; ở câu đầu thì thoát và không đổi hồ sơ', (
      tester,
    ) async {
      await ProfileRepository().completeOnboarding(
        const UserProfile(motivationTypes: [MotivationType.money], preferredReelLength: 30),
      );
      await _pumpApp(tester);
      await _tap(tester, find.byTooltip('Cài đặt'));
      await _tap(tester, find.text('Làm lại quiz động lực'));
      await _tap(tester, find.text('Có công việc mình thật sự muốn làm'));
      expect(find.text('Câu 2/4'), findsOneWidget);

      await _tap(tester, find.byTooltip('Quay lại'));
      expect(find.text('Câu 1/4'), findsOneWidget);

      await _tap(tester, find.byTooltip('Quay lại'));
      expect(find.text('Cài đặt'), findsOneWidget);
      expect(ProfileRepository().profile?.motivationTypes, [MotivationType.money]);
    });
  });

  group('Trang chủ', () {
    testWidgets('Chưa có mục tiêu: hiện màn trống, tạo xong mục tiêu và thói quen thì đổi ngay', (
      tester,
    ) async {
      await _completeOnboarding();
      await _pumpApp(tester);

      expect(find.text('Chưa có mục tiêu nào'), findsOneWidget);
      expect(find.text('Bắt đầu'), findsNothing);

      await _tap(tester, find.text('Tạo mục tiêu đầu tiên'));
      await _enterField(tester, 'Tên mục tiêu', 'Mục tiêu mới tạo');
      await _enterField(tester, 'Vì sao bạn muốn điều này?', 'Vì thích');
      await _tap(tester, find.text('Lưu'));

      expect(find.text('Chưa có mục tiêu nào'), findsNothing);
      expect(find.text('Mục tiêu mới tạo'), findsOneWidget);
      expect(find.text('Bắt đầu'), findsOneWidget);
      expect(find.text('Chưa có thói quen nào.'), findsOneWidget);

      await _tap(tester, find.text('Thêm thói quen'));
      await _enterField(tester, 'Tên thói quen', 'Thói quen mới tạo');
      await _tap(tester, find.text('Lưu'));

      expect(find.text('Thói quen mới tạo'), findsOneWidget);
      expect(find.text('0/25 phút hôm nay'), findsOneWidget);
    });

    testWidgets('Các lần sau vào thẳng Trang chủ với dữ liệu thật', (tester) async {
      await _seedGoalAndHabit();
      await _pumpApp(tester);

      expect(find.text('Tiếp tục'), findsNothing);
      expect(find.text('DisGret'), findsOneWidget);
      expect(find.bySemanticsLabel('Logo DisGret'), findsOneWidget);
      expect(find.bySemanticsLabel('Chuỗi 0 ngày học liên tiếp'), findsOneWidget);
      expect(find.text('Đạt điểm A'), findsOneWidget);
      expect(find.text('Ôn bài'), findsOneWidget);
      expect(find.text('Bắt đầu'), findsOneWidget);
    });

    testWidgets('Thanh tiến độ tô đúng tỉ lệ và nhìn thấy được', (tester) async {
      await _seedGoalAndHabit();
      await _addFocusLog(10);
      await _pumpApp(tester);

      final bar = find.byType(GradientProgressBar);
      final fill = find.descendant(of: bar, matching: find.byType(DecoratedBox));

      // Đã học 10/25 phút nên phần tô phải dài 40% và cao bằng cả thanh.
      expect(find.text('10/25 phút hôm nay'), findsOneWidget);
      expect(tester.getSize(fill).width, closeTo(tester.getSize(bar).width * 0.4, 0.01));
      expect(tester.getSize(fill).height, tester.getSize(bar).height);
      expect(tester.getSize(fill).height, greaterThan(0));
    });
  });

  group('Tick "Hôm nay đã làm"', () {
    testWidgets('Tick ở Trang chủ thì mọi màn cập nhật ngay; bỏ tick ở màn khác cũng vậy', (
      tester,
    ) async {
      await _seedGoalAndHabit();
      await _pumpApp(tester);
      expect(find.text('0/25 phút hôm nay'), findsOneWidget);

      await _tap(tester, find.byType(Checkbox));

      expect(find.text('25/25 phút hôm nay'), findsOneWidget);
      expect(find.bySemanticsLabel('Chuỗi 1 ngày học liên tiếp'), findsOneWidget);
      expect(find.bySemanticsLabel('Chuỗi 1 ngày'), findsOneWidget);
      final log = HabitLogRepository().getAll().single;
      expect(log.source, HabitLogSource.manual);
      expect(log.minutes, 25);

      // Sang tab Thói quen thấy đã tick, bỏ tick tại đó.
      await _tap(tester, find.text('Thói quen'));
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      await _tap(tester, find.byType(Checkbox));
      expect(HabitLogRepository().getAll(), isEmpty);

      // Về Trang chủ thấy đã bỏ tick.
      await _tap(tester, find.text('Trang chủ'));
      expect(find.text('0/25 phút hôm nay'), findsOneWidget);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      expect(find.bySemanticsLabel('Chuỗi 0 ngày học liên tiếp'), findsOneWidget);
    });

    testWidgets('Sau khi tick cho thêm ghi chú, không bắt buộc, sửa lại được', (tester) async {
      await _seedGoalAndHabit();
      await _pumpApp(tester);
      expect(find.text('Thêm ghi chú'), findsNothing);

      await _tap(tester, find.byType(Checkbox));

      // Bỏ qua thì không có ghi chú nào được lưu.
      await _tap(tester, find.text('Thêm ghi chú'));
      await _tap(tester, find.text('Bỏ qua'));
      expect(HabitLogRepository().getAll().single.note, '');

      await _tap(tester, find.text('Thêm ghi chú'));
      await tester.enterText(find.byType(TextField), 'Làm xong chương 3');
      await _tap(tester, find.text('Lưu'));
      expect(find.text('Làm xong chương 3'), findsOneWidget);
      expect(HabitLogRepository().getAll().single.note, 'Làm xong chương 3');

      // Bỏ tick thì ghi chú biến mất cùng log.
      await _tap(tester, find.byType(Checkbox));
      expect(find.text('Làm xong chương 3'), findsNothing);
    });

    testWidgets('Đủ phút từ phiên Focus: ô tick khoá lại để không xoá nhầm phút học thật', (
      tester,
    ) async {
      await _seedGoalAndHabit();
      await _addFocusLog(25);
      await _pumpApp(tester);

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
      expect(checkbox.onChanged, isNull);
      expect(find.text('Đã đủ phút từ phiên Focus'), findsOneWidget);
      expect(find.text('25/25 phút hôm nay'), findsOneWidget);
      expect(find.bySemanticsLabel('Chuỗi 1 ngày học liên tiếp'), findsOneWidget);
    });

    testWidgets('Focus chưa đủ phút: vẫn tick tay được, bỏ tick thì phút học vẫn còn', (
      tester,
    ) async {
      await _seedGoalAndHabit();
      await _addFocusLog(10);
      await _pumpApp(tester);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

      await _tap(tester, find.byType(Checkbox));
      expect(find.text('25/25 phút hôm nay'), findsOneWidget);

      await _tap(tester, find.byType(Checkbox));
      expect(find.text('10/25 phút hôm nay'), findsOneWidget);
      expect(HabitLogRepository().getAll().single.source, HabitLogSource.focus);
    });
  });

  group('Màn Thói quen', () {
    Future<void> openHabits(WidgetTester tester) async {
      await _pumpApp(tester);
      await _tap(tester, find.text('Thói quen'));
    }

    testWidgets('Nút + tạo mục tiêu; bỏ trống thì báo lỗi', (tester) async {
      await _completeOnboarding();
      await openHabits(tester);
      expect(find.text('Chưa có mục tiêu nào'), findsOneWidget);

      await _tap(tester, find.byTooltip('Thêm mục tiêu'));
      expect(find.text('Mục tiêu mới'), findsOneWidget);
      await _tap(tester, find.text('Lưu'));
      expect(find.text('Hãy đặt tên cho mục tiêu'), findsOneWidget);
      expect(GoalRepository().getAll(), isEmpty);

      await _enterField(tester, 'Tên mục tiêu', 'Mục tiêu A');
      await _enterField(tester, 'Vì sao bạn muốn điều này?', 'Lý do A');
      await _tap(tester, find.text('Lưu'));

      expect(find.text('Mục tiêu A'), findsOneWidget);
      expect(find.text('Lý do A'), findsOneWidget);
      expect(GoalRepository().getAll().single.reason, 'Lý do A');
    });

    testWidgets('Dòng báo lỗi biến mất ngay khi nhập lại, không cần bấm Lưu lần nữa', (
      tester,
    ) async {
      await _completeOnboarding();
      await openHabits(tester);
      await _tap(tester, find.byTooltip('Thêm mục tiêu'));
      await _tap(tester, find.text('Lưu'));
      expect(find.text('Hãy đặt tên cho mục tiêu'), findsOneWidget);
      expect(find.text('Hãy ghi lại lý do của bạn'), findsOneWidget);

      await _enterField(tester, 'Tên mục tiêu', 'Đã nhập');
      await tester.pumpAndSettle();

      // Ô vừa nhập hết lỗi, ô chưa nhập vẫn giữ lỗi.
      expect(find.text('Hãy đặt tên cho mục tiêu'), findsNothing);
      expect(find.text('Hãy ghi lại lý do của bạn'), findsOneWidget);
    });

    testWidgets('Sửa mục tiêu hiện sẵn dữ liệu cũ và cập nhật cả Trang chủ', (tester) async {
      await _seedGoalAndHabit();
      await openHabits(tester);

      await _tap(tester, find.byTooltip('Tuỳ chọn mục tiêu'));
      await _tap(tester, find.text('Sửa'));
      expect(find.text('Sửa mục tiêu'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Đạt điểm A'), findsOneWidget);

      await _enterField(tester, 'Đạt điểm A', 'Đạt điểm A+');
      await _tap(tester, find.text('Lưu'));
      expect(find.text('Đạt điểm A+'), findsOneWidget);

      await _tap(tester, find.text('Trang chủ'));
      expect(find.text('Đạt điểm A+'), findsOneWidget);
    });

    testWidgets('Xoá mục tiêu: Huỷ thì giữ, xác nhận thì xoá cả thói quen, về màn trống', (
      tester,
    ) async {
      await _seedGoalAndHabit();
      await openHabits(tester);

      await _tap(tester, find.byTooltip('Tuỳ chọn mục tiêu'));
      await _tap(tester, find.text('Xoá'));
      expect(find.text('Xoá mục tiêu?'), findsOneWidget);
      await _tap(tester, find.text('Huỷ'));
      expect(find.text('Đạt điểm A'), findsOneWidget);
      expect(GoalRepository().getAll(), hasLength(1));

      await _tap(tester, find.byTooltip('Tuỳ chọn mục tiêu'));
      await _tap(tester, find.text('Xoá'));
      await _tap(tester, find.text('Xoá'));

      expect(find.text('Chưa có mục tiêu nào'), findsOneWidget);
      expect(GoalRepository().getAll(), isEmpty);
      expect(HabitRepository().getAll(), isEmpty);

      await _tap(tester, find.text('Trang chủ'));
      expect(find.text('Tạo mục tiêu đầu tiên'), findsOneWidget);
    });

    testWidgets('Thêm thói quen bằng mức nhanh', (tester) async {
      await _completeOnboarding();
      await GoalRepository().save(_goal);
      await openHabits(tester);

      await _tap(tester, find.text('Thêm thói quen'));
      await _enterField(tester, 'Tên thói quen', 'Đọc sách');
      await _tap(tester, find.text('45 phút'));
      await _tap(tester, find.text('Lưu'));

      expect(find.text('Đọc sách'), findsOneWidget);
      expect(find.text('0/45 phút hôm nay'), findsOneWidget);
      expect(HabitRepository().getAll().single.goalId, _goal.id);
    });

    testWidgets('Tự nhập số phút: chặn giá trị sai, nhận giá trị đúng', (tester) async {
      await _completeOnboarding();
      await GoalRepository().save(_goal);
      await openHabits(tester);

      await _tap(tester, find.text('Thêm thói quen'));
      await _enterField(tester, 'Tên thói quen', 'Chạy bộ');
      await _tap(tester, find.text('Tự nhập'));

      for (final invalid in ['', '0', '1441']) {
        await _enterField(tester, 'Số phút', invalid);
        await _tap(tester, find.text('Lưu'));
        expect(find.text('Nhập số phút từ 1 đến 1440'), findsOneWidget, reason: 'nhập "$invalid"');
        expect(HabitRepository().getAll(), isEmpty);
      }

      await _enterField(tester, 'Số phút', '37');
      await _tap(tester, find.text('Lưu'));
      expect(HabitRepository().getAll().single.minMinutesPerDay, 37);
      expect(find.text('0/37 phút hôm nay'), findsOneWidget);
    });

    testWidgets('Sửa thói quen có số phút tự nhập thì mở sẵn ô tự nhập', (tester) async {
      await _completeOnboarding();
      await GoalRepository().save(_goal);
      await HabitRepository().save(
        const Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 37),
      );
      await openHabits(tester);

      await _tap(tester, find.byTooltip('Tuỳ chọn thói quen'));
      await _tap(tester, find.text('Sửa'));
      expect(find.text('Sửa thói quen'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '37'), findsOneWidget);

      await _tap(tester, find.text('15 phút'));
      await _tap(tester, find.text('Lưu'));
      expect(find.text('0/15 phút hôm nay'), findsOneWidget);
      expect(HabitRepository().getById('h1')?.minMinutesPerDay, 15);
    });

    testWidgets('Xoá thói quen có hỏi xác nhận và xoá luôn lịch sử', (tester) async {
      await _seedGoalAndHabit();
      await _addFocusLog(10);
      await openHabits(tester);

      await _tap(tester, find.byTooltip('Tuỳ chọn thói quen'));
      await _tap(tester, find.text('Xoá'));
      expect(find.text('Xoá thói quen?'), findsOneWidget);
      await _tap(tester, find.text('Xoá'));

      expect(find.text('Ôn bài'), findsNothing);
      expect(find.text('Đạt điểm A'), findsOneWidget);
      expect(HabitRepository().getAll(), isEmpty);
      expect(HabitLogRepository().getAll(), isEmpty);
    });

    testWidgets('Bottom sheet lấy bo góc và màu từ theme', (tester) async {
      await _completeOnboarding();
      await openHabits(tester);
      await _tap(tester, find.byTooltip('Thêm mục tiêu'));

      final context = tester.element(find.text('Mục tiêu mới'));
      final sheetTheme = Theme.of(context).bottomSheetTheme;
      expect((sheetTheme.shape! as RoundedRectangleBorder).borderRadius, AppRadius.sheetBorder);
      expect(sheetTheme.modalBackgroundColor, Theme.of(context).colorScheme.surface);
    });
  });

  group('Cài đặt', () {
    testWidgets('Tạo dữ liệu mẫu: Trang chủ hiện ngay mục tiêu, streak 5 và 2 thói quen', (
      tester,
    ) async {
      await _completeOnboarding();
      await _pumpApp(tester);
      expect(find.text('Tạo mục tiêu đầu tiên'), findsOneWidget);

      await _tap(tester, find.byTooltip('Cài đặt'));
      await _tapSettingsItem(tester, 'Tạo dữ liệu mẫu');
      expect(find.text('Đã tạo dữ liệu mẫu'), findsOneWidget);

      // Nút quay lại trên AppBar, nhãn của nó cũng phải là tiếng Việt.
      await _tap(tester, find.byTooltip('Quay lại'));

      expect(find.bySemanticsLabel('Chuỗi 5 ngày học liên tiếp'), findsOneWidget);
      expect(find.text('Đạt điểm A môn Tư Duy Tính Toán'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Làm bài tập về nhà'), 200);
      expect(find.text('10/30 phút hôm nay'), findsOneWidget);
    });

    testWidgets('Xoá toàn bộ dữ liệu: Huỷ thì giữ, xác nhận thì về onboarding như mới cài', (
      tester,
    ) async {
      await _seedGoalAndHabit();
      await _pumpApp(tester);
      await _tap(tester, find.byTooltip('Cài đặt'));

      await _tapSettingsItem(tester, 'Xoá toàn bộ dữ liệu');
      expect(find.text('Xoá toàn bộ dữ liệu?'), findsOneWidget);
      await _tap(tester, find.text('Huỷ'));
      expect(GoalRepository().getAll(), hasLength(1));

      await _tapSettingsItem(tester, 'Xoá toàn bộ dữ liệu');
      await _tap(tester, find.text('Xoá hết'));

      expect(find.text('Tiếp tục'), findsOneWidget);
      expect(GoalRepository().getAll(), isEmpty);
      expect(ProfileRepository().isOnboardingDone, isFalse);
    });
  });

  group('Khung app', () {
    testWidgets('Đi hết vòng chính: Bắt đầu → Reels → Focus 5 phút → Tổng kết → Trang chủ', (
      tester,
    ) async {
      await _seedGoalAndHabit();
      await _pumpApp(tester);

      await _tap(tester, find.text('Bắt đầu'));
      expect(find.text('Bắt đầu 5 phút'), findsOneWidget);

      await tester.tap(find.text('Bắt đầu 5 phút'));
      await tester.pumpAndSettle();
      expect(find.text('Kết thúc sớm'), findsOneWidget);
      expect(find.text('Ôn bài'), findsOneWidget);
      expect(find.text('05:00'), findsOneWidget);

      await _tap(tester, find.text('Kết thúc sớm'));
      await _tap(tester, find.text('Kết thúc'));
      expect(find.text('Tổng kết'), findsOneWidget);

      await _tap(tester, find.text('Về Trang chủ'));
      expect(find.text('Bắt đầu'), findsOneWidget);
    });

    testWidgets('Link "Bỏ qua, vào học luôn" mở thẳng Focus, không qua Reels', (tester) async {
      await _seedGoalAndHabit();
      await _pumpApp(tester);

      await _tap(tester, find.text('Bỏ qua, vào học luôn'));

      expect(find.text('Chỉ cần cam kết 5 phút đầu'), findsOneWidget);
      expect(find.text('Ôn bài'), findsOneWidget);
      expect((VideoPlayerPlatform.instance as FakeVideoPlayerPlatform).createdAssets, isEmpty);
    });

    testWidgets('Thanh dưới có đúng 4 tab và tab nào cũng mở được', (tester) async {
      await _seedGoalAndHabit();
      await _pumpApp(tester);

      expect(find.byType(NavigationDestination), findsNWidgets(4));

      await _tap(tester, find.text('Reels'));
      expect(find.text('Bắt đầu 5 phút'), findsOneWidget);

      // Vuốt dọc sang reel tiếp theo.
      expect(find.text('Bạn đủ thông minh để thay đổi'), findsOneWidget);
      await tester.fling(find.byType(PageView), const Offset(0, -400), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Làm nhiều hơn người khác'), findsOneWidget);

      await _tap(tester, find.text('Focus'));
      expect(find.text('Chỉ cần cam kết 5 phút đầu'), findsOneWidget);

      // Màn Focus cũng có ô chọn tên "Thói quen" nên phải chỉ rõ là bấm vào tab.
      await _tap(tester, find.widgetWithText(NavigationDestination, 'Thói quen'));
      expect(find.byTooltip('Thêm mục tiêu'), findsOneWidget);

      await _tap(tester, find.text('Trang chủ'));
      expect(find.text('Bắt đầu'), findsOneWidget);
    });

    testWidgets('Màn hình lấy đúng theme sáng/tối theo hệ thống', (tester) async {
      await _seedGoalAndHabit();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _pumpApp(tester);

      final context = tester.element(find.text('Bắt đầu'));
      expect(Theme.of(context).scaffoldBackgroundColor, const Color(0xFF07142F));
      expect(Theme.of(context).colorScheme.surfaceContainer, const Color(0xFF0F2350));
    });

    testWidgets('Tên rất dài trên màn hình nhỏ không gây tràn giao diện', (tester) async {
      await _completeOnboarding();
      await GoalRepository().save(Goal(id: 'g1', title: 'Mục tiêu ' * 8, reason: 'Lý do ' * 30));
      await HabitRepository().save(
        Habit(id: 'h1', goalId: 'g1', name: 'Thói quen ' * 6, minMinutesPerDay: 1440),
      );
      await _pumpApp(tester);

      // Trang chủ: thẻ mục tiêu rất dài đẩy ô tick xuống dưới nên phải cuộn tới.
      await tester.scrollUntilVisible(find.byType(Checkbox), 200);
      await _tap(tester, find.byType(Checkbox));
      expect(tester.takeException(), isNull);

      // Màn Thói quen có thêm menu Sửa/Xoá trên cùng một hàng.
      await _tap(tester, find.widgetWithText(NavigationDestination, 'Thói quen'));
      expect(find.byTooltip('Thêm mục tiêu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
