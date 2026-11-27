# Tasks: Gret's home in the sea, two café looks, and Gret working at a desk (019)

Plan: `docs/superpowers/plans/2026-11-27-sea-home-cafe-desk.md`. Art: `scene_art.py` in this folder
writes `assets/scene/` (reuses the soft shading of `specs/018-mascot-family/mascot_art.py`).

- [X] T001 Gret at a desk (US1): pure `GretWork.taskAt` (writing → typing → reading every 2 min of
      session time, so 40 s in demo), `MascotAtDesk` (desk and props on a 312×230 canvas in mascot
      units, the props move: pen, lit keys, turning page; still with reduced motion; empty desk
      and sleeping on a break). Sea session: coral-rock desk standing on the sand
      (`SeaScene.deskGretAlignment`, distractions aim there); café: wooden desk. Tests:
      `gret_work_test.dart`.
- [X] T002 Cosy café (US2): `SeaCafePainter` redrawn (shaded dotted wall, wainscot with moulding,
      plank floor with joints, sun beams by day, lamp pools and bunting lights by night, shaded
      lamps, a rug); friends sit on chairs behind round tables with their subject's things and a
      steaming cup (`MascotSeated`); the owner behind a counter with a kettle, cups and a menu;
      curtains, hanging plants and floor plants.
- [X] T003 Sea redraw and Gret's home (US5): crest lines on the wave bands, glowing shaded sun and
      moon, sand with a gradient, ripples, shells and a starfish, outlined shaded seaweed, coral
      as shaded polyp clusters, shaded fish with an eye, glossy bubbles; Gret's home on two rock
      ledges beside Gret (`GretHomeLedge`), shown on Hôm nay and in the sea session.
- [X] T004 Decorations and late-night sleep (US5): six decorations (40–150 pearls) for three
      spots, bought and placed ("Đặt" / "Cất đi") in Góc của Gret → Biển → "Trang trí nhà Gret",
      stored as `corner_decor`; `SeaTime.isLateNight` (23:00–05:59) makes Gret sleep on Hôm nay
      outside a session. Tests: `sea_home_test.dart`, `mascot_family_test.dart`.
- [X] T005 Diorama café and "Kiểu quán" (US3, US4): `CafeDioramaPainter` (isometric room cut open,
      walls with windows, tiled floor, rug, bunting, base slab, shadow), the same seats placed on
      its floor; "Kiểu quán" chips (Ấm cúng / Phòng mô hình) with a preview in Linh vật, stored as
      `corner_cafe_look`. Tests: `gret_work_test.dart`, `sea_home_test.dart`.
- [X] T006 Gates: format, analyze, 798 tests green; Flutter renders checked by day and night.
      My calls: three decoration spots instead of four, because Hôm nay's cards cover the sea
      floor and the home has to sit on ledges at Gret's level; the treasure chest is a
      decoration rather than part of the home; the late-night mood is computed when the sea
      state rebuilds (opening Hôm nay), not exactly at 23:00. Not checked on the emulator (it was
      closed).
- [X] T007 (lead's request after review) Hôm nay keeps the sea and Gret still while the cards
      scroll and pauses the sea's animations during a scroll; `DisplayRate.kt` asks for the
      fastest refresh rate in MainActivity and InterventionActivity. Native checklist smoke run
      2026-11-27 on Pixel_8_API_35 (API 35), release build, demo mode: the window requests the
      fastest mode (`preferredDisplayMode=1`, the emulator's only 60 Hz mode; 90/120 Hz needs a
      real phone); a session blocks YouTube (1st block, 10 s, line 1) with the intervention window
      requesting the same mode; "Quay lại học" returns to the running café session (Gret writing
      at its desk); "Kết thúc sớm" → "Kết thúc" stops the service and YouTube opens freely.
