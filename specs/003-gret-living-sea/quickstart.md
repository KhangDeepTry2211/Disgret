# Quickstart: validate Gret and the Living Sea (003)

## Prerequisites

- Flutter 3.47+ (`C:\src\flutter\bin\flutter.bat` on the current dev machine), Android emulator
  `Pixel_8_API_35` running.
- On Flutter 3.50+, add `--android-skip-build-dependency-validation` to `flutter run` (research R10).

## Automated checks

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter test test/sea_clarity_test.dart test/mascot_mood_test.dart
```

Expected: no format changes, "No issues found!", all tests pass.

## Manual scenarios on the emulator

1. **First launch** (US2): uninstall, run the app. The welcome step shows the logo, headline, Gret's
   introduction and the sea. Finish the quiz (thought bubble each time) and the first goal; a short
   "Biển của bạn đã sẵn sàng" moment leads to Hôm nay with clarity 70% and a happy Gret.
2. **Reading the sea** (US1): Settings → Tạo dữ liệu mẫu → Hôm nay. The clarity card and Gret's mood
   match the sample history; tap Gret to see a line; exactly one start control is visible.
3. **Distraction** (US1, SC-002): enable demo mode, Bắt đầu → Bỏ qua → leave to YouTube → choose
   "Quay lại học". The clarity is 5 points lower and the water murkier within a second.
4. **Studying next to Gret** (US3): during the session Gret concentrates and the water clears; take a
   break from the intervention screen: Gret sleeps and the remaining break time is shown.
5. **Summary** (US4): let the session end; Gret celebrates, "+N% độ trong" counts up, the streak card
   pulses when the streak grew.
6. **Dark mode**: switch the emulator to dark theme; the night sea appears with the same meaning.
7. **Reduced motion**: Settings → Accessibility → Remove animations on; nothing loops, numbers and
   scenes show their final state.
8. **Upgrade** (SC-006): install the previous APK, create data, install this build over it; habits,
   logs, sessions and streak are unchanged.
