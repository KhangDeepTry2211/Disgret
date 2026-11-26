# Sea map islands — design

Spec: `specs/012-sea-map-islands/spec.md`. Builds on spec 005 and ADR-0010.

## Intent

The sea map should look like a sea world Gret explores, not a chart with pins. A goal is an island
you can recognise, each habit is a place on it, and the place visibly grows as the habit reaches
7 / 21 / 40 / 66 days, so keeping a habit up (scenario S3) shows on the map.

## Decided by the lead

- Direction A: a sand island ringed by a coral reef, seen from above.
- The other three seas use the same structure with their own scenery.
- Landmarks grow at 7 / 21 / 40 / 66 days.

## Goals

- Island, from the outside in, on the existing wobbly outline (`IslandLayout.outline`):
  - shallow water ring (scale 1.14) with reef pieces along it;
  - beach (scale 1.0);
  - inner land or lagoon (scale about 0.62) with scenery.
- Scenery per sea:

  | Sea | Reef ring | Beach | Inner | Scenery |
  |---|---|---|---|---|
  | Rạn san hô | pink and orange corals | sand | turquoise lagoon | palm trees, starfish |
  | Biển băng | small icebergs | snow | pale ice | snow mounds, ice cracks |
  | Biển sâu | glowing corals | dark rock | darker rock | vents, jellyfish in the ring |
  | Vịnh nhà | rocks | sand | grass | a hut, a lighthouse, bushes |
  | Unknown | none | grey rock | none | none |

- Landmarks replace the pins, one per habit, by `PointKind`:
  - fish cave: a rock arch with a fish;
  - shipwreck;
  - kelp garden;
  - treasure chest;
  - coral temple: small columns;
  - old anchor.

  "n/66" stays under found landmarks, and a hidden habit is a "?" buoy.
- Growth layers by `JourneyStage`:

  | Stage | Days | What shows |
  |---|---|---|
  | found | 1+ | the landmark |
  | warmUp | 7+ | seaweed and small corals around it |
  | steady | 21+ | a school of fish |
  | solid | 40+ | a sea creature (turtle, crab or starfish) |
  | formed | 66 | a flag with sparkles |

- Open water gets a few fish schools, a turtle, a whale tail and bubbles. They are placed the same
  way every time (seeded), and the fog hides them where nothing has been explored yet.

## Non-goals

- No new data or storage, no change to ADR-0010's rules, positions or sizes of islands and points.
- Scenery does not move (the map is a still drawing; Gret keeps bobbing).
- The region sheet keeps its list icons.

## Anti-goals

- Clutter that hides the landmarks, Gret or the labels.
- Anything that reads as blame: no litter, dead coral or sad creatures on the map.

## Approaches

1. **Painted islands and SVG landmark layers (chosen).** `SeaWorldPainter` paints the island bands
   and scenery, because island shapes and sizes vary (seeded outline, height grows with habits).
   Landmarks are fixed art drawn as stacked SVG layers chosen by a pure function, the same pattern
   as Gret's `MascotLook`. This keeps the art easy to redraw and the stage rule testable.
2. **Everything painted in code.** One painter for islands and landmarks. Fewer files, but the art
   is hard to iterate and the stage rule hides inside drawing code.
3. **Pre-drawn island pictures per sea.** Looks richest, but cannot follow the varying outlines
   and sizes.

## The how, as decided

- New pure `LandmarkLook.layers(PointKind kind, JourneyStage stage) -> List<String>` (asset paths).
  It returns the buoy alone for hidden points, otherwise the kind's base layer plus the growth
  layers up to the stage.
- New `assets/map/` SVGs: one per kind, `buoy.svg`, and one per growth layer (`growth_kelp.svg`,
  `growth_fish.svg`, `growth_creature.svg`, `growth_flag.svg`) on one shared canvas.
- New pure scenery placement (`IslandScenery`): seeded spots inside the island bands that keep a
  clearance from every point, Gret's spot and the label anchor.
- `_MapPin` becomes a landmark widget with the same key, semantics, tap and "n/66" chip.
- Colours: new illustration colours in `AppSeaMap` (sand, lagoon, reef, palm, snow, rock, grass…)
  and inside the SVG files only.

## Left to the builder

- The exact art, the counts of scenery and sea features, the clearance distances.
- Which sea creature shows at 40 days for each kind.

## Testing

- Unit tests:
  - `LandmarkLook.layers` for each stage, and the buoy for a hidden point;
  - scenery placement is deterministic, stays inside the island, and keeps clear of points, Gret
    and the label.
- Widget tests:
  - every spec 005 sea map test passes unchanged;
  - a found landmark draws its layers;
  - a hidden point draws the buoy;
  - a small phone shows no overflow.
- Emulator: coral island with one habit at a few stages (seeded data), the whole-world zoom, and
  dark mode is not needed (the map is always dark).
