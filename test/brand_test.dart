// 5.2 Brand (spec 008): logo C2 drawn from one SVG, and the "Biển nắng" colours with readable
// contrast in light and dark mode.
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/app_logo.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';

import 'test_helpers.dart';

/// WCAG contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('Logo (FR-001)', () {
    setUp(openMemoryBoxes);
    tearDown(() async => Hive.close());

    testWidgets('is drawn from the SVG and keeps its screen-reader label', (tester) async {
      await pumpStandalone(tester, const Scaffold(body: Center(child: AppLogo(size: 64))));

      final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(picture.bytesLoader, isA<SvgAssetLoader>());
      expect((picture.bytesLoader as SvgAssetLoader).assetName, 'assets/branding/logo.svg');
      expect(find.bySemanticsLabel('Logo DisGret'), findsOneWidget);
    });
  });

  group('"Biển nắng" colours (FR-003)', () {
    final light = AppTheme.light.colorScheme;
    final dark = AppTheme.dark.colorScheme;

    test('the main colour is the sunny sea blue', () {
      expect(light.primary, const Color(0xFF1565C0));
      expect(dark.primary, const Color(0xFF1B6ED4));
      expect(AppColors.brand, const Color(0xFF1E88E5));
      expect(AppColors.sun, const Color(0xFFFFC93C));
    });

    test('button text is readable on the main colour', () {
      expect(contrast(light.onPrimary, light.primary), greaterThanOrEqualTo(4.5));
      expect(contrast(dark.onPrimary, dark.primary), greaterThanOrEqualTo(4.5));
    });

    test('links and selected items are readable on the background', () {
      expect(contrast(light.secondary, light.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(dark.secondary, dark.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(light.onSurfaceVariant, light.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(dark.onSurfaceVariant, dark.surface), greaterThanOrEqualTo(4.5));
    });

    test('rings and progress stand out from cards', () {
      expect(contrast(light.tertiary, light.surfaceContainer), greaterThanOrEqualTo(3));
      expect(contrast(dark.tertiary, dark.surfaceContainer), greaterThanOrEqualTo(3));
    });

    test('text on the sun highlight is readable', () {
      expect(contrast(AppColors.onSun, AppColors.sun), greaterThanOrEqualTo(4.5));
    });
  });
}
