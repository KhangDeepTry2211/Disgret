# Feature Specification: Tên gọi (display name in the greeting)

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-25
**Status**: Implemented (2026-11-25)
**Input**: Project lead: "đổi trên cùng thành DisGret chào buổi sáng tên của người dùng, có thể cho
người dùng nhập thông tin của mình"; only the name, used only for the greeting. Design:
`docs/superpowers/specs/2026-11-25-display-name-design.md`, ADR-0012.

## User Scenarios & Testing

### User Story 1 - Gret greets me by name (Priority: P1)

**Acceptance Scenarios**:

1. **Given** the name "Khôi" in the morning, **Then** the Hôm nay header shows "DisGret" and
   "Chào buổi sáng, Khôi".
2. **Given** no name, **Then** it shows "DisGret" and "Chào buổi sáng".

### User Story 2 - Tell Gret my name (Priority: P1)

1. **Given** onboarding, **When** the story ends (or is skipped), **Then** Gret asks "Bạn muốn
   Gret gọi bạn là gì?"; a typed name is saved when onboarding completes; leaving it empty is
   fine.
2. **Given** Cài đặt → "Tên gọi", **When** the student saves "  Minh   Anh ", **Then** the name is
   "Minh Anh" and the header follows.

### Edge Cases

- More than 20 characters: only the first 20 are kept; the header ends with "…" if it does not fit.
- Profiles saved before this feature read with no name.
- "Xem lại màn giới thiệu" pre-fills the current name.

## Requirements

- **FR-001**: `UserProfile.displayName` (String, default empty) MUST be stored in the local profile.
- **FR-002**: Names MUST be trimmed, inner spaces collapsed, and cut to 20 characters.
- **FR-003**: The header MUST show "DisGret" above the greeting, with ", <name>" only when set.
- **FR-004**: Onboarding MUST ask for the name right after the story pages; Cài đặt MUST allow
  editing it.
- **FR-005**: The name MUST NOT appear in events, statistics or exports (ADR-0012).

## Success Criteria

- **SC-001**: A new student can set a name with one field during onboarding.
- **SC-002**: Existing data stays readable without migration.
