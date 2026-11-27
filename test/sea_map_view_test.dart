// 5.5 Bản đồ biển, full screen from the Thói quen tab, and the focus session in the goal's sea
// (spec 005).
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/mascot_species.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/habit_log.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/gret_corner_repository.dart';
import 'package:focus_app/data/repositories/habit_log_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/data/repositories/study_place_repository.dart';
import 'package:focus_app/data/sea_map.dart';
import 'package:focus_app/data/study_place.dart';
import 'package:focus_app/l10n/app_strings.dart';
import 'package:focus_app/widgets/cafe/sea_cafe_scene.dart';
import 'package:focus_app/widgets/sea/landmark_look.dart';
import 'package:focus_app/widgets/sea/sea_scene.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const Size _phone = Size(412, 915);

void main() {
  late DateTime now;

  Future<void> saveHabit(String id, String goalId, String name, {int sortOrder = 0}) =>
      HabitRepository().save(
        Habit(
          id: id,
          goalId: goalId,
          name: name,
          minMinutesPerDay: 15,
          sortOrder: sortOrder,
          startDate: now.subtract(const Duration(days: 30)),
        ),
      );

  /// Ticks [habitId] on the last [days] days.
  Future<void> doneOn(String habitId, int days) async {
    for (var d = 1; d <= days; d++) {
      await HabitLogRepository().save(
        HabitLog(
          id: 'manual_${habitId}_$d',
          habitId: habitId,
          date: now.subtract(Duration(days: d)),
          source: HabitLogSource.manual,
          minutes: 15,
        ),
      );
    }
  }

  Future<void> openMap(WidgetTester tester, {Size size = _phone}) async {
    await pumpApp(tester, size: size, clock: () => now);
    await tapAndSettle(tester, find.widgetWithText(NavigationDestination, AppStrings.tabHabits));
    await tapAndSettle(tester, find.byTooltip(AppStrings.mapView));
  }

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
    await GoalRepository().save(const Goal(id: 'g1', title: 'Qua môn Toán', reason: 'Ra trường'));
    await GoalRepository().save(const Goal(id: 'g2', title: 'IELTS 7.0', reason: 'Du học'));
  });

  tearDown(() async {
    await Hive.close();
  });

  testWidgets('the tab still opens on Theo ngày; the full-screen map is one tap away', (
    tester,
  ) async {
    await saveHabit('h1', 'g1', 'Ôn bài');
    await pumpApp(tester, size: _phone, clock: () => now);
    await tapAndSettle(tester, find.widgetWithText(NavigationDestination, AppStrings.tabHabits));

    expect(find.byKey(const ValueKey('sea-map')), findsNothing);
    await tapAndSettle(tester, find.byTooltip(AppStrings.mapView));
    expect(find.byKey(const ValueKey('sea-map')), findsOneWidget);
    expect(find.text(AppStrings.mapTitle), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing, reason: 'Full screen, no tab bar');

    await tapAndSettle(tester, find.byTooltip(AppStrings.back));
    expect(find.text(AppStrings.habitsByDay), findsOneWidget);
  });

  testWidgets('one region per goal; a done habit shows n/66, a new one is a "?"', (tester) async {
    await saveHabit('h1', 'g1', 'Ôn bài', sortOrder: 1);
    await saveHabit('h2', 'g1', 'Làm đề', sortOrder: 2);
    await saveHabit('h3', 'g2', 'Nghe podcast');
    await doneOn('h1', 3);
    await openMap(tester);

    expect(find.text('Qua môn Toán'), findsOneWidget);
    expect(find.text('IELTS 7.0'), findsOneWidget);
    // (3 + 0) / (2 × 66) = 2%.
    expect(find.text(AppStrings.mapExploration('Rạn san hô', 2)), findsOneWidget);
    expect(find.text(AppStrings.mapExploration('Biển băng', 0)), findsOneWidget);
    expect(
      find.text(AppStrings.mapUnknown),
      findsNWidgets(2),
      reason: 'Seas waiting for new goals',
    );
    expect(find.text('3/66'), findsOneWidget);
    expect(find.bySemanticsLabel(AppStrings.mapHiddenSemantics('Làm đề')), findsOneWidget);
    expect(find.text(AppStrings.mapExplored(2)), findsOneWidget, reason: '3 / (3 × 66) ≈ 1.5%');
  });

  testWidgets('each habit is a landmark drawn by its stage; a new one is a "?" buoy (spec 012)', (
    tester,
  ) async {
    await saveHabit('h1', 'g1', 'Ôn bài', sortOrder: 1);
    await saveHabit('h2', 'g1', 'Làm đề', sortOrder: 2);
    await doneOn('h1', 8);
    await openMap(tester);

    List<String> drawnIn(String habitId) => [
      for (final picture in tester.widgetList<SvgPicture>(
        find.descendant(
          of: find.byKey(ValueKey('map-point-$habitId')),
          matching: find.byType(SvgPicture),
        ),
      ))
        (picture.bytesLoader as SvgAssetLoader).assetName,
    ];

    expect(drawnIn('h1'), LandmarkLook.layers(PointKind.fishCave, JourneyStage.warmUp));
    expect(
      find.descendant(of: find.byKey(const ValueKey('map-point-h1')), matching: find.text('8/66')),
      findsOneWidget,
    );
    expect(drawnIn('h2'), [LandmarkLook.buoy]);
  });

  testWidgets('a "?" point says which habit discovers it', (tester) async {
    await saveHabit('h1', 'g1', 'Ôn bài');
    await openMap(tester);

    await tester.tap(find.byKey(const ValueKey('map-point-h1')));
    await tester.pump();
    expect(find.text(AppStrings.mapDiscoverHint('Ôn bài')), findsOneWidget);
  });

  testWidgets('tapping a region lists its points with days and milestone', (tester) async {
    await saveHabit('h1', 'g1', 'Ôn bài');
    await doneOn('h1', 8);
    await openMap(tester);

    await tapAndSettle(tester, find.byKey(const ValueKey('map-point-h1')));
    expect(
      find.text(
        '${AppStrings.mapFishCave} · ${AppStrings.mapDaysLong(8, 66)} · ${AppStrings.mapStageWarmUp}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Gret stands on the map in the region studied last', (tester) async {
    await saveHabit('h1', 'g1', 'Ôn bài');
    await saveHabit('h3', 'g2', 'Nghe podcast');
    await doneOn('h3', 1);
    await openMap(tester);

    final gret = tester.getCenter(find.byKey(const ValueKey('map-gret')));
    final ielts = tester.getCenter(find.text('IELTS 7.0'));
    final math = tester.getCenter(find.text('Qua môn Toán'));
    expect((gret - ielts).distance, lessThan((gret - math).distance));
  });

  testWidgets('the map opens on Gret\'s island; + zooms in, "Về chỗ Gret" comes back', (
    tester,
  ) async {
    await saveHabit('h1', 'g1', 'Ôn bài');
    await doneOn('h1', 1);
    await openMap(tester);

    double scale() => tester
        .widget<InteractiveViewer>(find.byKey(const ValueKey('sea-map')))
        .transformationController!
        .value
        .getMaxScaleOnAxis();
    expect(scale(), closeTo(1, 1e-6));
    final gret = tester.getCenter(find.byKey(const ValueKey('map-gret')));
    expect(gret.dx, inInclusiveRange(0, _phone.width), reason: 'Gret is on screen');

    await tapAndSettle(tester, find.byTooltip(AppStrings.mapZoomIn));
    expect(scale(), closeTo(1.4, 1e-6));
    await tapAndSettle(tester, find.byTooltip(AppStrings.mapZoomOut));
    await tapAndSettle(tester, find.byTooltip(AppStrings.mapZoomOut));
    expect(scale(), closeTo(1 / 1.4, 1e-6));

    await tapAndSettle(tester, find.text(AppStrings.mapToGret));
    expect(scale(), closeTo(1, 1e-6));
  });

  testWidgets('− zooms out around the middle of the screen and keeps Gret in view', (tester) async {
    await saveHabit('h1', 'g1', 'Ôn bài');
    await doneOn('h1', 1);
    await openMap(tester);

    final controller = tester
        .widget<InteractiveViewer>(find.byKey(const ValueKey('sea-map')))
        .transformationController!;
    final middle = Offset(_phone.width / 2, _phone.height / 2);
    final before = controller.toScene(middle);
    // With animations on, each tap glides (AppMotion.mapGlide).
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures();
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip(AppStrings.mapZoomOut));
      for (var t = 0; t < 10; t++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final now = controller.toScene(middle);
      expect((now - before).distance, lessThan(1), reason: 'zoom-out ${i + 1} kept the middle');
    }
    final gret = tester.getCenter(find.byKey(const ValueKey('map-gret')));
    expect(gret.dx, inInclusiveRange(0, _phone.width));
    expect(gret.dy, inInclusiveRange(0, _phone.height));
  });

  testWidgets("a bought pearl sea is its own island; tapping it makes it Gret's sea (spec 014)", (
    tester,
  ) async {
    await saveHabit('h1', 'g1', 'Ôn bài');
    await GretCornerRepository().saveOwned({'sea_kelp'});
    await openMap(tester);
    for (var i = 0; i < 3; i++) {
      await tapAndSettle(tester, find.byTooltip(AppStrings.mapZoomOut));
    }

    expect(find.text('Rừng tảo bẹ'), findsOneWidget);
    expect(find.text(AppStrings.mapGretSea), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const ValueKey('map-sea-kelp')));
    await tapAndSettle(tester, find.text(AppStrings.mapChooseSea));

    expect(GretCornerRepository().sea, SeaPlace.kelp);
    await tapAndSettle(tester, find.byKey(const ValueKey('map-sea-kelp')));
    expect(find.text(AppStrings.mapSeaInUse), findsOneWidget);
  });

  testWidgets('a focus session happens in the sea of the habit\'s region', (tester) async {
    await StudyPlaceRepository().save(StudyPlace.sea);
    await saveHabit('h3', 'g2', 'Nghe podcast');
    await pumpApp(tester, size: _phone, clock: () => now);
    await holdToStart(tester);
    await tapAndSettle(tester, find.text('Bỏ qua'));

    expect(tester.widget<SeaScene>(find.byType(SeaScene)).look.place, SeaPlace.ice);
  });

  testWidgets('in Quán San Hô the windows look out on the habit\'s region', (tester) async {
    await saveHabit('h3', 'g2', 'Nghe podcast');
    await pumpApp(tester, size: _phone, clock: () => now);
    await holdToStart(tester);
    await tapAndSettle(tester, find.text('Bỏ qua'));

    expect(tester.widget<SeaCafeScene>(find.byType(SeaCafeScene)).windowPlace, SeaPlace.ice);
  });

  testWidgets('small phone: the full-screen map fits without overflow', (tester) async {
    await saveHabit('h1', 'g1', 'Một thói quen có tên khá dài để thử');
    await doneOn('h1', 2);
    await openMap(tester, size: smallPhone);

    expect(tester.takeException(), isNull);
  });
}
