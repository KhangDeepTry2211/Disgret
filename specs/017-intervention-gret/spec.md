# Feature Specification: Gret guards the door and breathes with you (intervention screen)

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-27
**Status**: Implemented (2026-11-27); native checklist run (tasks.md T003)
**Input**: Project lead: "bạn có ý tưởng gì về màn can thiệp (giả sử Gret hiện lên và animation
ngăn cản)", with a screenshot of today's screen (dark, "TikTok", "Bạn có chắc muốn vào TikTok
không?", a big 7, "Hít thở sâu một chút…"). From three sketched ideas they chose "Ghép 1 và 2":
Gret swims in and spreads its fins in front of the blocked app, then breathes with the student
while the countdown runs. Serves S2 (distracted mid-session). Builds on spec 2.3/2.4 (Reset Break).

## User Scenarios & Testing

### User Story 1 - Gret blocks the door (Priority: P1)

**Given** a study session and a blocked app (for example TikTok), **When** the student opens it,
**Then** the intervention shows the app's name and the question as today, and Gret swims in from
the side, stops in the middle and spreads its fins, inside a sun-yellow countdown ring, with a
short line in a bubble that changes with the block count (1st: "Khoan đã! Học thêm chút nhé?",
2nd: "Lại gặp nhau rồi! Thở cùng mình nào.", 3rd and later: "Mình tin bạn quay lại được mà.").

### User Story 2 - Breathe with Gret (Priority: P1)

**Then**, for the rest of the wait, Gret slowly puffs up for 4 s ("Hít vào…") and shrinks back for
4 s ("Thở ra…"), its tail wagging, a few bubbles rising; the seconds left stay visible. When the
wait ends the three choices appear exactly as today ("Quay lại học", "Xem 1 reel động lực",
"Nghỉ có chủ đích"); Back still returns to the session.

### Edge Cases

- Android "remove animations": Gret is still, spreading its fins, and the line reads
  "Hít thở sâu một chút…"; the ring and the seconds still count down.
- "Thử màn can thiệp" in Cài đặt shows the same screen (first-block line).
- Small screens and large text: the content scrolls, the choices are never hidden.
- Gret is never drawn hurt and never blames (ADR-0008).

## Requirements

- **FR-001**: Gret MUST be drawn natively from the same art as the app (vector drawables converted
  from `assets/mascot/gret/*.svg`), so the screen appears at once over the blocked app.
- **FR-002**: The wait, the block counting, the choices, the events and the method channel MUST
  stay unchanged (spec 2.3/2.4, `native-bridge.md`).
- **FR-003**: Colours in `res/values/colors.xml` matching `app_theme.dart` (sun #FFC93C, navy, cyan);
  text in `res/values/strings.xml`.
- **FR-004**: The native manual checklist MUST be run on the emulator and recorded.

## Design (approved idea, my calls marked)

- One custom view `GretGuardView` draws the ring, Gret's layers (tail, body, cheeks, focused eyes,
  neutral mouth) and two raised fins, and runs one animator: entrance (0.9 s, from the left with a
  small overshoot, fins rising), then the 8 s breath loop (scale 0.92 ↔ 1.1), tail wag, bubbles.
- My call: the countdown number moves under Gret ("7 giây") instead of the 88 sp number; the
  question stays above. My call: choices still appear only after the wait (no behaviour change).

## Success Criteria

- **SC-001**: On the emulator, opening a blocked app during a session shows Gret blocking and
  breathing, then the three choices; every checklist item passes.
