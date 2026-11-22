# UI Contract: Motivation Step (`/motivation`)

## Inputs

- Query `context`: `start` (default) or `distracted`.
- Session plan (feature 001): habit, planned minutes N.

## Screen elements

| Element | `start` | `distracted` |
|---|---|---|
| Reel video (plays once, tap = pause/resume) | yes | yes |
| Title + position "i/n" | yes | yes (always "1/1") |
| "Bỏ qua" (top) | always | no; system Back = back to session |
| End card: "Bắt đầu N phút" (primary) | yes | no |
| End card: "Chỉ 5 phút thôi" (secondary) | yes | no |
| End card: "Tiếp" | only if another reel remains | no |
| End card: "Quay lại học" | no | yes |
| Like / comment / share / counts / swipe | never | never |

## Outcomes

| Action | Navigation (feature 001) | Event |
|---|---|---|
| "Bỏ qua" | StudyStarter with N | `motivation_skipped` (+ `reel_watched` if ≥1 s watched) |
| "Bắt đầu N phút" / "Chỉ 5 phút thôi" | StudyStarter with N / 5 | `reel_watched` with `startedFocus: true` |
| "Tiếp" | stay, next reel | `reel_watched` for the finished reel |
| "Quay lại học" | `/focus` | `reel_watched` |
| System Back (`start`) | `/today`, no session | `reel_watched` if ≥1 s |
| Empty playlist | `start`: StudyStarter with N; `distracted`: `/focus` | none |
