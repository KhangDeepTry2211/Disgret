# Pearl seas — design

Spec: `specs/014-pearl-seas/spec.md`.

## Intent

Pearls (1 per 5 focused minutes) need long-term goals beyond outfits, and the lead wants
"opening a new island" to feel like getting a new map. Four new seas, bought with pearls, change
Gret's sea and appear as islands of their own on the sea map, so studying visibly grows Gret's
world (scenario S3).

## Decided by the lead

- Seas: Rừng tảo bẹ, Núi lửa ngầm, Thành phố chìm, Vịnh hoàng hôn (from the preview).
- Prices 150, 200, 250, 300 pearls, in that order; any can be bought first.
- On the map, each bought sea is its own island.

## My calls (please check)

- Only the four new pearl seas become map islands; Rạn san hô, Biển băng and Đáy biển sâu stay
  goal terrains and streak rewards as today.
- Bought-sea islands sit after the goal islands and before the two unknown seas, are always clear
  of fog, carry the label "<name> · Biển của Gret", and tapping one opens a small sheet with
  "Chọn làm biển của Gret" (or "Đang dùng").
- Vịnh hoàng hôn keeps its pink-orange sky all day (it is the sunset bay); at night it uses the
  night sky like every sea.
- Night extras: kelp gets glowing specks, the volcano's lava glows brighter, the sunken city's
  windows light up, the sunset bay gets a shooting star.

## Non-goals and anti-goals

- No real money, no daily limits, no random rewards (ADR-0009 stays: pearls only from studying).
- No new mascots or outfits; no change to how pearls are earned.
- Anti-goal: anything that makes pearls feel like a grind or a shop that pushes; prices are shown
  plainly, nothing nags.

## Approaches

1. **New `SeaPlace` values (chosen).** The sea painter, Góc của Gret, the café windows and the map
   already switch on `SeaPlace`; four new values reuse all of that.
2. **A separate "theme pack" layer over the four places.** Avoids touching the enum, but every
   view would need a second switch.
3. **Pre-drawn backgrounds.** Richer art, but no clarity blending, no day/night, no animation.

## How

- `SeaPlace` gains `kelp`, `volcano`, `sunken`, `sunset`; `GretCornerCatalog.seas` lists them with
  `Unlock.pearls(150/200/250/300)`; `SeaInfo.id` = `sea_<name>`; `obtain` and the spent total
  include seas; the sea tab uses the same id as `chooseSea`.
- `SeaPainter`: colours (`AppSea`) and scenery per new place; spec 013 layers on top.
- Sea map: `SeaWorldLayout.of` takes the bought new seas and adds their islands; `IslandLayout`
  gets an optional sea (no region); `IslandScenery` and the island bands cover the new places;
  the fog opens fully over them; `sea_map_screen.dart` shows their label and choose sheet.
- ADR-0010 gets a short amendment: the map may show islands that are not goals (bought seas).

## Testing

- Unit: catalog prices and ids; buying spends pearls and refuses when short; layout puts bought
  seas after goals and before unknown seas; scenery for each new place.
- Widget: the sea tab buys and chooses a new sea; the map shows the island and its sheet chooses
  it; every place paints day and night (existing loop over `SeaPlace.values`).
- Emulator: buy a sea (pearls permitting) and see it on Hôm nay and on the map.
