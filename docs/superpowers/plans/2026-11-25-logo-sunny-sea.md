# New logo and "Biển nắng" palette Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the temporary logo with logo C2 and move the theme to the "Biển nắng" colours.

**Architecture:** One SVG logo drawn by flutter_svg in the app; PNGs rendered from it with headless
Edge feed `flutter_launcher_icons` and `flutter_native_splash`; theme colours change in
`AppColors` and the two `ColorScheme`s, checked by contrast tests.

**Tech Stack:** Flutter, flutter_svg (present), flutter_launcher_icons and flutter_native_splash
(present as dev dependencies), Microsoft Edge headless (local tool, not shipped).

**Spec:** `specs/008-logo-sunny-sea/spec.md`, design
`docs/superpowers/specs/2026-11-25-logo-sunny-sea-design.md`.

## Global Constraints

- Colours exactly as the design table; new tokens `AppColors.lightLink`, `darkLink`, `sun`,
  `onSun`, `brand` (#1E88E5); existing token names keep their meaning.
- No new runtime dependency; generated platform files come from the two existing tools.
- Gate: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`.

## Review Focus

- Dark mode primary button: white text ≥ 4.5:1 (Task 2 test).
- Links and selected chips on the light background ≥ 4.5:1 (Task 2 test).
- Header logo at 32 px still shows the bubble and Gret (emulator check, Task 3).
- Launcher icon under a round mask: Gret not cut away entirely (emulator check, Task 3).
- Screen readers: the logo keeps the label "Logo DisGret" (Task 1 test).

---

### Task 1: The logo in the app

**Files:** Create `assets/branding/logo.svg`; modify `lib/widgets/app_logo.dart`, `pubspec.yaml`
(assets); test `test/brand_test.dart`.

- [ ] Test: `AppLogo` builds an `SvgPicture` whose asset is `assets/branding/logo.svg` and is found
  by `find.bySemanticsLabel('Logo DisGret')`.
- [ ] Implement; gate green.

### Task 2: The "Biển nắng" theme

**Files:** Modify `lib/theme/app_theme.dart`; test `test/brand_test.dart`.

- [ ] Tests: light/dark `primary` equal #1565C0/#1B6ED4; contrast of `onPrimary` on `primary` ≥ 4.5
  in both; `secondary` on `surface` ≥ 4.5 in both; `tertiary` on `surfaceContainer` ≥ 3 in both;
  `AppColors.onSun` on `AppColors.sun` ≥ 4.5.
- [ ] Implement the table; the pearl count uses the sun colour; gate green.

### Task 3: Icon, splash, Kotlin colours, docs

- [ ] Render `assets/branding/logo.png` (1024) and `assets/launcher/logo_foreground.png` (1024, logo
  at 72%) from the SVG; update both tool configs to #1E88E5; run both tools.
- [ ] `colors.xml` (#07111F, #4DD0E1, #1E88E5); design-system palette section; README asset notes;
  remove `logo_tam.png`.
- [ ] Gate green; emulator: header, launcher icon, splash.
