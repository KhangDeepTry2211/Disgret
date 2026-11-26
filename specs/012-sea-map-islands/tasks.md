# Tasks: Drawn islands and landmarks on the sea map (012)

**Plan**: `docs/superpowers/plans/2026-11-25-sea-map-islands.md`.

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test`.

- [X] T001 Landmark drawings and growth layers in `assets/map/`, chosen by
      `LandmarkLook.layers` (FR-002). Tests: `test/landmark_look_test.dart`.
- [X] T002 Island bands, sea scenery and sea life (`IslandScenery`, `OpenSea`, `SceneryArt`,
      `IslandLayout.edgeAt`) (FR-001, FR-003). Tests: `test/sea_scenery_test.dart`.
- [X] T003 Landmarks replace the pins with the same keys, semantics and taps (FR-002, FR-004).
      Tests: `test/sea_map_view_test.dart`.
- [X] T004 Look check: images rendered in a widget test with sample data (four seas, habits at
      0 / 8 / 25 / 45 / 66 days), then the emulator (Pixel_8_API_35, debug build) with the lead's
      data (one coral island, one habit on day 1): sand, lagoon, palms, corals, the fish cave with
      "1/66" and Gret all show. Seen there: after three "−" taps the view had left the island. Not
      reproduced: a widget test with the glides animated keeps the middle of the screen fixed
      (kept as a regression test), and the emulator was failing at the time (GPU "null ctx"
      errors, then it closed).
