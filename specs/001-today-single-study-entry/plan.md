# Implementation Plan: Today Screen, Three-Tab Navigation and a Single Study Entry

**Branch**: `feature/001-today-single-study-entry` | **Date**: 2026-11-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-today-single-study-entry/spec.md`

## Summary

Replace the four-tab shell (Trang chủ, Reels, Focus, Thói quen) with three tabs (Hôm nay, Thói
quen, Tiến độ). Hôm nay shows one session plan (goal, next habit, planned minutes, small streak) and
one "Bắt đầu" button that opens a full-screen motivation route; skipping or starting from there runs
the existing session start (Reset Break confirmation, then `FocusSessionNotifier.start`) and opens a
full-screen `/focus`. A running-session banner sits above the tab bar. Report and statistics move
into Tiến độ. Achievements, heat map and 66-day journey lose every UI entry point. No persisted data
changes.

## Technical Context

**Language/Version**: Dart SDK ^3.13.7, Flutter 3.47.9 (stable); Kotlin native layer unchanged

**Primary Dependencies**: flutter_riverpod 3, go_router 18, material_ui (Material 3), hive /
hive_flutter, video_player (used by the motivation route), fl_chart (report). No new dependency.

**Storage**: Hive boxes on device; this feature reads existing boxes only and adds no field

**Testing**: `flutter test` (unit + widget tests with existing `test/test_helpers.dart`),
`flutter analyze`, `dart format`; manual check of native routes on Android emulator Pixel API 34+

**Target Platform**: Android (API 34+ emulator for verification); web only for UI iteration

**Project Type**: mobile-app (single Flutter project with Android native module)

**Performance Goals**: tab switches and route changes render in the next frame; no extra Hive reads
on the start path compared with today's code

**Constraints**: offline, local-only (Constitution II); existing data readable (III); Vietnamese UI
text from `lib/l10n/app_strings.dart` for touched screens (ADR-0005); hand-off 2026-11-24

**Scale/Scope**: ~10 screens touched or added, ~6 test files updated, 1 new strings file

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. Scenario-Driven Scope | Every story names S1/S2/S3; one study entry; no feed or social element added; parked features made unreachable | Pass |
| II. Local-Only Privacy | No network, permission or SDK added | Pass |
| III. Data Integrity | No model or box change; streak and plan rules stay in pure functions (`habit_science.dart`, new `session_plan.dart`) with unit tests | Pass |
| IV. Layered Simplicity | Plan selection in a pure function + provider; widgets call providers only; colours from theme; strings from `app_strings.dart`; no new package | Pass |
| V. Verified Changes | Widget tests for tabs, start flow, banner, Tiến độ, parked entries; unit tests for plan rule; native route check on emulator | Pass (to verify at implementation) |
| VI. Traceability | Spec → plan → tasks; README demo script and decomposition map updated; ADR-0002/0004 referenced | Pass |
| VII. Agent Collaboration | Shared files touched: `app_router.dart`, `main_shell.dart`, `app.dart`, `app_providers.dart`; dependents listed in research R6 and checked before edits | Pass |

Post-design re-check (after Phase 1): unchanged, no violations; Complexity Tracking not needed.

## Project Structure

### Documentation (this feature)

```text
specs/001-today-single-study-entry/
├── plan.md              # This file
├── research.md          # Phase 0 decisions
├── data-model.md        # Transient session-plan model, no persisted change
├── quickstart.md        # Validation scenarios
├── contracts/
│   └── navigation.md    # Route table, native-action routing, tab contract
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks output
```

### Source Code (repository root)

```text
lib/
├── app.dart                         # native-action routing → new routes (modify)
├── l10n/app_strings.dart            # NEW: Vietnamese strings for touched screens
├── data/session_plan.dart           # NEW: pure rule for next habit + planned minutes
├── providers/app_providers.dart     # sessionPlanProvider (+ override notifier) (modify)
├── router/app_router.dart           # 3 branches; /motivation, /focus, /summary full screen (modify)
├── screens/
│   ├── main_shell.dart              # 3 tabs, running-session banner, no level-up dialog (modify)
│   ├── today_screen.dart            # NEW (replaces home_screen.dart)
│   ├── progress_screen.dart         # NEW: Thói quen report | Phiên học stats
│   ├── reels_screen.dart            # moved to /motivation; content redesigned in spec 002 (modify)
│   ├── focus_screen.dart            # running view only; no setup step (modify)
│   ├── summary_screen.dart          # exit → /today (modify)
│   ├── habits_screen.dart           # "Theo ngày" label; drop report + achievements entries (modify)
│   ├── habit_detail_screen.dart     # hide heat map + journey sections (modify)
│   ├── report_screen.dart           # extract ReportView body (modify)
│   ├── stats_screen.dart            # extract StatsView body (modify)
│   └── settings_screen.dart         # drop statistics entry (modify)
├── widgets/
│   ├── session_plan_sheet.dart      # NEW: change habit/minutes (reuses MinutesPicker)
│   ├── running_session_banner.dart  # NEW
│   ├── habit_today_card.dart        # "Bắt đầu Focus" → plan override + /motivation (modify)
│   └── level_badge.dart             # drop push to achievements (modify)
└── services/study_starter.dart      # NEW: confirm Reset Break → start → go /focus

test/
├── session_plan_test.dart           # NEW unit tests
├── navigation_test.dart             # NEW: tabs, start flow, banner, native routing
├── progress_screen_test.dart        # NEW
├── widget_test.dart, focus_screen_test.dart, reset_break_test.dart,
│   report_screens_test.dart, habit_tracker_test.dart   # update for new routes/labels
```

**Structure Decision**: keep the existing single Flutter project layout (`lib/data`, `lib/providers`,
`lib/router`, `lib/screens`, `lib/services`, `lib/widgets`, `test/`). New pure logic goes to
`lib/data/`, orchestration to `lib/services/`, UI to `lib/screens` and `lib/widgets`.

## Complexity Tracking

No constitution violations.
