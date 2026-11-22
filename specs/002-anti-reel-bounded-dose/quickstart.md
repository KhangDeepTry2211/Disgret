# Quickstart Validation: Feature 002

## Prerequisites

Feature 001 merged; Flutter 3.47.x; emulator Pixel API 34+ for video and native scenarios
(web works for the start-context scenarios without the blurred background).

## Automated

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Expected: all pass, including `motivation_dose_test.dart`, `motivation_screen_test.dart` and the
updated `reel_recommender_test.dart`; `reel_social_test.dart` no longer exists;
`grep -rn share_plus pubspec.yaml lib` returns nothing.

## Manual scenarios

1. **Bounded dose (S1)**: Hôm nay → "Bắt đầu" → reel 1/3 plays; swiping does nothing; it stops at
   the end (no restart) → end card with "Bắt đầu N phút", "Chỉ 5 phút thôi", "Tiếp".
2. **Last reel**: "Tiếp" twice → on 3/3 the end card has no "Tiếp".
3. **Skip**: "Bắt đầu" → "Bỏ qua" mid-reel → session starts with N minutes.
4. **After distraction (S2, emulator)**: during a session open YouTube → "Xem 1 reel động lực" →
   exactly one reel ("Get back to work!" is pinned) → end card shows only "Quay lại học" → session
   resumes, clock resumed.
5. **No social**: no heart, comment, share icons or counts anywhere; Tiến độ → Phiên học has no
   "Reel đã thích".
6. **Measurement**: after scenarios 1–3, Cài đặt sample data aside, Tiến độ → Phiên học shows reels
   watched and the share followed by a start increasing accordingly.
7. **Upgrade**: on a device with likes/comments from `master`, install this build → app starts,
   habits/sessions/events intact.
