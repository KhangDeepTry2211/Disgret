# Feature Specification: Gret's home in the sea, two café looks, and Gret working at a desk

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-27
**Status**: Implemented (2026-11-27), approved by the lead ("Duyệt, làm luôn"); see tasks.md
**Input**: Project lead: "hãy xem lại giao diện bãi biển và quán san hô, bạn có đề xuất phù hợp nào
nâng cấp đồ họa cho bãi biển và quán san hô không". From sketched directions they chose: the sea
"B · Nhà của Gret"; for Quán San Hô "lấy cả 2 phương án cho người dùng chọn, nhưng mà trong lúc học
ngoài việc có cảm xúc nghiêm túc ra, hãy cho Gret 1 bàn làm việc và đang chăm chú làm việc (ví dụ
như viết bài, gõ máy,..)". Then: Gret alternates writing, typing and reading; the desk is also in the
sea session (a coral-rock desk); the café look is chosen in Góc của Gret; Gret sleeps at home only
23:00–05:59. The sea animations planned as 019 (tap squash and hearts, friends swimming across Hôm
nay) move to spec 020.

Review that led here (renders of 2026-11-27): the mascots are now soft 3D while the sea and the café
are flat vector (flat water bands, stick seaweed, a plain sand strip, flat sun and moon, a "Y"
glowing coral at night; café walls and floor plain, tables are discs the friends float above, no
chairs or props, the lower 40% of the café empty).

## User Scenarios & Testing

### User Story 1 - Gret works at a desk while the student studies (Priority: P1)

**Given** a running session, **Then** Gret sits behind its own desk and works, in the sea (a
coral-rock desk on the sand, next to its shell house) and in Quán San Hô (a wooden desk at the front
table): it writes in a notebook (the pen moves along the lines), types on a laptop (keys light up,
the screen glows) or reads a book (a page turns now and then), switching task every 2 minutes of
the session clock (40 s in demo mode), with its focused face. On a break Gret sleeps at the desk
(head on the desk, "z"), as today. Distractions still drift in and Gret bats them away, then goes
back to work. With "remove animations" Gret sits still at the desk, writing.

### User Story 2 - Quán San Hô, cosy (default) (Priority: P1)

The café keeps today's layout, redrawn in the soft 3D look of the mascots: wood-panelled lower
walls and patterned wallpaper, curtained arched windows onto Gret's sea, a counter with a steaming
kettle and a chalk menu board, hanging plants, a tiled floor with sun beams by day and warm lamp
glows by night, string lights on the bunting at night. Friends sit on chairs behind round wooden
tables (the table hides their lower half), each table with props for the friend's subject (Toán:
calculator and ruler, Văn: open book, Tiếng Anh: ABC cards, Sinh học: a little plant), cups that
steam. Gret's desk fills the front, so the empty lower part is gone.

### User Story 3 - Quán San Hô, diorama room (Priority: P2)

A second look: the café as a small isometric room cut open at the corner and floating on a soft
background, like a toy diorama: two walls with windows onto the sea, the counter in the corner, the
tables and the friends on the floor, Gret's desk at the front corner. The habit name, the countdown
ring and the speech bubbles keep their places above the room.

### User Story 4 - Choose the café look (Priority: P2)

Góc của Gret has a "Kiểu quán" choice ("Ấm cúng", "Phòng mô hình") next to "Nét vẽ", with a small
preview; it is remembered and used by every café session.

### User Story 5 - Gret's home on the sea floor (Priority: P1)

Hôm nay's sea is redrawn in the soft 3D look (gradient water, light caustics, sand with ripples
and shells, rounded seaweed and coral with tonal outlines, shaded rocks, chibi fish, glossy bubbles,
a glowing sun and moon) and Gret has a home on the sand: a conch-shell house with a door and a
lantern, a wooden sign "Gret" and a small chest. Four marked spots on the sand ("+" when empty)
hold decorations bought with pearls in Góc của Gret. Between 23:00 and 05:59 Gret sleeps by its
house (sleeping face, "z"); tapping it wakes it for a line, then it dozes off again.

### Edge Cases

- Clarity still drives the water colour, litter and fish; a murky sea dims the lantern.
- Pearl seas and the café windows keep their own sceneries (kelp, volcano, sunken city, sunset); the
  home and decorations show in every sea.
- Another mascot worn (Bơ, Mây…) sits at the same desk and does the same tasks (the props move, not
  the limbs), so every species and drawing style works.
- Small phones and large text: the desk and props scale with the scene, nothing overlaps the
  countdown or the bubbles.
- Old saves: no decorations owned, cosy café.

## Requirements

- **FR-001**: Gret's work is a pure rule: task = writing, typing, reading in turn, changing every
  `AppMotion.workTask` (2 min of session time, demo-scaled), from the session's focused time; unit
  tested. Work props are SVG layers on the shared 240×200 canvas (desk front, notebook and pen,
  laptop, book), animated in `MascotView`-like code, never per species.
- **FR-002**: Scene props (shell house, sign, chest, decorations, café furniture, counter, plants,
  the diorama room) are SVG assets generated by a script like `mascot_art.py`, in the soft 3D look
  (radial shading, tonal outline, soft shadow); water, sky, light and sand stay in the painters,
  redrawn with gradients.
- **FR-003**: Decorations are catalog items (`DecorationInfo`, kind, price in pearls, spot), bought
  through the same sheet as seas and outfits; owned and placed ids stored with Góc của Gret's
  choices (`corner_decor`: spot → id); unknown ids ignored. No real-money items (ADR-0009).
- **FR-004**: `CafeLook { cosy, diorama }` stored with Góc của Gret's choices (unknown → cosy).
- **FR-005**: Sleeping at home uses `SeaTime` with a late-night window 23:00–05:59 and only on
  Hôm nay outside a session.
- **FR-006**: Colours only in the SVG files and `AppSea`/`AppCafe` tokens; reduced motion shows the
  still pose of every loop.

## My calls (for the lead to check)

- The sea and the café use the new soft 3D look whatever "Nét vẽ" is chosen; "Nét vẽ" changes the
  mascots only.
- Six decorations to start: đèn lồng sứa (40), lâu đài cát (60), hộp thư san hô (60), xích đu rong
  (80), vườn san hô mini (100), rương báu vàng (150) pearls; four spots.
- The diorama room is P2: built after the cosy café, desk and sea home.

## Success Criteria

- **SC-001**: On the emulator, a sea session and a café session (both looks) show Gret working and
  switching task; Hôm nay shows the home, decorations and late-night sleep.
- **SC-002**: The task rule, decoration and café-look storage are unit tested; changed screens have
  widget tests; gates green.

## Delivery order

1. Gret's desk and work (sea and café) with the cosy café redraw (US1, US2).
2. Sea redraw and Gret's home with decorations and late-night sleep (US5).
3. Diorama café and the "Kiểu quán" choice (US3, US4).
