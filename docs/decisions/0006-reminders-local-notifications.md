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
