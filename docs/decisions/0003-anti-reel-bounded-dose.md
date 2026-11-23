# ADR-0003: Anti-reel reels as a bounded dose, no social features

- Status: Accepted
- Date: 2026-11-22

## Context

`ReelsScreen` copies the infinite-feed pattern: vertical `PageView`, autoplay with looping, likes,
comments, share. The team's own risk register rates "Reels is a scrolling tab, contrary to the goal"
as High, and it weakens hypothesis H1 (the right reel helps the user start faster). The real
differentiator is personalisation by motivation profile.

## Decision

- Replace `ReelsScreen` with `MotivationScreen`: no vertical swiping.
- Playlist from `ReelRecommender`: up to 3 reels in context `start`, exactly 1 (pinned first) in
  context `distracted`.
- Each reel plays once, without looping, then shows an end card: "Bắt đầu 5 phút" plus "Tiếp" when
  more reels remain (`start`), or "Quay lại học" (`distracted`). "Bỏ qua" is always available.
- Delete likes, comments and share completely: `reel_action_column`, `reel_comments_sheet`,
  `reel_share`, the `ReelReaction` / `ReelComment` models, repositories and providers, the
  liked-tags scoring rule, the "Reel đã thích" statistic, their tests, and `share_plus` (no other
  usage).
- Stop opening the `reel_reactions` and `reel_comments` Hive boxes. Their names stay reserved so
  that old on-device data is never misread. They are deleted from disk only when the user runs the
  explicit "clear all data" reset. The social `EventType` values stay defined (never logged) so old
  events still parse.
- Keep the `reel_watched` event (with `startedFocus`); add `motivation_skipped` so skips are
  measurable.

Implemented by feature 002 (2026-11-23). The end-card start actions follow spec 001 FR-007:
"Bắt đầu N phút" (planned duration) and "Chỉ 5 phút thôi". "Bỏ qua" is available before a session
only; after a distraction the end card offers just "Quay lại học".

## Consequences

- Less engagement may lower motivation; R2.1 (motivation score before/after) must be watched in the
  experiment.
- Bundled Instagram videos remain (see ADR-0007).
