# Feature Specification: A livelier sea and Gret, day and night by the clock

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-25
**Status**: Implemented (2026-11-25)
**Input**: Project lead: "bạn có thể nâng cấp giao diện và render biển và linh vật trông đẹp hơn
không"; chose style A (light and depth), then from four animated variants: "cho tôi A2 + A4 với A2
xuất hiện từ 6h sáng tới 18h chiều và thời gian còn lại sẽ là map A4".

## User Scenarios & Testing

### User Story 1 - A sunlit sea by day (Priority: P1)

**Given** it is between 06:00 and 17:59 on the phone, **Then** the sea (Hôm nay, the focus
session, Quán San Hô's windows, Góc của Gret, onboarding, Tổng kết) shows variant A2: water that
deepens in steps, slanting sun rays that sway and brighten, light ripples under the surface, a
sand floor with corals, two layers of swaying seaweed, a school of fish crossing, rising specks,
and Gret bobbing with a slight tilt, wagging its tail, blinking and letting out bubbles.

### User Story 2 - A glowing sea by night (Priority: P1)

**Given** it is between 18:00 and 05:59, **Then** the same views show variant A4: night water,
the moon and stars, pale moon rays, twinkling plankton, a glowing jellyfish drifting up and
glowing corals; Gret keeps the same motions.

### User Story 3 - Every sea gets the new look (Priority: P1)

**Given** the student chose another sea in Góc của Gret (Rạn san hô, Biển băng, Biển sâu, bought
with pearls), **Then** that sea shows the same day and night life in its own colours and scenery
(lead's question, 2026-11-25).

### User Story 4 - The sea still means what it meant (Priority: P1)

**Given** the sea is murky (clarity below 70), **Then** rays dim and fish thin out as clarity
drops, and litter shows below 40, exactly as before. With "remove animations" on, everything is
still.

### Edge Cases

- The phone passes 18:00 or 06:00 while DisGret is open: the sea switches at that minute.
- Dark mode no longer decides the sea; the cards and the rest of the UI keep following it.

## Requirements

- **FR-001**: Night MUST be decided by the phone's clock: night from 18:00 to 05:59, day from
  06:00 to 17:59 (pure function, unit-tested), for every sea view and Quán San Hô.
- **FR-002**: The day sea MUST draw stepped depth bands, sun rays, ripples, a sand floor, two
  seaweed layers, a fish school and rising specks; the night sea MUST draw the moon, stars, moon
  rays, plankton, a glowing jellyfish and glowing corals. Rays and fish follow clarity.
- **FR-003**: Gret MUST gain soft shading (a shadow under the body, a gloss highlight, a second
  catch-light in the eyes), a wagging tail and a slight tilt while bobbing; other species keep
  their drawings.
- **FR-004**: Colours only in `AppSea` and the SVG files; illustration may use translucency, UI
  stays flat; "remove animations" shows a still frame.

## Success Criteria

- **SC-001**: The lead sees A2 on the emulator in the day and A4 at night.
- **SC-002**: Existing sea, focus, café and Góc của Gret tests still pass.
