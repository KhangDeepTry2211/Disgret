# Fonts and launch screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Use Baloo 2 + Nunito across the app and show Gret swimming across while DisGret opens.

**Architecture:** Variable fonts declared in `pubspec.yaml`; `AppTheme._textTheme` builds plain
`TextStyle`s with `fontFamily` and a `wght` variation. A `LaunchOverlay` in `MaterialApp.builder`
covers the router for 1.4 s, then fades; `launchScreenProvider` (bool) turns it off in tests.

**Tech Stack:** Flutter, Riverpod 3.

**Spec:** `specs/011-fonts-launch-screen/spec.md`.

## Global Constraints

- Files: `assets/fonts/Baloo2-Variable.ttf`, `assets/fonts/Nunito-Variable.ttf`,
  `assets/fonts/Baloo2-OFL.txt`, `assets/fonts/Nunito-OFL.txt` (from github.com/google/fonts).
- `AppFonts.heading = 'Baloo2'`, `AppFonts.body = 'Nunito'`; `AppMotion.launch` 1400 ms,
  `AppMotion.launchFade` 300 ms; text "Đang lặn xuống biển…" in `AppStrings.launchLine`.
- Gate: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`.

## Review Focus

- Weights: a title style really asks for 600 through the `wght` axis (Task 1 test).
- Reduced motion: the overlay still goes away (Task 2 test).
- The overlay blocks taps only while visible (Task 2 test).
- Coming back from the background does not show it again (Task 2 test).
- Licence page lists both fonts (Task 1, manual check).

---

### Task 1: Fonts

**Files:** modify `pubspec.yaml`, `lib/theme/app_theme.dart`, `lib/main.dart` (licences); remove
`assets/fonts/BeVietnamPro-*.ttf` and `OFL.txt`; test `test/brand_test.dart`.

- [x] Tests: `headlineSmall.fontFamily == 'Baloo2'` with `wght` 700; `titleMedium` Baloo2 600;
  `bodyMedium` Nunito 400; `labelLarge` Nunito 700.
- [x] Implement; gate green.

### Task 2: Launch screen

**Files:** create `lib/widgets/launch_overlay.dart`, `lib/providers/launch_providers.dart`; modify
`lib/app.dart`, `test/test_helpers.dart`, `lib/theme/app_theme.dart`, `lib/l10n/app_strings.dart`;
test `test/launch_overlay_test.dart`.

- [x] Tests: the overlay shows `AppStrings.launchLine` and a `MascotView` at start; after
  `launch + launchFade` it is gone and Hôm nay is tappable; with reduced motion it also goes away;
  resuming from the background does not bring it back.
- [x] Implement; gate green; emulator check.
