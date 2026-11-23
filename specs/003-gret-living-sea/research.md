# Research: Gret and the Living Sea (003)

## R1. Where the study data comes from

- **Decision**: Minutes studied come from **habit logs**: `manual` counts the habit's full
  minimum, `minimal` half of it, `focus` its real minutes (saved sessions write one focus log
  `focus_<sessionId>`), each habit capped at its minimum; `freeze` removes the habit from that
  day; `skip` counts nothing. Distractions come from `session_distracted` events (`time` day).
  Today additionally adds the running session's focused minutes from `focusSessionProvider`; its
  distractions are already logged as events the moment they happen.
- **Rationale**: The first draft counted only focus-session minutes; users who tick habits by hand
  (running, reading) would see a murky sea while keeping up. Habit logs are what streaks and
  strength already use. Events are written at distraction time, so a distraction is visible as
  soon as the user returns (SC-002).
- **Double counting**: running-session minutes are added only while its phase is `running`; the
  summary's gain leaves out the log `focus_<sessionId>` and adds the session back as live minutes,
  so the value is the same before and after saving.
- **Alternatives considered**: `Session.focusedSeconds` (ignores manual ticks);
  `Session.distractionCount` (misses unsaved sessions); storing a daily clarity in Hive (new box and
  migration rules, violates FR-001).

## R2. Daily target minutes

- **Decision**: target(day) = sum of `minMinutesPerDay` of habits planned that day:
  `HabitSchedule.isScheduledOn` (which includes `isActiveOn`), except weekly-by-count habits, which
  count only on days they were done; archived habits count for past days only; a frozen habit is
  left out. If the target is 0 but the user studied, 25 minutes is used.
- **Rationale**: `isDueOn` for "N days a week" depends on completions earlier in the week, and
  counting such habits every day would make the sea murky on legitimate off days.

## R3. History window and performance

- **Decision**: Replay at most the last 60 days, starting from 70 at the first day of the window that
  has any habit or session data (or 70 when there is none). Group sessions and events by day once
  (maps keyed by `dateKey`) before replaying.
- **Rationale**: With β = 0.3, the influence of a day 60 days ago is 0.7^60 ≈ 5e-10, so older days
  cannot change the result. Keeps the pure function O(days + records).

## R4. Rendering Gret: SVG layers

- **Decision**: Add `flutter_svg` (2.5.0, resolves with the current lock file; maintained under the
  Flutter "flutter.dev" verified publisher; pulls `vector_graphics*` and `path_parsing`). Gret is a
  `Stack` of `SvgPicture.asset` layers sharing one 240×200 viewBox: `body`, `belly`, `cheeks`,
  `eyes_<mood>`, `mouth_<mood>`, plus extras (`zzz`, `sparkles`). Assets live in
  `assets/mascot/gret/`.
- **Rationale**: Shared canvas and anchors let later features add outfit layers and species without
  touching mood logic (FR-020); SVG files can be edited or replaced by anyone without Dart code.
- **Alternatives considered**: `CustomPainter` only (no dependency, but hard to author and review
  shapes in code, and later art swaps need Dart changes); Rive (needs a Rive artist, see design
  doc 4.2); PNG (no crisp scaling, heavier).
- **Colour rule**: illustration assets carry their own fills, limited to the documented Ocean +
  pastel palette (design-system.md "Illustration palette"); ADR-0008 records this exception to
  "colours only from app_theme.dart".

## R5. Sea scene

- **Decision**: `SeaScene` draws sky, three wave bands, sand, seaweed, bubbles, fish and litter
  with a `CustomPainter` using `AppSea` tokens; the water colours are `Color.lerp` between clear and
  murky tokens by clarity (animated with an implicit `TweenAnimationBuilder`, 800 ms). One
  `AnimationController` (repeat, 8 s) drives wave phase, bubbles and fish positions.
- **Rationale**: Continuous motion and colour blending are simpler in a painter than in SVG; the
  painter reads only theme tokens, so it obeys the colour rule.
- **Variants**: `hero` (≈200 dp tall), `full` (fills its parent), `compact` (≈150 dp).
- **Night sea**: chosen from `Theme.of(context).brightness`; sky `AppColors.darkBackground` with a
  moon, darker water tokens.

## R6. Motion without new dependencies

- **Decision**: Use Flutter's built-in animation APIs: a small `StaggeredEntrance` widget
  (`AnimationController` + `Interval` per child: opacity 0→1, offset 12 dp→0, 280 ms, 60 ms step,
  `Curves.easeOutCubic`), `TweenAnimationBuilder` for count-up numbers and ring fill, and
  controllers for Gret's bob (2.4 s, ±4 dp) and blink (random 3–6 s, 120 ms).
- **Reduced motion**: every animated widget checks `MediaQuery.disableAnimationsOf(context)`; when
  true it renders the end state and starts no controller.
- **Off-screen**: tabs live in an indexed stack; `TickerMode` already mutes tickers of hidden tabs.
  Scenes are wrapped in `RepaintBoundary`.
- **Alternatives considered**: `flutter_animate` (concise, but another dependency for effects
  that are ~150 lines of plain Flutter).

## R7. Clarity gain on the summary

- **Decision**: gain = clarityToday(with the finished session) − clarityToday(without that
  session's focused minutes and without distraction events after its start), both from the same
  pure function, rounded to whole percent and hidden when ≤ 0.
- **Rationale**: Needs no stored "clarity at start" and stays correct if the user lingers on the
  summary.

## R8. Corner radius change

- **Decision**: `AppRadius.card` 12 → 16 and new `AppRadius.hero = 24`. Existing tests do not
  assert radii (checked with `grep -rn "AppRadius" test`).
- **Rationale**: FR-019; the rounder look of the approved mockups.

## R9. Visual references and licensing

- **References**: the iOS app *Brainrot: Screen Time Control* (mascot whose world reacts to
  behaviour) and the "Farm App UI Kit" by DailyFlutterUI (Instagram reel `DeEIdFhJ8Az`, sold on
  Payhip for USD 16 with full Flutter source; hero illustration, health ring card, quick-stat
  cards, top-down zone map, bottom detail card, staggered entrance animations).
- **Decision**: take only layout and motion ideas. No code, image, character or text is copied
  from either product. The Payhip page states no licence, so its source must not be used in
  DisGret unless the team buys it and the licence explicitly allows reuse in an app.

## R10. Flutter version on dev machines

- The repository targets Flutter 3.47.x; the current dev machine runs 3.50.1, which requires
  Android Gradle Plugin ≥ 9.1.1 (the project pins 9.1.0). Building there needs
  `--android-skip-build-dependency-validation`. Bumping AGP is out of scope for this feature and is
  left to the team.
