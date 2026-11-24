// 5.3 Lively buttons (button styles 1–3, 5): the raised pill sinks when pressed and may breathe,
// bubbles rise for "done" actions, sticker chips wiggle when selected. With "remove animations"
// on, nothing moves except the press itself.
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/gradient_pill_button.dart';
import 'package:focus_app/widgets/sticker_chip.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';

import 'test_helpers.dart';

/// Pumps [child] centred in a themed app. Fonts load first (as in [pumpStandalone]); then the
/// "remove animations" setting is turned off unless [animations] is false.
Future<void> pumpLively(WidgetTester tester, Widget child, {bool animations = true}) async {
  await pumpStandalone(tester, const Scaffold(body: SizedBox()));
  if (animations) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures();
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
        ),
      ),
    ),
  );
}

/// The face of the raised pill: the box inside the part that moves when pressed.
Finder get _face =>
    find.descendant(of: find.byType(AnimatedPositioned), matching: find.byType(DecoratedBox));

/// Bubbles from [BubbleBurst] live in the root overlay as a private widget.
Finder get _bubbles =>
    find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_BubbleBurstView');

Matrix4 _chipTransform(WidgetTester tester) => tester
    .widget<Transform>(
      find.ancestor(of: find.byType(ChoiceChip), matching: find.byType(Transform)).first,
    )
    .transform;

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(openMemoryBoxes);
  tearDown(() async => Hive.close());

  group('Raised pill (style 1)', () {
    testWidgets('sinks while pressed, rises again and then runs its action', (tester) async {
      var taps = 0;
      await pumpLively(
        tester,
        GradientPillButton(label: 'Lưu', height: AppButton.compact, onPressed: () => taps++),
        animations: false,
      );
      final restingTop = tester.getTopLeft(_face.first).dy;

      final gesture = await tester.startGesture(tester.getCenter(find.text('Lưu')));
      // The press registers after kPressTimeout; then the face slides down for AppMotion.press.
      await tester.pump(kPressTimeout);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(_face.first).dy, restingTop + AppButton.edge);
      expect(taps, 0);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(_face.first).dy, restingTop);
      expect(taps, 1);
    });

    testWidgets('without an action it is disabled and does not sink', (tester) async {
      await pumpLively(
        tester,
        const GradientPillButton(label: 'Lưu', onPressed: null),
        animations: false,
      );
      final restingTop = tester.getTopLeft(_face.first).dy;

      final gesture = await tester.startGesture(tester.getCenter(find.text('Lưu')));
      // The press registers after kPressTimeout; then the face slides down for AppMotion.press.
      await tester.pump(kPressTimeout);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(_face.first).dy, restingTop);
      await gesture.up();

      expect(
        tester.getSemantics(find.byType(GradientPillButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
    });
  });

  group('Breathing (style 2)', () {
    testWidgets('a breathing button keeps growing and shrinking', (tester) async {
      await pumpLively(
        tester,
        GradientPillButton(label: 'Bắt đầu', breathing: true, onPressed: () {}),
      );
      await tester.pump(AppMotion.bob ~/ 2);

      expect(tester.binding.hasScheduledFrame, isTrue);
      final scale = tester.widget<ScaleTransition>(
        find.descendant(
          of: find.byType(GradientPillButton),
          matching: find.byType(ScaleTransition),
        ),
      );
      expect(scale.scale.value, greaterThan(1));
      // Remove the looping button before the test ends.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('stays still with "remove animations" on or when disabled', (tester) async {
      await pumpLively(
        tester,
        GradientPillButton(label: 'Bắt đầu', breathing: true, onPressed: () {}),
        animations: false,
      );
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);

      await pumpLively(
        tester,
        const GradientPillButton(label: 'Bắt đầu', breathing: true, onPressed: null),
      );
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('Bubbles (style 3)', () {
    testWidgets('rise from the button when it is tapped, then disappear', (tester) async {
      await pumpLively(tester, GradientPillButton(label: 'Lưu', bubbles: true, onPressed: () {}));
      expect(_bubbles, findsNothing);

      await tester.tap(find.text('Lưu'));
      await tester.pump();
      expect(_bubbles, findsOneWidget);

      await tester.pump(AppMotion.bubbleBurst + const Duration(milliseconds: 100));
      await tester.pump();
      expect(_bubbles, findsNothing);
    });

    testWidgets('do not show with "remove animations" on', (tester) async {
      var taps = 0;
      await pumpLively(
        tester,
        GradientPillButton(label: 'Lưu', bubbles: true, onPressed: () => taps++),
        animations: false,
      );

      await tester.tap(find.text('Lưu'));
      await tester.pump();
      expect(_bubbles, findsNothing);
      expect(taps, 1);
    });
  });

  group('Sticker chip (style 5)', () {
    Widget chip() {
      var selected = false;
      return StatefulBuilder(
        builder: (context, setState) => StickerChip(
          label: 'Sáng',
          icon: AppIcons.morning,
          colour: 6,
          selected: selected,
          onSelected: (value) => setState(() => selected = value),
        ),
      );
    }

    testWidgets('wiggles once when it becomes selected', (tester) async {
      await pumpLively(tester, chip());
      expect(_chipTransform(tester).isIdentity(), isTrue);

      await tester.tap(find.byType(ChoiceChip));
      await tester.pump();
      await tester.pump(AppMotion.wiggle ~/ 8);
      expect(_chipTransform(tester).isIdentity(), isFalse);

      await tester.pumpAndSettle();
      expect(_chipTransform(tester).isIdentity(), isTrue);
      expect(tester.widget<ChoiceChip>(find.byType(ChoiceChip)).selected, isTrue);
    });

    testWidgets('selects without moving with "remove animations" on', (tester) async {
      await pumpLively(tester, chip(), animations: false);

      await tester.tap(find.byType(ChoiceChip));
      await tester.pump();
      await tester.pump(AppMotion.wiggle ~/ 8);
      expect(_chipTransform(tester).isIdentity(), isTrue);
      expect(tester.widget<ChoiceChip>(find.byType(ChoiceChip)).selected, isTrue);
    });
  });
}
