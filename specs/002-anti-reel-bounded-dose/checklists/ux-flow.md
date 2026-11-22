# Requirements Quality Checklist: Dose Flow, Measurement and Data Safety — Feature 002

**Purpose**: Unit tests for the requirements of feature 002, for the reviewer before
implementation.
**Created**: 2026-11-22
**Depth / audience / focus**: Standard / reviewer / bounded-dose flow + measurement + data safety.
**Feature**: [spec.md](../spec.md)

## Requirement Completeness

- [x] CHK001 Are playlist limits defined per context? [Spec FR-002]
- [x] CHK002 Is every exit from the step (start, small step, next, skip, back, background) given an
      outcome? [contracts/motivation-step.md]
- [x] CHK003 Are failure cases (no eligible reel, video error) specified? [Edge Cases]
- [x] CHK004 Is the after-distraction variant fully specified, including absence of "Bỏ qua"?
      [Spec US2, contract]

## Requirement Clarity

- [x] CHK005 Is "plays once" testable (no restart, no auto-advance)? [Spec FR-003, SC-002]
- [x] CHK006 Is "watched to the end" defined with a tolerance? [Research R2]

## Measurement

- [x] CHK007 Can the share of openings followed by a start be computed from the specified events
      alone? [Spec SC-005, data-model.md]
- [x] CHK008 Is the skip event's meta defined? [data-model.md `motivation_skipped`]

## Data Safety

- [x] CHK009 Is it specified that old social events still parse? [Research R4, data-model.md]
- [x] CHK010 Is deletion of retired boxes limited to an explicit user reset, and recorded in an ADR?
      [ADR-0003 updated, Research R4]

## Consistency

- [x] CHK011 Do end-card actions match spec 001 FR-007? [Spec FR-004]
- [x] CHK012 Does the "Bỏ qua" definition agree between spec US1 AS6 and the contract? [Spec US1
      AS6 now says "before-session step"]
