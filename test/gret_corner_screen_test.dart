// 5.4 Góc của Gret: the wardrobe button on Hôm nay, obtaining and wearing, locked seas, premium
// items and mascots (spec 004 user stories 1–3, FR-005, FR-006).
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
import 'package:focus_app/widgets/mascot/mascot_view.dart';
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
      distractionCount: 2,
    ),
  );

  Future<void> openCorner(WidgetTester tester, {Size size = _phone}) async {
    await pumpApp(tester, size: size, clock: () => now);
    await tapAndSettle(tester, find.byTooltip(AppStrings.cornerOpen));
  }

  GretLook todayLook(WidgetTester tester) => tester.widget<SeaScene>(find.byType(SeaScene)).look;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

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

  tearDown(() async {
    await Hive.close();
  });

  testWidgets('the button on Gret\'s sea shows the pearls and opens Góc của Gret', (tester) async {
    await earn(12);
    await pumpApp(tester, size: _phone, clock: () => now);

    final button = find.byTooltip(AppStrings.cornerOpen);
    expect(find.descendant(of: button, matching: find.text('12')), findsOneWidget);

    await tapAndSettle(tester, button);
    expect(find.text(AppStrings.cornerTitle), findsOneWidget);
    expect(find.text(AppStrings.cornerTabWardrobe), findsOneWidget);
    expect(find.text(AppStrings.cornerTabSea), findsOneWidget);
    expect(find.text(AppStrings.cornerTabMascots), findsOneWidget);
    expect(find.text(AppStrings.cornerNothingWorn), findsOneWidget);
  });

  testWidgets('obtain and wear the bow: pearls drop, Gret wears it on Hôm nay too', (tester) async {
    await earn(25);
    await openCorner(tester);

    await tapAndSettle(tester, find.text('Nơ hồng'));
    await tapAndSettle(tester, find.text(AppStrings.cornerObtain(20)));

    expect(find.text(AppStrings.cornerGot('Nơ hồng')), findsOneWidget);
    expect(
      find.text('${AppStrings.rarityCommon} · ${AppStrings.cornerWearing}'),
      findsOneWidget,
      reason: 'The bow card says it is worn',
    );
    expect(GretCornerRepository().owned, {'pink_bow'});

    await tapAndSettle(tester, find.byTooltip('Quay lại'));
    expect(todayLook(tester).outfit, {OutfitSlot.head: 'assets/mascot/outfits/pink_bow.svg'});
    final gret = tester.widget<MascotView>(
      find.descendant(of: find.byType(SeaScene), matching: find.byType(MascotView)),
    );
    expect(gret.outfit[OutfitSlot.head], 'assets/mascot/outfits/pink_bow.svg');
    expect(
      find.descendant(of: find.byTooltip(AppStrings.cornerOpen), matching: find.text('5')),
      findsOneWidget,
    );
  });

  testWidgets('not enough pearls: says how many are missing, no exchange', (tester) async {
    await earn(25);
    await openCorner(tester);

    await tapAndSettle(tester, find.text('Áo phao'));
    expect(find.text(AppStrings.cornerMissing(95)), findsOneWidget);
    expect(find.text(AppStrings.cornerObtain(120)), findsNothing);
  });

  testWidgets('premium items are listed under Cửa hàng as "Sắp có" with no way to get them', (
    tester,
  ) async {
    await earn(500);
    await openCorner(tester);

    await tapAndSettle(tester, find.text(AppStrings.cornerFilterShop));
    expect(find.text('Mũ phù thuỷ'), findsOneWidget);
    expect(find.text('Nơ hồng'), findsNothing);

    await tapAndSettle(tester, find.text('Mũ phù thuỷ'));
    expect(find.text(AppStrings.cornerPremium), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('locked seas: arrows only preview them, the Biển tab shows the streak needed', (
    tester,
  ) async {
    await openCorner(tester);

    await tapAndSettle(tester, find.byTooltip(AppStrings.cornerNextSea));
    expect(
      find.text('Rạn san hô · ${AppStrings.cornerSeaLocked(3)}'),
      findsOneWidget,
      reason: 'Previewed, still locked',
    );
    expect(GretCornerRepository().sea, SeaPlace.home);

    await tapAndSettle(tester, find.text(AppStrings.cornerTabSea));
    expect(find.text(AppStrings.cornerStreak(3)), findsOneWidget);
    expect(find.text(AppStrings.cornerStreak(14)), findsOneWidget);
    await tapAndSettle(tester, find.text('Biển băng'));
    expect(GretCornerRepository().sea, SeaPlace.home);
  });

  testWidgets('the crab for 300 pearls swims on Hôm nay instead of Gret', (tester) async {
    await earn(320);
    await openCorner(tester);

    await tapAndSettle(tester, find.text(AppStrings.cornerTabMascots));
    expect(find.text('Mochi'), findsOneWidget);
    await tapAndSettle(tester, find.text('Bơ'));
    await tapAndSettle(tester, find.text(AppStrings.cornerObtain(300)));

    expect(GretCornerRepository().mascot, MascotSpecies.crab);
    await tapAndSettle(tester, find.byTooltip('Quay lại'));
    expect(todayLook(tester).species, MascotSpecies.crab);
  });

  testWidgets('small phone: Góc của Gret fits without overflow', (tester) async {
    await earn(50);
    await openCorner(tester, size: smallPhone);
    expect(tester.takeException(), isNull);

    await tapAndSettle(tester, find.text('Nơ hồng'));
    expect(tester.takeException(), isNull);
  });
}
