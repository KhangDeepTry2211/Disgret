// 5.3 Lively buttons (style F): the round "+" on Thói quen, raised like the pill buttons, with
// rings rippling out. They keep rippling while there is no habit yet, otherwise they ripple a few
// times and stop; with "remove animations" on there are none.
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/ripple_add_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';

import 'test_helpers.dart';

Finder get _rings => find.byKey(RippleAddButton.ringKey);

/// Pumps [button] in a themed app; fonts load first, then animations are turned on unless
/// [animations] is false.
Future<void> pumpButton(WidgetTester tester, Widget button, {bool animations = true}) async {
  await pumpStandalone(tester, const Scaffold(body: SizedBox()));
  if (animations) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures();
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: button)),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(openMemoryBoxes);
  tearDown(() async => Hive.close());

  testWidgets('a tap runs the action; screen readers hear a button with its tooltip', (
    tester,
  ) async {
    var taps = 0;
    await pumpButton(
      tester,
      RippleAddButton(tooltip: 'Tạo thói quen', onPressed: () => taps++),
      animations: false,
    );

    await tester.tap(find.byTooltip('Tạo thói quen'));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(
      tester.getSemantics(find.byType(RippleAddButton)),
      isSemantics(isButton: true, hasTapAction: true),
    );
  });

  testWidgets('the face sinks while pressed', (tester) async {
    await pumpButton(
      tester,
      RippleAddButton(tooltip: 'Tạo thói quen', onPressed: () {}),
      animations: false,
    );
    final face = find.byKey(RippleAddButton.faceKey);
    final resting = tester.getTopLeft(face).dy;

    final gesture = await tester.startGesture(tester.getCenter(face));
    await tester.pump(kPressTimeout);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(face).dy, resting + AppButton.edge);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(face).dy, resting);
  });

  testWidgets('with habits already, it ripples a few times and then stops', (tester) async {
    await pumpButton(tester, RippleAddButton(tooltip: 'Tạo thói quen', onPressed: () {}));
    await tester.pump(AppMotion.ripple ~/ 4);
    expect(_rings, findsWidgets);

    await tester.pump(AppMotion.ripple * AppButton.ripplePulses);
    await tester.pump();
    expect(_rings, findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('with no habit yet, it keeps rippling', (tester) async {
    await pumpButton(
      tester,
      RippleAddButton(tooltip: 'Tạo thói quen', keepRippling: true, onPressed: () {}),
    );

    await tester.pump(AppMotion.ripple * (AppButton.ripplePulses + 3));
    expect(_rings, findsWidgets);
    expect(tester.binding.hasScheduledFrame, isTrue);
    // Remove the looping button before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with "remove animations" on, there are no rings', (tester) async {
    await pumpButton(
      tester,
      RippleAddButton(tooltip: 'Tạo thói quen', keepRippling: true, onPressed: () {}),
      animations: false,
    );
    await tester.pump(AppMotion.ripple);

    expect(_rings, findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
