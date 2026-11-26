# Pearl seas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Four seas bought with pearls (150/200/250/300), each with its own day and night look,
each shown as its own island on the sea map once bought.

**Architecture:** New `SeaPlace` values reuse the sea painter, Góc của Gret and the map. The
catalog prices them; the corner notifier buys them like outfits (`sea_<name>`); the sea map
layout appends an island per bought new sea.

**Tech Stack:** Flutter, Riverpod 3, Hive.

**Spec:** `specs/014-pearl-seas/spec.md`; design `docs/superpowers/specs/2026-11-25-pearl-seas-design.md`.

## Global Constraints

- Prices: Rừng tảo bẹ 150, Núi lửa ngầm 200, Thành phố chìm 250, Vịnh hoàng hôn 300 pearls.
- Owned ids `sea_<name>`; unknown stored sea → Biển nhà; old data unchanged.
- Goal terrains stay coral, ice, deep, home. Colours in `AppSea` / `AppSeaMap`; text in
  `app_strings.dart`.
- Gate: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`.

## Review Focus

- Buying with too few pearls changes nothing (Task 1 test).
- Pearls spent on a sea count in the balance after a restart (Task 1 test).
- A bought-sea island never overlaps a goal island and is clear of fog (Task 3 test).
- Every new place paints day and night (living sea loop over `SeaPlace.values`).
- The sea preview arrows show the price of a locked pearl sea (Task 1 test).

---

### Task 1: Catalog and buying

**Files:** modify `lib/data/mascot_species.dart`, `lib/data/gret_corner_catalog.dart`,
`lib/providers/gret_corner_providers.dart`, `lib/screens/gret_corner_screen.dart`,
`lib/l10n/app_strings.dart`; test `test/pearl_seas_test.dart`.

- [x] Tests: catalog prices and ids; the Biển tab buys Rừng tảo bẹ with 160 pearls (10 left,
  chosen, on Hôm nay), refuses with 100; the preview arrow shows "Rừng tảo bẹ · 150 ngọc".
- [x] Implement; gate green.

### Task 2: Painting the new seas

**Files:** modify `lib/widgets/sea/sea_painter.dart`, `lib/theme/app_theme.dart`.

- [x] Existing loop test covers every place by day and night; add the scenery.

### Task 3: Islands on the map

**Files:** modify `lib/widgets/sea/sea_world.dart`, `lib/widgets/sea/sea_scenery.dart`,
`lib/providers/sea_map_providers.dart`, `lib/screens/sea_map_screen.dart`,
`lib/theme/app_theme.dart`, `lib/l10n/app_strings.dart`, `docs/decisions/0010-*.md`; tests
`test/sea_scenery_test.dart`, `test/sea_map_view_test.dart`.

- [x] Tests: layout order goal → bought seas → unknown; no overlap; the island's label and sheet
  choose the sea; scenery for each new place.
- [x] Implement; gate green; docs; emulator check.
