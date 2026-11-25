# ADR-0006: Habit reminders through local notifications (R2.2)

- Status: Accepted (priority 3; may slip past 2026-11-24)
- Date: 2026-11-22

## Context

`Habit.reminderEnabled` and `Habit.reminderTime` are stored but no notification is sent, so
criterion R2.2 (start within 10 minutes of the planned time) has no feature. `POST_NOTIFICATIONS`
is already requested by the native layer.

## Decision

- Schedule reminders with `flutter_local_notifications` and `timezone`, using inexact scheduling so
  that `SCHEDULE_EXACT_ALARM` is not needed.
- Reschedule when a habit is created, edited, archived or removed, and on app start.
- Tapping a reminder opens Hôm nay.
- Exact package versions are chosen and verified during `/speckit-plan`.

## Alternatives

- Native `AlarmManager` in Kotlin: no new Dart dependency, but more code and more manual testing.

## Consequences

- Two new dependencies; reminders may fire a few minutes late, which R2.2's 10-minute window
  tolerates.

## Amendment 2026-11-25 (spec 009)

- Status: built after the project lead asked for study reminders ("làm tiếp phần này luôn").
- Version: `flutter_local_notifications` 22.0.0 (the last line that compiles against Flutter's
  default `compileSdk` 36; 23.x needs 37) and `timezone` 0.11.2. Core library desugaring is
  enabled in `android/app/build.gradle.kts`, as the plugin requires.
- Scheduling: one-shot notifications for the next 7 days, placed at absolute instants (UTC), so no
  time-zone database or device time-zone lookup is needed; the plan is rebuilt at app start and
  whenever habits or habit logs change, so today's reminder disappears once the habit is done.
- New permission `RECEIVE_BOOT_COMPLETED` (normal permission, no prompt): Android drops scheduled
  alarms on reboot, and the plugin's boot receiver re-registers them. Without it, a student who
  restarts the phone would get no reminder until they open DisGret, which defeats the purpose.
- The notification shows only the habit name and minutes, never the student's name (ADR-0012).
