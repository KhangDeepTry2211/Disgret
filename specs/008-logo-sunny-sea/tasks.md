# Tasks: New logo and "Biển nắng" palette (008)

**Plan**: `docs/superpowers/plans/2026-11-25-logo-sunny-sea.md`.

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test`.

- [X] T001 Logo SVG drawn in the app (FR-001).
- [X] T002 "Biển nắng" theme with contrast tests (FR-003).
- [X] T003 Launcher icon and splash regenerated; Kotlin colours; docs (FR-002, FR-004). Android
      only: the tools also rewrote iOS files (and broke an iOS build setting), so ios/ was reverted;
      iOS is unsupported.
