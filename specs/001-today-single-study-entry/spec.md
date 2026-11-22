# Feature Specification: Today Screen, Three-Tab Navigation and a Single Study Entry

**Feature Branch**: `feature/001-today-single-study-entry`

**Created**: 2026-11-22

**Status**: Draft

**Input**: User description: "Restructure navigation to three tabs (Hôm nay / Thói quen / Tiến độ).
Hôm nay answers only 'what do I study now, and for how long': one goal, one start button, a small
streak. One way into studying: Bắt đầu → short motivation (skippable) → Focus. Focus and motivation
leave the tab bar. Progress (report + statistics) moves into Tiến độ. Hide achievements, the heat map
and the 66-day journey from the UI (ADR-0002, ADR-0004)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Start studying from Hôm nay in one obvious path (Priority: P1)

A student opens DisGret at the time they planned to study (scenario S1, hard to start). The first
screen tells them what to study now and for how long, and offers one start button. Pressing it
leads through a short, skippable motivation step into a running focus session.

**Why this priority**: S1 is the core problem ("khó bắt đầu"); two competing start buttons and a
crowded home screen are the main causes of confusion identified in discovery (V2).

**Independent Test**: With one goal and one habit due today, launch the app, press "Bắt đầu", skip
motivation, and confirm a focus session is running for that habit; no other entry into a session
is visible on the home screen.

**Acceptance Scenarios**:

1. **Given** a goal and at least one habit due and not yet done today, **When** the user opens the
   app, **Then** Hôm nay shows the goal, the habit to study next, its planned duration, a small
   streak indicator and exactly one primary start button.
2. **Given** Hôm nay is shown, **When** the user presses "Bắt đầu", **Then** the motivation step
   opens full screen (no tab bar).
3. **Given** the motivation step is open, **When** the user chooses "Bỏ qua", **Then** a focus
   session starts immediately for the habit shown on Hôm nay, without passing through a setup
   screen.
4. **Given** the motivation step is open, **When** the user chooses "Bắt đầu N phút", **Then** a
   focus session starts with the planned duration N shown on Hôm nay; **When** they choose "Chỉ 5
   phút thôi", **Then** a 5-minute session starts for the same habit.
5. **Given** Hôm nay is shown, **When** the user wants a different habit or duration, **Then** they
   can change it from Hôm nay before starting, and the start button then uses that choice.
6. **Given** a session finishes, **When** the summary is closed, **Then** the user returns to Hôm
   nay, and the streak indicator reflects the completed day.

---

### User Story 2 - Always find the way back to a running session (Priority: P1)

A student in a running session leaves DisGret, opens a blocked app, and the intervention appears
(scenario S2). Whatever they choose, and whichever screen of DisGret they later open, they can get
back to the running session in one step.

**Why this priority**: Moving Focus out of the tab bar must not make a running session hard to
reach; S2 outcomes (returning on time) depend on it.

**Independent Test**: Start a session, navigate to Thói quen and Tiến độ, and confirm a visible
"return to session" affordance on each tab leads back to the running session; trigger the
intervention's "Quay lại học" and confirm the session screen opens.

**Acceptance Scenarios**:

1. **Given** a session is running, **When** the user is on any of the three tabs, **Then** a
   persistent banner shows the session is running and returns to it in one tap.
2. **Given** a session is running, **When** the user chooses "Quay lại học" on the intervention
   screen, **Then** DisGret opens on the running session.
3. **Given** a session is running, **When** the user chooses "Xem 1 reel động lực" on the
   intervention screen, **Then** DisGret opens the motivation step in its after-distraction form.
4. **Given** a session is on a break, **When** the break ends, **Then** DisGret shows the running
   session again.
5. **Given** a session is running, **When** the user presses "Bắt đầu" on Hôm nay, **Then** no
   second session is created; the user is taken to the running session.

---

### User Story 3 - See progress in one place (Priority: P2)

A student in their second or third week (scenario S3) wants to see whether they are keeping up.
The Tiến độ tab gathers the habit report and the study statistics that were previously spread
across the Habits app bar and Settings.

**Why this priority**: Supports S3 and gives the R4.3 comparison card (separate spec) a home, but
the start flow matters more for the 2026-11-24 hand-off.

**Independent Test**: Open Tiến độ and confirm both the habit report (completion, streak, charts by
period) and study statistics (focus minutes, Reset Break choices, motivation views) are reachable
there, and no longer from the Habits app bar or Settings.

**Acceptance Scenarios**:

1. **Given** any data state, **When** the user opens Tiến độ, **Then** they can switch between a
   habit report view and a study statistics view.
2. **Given** the user opens Thói quen or Cài đặt, **When** they look for the report or statistics,
   **Then** those entries are no longer there.
3. **Given** there is no history yet, **When** the user opens Tiến độ, **Then** an empty state
   explains that progress appears after the first session.

---

### User Story 4 - Out-of-MVP features no longer compete for attention (Priority: P3)

Achievements (9 levels), the heat map, and the 66-day journey badges are hidden so that the main
path stays focused (ADR-0004).

**Why this priority**: Reduces clutter, but the app is usable without it.

**Independent Test**: Search every screen and menu for achievements, the heat map and journey
badges and confirm none is reachable; complete enough habits to cross an achievement threshold and
confirm no level-up dialog appears.

**Acceptance Scenarios**:

1. **Given** any screen, **When** the user explores menus and cards, **Then** no entry leads to
   achievements, the heat map or the 66-day journey.
2. **Given** the user crosses an achievement threshold, **When** the day is completed, **Then** no
   level-up dialog is shown.
