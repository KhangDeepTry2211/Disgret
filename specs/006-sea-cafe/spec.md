# Feature Specification: Quán San Hô (sea café)

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-24
**Status**: Implemented (2026-11-24)
**Input**: Project lead: "thiết kế 1 mục … tạo 1 phòng học, 1 quán cà phê,... ở biển để các gret từ
những người dùng khác cùng focus chung" (reference: the "Phòng trà" study room screenshot); goal
"để các bạn không có cảm giác học 1 mình"; offline first, online later; companions are Gret's sea
friends; each student keeps their own plan; the café is the default place. Design:
`docs/superpowers/specs/2026-11-24-sea-cafe-design.md`, ADR-0011.

## User Scenarios & Testing

### User Story 1 - Study in the café with Gret's friends (Priority: P1)

A student taps "Bắt đầu" and the session takes place in Quán San Hô: Gret sits at the front table,
the owner Rùa stands at the counter and three sea friends study at their tables; the windows look
out on Gret's sea (S1: others are already studying).

**Acceptance Scenarios**:

1. **Given** a student who never chose a place, **When** a session starts, **Then** the focus
   screen shows the café with the countdown ring, the owner and three friends labelled
   "name · subject", and Gret wearing the student's look.
2. **Given** the student wears the crab Ẩn, **Then** Ẩn is not at a table and Gret (the fish) is.
3. **Given** the session starts, **Then** the owner greets the student in a speech bubble that
   disappears after 3 seconds.

### User Story 2 - Friends welcome you back (Priority: P1)

After a distraction or a break, one friend says a kind ready-made line (S2).

**Acceptance Scenarios**:

1. **Given** a running session in the café, **When** a distraction is recorded, **Then** one
   friend says a "welcome back" line.
2. **When** a break starts and when it ends, **Then** a friend says a break line and a resume
   line; **when** the session passes half its time, **then** a friend says a halfway line.
3. Lines rotate between friends; no line scolds.

### User Story 3 - Greet the café (Priority: P2)

During the first minute and during breaks, the student can tap a ready-made greeting; Gret says it
and a friend replies. While studying, the greetings are hidden.

### User Story 4 - Choose where to study (Priority: P2)

In "Đổi thói quen hoặc thời lượng", the student picks "Biển của Gret" or "Quán San Hô"; the choice
lasts until changed and "Học tiếp" shows "ở Quán San Hô" when the café is chosen.

### Edge Cases

- Remove animations: friends are still, bubbles appear without animation, nothing loops.
- Dark theme: the café at night with the lamps on.
- Small phone (360×640): no overflow; the ring, the friends and the greetings fit.
- Sessions saved before this feature read as studied in the sea.

## Requirements

- **FR-001**: `StudyPlace { sea, cafe }` MUST be stored in the profile box as `study_place`; missing
  or unknown values read as `cafe`.
- **FR-002**: The session plan sheet MUST offer the two places as sticker chips and save the
  choice on "Áp dụng"; "Học tiếp" MUST show "ở Quán San Hô" when the café is chosen.
- **FR-003**: With the café chosen, the focus screen MUST draw the café instead of the sea; the
  habit name, countdown ring, break text, distraction swat effect, stat cards and buttons stay.
- **FR-004**: The café windows MUST show the sea of the session habit's region (else the home sea
  of Góc của Gret) at the live sea clarity.
- **FR-005**: The café MUST seat the owner Rùa and the first three of Ẩn (crab, Toán), Mochi
  (octopus, Văn), Sao (starfish, Tiếng Anh), Gret (fish, Sinh học) whose species the student is
  not wearing; nothing may present them as real users or count people.
- **FR-006**: Friends MUST react only at these moments: session started (owner), back after a
  distraction, break started, break ended, halfway; one bubble at a time for 3 s; speakers rotate.
- **FR-007**: Greetings ("Chào cả quán!", "Cố lên nhé!", "Mình nghỉ chút", "Cảm ơn nha!") MUST be
  available only in the first minute of focus and during breaks, get a ready-made reply, accept
  no free text, and store or send nothing.
- **FR-008**: A saved session MUST record its place (`place`, default `sea` for older sessions).
- **FR-009**: Text from `app_strings.dart`, colours from `app_theme.dart`; the scene has one
  screen-reader label and each bubble is announced once.

## Success Criteria

- **SC-001**: A new student's first session takes place in the café with no extra tap.
- **SC-002**: Switching back to Gret's sea takes 3 taps from Hôm nay (link, chip, "Áp dụng").
- **SC-003**: Existing data stays readable without migration.
