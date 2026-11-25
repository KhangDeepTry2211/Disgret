# Tên gọi (display name) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the student set an optional name that the Hôm nay header greets them with.

**Architecture:** A `displayName` field on `UserProfile` with a pure clean-up rule; the profile
notifier saves it; the header builds "greeting, name"; onboarding asks after the story; Cài đặt
edits it.

**Tech Stack:** Flutter, Riverpod 3, Hive (profile box).

**Spec:** `specs/007-display-name/spec.md`, design
`docs/superpowers/specs/2026-11-25-display-name-design.md`, ADR-0012.

## Global Constraints

- Name: trimmed, inner whitespace collapsed to one space, first 20 grapheme clusters
  (`UserProfile.maxNameLength = 20`); empty means no name.
- UI text in `lib/l10n/app_strings.dart`; never in events or exports.
- Gate: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`.

## Review Focus

- A name of only spaces: treated as no name (Task 1 test).
- A Vietnamese name with diacritics longer than 20 characters: cut by characters, not code units,
  so no broken letter (Task 1 test).
- Replaying the introduction keeps the existing name and demo mode (Task 2 test).
- A long name on a 360-wide phone: header stays on one line, no overflow (Task 1 test).
- Profiles saved before the feature: read with no name (Task 1 test).

---

### Task 1: Name in the profile and the header greeting

**Files:**
- Modify: `lib/data/models/user_profile.dart`, `lib/providers/app_providers.dart`
  (`ProfileNotifier.setDisplayName`), `lib/l10n/app_strings.dart`
  (`greetingFor(DateTime now, String name)`), `lib/screens/today_screen.dart` (header)
- Test: `test/display_name_test.dart`

**Interfaces:**
- Produces: `UserProfile.displayName` (String, default `''`, map key `displayName`),
  `static String UserProfile.cleanName(String raw)`, `copyWith(displayName:)`,
  `ProfileNotifier.setDisplayName(String raw)`, `AppStrings.greetingFor(now, name)`.

- [ ] Tests: `cleanName('  Minh   Anh ') == 'Minh Anh'`; `cleanName('   ') == ''`; a 25-character
  Vietnamese name keeps its first 20 characters; old profile map → `displayName == ''`; round trip;
  `greetingFor(9:00, 'Khôi') == 'Chào buổi sáng, Khôi'`, `greetingFor(9:00, '') == 'Chào buổi
  sáng'`; header shows "DisGret" and the greeting with the name; a 20-character name on 360×640
  does not overflow.
- [ ] Implement; the header puts `AppStrings.appName` first and the greeting second, one line each.
- [ ] Gate green.

### Task 2: Ask in onboarding, edit in Cài đặt

**Files:**
- Modify: `lib/screens/onboarding_screen.dart` (`_PageKind.name`), `lib/screens/settings_screen.dart`,
  `test/onboarding_gret_test.dart` (story now leads to the name page), `lib/l10n/app_strings.dart`
- Test: `test/display_name_test.dart`

**Interfaces:**
- Consumes: Task 1's `displayName`, `cleanName`, `setDisplayName`.

- [ ] Tests: after the story Gret asks `AppStrings.nameQuestion`; typing "Khôi", finishing
  onboarding saves `displayName == 'Khôi'`; leaving it empty saves `''`; replaying the introduction
  shows the current name in the field; Cài đặt "Tên gọi" → dialog → "Lưu" updates the profile and
  Hôm nay; "Hủy" changes nothing.
- [ ] Implement; update the onboarding tests whose story skip now lands on the name page.
- [ ] Gate green; docs (data-model, design-system header line, README onboarding step).
