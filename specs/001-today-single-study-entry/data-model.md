# Data Model: Today Screen, Three-Tab Navigation and a Single Study Entry

No persisted entity, field or Hive box changes in this feature (Constitution III). Existing models
(`Goal`, `Habit`, `HabitLog`, `Session`, `Event`, `UserProfile`) are read as they are.

## Transient: SessionPlan (in memory only)

| Field | Type | Rule |
|---|---|---|
| goal | Goal? | first goal (current `todayGoalProvider` rule) |
| habit | Habit? | override habit if it still exists and is not archived; else first habit due today and not done; else first habit; null if no habit |
| plannedMinutes | int | override minutes if set; else `habit.minMinutesPerDay` when 5–480; else 25 |
| state | enum | `noGoal`, `noHabit`, `ready`, `allDoneToday`, `restDay` |

Derived from `habits`, `habitLogs`, `today` and the override; recomputed by the provider when any
of them changes.

## Transient: SessionPlanOverride (in memory only)

| Field | Type | Rule |
|---|---|---|
| habitId | String? | set from the plan sheet or the habit card "Bắt đầu Focus" shortcut |
| minutes | int? | 1–480, set from the plan sheet |

Lifecycle: empty → set by user → cleared when a session starts or the app restarts.

## State transitions used by navigation

`FocusPhase.setup` → (start) → `running` ⇄ (break) → `finished` → (summary closed, `reset`) →
`setup`. Banner visible when phase is `running`; `/focus` allowed only when `running`; `/summary`
only when `finished` (existing rule).
