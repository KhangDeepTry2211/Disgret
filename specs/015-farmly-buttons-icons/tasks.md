# Tasks: Buttons, icon tiles and cards in the lead's Farmly style (015)

**Plan**: `docs/superpowers/plans/2026-11-27-farmly-buttons-icons.md`.

**Gate for every task**: `dart format --set-exit-if-changed lib test`, `flutter analyze`,
`flutter test`.

- [X] T001 `IconTile` and `ChevronCircle`; Farmly layout for `ClarityCard` and `StreakCard` with an
      `onTap`; `GradientPillButton.trailingIcon`; outlined buttons with a blue border; card radius
      20; icon tiles in the Thống kê, habit detail and focus stat cards (FR-001, FR-002, FR-004).
- [X] T002 Hôm nay: tappable stat cards to Tiến độ, "Lối tắt", "Việc hôm nay" (`TodayTasks`), the
      arrow on "Bắt đầu" (FR-003). Tests: `test/farmly_style_test.dart`; the habit detail test
      now scrolls to the month calendar, which the taller stat tiles push down.
- [X] T003 Emulator (Pixel_8_API_35, debug build, 09:12, the lead's data): stat cards with the ring,
      the flame tile and chevrons; "Lối tắt" with the pearl tag 8 and no reminder badge (no
      reminder today); "Việc hôm nay" 0/1 with "qwe · 15 phút"; "Bắt đầu →".
