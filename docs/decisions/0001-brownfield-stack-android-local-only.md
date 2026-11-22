# ADR-0001: Continue on the existing stack, Android-only, local-only data

- Status: Accepted
- Date: 2026-11-22

## Context

The first version (Flutter, ~14k lines in `lib/`, 475 passing tests, `flutter analyze` clean)
already implements the four features. The team must hand a revised app to its members on the
evening of 2026-11-24, two and a half days after this decision. Earlier notes mentioned Firebase,
sqflite, camera-based distraction detection (ML Kit Face) and scikit-learn, none of which exist in
the code.

## Decision

- Keep the current stack: Flutter, Riverpod 3, go_router, Material 3, Hive, and the Kotlin native
  layer reached through the `focus/native` MethodChannel (UsageStats, overlay, foreground service).
- Android is the only supported and CI-verified platform. Web (`flutter run -d chrome`) is a
  development convenience only; native calls stay guarded by `kIsWeb` / `NativeBridge.isSupported`.
  iOS and desktop folders are kept but unsupported; no platform-specific code is written for them.
- All data stays on the device (Hive). No backend, no accounts, no Firebase in the MVP.
- Out of the MVP: Firebase and sign-in, ML Kit Face, scikit-learn, criterion R1.3 (meme alert).

## Consequences

- No rewrite risk; existing tests remain the safety net.
- Evaluation data for the later experiment must come from an on-device event log plus a manual,
  anonymous export (to be specified after 2026-11-24).
- Behaviour of UsageStats/foreground service on real phones (aggressive battery savers) is unverified;
  only the Android emulator (Pixel, API 34+) is available.
