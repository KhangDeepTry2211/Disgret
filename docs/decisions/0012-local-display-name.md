# ADR-0012: An optional display name, kept on the phone, for the greeting only

- Status: Accepted (project lead, chat 2026-11-25)
- Date: 2026-11-25
- Related: constitution Principle II, AGENTS.md "Security and privacy", spec 007,
  design `docs/superpowers/specs/2026-11-25-display-name-design.md`

## Context

The lead wants Hôm nay to greet the student by name ("Chào buổi sáng, Khôi"). Users may be under
18, and the project collects nothing that identifies them; events never carry personal
identifiers.

## Decision

- Add one optional field, `displayName` ("tên gọi"), to the local profile. A nickname is welcome
  and the field may stay empty.
- It is used only to render the greeting on Hôm nay. It is never written to events, statistics or
  any export, never sent anywhere, and "Xóa toàn bộ dữ liệu" removes it with the profile.
- At most 20 characters after trimming. No other personal data (class, school, birthday) is
  asked for.

## Consequences

- `UserProfile.displayName` defaults to empty, so profiles saved before stay readable.
- Onboarding gains one page; Cài đặt gains one row.
