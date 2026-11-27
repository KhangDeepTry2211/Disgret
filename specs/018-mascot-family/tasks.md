# Tasks: The mascot family, redrawn, with new friends to earn (018)

Plan: `docs/superpowers/plans/2026-11-27-mascot-family.md`.

- [X] T001 Bơ, the five new species and the study unlocks: `UnlockKind.onTimeStarts`,
      `interventionReturns`, `focusHours`, `habitDays`; pure `StudyFacts` (on-time starts counted
      once per habit and day, 0–10 min after the reminder on a scheduled day); `CornerLock.study`;
      a chosen study friend is kept in `corner_owned`. Mochi needs 30 focus hours (no more "Sắp
      có"). Tests: `study_unlocks_test.dart`, `gret_corner_providers_test.dart`.
- [X] T002 Art: `specs/018-mascot-family/mascot_art.py` writes the flat and soft layers and the
      classic files that were missing (five bodies, four emotes, hearts, sparkle, burst). Checked
      on contact sheets in Edge and through flutter_svg.
- [X] T003 Styles and emotes in the app: `MascotStyle`, `MascotLook.layers(style:)`,
      `MascotStyleScope` under `MaterialApp`, "Nét vẽ" chips in Linh vật, moods `love`,
      `surprised`, `proud`, `wink`, `gretEmoteProvider` (tap, morning, return from the
      intervention, milestone), proud on Tổng kết after a full session. My call: the chips read
      "Cổ điển", "Phẳng viền", "3D mềm" (no other app's name in the UI). Tests:
      `mascot_family_test.dart`, `gret_sea_widgets_test.dart`, `focus_screen_test.dart`.
- [X] T004 Intervention Gret regenerated from 3D mềm (`gret_tail.xml`, `gret_front.xml` with
      `aapt:attr` radial gradients, via `specs/018-mascot-family/svg2vector.py`); the native fins
      get the tonal outline `gret_fin_outline`.
- [X] T005 Native manual checklist and emulator check. Art check (Pixel_8_API_35, API 35, debug
      build, 2026-11-27): Hôm nay shows Gret in 3D mềm; Góc của Gret → Linh vật switches Cổ điển /
      Phẳng viền / 3D mềm at once (cards and the sea preview), outfits fit, eight friends with
      their progress; Cài đặt → "Thử màn can thiệp" shows the 3D mềm Gret with shading and
      outlined fins, breathing in the ring, the three choices after the wait, "Quay lại học"
      returns to DisGret. Fixed on the way: the screen-reader text "Gret dang" → "Gret đang"
      (spec 017 string), and "Ứng dụng cần nhắc", which could not read the app list since commit
      bfab4e3: Dart expected a JSON string while Kotlin sends the documented list of
      {packageName, name, icon (PNG)}; `InstalledApp.listFrom` now reads the list
      (`test/native_bridge_test.dart`).
      Native manual checklist run 2026-11-27 on Pixel_8_API_35 (API 35), debug build, demo
      mode on, upgrade install (`adb install -r`, data kept):
      - Setup: overlay permission was off and was turned on from Cài đặt → Quyền cho Reset
        break → "Bật" (system page); usage access and notifications already on; YouTube and
        Chrome on in "Ứng dụng cần nhắc". Not run: a fresh install, notifications denied.
      - Blocking: YouTube during a session shows the intervention; waits 10, 15, 20, 25, 30, 30 s
        with Gret's line 1/2/3; YouTube's own window drawing over the intervention shows it again;
        Back then reopening within 4.1 s adds no block; "Quay lại học" and Back open the running
        session (Gret proud for 2.5 s); "Xem 1 reel động lực" opens the after-distraction
        motivation step; a 5-minute break lets Chrome and YouTube open, and at its end (100 s,
        demo) the intervention reappears over Chrome within 2 s; the "Hết giờ nghỉ rồi!"
        notification opens the running session. A new session starts again at 10 s and line 1.
      - Lifecycle: finishing the session stops the service (YouTube opens freely); swiping
        DisGret from recents stops the service and the process; demo clocks run 3× (34 s of
        session in 11 s, the 5-minute break in 100 s) while the waits stay real-time; "Thử màn
        can thiệp" shows line 1, 10 s, the three choices, records no event and starts no break.
        Not run: ending a session early.
      - Events: Tiến độ → Phiên học went from 0 to "Đã chặn 9 lần", Quay lại học 6, Xem 1 reel
        1, Nghỉ có chủ đích 2 (the trial's break not counted), matching the run.
      Finding, fixed the same day: the 5 s "same opening" window counted from the intervention's
      opening, so YouTube's cold start (its own window 6.15 s after the first block) counted as a
      second block: the first real open showed 15 s and "Lại gặp nhau rồi!". Now
      `InterventionActivity` records when it is covered without a choice (`coveredAt`) and
      `FocusGuardService` counts the window from the later of that and the last block. Rechecked
      on the emulator: YouTube's own windows covering the intervention 30 s after the block
      (twice) re-show it with line 1 and 10 s and no new event; "Quay lại học" then reopening
      YouTube 3 s later is a new block (15 s). Still not run: ending a session early (the
      emulator was closed during that step).
