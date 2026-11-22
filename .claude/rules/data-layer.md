---
paths:
  - "lib/data/**"
  - "lib/providers/**"
---

# Data layer

- Data written by earlier versions must stay readable: new fields get defaults, unknown enum values
  map to a default, `EventType` values are never removed (old events must parse).
- Never reuse a Hive box name; retired names stay listed in `HiveBoxes`. Do not delete user data
  except through the explicit "clear all data" reset.
- Streak, schedule, strength, statistics and session-plan rules are pure functions with unit tests;
  change the test first.
- Field-level documentation: `docs/architecture/data-model.md`. Update it when a model changes.
