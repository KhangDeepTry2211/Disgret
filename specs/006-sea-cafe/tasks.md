# Tasks: Quán San Hô (006)

**Plan**: `docs/superpowers/plans/2026-11-24-sea-cafe.md` (interfaces, tests and review focus per
task). Pure logic `lib/data/sea_cafe.dart`; preference `lib/data/study_place.dart` +
`StudyPlaceRepository` (profile key `study_place`); providers `lib/providers/sea_cafe_providers.dart`;
scene `lib/widgets/cafe/`; the focus screen picks the café or the sea. No new dependency.

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test`.

- [X] T001 Study place preference, plan sheet chips, "Học tiếp" line, `Session.place` (FR-001,
      FR-002, FR-008).
- [X] T002 Sea friends roster, line rules, greetings window; turtle and starfish drawings (FR-005,
      FR-006, FR-007).
- [X] T003 Café scene: painter, windows on the sea, seats, bubble, semantics (FR-003, FR-004,
      FR-009).
- [X] T004 Café in the focus session: moments, bubble timer, greetings; existing sea tests pinned to
      the sea (FR-003, FR-006, FR-007).
- [X] T005 README, design-system, data-model; emulator check and screenshots. Done 2026-11-24
      on Pixel_8_API_35 (light theme): owner greeting, greeting exchange, welcome back after a
      distraction. After the first look the characters were sized by the scene height, the counter
      lowered, the friends given the neutral face, and the reply delayed after Gret's greeting so
      the bubbles do not overlap.
