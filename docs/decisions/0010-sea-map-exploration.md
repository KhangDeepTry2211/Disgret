# ADR-0010: The 66-day journey returns as the sea map

- Status: Accepted (project lead, chat 2026-11-24)
- Date: 2026-11-24
- Related: ADR-0004 (gamification parked, including "Hành trình 66 ngày"), ADR-0008, ADR-0009,
  spec 005, design `docs/superpowers/specs/2026-11-24-sea-map-design.md`

## Context

ADR-0004 parked the 66-day journey and its badges (7 / 21 / 40 / 66 days) because they showed up as
extra scores on the habit cards and pulled attention from the one thing to do today. The lead wants
goals and habits shown as a sea to explore: one region per goal, one point per habit, fog that
clears as habits are practised.

## Decision

- Bring the 66-day journey back only as the sea map in the Thói quen tab ("Bản đồ" view): a point is
  fully explored after 66 days done (not necessarily in a row), with milestones 7 / 21 / 40 / 66.
- Progress never decreases: missed days do not bring fog back, nothing is lost.
- No points, pearls or other rewards for exploring; no ranking or comparison.
- The map is computed from existing goals, habits and habit logs; nothing new is stored.
- The rest of ADR-0004 stays parked (achievement levels, level badges, the old habit card).

## Consequences

- New pure logic (`lib/data/sea_map.dart`) with unit tests; a painter and a view in the Thói quen
  tab; the focus session uses the terrain of the habit's region.
- The parked `lib/widgets/habit_journey.dart` is not reused; the milestones live in the new logic.
