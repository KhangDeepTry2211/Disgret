// 5.1 Tên gọi (spec 007, ADR-0012): an optional name, kept on the phone, that the Hôm nay header
// greets the student with; asked in onboarding and editable in Cài đặt.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/l10n/app_strings.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const Goal _goal = Goal(id: 'g1', title: 'Mục tiêu', reason: 'Lý do');
const Habit _habit = Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 25);
final DateTime _morning = DateTime(2026, 3, 2, 9);

Future<void> _onboard({String name = ''}) => ProfileRepository().completeOnboarding(
  UserProfile(
    motivationTypes: const [MotivationType.career],
    preferredReelLength: 30,
    displayName: name,
  ),
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    await openMemoryBoxes();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
    await GoalRepository().save(_goal);
    await HabitRepository().save(_habit);
  });

  tearDown(() async => Hive.close());

  group('The name rule (FR-001, FR-002)', () {
    test('spaces are trimmed and collapsed; only spaces means no name', () {
      expect(UserProfile.cleanName('  Minh   Anh '), 'Minh Anh');
      expect(UserProfile.cleanName('   '), '');
      expect(UserProfile.cleanName(''), '');
    });

    test('long names keep their first 20 letters, accents and emoji intact', () {
      const long = 'Nguyễn Trần Phương Thảo Vy';
      expect(UserProfile.cleanName(long), 'Nguyễn Trần Phương T');
      expect(UserProfile.cleanName(long).runes.length, UserProfile.maxNameLength);
      expect(UserProfile.cleanName('Khôi 🐟🐟🐟🐟🐟🐟🐟🐟🐟🐟🐟🐟🐟🐟🐟🐟'), endsWith('🐟'));
    });

    test('profiles saved before the name existed read with no name', () {
      final old = UserProfile.fromMap({
        'motivationTypes': ['career'],
        'preferredReelLength': 30,
      });
      expect(old.displayName, '');

      const named = UserProfile(
        motivationTypes: [MotivationType.career],
        preferredReelLength: 30,
        displayName: 'Khôi',
      );
      expect(UserProfile.fromMap(named.toMap()).displayName, 'Khôi');
      expect(named.copyWith(demoMode: true).displayName, 'Khôi');
    });

    test('the greeting adds the name only when there is one', () {
      expect(AppStrings.greetingFor(_morning, 'Khôi'), 'Chào buổi sáng, Khôi');
      expect(AppStrings.greetingFor(_morning, ''), 'Chào buổi sáng');
    });
  });

  group('The Hôm nay header (FR-003)', () {
    testWidgets('shows DisGret above the greeting with the name', (tester) async {
      await _onboard(name: 'Khôi');
      await pumpApp(tester, clock: () => _morning);

      expect(find.text('DisGret'), findsOneWidget);
      expect(find.text('Chào buổi sáng, Khôi'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('DisGret')).dy,
        lessThan(tester.getTopLeft(find.text('Chào buổi sáng, Khôi')).dy),
      );
    });

    testWidgets('without a name it only says good morning', (tester) async {
      await _onboard();
      await pumpApp(tester, clock: () => _morning);

      expect(find.text('Chào buổi sáng'), findsOneWidget);
    });

    testWidgets('a 20-letter name fits a small phone', (tester) async {
      await _onboard(name: UserProfile.cleanName('Nguyễn Trần Phương Thảo Vy'));
      await pumpApp(tester, clock: () => _morning);

      expect(tester.takeException(), isNull);
      expect(find.text('Chào buổi sáng, Nguyễn Trần Phương T'), findsOneWidget);
    });
  });

  group('Cài đặt and the introduction (FR-004)', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tapAndSettle(tester, find.byTooltip(AppStrings.settings));
      await tapAndSettle(tester, find.text(AppStrings.nameLabel));
    }

    testWidgets('the name is edited in Cài đặt and Hôm nay follows', (tester) async {
      await _onboard();
      await pumpApp(tester, clock: () => _morning);
      await openSettings(tester);

      await tester.enterText(find.byType(TextField), '  Minh   Anh ');
      await tapAndSettle(tester, find.text(AppStrings.save));
      expect(ProfileRepository().profile?.displayName, 'Minh Anh');
      expect(find.text('Minh Anh'), findsOneWidget, reason: 'Shown on the row');

      await tapAndSettle(tester, find.byTooltip(AppStrings.back));
      expect(find.text('Chào buổi sáng, Minh Anh'), findsOneWidget);
    });

    testWidgets('"Hủy" keeps the name', (tester) async {
      await _onboard(name: 'Khôi');
      await pumpApp(tester, clock: () => _morning);
      await openSettings(tester);

      await tester.enterText(find.byType(TextField), 'Ai đó');
      await tapAndSettle(tester, find.text(AppStrings.cancel));

      expect(ProfileRepository().profile?.displayName, 'Khôi');
    });

    testWidgets('replaying the introduction shows the current name', (tester) async {
      await _onboard(name: 'Khôi');
      await pumpApp(tester, clock: () => _morning);
      await tapAndSettle(tester, find.byTooltip(AppStrings.settings));
      await tester.scrollUntilVisible(find.text('Xem lại màn giới thiệu'), 200);
      await tapAndSettle(tester, find.text('Xem lại màn giới thiệu'));
      await tapAndSettle(tester, find.text(AppStrings.storySkip));

      expect(find.widgetWithText(TextField, 'Khôi'), findsOneWidget);
    });
  });
}
