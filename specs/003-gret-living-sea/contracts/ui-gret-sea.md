# UI Contract: Gret and the Living Sea (003)

Routes and navigation are unchanged from spec 001 (`contracts/navigation.md` of 001). This contract
fixes the widgets other features may rely on and what each redesigned screen must contain.

## Reusable widgets

| Widget | File | Contract |
|---|---|---|
| `MascotView({species = gret, required mood, double size})` | `lib/widgets/mascot/mascot_view.dart` | Draws the mascot layers for the mood; bobs and blinks unless animations are disabled; `onTap` optional; exposes no clarity logic |
| `SeaScene({required clarity, required mood, variant, onMascotTap})` | `lib/widgets/sea/sea_scene.dart` | Sky, waves, sand, seaweed, bubbles; fish at ≥ 70, litter at < 40; water colour follows clarity; contains a `MascotView`; `Semantics(label: "Gret <mood>. Biển trong <n>%")` |
| `SpeechBubble` / `ThoughtBubble` | `lib/widgets/mascot/mascot_bubbles.dart` | Rounded bubble with a tail (speech) or trailing dots (thought) |
| `ClarityCard({required clarity})` | `lib/widgets/sea/clarity_card.dart` | Ring that fills to the clarity, percentage counting up, label Biển trong / Hơi đục / Đục |
| `StreakCard({required days, bool highlight})` | `lib/widgets/streak_card.dart` | Flame icon and "N ngày"; `highlight` pulses once |
| `StaggeredEntrance({required children})` | `lib/widgets/motion/staggered_entrance.dart` | Children fade in and rise 12 dp in order (280 ms, 60 ms step); end state immediately when animations are disabled |
| `CountUpText({required value, String Function(int) format})` | `lib/widgets/motion/count_up_text.dart` | Counts from the previous to the new value in 600 ms |

## Screens

### Hôm nay (`today_screen.dart`)

Top to bottom (FR-009): `SeaScene(variant: full)` filling the top 46% of the screen behind a
transparent header (logo, greeting by time of day, app name "DisGret", the Góc của Gret pill of
spec 004, settings) → a sheet with rounded top corners overlapping the sea holding the row
[`ClarityCard`, `StreakCard`] → goal card (title + identity) →
next-session card (habit, minutes, change action) → single start control. Empty states keep their
single call to action and show a full-bleed `SeaScene` with a neutral Gret. Tapping Gret shows a
`SpeechBubble` with a line for the mood for 3 s, just below the header so nothing covers it
(amended 2026-11-24 at the lead's request).

### Onboarding (`onboarding_screen.dart`, `quiz_question_view.dart`)

A story told by Gret (amended 2026-11-23, design
`docs/superpowers/specs/2026-11-23-story-onboarding-design.md`). One screen with an ordered list of
pages; data are saved only when the last page is confirmed.

- Frame: progress segments (one per page, key `story-progress`); "Bỏ qua" on story pages jumps to
  the first question; system Back goes one page back (leaves the app on page 1).
- Story pages 1–4 share one `SeaScene(variant: full)` so the water changes in place: hello (logo,
  "DisGret", headline "Bớt lướt. / Học nhiều hơn.", clear, happy) → scrolling (murky with litter,
  sad) → studying (clear, happy) → "I'll call you back" (clear, focused). Gret's line is a
  `SpeechBubble`. A page turns after 4 s (`AppMotion.storyPage`), on "Tiếp tục" or a tap on the
  right two thirds; the left third goes back; holding pauses. No auto-turn when animations are
  removed.
- Reel length: Gret asks in a `ThoughtBubble`, three large pills, "Quay lại" / "Tiếp tục".
- Quiz: small `MascotView` + `ThoughtBubble` with the question, answer cards (icon, label), step
  dots; on answer Gret shows `happy` for 400 ms before the next step (the answer goes through at
  once when animations are removed; taps during the reaction are ignored).
- Apps (Android only): "App nào hay kéo bạn đi nhất?", `FilterChip`s from
  `BlockedAppsRepository.onboardingApps`, preselected from `blockedAppsProvider`; saved with
  `BlockedAppsNotifier.replaceAll` at the end. Its button reads "Vào DisGret" when it is the last
  page (replay with a goal).
- Goal: Gret `SpeechBubble` "Đặt mục tiêu đầu tiên nhé", existing fields; only without a goal.
- Finish: "Biển của bạn đã sẵn sàng" with `SeaScene(variant: compact)` and a happy Gret for about
  1.2 s, then `/today`. Everything is saved before the moment. It is skipped when no first goal
  was created (replay from Settings) and when animations are removed (FR-015).

### Focus running (`focus_screen.dart`)

`SeaScene(variant: full)` fills the screen above two stat cards (Tập trung thực, Số lần xao
nhãng) and the buttons ("Tiếp tục" during a break, outlined "Kết thúc sớm"). Its sky holds the
habit name and the countdown ring (size: 42% of the scene height, 140–220). Clarity and mood come
from `seaStateProvider` (focused while running, sleeping on a break). `DistractionSwatLayer`
(foreground) sends a distraction towards Gret every 12 s and bursts three away when the
distraction count rises; each swat bumps `SeaScene.gretReaction`, which wiggles Gret
(`ReactionWiggle`). Nothing moves with animations removed. The setup view keeps its layout.

### Summary (`summary_screen.dart`)

`SeaScene(variant: compact, mood: celebrating)`, "+N% độ trong" with `CountUpText` (hidden when
N ≤ 0), `StreakCard(highlight: streakGrew)`, existing rating, note and save.

## Strings (`lib/l10n/app_strings.dart`)

New keys: greetings (morning < 11:00, afternoon < 18:00, evening), `seaTitle`, clarity labels,
`gretIntro`, `gretGoalPrompt`, `seaReady`, `clarityGain(n)`, and five Gret lines per mood
(`gretLines(MascotMood)`), all Vietnamese, encouraging, never blaming.
