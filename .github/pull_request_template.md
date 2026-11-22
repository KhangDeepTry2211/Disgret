## What and why

<!-- One or two sentences. Link the spec and task IDs, e.g. specs/001-…/tasks.md T009. -->

- Spec / tasks:
- Scenario served (S1 / S2 / S3):

## Verification

- [ ] `dart format --output=none --set-exit-if-changed lib test`
- [ ] `flutter analyze` — no issues
- [ ] `flutter test` — all pass
- [ ] Tests added for new logic / changed flows
- [ ] Native changes: `docs/architecture/native-manual-checklist.md` run on emulator (API level: …) — or N/A
- [ ] Old on-device data still readable (models, Hive boxes, event types) — or N/A

## Docs and decisions

- [ ] `tasks.md` ticked; README demo script / mapping updated if the flow changed
- [ ] ADR added or updated if an architecture, platform, data or privacy decision changed
- [ ] Shared components touched — dependents checked (`graphify explain` + `grep`):

## Screenshots (UI changes)
