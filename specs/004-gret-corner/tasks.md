# Tasks: Góc của Gret (004)

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test`.

## Phase 1: Foundations

- [X] T001 Write `test/pearls_test.dart` and implement `lib/data/pearls.dart` (FR-001).
- [X] T002 Write `test/gret_corner_catalog_test.dart` (unique ids, every asset exists, premium never
      obtainable) and implement `lib/data/gret_corner_catalog.dart`.
- [X] T003 Implement `GretCornerRepository` (profile box) and `lib/providers/gret_corner_providers.dart`
      (`pearlBalanceProvider`, `bestStreakProvider`, `GretCornerNotifier`, `gretLookProvider`);
      provider tests in `test/gret_corner_providers_test.dart`.

## Phase 2: Art and sea places

- [X] T004 Draw outfits in `assets/mascot/outfits/` and bodies for `crab` and `octopus`; mascot
      layers accept outfits and other species (face layers shared with Gret).
- [X] T005 `SeaPlace` palettes and decorations in `SeaPainter` (home, coral, ice, deep); tokens in
      `AppSea`.

## Phase 3: Screen

- [X] T006 `lib/screens/gret_corner_screen.dart` + route `/gret-corner`; wardrobe button on the Hôm
      nay sea; strings.
- [X] T007 Hôm nay and focus session draw the chosen look (`gretLookProvider`).
- [X] T008 Widget tests `test/gret_corner_screen_test.dart`: open from Hôm nay, buy and wear,
      not enough pearls, locked sea, premium "Sắp có", mascot switch.

## Phase 4: Polish

- [X] T009 Run on the emulator, screenshots; update README demo script and map row
      "5.4 Góc của Gret".
