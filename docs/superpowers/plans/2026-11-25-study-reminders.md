# Study reminders Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Send Gret's local notification at each habit's reminder time on its scheduled days.

**Architecture:** A pure rule (`lib/data/reminder_plan.dart`) turns habits, today's completions and
the time into a list of planned reminders; a `ReminderService` interface applies the list (real:
flutter_local_notifications; fake in tests; no-op on web); `app.dart` applies the plan at start and
on every change; the habit form asks for the permission.

**Tech Stack:** Flutter, Riverpod 3, flutter_local_notifications 22.0.0, timezone 0.11.2.

**Spec:** `specs/009-study-reminders/spec.md`, ADR-0006 (amendment 2026-11-25).

## Global Constraints

- `ReminderPlan.daysAhead = 7`, `ReminderPlan.maxReminders = 60`; times "HH:mm" in local time.
- No network; no student name in notifications; text from `app_strings.dart`.
- Android: desugaring on, receivers and `RECEIVE_BOOT_COMPLETED` in the manifest, small icon
  `@drawable/ic_stat_gret` (white silhouette) kept from shrinking.
- Gate: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`.

## Review Focus

- A reminder time earlier than now today: first reminder tomorrow (Task 1 test).
- A habit done today: no reminder today, still tomorrow (Task 1 test).
- Archived habit or reminder off: none (Task 1 test).
- Weekly habit on Mon/Wed: only those days (Task 1 test).
- Saving a habit with the reminder on asks for the permission and reschedules (Task 2 test).

---

### Task 1: The plan

**Files:** Create `lib/data/reminder_plan.dart`; test `test/reminder_plan_test.dart`.

**Interfaces:** `class PlannedReminder { String habitId; DateTime at; String title; String body }`;
`ReminderPlan.upcoming({required List<Habit> habits, required Set<String> doneToday,
required DateTime now}) -> List<PlannedReminder>` sorted by time, capped.

- [ ] Tests for the five Review Focus cases plus "text names the habit and minutes".
- [ ] Implement with `HabitSchedule.isScheduledOn`; gate green.

### Task 2: Applying the plan

**Files:** Create `lib/services/reminder_service.dart`, `lib/providers/reminder_providers.dart`;
modify `lib/app.dart`, `lib/screens/habit_form_screen.dart`, `test/test_helpers.dart`
(`FakeReminderService`, overridden in `pumpApp`/`pumpStandalone`), Android files.

**Interfaces:** `abstract class ReminderService { Future<void> replaceAll(List<PlannedReminder>);
Future<bool> requestPermission(); }`; `reminderServiceProvider`, `reminderPlanProvider`.

- [ ] Test (full app with the fake): saving a habit with the reminder on requests the permission
  and the fake receives a plan containing it; switching it off removes it.
- [ ] Implement; Android setup; gate green; emulator: a reminder two minutes ahead appears.
