# UI Contract: Navigation

## Tabs (bottom bar, in order)

| Index | Label | Route | Content |
|---|---|---|---|
| 0 | Hôm nay | `/today` | session plan, "Bắt đầu", change-plan action, small streak, settings icon |
| 1 | Thói quen | `/habits` | sub-views "Theo ngày" / "Tuần" / "Tổng thể", habit CRUD |
| 2 | Tiến độ | `/progress` | segments "Thói quen" (report) / "Phiên học" (statistics) |

## Full-screen routes (no tab bar)

| Route | Allowed when | Otherwise |
|---|---|---|
| `/motivation?context=start` | no session running | redirect to `/focus` if a session runs |
| `/motivation?context=distracted` | session running | redirect to `/today` |
| `/focus` | session running (incl. break) | redirect to `/today` |
| `/summary` | session finished (existing rule) | redirect to `/today` |
| `/onboarding`, `/settings`, `/quiz`, `/reset-break-permissions`, `/blocked-apps`, `/habit/:id`, `/habit-form`, `/my-habits` | unchanged | unchanged |

Removed routes: `/home`, `/reels`, `/report`, `/stats`, `/achievements`. Unknown paths go to
`/today`.

## Native action routing (`onNativeAction`, names unchanged)

| Action | Condition | Result |
|---|---|---|
| `intervention_shown` | any | count only (unchanged) |
| `resume_focus` | session running | go `/focus` |
| `open_reels_distracted` | session not finished | go `/motivation?context=distracted` |
| `break_started` | any | pause session (unchanged) |
| `break_ended` | session running | resume, go `/focus` |

In-app nudge choices (`askAfterDistraction`): keep studying → stay; watch reel →
`/motivation?context=distracted`; take break → break + `/focus`.

## Start actions (all go through StudyStarter)

| Control | Minutes |
|---|---|
| Motivation "Bỏ qua" | plan minutes |
| Motivation "Bắt đầu N phút" | plan minutes (N) |
| Motivation "Chỉ 5 phút thôi" | 5 |
| Hôm nay "Bắt đầu" while running | no start; go `/focus` |
