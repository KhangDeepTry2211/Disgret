# ADR-0008: Gret and the living sea as emotional feedback

- Status: Proposed (feature 003, 2026-11-23; needs the project lead's approval)
- Date: 2026-11-23

## Context

DisGret is going to real users. Testers find the app usable but not attractive on first launch.
The team looked at the iOS app *Brainrot: Screen Time Control*, whose users say they keep going
because they "don't want to hurt" its mascot, and at a Flutter "Farm App UI Kit" for layout and
motion. ADR-0004 parked achievements, badges and the level-up dialog because gamification did not
serve S1–S3 and competed with the single study entry.

## Decision

- Add **Gret**, an original round sea creature, and a **sea clarity** score (0–100) derived from
  the existing study history (focused minutes up, distractions down, rest days neutral). Gret's
  mood and the water colour show the score on Hôm nay, during the session and on the summary.
- Gret is **feedback, not a reward system**: no points, levels, badges or unlocks in this feature,
  no second entry into a session, no new tab. It serves S2 (a distraction visibly clouds the sea)
  and S3 (several good days visibly clear it). Gret is never shown hurt and never blames the user.
- **Illustration exception to the colour rule**: files under `assets/mascot/` (and `assets/sea/`
  if added) may contain their own fills, limited to the Ocean palette and the pastel habit palette
  documented in `docs/architecture/design-system.md`. UI chrome and the painted sea still take
  every colour from `lib/theme/app_theme.dart`.
- **New dependency `flutter_svg` (^2.5.0)** to render the layered mascot. It renders bundled assets
  only, makes no network calls and is published by the Flutter team's verified publisher.
  Alternatives: `CustomPainter` only (hard to author and swap art), Rive (needs a Rive artist), PNG
  (blurry scaling, heavier).
- References (Brainrot, Farm App UI Kit) inspire ideas only. No code, art, character or text is
  copied; the UI kit states no licence.

## Consequences

- No stored data changes; clarity is recomputed from sessions, events and habits.
- Later features (outfits, new mascots, pearls, themes, sea farm, real-money purchases) will need
  their own ADRs, because they do bring back reward mechanics and, for purchases, network access.
- The Kotlin intervention screen keeps its look until the feature that adds Gret there.
