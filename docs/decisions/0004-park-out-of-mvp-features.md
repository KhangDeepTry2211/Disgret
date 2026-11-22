# ADR-0004: Park out-of-MVP habit features instead of deleting them

- Status: Accepted
- Date: 2026-11-22

## Context

The habit tracker carries features that do not serve S1–S3 and clutter the main path: 9-level
achievements, the heat map, the 66-day journey badges, and the level-up dialog in `MainShell`.
The old Home habit card (`HabitCard`: strength score, "Đừng bỏ 2 lần liên tiếp" nudge) also loses
its only screen when Hôm nay is simplified (ADR-0002).

## Decision

- Remove every UI entry point to these features (menu items, routes, dialogs, cards).
- Keep their pure logic (`lib/data/habit_science.dart`, `lib/data/achievements.dart`), stored data,
  and unit tests, so they can return after the experiment.
- List parked features in `docs/architecture/parked-features.md`.

## Consequences

- Some widgets become unreferenced; they are acceptable until the parked list is reviewed after
  2026-11-24. Deleting them is a separate decision.
