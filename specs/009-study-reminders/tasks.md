# Tasks: Study reminders (009)

**Plan**: `docs/superpowers/plans/2026-11-25-study-reminders.md`. Pure rule
`lib/data/reminder_plan.dart`; `ReminderService` (`lib/services/reminder_service.dart`: local
notifications on Android, nothing elsewhere); `reminderPlanProvider` applied by `app.dart` at start
and on every change; permission asked once (`ReminderSettingsRepository`, profile key
`reminder_permission_asked`). New dependencies `flutter_local_notifications` 22.0.0 and `timezone`
0.11.2 (ADR-0006 amendment).

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test`.

- [X] T001 Reminder plan rule with tests (FR-001).
- [X] T002 Service, providers, sync in app.dart, fake in tests, Android setup (desugaring,
      `RECEIVE_BOOT_COMPLETED`, receivers, `ic_stat_gret`) (FR-002–FR-004). The permission is asked
      the first time a reminder exists, whether it comes from the habit form or from saved data,
      instead of on every save of the form.
- [X] T003 Emulator (2026-11-25): reminders at 11:16 and 18:05 arrived within their window; tapping one
      opens Hôm nay (fixed after the first try, which resumed on the last tab); the habit form hint
      no longer says notifications are not sent.
