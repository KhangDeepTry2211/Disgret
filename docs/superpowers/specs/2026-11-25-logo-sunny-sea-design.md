# New logo and the "Biển nắng" palette — design

Date: 2026-11-25 · Status: approved by the project lead in chat ("Duyệt, làm luôn") after the preview · Feature:
spec `specs/008-logo-sunny-sea`.

## Intent

The lead wants a logo that is eye-catching and lively and fits DisGret, and allowed a brighter main
colour. The current logo is a temporary PNG cropped from a screenshot
(`assets/branding/logo_tam.png`).

## Decisions taken with the lead

- Logo **C2**: a white bubble holding a blue "D", with Gret (cyan, with face) peeking up at it from
  the bottom-right corner of a bright-blue rounded square; two small sun-yellow bubbles bottom left.
- Palette **"Biển nắng"**: bright sea blue, aqua and sun yellow, replacing the navy "Ocean" brand.

## Approaches considered

- Logo: A (Gret as the letter D), B (Gret above a wave), C (D in a bubble), D (wordmark). C chosen,
  then C2 among three variants (bigger yellow fish, Gret bottom right, Gret bottom left with sun).
- Palette: keep Ocean, "Lagoon tươi" (teal and coral), "Biển nắng" (chosen).
- Asset pipeline (builder's call): one SVG source (`assets/branding/logo.svg`) drawn crisp in the
  app with flutter_svg; the launcher icon and splash PNGs are rendered from the same SVG, then
  `flutter_launcher_icons` and `flutter_native_splash` regenerate the platform files. Keeping a
  PNG in the app would blur at larger sizes.

## Palette (builder's call within the lead's choice; contrast checked)

| Role | Light | Dark |
|---|---|---|
| Background / surface | #F3F8FD / #FFFFFF | #07111F / #0F1C2E |
| Divider | #D8E4F0 | #1F3350 |
| Text / secondary text | #0B0F17 / #56677F (5.4:1) | #E8F1FF / #8FA3BF (6.7:1) |
| Primary (main buttons, white text) | #1565C0 (5.75:1) | #1B6ED4 (4.97:1) |
| Links, selected tabs and chips | #0D47A1 (8.1:1 on background) | #6CB6FF (8.8:1) |
| Progress rings, streak ring | #0097A7 (3.5:1, graphics) | #4DD0E1 |
| Sun highlight (pearls, celebrations) | #FFC93C, text on it #5C3D00 (6.4:1) | #FFC93C |
| Heat map (4 levels) | #E3F2FD → #90CAF9 → #42A5F5 → #1565C0 | #10233D → #174A80 → #1B6ED4 → #4DD0E1 |
| Logo, launcher and splash background | #1E88E5 | #1E88E5 |

- The sea, Gret, the café and the map keep their own illustration colours.
- The Kotlin intervention screen (`res/values/colors.xml`) follows: dark background #07111F, aqua
  #4DD0E1; colour names stay so the Kotlin code does not change.

## Where the logo appears

Hôm nay header (32), onboarding story (larger), launcher icon (adaptive: background #1E88E5,
foreground the logo inside the safe zone), splash screen (background #1E88E5).

## Non-goals

Changing the sea or character art; new screens; changing Gret.

## Left to the builder

Exact SVG paths, the padding of the adaptive foreground, which widgets take the sun highlight
beyond the pearl count.
