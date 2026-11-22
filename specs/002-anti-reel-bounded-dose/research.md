# Research: Anti-reel Motivation as a Bounded Dose

## R1. State machine outside the widget

- **Decision**: `MotivationDose` (pure Dart) holds `playlist`, `index`, `phase` (`playing`,
  `endCard`, `done`) and `context`; methods `videoEnded()`, `next()`, `skip()`, `start(minutes)`.
  It answers `canGoNext`, `positionLabel` ("1/3") and which end-card actions to show.
- **Rationale**: Constitution IV/V — the rules (bounded playlist, no loop, which actions) become
  unit-testable without video playback.
- **Alternatives**: keep logic in the `State` like the current feed (hard to test, as the existing
  `reels_screen_test.dart` shows).

## R2. Playback once, end detection

- **Decision**: `VideoPlayerController.asset(...)..setLooping(false)`; end = initialised, not
  playing, and `position >= duration - 1 s` (same tolerance as `ReelWatchTracker`). On error the end
  card appears immediately. The next reel's controller is created when the current one starts.
- **Rationale**: matches existing tracker tolerance; preload avoids a visible pause on "Tiếp".

## R3. Recommender changes

- **Decision**: remove the `likedReelIds` parameter and the liked-tags point; add
  `limitFor(context)` = 3 for `start`, 1 for `distracted`. Pinned-first, tag score and
  recently-watched penalty are unchanged.
- **Rationale**: FR-002; keeps the personalisation that is the feature's differentiator.

## R4. Retired social data

- **Decision**: remove `reel_reactions` and `reel_comments` from `HiveBoxes.all` (never opened, never
  read). Keep their names in `HiveBoxes.retired` so they are never reused. Keep `EventType`
  values `reel_liked`, `reel_unliked`, `reel_commented`, `reel_shared` (annotated as no longer
  logged) because `EventType.fromValue` throws on unknown values and old devices have such events.
  `clearUserData()` ("Xoá toàn bộ dữ liệu", an explicit user reset) also deletes retired boxes from
  disk.
- **Rationale**: ADR-0003 and Constitution III (no silent deletion; an explicit full reset is the
  user's own action). Keeping enum values is the smallest safe change.
- **Alternatives**: make `fromValue` fall back to a default type (changes semantics of every old
  event); keep opening the boxes (keeps dead code alive).
- **Follow-up**: ADR-0003 gets one line noting the explicit-reset exception.

## R5. Events

- **Decision**: keep `reel_watched` (reelId, secondsWatched, completed, startedFocus) logged once
  per reel shown, when the user leaves that reel (next, start, skip, back, app paused). Add
  `motivation_skipped` with meta `context` and `position` (1-based index when skipped). Watching
  under 1 s is not logged unless it led to a start (existing rule).
- **Rationale**: FR-008, SC-005; H1 = share of openings followed by a start.

## R6. Shared components and dependents (code search)

| Symbol | Dependents |
|---|---|
| `ReelsScreen`, `ReelsScreen.quickStartMinutes` | `app_router.dart`, `reels_screen_test.dart` (feature 001 already moves the route) |
| `reelLikesProvider`, `reelCommentsProvider`, repositories | `reels_screen.dart`, `reel_action_column.dart`, `reel_comments_sheet.dart`, `focus_stats.dart` via `focusStatsProvider`, `mock_data.dart`, `reel_social_test.dart` |
| `ReelRecommender.recommend(likedReelIds:)` | `reels_screen.dart`, `reel_recommender_test.dart` |
| `HiveBoxes.all` | `main.dart` (`openAll`), `clearUserData` callers in settings, `test_helpers.dart` |
| `AppReels.*`, `AppColors.reelLiked` | `reels_screen.dart`, `reel_action_column.dart` |

These symbols were not yet queried in the Graphify graph. The first graph (2026-11-22) misses some
Dart references (see `docs/architecture/codebase-graph.md`), so the grep list above stands; run
both `graphify explain` and `grep` for each symbol before implementing.

## R7. Blurred background

- **Decision**: keep the current "whole video over its own blur" layout (`AppReels.blurBackground`);
  drop gradient overlays tied to social controls, keep the overlay that keeps title text readable.
- **Rationale**: visual polish is priority 5; reuse working code.
