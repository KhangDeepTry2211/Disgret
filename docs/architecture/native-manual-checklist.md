# Native Manual Checklist (Reset Break, Android)

Required by Constitution V whenever Kotlin code under
`android/app/src/main/kotlin/com/nhom/focus/focus_app/` or a flow that depends on it changes.
Run on the Android emulator (Pixel, API 34+, Google Play image). Record the result (pass/fail per
item, emulator API level) in the commit message or PR description.

Source of the rules: [native-bridge.md](native-bridge.md) ("Quy tắc").

## Setup

- [ ] Fresh install; grant usage access and overlay permission from Cài đặt → Reset Break.
- [ ] Notification permission granted (and once denied: blocking must still work, only
      notifications are missing).
- [ ] Blocked apps include YouTube and Chrome (defaults: TikTok, Facebook, Instagram, YouTube,
      Chrome).

## Blocking during a session

- [ ] Start a session, open YouTube → intervention screen appears.
- [ ] Waiting time: 1st block 10 s, 2nd 15 s, 3rd 20 s (… max 30 s).
- [ ] Reopening the same app within 5 s counts as one block.
- [ ] If the blocked app draws over the intervention, the intervention is shown again.
- [ ] "Quay lại học" (and Back) → DisGret opens on the running session.
- [ ] "Xem 1 reel động lực" → DisGret opens the motivation step (after-distraction form).
- [ ] Choose a break → no app is blocked during the break; at the end, if still in a blocked app,
      the intervention reappears at once; DisGret shows the running session.
- [ ] Tapping the break-ended notification opens the running session.

## Lifecycle

- [ ] Ending or finishing the session stops the foreground service (no more blocking).
- [ ] Swiping DisGret away from recents stops the service (`stopWithTask`).
- [ ] Demo mode: session and break clocks run 3× faster; intervention waiting time does not.
- [ ] Cài đặt → "Thử màn can thiệp": all 3 choices shown, no event recorded, waiting time not
      increased, no real break started.

## Events

- [ ] After returning to DisGret, Tiến độ → Phiên học counts the interventions and choices made
      above.
