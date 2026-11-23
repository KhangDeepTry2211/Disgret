// 5.3 Reusable Gret and sea widgets (spec 003 FR-007, FR-015, FR-018, FR-020).
import 'package:flutter_test/flutter_test.dart';
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
    test('every mood has eyes and a mouth on the shared canvas', () {
      for (final mood in MascotMood.values) {
        final layers = MascotLook.layers(mood);
        expect(layers.first, 'assets/mascot/gret/body.svg');
        expect(layers, contains('assets/mascot/gret/mouth_${mood.name}.svg'));
        expect(MascotLook.lines(mood), isNotEmpty);
      }
    });

    test('blinking swaps open eyes only', () {
      expect(
        MascotLook.layers(MascotMood.happy, blinking: true),
        contains('assets/mascot/gret/eyes_blink.svg'),
      );
      expect(
        MascotLook.layers(MascotMood.sleeping, blinking: true),
        contains('assets/mascot/gret/eyes_sleeping.svg'),
      );
    });

    test('extras: z for sleeping, sparkles for celebrating', () {
      expect(MascotLook.layers(MascotMood.sleeping).last, endsWith('zzz.svg'));
      expect(MascotLook.layers(MascotMood.celebrating).last, endsWith('sparkles.svg'));
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
      const MaterialApp(
        home: Scaffold(body: SeaScene(clarity: 85, mood: MascotMood.happy)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.binding.hasScheduledFrame, isTrue);
    // Remove the looping scene before the test ends.
    await tester.pumpWidget(const SizedBox());
  });
}
