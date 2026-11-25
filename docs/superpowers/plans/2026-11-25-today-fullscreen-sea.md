# Hôm nay on a full-screen sea Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fill Hôm nay with Gret's sea, float the existing cards over it, and float the tab bar.

**Architecture:** `TodayScreen` body becomes a `Stack`: a still `SeaScene` (full) behind a scrolling
list whose first item is a transparent Gret tap area; `MainShell` uses `extendBody` with an inset,
rounded `NavigationBar`; screens pad their last controls by `MediaQuery.paddingOf(context).bottom`.

**Tech Stack:** Flutter, Riverpod 3.

**Spec:** `specs/010-today-fullscreen-sea/spec.md`.

## Global Constraints

- `AppMascot.todayGretAlignment = Alignment(0, -0.4)`, `AppMascot.todayCardsTop = 0.44` (share of
  the screen height); `AppSpacing.md` margins; tab bar radius `AppRadius.pill`, 16 px insets.
- `SeaScene` gains an optional `gretAlignment` (default the current `SeaScene.gretAlignment`).
- Gate: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`.

## Review Focus

- Scrolling: the sea rect does not move (Task 1 test).
- Tapping Gret through the transparent area still talks (Task 1 test).
- Empty states: text readable on a card, not on the dark sea (Task 1 test).
- "Bắt đầu" and the Thói quen "+" stay above the floating bar (Task 2 test).
- 360×640: no overflow on Hôm nay and Thói quen (Task 2 test).

---

### Task 1: Full-screen sea with floating cards

**Files:** modify `lib/widgets/sea/sea_scene.dart` (`gretAlignment`), `lib/screens/today_screen.dart`
(`_PlanView`, `_WithSea`, `_SeaHero`; remove `_Sheet`), `lib/theme/app_theme.dart`; tests
`test/today_fullscreen_test.dart`, update `test/today_sea_test.dart` (tap Gret with `tapAt`).

- [ ] Tests: sea rect equals the screen; after dragging the list up 200 px the sea rect is
  unchanged and the clarity card moved up; Gret's centre is above 40% of the height and the clarity
  card starts below Gret; `tapAt` Gret's centre shows a `SpeechBubble`; with no goal the empty
  view sits inside a surface-coloured box.
- [ ] Implement; gate green.

### Task 2: Floating tab bar

**Files:** modify `lib/screens/main_shell.dart`, `lib/screens/today_screen.dart` (bottom padding);
tests in `test/today_fullscreen_test.dart`.

- [ ] Tests: `NavigationBar` rect inset ≥ 16 px from left, right and bottom; the "Bắt đầu" button and
  the Thói quen `RippleAddButton` end above the bar; no overflow on 360×640.
- [ ] Implement; gate green; emulator check.
