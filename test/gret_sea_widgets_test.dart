// 5.3 Reusable Gret and sea widgets (spec 003 FR-007, FR-015, FR-018, FR-020).
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/gret_corner_catalog.dart';
import 'package:focus_app/data/mascot_mood.dart';
import 'package:focus_app/l10n/app_strings.dart';
import 'package:focus_app/widgets/mascot/mascot_look.dart';
import 'package:focus_app/widgets/sea/clarity_card.dart';
import 'package:focus_app/widgets/sea/sea_scene.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(openMemoryBoxes);
  tearDown(() async => Hive.close());

  group('MascotLook', () {
    test('only Gret has a tail layer; outfits still sit on the body (spec 013)', () {
      for (final style in MascotStyle.values) {
        expect(File(MascotLook.tailOf(style)).existsSync(), isTrue);
        for (final species in MascotSpecies.values.where((s) => s != MascotSpecies.gret)) {
          expect(
            MascotLook.layers(MascotMood.happy, species: species, style: style),
            isNot(contains(MascotLook.tailOf(style))),
          );
        }
        final dressed = MascotLook.layers(
          MascotMood.happy,
          style: style,
          outfit: const {OutfitSlot.back: 'assets/mascot/outfits/hero_cape.svg'},
        );
        expect(
          dressed.indexOf(MascotLook.tailOf(style)),
          lessThan(dressed.indexOf(MascotLook.bodyOf(MascotSpecies.gret, style))),
        );
      }
    });

    test('every mood of every species and style has its drawings (spec 018)', () {
      for (final style in MascotStyle.values) {
        for (final species in MascotSpecies.values) {
          for (final mood in MascotMood.values) {
            for (final blinking in [false, true]) {
              final layers = MascotLook.layers(
                mood,
                species: species,
                style: style,
                blinking: blinking,
              );
              for (final path in layers) {
                expect(File(path).existsSync(), isTrue, reason: path);
              }
            }
          }
        }
      }
      for (final mood in MascotMood.values) {
        expect(MascotLook.lines(mood), isNotEmpty);
        expect(MascotLook.moodLabel(mood), isNotEmpty);
      }
    });

    test('the classic style keeps the first drawings', () {
      final layers = MascotLook.layers(MascotMood.happy, style: MascotStyle.classic);
      expect(layers.take(2), ['assets/mascot/gret/tail.svg', 'assets/mascot/gret/body.svg']);
      expect(layers, contains('assets/mascot/gret/mouth_happy.svg'));
      expect(
        MascotLook.layers(
          MascotMood.happy,
          species: MascotSpecies.crab,
          style: MascotStyle.classic,
        ),
        contains('assets/mascot/crab/body.svg'),
      );
    });

    test('the other styles have their own folder', () {
      expect(MascotLook.layers(MascotMood.happy, style: MascotStyle.flat).take(2), [
        'assets/mascot/flat/tail.svg',
        'assets/mascot/flat/body_gret.svg',
      ]);
      expect(
        MascotLook.layers(MascotMood.happy, species: MascotSpecies.whale),
        contains('assets/mascot/soft/body_whale.svg'),
        reason: '3D mềm is the default',
      );
    });

    test('blinking swaps open eyes only', () {
      expect(
        MascotLook.layers(MascotMood.happy, blinking: true),
        contains('assets/mascot/soft/eyes_blink.svg'),
      );
      expect(
        MascotLook.layers(MascotMood.sleeping, blinking: true),
        contains('assets/mascot/soft/eyes_sleeping.svg'),
      );
      expect(
        MascotLook.layers(MascotMood.wink, blinking: true),
        contains('assets/mascot/soft/eyes_wink.svg'),
      );
    });

    test('extras: z, sparkles, hearts, one sparkle and a burst', () {
      expect(MascotLook.layers(MascotMood.sleeping).last, endsWith('zzz.svg'));
      expect(MascotLook.layers(MascotMood.celebrating).last, endsWith('sparkles.svg'));
      expect(MascotLook.layers(MascotMood.love).last, endsWith('hearts.svg'));
      expect(MascotLook.layers(MascotMood.proud).last, endsWith('sparkle.svg'));
      expect(MascotLook.layers(MascotMood.surprised).last, endsWith('burst.svg'));
    });

    test('only the tail files count as tails', () {
      for (final style in MascotStyle.values) {
        expect(MascotLook.isTail(MascotLook.tailOf(style)), isTrue);
        expect(MascotLook.isTail(MascotLook.bodyOf(MascotSpecies.gret, style)), isFalse);
      }
    });
  });

  test('clarity labels follow the thresholds', () {
    expect(ClarityCard.labelFor(90), AppStrings.clarityClear);
    expect(ClarityCard.labelFor(50), AppStrings.clarityHazy);
    expect(ClarityCard.labelFor(10), AppStrings.clarityMurky);
  });

  testWidgets('the sea describes Gret and the clarity to screen readers', (tester) async {
    await pumpStandalone(tester, const Scaffold(body: SeaScene(clarity: 32, mood: MascotMood.sad)));

    expect(find.bySemanticsLabel('Gret đang buồn. Biển trong 32%.'), findsOneWidget);
  });

  testWidgets('with "remove animations" on, nothing keeps animating', (tester) async {
    await pumpStandalone(
      tester,
      const Scaffold(
        body: Column(
          children: [
            SeaScene(clarity: 85, mood: MascotMood.happy),
            ClarityCard(clarity: 85),
          ],
        ),
      ),
    );

    // pumpStandalone settled already; a looping controller would keep scheduling frames.
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.text('85%'), findsOneWidget);
  });

  testWidgets('with animations on, the sea keeps moving', (tester) async {
    await pumpStandalone(tester, const Scaffold(body: SizedBox()));
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures();
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SeaScene(clarity: 85, mood: MascotMood.happy)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.binding.hasScheduledFrame, isTrue);
    // Remove the looping scene before the test ends.
    await tester.pumpWidget(const SizedBox());
  });
}
