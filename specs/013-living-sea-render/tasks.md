# Tasks: A livelier sea and Gret, day and night by the clock (013)

**Plan**: `docs/superpowers/plans/2026-11-25-living-sea-render.md`.

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test`.

- [X] T001 `SeaTime` (night 18:00–05:59) drives `SeaScene`, Quán San Hô, the Góc của Gret sea
      cards and Hôm nay's deep-water fill; an open sea turns at the next 06:00 / 18:00 (FR-001).
      Tests: `test/sea_time_test.dart`, `test/living_sea_test.dart`.
- [X] T002 Day (A2) and night (A4) layers in `SeaPainter` for all four seas, Gret's mouth
      bubbles; text on the sky or the café wall follows `AppTheme.forSky` (FR-002, FR-004).
- [X] T003 Gret: tail layer that wags, tilt while bobbing, crescent shading, gloss and second
      catch-light (FR-003). Tests: `test/gret_sea_widgets_test.dart`.
- [X] T004 Look check on images rendered in a widget test (Hôm nay by day and night; the four
      seas by day and night). Fixed from that check: the header was unreadable on the night sky
      in light mode, the sun, moon and night jellyfish were too big on the full-screen sea, and
      the night skies of the pearl seas were grey.
