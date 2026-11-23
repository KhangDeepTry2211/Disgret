# Feature Specification: Gret and the Living Sea

**Feature Branch**: `feature/003-gret-ocean`

**Created**: 2026-11-23

**Status**: Implemented (2026-11-24)

**Input**: User description: "Redesign DisGret for real users so the first launch is eye-catching,
in the spirit of the iOS app Brainrot (a cute mascot living in a world that reacts to your
behaviour) while keeping the DisGret brand. Add Gret, an original round sea creature, whose sea
clears when the user studies and turns murky when they get distracted. Part 1 of 6 covers Gret,
the living sea, the onboarding, Hôm nay, the focus session and the summary. Smooth effects in the
style of a reference farm app: hero illustration, health ring card, cards that appear in sequence.
Design approved in docs/superpowers/specs/2026-11-23-gret-ocean-redesign-design.md."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See how my study habits are doing at a glance (Priority: P1)

A student opens DisGret (scenarios S2 and S3). Before reading anything, they see Gret in a sea
scene. The water is clear and Gret is happy when they have been studying as planned; the water is
murky and Gret looks sad when they have skipped sessions or been distracted. A ring card shows the
sea clarity as a percentage next to the streak.

**Why this priority**: This is the core of the redesign: an emotional, immediate picture of the
user's own behaviour. In the reference app it is what users say keeps them going ("I don't want to
hurt him").

**Independent Test**: With sample data, open Hôm nay and confirm the sea, Gret's mood and the
clarity percentage match the expected value for that history; add a distraction event for today and
confirm the clarity drops and the scene updates when the app is shown again.

**Acceptance Scenarios**:

1. **Given** a new user with no history, **When** they open Hôm nay, **Then** the sea clarity is
   70% and Gret is happy.
2. **Given** a user who reached their planned focus minutes on each of the last 3 scheduled days,
   **When** they open Hôm nay, **Then** the clarity is at least 70% and Gret is happy.
3. **Given** a user who has not studied yet today, **When** they open Hôm nay, **Then** the clarity
   is not lower than yesterday's value.
4. **Given** a running session in which the user was distracted once, **When** they come back to
   DisGret, **Then** today's clarity is 5 points lower than before the distraction and the sea
   looks murkier.
5. **Given** a clarity below 40%, **When** the sea is shown, **Then** Gret looks sad (never hurt or
   injured) and a little floating litter is visible.
6. **Given** Hôm nay is shown, **When** the user taps Gret, **Then** Gret says a short encouraging
   line that matches its mood, and no session is started or opened.
7. **Given** Hôm nay is shown, **When** the user looks for a way into studying, **Then** there is
   still exactly one control that leads into a session (spec 001).

---

### User Story 2 - A first launch that makes me want to stay (Priority: P1)

A student installs DisGret and opens it for the first time (scenario S1). Onboarding plays like a
story: on four short pages Gret introduces itself and the app (scrolling clouds the sea, studying
clears it, Gret calls you back when you are pulled away), then asks the questions the app needs one
page at a time: reel length, the motivation quiz in Gret's thought bubble, which apps pull the user
away, and the first goal. Finishing ends on a short "your sea is ready" moment before Hôm nay
(amended 2026-11-23, design `docs/superpowers/specs/2026-11-23-story-onboarding-design.md`).

**Why this priority**: The user's main complaint is that the first screen is usable but not
attractive; a real user decides in the first minute whether to keep the app.

**Independent Test**: On a fresh install, go through onboarding to Hôm nay and confirm every page
shows Gret, the saved data are the same as before (reel length, quiz answers, first goal and habit)
plus the chosen apps, and Back still returns to the previous page.

**Acceptance Scenarios**:

1. **Given** a fresh install, **When** the app opens, **Then** the first story page shows the
   progress segments, the logo, the headline "Bớt lướt. / Học nhiều hơn.", Gret saying hello in the
   sea, "Bỏ qua" and one "Tiếp tục" button.
2. **Given** a story page, **When** the user waits 4 seconds, taps the right side or presses
   "Tiếp tục", **Then** the next page appears; tapping the left side goes back; holding pauses;
   "Bỏ qua" jumps to the first question.
3. **Given** the app-choice page, **When** it is shown, **Then** TikTok, YouTube, Instagram,
   Facebook and Chrome are offered with the apps already in the reminder list selected, and the
   final choice is saved to that list when onboarding completes.
4. **Given** a quiz step, **When** it is shown, **Then** the question appears in Gret's thought
   bubble and the answers are large tappable cards.
5. **Given** a quiz step, **When** the user picks an answer, **Then** Gret briefly reacts and the
   next step appears, as before.
6. **Given** the first-goal step is completed, **When** the user confirms, **Then** a short
   "Biển của bạn đã sẵn sàng" moment with a happy Gret is shown, followed by Hôm nay.
7. **Given** onboarding is reopened from Settings by a user who already has a goal, **When** they
   finish the questions, **Then** no goal is asked again or duplicated and Hôm nay opens.

---

