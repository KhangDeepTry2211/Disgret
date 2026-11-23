# Implementation Plan: Gret and the Living Sea

**Branch**: `feature/003-gret-ocean` | **Date**: 2026-11-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-gret-living-sea/spec.md`; approved design
`docs/superpowers/specs/2026-11-23-gret-ocean-redesign-design.md` (part 1 of 6).

## Summary

Add Gret, an original sea mascot, and a "living sea" whose clarity (0–100) is derived from the
existing study history: focused minutes raise it, distractions lower it, rest days keep it. Show it
on Hôm nay (hero scene, clarity ring, streak card), restyle onboarding around Gret (speech and
thought bubbles, "your sea is ready"), put the sea behind the running focus session (Gret focusing
or sleeping) and on the summary (Gret celebrating, "+N%"). Technically: one pure function
(`SeaClarity`) plus a mood mapping, a derived Riverpod provider, SVG-layered mascot via
`flutter_svg`, a `CustomPainter` sea, and built-in Flutter animations that respect "remove
animations". No stored data changes.

## Technical Context

**Language/Version**: Dart ^3.13.7, Flutter 3.47.x (verified locally on 3.50.1)

**Primary Dependencies**: flutter_riverpod 3, go_router 18, material_ui, hive; **new**:
`flutter_svg ^2.5.0` (research R4)

**Storage**: Hive, unchanged; clarity is derived in memory (data-model.md)

**Testing**: `flutter_test` unit tests (pure clarity and mood), widget tests (Hôm nay, onboarding,
focus, summary, reduced motion); manual emulator scenarios in quickstart.md

**Target Platform**: Android (Pixel emulator, API 34+); web only for quick UI iteration

**Project Type**: mobile app (single Flutter project with a Kotlin layer; Kotlin untouched)

**Performance Goals**: no visible stutter on the Pixel emulator while scrolling Hôm nay or switching
tabs; one animation controller per scene; recompute clarity only on data, phase, distraction or
focused-minute changes

**Constraints**: offline; no new permission; all UI colours from `app_theme.dart` (illustration
SVGs excepted by ADR-0008); Vietnamese strings from `app_strings.dart`; exactly one session entry on
Hôm nay (ADR-0002)

**Scale/Scope**: 4 screens restyled (onboarding, Hôm nay, focus running, summary), ~10 new widgets,
~12 SVG layer files, 2 pure modules, 1 provider file, 1 ADR

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
|---|---|---|
| I. Scenario-driven scope | Every story names S1/S2/S3 (spec); one primary action per screen kept; no second session entry (FR-009 keeps spec 001); no feed or social mechanics; parked features stay hidden. Gret is feedback, not rewards (no points, levels or badges) | Pass |
| II. Local-only privacy | No network at runtime, no new SDK that phones home (`flutter_svg` renders bundled assets), no new permission, no stored personal data | Pass |
| III. Data integrity | No model, box or field changes; clarity and mood rules are pure functions under `lib/data/` with unit tests | Pass |
| IV. Layered simplicity | Widgets read `seaStateProvider`; providers read repositories; no Hive or channel access in widgets. New dependency justified in research R4. Illustration colours are an exception to "colours only from app_theme.dart" → recorded in ADR-0008 and design-system.md | Pass with documented exception |
| V. Verified changes | Unit tests for new logic, widget tests for changed flows, format/analyze/test gates before merge; no Kotlin change, so no native checklist run is needed | Pass |
| VI. Spec-driven traceability | specify → plan → tasks done; ADR-0008 for the mascot and the colour exception; README demo script and decomposition map updated ("5.3 Gret và biển sống") | Pass |
| VII. Agent collaboration | Shared components touched (`app_theme.dart`, `app_strings.dart`, `app_providers.dart`-adjacent, `pubspec.yaml`): dependents checked with grep before editing; scope limited to this feature | Pass |

Post-design re-check (after data-model.md and contracts): unchanged, Pass.

## Project Structure

### Documentation (this feature)

```text
specs/003-gret-living-sea/
├── spec.md
├── plan.md              # this file
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── ui-gret-sea.md
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
assets/
├── mascot/gret/          # body, belly, cheeks, eyes_<mood>, mouth_<mood>, zzz, sparkles (.svg)
└── sea/                  # litter_bottle, litter_bag, fish (.svg) if not painted

lib/
├── data/
│   ├── sea_clarity.dart          # NEW pure rule (FR-001…FR-005)
│   └── mascot_mood.dart          # NEW enum + moodFor (FR-006)
├── providers/
│   └── sea_providers.dart        # NEW seaStateProvider, clarityGainProvider
├── l10n/app_strings.dart         # + greetings, sea labels, Gret lines
├── theme/app_theme.dart          # + AppSea, AppMascot, AppMotion; AppRadius.card 16, hero 24
├── widgets/
│   ├── mascot/{mascot_view.dart, mascot_look.dart, mascot_bubbles.dart}
│   ├── sea/{sea_scene.dart, sea_painter.dart, clarity_card.dart}
│   ├── motion/{staggered_entrance.dart, count_up_text.dart}
│   └── streak_card.dart
└── screens/
    ├── today_screen.dart         # restyled (FR-009, FR-010)
    ├── onboarding_screen.dart    # restyled (FR-011)
    ├── focus_screen.dart         # running view restyled (FR-012)
    └── summary_screen.dart       # restyled (FR-013)
lib/widgets/quiz_question_view.dart  # thought bubble + answer cards

test/
├── sea_clarity_test.dart         # NEW
├── mascot_mood_test.dart         # NEW
├── gret_sea_widgets_test.dart    # NEW (SeaScene, ClarityCard, reduced motion)
└── existing tests updated: navigation_test, widget_test, focus_screen_test, progress/summary tests

docs/
├── decisions/0008-gret-living-sea-feedback.md   # NEW ADR
└── architecture/design-system.md                # Gret and sea section, illustration palette
README.md                                        # demo script, map "5.3 Gret và biển sống"
pubspec.yaml                                     # flutter_svg, assets/mascot/, assets/sea/
```

**Structure Decision**: single Flutter project, existing layering (screens/widgets → providers →
repositories/services). New pure logic in `lib/data/` next to `habit_science.dart`; mascot and sea
widgets in their own subfolders so later features (outfits, species, themes) extend them in place.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Illustration SVGs carry their own colours (exception to Principle IV colour rule) | Multi-colour character art cannot be expressed as a single theme colour; artists need editable files | Painting Gret in Dart with theme colours makes the art hard to author, review and swap for later species and outfits |
| New dependency `flutter_svg` | Render layered SVG assets crisply at any size | `CustomPainter` only: see above; PNG: blurry scaling and larger files |
