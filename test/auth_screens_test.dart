// F3 Kiểm thử màn chào, đăng nhập, đăng ký nhiều bước và Hồ sơ.
// Không gọi Firebase thật: AuthService và SyncService được thay bằng bản giả (test_helpers.dart).
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/hive_boxes.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/services/auth_service.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';

import 'test_helpers.dart';

const String _guestLink = 'Dùng thử không cần tài khoản';

Future<void> _tap(WidgetTester tester, Finder finder) => tapAndSettle(tester, finder);

Finder _field(String label) => find.widgetWithText(TextField, label);

/// Nút chính đang bật hay đang khoá (mờ).
bool _enabled(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, label)).onPressed != null;

Future<void> _onboard() => ProfileRepository().completeOnboarding(
  const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
);

Future<FakeAuthService> _pumpWithServer(WidgetTester tester, {AuthUser? signedIn}) async {
  final auth = FakeAuthService(signedIn: signedIn);
  await pumpApp(tester, overrides: fakeAccountOverrides(auth));
  return auth;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(openMemoryBoxes);
  tearDown(() async => Hive.close());

  group('Màn chào', () {
    testWidgets('Mới cài, chưa đăng nhập, chưa dùng thử thì hiện màn chào', (tester) async {
      await pumpApp(tester);

      expect(find.text('DisGret'), findsOneWidget);
      expect(find.bySemanticsLabel('Logo DisGret'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Đăng nhập'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Tạo tài khoản mới'), findsOneWidget);
      expect(find.text(_guestLink), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Không có máy chủ: bấm Đăng nhập thì báo và gợi ý dùng thử', (tester) async {
      await pumpApp(tester); // Trong test Firebase không chạy, giống lúc mất mạng.

      await _tap(tester, find.widgetWithText(FilledButton, 'Đăng nhập'));

      expect(find.textContaining(AuthRules.noServer), findsOneWidget);
      expect(find.textContaining('dùng thử'), findsOneWidget);
      expect(find.text('Tên đăng nhập'), findsNothing, reason: 'Không mở màn đăng nhập');
    });

    testWidgets('Dùng thử: hỏi nhẹ rồi vào quiz động lực, lưu guestMode', (tester) async {
      await pumpApp(tester);

      await _tap(tester, find.text(_guestLink));
      expect(find.textContaining('Dữ liệu chỉ lưu trên máy này'), findsOneWidget);
      await _tap(tester, find.widgetWithText(TextButton, 'Huỷ'));
      expect(ProfileRepository().isGuestMode, isFalse);

      await _tap(tester, find.text(_guestLink));
      await _tap(tester, find.widgetWithText(TextButton, 'Tiếp tục'));

      expect(ProfileRepository().isGuestMode, isTrue);
      expect(find.text(_guestLink), findsNothing);
      // Onboarding cũ (giới thiệu → quiz) chạy sau khi chọn dùng thử.
      await _tap(tester, find.text('Tiếp tục'));
      expect(find.text('Câu 1/4'), findsOneWidget);
    });

    testWidgets('Người đã dùng app từ trước (đã qua onboarding) không bị đưa về màn chào', (
      tester,
    ) async {
      await _onboard();
      await pumpApp(tester);
      expect(find.text(_guestLink), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('Đăng nhập', () {
    testWidgets('Nút Đăng nhập bị khoá khi ô trống; sai mật khẩu thì báo đỏ ngay dưới ô', (
      tester,
    ) async {
      final auth = await _pumpWithServer(tester);
      await _tap(tester, find.widgetWithText(FilledButton, 'Đăng nhập'));
      expect(find.text('Tên đăng nhập'), findsOneWidget);

      expect(_enabled(tester, 'Đăng nhập'), isFalse);
      await tester.enterText(_field('Tên đăng nhập'), 'Khang');
      await tester.pump();
      expect(_enabled(tester, 'Đăng nhập'), isFalse, reason: 'Còn thiếu mật khẩu');
      // Ô tên tự chuyển chữ thường.
      expect(find.text('khang'), findsOneWidget);

      await tester.enterText(_field('Mật khẩu'), FakeAuthService.wrongPassword);
      await tester.pump();
      expect(_enabled(tester, 'Đăng nhập'), isTrue);

      await _tap(tester, find.widgetWithText(FilledButton, 'Đăng nhập'));
      final error = tester.widget<Text>(find.text('Sai tên đăng nhập hoặc mật khẩu'));
      final context = tester.element(find.text('Sai tên đăng nhập hoặc mật khẩu'));
      expect(error.style?.color, Theme.of(context).colorScheme.error);
      expect(find.byType(AlertDialog), findsNothing, reason: 'Không dùng hộp thoại');
      expect(auth.calls, ['signIn:khang']);
    });

    testWidgets('Mật khẩu có nút ẩn/hiện', (tester) async {
      await _pumpWithServer(tester);
      await _tap(tester, find.widgetWithText(FilledButton, 'Đăng nhập'));

      TextField password() => tester.widget<TextField>(_field('Mật khẩu'));
      expect(password().obscureText, isTrue);
      await _tap(tester, find.byTooltip('Hiện mật khẩu'));
      expect(password().obscureText, isFalse);
    });

    testWidgets('Quên mật khẩu mở bottom sheet giải thích', (tester) async {
      await _pumpWithServer(tester);
      await _tap(tester, find.widgetWithText(FilledButton, 'Đăng nhập'));
      await _tap(tester, find.text('Quên mật khẩu?'));
      expect(find.textContaining('liên hệ nhóm phát triển'), findsOneWidget);
    });

    testWidgets('Đăng nhập tài khoản đã làm quiz thì vào thẳng Trang chủ, bỏ qua onboarding', (
      tester,
    ) async {
      // Giả lập dữ liệu vừa tải từ mây về: đã có hồ sơ quiz và một mục tiêu.
      await ProfileRepository().saveProfile(
        const UserProfile(motivationTypes: [MotivationType.family], preferredReelLength: 30),
      );
      await GoalRepository().save(const Goal(id: 'g1', title: 'Học tiếng Anh', reason: 'R'));
      await _pumpWithServer(tester);

      await _tap(tester, find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.enterText(_field('Tên đăng nhập'), 'khang');
      await tester.enterText(_field('Mật khẩu'), '123456');
      await tester.pump();
      await _tap(tester, find.widgetWithText(FilledButton, 'Đăng nhập'));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Học tiếng Anh'), findsOneWidget);
      expect(ProfileRepository().isOnboardingDone, isTrue);
    });

    testWidgets('"Chưa có tài khoản? Đăng ký" chuyển sang màn đăng ký', (tester) async {
      await _pumpWithServer(tester);
      await _tap(tester, find.widgetWithText(FilledButton, 'Đăng nhập'));
      await _tap(tester, find.widgetWithText(TextButton, 'Đăng ký'));
      expect(find.text('Chọn tên đăng nhập'), findsOneWidget);
    });
  });

  group('Đăng ký nhiều bước', () {
    Future<void> openSignup(WidgetTester tester) async {
      await _pumpWithServer(tester);
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Tạo tài khoản mới'));
    }

    Future<void> typeUsername(WidgetTester tester, String name) async {
      await tester.enterText(_field('Tên đăng nhập'), name);
      await tester.pump();
    }

    testWidgets('Bước 1 kiểm tra tên ngay khi gõ: lỗi đỏ, hoặc tick khi hợp lệ', (tester) async {
      await openSignup(tester);
      expect(find.text('Chọn tên đăng nhập'), findsOneWidget);
      expect(find.text('@'), findsOneWidget, reason: 'Ô nhập có tiền tố @');
      expect(_enabled(tester, 'Tiếp'), isFalse);

      await typeUsername(tester, 'ab');
      expect(find.text('Tên đăng nhập dài 3–20 ký tự'), findsOneWidget);
      expect(_enabled(tester, 'Tiếp'), isFalse);

      await typeUsername(tester, 'khang!');
      expect(
        find.text('Tên đăng nhập chỉ gồm chữ a–z không dấu, số, dấu _ và dấu .'),
        findsOneWidget,
      );

      await typeUsername(tester, 'a' * 21);
      expect(find.text('Tên đăng nhập dài 3–20 ký tự'), findsOneWidget);

      await typeUsername(tester, 'Khang Tran_07');
      expect(find.text('khangtran_07'), findsOneWidget, reason: 'Chữ thường, bỏ khoảng trắng');
      expect(find.bySemanticsLabel('Tên hợp lệ'), findsOneWidget);
      expect(find.text('Tên đăng nhập dài 3–20 ký tự'), findsNothing);
      expect(_enabled(tester, 'Tiếp'), isTrue);
    });

    testWidgets('Bước 2: điều kiện tick dần, nhập lại phải khớp; quay lại về bước 1', (
      tester,
    ) async {
      await openSignup(tester);
      await typeUsername(tester, 'khang');
      await _tap(tester, find.widgetWithText(FilledButton, 'Tiếp'));
      expect(find.text('Tạo mật khẩu'), findsOneWidget);
      expect(find.text('Hãy nhớ kỹ mật khẩu, app chưa hỗ trợ lấy lại mật khẩu.'), findsOneWidget);
      expect(_enabled(tester, 'Tạo tài khoản'), isFalse);

      await tester.enterText(_field('Mật khẩu'), 'abc123');
      await tester.enterText(_field('Nhập lại mật khẩu'), 'abc124');
      await tester.pump();
      expect(find.text('Mật khẩu nhập lại không khớp'), findsOneWidget);
      expect(_enabled(tester, 'Tạo tài khoản'), isFalse);

      await tester.enterText(_field('Nhập lại mật khẩu'), 'abc123');
      await tester.pump();
      expect(find.text('Mật khẩu nhập lại không khớp'), findsNothing);
      expect(_enabled(tester, 'Tạo tài khoản'), isTrue);

      await _tap(tester, find.byTooltip('Quay lại'));
      expect(find.text('Chọn tên đăng nhập'), findsOneWidget);
      expect(find.text('khang'), findsOneWidget, reason: 'Giữ tên đã nhập');
    });

    testWidgets('Tên đã có người dùng: quay về bước 1 và báo lỗi dưới ô tên', (tester) async {
      await openSignup(tester);
      await typeUsername(tester, FakeAuthService.takenName);
      await _tap(tester, find.widgetWithText(FilledButton, 'Tiếp'));
      await tester.enterText(_field('Mật khẩu'), '123456');
      await tester.enterText(_field('Nhập lại mật khẩu'), '123456');
      await tester.pump();
      await _tap(tester, find.widgetWithText(FilledButton, 'Tạo tài khoản'));

      expect(find.text('Chọn tên đăng nhập'), findsOneWidget);
      expect(find.text('Tên đăng nhập đã có người dùng'), findsOneWidget);
      expect(_enabled(tester, 'Tiếp'), isFalse);
    });

    testWidgets('Tạo tài khoản xong: "Chào mừng @ten!" → Bắt đầu → quiz động lực', (tester) async {
      await openSignup(tester);
      await typeUsername(tester, 'khang');
      await _tap(tester, find.widgetWithText(FilledButton, 'Tiếp'));
      await tester.enterText(_field('Mật khẩu'), '123456');
      await tester.enterText(_field('Nhập lại mật khẩu'), '123456');
      await tester.pump();
      await _tap(tester, find.widgetWithText(FilledButton, 'Tạo tài khoản'));

      expect(find.text('Chào mừng @khang!'), findsOneWidget);
      expect(find.text('K'), findsOneWidget, reason: 'Avatar chữ cái lớn');
      expect(find.byTooltip('Quay lại'), findsNothing);

      await _tap(tester, find.widgetWithText(FilledButton, 'Bắt đầu'));
      await _tap(tester, find.text('Tiếp tục'));
      expect(find.text('Câu 1/4'), findsOneWidget);
    });

    testWidgets('Đang dùng thử có dữ liệu thì đăng ký xong báo đã lưu vào tài khoản', (
      tester,
    ) async {
      await _onboard();
      await ProfileRepository().setGuestMode(true);
      await GoalRepository().save(const Goal(id: 'g1', title: 'A', reason: 'B'));
      await _pumpWithServer(tester);

      await _tap(tester, find.byTooltip('Hồ sơ'));
      expect(find.text('Bạn đang dùng thử'), findsOneWidget);
      await _tap(tester, find.widgetWithText(FilledButton, 'Tạo tài khoản'));
      await typeUsername(tester, 'khang');
      await _tap(tester, find.widgetWithText(FilledButton, 'Tiếp'));
      await tester.enterText(_field('Mật khẩu'), '123456');
      await tester.enterText(_field('Nhập lại mật khẩu'), '123456');
      await tester.pump();
      await _tap(tester, find.widgetWithText(FilledButton, 'Tạo tài khoản'));

      expect(find.text('Đã lưu dữ liệu của bạn vào tài khoản'), findsOneWidget);
      await _tap(tester, find.widgetWithText(FilledButton, 'Bắt đầu'));
      // Đã làm quiz khi dùng thử nên vào thẳng Trang chủ.
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('Hồ sơ', () {
    const user = AuthUser(uid: 'u1', username: 'khang');

    testWidgets('Đã đăng nhập: @tên, 3 số liệu, trạng thái đồng bộ; đăng xuất về màn chào', (
      tester,
    ) async {
      await _onboard();
      final auth = await _pumpWithServer(tester, signedIn: user);

      await _tap(tester, find.byTooltip('Hồ sơ'));
      expect(find.text('@khang'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Streak dài nhất: \d+$')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Phiên tập trung: \d+$')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Thói quen: \d+$')), findsOneWidget);
      expect(find.text('Đồng bộ ngay'), findsOneWidget);

      await _tap(tester, find.text('Đăng xuất'));
      expect(
        find.text('Dữ liệu trên máy này sẽ được xoá, dữ liệu vẫn còn trong tài khoản.'),
        findsOneWidget,
      );
      await _tap(tester, find.widgetWithText(TextButton, 'Đăng xuất'));

      expect(auth.calls, contains('signOut'));
      expect(find.text(_guestLink), findsOneWidget);
      expect(ProfileRepository().isOnboardingDone, isFalse);
      expect(Hive.box<dynamic>(HiveBoxes.device).isEmpty, isTrue);
    });

    testWidgets('Dùng thử: avatar xám, kêu gọi tạo tài khoản, không có chấm đồng bộ', (
      tester,
    ) async {
      await _onboard();
      await ProfileRepository().setGuestMode(true);
      await _pumpWithServer(tester);

      expect(find.byIcon(AppIcons.offline), findsNothing);
      expect(find.byIcon(AppIcons.synced), findsNothing);
      await _tap(tester, find.byTooltip('Hồ sơ'));
      expect(find.text('Bạn đang dùng thử'), findsOneWidget);
      expect(find.text('Tạo tài khoản để lưu dữ liệu và dùng trên nhiều thiết bị'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsNothing);

      await _tap(tester, find.text('Cài đặt'));
      expect(find.text('Tài khoản'), findsOneWidget);
    });
  });

  group('Màn hẹp, sáng và tối', () {
    for (final brightness in Brightness.values) {
      testWidgets('Không tràn giao diện ở chế độ ${brightness.name}', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await _onboard();
        await _pumpWithServer(
          tester,
          signedIn: const AuthUser(uid: 'u1', username: 'khang'),
        );
        await _tap(tester, find.byTooltip('Hồ sơ'));
        expect(tester.takeException(), isNull);

        // Đăng xuất để xem màn chào, đăng nhập, đăng ký trên màn hẹp.
        await _tap(tester, find.text('Đăng xuất'));
        await _tap(tester, find.widgetWithText(TextButton, 'Đăng xuất'));
        expect(tester.takeException(), isNull);
        await _tap(tester, find.widgetWithText(FilledButton, 'Đăng nhập'));
        expect(tester.takeException(), isNull);
        await _tap(tester, find.widgetWithText(TextButton, 'Đăng ký'));
        await tester.enterText(_field('Tên đăng nhập'), 'khang');
        await tester.pump();
        await _tap(tester, find.widgetWithText(FilledButton, 'Tiếp'));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
