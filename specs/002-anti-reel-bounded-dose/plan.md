# Implementation Plan: Anti-reel Motivation as a Bounded Dose

**Branch**: `feature/002-anti-reel-bounded-dose` | **Date**: 2026-11-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-anti-reel-bounded-dose/spec.md`

**Depends on**: feature 001 (routes `/motivation`, `StudyStarter`, session plan, clock pause)

## Summary

Replace the vertical `PageView` feed in `reels_screen.dart` with `MotivationScreen`, driven by a pure
`MotivationDose` state machine: a finite playlist (≤3 for `start`, 1 for `distracted`) from
`ReelRecommender`, each reel played once without looping, then an end card with "Bắt đầu N phút" /
"Chỉ 5 phút thôi" / "Tiếp" (start) or "Quay lại học" (distracted). Log `reel_watched` per reel shown
and a new `motivation_skipped` event. Delete likes, comments, share and `share_plus`; stop opening
the two social Hive boxes while keeping old data readable-safe.

## Technical Context

**Language/Version**: Dart SDK ^3.13.7, Flutter 3.47.9

**Primary Dependencies**: video_player (existing), flutter_riverpod, go_router. Removes `share_plus`.
No new dependency.

**Storage**: Hive `events` box (adds one event type); `reel_reactions` / `reel_comments` boxes retired

**Testing**: unit tests for `MotivationDose` and recommender; widget tests with the existing fake
video player platform (`video_player_platform_interface` dev dependency, `test_helpers.dart`)

**Target Platform**: Android; web for UI iteration (no blurred background)

**Project Type**: mobile-app

**Performance Goals**: next reel's controller is pre-initialised while the current one plays, so
"Tiếp" starts playback without a visible load in the common case

**Constraints**: local-only; old event types in stored data must still parse (Constitution III)

**Scale/Scope**: 1 screen rewritten, 1 pure service added, ~9 files deleted, 4 test files changed

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. Scenario-Driven Scope | Removes feed and social mechanics; S1/S2 mapped; bounded playlist | Pass |
| II. Local-Only Privacy | Removes the only sharing path (`share_plus`); events stay local | Pass |
| III. Data Integrity | Retired boxes never read; social `EventType` values kept so old events parse; deletion only on explicit "clear all data" (see research R4) | Pass with note R4 |
| IV. Layered Simplicity | Dose logic pure in `lib/services/motivation_dose.dart`; widget renders state; one dependency removed | Pass |
| V. Verified Changes | Unit tests for dose + recommender; widget tests for end card, no swipe, no loop, skip, distracted | Pass (to verify) |
| VI. Traceability | ADR-0003 implemented; README demo script updated (reel step) | Pass |
| VII. Agent Collaboration | Shared files: `app_providers.dart`, `hive_boxes.dart`, `event.dart`, `app_theme.dart`, `mock_data.dart`, `focus_stats.dart`; dependents in research R6 | Pass |

Post-design re-check: unchanged.

## Project Structure

### Documentation (this feature)

```text
specs/002-anti-reel-bounded-dose/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/motivation-step.md
├── checklists/requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── services/motivation_dose.dart     # NEW: pure playlist/phase state machine
├── services/reel_recommender.dart    # drop likedTags; limit by context (modify)
├── services/reel_watch_tracker.dart  # unchanged (looping path becomes unused)
├── services/focus_stats.dart         # drop reelsLiked (modify)
├── services/reel_share.dart          # DELETE
├── screens/motivation_screen.dart    # NEW (replaces reels_screen.dart, which is deleted)
├── screens/stats_screen.dart         # drop "Reel đã thích" row (modify)
├── widgets/reel_end_card.dart        # NEW
├── widgets/reel_action_column.dart   # DELETE
├── widgets/reel_comments_sheet.dart  # DELETE
├── data/models/event.dart            # + motivationSkipped; social values kept, never logged (modify)
├── data/models/reel_comment.dart     # DELETE
├── data/models/reel_reaction.dart    # DELETE
├── data/repositories/event_repository.dart        # + logMotivationSkipped (modify)
├── data/repositories/reel_comment_repository.dart # DELETE
├── data/repositories/reel_reaction_repository.dart# DELETE
├── data/hive_boxes.dart              # retired box list; not opened (modify)
├── data/mock_data.dart               # drop likes/comments sample data (modify)
├── providers/app_providers.dart      # drop reel likes/comments providers (modify)
└── theme/app_theme.dart              # drop like/heart tokens; keep overlay tokens (modify)

test/
├── motivation_dose_test.dart         # NEW
├── motivation_screen_test.dart       # NEW (replaces reels_screen_test.dart)
├── reel_recommender_test.dart        # update (no likedTags, per-context limit)
├── stats_test.dart, data_test.dart   # update
└── reel_social_test.dart             # DELETE
pubspec.yaml                          # remove share_plus
```

**Structure Decision**: same single Flutter project layout as feature 001.

## Complexity Tracking

No constitution violations.
