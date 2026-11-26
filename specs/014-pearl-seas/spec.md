# Feature Specification: New seas bought with pearls, each an island on the map

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-25
**Status**: Implemented (2026-11-25)
**Input**: Project lead: "có thể thêm tính năng mở đảo mới thì là map mới"; chose "Thêm biển mở
bằng ngọc", all four candidate seas (Rừng tảo bẹ, Núi lửa ngầm, Thành phố chìm, Vịnh hoàng hôn),
prices rising from 150 to 300 pearls, and "Hiện đảo riêng" on the sea map. Builds on spec 004
(Góc của Gret, ADR-0009), spec 005 (sea map, ADR-0010), spec 012 (drawn islands) and spec 013
(living sea).

## User Scenarios & Testing

### User Story 1 - Buy a new sea with pearls (Priority: P1)

**Given** 160 pearls, **When** the student opens Góc của Gret → Biển and buys Rừng tảo bẹ
(150), **Then** 10 pearls remain, the sea is theirs and can be chosen; Hôm nay and the focus
session (when it uses the chosen sea) show it by day and by night. Núi lửa ngầm costs 200,
Thành phố chìm 250, Vịnh hoàng hôn 300; with too few pearls the card shows the price and stays
locked. Biển nhà, Rạn san hô, Biển băng and Đáy biển sâu keep their current rules.

### User Story 2 - A bought sea is an island on the map (Priority: P1)

**Given** Rừng tảo bẹ is bought, **When** the student opens the sea map, **Then** a kelp-forest
island appears after the goal islands, clear of the fog, labelled "Rừng tảo bẹ · Biển của Gret";
tapping it opens a sheet to make it Gret's sea ("Đang dùng" when it already is).

### Edge Cases

- Pearls already spent on outfits are not given back; buying never goes below zero.
- Old data without the new seas reads as before; a chosen sea that is unknown falls back to
  Biển nhà.
- Goal islands keep the four original terrains; landmarks, fog and exploration are unchanged.

## Requirements

- **FR-001**: Four new seas MUST exist with their own day and night look (spec 013 layers plus
  their own scenery): Rừng tảo bẹ (tall swaying kelp, light through it), Núi lửa ngầm (black rock,
  glowing lava cracks, bubble columns, red corals), Thành phố chìm (mossy columns and arches,
  treasure glints), Vịnh hoàng hôn (pink-orange sky, low sun, warm water, palm, pink sand).
- **FR-002**: They MUST be bought with pearls at 150, 200, 250 and 300, through the same
  Góc của Gret flow as outfits (owned ids `sea_<name>`), counted in the pearls spent.
- **FR-003**: Each bought new sea MUST show on the sea map as its own island with that sea's
  scenery, after the goal islands and before the unknown seas, clear of fog, with no landmarks
  and no exploration percentage; tapping it lets the student choose it as Gret's sea.
- **FR-004**: Nothing new is stored beyond the owned ids and the chosen sea; colours only in
  `AppSea` / `AppSeaMap`; text in `app_strings.dart`.

## Success Criteria

- **SC-001**: On the emulator, buying a sea shows it on Hôm nay and as an island on the map.
- **SC-002**: Existing Góc của Gret, sea map and sea tests still pass.
