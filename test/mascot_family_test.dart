// 5.3–5.4 The mascot family (spec 018): three drawing styles chosen in Góc của Gret, friends
// earned by studying shown with their progress, and the four new emotes.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/gret_corner_catalog.dart';
import 'package:focus_app/data/mascot_mood.dart';
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
import 'package:focus_app/providers/gret_emote_provider.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/mascot/mascot_style_scope.dart';
import 'package:focus_app/widgets/mascot/mascot_view.dart';
import 'package:focus_app/widgets/sea/sea_scene.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'test_helpers.dart';

const Size _phone = Size(412, 915);

Finder _svg(String asset) => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName == asset,
);

void main() {
  late DateTime now;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    await openMemoryBoxes();
    now = DateTime(2026, 11, 27, 15);
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

  Future<void> openMascots(WidgetTester tester) async {
    await pumpApp(tester, size: _phone, clock: () => now);
    await tapAndSettle(tester, find.byTooltip(AppStrings.cornerOpen));
    await tapAndSettle(tester, find.text(AppStrings.cornerTabMascots));
  }

  group('Styles', () {
    testWidgets('MascotView follows MascotStyleScope, 3D mềm without one', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MascotView(mood: MascotMood.happy)));
      expect(_svg('assets/mascot/soft/body_gret.svg'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: MascotStyleScope(
            style: MascotStyle.flat,
            child: Column(
              children: [
                MascotView(mood: MascotMood.happy),
                MascotView(mood: MascotMood.happy, style: MascotStyle.classic),
              ],
            ),
          ),
        ),
      );
      expect(_svg('assets/mascot/flat/body_gret.svg'), findsOneWidget);
      expect(_svg('assets/mascot/gret/body.svg'), findsOneWidget, reason: 'style overrides');
    });

    test('an unknown stored style reads as 3D mềm', () async {
      expect(GretCornerRepository().style, MascotStyle.soft);
      await Hive.box<dynamic>('profile').put('corner_mascot_style', 'pixel');
      expect(GretCornerRepository().style, MascotStyle.soft);
      await GretCornerRepository().saveStyle(MascotStyle.flat);
      expect(GretCornerRepository().style, MascotStyle.flat);
    });

    testWidgets('Nét vẽ in Góc của Gret redraws every mascot and is kept', (tester) async {
      await openMascots(tester);
      expect(find.text(AppStrings.cornerStyleTitle), findsOneWidget);

      await tapAndSettle(tester, find.text(AppStrings.styleFlat));
      expect(GretCornerRepository().style, MascotStyle.flat);
      expect(_svg('assets/mascot/flat/body_crab.svg'), findsWidgets);
      expect(_svg('assets/mascot/soft/body_crab.svg'), findsNothing);

      await tapAndSettle(tester, find.byTooltip('Quay lại'));
      expect(_svg('assets/mascot/flat/body_gret.svg'), findsOneWidget);
    });
  });

  group('Friends earned by studying', () {
    testWidgets('the Linh vật tab shows eight friends and their progress', (tester) async {
      await SessionRepository().save(
        Session(
          id: 's1',
          habitId: 'h1',
          start: now,
          plannedMinutes: 25,
          focusedSeconds: 3 * 3600 + 1800,
          distractionCount: 0,
        ),
      );
      await openMascots(tester);
      final list = find
          .descendant(
            of: find.byKey(const ValueKey('corner-mascot-list')),
            matching: find.byType(Scrollable),
          )
          .first;

      for (final text in [
        AppStrings.cornerOnTimeShort(0, 5),
        AppStrings.cornerReturnsShort(0, 5),
        '3,5/10 giờ',
        '3,5/30 giờ',
        AppStrings.cornerDaysProgress(0, 21),
        AppStrings.cornerDaysProgress(0, 66),
      ]) {
        // Cards read "rarity · status".
        await tester.scrollUntilVisible(find.textContaining(text), 100, scrollable: list);
        expect(find.textContaining(text), findsOneWidget, reason: text);
      }

      await tester.scrollUntilVisible(find.text('Mây'), -100, scrollable: list);
      await tapAndSettle(tester, find.text('Mây'));
      expect(find.text('Sứa'), findsOneWidget);
      expect(
        find.text('${AppStrings.cornerNeedHours(10)}\n${AppStrings.cornerSoFar('3,5/10 giờ')}'),
        findsOneWidget,
      );
    });
  });

  group("Gret's home (spec 019)", () {
    testWidgets("a decoration bought in Góc của Gret stands by Gret's house on Hôm nay", (
      tester,
    ) async {
      await SessionRepository().save(
        Session(
          id: 's1',
          habitId: 'h1',
          start: now,
          plannedMinutes: 25,
          focusedSeconds: 50 * 300,
          distractionCount: 0,
        ),
      );
      await pumpApp(tester, size: _phone, clock: () => now);
      expect(_svg('assets/scene/home_house.svg'), findsOneWidget);
      await tapAndSettle(tester, find.byTooltip(AppStrings.cornerOpen));
      await tapAndSettle(tester, find.text(AppStrings.cornerTabSea));
      final list = find
          .descendant(
            of: find.byKey(const ValueKey('corner-sea-list')),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(find.text('Đèn lồng sứa'), 150, scrollable: list);
      await tapAndSettle(tester, find.text('Đèn lồng sứa'));
      await tapAndSettle(tester, find.text(AppStrings.cornerObtain(40)));

      expect(GretCornerRepository().decor, {DecorSpot.leftBack: 'deco_jelly_lantern'});
      await tapAndSettle(tester, find.byTooltip('Quay lại'));
      expect(_svg('assets/scene/deco_jelly_lantern.svg'), findsOneWidget);
    });
  });

  group('Emotes', () {
    test('a habit crossing 7, 21, 40 or 66 done days is a milestone', () {
      expect(GretEmotes.reachedMilestone({'h1': 6}, {'h1': 7}), isTrue);
      expect(GretEmotes.reachedMilestone({'h1': 20}, {'h1': 21, 'h2': 3}), isTrue);
      expect(GretEmotes.reachedMilestone({'h1': 7}, {'h1': 8}), isFalse);
      expect(GretEmotes.reachedMilestone({'h1': 8}, {'h1': 7}), isFalse, reason: 'unticked');
      expect(GretEmotes.reachedMilestone(const {}, {'h1': 1}), isFalse);
    });

    testWidgets('tapping Gret on Hôm nay shows love, every third tap a wink', (tester) async {
      await pumpApp(tester, size: _phone, clock: () => now);
      MascotMood mood() => tester.widget<SeaScene>(find.byType(SeaScene)).mood;
      final before = mood();

      await tester.tap(find.byType(MascotView));
      await tester.pump();
      expect(mood(), MascotMood.love);
      await tester.tap(find.byType(MascotView));
      await tester.pump();
      expect(mood(), MascotMood.love);
      await tester.tap(find.byType(MascotView));
      await tester.pump();
      expect(mood(), MascotMood.wink);

      await tester.pump(AppMotion.emote + const Duration(milliseconds: 100));
      await tester.pump(AppMotion.speechBubble);
      expect(mood(), before);
    });

    testWidgets('Hôm nay opened in the morning winks once', (tester) async {
      now = DateTime(2026, 11, 27, 8);
      await pumpApp(tester, size: _phone, clock: () => now, launchScreen: true);
      await tester.pump();
      expect(tester.widget<SeaScene>(find.byType(SeaScene)).mood, MascotMood.wink);
      await tester.pump(AppMotion.emote + const Duration(milliseconds: 100));
      expect(tester.widget<SeaScene>(find.byType(SeaScene)).mood, isNot(MascotMood.wink));
    });

    test('an emote clears itself', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gretEmoteProvider.notifier).show(MascotMood.proud);
      expect(container.read(gretEmoteProvider), MascotMood.proud);
      await Future<void>.delayed(AppMotion.emote + const Duration(milliseconds: 50));
      expect(container.read(gretEmoteProvider), isNull);
    });
  });
}
