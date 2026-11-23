---
description: "Tasks for feature 002: anti-reel motivation as a bounded dose"
---

# Tasks: Anti-reel Motivation as a Bounded Dose

**Input**: `specs/002-anti-reel-bounded-dose/` (plan.md, spec.md, research.md, data-model.md,
contracts/motivation-step.md, quickstart.md)

**Prerequisite**: feature 001 tasks T001–T007 merged (routes, `StudyStarter`, plan). 001-T011
(start actions) is implemented inside T007 here when 002 follows 001 directly.

**Tests**: Required by Constitution V.

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test` all pass.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [X] T001 Add motivation-step strings to `lib/l10n/app_strings.dart` ("Bỏ qua", "Tiếp", "Quay lại
      học", "Chỉ 5 phút thôi", position label).

## Phase 2: Foundational

- [X] T002 [P] Write `test/motivation_dose_test.dart` for data-model.md `MotivationDose.playlist`,
      `.index`, `.phase` transitions: `playing` → `endCard` on end or error; `next()` only in
      `start` with remaining reels; `skip`/`start`/`backToSession` → `done`; empty playlist → `done`;
      end-card actions per context. **Done when** tests exist and fail.
- [X] T003 Implement `lib/services/motivation_dose.dart` so T002 passes.
- [X] T004 [P] Update `test/reel_recommender_test.dart`: no liked-tags bonus; `limitFor('start')` = 3,
      `limitFor('distracted')` = 1; pinned first unchanged. Then change
      `lib/services/reel_recommender.dart` (remove `likedReelIds`, add `limitFor`).
- [X] T005 Add `EventType.motivationSkipped` (data-model.md `motivation_skipped.context`,
      `.position`) and `EventRepository.logMotivationSkipped` in `lib/data/models/event.dart` and
      `lib/data/repositories/event_repository.dart`; annotate the four social values as never
      logged; unit test in `test/data_test.dart` that old `reel_liked` events still parse.

## Phase 3: User Story 1 — Bounded boost before studying (P1) 🎯 MVP

**Independent test**: quickstart scenarios 1–3.

- [X] T006 [P] [US1] Widget tests `test/motivation_screen_test.dart` (fake video platform from
      `test_helpers.dart`): position "1/3"; vertical/horizontal drag does not change reel (FR-001);
      no loop and end card on end (FR-003, FR-004); "Tiếp" only when a reel remains; "Bỏ qua" calls
      `StudyStarter` with plan minutes; tap toggles pause (FR-006); no like/comment/share widgets
      (FR-007).
- [X] T007 [US1] Implement `lib/screens/motivation_screen.dart` (single `VideoPlayerController` per
      reel, `setLooping(false)`, preload next, blurred background kept) and
      `lib/widgets/reel_end_card.dart` (start actions wired to `StudyStarter`, covering 001-T011);
      route `/motivation` to it; delete
      `lib/screens/reels_screen.dart` and `test/reels_screen_test.dart` (moving still-relevant cases
      — watch-time accounting, background save, small-screen overflow — into T006's file).
- [X] T008 [US1] Edge cases: empty playlist → start session directly; video error → end card
      immediately; system Back in `start` → `/today` without session; app paused → pause video and
      log once.

## Phase 4: User Story 2 — One reel after a distraction (P1)

**Independent test**: quickstart scenario 4.

- [X] T009 [P] [US2] Widget tests: `context=distracted` shows exactly one reel (pinned first), no
      "Tiếp", no "Bỏ qua", end card only "Quay lại học" → `/focus`; clock paused while open and
      resumed after (FR-011).
- [X] T010 [US2] Implement distracted behaviour in `motivation_screen.dart` / `MotivationDose`.
- [ ] T011 [US2] Manual check on emulator with `docs/architecture/native-manual-checklist.md`
      (item "Xem 1 reel động lực") plus quickstart scenario 4: one reel → back to session; record the
      result in the commit message.

## Phase 5: User Story 3 — Measurement (P2)

**Independent test**: quickstart scenario 6.

- [X] T012 [P] [US3] Tests: one `reel_watched` per reel shown with `startedFocus` true only after a
      start action; `motivation_skipped` with context and position on skip; stats view has no
      "Reel đã thích" (FR-008, FR-010, SC-005).
- [X] T013 [US3] Wire logging in `motivation_screen.dart`; remove `reelsLiked` from
      `lib/services/focus_stats.dart` and its row in `lib/screens/stats_screen.dart` (now
      `StatsView`); update `test/stats_test.dart`.

## Phase 6: User Story 4 — Social features removed safely (P3)

**Independent test**: quickstart scenarios 5 and 7.

- [ ] T014 [US4] Delete `lib/widgets/reel_action_column.dart`, `lib/widgets/reel_comments_sheet.dart`,
      `lib/services/reel_share.dart`, `lib/data/models/reel_comment.dart`,
      `lib/data/models/reel_reaction.dart`, `lib/data/repositories/reel_comment_repository.dart`,
      `lib/data/repositories/reel_reaction_repository.dart`, `test/reel_social_test.dart`; remove
      their providers from `app_providers.dart`, sample likes/comments from `mock_data.dart`, like
      tokens from `app_theme.dart`; remove `share_plus` from `pubspec.yaml` and run `flutter pub get`.
- [ ] T015 [US4] `lib/data/hive_boxes.dart`: move `reel_reactions`, `reel_comments` to `retired` (not
      opened); `clearUserData()` also deletes retired boxes from disk; test in `test/data_test.dart`
      that start-up with pre-existing retired boxes succeeds (FR-009, SC-006).

## Phase 7: Polish

- [ ] T016 Update `README.md` demo script (reel step) and the references to the Reels tab, likes and
      comments in `docs/architecture/design-system.md` and `docs/architecture/data-model.md`.
- [ ] T017 Run full gate + quickstart; verify `grep -rn "share_plus\|ReelComment\|ReelReaction" lib
      test pubspec.yaml` is empty; mark spec "Implemented".

## Dependencies & order

Phase 1 → Phase 2 (T002 → T003; T004, T005 parallel) → US1 → US2 → US3 → US4 → Polish. US4 (T014,
T015) can run right after T007 because the old screen is gone by then.

## Parallel examples

T002 ∥ T004 ∥ T005; T006 ∥ T009 ∥ T012 (test files), then implementations.

## Implementation strategy

MVP for 2026-11-24 = US1 + US2 + US4 (social removal is cheap once the old screen is deleted). US3
logging is small and should ship together.
