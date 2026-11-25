# Tasks: Tên gọi (007)

**Plan**: `docs/superpowers/plans/2026-11-25-display-name.md`. `UserProfile.displayName` with
`cleanName`; `ProfileNotifier.setDisplayName`; header "DisGret" + `AppStrings.greetingFor`;
onboarding name page after the story; Cài đặt "Tên gọi". No new dependency.

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test`.

- [X] T001 Name in the profile, clean-up rule, header greeting (FR-001–FR-003, FR-005).
- [X] T002 Onboarding name page and Cài đặt row; onboarding tests updated (FR-004). The name is cut
      by Unicode code points (not grapheme clusters, which would need a new dependency); phone
      keyboards type precomposed Vietnamese letters, so no letter is split.
