# Living sea render Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A2 by day (06:00–17:59) and A4 by night, by the clock, in every sea (all four places,
including the ones bought with pearls), with a shaded Gret whose tail wags.

**Architecture:** Pure `SeaTime.isNight`; `SeaScene` and `SeaCafeScene` read `clockProvider` and
switch at the next boundary. `SeaPainter` gains day and night layers; `MascotView` rotates Gret's
new tail layer and tilts while bobbing.

**Tech Stack:** Flutter, Riverpod 3, flutter_svg.

**Spec:** `specs/013-living-sea-render/spec.md`; design
`docs/superpowers/specs/2026-11-25-living-sea-render-design.md`.

## Global Constraints

- Night: hour < 6 or hour ≥ 18. Clarity meaning unchanged (fish ≥ 70, litter < 40).
- Colours only in `AppSea` and SVG files; "remove animations" = still frame.
- Gate: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`.

## Review Focus

- 05:59 / 06:00 / 17:59 / 18:00 boundaries (Task 1 test).
- A scene open across 18:00 switches without a rebuild from outside (Task 1 test).
- Hôm nay's deep-water fill follows the clock too (Task 1).
- Every place (home, coral, ice, deep) paints both day and night without errors (Task 2 test).
- Only Gret gets the tail layer; outfits still sit on the body (Task 3 test).

---

### Task 1: Day or night by the clock

**Files:** create `lib/data/sea_time.dart`; modify `lib/widgets/sea/sea_scene.dart`,
`lib/widgets/cafe/sea_cafe_scene.dart`, `lib/screens/gret_corner_screen.dart`,
`lib/screens/today_screen.dart`; tests `test/sea_time_test.dart`, `test/living_sea_test.dart`
(and wrap the two direct `pumpWidget` sea tests in a `ProviderScope`).

- [x] Tests: boundaries; a scene at 20:00 paints night, at 09:00 day; a scene at 17:59:30 turns
  night 30 s later.
- [x] Implement; gate green.

### Task 2: A2 day and A4 night layers

**Files:** modify `lib/widgets/sea/sea_painter.dart`, `lib/theme/app_theme.dart` (`AppSea`);
`lib/widgets/sea/sea_scene.dart` (Gret's mouth bubbles); test `test/living_sea_test.dart`.

- [x] Tests: every place × day/night × clarity 85/30 paints without errors.
- [x] Implement; gate green.

### Task 3: Shaded Gret with a wagging tail

**Files:** create `assets/mascot/gret/tail.svg`; modify `assets/mascot/gret/body.svg`, open-eye
drawings, `lib/widgets/mascot/mascot_look.dart`, `lib/widgets/mascot/mascot_view.dart`,
`lib/theme/app_theme.dart` (`AppMotion.tailWag`, `AppMascot.tailJoint`); tests
`test/gret_sea_widgets_test.dart`.

- [x] Tests: Gret's layers start with the tail, then the body; a crab has no tail layer.
- [x] Implement; gate green; docs; emulator check by day, widget-test image by night.
