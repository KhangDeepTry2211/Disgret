# Farmly buttons and icons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Part 1 of the lead's Farmly style: icon tiles, Farmly stat cards, "Lối tắt" and
"Việc hôm nay" on Hôm nay, arrow on the primary button, blue-bordered outlined buttons, card radius
20, in DisGret's "Biển nắng" colours.

**Architecture:** One `IconTile` widget (+ `ChevronCircle`); `ClarityCard` and `StreakCard` take an
`onTap`; a pure `TodayTasks.of` feeds the new Hôm nay card; theme changes in `app_theme.dart`.

**Tech Stack:** Flutter, Riverpod 3, go_router.

**Spec:** `specs/015-farmly-buttons-icons/spec.md`; mockup approved in conversation (2026-11-27).

## Global Constraints

- Colours from `AppHabitColors` (pastel pairs), `AppColors.sun/onSun`, the theme scheme.
- Shortcuts never start a session (ADR-0002). Text in `app_strings.dart`.
- Gate: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`.

## Review Focus

- Badge hidden at 0, tag hidden without pearls (Task 1 test).
- Timed habits sorted before untimed, archived and unscheduled ones left out (Task 1 test).
- Card semantics labels unchanged (existing tests).
- Small phone without overflow (Task 2 test).

---

### Task 1: Icon tiles, today's tasks rule, stat cards and buttons

**Files:** create `lib/widgets/icon_tile.dart`, `lib/data/today_tasks.dart`; modify
`lib/widgets/sea/clarity_card.dart`, `lib/widgets/streak_card.dart`,
`lib/widgets/gradient_pill_button.dart`, `lib/theme/app_theme.dart`, `lib/l10n/app_strings.dart`;
test `test/farmly_style_test.dart`.

- [x] Tests: `TodayTasks.of` order and done flags; `IconTile` badge and tag.
- [x] Implement; gate green.

### Task 2: Hôm nay

**Files:** modify `lib/screens/today_screen.dart`; test `test/farmly_style_test.dart`.

- [x] Tests: shortcuts with pearl tag and reminder badge; "1/2 đã xong" with rows; map shortcut
  opens the sea map; the clarity card opens Tiến độ; small phone.
- [x] Implement; gate green; docs; emulator check.
