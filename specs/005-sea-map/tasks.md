# Tasks: Sea map (005)

**Plan**: pure logic `lib/data/sea_map.dart` (regions, points, progress, milestones, Gret's region);
provider `seaMapProvider` in `lib/providers/sea_map_providers.dart`; painter
`lib/widgets/sea/sea_map_painter.dart`; view `lib/widgets/sea/sea_map_view.dart`; the Thói quen tab
gains a "Bản đồ" view; the focus session uses `sessionSeaPlaceProvider`. No new dependency, nothing
stored.

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test`.

- [X] T001 Write `test/sea_map_test.dart` and implement `lib/data/sea_map.dart` (FR-001–FR-003,
      Gret's region).
- [X] T002 `seaMapProvider` and `sessionSeaPlaceProvider`; strings.
- [X] T003 Map painter (ocean, island regions, fog with clear circles) and `SeaMapView` (points,
      labels, Gret, region sheet, "?" hint).
- [X] T004 Thói quen tab: "Bản đồ" view, time filter hidden on the map. Built as a map button in
      the app bar instead of a fourth segment: four equal segments wrapped "Theo ngày" on two lines.
- [X] T005 Focus session sea in the region's terrain (FR-005).
- [X] T006 Widget tests `test/sea_map_view_test.dart`; README map row "5.5 Bản đồ biển" and demo
      step; design-system and data-model notes.
- [X] T007 Run on the emulator, screenshots.
