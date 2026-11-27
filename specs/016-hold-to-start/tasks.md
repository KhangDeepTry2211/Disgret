# Tasks: Hold to start (016)

**Gate**: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`.

- [X] T001 `HoldToStartButton` (1.5 s hold, drain on early release, hint on a tap measured by the
      charge, semantics tap starts at once, fill kept with "remove animations", medium haptic so it
      never feels like the "time is up" alert) (FR-001, FR-003). Tests: `test/hold_to_start_test.dart`.
- [X] T002 Hôm nay uses it for "Bắt đầu" and "Học thêm một phiên" (FR-002); flow tests start through
      the shared `holdToStart` helper in `test/test_helpers.dart` (757/757 pass).
