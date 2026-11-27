# Feature Specification: Buttons, icon tiles and cards in the lead's Farmly style

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-27
**Status**: Implemented (2026-11-27)
**Input**: Project lead shared a recording of their own app design "Farmly" and asked to learn its
graphics and buttons for DisGret; chose all four parts, keeping DisGret's sea blue, and approved
part 1 (buttons and icons) from a mockup: "Làm phần 1". Parts 2–4 (hold to start, game HUD, 3D
pedestal and illustrated cards) follow as their own specs.

## User Scenarios & Testing

### User Story 1 - Hôm nay reads like the mockup (Priority: P1)

**Given** a goal with habits, **Then** Hôm nay shows, over the sea:
- the clarity and streak cards in the Farmly shape (visual top-left, a round chevron top-right,
  the big number, a grey label); tapping either opens Tiến độ;
- a "Lối tắt" card with four pastel icon tiles: Bản đồ (sea map), Góc Gret (pearl count tag),
  Nhắc giờ (red badge with the reminders still to come today; opens Thói quen), Tiến độ;
- the goal and "Học tiếp" cards as before, then "Việc hôm nay": "n/m đã xong", a thin progress bar
  and one row per habit scheduled today (round tick, "name · minutes", reminder time);
- the one primary button "Bắt đầu" with an arrow; the secondary "Học thêm một phiên" is a white pill
  with a blue border.

### User Story 2 - The same language everywhere (Priority: P2)

Stat cards in Tiến độ, Thống kê, habit detail and Tổng kết show their icon in a pastel tile; cards
have larger corners (20); outlined buttons are white pills with a blue border and blue text.

### Edge Cases

- No habit today: "Việc hôm nay" is hidden. No reminders left: no badge. No pearls: no tag.
- Shortcuts never start a study session (ADR-0002: one way in, "Bắt đầu").
- Small phones: no overflow.

## Requirements

- **FR-001**: An `IconTile` widget (pastel square, outline icon, optional red count badge or
  sun-coloured tag) MUST be used for shortcut tiles and stat card icons.
- **FR-002**: Clarity and streak cards MUST use the Farmly layout with a round chevron and open
  Tiến độ when tapped; their screen-reader labels stay.
- **FR-003**: Hôm nay MUST show "Lối tắt" and "Việc hôm nay" as described; the today list comes from
  a pure, unit-tested rule (scheduled today, done state, ordered by reminder time when the
  reminder is on, then by the habit order).
- **FR-004**: Primary forward buttons carry a trailing arrow; outlined buttons use the blue border
  style; card radius 20. Colours stay the "Biển nắng" palette.

## Success Criteria

- **SC-001**: The lead recognises the mockup on the emulator.
- **SC-002**: Existing tests still pass (labels and flows unchanged).
