# Quickstart Validation: Feature 001

## Prerequisites

- Flutter 3.47.x; `flutter pub get` done.
- Android emulator Pixel, API 34+ (for native scenarios); web is enough for UI scenarios.

## Automated

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Expected: no formatting diff, "No issues found!", all tests pass (including new
`session_plan_test.dart`, `navigation_test.dart`, `progress_screen_test.dart`).

## Manual scenarios

1. **Fresh start (S1)**: Cài đặt → "Tạo dữ liệu mẫu". Open Hôm nay → see goal, next habit,
   "N phút", streak, one "Bắt đầu". Press it → motivation opens without tab bar → "Bỏ qua" →
   session running for that habit (≤2 taps, SC-001).
2. **Change plan**: on Hôm nay change habit and minutes → "Bắt đầu" → "Bắt đầu N phút" shows the new
   N → session uses it.
3. **Small step**: "Bắt đầu" → "Chỉ 5 phút thôi" → 5-minute session.
4. **Banner (S2)**: during a session switch to Thói quen and Tiến độ → banner visible → tap → session.
   Press "Bắt đầu" on Hôm nay → goes to the running session, no second one.
5. **Native routing (emulator)**: during a session open YouTube → intervention → "Quay lại học" →
   DisGret shows the session. Repeat with "Xem 1 reel động lực" → motivation (distracted) → back to
   session. Choose a break → when it ends the session is shown.
6. **Tiến độ (S3)**: report and statistics both reachable; Thói quen app bar has no report button;
   Cài đặt has no statistics entry.
7. **Parked**: no achievements item in menus; habit detail shows no heat map or 66-day journey;
   crossing a level threshold shows no dialog.
8. **Upgrade**: install the `master` build, create data, install this build over it → habits, logs,
   sessions and streak unchanged (SC-005).
