# Tasks: Livelier fonts and a Gret launch screen (011)

**Plan**: `docs/superpowers/plans/2026-11-25-fonts-launch-screen.md`.

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test`.

- [X] T001 Baloo 2 and Nunito variable fonts and their OFL licences in `assets/fonts/`, declared in
      pubspec.yaml; the text theme picks each weight with `FontVariation.weight`; Be Vietnam Pro
      removed; both licences registered in `main.dart` (FR-001, FR-002). Widget tests load the real
      fonts (`test/flutter_test_config.dart`) so overflow checks measure real text.
- [X] T002 `LaunchOverlay` in `MaterialApp.builder`: Gret swims in from the right with bubbles,
      "DisGret" and "Đang lặn xuống biển…" for 1.4 s, then fades for 300 ms; still Gret with
      "remove animations"; once per cold start; `launchScreenProvider` off in `pumpApp` (FR-003,
      FR-004). Tests: `test/launch_overlay_test.dart`.
- [X] T003 Emulator (Pixel_8_API_35, light, debug build): launch screen, Hôm nay, Thói quen,
      Tiến độ, Vietnamese diacritics. The first try showed no launch screen because the debug
      build's first frame took seconds and the 1.4 s ran before it; the count now starts after the
      first frame. Out of scope but seen there: the Tiến độ and habit-detail chart bubbles were
      cut at the card edge (`fitInsideHorizontally` added).
