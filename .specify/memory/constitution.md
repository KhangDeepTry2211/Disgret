# DisGret Constitution

## Core Principles

### I. Scenario-Driven Scope

- Every user-facing screen, flow and feature MUST name, in its spec, the scenario it serves
  (S1 hard to start, S2 distracted mid-session, S3 keeping it up over several days) and the
  evaluation criterion (R-code) it moves. Work that serves none of them is out of the MVP.
- Each screen has one primary action. A second competing entry into a study session MUST NOT be
  added (ADR-0002).
- Infinite-feed and social mechanics are forbidden: no vertical feed of videos, no autoplay loop,
  no likes, comments, shares or follower counts (ADR-0003).
- Parked features (ADR-0004) MUST stay unreachable from the UI until an ADR brings them back.

Rationale: the product exists to help students start and return to studying; anything that
rewards browsing works against the goal and weakens the hypotheses being tested.

### II. Local-Only Privacy

- All user data MUST stay on the device (Hive). The MVP MUST NOT add a backend, accounts, cloud
  sync, remote analytics, crash reporting or advertising SDKs.
- The app MUST NOT make network requests at runtime. Fonts and videos are bundled.
- Recorded events MUST NOT contain personal identifiers. The list of installed apps and the
  blocked-app list never leave the device.
- Any future data export MUST be an explicit user action and MUST produce anonymised data.
- A new Android permission MUST be justified in an ADR before it is added to the manifest.

Rationale: users include high-school students, many under 18; collecting nothing is the
simplest defensible privacy position.

### III. Data Integrity and Backward Compatibility

- Data written by any earlier released version MUST remain readable. New model fields MUST have
  defaults; unknown enum values MUST map to a default instead of throwing.
- Hive box names are never reused for a different shape of data. Retired boxes
  (`reel_reactions`, `reel_comments`) are listed as reserved and are simply no longer opened;
  existing user data MUST NOT be deleted without an ADR.
- Rules that decide completion, streaks, strength scores, schedules and statistics MUST live in
  pure functions under `lib/data/` or `lib/services/` and MUST be covered by unit tests.

Rationale: streaks and logs are the user's history and the experiment's evidence; silent data
loss would invalidate both.

### IV. Layered Simplicity

- Dependencies flow one way: screens and widgets → providers → repositories and services.
  Widgets MUST NOT read Hive boxes or call the MethodChannel directly.
- Every native call goes through `lib/services/native_bridge.dart` and MUST be safe on web
  (no-op or default value).
- Colours, fonts, radii and spacing come only from `lib/theme/app_theme.dart` (Kotlin screens use
  `android/app/src/main/res/values/colors.xml`). New or modified screens take their text from
  `lib/l10n/app_strings.dart` (ADR-0005).
- A new package dependency MUST be justified in the feature's `plan.md` (problem, alternatives,
  maintenance status); one that changes architecture also needs an ADR.
- Prefer the simplest code that a team member can explain in the course report over clever or
  optimised code.

Rationale: four people and their agents edit one codebase under deadline pressure; predictable
structure is what keeps changes reviewable.

### V. Verified Changes (NON-NEGOTIABLE)

- Before any merge into `master`, all of these MUST pass locally and in CI:
  `dart format --set-exit-if-changed lib test`, `flutter analyze` with zero issues, and
  `flutter test` with zero failures.
- New pure logic MUST ship with unit tests. A changed user flow MUST ship with widget tests that
  cover its main path. A bug fix SHOULD include a regression test when the behaviour is testable
  in Dart.
- Changes to Kotlin native code MUST be checked manually on the Android emulator (Pixel, API 34+)
  against `docs/architecture/native-manual-checklist.md`, and the result recorded in the commit or
  PR description.
- Nobody (human or agent) may report a check as passing without having run it in that state of
  the code.

Rationale: the existing 475 tests are the main safety net for a brownfield refactor on a short
timeline.

### VI. Spec-Driven Traceability

- A change that adds or removes a screen, alters a user flow, changes a data model, or adds a
  dependency MUST go through `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` before code is
  written. Small fixes and refactors without behaviour change do not need a spec.
- Every `plan.md` MUST contain a Constitution Check against these principles; violations are
  listed with justification or the plan is revised.
- Decisions that affect architecture, platform, data or privacy are recorded as ADRs in
  `docs/decisions/`.
- Code keeps the existing decomposition-code comments (for example `// 2.3 Màn can thiệp`), and
  `README.md` (demo script and decomposition map) is updated when a flow or file mapping changes.

Rationale: the course evaluates the design reasoning as much as the app; specs and ADRs make that
reasoning traceable.

### VII. Agent Collaboration and Shared Instructions

- `AGENTS.md` is the single source of shared engineering rules for every coding agent; agent-
  specific files (`CLAUDE.md`, `.claude/`) only add tool-specific instructions and MUST NOT
  duplicate or contradict it.
- Before editing a shared component (router, theme, providers, models, repositories, native
  bridge), an agent MUST check its dependents (Graphify graph or code search) and confirm findings
  in the source files. Generated graphs are aids, not authority.
- An agent works only within the current task's scope; any edit outside it is reported explicitly.
- Secrets, keystores and personal data MUST NOT be committed. History on `master` MUST NOT be
  rewritten or force-pushed.

Rationale: several agents acting on one repository need one rulebook and a habit of checking
impact before touching shared code.

## Platform and Technology Constraints

- Target: Android only (ADR-0001). Web is used only for fast UI iteration; iOS and desktop are
  unsupported.
- Stack: Flutter, Dart, Riverpod 3, go_router, Material 3, Hive; Kotlin native layer over the
  `focus/native` MethodChannel.
- UI text is Vietnamese. Code, comments for new code, specs, ADRs, `AGENTS.md` and commit messages
  are in English. Existing Vietnamese comments may stay.
- Formatting width is 100 (`analysis_options.yaml`); lints come from `flutter_lints`.
- Test environment: Android emulator (Pixel, API 34+, Google Play image); no physical device is
  assumed.

## Development Workflow and Quality Gates

- Branches: `master` holds verified code; work happens on `feature/<topic>` or `fix/<topic>`,
  one branch per spec. Branches merge into `master` only after the Principle V gates pass.
- Commits follow Conventional Commits in English (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`,
  `chore:`, `ci:`).
- Until the 2026-11-24 hand-off, only the project lead and Claude write code and PR review is not
  required. TODO(REVIEW_RULE): after 2026-11-24, amend this section with the four-person ownership
  and review rule.
- CI (GitHub Actions) runs the Principle V gates and builds a debug APK on every push and pull
  request. A hand-off is a tagged GitHub Release carrying that APK.

## Governance

- This constitution overrides `AGENTS.md`, `CLAUDE.md` and other guides where they conflict; those
  files are corrected to match it.
- Amendments are made in a commit that edits this file, explains the reason, and bumps the
  version: MAJOR for removing or redefining a principle, MINOR for adding a principle or
  materially expanding one, PATCH for wording.
- `/speckit-analyze` and every plan's Constitution Check verify compliance; unresolved violations
  block implementation.
- The project lead (repository owner) approves amendments.

**Version**: 1.0.0 | **Ratified**: 2026-11-22 | **Last Amended**: 2026-11-22
