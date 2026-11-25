# Feature Specification: New logo and the "Biển nắng" palette

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-25
**Status**: Implemented (2026-11-25)
**Input**: Project lead: "thiết kế lại logo app sao cho bắt mắt và sinh động với DisGret (có thể đổi
màu chủ đạo)"; chose logo C2 (a "D" in a bubble, Gret peeking from the bottom-right corner) and the
"Biển nắng" palette after a preview. Design: `docs/superpowers/specs/2026-11-25-logo-sunny-sea-design.md`.

## User Scenarios & Testing

### User Story 1 - A logo that looks like DisGret (Priority: P1)

The app header, the onboarding, the launcher icon and the splash screen show the new logo; screen
readers hear "Logo DisGret".

### User Story 2 - Brighter colours (Priority: P1)

Buttons, links, rings and highlights use the "Biển nắng" colours in light and dark mode, with text
still easy to read; the Kotlin intervention screen follows.

### Edge Cases

- Small sizes (32 px header, launcher icon masks): the bubble, the D and Gret stay recognisable.
- Dark mode: white text on the primary button keeps a 4.5:1 contrast.

## Requirements

- **FR-001**: One SVG source `assets/branding/logo.svg`; the app draws it with flutter_svg.
- **FR-002**: Launcher icon (adaptive background #1E88E5) and splash (background #1E88E5) are
  generated from PNGs rendered from that SVG.
- **FR-003**: Theme colours follow the design table; text on its background ≥ 4.5:1, rings and
  progress ≥ 3:1 against the surface.
- **FR-004**: `res/values/colors.xml` follows (dark background #07111F, aqua #4DD0E1).

## Success Criteria

- **SC-001**: No screen keeps the old navy logo.
- **SC-002**: Contrast tests pass for both modes.
