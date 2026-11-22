---
paths:
  - "android/**"
  - "lib/services/native_bridge.dart"
  - "lib/app.dart"
---

# Native layer (Reset Break)

- The MethodChannel contract is in `docs/architecture/native-bridge.md`. A change on one side
  (Kotlin or `native_bridge.dart`) must be mirrored on the other and in that document.
- Actions sent from Kotlin are names, not routes; route them in `lib/app.dart`.
- Intervention screen colours live in `android/app/src/main/res/values/colors.xml`; keep them in
  sync with `lib/theme/app_theme.dart`.
- After changing anything here, run `docs/architecture/native-manual-checklist.md` on the Android
  emulator and record the result in the commit message. `flutter test` does not cover Kotlin.
