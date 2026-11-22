# Feature Specification: Anti-reel Motivation as a Bounded Dose

**Feature Branch**: `feature/002-anti-reel-bounded-dose`

**Created**: 2026-11-22

**Status**: Draft

**Input**: User description: "Redesign anti-reel reels so a reel is a dose of motivation with an
end, not a feed. No vertical swiping, no likes, comments or share. At most 3 reels before a
session, exactly 1 after a distraction. Each reel plays once, then an end card leads straight into
studying. Keep personalisation by motivation profile. Measure whether the user starts studying or
skips (ADR-0003, hypothesis H1)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A short, finite boost before studying (Priority: P1)

Before a session (scenario S1), the student sees at most three short motivation videos chosen for
their motivation profile. Each one plays once and stops on an end card that invites them to start
studying. There is nothing to scroll through and nothing to like or comment on.

**Why this priority**: The current feed copies doomscrolling, which the team rated a High risk and
which undermines hypothesis H1 (the right reel helps the user start faster).

**Independent Test**: From Hôm nay press "Bắt đầu"; confirm one reel plays, cannot be swiped away,
does not loop, ends on a card with a start action, and that after the last reel the only ways
forward are starting a session or leaving.

**Acceptance Scenarios**:

1. **Given** the motivation step opens before a session, **When** it loads, **Then** it shows the
   first reel of a playlist of at most 3, chosen by the existing personalisation rules, with a
   visible position indicator (for example "1/3").
2. **Given** a reel is playing, **When** the user swipes vertically or horizontally, **Then**
   nothing changes; the reel keeps playing.
3. **Given** a reel reaches its end, **When** it stops, **Then** it does not restart; an end card
   shows the start action and, if more reels remain, a "Tiếp" action.
4. **Given** the end card of a non-final reel, **When** the user chooses "Tiếp", **Then** the next
   reel plays.
5. **Given** the end card of the final reel, **When** it is shown, **Then** the only actions are
   the start action and leaving the step; no further reel is offered.
6. **Given** any moment of the before-session step, **When** the user chooses "Bỏ qua", **Then**
   the step closes and the session starts as defined in spec 001. (The after-distraction step has
   no "Bỏ qua"; see User Story 2.)
7. **Given** a reel is playing, **When** the user taps it, **Then** it pauses or resumes
   immediately.

---

### User Story 2 - One reel to get back on track after a distraction (Priority: P1)

During a session, the student opened a blocked app and chose "Xem 1 reel động lực" on the
intervention screen (scenario S2). DisGret shows exactly one reel, the one pinned for distraction
when available, then sends them back to the running session.

**Why this priority**: S2 outcomes (returning to study on time) are measured criteria; an open feed
at this moment would defeat the intervention.

**Independent Test**: Start a session, trigger "Xem 1 reel động lực", confirm exactly one reel plays
once and its end card offers only "Quay lại học", which returns to the running session.

**Acceptance Scenarios**:

1. **Given** a running session and the after-distraction context, **When** the step opens,
   **Then** exactly one reel is shown, the pinned after-distraction reel if one exists.
2. **Given** that reel ends or the user leaves early, **When** they choose "Quay lại học",
   **Then** the running session is shown and its clock resumes.
3. **Given** the after-distraction step, **When** it is shown, **Then** no "Tiếp" action and no
   second reel are offered.

---

### User Story 3 - The team can measure whether reels help users start (Priority: P2)

The team needs evidence for H1: how often a reel is followed by a session start, how much of each
reel is watched, and how often the step is skipped.

**Why this priority**: Required for the later experiment, but invisible to users.

**Independent Test**: Run the step three times (watch and start, skip immediately, watch and leave)
and confirm three distinguishable records exist in the on-device event log.

**Acceptance Scenarios**:

1. **Given** a reel is shown, **When** the user moves on (start, next, skip or leave), **Then** a
   watch record is stored with the reel, seconds watched, whether it was watched to the end, and
   whether a session started from it.
2. **Given** the step opens, **When** the user skips before any reel ends, **Then** a skip record is
   stored with the context and the position at which they skipped.
3. **Given** the statistics view in Tiến độ, **When** opened, **Then** it shows the number of reels
   watched and the share followed by a session start, and no longer shows "Reel đã thích".

---

### User Story 4 - Social features are gone without harming existing data (Priority: P3)

Likes, comments and sharing are removed entirely. Devices that used the previous version keep
working and keep all other data.

**Why this priority**: Required by the anti-reel principle, but a smaller user-visible change once
stories 1–2 replace the feed.

