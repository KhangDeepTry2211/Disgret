# Living sea render — design

Spec: `specs/013-living-sea-render/spec.md`.

## Intent

The sea and Gret are the heart of DisGret; the lead wants them to look richer and more alive. They
chose style A (light and depth) with motion level A2 by day and the night glow A4, switched by the
clock (06:00–17:59 day, 18:00–05:59 night), not by dark mode.

## Decided by the lead

- Style A, motion A2 by day, A4 by night.
- Day and night follow the clock: A2 from 06:00 to 18:00, A4 the rest of the time.

## My calls (please check)

- The clock rule applies to every place the sea shows (Hôm nay, focus session, Tổng kết,
  onboarding, Góc của Gret previews) and to Quán San Hô (room and windows), so they always agree.
- The meaning stays: murky water still dims the rays and thins the fish; litter below 40.
- Only Gret gets the new shading and the wagging tail (its body is split into a tail layer and a
  body layer); crab, octopus, turtle and starfish keep their drawings for now.
- "Remove animations" keeps showing a still frame.

## Approaches

1. **Extend `SeaPainter` (chosen).** The existing painter already loops one controller and blends
   clear to murky; it gains layers (rays, ripples, floor, seaweed layers, school, specks, night
   life). One place to tune, already used by every sea view.
2. **Separate animated widgets per element.** Easier to test one by one, but many controllers and
   repaints per frame on a full-screen view.
3. **Rive or Lottie animation files.** Richest motion, but a new dependency and authoring tool the
   course team cannot maintain, and colours could no longer follow clarity.

## How

- Pure `SeaTime.isNight(DateTime now)`; `SeaScene` and the café read the clock through
  `clockProvider` and switch at the next 06:00 or 18:00.
- `SeaPainter` draws, by day: stepped bands, rays (swaying, pulsing, dimmed by murk), ripples,
  sand floor with pebbles and corals, back and front seaweed, fish school, specks; by night: moon,
  stars, moon rays, plankton, jellyfish, glowing corals. Gret's bubbles come from the scene next to
  Gret's mouth.
- Gret: `assets/mascot/gret/tail.svg` split from `body.svg`, shading in `body.svg`, catch-lights
  in the eye drawings; `MascotView` rotates the tail layer and tilts while bobbing.

## Testing

- Unit: `SeaTime.isNight` at 05:59, 06:00, 17:59, 18:00; `MascotLook.layers` puts the tail first
  for Gret only.
- Widget: a sea at 20:00 paints night and at 09:00 day; the scene switches when the clock passes
  18:00; existing sea, focus, café and Góc của Gret tests pass.
- Emulator: Hôm nay by day; the night sea by setting the emulator clock is not allowed (system
  setting), so night is checked in a widget test image instead.
