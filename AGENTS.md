# AGENTS.md — DisGret

Shared instructions for every coding agent (Claude Code, Codex, others) and human contributor.
The binding rules are in [`.specify/memory/constitution.md`](.specify/memory/constitution.md);
this file is the practical summary. If the two disagree, the constitution wins.

## Project

DisGret is an Android app that helps high-school and university students **start studying and
return to studying** after a distraction. It is a course project (Tư Duy Tính Toán). Four features:
Habit tracker (goal), Anti-reel reels (motivation), Focus mode (study session), Reset Break
(intervention when a blocked app is opened during a session). Every change serves one of three
scenarios: **S1** hard to start, **S2** distracted mid-session, **S3** keeping it up for days.

## Stack

- Flutter (stable 3.47.x), Dart ^3.13.7, Riverpod 3, go_router, Material 3 (`material_ui`), Hive.
- Kotlin native layer for Reset Break (UsageStats, overlay, foreground service) over the
  MethodChannel `focus/native`.
- Android is the only supported platform. Web (`flutter run -d chrome`) is for quick UI work only;
  iOS and desktop folders exist but are unsupported.
- All data stays on the device. No backend, accounts, Firebase, analytics or network calls.

## Architecture

```
screens/widgets ──► providers (Riverpod) ──► repositories (Hive) / services (pure logic)
                                               services/native_bridge.dart ──► Kotlin
```

- Business rules (streaks, schedules, statistics, recommendation, session plan) are pure functions
  in `lib/data/` or `lib/services/` with unit tests.
- Widgets never touch Hive or the MethodChannel directly.
- Details: [design system](docs/architecture/design-system.md),
  [data model and statistics](docs/architecture/data-model.md),
  [native bridge](docs/architecture/native-bridge.md),
  [decisions (ADRs)](docs/decisions/).

## Directory map

| Path | Contents |
|---|---|
| `lib/data/` | models, repositories, Hive boxes, pure domain logic |
| `lib/providers/` | Riverpod providers and notifiers |
| `lib/router/` | `app_router.dart` (routes, redirects) |
| `lib/screens/`, `lib/widgets/` | UI |
| `lib/services/` | pure services, timers, `native_bridge.dart` |
| `lib/theme/app_theme.dart` | all colours, fonts, radii, spacing |
| `lib/l10n/app_strings.dart` | UI strings for new/modified screens (ADR-0005) |
| `android/app/src/main/kotlin/com/nhom/focus/focus_app/` | Kotlin native layer |
| `test/` | unit and widget tests (`test_helpers.dart`) |
| `specs/NNN-*/` | Spec Kit feature artifacts (spec, plan, tasks…) |
| `docs/architecture/`, `docs/decisions/` | architecture docs, ADRs |
| `.specify/` | Spec Kit config, templates, scripts, constitution |

## Conventions

- UI text is Vietnamese. Code identifiers, new comments, specs, ADRs, this file and commit messages
  are English. Existing Vietnamese comments may stay.
- Keep the decomposition-code comment at the top of files and features, e.g. `// 2.3 Màn can thiệp`.
- Naming: files `snake_case.dart`; classes `UpperCamelCase`; providers `somethingProvider`;
  notifiers `SomethingNotifier`; routes in `AppRoutes`.
- No hard-coded colours or sizes in screens: use `AppColors`, `AppSpacing`, `AppRadius` from
  `app_theme.dart`. The Kotlin intervention screen uses `res/values/colors.xml`; change both when
  the brand colours change.
- New model fields need defaults; unknown enum values map to a default. Never reuse a Hive box name
  (retired names are listed in `HiveBoxes`).
- Native calls go through `native_bridge.dart` and must be no-ops on web (`kIsWeb`).
- Prefer simple code a team member can explain in the course report.

## Verification (required before every merge)

```bash
dart format --set-exit-if-changed lib test   # width 100 (analysis_options.yaml)
flutter analyze                              # must report "No issues found!"
flutter test                                 # all tests pass
```

