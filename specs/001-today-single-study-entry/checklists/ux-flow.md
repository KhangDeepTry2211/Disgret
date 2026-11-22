# Requirements Quality Checklist: UX Flow and Data Safety — Feature 001

**Purpose**: Unit tests for the requirements (not the implementation) of feature 001, for the
reviewer before implementation.
**Created**: 2026-11-22
**Depth / audience / focus**: Standard / reviewer / navigation flow + data safety (defaults; no
extra questions asked because the user's earlier answers fixed scope).
**Feature**: [spec.md](../spec.md)

## Requirement Completeness

- [x] CHK001 Are all entry points into a session enumerated, including the Thói quen card shortcut?
      [Completeness, Spec FR-004, Tasks T014]
- [x] CHK002 Is the behaviour of "Bắt đầu" while a session is running specified? [Spec FR-008]
- [x] CHK003 Are all native intervention outcomes mapped to a destination? [Spec FR-009,
      contracts/navigation.md]
- [x] CHK004 Are the empty states of Hôm nay (no goal, no habit, all done, rest day) defined?
      [Edge Cases]
- [x] CHK005 Is the Settings entry point on Hôm nay covered by a test? [Spec FR-015, Tasks T008]

## Requirement Clarity

- [x] CHK006 Is "planned duration" defined unambiguously? [Spec FR-007, Research R1]
- [x] CHK007 Is "small streak indicator" bounded so it cannot grow back into a dashboard? [Spec
      FR-002 excludes list and strength]
- [x] CHK008 Is "persistent banner" content specified (what it shows)? [Spec FR-008]

## Consistency

- [x] CHK009 Do spec 001 FR-010 and spec 002 FR-011 describe the same clock-pause behaviour?
      [Consistency]
- [x] CHK010 Do the removed routes in the contract match FR-012 and FR-014? [Consistency]

## Acceptance Criteria Quality

- [x] CHK011 Is SC-001 (≤2 taps) objectively measurable? [Measurability]
- [x] CHK012 Is SC-006 (hallway test, 5 seconds) traceable to a task that runs it? [Tasks T028]

## Data Safety

- [x] CHK013 Is "no persisted change" stated and is upgrade preservation testable? [Spec FR-016,
      SC-005, Tasks T026]
- [x] CHK014 Is the fate of `HabitCard` decided? [ADR-0004: parked, Tasks T002/T015]
