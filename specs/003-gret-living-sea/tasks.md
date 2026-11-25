---
description: "Tasks for feature 003: Gret and the Living Sea (redesign part 1)"
---

# Tasks: Gret and the Living Sea

**Input**: `specs/003-gret-living-sea/` (plan.md, spec.md, research.md, data-model.md,
contracts/ui-gret-sea.md, quickstart.md); design doc
`docs/superpowers/specs/2026-11-23-gret-ocean-redesign-design.md`.

**Tests**: Required by Constitution V (new pure logic → unit tests; changed flows → widget tests).

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze` (0 issues)
and `flutter test` (0 failures) pass before the task is checked off.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no unfinished dependency)
- Paths are relative to the repository root.

## Phase 1: Setup

- [X] T001 Add `flutter_svg: ^2.5.0` to `pubspec.yaml`, register `assets/mascot/gret/` and
      `assets/sea/`, run `flutter pub get`. **Done when** the app builds and existing tests pass.
- [X] T002 [P] Write `docs/decisions/0008-gret-living-sea-feedback.md`: Gret and sea clarity are
      emotional feedback (no points, levels, badges) serving S2/S3, not the gamification parked by
      ADR-0004; illustration assets may carry their own colours from a documented palette;
      `flutter_svg` justification (research R4); references used for ideas only (research R9).
- [X] T003 [P] Add to `lib/theme/app_theme.dart`: `AppSea` (clear/murky water ×3 bands, day/night
      sky, moon, sand, seaweed, litter, fish, bubble), `AppMascot` (sizes per variant), `AppMotion`
      (durations and curves from research R6); change `AppRadius.card` to 16 and add
      `AppRadius.hero = 24`. List dependents with `grep -rn "AppRadius\." lib test` first.

## Phase 2: Foundational (blocks all stories)

- [X] T004 Write `test/sea_clarity_test.dart` for data-model.md rules: new user = 70; rest day keeps
      value; full day, partial day, distractions on a past day; today never below yesterday without
      distractions; −5 per distraction today; clamps at 0 and 100; 60-day window; 3 full days from
      40 reach ≥ 70 (SC-001); `todayWithout` for the summary gain. **Done when** tests fail.
- [X] T005 Implement `lib/data/sea_clarity.dart` (pure, constants from data-model.md) so T004
      passes.
- [X] T006 [P] Write `test/mascot_mood_test.dart` and implement `lib/data/mascot_mood.dart`
      (`MascotMood`, `moodFor`, thresholds 70/40, overrides) so it passes.
- [X] T007 Implement `lib/providers/sea_providers.dart`: build the per-day maps from
      `sessionRepositoryProvider`, `eventRepositoryProvider`, `allHabitsProvider` and
      `HabitSchedule` (research R1–R3), add the running session's focused minutes without double
      counting, expose `seaStateProvider` (clarity, mood, label) using a `select` on
      `focusSessionProvider`, and `clarityGainProvider` (research R7). Add provider tests to
      `test/providers_test.dart`.
- [X] T008 [P] Draw Gret's SVG layers in `assets/mascot/gret/` (240×200 viewBox, shared anchors):
      `body`, `belly`, `cheeks`, `eyes_{happy,neutral,sad,focused,sleeping,celebrating}`,
      `mouth_{happy,neutral,sad,focused,sleeping,celebrating}`, `zzz`, `sparkles`; palette as in the
      ADR. Gret is never drawn hurt (FR-008).
- [X] T009 Implement `lib/widgets/mascot/mascot_look.dart` (species + mood → ordered layer paths,
      reserved outfit slots) and `lib/widgets/mascot/mascot_view.dart` (layered `SvgPicture.asset`,
      bob 2.4 s, random blink, breathing for focused, rising "z" for sleeping, disabled when
      `MediaQuery.disableAnimationsOf`).
- [X] T010 [P] Implement `lib/widgets/mascot/mascot_bubbles.dart` (`SpeechBubble`,
      `ThoughtBubble`).
- [X] T011 Implement `lib/widgets/sea/sea_painter.dart` and `lib/widgets/sea/sea_scene.dart`
      (variants hero/full/compact, clarity colour lerp 800 ms, fish ≥ 70, litter < 40, day/night by
      brightness, one controller, `RepaintBoundary`, semantics label FR-018, `onMascotTap`).
- [X] T012 [P] Implement `lib/widgets/motion/staggered_entrance.dart` and
      `lib/widgets/motion/count_up_text.dart` (research R6, reduced motion = end state).
- [X] T013 [P] Implement `lib/widgets/sea/clarity_card.dart` and `lib/widgets/streak_card.dart`.
- [X] T014 Write `test/gret_sea_widgets_test.dart`: `SeaScene` semantics label per clarity;
      `ClarityCard` label thresholds; with `disableAnimations: true` no ticker remains active
      after pumping (`tester.binding.hasScheduledFrame` false).
- [X] T015 Add new strings to `lib/l10n/app_strings.dart` (contract "Strings"): greetings,
      `seaTitle`, clarity labels, `gretIntro`, `gretGoalPrompt`, `seaReady`, `clarityGain(n)`,
      `gretLines(MascotMood)` with five encouraging lines per mood.

**Checkpoint**: the pure rules, provider and reusable widgets exist and are tested.

## Phase 3: User Story 1 - See how my study habits are doing (P1) 🎯 MVP

- [X] T016 [US1] Restyle `lib/screens/today_screen.dart` per contract: header with greeting and
      "Biển của Gret", `SeaScene(hero)`, [`ClarityCard`, `StreakCard`], compact goal card,
      next-session card, single start control, all inside `StaggeredEntrance`; empty states with a
      neutral Gret; tap Gret → `SpeechBubble` with a mood line for 3 s.
- [X] T017 [US1] Update `test/navigation_test.dart` / `test/widget_test.dart` Hôm nay tests: exactly
      one session control (SC-003), sea and clarity card present, tapping Gret starts nothing, a
      distraction event today lowers the shown clarity by 5.

**Checkpoint**: Hôm nay shows the living sea; MVP demoable.

## Phase 4: User Story 2 - A first launch that makes me want to stay (P1)

- [X] T018 [US2] Restyle the intro and goal steps of `lib/screens/onboarding_screen.dart` (headline,
      `SpeechBubble`, `SeaScene(compact)`, reel-length pills) and add the "Biển của bạn đã sẵn
      sàng" moment (~1.2 s, skipped when replayed from Settings).
- [X] T019 [US2] Restyle `lib/widgets/quiz_question_view.dart`: small `MascotView` + `ThoughtBubble`,
      large answer cards, step dots, 400 ms happy reaction before advancing.
- [X] T020 [US2] Widget test: onboarding still saves reel length, quiz answers, first goal and
      habit; Back returns to the previous step; finishing lands on Hôm nay.

### Phase 4b: Story onboarding (amendment 2026-11-23)

Design: `docs/superpowers/specs/2026-11-23-story-onboarding-design.md`; spec FR-011, FR-011a.

- [X] T029 [US2] Write `test/onboarding_gret_test.dart` for the story: first page content, "Tiếp tục"
      through the four story pages, tap right/left, "Bỏ qua", auto-advance after 4 s and pause on
      hold (animations on), no auto-advance with animations removed, app page preselection and
      saving, no app page without native support. **Done when** the new tests fail.
- [X] T030 [US2] Add `BlockedAppsRepository.onboardingApps` and `BlockedAppsNotifier.replaceAll`;
      tokens `AppMotion.storyPage`, `AppStory`; strings for the story and the app question.
- [X] T031 [US2] Rebuild `lib/screens/onboarding_screen.dart` as an ordered list of pages with the
      story frame (progress segments, tap zones, auto-advance, skip), the four story pages sharing
      one `SeaScene` so the water changes in place, the app-choice page, and saving the app choice
      in `_finish`.
- [X] T032 [US2] Update the onboarding tests in `test/widget_test.dart` for the story pages and the
      app page; keep their checks on saved data.
- [X] T033 Update `contracts/ui-gret-sea.md` (Onboarding) to the story flow.

## Phase 5: User Story 3 - Study next to Gret (P2)

- [X] T021 [US3] Restyle the running view in `lib/screens/focus_screen.dart`: `SeaScene(full)`
      behind habit name, countdown ring, two stat cards; mood focused / sleeping; break text and
      "Tiếp tục"; "Kết thúc sớm" unchanged; water follows live clarity. Amendment 2026-11-23:
      `DistractionSwatLayer` + `ReactionWiggle` (FR-012a).
- [X] T022 [US3] Update `test/focus_screen_test.dart`: Gret focused while running, sleeping on a
      break, end-early confirmation unchanged.

## Phase 6: User Story 4 - Celebrate a finished session (P2)

- [X] T023 [US4] Restyle `lib/screens/summary_screen.dart`: `SeaScene(compact, celebrating)`,
      `CountUpText` "+N% độ trong" from `clarityGainProvider` (hidden when ≤ 0),
      `StreakCard(highlight: streakGrew)`; rating, note and save unchanged.
- [X] T024 [US4] Widget test: gain shown for a session with focused minutes, hidden for zero; streak
      highlight when the streak grew.

## Phase 7: Polish & cross-cutting

- [X] T025 [P] Update `docs/architecture/design-system.md` (English for edited parts): "Gret and
      the living sea" section, illustration palette, radius 16/24, motion tokens, reduced motion.
- [X] T026 [P] Update `README.md`: demo script (new onboarding, sea reacting to a distraction,
      summary gain) and decomposition map row "5.3 Gret và biển sống".
- [X] T027 Run the full gate and quickstart scenarios 1–7 on the Pixel emulator (light and dark);
      take screenshots of onboarding, Hôm nay, focus and summary for the team. Done 2026-11-24 in
      light mode on Pixel_8_API_35 (screenshots shared with the lead); dark mode is covered by the
      widget tests and the night-sea painter, not checked on the emulator (it needs a system
      setting change).
- [X] T028 Quickstart scenario 8 (upgrade from the previous APK keeps all data); mark spec status
      "Implemented". Done 2026-11-24: the new APK was installed over the lead's existing test data
      several times; goals, habits, sessions and the profile were kept.
- [X] T029 [P] Lively buttons, chosen by the lead from five styles (1, 2, 3 and 5; not 4
      hold-to-confirm): raised `GradientPillButton` that sinks when pressed, breathing hero
      "Bắt đầu", `BubbleBurst` for done moments (Lưu, obtain with pearls, habit tick) and
      `StickerChip` for the Thói quen filter and onboarding answers; `AppButton` tokens; reduced
      motion keeps only the press. Tests in `test/lively_buttons_test.dart`; checked on
      Pixel_8_API_35 on 2026-11-24; documented in design-system.md "Lively buttons".
- [X] T030 [P] Rippling "+" on Thói quen (style F from the second round of references):
      `RippleAddButton`, raised and sinking, two rings rippling out; endless while there is no
      habit, three pulses otherwise; none with reduced motion. Tests in
      `test/ripple_add_button_test.dart`. Not checked on the emulator (it was closed).

## Dependencies & order

- Phase 1 → Phase 2 (T004 → T005 → T007; T006, T008, T010, T012, T013 in parallel; T009 after
  T008; T011 after T009; T014 after T011–T013; T015 any time) → US1 → US2 → US3 → US4 → Polish.
- US2, US3 and US4 only depend on Phase 2 and can be reordered.

## Parallel examples

- Phase 1: T002 and T003 in parallel after T001.
- Phase 2: T006, T008, T010, T012, T013 in parallel once T003 is done.

## Implementation strategy

MVP = Phases 1–3 (Hôm nay with the living sea). Then onboarding (US2), the session (US3) and the
summary (US4). Each phase ends with the gate green and a runnable app on the emulator.
