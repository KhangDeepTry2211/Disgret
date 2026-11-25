// 5.3 Màn chờ (spec 011 FR-003, FR-004): Gret swims across the brand blue while DisGret opens,
// then the screen fades into the app; with "remove animations" Gret stays still and the screen
// still goes away; it shows once per cold start.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/l10n/app_strings.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/launch_overlay.dart';
import 'package:focus_app/widgets/mascot/mascot_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';

import 'test_helpers.dart';

void main() {
  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await openMemoryBoxes();
    await ProfileRepository().completeOnboarding(
      const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
    );
  });
  tearDown(() async => Hive.close());

  final scene = find.byKey(LaunchOverlay.sceneKey);

  testWidgets('shows Gret, DisGret and the line, then goes away even without animations', (
    tester,
  ) async {
    await pumpApp(tester, launchScreen: true);

    expect(scene, findsOneWidget);
    expect(find.descendant(of: scene, matching: find.byType(MascotView)), findsOneWidget);
    expect(find.descendant(of: scene, matching: find.text(AppStrings.appName)), findsOneWidget);
    expect(find.text(AppStrings.launchLine), findsOneWidget);
    // Gret stays still in the middle when animations are removed.
    final screen = tester.getSize(find.byType(MaterialApp));
    final gret = find.descendant(of: scene, matching: find.byType(MascotView));
    expect(tester.getCenter(gret).dx, moreOrLessEquals(screen.width / 2));
    // The app underneath cannot be tapped while the launch screen covers it.
    expect(find.byType(NavigationBar).hitTestable(), findsNothing);

    await tester.pump(AppMotion.launch);
    await tester.pump();

    expect(scene, findsNothing);
    expect(find.text(AppStrings.launchLine), findsNothing);
    expect(find.byType(NavigationBar).hitTestable(), findsOneWidget);
  });

  testWidgets('does not come back when the student returns from the background', (tester) async {
    await pumpApp(tester, launchScreen: true);
    await tester.pump(AppMotion.launch);
    await tester.pump();
    expect(scene, findsNothing);

    hideApp(tester);
    await tester.pump();
    showApp(tester);
    await tester.pumpAndSettle();

    expect(scene, findsNothing);
    expect(find.byType(NavigationBar).hitTestable(), findsOneWidget);
  });

  testWidgets('tests and the rest of the app start without it', (tester) async {
    await pumpApp(tester);

    expect(scene, findsNothing);
    expect(find.byType(NavigationBar).hitTestable(), findsOneWidget);
  });

  testWidgets('Gret swims in from the right, then the screen fades into the app', (tester) async {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var taps = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: LaunchOverlay(
            child: Scaffold(
              body: Center(
                child: TextButton(onPressed: () => taps++, child: const Text('Vào app')),
              ),
            ),
          ),
        ),
      ),
    );

    final gret = find.byType(MascotView);
    final start = tester.getCenter(gret).dx;
    expect(start, greaterThan(smallPhone.width));

    await tester.pump(AppMotion.launch ~/ 2);
    final middle = tester.getCenter(gret).dx;
    expect(middle, lessThan(start));

    await tester.pump(AppMotion.launch ~/ 2);
    expect(tester.getCenter(gret).dx, lessThan(middle));
    expect(tester.getCenter(gret).dx, lessThan(smallPhone.width / 2));
    // Fading: the app underneath can already be tapped.
    await tester.pump();
    await tester.tap(find.text('Vào app'));
    expect(taps, 1);

    // The fade takes launchFade; settling also proves nothing keeps looping afterwards.
    await tester.pumpAndSettle();
    expect(scene, findsNothing);
    expect(gret, findsNothing);
  });
}
