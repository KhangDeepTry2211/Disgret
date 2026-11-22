# Data Model: Anti-reel Motivation as a Bounded Dose

## Persisted changes

| Item | Change |
|---|---|
| `EventType.motivationSkipped` (`motivation_skipped`) | NEW. Meta: `context` (`start` \| `distracted`), `position` (int, 1-based reel index when skipped) |
| `EventType.reelLiked`, `reelUnliked`, `reelCommented`, `reelShared` | Kept for parsing old events; never logged again |
| `reel_watched` | Unchanged meta: `reelId`, `secondsWatched`, `completed`, `startedFocus` |
| Hive boxes `reel_reactions`, `reel_comments` | Retired: not opened or read; names reserved; deleted only by an explicit full data reset |
| `ReelReaction`, `ReelComment` models | Removed from code |
| `Reel` (asset catalogue) | Unchanged |

## Transient: MotivationDose

| Field | Type | Rule |
|---|---|---|
| context | `start` \| `distracted` | from the route |
| playlist | List<Reel> | recommender output, length ≤ 3 (`start`) or ≤ 1 (`distracted`) |
| index | int | 0-based current reel |
| phase | `playing` \| `endCard` \| `done` | see transitions |

Transitions:

- `playing` → `videoEnded()` or playback error → `endCard`
- `endCard` → `next()` (only if `index < playlist.length - 1` and context `start`) → `playing`
  with `index + 1`
- any → `skip()` / `start(minutes)` / `backToSession()` / system Back → `done`
- empty playlist at creation → `done` immediately (caller starts or resumes the session)

End-card actions: `start` → "Bắt đầu N phút", "Chỉ 5 phút thôi", and "Tiếp" when another reel
remains; `distracted` → "Quay lại học" only. "Bỏ qua" is available in every `start` phase.
