// 5.4 Góc của Gret (spec 014 FR-002): four new seas bought with pearls.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/gret_corner_catalog.dart';
import 'package:focus_app/data/mascot_species.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/session.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/gret_corner_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/data/repositories/session_repository.dart';
import 'package:focus_app/l10n/app_strings.dart';
import 'package:focus_app/widgets/sea/sea_scene.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const Size _phone = Size(412, 915);

void main() {
  late DateTime now;

  /// Saved sessions worth [pearls] pearls (5 focused minutes each).
  Future<void> earn(int pearls) => SessionRepository().save(
    Session(
      id: 'study',
      habitId: 'h1',
      start: now,
      plannedMinutes: 25,
      focusedSeconds: pearls * 300,
      distractionCount: 0,
    ),
  );

  Future<void> openSeaTab(WidgetTester tester) async {
    await pumpApp(tester, size: _phone, clock: () => now);
    await tapAndSettle(tester, find.byTooltip(AppStrings.cornerOpen));
    await tapAndSettle(tester, find.text(AppStrings.cornerTabSea));
  }

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() async {
    await openMemoryBoxes();
    now = DateTime.now();
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
    await ProfileRepository().completeOnboarding(
      const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
    );
    await GoalRepository().save(const Goal(id: 'g1', title: 'Đỗ đại học', reason: 'Vì tương lai'));
    await HabitRepository().save(
      Habit(id: 'h1', goalId: 'g1', name: 'Ôn Toán', minMinutesPerDay: 30, startDate: now),
    );
  });

  tearDown(() async => Hive.close());

  test('four new seas cost 150, 200, 250 and 300 pearls', () {
    final prices = {
      for (final sea in GretCornerCatalog.seas)
        if (sea.unlock.kind == UnlockKind.pearls) sea.place: sea.unlock.price,
    };
    expect(prices, {
      SeaPlace.kelp: 150,
      SeaPlace.volcano: 200,
      SeaPlace.sunken: 250,
      SeaPlace.sunset: 300,
    });
    expect(GretCornerCatalog.seaOf(SeaPlace.kelp).name, 'Rừng tảo bẹ');
    expect(GretCornerCatalog.seaOf(SeaPlace.kelp).id, 'sea_kelp');
    expect(GretCornerCatalog.seaById('sea_sunset')?.place, SeaPlace.sunset);
  });

  testWidgets('buy Rừng tảo bẹ with 160 pearls: 10 left, chosen, on Hôm nay', (tester) async {
    await earn(160);
    await openSeaTab(tester);

    expect(find.text(AppStrings.cornerPrice(150)), findsOneWidget);
    await tapAndSettle(tester, find.text('Rừng tảo bẹ'));
    await tapAndSettle(tester, find.text(AppStrings.cornerObtain(150)));

    expect(GretCornerRepository().owned, contains('sea_kelp'));
    expect(GretCornerRepository().sea, SeaPlace.kelp);
    expect(find.bySemanticsLabel(AppStrings.cornerPearls(10)), findsWidgets);
    await tapAndSettle(tester, find.byTooltip('Quay lại'));
    expect(tester.widget<SeaScene>(find.byType(SeaScene)).look.place, SeaPlace.kelp);
  });

  testWidgets('with 100 pearls the sea stays locked and says how many are missing', (tester) async {
    await earn(100);
    await openSeaTab(tester);

    await tapAndSettle(tester, find.text('Rừng tảo bẹ'));
    expect(find.text(AppStrings.cornerMissing(50)), findsOneWidget);
    expect(GretCornerRepository().owned, isNot(contains('sea_kelp')));
    expect(GretCornerRepository().sea, SeaPlace.home);
  });

  testWidgets('the preview arrows show a pearl sea with its price', (tester) async {
    await pumpApp(tester, size: _phone, clock: () => now);
    await tapAndSettle(tester, find.byTooltip(AppStrings.cornerOpen));
    for (var i = 0; i < 4; i++) {
      await tapAndSettle(tester, find.byTooltip(AppStrings.cornerNextSea));
    }
    expect(find.text('Rừng tảo bẹ · ${AppStrings.cornerPrice(150)}'), findsOneWidget);
  });
}
