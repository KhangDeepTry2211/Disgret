# Tasks: New seas bought with pearls, each an island on the map (014)

**Plan**: `docs/superpowers/plans/2026-11-25-pearl-seas.md`.

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test`.

- [X] T001 `SeaPlace.kelp/volcano/sunken/sunset`; catalog prices 150/200/250/300; `SeaInfo.id`,
      `seaById`, `boughtSeas`; buying and the spent total include seas; the Biển tab opens the buy
      sheet for a pearl sea; the preview arrows show its price (FR-002). Tests:
      `test/pearl_seas_test.dart`, `test/pearls_test.dart`.
- [X] T002 Day and night look of the four seas in `SeaPainter` (FR-001); covered by the
      `test/living_sea_test.dart` loop over every place.
- [X] T003 Bought seas as islands on the map: layout after the goals, bands, scenery
      (kelp tufts, lava rocks, a cone, columns, an arch, ruin blocks), fog cleared, label and the
      choose sheet; ADR-0010 amendment (FR-003). Tests: `test/sea_scenery_test.dart`,
      `test/sea_map_view_test.dart`.
- [X] T004 Look check on images rendered in a widget test (the four seas by day and night, the map
      with four bought seas), then the emulator (Pixel_8_API_35, debug build, 11:24, the lead's
      data with 8 pearls): the Biển tab lists the four seas with their pictures and prices, and
      Rừng tảo bẹ's sheet shows its sea and "Còn thiếu 142 ngọc trai. Học thêm nhé!". Buying and
      the map island were not tried there (not enough pearls); the widget tests cover them.
