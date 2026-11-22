// 5.1, 4.2, 8.2 Kiểm thử tab Tiến độ: báo cáo thói quen và thống kê phiên học ở cùng một chỗ,
// trạng thái trống, và không còn lối vào cũ ở Thói quen / Cài đặt (spec 001 US3, FR-012).
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/mock_data.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

/// Thursday 5/3/2026, 10:00.
final DateTime _now = DateTime(2026, 3, 5, 10);

Future<void> _tap(WidgetTester tester, Finder finder) => tapAndSettle(tester, finder);

Future<void> _onboard() => ProfileRepository().completeOnboarding(
  const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
);

Future<void> _openHabitsTab(WidgetTester tester) =>
    _tap(tester, find.widgetWithText(NavigationDestination, 'Thói quen'));

Future<void> _openReport(WidgetTester tester) =>
    _tap(tester, find.widgetWithText(NavigationDestination, 'Tiến độ'));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() async {
    await openMemoryBoxes();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  });

  tearDown(() async => Hive.close());

  group('Tiến độ', () {
    testWidgets('Chưa có lịch sử thì Tiến độ báo trống', (tester) async {
      await _onboard();
      await GoalRepository().save(const Goal(id: 'g1', title: 'A', reason: 'B'));
      await pumpApp(tester, clock: () => _now);
      await _openReport(tester);
      expect(find.text('Tiến độ sẽ hiện ở đây sau phiên học đầu tiên.'), findsOneWidget);
      expect(find.text('Phiên học'), findsNothing);
    });

    testWidgets('Hai đoạn "Thói quen" và "Phiên học" đổi nội dung', (tester) async {
      await _onboard();
      await MockData.createDemoData(now: _now);
      await pumpApp(tester, clock: () => _now);
      await _openReport(tester);
      expect(find.text('Đã hoàn thành'), findsOneWidget);

      await _tap(tester, find.text('Phiên học'));
      expect(find.text('Đã hoàn thành'), findsNothing);
      expect(find.textContaining('Phút tập trung'), findsOneWidget);

      await _tap(tester, find.text('Thói quen').first); // The segment, not the tab.
      expect(find.text('Đã hoàn thành'), findsOneWidget);
    });

    testWidgets('Báo cáo và thống kê không còn ở Thói quen hay Cài đặt (FR-012)', (tester) async {
      await _onboard();
      await MockData.createDemoData(now: _now);
      await pumpApp(tester, clock: () => _now);

      await _openHabitsTab(tester);
      expect(find.byTooltip('Báo cáo'), findsNothing);

      await _tap(tester, find.widgetWithText(NavigationDestination, 'Hôm nay'));
      await _tap(tester, find.byTooltip('Cài đặt'));
      expect(find.text('Thống kê'), findsNothing);
      await tester.scrollUntilVisible(find.text('Tạo dữ liệu mẫu'), 200);
      expect(find.text('Thống kê'), findsNothing);
    });
  });
}