3. **Given** a device with data from the previous version, **When** the new version starts,
   **Then** all habits, logs, sessions and streaks are intact.

### Edge Cases

- No goal yet (fresh install after onboarding was skipped or goal deleted): Hôm nay shows a single
  call to create a goal; the start button is not shown.
- Goal exists but no habit: Hôm nay shows a single call to add a habit.
- Every habit due today is done: Hôm nay says today is complete and still allows an extra session
  for the first habit, as a secondary action.
- No habit is due today (rest day by schedule): Hôm nay says so and allows an optional session.
- Several goals: Hôm nay shows the same goal the current version treats as today's goal.
- A session finished while the app was in the background: opening the app shows the summary first.
- Running on web during development: native-only items (intervention, blocked apps) stay hidden and
  navigation still works.

## Clarifications

### Session 2026-11-22

- Q: Which duration does the motivation step's start action use? → A: Primary action uses the
  planned duration from Hôm nay; a secondary "Chỉ 5 phút thôi" action starts a 5-minute session.
- Q: Label of the Thói quen tab's "Hôm nay" sub-view? → A: Rename to "Theo ngày".

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The bottom tab bar MUST contain exactly three tabs, in this order: Hôm nay, Thói
  quen, Tiến độ. There MUST be no Reels tab and no Focus tab.
- **FR-002**: Hôm nay MUST show: today's goal, the next habit to study (the first habit due and not
  yet done, else the first habit), its planned duration, a small streak indicator, and one primary
  "Bắt đầu" button. It MUST NOT show the full list of today's habits or habit strength details.
- **FR-003**: Hôm nay MUST let the user change the habit and duration for the next session before
  starting; the choice applies only to that session.
- **FR-004**: "Bắt đầu" MUST open the motivation step in its before-session form. No other control
  on Hôm nay may start or open a focus session.
- **FR-005**: The motivation step, the focus session and the session summary MUST be shown full
  screen, without the tab bar.
- **FR-006**: Skipping the motivation step MUST start the session immediately with the habit and
  duration shown on Hôm nay.
- **FR-007**: The motivation step MUST offer a primary start action labelled with, and using, the
  planned duration shown on Hôm nay (for example "Bắt đầu 25 phút"), and a secondary "Chỉ 5 phút
  thôi" action that starts a 5-minute small-step session for the same habit.
- **FR-008**: While a session is running or on a break, each tab MUST show a persistent banner that
  shows the habit name and the remaining time (or "Đang nghỉ" during a break) and opens the running
  session in one tap; "Bắt đầu" MUST open the running session instead of creating a new one.
- **FR-009**: Intervention outcomes MUST route as follows: "Quay lại học" and break end → running
  session; "Xem 1 reel động lực" → motivation step in its after-distraction form.
- **FR-010**: The session clock MUST pause while the motivation step is open during a session and
  resume when it closes, as it currently does on the Reels tab.
- **FR-011**: Closing the summary MUST return to Hôm nay.
- **FR-012**: Tiến độ MUST contain the existing habit report and the existing study statistics,
  switchable within the tab. The report entry MUST be removed from the Thói quen app bar and the
  statistics entry from Cài đặt.
- **FR-013**: The Thói quen tab MUST keep habit management (daily, weekly and overall views, create,
  edit, archive). Its sub-views MUST be labelled "Theo ngày", "Tuần" and "Tổng thể", so that no
  sub-view shares the name of a main tab.
- **FR-014**: Achievements, the heat map, the 66-day journey badges and the level-up dialog MUST
  NOT be reachable or shown anywhere in the UI.
- **FR-015**: Settings MUST remain reachable from Hôm nay and keep its other entries (motivation
  quiz, Reset Break permissions, blocked apps, demo mode, sample data).
- **FR-016**: All data stored by the previous version MUST remain readable and unchanged by this
  feature.
- **FR-017**: All text on new or modified screens MUST be Vietnamese and come from the shared UI
  strings file (ADR-0005).

### Key Entities

- **Today's plan**: the goal, habit and duration proposed for the next session; derived from
  existing goals, habits and logs; the user's override lasts for one session only.
- **Running session**: the existing focus session state (running, on break, finished); used to
  decide whether "Bắt đầu" starts or resumes, and whether the banner is shown.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: From a cold app launch with a habit due, a user can have a session running in at most
  2 taps ("Bắt đầu", then "Bỏ qua" or the start action).
- **SC-002**: Hôm nay contains exactly one control that leads into a session.
- **SC-003**: From any tab, a running session is reachable in 1 tap.
- **SC-004**: 0 entry points to Reels-as-a-tab, achievements, the heat map or the 66-day journey
  remain in the UI.
- **SC-005**: 100% of data created by the previous version is still shown after upgrading (habits,
  logs, sessions, streak value unchanged).
- **SC-006**: In the team's hallway test on 2026-11-24, every tester can say what Hôm nay asks them
  to do within 5 seconds of opening it.

## Assumptions

- The motivation step's own content and behaviour (bounded dose, no social features) is defined in
  spec 002; this spec only fixes where it sits in the flow. Until 002 lands, the existing reel
  content may be shown full screen.
- "Today's goal" and "next habit" keep the current selection rules (first goal; first habit due and
  not done, else first habit).
- Tiến độ reuses the current report and statistics content; the R4.3 comparison card is a separate,
  lower-priority spec.
- Removing the social statistics row ("Reel đã thích") is handled in spec 002.
- Reset Break behaviour on the native side is unchanged; only the screens it opens change.