- New pure logic → unit tests. Changed user flow → widget tests for its main path.
- Kotlin or Reset Break flow changes → run
  [docs/architecture/native-manual-checklist.md](docs/architecture/native-manual-checklist.md) on
  the Android emulator (Pixel, API 34+) and record the result in the commit/PR.
- Never claim a check passed without running it on the current code.

Test environment: no physical Android phone is assumed. Use the Android emulator (Pixel, API 34+,
Google Play image); test blocking with YouTube and Chrome (preinstalled) and TikTok if installed.
Default blocked apps: TikTok, Facebook, Instagram, YouTube, Chrome. Non-native screens may be tried
with `flutter run -d chrome`; Reset Break only runs on the emulator or a real device.

## Spec-driven workflow (Spec Kit)

1. Read the constitution and the relevant `specs/NNN-*/` folder before changing behaviour.
2. New screen, changed flow, data model change or new dependency → `specify` → `clarify` (if
   needed) → `plan` → `tasks` → `analyze` before writing code. Bug fixes and pure refactors do not
   need a spec.
3. Implement tasks in order; tick them in `tasks.md`; keep `plan.md` and code consistent.
4. Architecture, platform, data or privacy decisions → a new ADR in `docs/decisions/`.
5. Flow or file-mapping changes → update `README.md` (demo script, decomposition map).

Claude Code invokes the steps as `/speckit-specify`, `/speckit-plan`, … (installed in
`.claude/skills/`). Other agents follow the same steps by reading the templates in
`.specify/templates/` (or install their own integration: `specify integration install <key>`).

## Codebase graph (Graphify)

Setup, refresh and query details: [docs/architecture/codebase-graph.md](docs/architecture/codebase-graph.md).

- Install once: `uv tool install graphifyy==0.9.115`. Build/refresh (offline, code only):
  `GRAPHIFY_BACKEND=none graphify update .` after pulling, switching branches or significant
  changes. Output `graphify-out/` is git-ignored.
- Before changing a shared component: `graphify explain "<Symbol>"` **and**
  `grep -rn "<Symbol>" lib test`; union both (the Dart extractor misses some references), then read
  the source at those lines.
- The graph is an aid, never a source of truth. Codex users can add Graphify's own instructions
  with `graphify install --project --platform codex` (not installed yet).

## Changing existing code

- Before editing a shared component (`app_router.dart`, `app_theme.dart`, `app_providers.dart`,
  models, repositories, `hive_boxes.dart`, `native_bridge.dart`, `app.dart`), list its dependents
  and check them after the change.
- Stay inside the task's scope; mention any edit outside it in the commit message.
- Do not delete parked features (ADR-0004); keep them unreachable.
- Keep every commit runnable: analyze and tests green after each step.

## Git

- `master` = verified code. Work on `feature/<topic>` or `fix/<topic>`, one branch per spec; merge
  after the verification gate passes. Never force-push or rewrite `master`.
- Conventional Commits in English: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `style:`,
  `chore:`, `ci:`. CI (`.github/workflows/ci.yml`) runs the verification gate and a debug APK build
  on every push and PR; a `v*` tag publishes the APK as a GitHub Release. Details and recommended
  GitHub settings: [docs/architecture/git-and-ci.md](docs/architecture/git-and-ci.md).
- Until the 2026-11-24 hand-off only the project lead and Claude write code; afterwards the review
  rule in the constitution applies.

## Security and privacy

- Never commit secrets, keystores, `key.properties`, `local.properties` or personal data.
- No network requests, telemetry or third-party SDKs; new Android permissions need an ADR.
- Users may be under 18: collect nothing that identifies them; any export must be explicit and
  anonymous.

## Definition of Done

- [ ] Acceptance scenarios of the spec/task pass; task ticked in `tasks.md`.
- [ ] `dart format`, `flutter analyze`, `flutter test` green locally and in CI.
- [ ] Tests added for new logic and changed flows; native checklist run if Kotlin/Reset Break changed.
- [ ] No hard-coded colours/strings in touched screens; old data still readable.
- [ ] README / docs / ADR updated when behaviour, mapping or a decision changed.
- [ ] Conventional Commit message, scope limited to the task.
