# Sea map islands Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Draw each goal as a real island with its sea's scenery and each habit as a landmark that
grows at 7 / 21 / 40 / 66 days, with sea life in the water.

**Architecture:** `SeaWorldPainter` paints the island bands (reef ring, beach, inner land) and the
scenery placed by a pure, seeded `IslandScenery` / `OpenSea`. Landmarks are stacked SVG layers
chosen by a pure `LandmarkLook.layers`, drawn by the widget that replaces `_MapPin`.

**Tech Stack:** Flutter, flutter_svg, Riverpod 3.

**Spec:** `specs/012-sea-map-islands/spec.md`; design
`docs/superpowers/specs/2026-11-25-sea-map-islands-design.md`.

## Global Constraints

- Nothing new is stored; island and point positions unchanged (`SeaWorldLayout`).
- Colours only in `AppSeaMap` / `AppSea` and the SVG files; no new strings needed.
- Keys `map-point-<habitId>`, semantics labels and taps unchanged; every spec 005 test passes.
- Gate: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`.

## Review Focus

- A landmark's layers follow its stage exactly (Task 1 test).
- Scenery never lands on a landmark or on Gret's spot (Task 2 test).
- Scenery stays inside its band and is the same on every open (Task 2 test).
- Open-sea life never sits on an island (Task 2 test).
- Small phone: the map still fits (existing spec 005 test).

---

### Task 1: Landmark art and stage rule

**Files:** create `lib/widgets/sea/landmark_look.dart`, `assets/map/*.svg` (6 kinds, `buoy.svg`,
`growth_kelp.svg`, `growth_fish.svg`, `growth_creature.svg`, `growth_flag.svg`, canvas 120×100);
modify `pubspec.yaml` (assets); test `test/landmark_look_test.dart`.

**Produces:** `LandmarkLook.layers(PointKind kind, JourneyStage stage) -> List<String>`,
`LandmarkLook.buoy`, `LandmarkLook.canvas` (Size 120×100).

- [x] Tests: hidden → `[buoy]`; found → `[base]`; warmUp → `[kelp, base]`; steady → `[kelp, base,
  fish]`; solid → `[kelp, base, fish, creature]`; formed → `[kelp, base, fish, creature, flag]`;
  every path exists on disk.
- [x] Implement; gate green.

### Task 2: Island scenery and sea life

**Files:** create `lib/widgets/sea/sea_scenery.dart` (placement + drawing); modify
`lib/widgets/sea/sea_world.dart` (`IslandLayout.edgeAt`, painter bands), `lib/theme/app_theme.dart`
(`AppSeaMap` colours and sizes); test `test/sea_scenery_test.dart`.

**Produces:** `IslandLayout.edgeAt(double angle, double scale) -> Offset`;
`IslandScenery.of(IslandLayout island) -> List<SceneryItem>`;
`OpenSea.of(SeaWorldLayout layout) -> List<SceneryItem>`; `SceneryItem(kind, at, size)`.

- [x] Tests: same island → same items; coral has palms and corals, ice icebergs, deep glowing
  corals, home a hut and a lighthouse, unknown nothing; land items inside the outline; no item
  within `AppSeaMap.sceneryClearance` of a point or Gret's spot; open-sea items outside every
  island's bounds.
- [x] Implement painter bands and drawing; gate green.

### Task 3: Landmarks on the map

**Files:** modify `lib/screens/sea_map_screen.dart` (`_MapPin` → `_Landmark`); test
`test/sea_map_view_test.dart`.

- [x] Tests: a habit done 8 days draws `LandmarkLook.layers(fishCave, warmUp)` under its key with
  "8/66"; a new habit draws the buoy.
- [x] Implement; gate green; docs (design system, README step 10, spec tasks).
- [x] Look check: widget-test images with sample data, then the emulator with the lead's data.