**Independent Test**: Install the previous version, like and comment on reels, upgrade, and confirm
the app starts normally, no social control or count is visible anywhere, and habits, sessions and
events are intact.

**Acceptance Scenarios**:

1. **Given** any screen, **When** the user looks for like, comment or share controls related to
   reels, **Then** none exists.
2. **Given** a device with likes and comments from the previous version, **When** the new version
   starts, **Then** it starts without errors and all non-social data is intact.
3. **Given** past likes, **When** reels are chosen for the playlist, **Then** likes no longer
   influence the choice.

### Edge Cases

- No reel matches the context: the step is skipped automatically and the session starts (before a
  session) or the running session is shown (after a distraction).
- A video fails to load or play: its end card is shown at once with the same actions, and the watch
  record notes zero seconds.
- The app goes to the background while a reel plays: playback pauses; on return the reel is paused
  on the same frame and the record is kept, not duplicated.
- The user presses system Back: before a session it returns to Hôm nay without starting; after a
  distraction it returns to the running session.
- Fewer than three reels are eligible before a session: the playlist is shorter and the indicator
  reflects the real count.
- Development on web: videos play without the blurred background; behaviour is otherwise the same.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The motivation step MUST present reels one at a time with no swipe-to-next gesture
  and no scrollable list of reels.
- **FR-002**: Before a session, the playlist MUST contain at most 3 reels; after a distraction,
  exactly 1. Selection MUST use the existing personalisation rules (motivation-profile tags,
  recently-watched penalty, pinned reels first) minus the liked-tags rule.
- **FR-003**: Each reel MUST play once and MUST NOT loop or auto-advance to another reel.
- **FR-004**: When a reel ends, an end card MUST appear. Before a session it shows the primary
  "Bắt đầu N phút" (planned duration) and the secondary "Chỉ 5 phút thôi" (spec 001 FR-007), plus
  "Tiếp" only when another reel remains. After a distraction it shows only "Quay lại học".
- **FR-005**: "Bỏ qua" MUST be available at all times before a session and MUST lead to the session
  start defined in spec 001.
- **FR-006**: Tapping a playing reel MUST toggle pause and play without delay.
- **FR-007**: The step MUST show the reel's title and position in the playlist; it MUST NOT show
  like, comment or share controls, counts, or any social element.
- **FR-008**: The app MUST record, for each reel shown: reel, context, seconds watched, watched to
  the end or not, and whether a session started from it. It MUST record a skip with its context and
  playlist position. Records stay on the device.
- **FR-009**: All like, comment and share features and their stored-data readers MUST be removed
  from the app; data they stored on the device MUST be left untouched and never read.
- **FR-010**: The statistics view MUST drop the "Reel đã thích" row and MUST keep reels watched and
  the share followed by a session start.
- **FR-011**: While the step is open during a running session, the session clock MUST be paused,
  and it MUST resume when the step closes.
- **FR-012**: All text in the step MUST be Vietnamese and come from the shared UI strings file
  (ADR-0005).

### Key Entities

- **Reel**: an existing bundled video with title, motivation tags, length, eligible contexts and
  optional pinning; unchanged by this feature.
- **Playlist**: the ordered, finite list of reels chosen for one opening of the step (≤3 before a
  session, 1 after a distraction).
- **Watch record**: an existing on-device event describing one reel shown (now always one play).
- **Skip record**: a new on-device event describing the step being skipped (context, position).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can see at most 3 reels per opening before a session and at most 1 after a
  distraction; there is no gesture or control that shows more.
- **SC-002**: No reel ever restarts by itself; 100% of reel endings show an end card.
- **SC-003**: From the end card of any reel, a session is running (or resumed) in 1 tap.
- **SC-004**: 0 like, comment, share or social-count elements remain in the app.
- **SC-005**: Every opening of the step leaves at least one watch or skip record, so the share of
  openings followed by a session start can be computed from on-device data.
- **SC-006**: Upgrading a device that has likes and comments from the previous version produces 0
  start-up errors and 0 loss of non-social data.

## Assumptions

- The bundled reel catalogue (6 videos) and its licensing are unchanged (ADR-0007).
- The end card's start actions follow spec 001 FR-007 (planned duration, plus a 5-minute option).
- The motivation quiz and motivation profile stay as they are.
- Where the step sits in navigation, and how the session clock pauses, is defined in spec 001;
  this spec defines what happens inside the step.
- Alternative formats (text or image cards instead of video, daily caps, A/B variants) are out of
  scope and may be specified for the experiment later.
