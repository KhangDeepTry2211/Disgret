# Feature Specification: Study reminders (nhắc giờ học)

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-25
**Status**: Implemented (2026-11-25)
**Input**: Project lead: "làm sao để app thông báo được tới lúc học khi mà người dùng đặt trước
lịch". The habit form already stores `reminderEnabled` and `reminderTime`; nothing is sent yet.
Decision record: ADR-0006 and its 2026-11-25 amendment. Serves S1 and criterion R2.2 (start within
10 minutes of the planned time).

## User Scenarios & Testing

### User Story 1 - Gret reminds me at my study time (Priority: P1)

**Acceptance Scenarios**:

1. **Given** a habit "Ôn Toán" (25 phút) with the reminder on at 19:00 on Mondays, **When** it is
   Monday 19:00, **Then** a notification from Gret says it is time for "Ôn Toán", 25 minutes.
2. **Given** the habit is already done today, **Then** today's reminder does not fire.
3. **Given** the habit is archived, ends, or its reminder is switched off, **Then** no reminder
   fires for it.
4. **Given** the phone restarts, **Then** the reminders still fire.
5. **When** the student taps the notification, **Then** DisGret opens on Hôm nay.

### User Story 2 - Allow notifications (Priority: P1)

**Given** Android 13+, **When** the first reminder exists (a habit saved with the reminder on, or
saved data opened), **Then** the system asks for the notification permission once; refusing keeps
the app working.

### Edge Cases

- A reminder time already past today: the first reminder is on the next scheduled day.
- Many habits: at most 60 reminders are scheduled at once (7 days ahead), earliest first.
- Web and tests: no notifications.

## Requirements

- **FR-001**: Reminders MUST be planned by a pure rule from the habits, today's completions and the
  current time: each active habit with the reminder on, on each scheduled day of the next 7 days
  at its reminder time, skipping times already past and today when the habit is done.
- **FR-002**: The plan MUST be applied (all pending reminders replaced) at app start and whenever
  habits or habit logs change.
- **FR-003**: Notifications use local scheduling only (`flutter_local_notifications` 22.0.0,
  inexact while idle), no network; text in Gret's voice from `app_strings.dart`; no personal data
  beyond the habit name and minutes.
- **FR-004**: The notification permission MUST be requested once, the first time a reminder
  exists (profile key `reminder_permission_asked`).

## Success Criteria

- **SC-001**: A reminder set for a few minutes ahead appears on the emulator.
- **SC-002**: Existing habits keep their saved reminder settings without migration.
