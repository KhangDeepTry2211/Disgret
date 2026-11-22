# Research: Today Screen, Three-Tab Navigation and a Single Study Entry

All Technical Context items were known from the codebase; no NEEDS CLARIFICATION remained. The
decisions below fix the design points the spec leaves open.

## R1. Planned duration shown on Hôm nay

- **Decision**: planned minutes = the habit's `minMinutesPerDay` when it is between 5 and 480;
  otherwise 25 (the current Focus default). A user override from the plan sheet replaces it for one
  session. The secondary action is always 5 minutes.
- **Rationale**: the habit already stores how many focus minutes count as done; reusing it keeps
  Hôm nay consistent with habit completion. 25 keeps today's behaviour when the field is unset.
- **Alternatives**: remaining minutes for today (can be 1–2 minutes, confusing); always 25 (ignores
  the habit).

## R2. Where the session plan lives

- **Decision**: a pure function `SessionPlan.next(habits, logs, today, override)` in
  `lib/data/session_plan.dart`, exposed by `sessionPlanProvider`; the override
  (habitId, minutes) is held by a small notifier and cleared when a session starts.
  `focusHabitChoiceProvider` is replaced by this override.
- **Rationale**: Constitution III/IV — selection rules in pure, unit-tested functions; one source of
  truth for Hôm nay, the motivation end card and the habit card shortcut.
- **Alternatives**: keep `focusHabitChoiceProvider` plus a minutes provider (two sources of truth).

## R3. Starting a session from several places

- **Decision**: `StudyStarter.start(context, ref, minutes)` in `lib/services/study_starter.dart`
  runs `confirmStartWithResetBreak`, calls `FocusSessionNotifier.start(habit, minutes)` with the plan
  habit, clears the override and goes to `/focus`. If a session already runs it only goes to
  `/focus`.
- **Rationale**: "Bỏ qua", "Bắt đầu N phút" and "Chỉ 5 phút thôi" share one path, so the Reset
  Break permission check can never be skipped and no duplicate session is created
  (`start` already ignores calls outside `setup`).
- **Alternatives**: keep the `?minutes=` query on `/focus` (current approach; clears itself with a
  second navigation and is harder to test).

## R4. Focus screen without a setup step

- **Decision**: `/focus` shows only the running or break view. If no session is running, the router
  redirects `/focus` to `/today`. Habit and duration are changed on Hôm nay through
  `session_plan_sheet.dart`, reusing `MinutesPicker` (presets 5/25/45, max 480).
- **Rationale**: FR-004 (no other control starts a session) and FR-006 (skip starts immediately).
- **Alternatives**: keep the setup view reachable (re-creates the second entry).

## R5. Session clock pause while motivating

- **Decision**: the motivation route calls `setWatchingReels(true)` on open and `false` on close
  (initState/dispose with a post-frame callback), replacing `MainShell._syncReelsTabWithSession`.
- **Rationale**: same notifier API, behaviour unchanged (FR-010).

## R6. Shared components and dependents (checked by code search)

| Changed symbol | Dependents found |
|---|---|
| `AppRoutes.home/reels/focus/focusFor/reelsFor/report/stats/achievements` | `app.dart`, `home_screen.dart`, `reels_screen.dart`, `focus_screen.dart`, `summary_screen.dart`, `onboarding_screen.dart`, `habits_screen.dart`, `settings_screen.dart`, `level_badge.dart`, `habit_today_card.dart`, tests `widget_test`, `focus_screen_test`, `reset_break_test`, `report_screens_test`, `reels_screen_test` |
| `MainShell` (4 tabs, level-up listener, reels-tab pause) | router only; tests referencing tab labels |
| `focusHabitChoiceProvider` | `focus_screen.dart`, `habit_today_card.dart` |
| `HabitCard` | only `home_screen.dart` and `habit_tracker_test.dart` → becomes unused after Hôm nay is replaced; test expectations move to the habit card used in Thói quen or are dropped |

Re-checked on 2026-11-22 against the first Graphify graph: the graph found a subset of these
dependents (it misses some Dart references, see `docs/architecture/codebase-graph.md`); the grep
list above stands. Re-run both before implementing.

## R7. Tiến độ composition

- **Decision**: `ProgressScreen` with a two-segment control "Thói quen" | "Phiên học". The bodies
  of `ReportScreen` and `StatsScreen` are extracted into `ReportView` and `StatsView` (no Scaffold);
  the old routes `/report` and `/stats` are removed.
- **Rationale**: reuse tested content (report_logic, focus_stats) with minimal change.
- **Alternatives**: a scrolling page with both (long, mixes two purposes).

## R8. Parked features

- **Decision**: remove the `/achievements` route, the Thói quen menu item, the `level_badge` push,
  the `MainShell` level-up listener, and the heat map + journey sections in `habit_detail_screen`.
  Keep `achievements.dart`, `habit_science.dart`, `habit_heat_map.dart`, `level_badge.dart` and
  their unit tests; record them in `docs/architecture/parked-features.md`.
- **Rationale**: ADR-0004.

## R9. Route names

- **Decision**: `/today`, `/habits`, `/progress` (tabs); `/motivation?context=start|distracted`,
  `/focus`, `/summary` (full screen). Native actions are names, not paths, so Kotlin is unchanged.
- **Rationale**: ADR-0002; names match the Vietnamese tab meaning.
