---
description: "Tasks for feature 001: Today screen, three-tab navigation, single study entry"
---

# Tasks: Today Screen, Three-Tab Navigation and a Single Study Entry

**Input**: `specs/001-today-single-study-entry/` (plan.md, spec.md, research.md, data-model.md,
contracts/navigation.md, quickstart.md)

**Tests**: Required by Constitution V (new pure logic → unit tests; changed flows → widget tests).

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze` (0 issues)
and `flutter test` (0 failures) pass before the task is checked off.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no unfinished dependency)
- Paths are relative to the repository root.

## Phase 1: Setup

- [ ] T001 Create `lib/l10n/app_strings.dart` with a `AppStrings` class of `static const String`
      values (and small functions for interpolated text such as `startMinutes(int n)`) for every
      string introduced by this feature. **Done when** the file compiles and is referenced by at
      least one screen (ADR-0005).
- [ ] T002 [P] Create `docs/architecture/parked-features.md` listing achievements
      (`lib/data/achievements.dart`, `lib/widgets/level_badge.dart`, `lib/screens/achievements_screen.dart`),
      heat map (`lib/widgets/habit_heat_map.dart`), 66-day journey (`HabitScience.journeyDays`,
      `_Journey` in `habit_detail_screen.dart`) and the former Home habit card
      (`lib/widgets/habit_card.dart`: strength, "Đừng bỏ 2 lần liên tiếp" nudge) with reason and how
      to restore (ADR-0004).

## Phase 2: Foundational (blocks all stories)

- [ ] T003 Write `test/session_plan_test.dart` covering data-model.md `SessionPlan.habit`,
      `SessionPlan.plannedMinutes` and `SessionPlan.state` rules: override habit wins if present and
      not archived; else first due-and-not-done; else first habit; minutes = override, else
      `minMinutesPerDay` within 5–480, else 25; states `noGoal`, `noHabit`, `ready`,
      `allDoneToday`, `restDay`. **Done when** tests exist and fail.
- [ ] T004 Implement `lib/data/session_plan.dart` (pure `SessionPlan.next(...)`) so T003 passes.
- [ ] T005 Add `sessionPlanOverrideProvider` (data-model.md `SessionPlanOverride.habitId`,
      `.minutes`, cleared on start) and `sessionPlanProvider` in `lib/providers/app_providers.dart`;
      replace `focusHabitChoiceProvider` and update its users (`lib/screens/focus_screen.dart`,
      `lib/widgets/habit_today_card.dart`). **Done when** analyze is clean and existing tests pass.
- [ ] T006 Implement `lib/services/study_starter.dart` (research R3): if a session runs → go
      `/focus`; else `confirmStartWithResetBreak` → `FocusSessionNotifier.start(habit, minutes)` →
      clear override → go `/focus`. Add unit/widget test in `test/navigation_test.dart` proving no
      second session is created when called twice.
- [ ] T007 Restructure `lib/router/app_router.dart` per contracts/navigation.md: branches `/today`,
      `/habits`, `/progress`; full-screen `/motivation`, `/focus`, `/summary`; redirects for
      `/focus` (not running → `/today`), `/motivation?context=distracted` (not running → `/today`),
      `/motivation?context=start` (running → `/focus`); remove `/home`, `/reels`, `/report`,
      `/stats`, `/achievements`; unknown → `/today`. Temporarily point `/motivation` at the existing
      `ReelsScreen` content (spec 001 assumption). Move the clock pause (research R5) from
      `MainShell` into the motivation route.

**Checkpoint**: app builds; tabs may still show old content.

## Phase 3: User Story 1 — Start studying from Hôm nay (P1) 🎯 MVP

**Goal**: one obvious path Hôm nay → motivation → running session (S1).
**Independent test**: quickstart scenarios 1–3.

- [ ] T008 [P] [US1] Widget tests in `test/navigation_test.dart`: exactly 3 tabs in order (FR-001);
      Hôm nay shows goal, habit, "N phút", streak and exactly one control leading into a session
      (FR-002, SC-002); "Bắt đầu" opens motivation without tab bar (FR-004, FR-005); "Bỏ qua" starts
      a running session with plan minutes (FR-006); the settings icon on Hôm nay opens Cài đặt and
      Cài đặt still lists quiz, Reset Break permissions, blocked apps, demo mode and sample data
      (FR-015); edge states `noGoal`, `noHabit`, `allDoneToday`, `restDay`.
- [ ] T009 [US1] Implement `lib/screens/today_screen.dart` (replaces `home_screen.dart`, which is
      deleted) using `sessionPlanProvider`, `StreakRing` (small), one `GradientPillButton`
      "Bắt đầu", a change-plan text action, settings icon; strings from `AppStrings`.
- [ ] T010 [P] [US1] Implement `lib/widgets/session_plan_sheet.dart`: habit dropdown + `MinutesPicker`
      (presets 5/25/45, max 480) writing `sessionPlanOverrideProvider` (FR-003).
- [ ] T011 [US1] Wire the motivation step's start actions — "Bắt đầu N phút" (plan minutes), "Chỉ 5
      phút thôi" and "Bỏ qua" — to `StudyStarter` (FR-006, FR-007), and remove the `?minutes=`
      mechanism from `FocusScreen`. **If feature 002 is implemented right after 001 (planned),
      do this directly in 002's `MotivationScreen` (002-T007) instead of editing `ReelsScreen`;**
      only edit `ReelsScreen` if 002 slips past the hand-off.
- [ ] T012 [US1] Reduce `lib/screens/focus_screen.dart` to the running/break view (research R4);
      "Tạo thói quen" fallback removed (router redirect covers it).
- [ ] T013 [US1] `lib/screens/summary_screen.dart`: exit goes to `/today` (FR-011).
- [ ] T014 [US1] `lib/widgets/habit_today_card.dart`: "Bắt đầu Focus" sets the plan override habit
      and goes to `/motivation?context=start` (single flow).
- [ ] T015 [US1] Update `test/widget_test.dart`, `test/focus_screen_test.dart` and
      `test/habit_tracker_test.dart` to the new flow; all green. `lib/widgets/habit_card.dart`
      (strength, "Đừng bỏ 2 lần liên tiếp" nudge) is NOT deleted: it becomes unreferenced, is added
      to `docs/architecture/parked-features.md`, and its tests keep exercising it directly.

**Checkpoint**: US1 passes quickstart 1–3 on web and emulator.

## Phase 4: User Story 2 — Way back to a running session (P1)

**Goal**: running session reachable in 1 tap from anywhere; native outcomes land correctly (S2).
**Independent test**: quickstart scenarios 4–5.

- [ ] T016 [P] [US2] Widget tests in `test/navigation_test.dart`: banner on each tab while running
      (FR-008, SC-003); "Bắt đầu" while running opens `/focus` without a new session; simulated
      native actions `resume_focus`, `open_reels_distracted`, `break_ended` route per
      contracts/navigation.md (FR-009).
- [ ] T017 [P] [US2] Implement `lib/widgets/running_session_banner.dart` and place it above the
      `NavigationBar` in `lib/screens/main_shell.dart` (shows habit name and remaining time).
- [ ] T018 [US2] Update `_onNativeAction` and `_respondToDistraction` in `lib/app.dart` to the new
      routes; update `test/reset_break_test.dart`.
- [ ] T019 [US2] Manual native check on emulator (Pixel API 34+) with
      `docs/architecture/native-manual-checklist.md` (sections "Blocking during a session" and
      "Lifecycle") plus quickstart scenario 5; record the result in the commit message
      (Constitution V).

## Phase 5: User Story 3 — Progress in one place (P2)

**Goal**: report and statistics in Tiến độ (S3).
**Independent test**: quickstart scenario 6.

- [ ] T020 [P] [US3] Widget test `test/progress_screen_test.dart`: segments "Thói quen" and "Phiên
      học" switch content; empty state with no history; Thói quen app bar has no report action;
      Cài đặt has no statistics entry (FR-012).
- [ ] T021 [US3] Extract `ReportView` from `lib/screens/report_screen.dart` and `StatsView` from
      `lib/screens/stats_screen.dart` (bodies without Scaffold); create
      `lib/screens/progress_screen.dart`; remove the report button from `habits_screen.dart` and the
      statistics tile from `settings_screen.dart`; update `test/report_screens_test.dart`.
- [ ] T022 [US3] Rename the Thói quen segment "Hôm nay" to "Theo ngày" in
      `lib/screens/habits_screen.dart` (FR-013); update affected tests.

## Phase 6: User Story 4 — Parked features hidden (P3)

**Goal**: no entry to achievements, heat map, 66-day journey (ADR-0004).
**Independent test**: quickstart scenario 7.

- [ ] T023 [P] [US4] Widget tests: no "Thành tích" menu item; habit detail has no heat map or
      journey section; no level-up dialog after crossing a threshold (FR-014).
- [ ] T024 [US4] Remove the achievements menu item (`habits_screen.dart`), the push in
      `lib/widgets/level_badge.dart`, the level listener in `main_shell.dart`, and the heat map +
      journey sections in `lib/screens/habit_detail_screen.dart`; keep logic files and their tests.

## Phase 7: Polish & cross-cutting

- [ ] T025 Update `README.md` demo script and decomposition map (new routes and files).
- [ ] T026 [P] Verify SC-005 (upgrade keeps data): install `master` APK, create data, install this
      build, compare habits/logs/sessions/streak (quickstart scenario 8).
- [ ] T027 Run the full gate and quickstart; mark spec status "Implemented".
- [ ] T028 Hand-off check for SC-006 on 2026-11-24: each of the 3 testers opens Hôm nay once and
      says what it asks them to do; record time-to-answer and pass/fail (≤5 s) in
      `specs/001-today-single-study-entry/checklists/handoff-test.md`.

## Dependencies & order

- Phase 1 → Phase 2 (T003 → T004 → T005 → T006 → T007) → US1 → US2 → US3 → US4 → Polish.
- US3 and US4 only depend on Phase 2 and can be done before US2 if needed.
- Feature 002 starts after T007 (it replaces the motivation route content and absorbs T011).

## Parallel examples

- After T007: T008, T010 in parallel; then T009.
- US2: T016 and T017 in parallel, then T018.
- US3/US4: T020, T023 in parallel.

## Implementation strategy

MVP for the 2026-11-24 hand-off = Phases 1–4 (US1 + US2). US3 and US4 follow the same day if time
allows; they do not block feature 002.
