# Feature Specification: Hôm nay on a full-screen sea

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-25
**Status**: Implemented (2026-11-25)
**Input**: Project lead: "thiết kế giao diện để khung cảnh của gret có thể full màn hình và đè
những mục đang sẵn có lên khung cảnh đó như unrot"; chose approach A. Design:
`docs/superpowers/specs/2026-11-25-today-fullscreen-sea-design.md`.

## User Scenarios & Testing

### User Story 1 - Gret's sea is the whole screen (Priority: P1)

1. **Given** Hôm nay, **Then** the sea fills the screen, Gret swims in its upper part and the cards
   start below Gret.
2. **When** the student scrolls, **Then** the cards slide over Gret and the sea does not move.
3. **When** the student taps Gret, **Then** Gret says a line (as before).

### User Story 2 - Floating tab bar (Priority: P2)

**Given** any tab, **Then** the tab bar is a rounded bar inset from the screen edges, and no button
(Bắt đầu, the Thói quen "+") hides behind it.

### Edge Cases

- No goal or no habit: the same full-screen sea, the empty state in a card.
- 360×640 phone: no overflow. Dark mode: the night sea. Remove animations: still.

## Requirements

- **FR-001**: `SeaScene` (full) MUST fill Hôm nay behind the content and stay still while it
  scrolls; Gret at alignment (0, −0.34) (about 33% of the height), under a lower sky (22%).
- **FR-002**: The content MUST start with a transparent space of 44% of the screen height that
  passes taps to Gret, then the existing cards with 16 px margins; no sheet.
- **FR-003**: The tab bar MUST float 16 px from the sides and bottom with rounded corners; the body
  extends behind it and screens keep their last controls above it.
- **FR-004**: Colours from `app_theme.dart`; controls drawn straight on the sea keep a surface
  background so their text stays readable.

## Success Criteria

- **SC-001**: Exactly one control still leads into a session (ADR-0002).

## Amendment (2026-11-25)

The lead asked that the sea scroll with the cards ("kéo thì kéo khung hình của gret đằng sau lên
luôn"): the sea and Gret now move up by the scroll offset, and the deepest water colour
(`SeaPainter.deepColour`) fills the screen under them. Test: `test/today_fullscreen_test.dart`.

## Amendment (2026-11-27)

The lead found scrolling not smooth and asked to pin Gret ("cố định lại Gret khi tôi scroll
xuống"), reversing the 2026-11-25 amendment: the sea and Gret stay put and the cards slide over
them (as in the original story 1.2), and the sea's animations (waves, rays, fish, Gret's bob and
tail) pause from the start to the end of a scroll (`TickerMode`), so a scroll only moves the cards.
Both activities also ask Android for the screen's fastest refresh rate (`DisplayRate.kt`), so
phones with 90/120 Hz screens do not keep DisGret at 60 Hz.
Tests: `test/today_fullscreen_test.dart`.