### User Story 3 - Study next to Gret (Priority: P2)

During a focus session (scenarios S1 and S2), the session screen is the sea with Gret concentrating.
As focused minutes add up, the water visibly clears. During an intentional break Gret sleeps and the
remaining break time is shown.

**Why this priority**: Makes the time spent studying feel rewarding and shows, while it happens,
that studying heals the sea; less critical than the first two stories because the session already
works.

**Independent Test**: Start a 5-minute session in demo mode, confirm Gret is in its focused state
and the water clears as time passes; start a break and confirm Gret sleeps and the remaining break
time is shown; end the break and confirm Gret is focused again.

**Acceptance Scenarios**:

1. **Given** a running session, **When** the session screen is shown, **Then** it shows the habit
   name, the countdown, Gret concentrating in the sea, the real focused time and the number of
   distractions.
2. **Given** a running session, **When** focused minutes increase, **Then** the water becomes
   clearer towards the clarity today will reach.
3. **Given** an intentional break, **When** the session screen is shown, **Then** Gret sleeps, the
   text "Đang nghỉ – còn mm:ss" is shown with the "Tiếp tục" action.
4. **Given** a running session, **When** the user chooses "Kết thúc sớm", **Then** the existing
   confirmation and saving behaviour is unchanged.

---

### User Story 4 - Celebrate a finished session (Priority: P2)

When a session ends (scenario S3), the summary shows Gret celebrating and how much clearer the sea
became, and highlights the streak when it grew.

**Why this priority**: Closes the loop with a positive feeling; depends on the sea clarity of User
Story 1.

**Independent Test**: Finish a session that completes today's habit and confirm the summary shows a
celebrating Gret, a positive "+N%" clarity gain and a highlighted streak; the rating and save
behaviour are unchanged.

**Acceptance Scenarios**:

1. **Given** a finished session with focused time, **When** the summary opens, **Then** Gret
   celebrates and the clarity gain since the session started is shown as "+N%".
2. **Given** the session made the streak grow, **When** the summary opens, **Then** the streak
   indicator is highlighted.
3. **Given** a session with no focused time, **When** the summary opens, **Then** no gain is shown
   and Gret is not sad.

### Edge Cases

- No goal or no habit yet: Hôm nay shows the sea with a neutral Gret and the existing single
  invitation to create a goal or a habit.
- A day with nothing due and no session is a rest day: clarity does not change.
- Many distractions in one day: clarity never goes below 0; one good day always raises it.
- Clarity at 100: studying keeps it at 100 (no overflow).
- A session that crosses midnight counts for the day it started, as statistics already do.
- The device's "remove animations" accessibility setting is on: no looping animation runs; scenes
  and numbers show their final state immediately.
- Dark mode: the sea becomes a night sea with the same meaning (clarity, mood).
- Running on web during development: scenes render without the blurred or native-only parts and
  navigation still works.
- Data from previous versions (habits, logs, sessions, events) is used as-is; no stored data changes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST compute a sea clarity score from 0 to 100 from data that already
  exists (focus sessions, distraction events, habits due each day). It MUST NOT store new user data
  for this feature.
- **FR-002**: A user with no history MUST start at a clarity of 70.
- **FR-003**: For each past day, a day score from 0 to 1 MUST be computed as the minutes studied
  divided by that day's target minutes, capped at 1, minus 0.1 per distraction, floored at 0. The
  target is the sum of the daily minimum minutes of habits planned that day (25 when nothing was
  planned but the user studied). Minutes studied credit each habit up to its minimum: a habit
  ticked as done counts its full minimum, a two-minute version counts half, focus sessions count
  their real minutes. A day off (freeze) removes that habit from the day; habits done "N days a
  week" only count on the days they were done. A day with nothing planned and nothing studied
  MUST leave the clarity unchanged. *(Changed during implementation, 2026-11-23: counting only
  focus minutes made users who tick habits by hand see a murky sea despite keeping up.)*
- **FR-004**: The clarity after a past day MUST be the previous clarity × 0.7 + 30 × the day score.
- **FR-005**: Today's clarity MUST be max(yesterday, yesterday × 0.7 + 30 × today's score so far)
  minus 5 per distraction today, kept within 0–100, so that not having studied yet never lowers it
  and each distraction lowers it immediately.
- **FR-006**: Gret's mood MUST be happy at 70 or more, neutral from 40 to 69 and sad below 40;
  during a running session it MUST be "focused", during an intentional break "sleeping", and on the
  summary "celebrating".
- **FR-007**: The sea's colours MUST move between a clear brand blue/cyan and a murky grey-green
  with the clarity; below 40 some floating litter MUST appear; at 70 or more small fish MUST appear.
- **FR-008**: Gret MUST never be shown injured or in pain, and its lines MUST never blame the user.
- **FR-009**: Hôm nay MUST show, from top to bottom: the logo with a time-of-day greeting and the
  app name "DisGret", the sea scene with Gret, a clarity ring card and a streak card side by
  side, a compact goal card with the identity line, the next-session card with its change action,
  and the single start control. All spec 001 requirements for Hôm nay remain in force.
