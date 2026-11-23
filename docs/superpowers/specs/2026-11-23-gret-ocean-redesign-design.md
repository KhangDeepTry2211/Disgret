# Design: "Gret's Sea" — redesigning DisGret for real users

- Date: 2026-11-23
- Status: approved by the project lead (2026-11-23); part 1 implemented as spec 003, part 4 (the
  pearl economy and Góc của Gret) as spec 004
- Base branch: `feature/003-gret-ocean`, split from `bim/feature/002-anti-reel-bounded-dose`
  (contains Bim's features 001 and 002, not yet merged into `master`)
- Language: first written in Vietnamese for the reviewer, translated to English before commit
  (constitution, principle VI).
- Later amendments: the onboarding became a story told by Gret
  (`2026-11-23-story-onboarding-design.md`); the wardrobe opens from a button in the Hôm nay
  header, not by tapping Gret, and the sea fills the top of Hôm nay (2026-11-24); pearls are earned
  only from focused minutes (`2026-11-23-gret-corner-design.md`, ADR-0009).

## 1. Intent and why

DisGret will be given to **real users** (high-school and university students, some under 18), not
only shown in the course demo. The current interface is easy to use but **not eye-catching from the
first launch**. The lead chose the direction of the iOS app *Brainrot: Screen Time Control*: **a
cute mascot living in a world that changes with the user's own behaviour**. Brainrot keeps users
(according to its App Store reviews) because they "don't want to hurt the mascot".

DisGret keeps its brand (name, navy/cyan D logo, Ocean palette, Be Vietnam Pro font) and changes the
feeling with:

- **Gret**: a round sea creature with big eyes, designed for DisGret (not a brain like Brainrot).
- **Gret's sea**: clear when the user studies regularly, murkier after distractions.
- Smooth effects in the style of the "My Farm" app the lead sent as a sample: a large illustrated
  scene at the top, a ring "health" card, stat cards, detail cards sliding up, cards appearing in
  sequence.

Every change still serves at least one of the team's scenarios: **S1** hard to start, **S2**
distracted mid-session, **S3** keeping it up for days.

## 2. Goals, non-goals, anti-goals

**Goals**
- The first launch makes an impression: the sea, Gret saying hello, large clear text.
- The user sees the consequence of their behaviour at once in the sea and Gret's face (S2, S3).
- Still exactly one way into a study session, still three tabs (Bim's ADR-0002).
- Later (parts 4–5): wardrobe, new mascots, themes, a sea farm, cosmetics sold for real money.

**Non-goals**
- Rebuilding the habit, schedule, streak or session logic: only how it is shown changes, plus the
  new "sea clarity" calculation.
- Changing Bim's motivation step (the bounded reel dose).
- iOS.

**Anti-goals** (shipping any of these is a failure even if it works)
- **Pay to win**: real money never buys pearls, streaks, sea clarity or study statistics.
- **Punishment spiral**: no pearls taken away, Gret is never "hurt" or in pain. Gret is only sad
  and the sea only murky, and there is always a quick way back.
- Dark patterns: fake discounts, countdowns pushing a purchase, features locked before a trial.
  These are what users criticise in Brainrot.
- More tabs, a feed or social features.
- Effects that make the app stutter on the emulator or slow phones.

## 3. Constraints

- Android, Flutter 3.47+ (the dev machine uses 3.50.1), Riverpod 3, go_router, Hive, data on the
  device only.
- The team rules (`.specify/memory/constitution.md`):
  - Colours, fonts, radii and spacing only from `lib/theme/app_theme.dart`.
  - Text of new or changed screens from `lib/l10n/app_strings.dart`.
  - Pure logic in `lib/data/` or `lib/services/` with unit tests; changed flows get widget tests.
  - New dependencies are justified in `plan.md`.
  - Architecture or privacy changes need an ADR.
  - `dart format`, `flutter analyze` and `flutter test` pass before merging.
- Part 4 (gamification) and part 5 (network for payments) **go against ADR-0004 and principle II**,
  so they need a new ADR approved by the lead first. Part 1 is not affected. (Part 4 was approved
  as ADR-0009; part 5 is still open.)
- The intervention screen is written in Kotlin with its own colours in `colors.xml`. Part 1 does not
  touch it, so it has no Gret yet.

## 4. Approaches considered

### 4.1 Visual direction (the lead chose A)

| Direction | Description | Trade-off |
|---|---|---|
| **A · Ocean mascot** ✅ | Gret and the sea reflect behaviour | Closest to what the lead likes in Brainrot; needs mascot art in several moods |
| B · Bold, no mascot | Strong colours, large block cards | More eye-catching than today but without a "soul" |
| C · Premium night sea | Polish the current look | Least change, least cute |

The lead chose A and asked to **keep the brand**.

### 4.2 How the art is made (the lead chose A)

| Approach | Trade-off |
|---|---|
| **A · Vector drawn in code/SVG by Claude** ✅ | Fast, consistent, easy layered outfits, light, editable. Flat cute style |
| B · Rive (like Duolingo) | Most beautiful and lively, but needs someone on the team who draws in Rive |
| C · Commissioned or AI-generated PNGs | Most detailed, but hard to keep many mascots and outfits consistent, little motion, heavy app |

The mascot's drawing is isolated behind `MascotView`; Rive or bitmap art can replace it later
without touching the logic.

### 4.3 Selling for real money (the lead chose one-off purchases)

| Approach | Trade-off |
|---|---|
| **One-off items, bought once, kept forever** ✅ | Simplest. Works offline after purchase; Google restores it on reinstall |
| Pearl packs | A balance and refunds to manage; breaks the meaning "pearls = study effort" |
| Plus subscription | Steady income but the most complex, usually needs a server |

## 5. Overall vision: six parts, one after another

Each part is its own spec (feature 003, 004…). The order is a proposal the lead may change.

| Part | Content | Scenarios | Settled |
|---|---|---|---|
| **1** | Gret and the living sea: onboarding, Hôm nay, focus session, summary (features 1, 5) | S1 S2 S3 | Details in section 6 (spec 003) |
| 2 | Progress: Gret "thinks" insights from the statistics, scroll time and the worst apps (features 3, 4) | S2 S3 | Rule-based insights, offline. Scroll time read through `UsageStatsManager` with the Usage access permission already granted (no new permission), added to the sea clarity rule |
| 3 | Intervention screen with a sad Gret and murky sea, asking "Do you really need … right now?" (feature 2) | S2 | Kotlin. Gret as a VectorDrawable, colours added to `colors.xml` |
| 4 | Pearls, wardrobe, new mascots, streak-unlocked themes, sea farm (feature 8 and the lead's additions) | S3 | See 5.1 (wardrobe, seas, mascots done as spec 004) |
| 5 | Selling cosmetics for real money with Google Play Billing | — | See 5.2 |
| 6 | Home-screen widget (Gret, streak, clarity; tap opens Hôm nay) and Gret's study reminders, joined with ADR-0006 (features 6, 7) | S1 S3 | |

### 5.1 Settled for part 4

- **Pearls** are earned only by studying. **Never taken away.** (Spec 004 settled the rule: one pearl
  per five focused minutes of a saved session.)
- **Wardrobe** without a new tab. Outfits by slot (head, eyes, neck, body, back). New mascots, for
  example a turtle, an octopus or a seahorse (spec 004: a hermit crab and an octopus). Unlocked with
  pearls or a streak milestone. (Opens from the Hôm nay header button, not by tapping Gret.)
- **Sea themes** unlock at streak milestones (spec 004: 3, 7 and 14 days, best streak ever).
- **Sea farm** (not built yet):
  - Each **goal is a plot** (seaweed bed, coral reef, pearl raft), each **habit a row**.
  - A row's "growth" is the habit's existing strength score. The parked 66-day milestone becomes
    **harvest** day.
  - The farm lives in the Thói quen tab; whether the tab is renamed is decided in its spec.
- An ADR brings part of ADR-0004 back (ADR-0009).

### 5.2 Settled for part 5

- **Cosmetics only**, one-off purchases kept forever: mascots, outfit packs, theme packs. Every item
  has a free path with pearls or a streak, or at least an equivalent free item.
- Never sell pearls, streaks or statistics.
- To prepare:
  - An ADR amending principle II: network allowed only for payments.
  - A privacy policy.
  - A Google Play Console account (owner not decided yet).
  - Compliance with the rules for users under 18, with a restore-purchases button.

## 6. Detailed design of part 1 — Gret and the living sea

### 6.1 Scope

| Screen or block | Change |
|---|---|
| Onboarding (`onboarding_screen.dart`, `quiz_question_view.dart`) | New look, same steps and logic (later amended into a story) |
| Hôm nay (`today_screen.dart`) | Sea with Gret, clarity card, layout per spec 001 |
| Focus (`focus_screen.dart`) | Full-screen sea, Gret focusing, or sleeping on a break |
| Summary (`summary_screen.dart`) | Gret celebrating, how much the sea cleared |
| Theme (`app_theme.dart`) | Tokens for the sea, Gret and motion; larger card radius |
| New | `lib/data/sea_clarity.dart` (pure logic), `lib/widgets/mascot/…`, `lib/widgets/sea/…`, `assets/mascot/…` |
| Unchanged | Motivation step, Thói quen, Tiến độ, Cài đặt (only the shared theme change), the Kotlin intervention screen |

### 6.2 Gret

- **Look**: round, slightly flat body in the brand cyan, triangular tail fin, lighter belly, big
  eyes, pink cheeks, small mouth, following the sketch from the discussion.
- **Personality**: says "mình" and calls the user "bạn". Always encouraging, never blaming or
  making the user feel guilty.
- **Moods** (`MascotMood`):
  - `happy`, `neutral`, `sad`: from the sea clarity.
  - `focused`: while a session runs.
  - `sleeping`: during an intentional break.
  - `celebrating`: on the summary.
- **Drawing**: SVG layers stacked on one fixed canvas (viewBox 240×200):
  - `body`
  - `eyes_<mood>`
  - `mouth_<mood>`
  - `cheeks`
  - Part 4 adds outfit layers.

  Every later species shares the canvas and anchor points so outfits fit without per-species art.
- **Widget**: `MascotView(species, mood, outfit, size)`. Part 1 has only `species = gret` and no
  `outfit`.
- **Idle motion**:
  - Bobbing up and down, about 2.4 s per cycle.
  - Random blinks 3–6 s apart.
  - `focused`: slow breathing.
  - `sleeping`: a rising "z".
- **Tapping Gret** (part 1): a short speech bubble chosen at random for the mood (about five lines
  per mood in `AppStrings`).
- **Colour exception**: illustrations (`assets/mascot/`, `assets/sea/`) carry their own colours in
  the SVG files. Their palette is recorded in `design-system.md` and uses only the Ocean brand
  colours and the existing pastel palette. The UI outside illustrations still takes colours only
  from `app_theme.dart`. The exception is recorded in an ADR (section 6.13).

### 6.3 Sea clarity (`SeaClarity`)

A pure calculation in `lib/data/sea_clarity.dart` with unit tests. It **stores nothing new**: it is
recomputed from existing data (sessions and habit logs, `session_distracted` events, habits due via
`habit_schedule.dart` and `minMinutesPerDay`). No migration, old data stays readable.

Rules:

1. **Scale 0–100.** A new user starts at **70** so Gret is not sad on day one.
2. **Each past day gets a day score** from 0 to 1:
   - Base = `min(1, credited minutes / the day's target minutes)`. The target is the sum of
     `minMinutesPerDay` of the habits due that day, or 25 when nothing was due but the user studied.
     (Amended during implementation: credited minutes come from habit logs — a tick counts the
     habit's minimum, the 2-minute version half of it, focus sessions their real minutes — so users
     who tick habits by hand are not shown a murky sea.)
   - Each distraction subtracts 0.1. The day score never goes below 0.
   - A day with nothing due and no study is **skipped**; clarity stays the same (like a streak rest
     day).
3. **Moving average**: `clarity = yesterday's clarity × 0.7 + 30 × day score`. The sea reacts within
   a few days, unlike the 66-day strength score.
4. **Today is live**:
   - Today's study minutes **only add**; not having studied yet subtracts nothing (like the
     strength score).
   - Each distraction today **subtracts 5 at once**, so the user sees the consequence on return
     (S2).
   - Starting formula: `today = max(yesterday, yesterday × 0.7 + 30 × today's base score) − 5 ×
     distractions today`, kept within 0–100.
   - A session crossing midnight counts for the day it started, as statistics already do.
5. Part 2 will add **minutes spent in blocked apps** (for example −1 per 10 minutes). Part 1 leaves
   room for this parameter.
6. **Mood mapping**: 70 and above `happy`, 40–69 `neutral`, below 40 `sad`. The session states
   (`focused`, `sleeping`) and the summary (`celebrating`) take precedence.

These numbers are a **starting point**; the builder tunes them with tests until the sea "feels
right". For example: three full study days take the sea from 40 to above 70, and one session with
three distractions does not take a clear sea down to `sad`.

### 6.4 The sea (`SeaScene`)

- **Drawn with `CustomPainter`** because it moves and changes colour: three slow waves out of phase,
  seaweed on the floor, rising bubbles, Gret in the middle.
- **Water colour follows clarity**: clear is the brand cyan/sea blue, murky a grey moss green.
  `AppSea` tokens in `app_theme.dart`.
  - Below 40: a few pieces of litter (bottle, bag) and few bubbles.
  - 70 and above: small fish and many bubbles.
- **Light/dark**: light mode has a pale blue sky. Dark mode is a "night sea": sky `#06090F` with a
  moon, darker water, Gret keeps her colours slightly softened.
- **Size variants**: `hero` about 200 high on Hôm nay, `full` filling the focus screen, `compact`
  for onboarding and the summary. (Since 2026-11-24 Hôm nay uses a full-bleed `full` sea.)
- **Flat colours per layer**, in the spirit of "no decorative gradients". A dark overlay only where
  needed for readable text, as before.

### 6.5 Onboarding

Same steps (intro with reel length → 4-question quiz → first goal), new look:

1. **Intro**:
   - Logo and "DisGret" at the top.
   - Large headline "Bớt lướt. / Học nhiều hơn." (second line in primary).
   - One sentence, Gret's speech bubble introducing herself, a `compact` sea.
   - Reel length as three large pills. "Tiếp tục" in primary.
2. **Quiz**:
   - Small Gret at the top, the question in a **thought bubble** (small dots leading down to Gret).
   - Answers are large rounded cards with an icon. Step dots.
   - Picking an answer changes Gret's face briefly.
3. **First goal**: Gret says "Đặt mục tiêu đầu tiên nhé", fields restyled with the new theme.
4. **Finish**: a short transition (about 1.2 s) "Biển của bạn đã sẵn sàng" with a happy Gret, then
   Hôm nay.

(Amended: the onboarding is now a story of four pages followed by one page per question,
including "App nào hay kéo bạn đi nhất?".)

### 6.6 Hôm nay

Still follows spec 001: goal, next habit, minutes, a small streak and **exactly one** control into a
session; no habit list or strength details. Top to bottom:

1. **Header**: logo, greeting by time ("Chào buổi sáng/chiều/tối") and the title. Settings button
   unchanged (FR-015). (Implemented with the app name "DisGret" as the title.)
2. **The `hero` sea** with Gret, mood from clarity. Tap Gret to talk (6.2).
3. **Two cards side by side**:
   - Clarity: a small ring, the percentage and "Biển trong / Hơi đục / Đục".
   - Streak: a flame icon and "N ngày", replacing the current 96 `StreakRing`.
4. **Compact goal card**: goal and "Tôi là người…".
5. **"Học tiếp" card**: habit, minutes, "Đổi thói quen hoặc thời lượng"; `session_plan_sheet`
   unchanged.
6. **"Bắt đầu"** in primary, or the secondary "Học thêm một phiên" (current logic).
7. Bim's **running-session strip** unchanged.

Empty states (no goal or no habit yet): the sea with a `neutral` Gret and an invitation to create a
goal or habit.

### 6.7 Focus (running session)

- **`full` sea** as the background, Gret `focused`.
- The habit name at the top; the countdown ring in the middle (`ProgressRing`, thicker and rounder),
  Gret below it.
- **The water clears with focused minutes**, previewing the clarity today will reach.
- "Tập trung thực" and "Số lần xao nhãng" become two small cards.
- **On a break**: Gret `sleeping`, "Đang nghỉ – còn mm:ss", "Tiếp tục".
- Outlined "Kết thúc sớm" unchanged.
- The setup view keeps its logic and only gets the theme change.

(Added at the lead's request: distractions drift towards Gret and Gret bats them away.)

### 6.8 Summary

- Gret `celebrating` (jumping with a few bubbles).
- "+N% độ trong" counting up.
- If this session grew the streak, the flame "pops".
- Rating and Save unchanged.

(Spec 004 adds "+N ngọc trai".)

### 6.9 Motion

| Effect | Where | Suggested values |
|---|---|---|
| Cards appear in sequence (fade in, rise 12 dp) | Hôm nay, onboarding, summary | 280 ms, 60 ms apart, easeOutCubic |
| Numbers count up | Clarity, streak, "+N%" | 600 ms |
| Ring fills | Clarity card | 700 ms |
| Gret bobs and blinks; waves drift; bubbles rise | Every sea | Looping |
| Water colour changes with clarity | Every sea | 800 ms |
| Gret's face reacts to a quiz answer | Onboarding | 400 ms |

- **Use Flutter's built-in animation APIs**, no `flutter_animate`, to keep dependencies few. If the
  code grows too long the builder may propose a library in `plan.md`.
- **Respect "reduced motion"**: with `MediaQuery.disableAnimations` every loop stops and the end
  state shows at once.
- Loops stop when the screen is not visible (`TickerMode`); seas are wrapped in `RepaintBoundary`.

### 6.10 Design-system changes

- **Radius**: `AppRadius.card` from 12 to **16** app-wide for consistency; `AppRadius.hero = 24` for
  the sea frame. Pill buttons unchanged.
- **New tokens**:
  - `AppSea`: clear/murky water, day/night sky, sand, seaweed, litter.
  - `AppMascot`: Gret sizes per variant.
  - `AppMotion`: durations and curves of 6.9.
- `docs/architecture/design-system.md`: translate edited sections to English (team rule), add
  "Gret and the living sea", record the illustration colour exception.
- Tab bar, cards and buttons keep the current Ocean colours.

### 6.11 Text (AppStrings)

- All new sentences in `lib/l10n/app_strings.dart`: Gret's lines per mood, clarity labels, greetings,
  "Biển của bạn đã sẵn sàng".
- Tone: short, friendly, never blaming. For example:
  - Happy: "Biển trong veo luôn! Hôm nay mình bơi được xa ghê."
  - Sad: "Biển hơi đục rồi… Học 5 phút với mình nhé?"

### 6.12 Testing

- **Unit tests for `sea_clarity.dart`**:
  - New user (70), rest day, full day, partial day.
  - A distraction today subtracts at once; not having studied yet subtracts nothing.
  - Ceiling 100, floor 0, mood mapping.
- **Widget tests**:
  - Hôm nay still has exactly one session control and shows the sea and clarity card; update the
    existing spec 001 tests.
  - The running session shows Gret focusing, and sleeping on a break.
  - Onboarding still goes through all steps and saves.
  - With reduced motion there is no looping animation.
- **Manual check on the Pixel emulator**: smooth sea, no stutter when switching tabs. Light and dark
  screenshots of onboarding, Hôm nay, focus and summary.

### 6.13 Docs and ADR

- **ADR-0008 "Gret and the sea clarity are emotional feedback"**:
  - Why this is not the gamification parked by ADR-0004: no points, no levels; it serves S2/S3.
  - The illustration colour exception.
  - New dependency `flutter_svg` to show the SVG layers; maintained by the Flutter team; the
    alternative is plain `CustomPainter`, which is harder to draw and for others to edit.
- **README**: update the demo script (new onboarding, the sea murking after a distraction) and the
  decomposition map with the new code "5.3 Gret và biển sống".
- **When starting**: run `/speckit-specify` with this document as input → `plan` → `tasks`, as the
  team process requires.

## 7. Decisions I made (for the lead to check)

1. The mascot is **Gret**, a round cyan sea creature who says "mình – bạn".
2. "Keep the brand" means keeping the name, logo, Ocean palette and font. Primary actions in brand
   blue; warm colours only for streaks and rewards.
3. The farm is a **sea farm** (seaweed beds, coral reefs, pearl rafts), not a land farm.
4. Pearls are never taken away. Real money buys only cosmetics.
5. The sea clarity rule and starting numbers in 6.3.
6. Card radius 16 app-wide.
7. No `flutter_animate`; add `flutter_svg`.
8. The order of the six parts in section 5.
9. The Kotlin intervention screen gets Gret only in part 3.

## 8. Left to the builder

- The exact SVG strokes of Gret and the sea, following the sketch and palette.
- Exact animation values within the ranges of 6.9.
- Tuning the clarity numbers with tests.
- File structure inside `lib/widgets/mascot/` and `lib/widgets/sea/`.
- Gret's exact lines (in the tone of 6.11).
