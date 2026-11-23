# Data Model: Gret and the Living Sea (003)

No stored data is added, removed or changed (FR-001, SC-006). Everything below is derived in
memory from existing boxes (`habit_logs`, `events`, `habits`).

## SeaClarity (pure, `lib/data/sea_clarity.dart`)

| Name | Type | Meaning |
|---|---|---|
| `start` | `double` const = 70 | Clarity of a user with no history |
| `decay` | `double` const = 0.7 | Weight of the previous value |
| `gain` | `double` const = 30 | Points for a perfect day |
| `distractionDayPenalty` | `double` const = 0.1 | Subtracted from a past day's score per distraction |
| `distractionLivePenalty` | `double` const = 5 | Points removed per distraction today |
| `fallbackTargetMinutes` | `int` const = 25 | Target when nothing was due but a session happened |
| `windowDays` | `int` const = 60 | History replayed |

Inputs (plain values so the function is testable without Hive):

- `studyMinutesByDay: Map<DateTime, int>` (date-only keys; minutes credited from habit logs, see
  research R1)
- `distractionsByDay: Map<DateTime, int>`
- `targetMinutesFor(DateTime day): int` (from habits and schedules, see research R2)
- `today: DateTime`
- `liveFocusMinutes: int` (running session, today only)
- reserved for feature 004+: `blockedMinutesByDay` (not read in 003)

Outputs:

- `double today` in [0, 100]
- `double yesterday` in [0, 100]
- The summary gain (R7) calls the same function twice: with the session (live minutes) and
  without it (its focus log left out, its distractions removed).

Rules (spec FR-003…FR-005):

```text
dayScore(d) = clamp(min(1, study(d) / target(d)) − 0.1 × distractions(d), 0, 1)
skip d when target(d) == 0 and study(d) == 0 and distractions(d) == 0   # rest day
clarity(d) = clarity(d−1) × 0.7 + 30 × dayScore(d)
today = clamp(max(y, y × 0.7 + 30 × scoreSoFar) − 5 × distractionsToday, 0, 100), y = clarity(yesterday)
```

Note: `y × 0.7 + 30 × 1` is at most 100 when y ≤ 100, so the scale never overflows.

## MascotMood (`lib/data/mascot_mood.dart`)

`enum MascotMood { happy, neutral, sad, focused, sleeping, celebrating }`

```text
moodFor(clarity, phase, isOnBreak, isSummary):
  isSummary           → celebrating
  phase == running    → isOnBreak ? sleeping : focused
  clarity ≥ 70        → happy
  clarity ≥ 40        → neutral
  otherwise           → sad
```

## MascotSpecies and MascotLook (`lib/widgets/mascot/mascot_look.dart`)

- `enum MascotSpecies { gret }` (later features add species; unknown → `gret`).
- `MascotLook`: species + mood → ordered list of asset paths (layers). Outfits are a later feature;
  the list order already reserves slots after `body`/`belly` (back) and after `eyes` (eyes, head,
  neck).

## SeaState (view model, `lib/providers/sea_providers.dart`)

| Field | Type | Source |
|---|---|---|
| `clarity` | `double` | `SeaClarity.today` |
| `mood` | `MascotMood` | `moodFor` |
| `level` | `ClarityLevel` | clear (≥ 70) / hazy (40–69) / murky (< 40) → "Biển trong" / "Hơi đục" / "Đục" |

Provider `seaInputsProvider` builds `SeaInputs` from `allHabitsProvider`, `habitLogsProvider` and
the event repository. Provider `seaStateProvider` watches it, `todayProvider` and a
`select` of `focusSessionProvider` (phase, isOnBreak, distractionCount, focused minutes) so it
recomputes on each distraction or new focused minute, not on every clock tick.
