# Git Workflow and CI

The rules are in `AGENTS.md` (Git) and the constitution (Development Workflow); this page holds
the details and the settings that live on GitHub.

## Branches

| Branch | Use |
|---|---|
| `master` | verified code; every commit passes the CI gate |
| `feature/<topic>` | one per spec, e.g. `feature/001-today-single-study-entry` |
| `fix/<topic>` | bug fixes |

No `dev` branch: the team is small and the timeline short. Branches merge into `master` after the
gate passes (squash or fast-forward). Rename to `main` was considered and declined (2026-11-22).

## Commits

Conventional Commits in English: `type(scope): summary`, types `feat`, `fix`, `refactor`,
`test`, `docs`, `style`, `chore`, `ci`. Mention the task ID (`001-T009`) and, for native changes,
the manual checklist result in the body.

## Review expectations

- Until the 2026-11-24 hand-off: project lead + Claude write code; no mandatory review.
- After it (to be ratified as a constitution amendment): every PR reviewed by one other member,
  nobody merges their own PR; the PR template checklist must be complete.

## CI (`.github/workflows/`)

| Workflow | Trigger | Steps |
|---|---|---|
| `ci.yml` | push to `master`, `feature/**`, `fix/**`; PR to `master`; manual | `flutter pub get` → `dart format --output=none --set-exit-if-changed lib test` → `flutter analyze` → `flutter test` → (then) `flutter build apk --debug` and upload the APK artifact (14 days) |
| `release.yml` | tag `v*` | same gate → debug APK → GitHub pre-release with the APK attached |

Toolchain pinned in the workflows: Flutter 3.47.9 stable, Temurin JDK 17 (the app targets Java
17; AGP 9.1, Gradle 9.3.1). No integration tests exist yet; the native layer is covered by the
manual checklist, not CI.

Hand-off release: `git tag v0.2.0 && git push origin v0.2.0` on the verified `master` commit.

`gh` note: the clone has an `upstream` remote (the original repository), so `gh` may resolve to it.
Run `gh repo set-default ltuong0211/Disgret` once per clone, or pass `-R ltuong0211/Disgret`.

First CI run: run 45031049645 on `feature/agentic-setup` (2026-11-22) — both jobs green; the debug
APK artifact is about 113 MB (debug build plus ~13 MB of bundled videos).

## Recommended GitHub settings (not applied; decided "not needed" for now)

- Protect `master`: require the `CI / Format, analyze, test` and `CI / Build debug APK` checks,
  block force-pushes and deletion.
- After 2026-11-24: require one approving review and conversation resolution before merge.
- Allow squash merge only; delete head branches after merge.
- Actions → General: allow GitHub Actions; workflow permissions read-only by default (the release
  workflow asks for `contents: write` itself).
