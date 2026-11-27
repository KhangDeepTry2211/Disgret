# Feature Specification: The mascot family, redrawn, with new friends to earn

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-27
**Status**: Implemented (2026-11-27); native checklist run (tasks.md T005)
**Input**: Project lead: "đổi tên linh vật thứ 2, và có thể gợi ý thêm tên và thiết kế những con
linh vật mới kèm theo những điều kiện mới để mở được (… học hỏi cách vẽ từ app widgetable … để vẽ
lại các nét linh vật và thiết kế animation cho các giao diện biển …)". From a sketch they chose:
the crab "Ẩn" becomes "Bơ"; six friends with study-based unlocks (Cá ngựa Tép, Cá nóc Phồng,
Sứa Mây, Bạch tuộc Mochi, Cánh cụt Bông, Cá voi Bự); every mascot, Gret included, redrawn in a
chibi outlined style learnt from Widgetable (original characters, nothing copied). Then: "combine
nét vẽ widgetable lên 3d … như kiểu hình ảnh unrot này và để cho các linh vật có nhiều emote hơn",
"vẽ lại mắt cho phần widgetable + 3d mềm với có thể cho user lựa chọn cả 3 giao diện trên app";
they chose eye style "C · Hạt đậu bóng" and the style picker in Góc của Gret. Sea animations in
that spirit are a separate spec (019).

## User Scenarios & Testing

### User Story 1 - Bơ (Priority: P1)

The hermit crab is called "Bơ" everywhere: Góc của Gret, Quán San Hô's roster and lines, the
sheet that obtains it (still 300 pearls).

### User Story 2 - Friends you earn by studying (Priority: P1)

Góc của Gret → Linh vật lists, with their progress while locked:

| Friend | Unlock | Progress shown |
|---|---|---|
| Cá ngựa Tép | start a session within 10 min after a habit's reminder, 5 times | "2/5 lần đúng giờ" |
| Cá nóc Phồng | choose "Quay lại học" on the intervention screen 5 times | "3/5 lần quay lại" |
| Sứa Mây | 10 hours of focused study in total | "6,5/10 giờ" |
| Bạch tuộc Mochi | 30 hours of focused study in total (no longer "Sắp có") | "6,5/30 giờ" |
| Cánh cụt Bông | one habit reaches 21 days done | "12/21 ngày" |
| Cá voi Bự | one habit reaches 66 days done | "12/66 ngày" |

Once earned it can be chosen; it swims in the sea, sits in Quán San Hô's roster rules as today.

### User Story 3 - Three drawing styles to choose from (Priority: P1)

Góc của Gret → Linh vật has a "Nét vẽ" choice, previewed on the sea above it:
- **Hiện tại**: today's flat drawings, big eyes, no outline;
- **Widgetable phẳng**: chibi, warm dark-brown outline, flat fills, small bead eyes, pink cheeks;
- **3D mềm** (default for new installs): Widgetable proportions with soft 3D volumes like the
  lead's unrot reference: radial shading, an outline in a darker shade of the body colour, a soft
  shadow under the mascot, cheeks with freckles, and glossy bean eyes (option C: larger bead eyes
  with depth and two highlights).

The choice applies to every mascot everywhere (Hôm nay, focus, Quán San Hô, Góc của Gret, the
onboarding; the intervention screen follows the default style). Outfits fit in all three.

### User Story 4 - More emotes (Priority: P2)

Every mascot, in every style, also shows: **Thương** (heart eyes, a heart rising) when Gret is
tapped or a friend is unlocked; **Ngạc nhiên** (round eyes, "O" mouth) at a 7/21/40/66-day
milestone; **Tự hào** (^^ eyes, a sparkle) after a full session or returning from the
intervention; **Nháy mắt** at the morning greeting or now and then when tapped. Existing moods
(happy, neutral, sad, focused, sleeping, celebrating, blink) are redrawn in each style.

### Edge Cases

- Progress never goes down; counts come from data already stored (sessions, events, habit logs,
  habits' reminder times); nothing new is stored except what is chosen.
- Old saves that chose a removed or renamed mascot fall back to Gret.

## Requirements

- **FR-001**: Rename the crab to "Bơ" in catalog, café and strings.
- **FR-002**: New unlock kinds MUST be pure, unit-tested rules over stored data: on-time starts,
  returns after an intervention, focused hours, a habit milestone; each reports progress.
- **FR-003**: New species (seahorse, pufferfish, jellyfish, penguin, whale) need only a body SVG on
  the shared 240×200 canvas; face layers are shared by all species within a style. Art lives in
  `assets/mascot/<style>/…` for the three styles, with the same body geometry so outfits fit.
- **FR-006**: The chosen style is stored with Góc của Gret's choices (unknown → 3D mềm) and
  `MascotLook.layers` picks the style's folder; new moods `love`, `surprised`, `proud`, `wink`
  (unknown stored moods fall back as today).
- **FR-004**: The intervention screen's native Gret drawables are regenerated from the new art.
- **FR-005**: Colours inside the SVG files only; no real-money unlocks (ADR-0009).

## Success Criteria

- **SC-001**: The lead sees every mascot in the new style in Góc của Gret and on Hôm nay.
- **SC-002**: Existing tests pass after renaming; new rules covered by unit tests.
