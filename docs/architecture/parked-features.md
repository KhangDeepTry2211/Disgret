# Parked features

Features that are out of the MVP and have **no UI entry point**, but whose code, stored data and
unit tests are kept so they can return after the experiment ([ADR-0004](../decisions/0004-park-out-of-mvp-features.md)).
Do not delete these files without a new decision; do not link them from any screen.

Review this list after the 2026-11-24 hand-off.

| Feature | Files kept | Why parked | How to restore |
|---|---|---|---|
| Achievements (9 levels) and level-up dialog | `lib/data/achievements.dart`, `lib/widgets/level_badge.dart` (`LevelBadge`, `showLevelUpDialog`), `lib/screens/achievements_screen.dart`; providers `completionTotalProvider`, `achievementLevelProvider`; profile field `celebratedLevel` | Gamification does not serve S1–S3 and competes with the single study entry (ADR-0002) | Add an `/achievements` route in `app_router.dart`, a menu item in `habits_screen.dart`, re-add the push in `level_badge.dart` and the `ref.listen(achievementLevelProvider, …)` level-up listener in `main_shell.dart` |
| 16-week heat map on habit detail | `HabitHeatCalendar` and `HeatLegend` in `lib/widgets/habit_heat_map.dart` (`habitHeatLevel` in the same file still serves the Thói quen "Tổng thể" grid, which stays) | Long-term calendar view adds clutter to the habit detail screen | Put a "Lịch 16 tuần" `_Section` with `HabitHeatCalendar(history: …, today: …)` and `HeatLegend()` back in `lib/screens/habit_detail_screen.dart` |
| 66-day journey badges | `HabitScience.journeyDays`, `HabitScience.nextBadge`, `HabitBadge` in `lib/data/habit_science.dart`; `HabitJourney` widget in `lib/widgets/habit_journey.dart` (moved out of `habit_detail_screen.dart`) | Long-horizon badges are not part of S3's day-to-day keep-up loop | Render `HabitJourney(days: HabitScience.journeyDays(history))` in a section of the habit detail screen |
| Former Home habit card | `lib/widgets/habit_card.dart` (`HabitCard`: strength score, "Đừng bỏ 2 lần liên tiếp" nudge) | Hôm nay shows only one next habit (ADR-0002, spec 001 FR-002); full habit list lives in Thói quen | Use `HabitCard` in a screen again; its widget tests in `test/habit_tracker_test.dart` keep it working |

Pure logic and its tests (`test/habit_science_test.dart`, achievement tests) keep running in CI, so
the parked code stays correct while hidden. Parked widgets are pumped directly with
`pumpStandalone` / `pumpHabitCard` in `test/test_helpers.dart` (see `test/widget_test.dart`,
`test/habit_tracker_test.dart`, `test/report_screens_test.dart`).