- **FR-010**: Tapping Gret on Hôm nay MUST show a short line chosen from a set that matches the
  current mood, and MUST NOT start or open a session.
- **FR-011**: Onboarding MUST keep its saved data and its save-at-the-end rule, and MUST present
  it as a story with Gret: four story pages (hello; scrolling clouds the sea; studying clears it;
  Gret calls you back), then one page per question (reel length, the four quiz questions in Gret's
  thought bubble with large answer cards and a short reaction, the apps that pull the user away,
  the first goal), and a closing "Biển của bạn đã sẵn sàng" moment of about 1.2 seconds before
  Hôm nay. Story pages advance after 4 seconds (not when animations are removed), on "Tiếp tục" or a
  tap, and can be skipped; question pages wait for an answer.
- **FR-011a**: The app question MUST offer TikTok, YouTube, Instagram, Facebook and Chrome,
  preselected from the current reminder list, and MUST save the choice to that list only (no new
  stored field); it is shown only where the reminder feature runs (Android).
- **FR-012**: The running-session screen MUST show the sea with Gret focusing, the habit name, the
  countdown ring, the real focused time and the distraction count; the water MUST clear as focused
  minutes increase; during a break Gret MUST sleep and the remaining break time MUST be shown.
- **FR-012a**: During a running session (not a break), a distraction (a reel, a notification or a
  message) MUST now and then drift towards Gret and pop as Gret bats it away, and coming back after
  a real distraction MUST burst a few away at once. The effect is decorative: it changes no data,
  takes no input, is hidden from screen readers and does not run with animations removed (added
  2026-11-23 at the project lead's request).
- **FR-013**: The summary MUST show Gret celebrating, the clarity gain since the session started as
  "+N%" (hidden when zero) and a highlighted streak when it grew; rating and saving are unchanged.
- **FR-014**: Cards on the redesigned screens MUST appear in sequence (fade in and rise slightly);
  numbers MUST count up; ring cards MUST fill; Gret MUST bob gently and blink; waves and bubbles
  MUST drift.
- **FR-015**: When the system's "remove animations" setting is on, no looping animation may run and
  all scenes and numbers MUST show their final state immediately.
- **FR-016**: Looping animations MUST stop while their screen is not visible.
- **FR-017**: Light mode MUST show a day sea and dark mode a night sea, with the same meaning.
- **FR-018**: Each sea scene MUST expose a text description for screen readers that states Gret's
  mood and the clarity percentage.
- **FR-019**: The DisGret name, logo, Ocean palette and typeface MUST be kept; card corners MUST
  become rounder across the whole app for a consistent look.
- **FR-020**: Gret's appearance MUST be built so that other species and outfits can be added later
  without changing how clarity or mood are decided.
- **FR-021**: All text on new or modified screens MUST be Vietnamese and come from the shared UI
  strings file (ADR-0005).
- **FR-022**: The motivation step, the Thói quen and Tiến độ tabs, Settings and the native
  intervention screen MUST keep their behaviour; they only receive the app-wide look changes.

### Key Entities

- **Sea clarity**: a number from 0 to 100 derived from the study history; has a value for today and
  for each past day; not stored.
- **Gret's mood**: one of happy, neutral, sad, focused, sleeping, celebrating; derived from the sea
  clarity and the session state.
- **Mascot**: the character shown in the sea; in this feature always Gret. Later features add other
  species and outfits.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user at 40% who reaches their planned minutes on 3 consecutive scheduled days is at
  70% or more on the fourth day.
- **SC-002**: After a distraction during a session, the lower clarity is visible within 1 second of
  returning to DisGret.
- **SC-003**: From a cold launch with a habit due, a session can still be running in at most 2 taps,
  and Hôm nay still contains exactly one control into a session.
- **SC-004**: In a hallway test with at least 5 students, at least 4 rate the first screen 4 or 5
  out of 5 for attractiveness, and at least 4 can explain what Gret's sea shows within 10 seconds.
- **SC-005**: On the team's Pixel emulator, the redesigned screens show no visible stutter while
  scrolling or switching tabs; with "remove animations" on, nothing loops.
- **SC-006**: 100% of data created by previous versions is still shown after upgrading (habits,
  logs, sessions, streak value unchanged).

## Assumptions

- The numbers in FR-002 to FR-005 are starting values; they may be tuned during implementation as
  long as the acceptance scenarios and SC-001 still hold.
- Minutes spent in blocked apps will lower the clarity in a later feature (part 2: Tiến độ
  insights and scroll time); this feature leaves room for that input but does not read it.
- The native intervention screen gets Gret in a later feature (part 3); until then it keeps its
  current look.
- Outfits, new mascots, pearls, sea themes, the sea farm, real-money purchases, the home-screen
  widget and reminders are later features (parts 4–6) described in the design document.
- Gret, the sea and its litter are original illustrations made for DisGret; nothing is copied from
  Brainrot or from the reference farm app.
- The motivation step's content and flow are defined by spec 002 and do not change here.
