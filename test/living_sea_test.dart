// 5.3 Gret và biển sống (spec 013): the sea follows the clock, and every sea paints its day (A2)
// and night (A4) life at any clarity.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/gret_corner_catalog.dart';
import 'package:focus_app/data/mascot_mood.dart';
import 'package:focus_app/data/mascot_species.dart';
import 'package:focus_app/widgets/sea/sea_painter.dart';
import 'package:focus_app/widgets/sea/sea_scene.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';

import 'test_helpers.dart';

void main() {
  setUp(openMemoryBoxes);
  tearDown(() async => Hive.close());

  SeaPainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((paint) => paint.painter)
      .whereType<SeaPainter>()
      .single;

  const scene = SeaScene(clarity: 85, mood: MascotMood.happy);

  testWidgets('at 20:00 the sea is night, even in light mode', (tester) async {
    await pumpStandalone(tester, scene, clock: () => DateTime(2026, 11, 25, 20));
    expect(painterOf(tester).isNight, isTrue);
  });

  testWidgets('at 09:00 the sea is day', (tester) async {
    await pumpStandalone(tester, scene, clock: () => DateTime(2026, 11, 25, 9));
    expect(painterOf(tester).isNight, isFalse);
  });

  testWidgets('a sea left open across 18:00 turns to night by itself', (tester) async {
    var now = DateTime(2026, 11, 25, 17, 59, 30);
    await pumpStandalone(tester, scene, clock: () => now);
    expect(painterOf(tester).isNight, isFalse);

    now = DateTime(2026, 11, 25, 18, 0, 1);
    await tester.pump(const Duration(seconds: 31));
    expect(painterOf(tester).isNight, isTrue);
  });

  testWidgets('every sea paints day and night, clear and murky', (tester) async {
    var now = DateTime(2026, 11, 25, 9);
    await pumpStandalone(tester, const SizedBox(), clock: () => now);
    for (final place in SeaPlace.values) {
      for (final hour in [9, 21]) {
        for (final clarity in [85.0, 30.0]) {
          now = DateTime(2026, 11, 25, hour);
          await pumpStandalone(
            tester,
            SeaScene(
              key: ValueKey('$place-$hour-$clarity'),
              clarity: clarity,
              mood: MascotMood.happy,
              variant: SeaSceneVariant.full,
              look: GretLook(place: place),
            ),
            clock: () => now,
          );
          expect(painterOf(tester).isNight, hour == 21, reason: '$place $hour $clarity');
        }
      }
    }
  });
}
