# ADR-0005: UI strings in a Dart constants file, Vietnamese only

- Status: Accepted
- Date: 2026-11-22

## Context

All UI text is Vietnamese and hard-coded in widgets. The team wants strings separated from code.
There is no plan for a second language.

## Decision

- New or modified screens take their text from `lib/l10n/app_strings.dart` (a class of `static
  const String` values, plus small functions for interpolated text).
- Untouched screens migrate gradually; no big-bang extraction before 2026-11-24.
- Flutter gen-l10n with ARB files is not adopted now.

## Consequences

- Zero new dependencies and simple review.
- Adding another language later requires moving to ARB/gen-l10n; the constants file makes that a
  mechanical change.
