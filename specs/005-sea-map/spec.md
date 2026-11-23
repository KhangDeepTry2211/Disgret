# Feature Specification: Sea map (bản đồ biển)

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-24
**Status**: Implemented (2026-11-24)
**Input**: Project lead: "thiết kế phần thói quen mục tiêu như trang trại biển, khi tạo 1 thói quen
mục tiêu sẽ add 1 vùng biển xong khi làm mục tiêu Gret sẽ ngừng ở đó và đi khám phá vùng biển đó";
one region per goal, habits as discovery points, "như Genshin Impact mở map"; fog clears with the
number of days done. Design: `docs/superpowers/specs/2026-11-24-sea-map-design.md`, ADR-0010.

## User Scenarios & Testing

### User Story 1 - See my goals as a sea to explore (Priority: P1)

A student opens Thói quen → Bản đồ and sees one region per goal, each habit as a point, the parts
not explored yet under fog, a percentage per region and for the whole map, and Gret in the region
they studied last (S3).

**Acceptance Scenarios**:

1. **Given** two goals, **When** Bản đồ opens, **Then** two regions show with their goal titles and
   percentages.
2. **Given** a habit never done, **Then** its point shows "?"; **Given** it was done on 30 days,
   **Then** its point shows its icon and "30/66".
3. **Given** a goal with habits done 66 and 0 days, **Then** the region shows 50%.
4. **Given** a missed day, **Then** no percentage goes down.
5. **Given** the latest habit log belongs to goal B, **Then** Gret stands in B's region.

### User Story 2 - Explore a region (Priority: P2)

Tapping a region lists its points with "n/66 ngày" and the milestone; tapping a "?" point says which
habit discovers it.

### User Story 3 - Study in the goal's sea (Priority: P2)

A focus session for a habit is drawn in the terrain of that habit's region.

### Edge Cases

- A goal without habits: an empty region at 0% with an invitation to add a habit.
- Archived habits keep their point; habits deleted with their history disappear.
- Many goals: the map scrolls.
- Remove animations: the map is still.

## Requirements

- **FR-001**: Regions MUST follow the goals in order; terrain cycles coral, ice, deep, home.
- **FR-002**: Each habit of a goal (archived included) MUST be one point; days done = the habit's
  completed days (`HabitHistory.doneDays`).
- **FR-003**: Point progress = min(days, 66) / 66; milestones 7 / 21 / 40 / 66; region and total
  percentages as in the design; progress never decreases with time alone.
- **FR-004**: The Thói quen tab MUST offer the "Bản đồ" view (a map button in its app bar); the tab
  still opens on "Theo ngày".
- **FR-005**: The focus session sea MUST use the terrain of the session habit's region.
- **FR-006**: Nothing new is stored; text from `app_strings.dart`; colours from `app_theme.dart`;
  screen readers get region and point names with their progress.

## Success Criteria

- **SC-001**: From Hôm nay, the map is reachable in 2 taps (tab, map button).
- **SC-002**: Existing data shows on the map without migration.
