# Feature Specification: Hold to start (Farmly part 2)

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-27
**Status**: Implemented (2026-11-27)
**Input**: Project lead, part 2 of their Farmly style: "Giữ để bắt đầu học". From an interactive
mockup they chose "A · Nút tròn phát sáng" and a 1.5 s hold. Serves S1 (hard to start): starting
becomes a small ritual, like starting an engine.

## User Scenarios & Testing

### User Story 1 - Hold to start (Priority: P1)

**Given** Hôm nay with a habit due, **Then** the bottom control is a white bar: "Sẵn sàng chưa?" and
"Giữ nút để bắt đầu" on the left, a round blue button "Giữ để / Bắt đầu" with a sun-yellow ring on
the right. **When** the student presses and holds anywhere on the bar, the ring fills and the glow
grows over 1.5 s while the line changes "Gret đang khởi động…" → "Hít một hơi…" → "Vào biển!"; at
full, a firm haptic and the study flow opens as before (motivation step, then the session).
Letting go early drains the ring and nothing starts; a quick tap says "Giữ lâu hơn một chút nhé".
When today is done, the same bar reads "Học thêm một phiên".

### Edge Cases

- Screen readers: double-tap starts at once (holding is hard there); the label says what it does.
- "Remove animations": the ring still fills while held (it is feedback), the glow stays still.
- Still exactly one way into a session on Hôm nay (ADR-0002).

## Requirements

- **FR-001**: A `HoldToStartButton` MUST start only after a continuous 1.5 s hold
  (`AppMotion.holdToStart`), drain on early release, hint on a quick tap, and offer an immediate
  semantics tap.
- **FR-002**: Hôm nay MUST use it for both "Bắt đầu" and "Học thêm một phiên".
- **FR-003**: Colours from the theme and `AppColors.sun`; text in `app_strings.dart`.

## Success Criteria

- **SC-001**: On the emulator, holding starts a session and a tap does not.
- **SC-002**: Every existing flow test still reaches the session (through a shared hold helper).
