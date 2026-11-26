# Feature Specification: Drawn islands and landmarks on the sea map

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-25
**Status**: Implemented (2026-11-25)
**Input**: Project lead, with a screenshot of the current map (a green patch with one pin "1/66"):
"tôi muốn bạn vẽ luôn cả hòn đảo san hô và những đặc điểm bạn có thể thấy ở biển chứ không phải
như cột mốc như thế này". Chose direction A (a sand island ringed by a coral reef), the same island
structure with its own scenery for the other three seas, and landmarks that grow at 7 / 21 / 40 /
66 days. Builds on spec 005 and ADR-0010; nothing new is stored.

## User Scenarios & Testing

### User Story 1 - My goal is a real island (Priority: P1)

**Given** a goal in "Rạn san hô", **When** the student opens the sea map, **Then** its island shows a
coral reef in shallow water around a sand beach, a lagoon and palm trees, with fish and other sea
life in the water nearby, under the same fog that clears as habits are done.

The other seas keep the same structure with their own scenery: Biển băng (snow, ice, icebergs),
Biển sâu (dark volcanic rock, glowing corals, jellyfish), Vịnh nhà (grass, a hut, a lighthouse).
Unknown seas stay a grey islet under the fog.

### User Story 2 - Each habit is a place that grows (Priority: P1)

**Given** a habit done on 8 days, **Then** its landmark (for example a shipwreck) stands on the
island with seaweed and small corals around it and "8/66" under it. At 21 days a school of fish
joins, at 40 days a sea creature, at 66 days a flag with sparkles. A habit never done is a "?"
buoy. Tapping a landmark or a buoy does what tapping a pin did.

### Edge Cases

- Many habits on one island: landmarks keep their spots; scenery never covers a landmark, Gret or
  the island label.
- Zoomed out to the whole world: islands still read as islands; nothing tiny is needed to
  understand progress.
- Small phones: no overflow.

## Requirements

- **FR-001**: Each known island MUST be drawn as a reef ring, a beach and an inner land, with the
  scenery of its sea; unknown seas as a plain grey islet.
- **FR-002**: Each habit point MUST be drawn as the landmark of its kind, with the growth layers
  of its stage: found = landmark; 7 days + seaweed and corals; 21 + fish; 40 + a sea creature;
  66 + a flag and sparkles. Hidden points are a "?" buoy. "n/66" stays under found landmarks.
- **FR-003**: Open water MUST show a few sea features (fish schools, a turtle, a whale tail,
  bubbles), placed the same way every time.
- **FR-004**: Keys `map-point-<habitId>`, semantics labels, taps, fog, labels, Gret, pan and zoom
  stay as in spec 005. Nothing new is stored; colours only in `AppSeaMap` and the SVG files.

## Success Criteria

- **SC-001**: The lead recognises the coral island and each landmark on the emulator without
  reading labels.
- **SC-002**: Every spec 005 test still passes.
