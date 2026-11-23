# Feature Specification: Góc của Gret (wardrobe, seas, mascots)

**Feature Branch**: `feature/003-gret-ocean` (continues the redesign)
**Created**: 2026-11-23
**Status**: Implemented (2026-11-24); real-money checkout not started
**Input**: Project lead: "thiết kế thêm 1 mục tủ đồ cùng với lại map để có thể đổi khung cảnh biển
và thay đồ cho Gret, cũng như mua những linh vật mới ngoài Gret … tủ đồ ở trên góc phải màn hình của
Gret"; "ngọc trai trước để thúc đẩy động lực … tiền thật không thể mua, nhưng vẫn thiết kế thêm
những món bằng tiền thật". Design: `docs/superpowers/specs/2026-11-23-gret-corner-design.md`,
ADR-0009.

## User Scenarios & Testing

### User Story 1 - Earn pearls by studying and dress Gret (Priority: P1)

A student finishes study sessions (S3) and sees pearls grow: one per five focused minutes. From
the wardrobe button on Gret's sea they open Góc của Gret, pick an outfit they can afford, spend
the pearls, and Gret wears it on Hôm nay and during study sessions.

**Independent Test**: With sessions saved, open Góc của Gret, buy an item, wear it, and see it on
Hôm nay; the balance drops by the price and never goes below zero.

**Acceptance Scenarios**:

1. **Given** saved sessions with 25 and 12 focused minutes, **When** Góc của Gret opens, **Then**
   the balance is 7 pearls (5 + 2).
2. **Given** a balance at least the price, **When** the user confirms "Đổi", **Then** the item is
   owned, the balance drops by the price and the item is worn.
3. **Given** a balance below the price, **When** the item is opened, **Then** it shows how many
   pearls are missing and cannot be bought.
4. **Given** an owned item, **When** the user chooses "Mặc" or "Cởi", **Then** Gret wears it (one
   item per slot) or takes it off, on Hôm nay too.
5. **Given** a distraction during a session, **Then** no pearl is ever removed.

### User Story 2 - Change the sea (Priority: P2)

The user browses seas with arrows on the preview or in the Biển tab. Seas open at a 3, 7 or 14-day
best streak; the chosen sea is drawn on Hôm nay and in the focus session.

**Acceptance Scenarios**:

1. **Given** a best streak of 3, **When** the Biển tab opens, **Then** home and coral reef can be
   chosen and the others say which streak opens them.
2. **Given** the current streak breaks, **Then** a sea opened before stays open (best streak).

### User Story 3 - New mascots and premium items (Priority: P3)

The Linh vật tab shows Gret, the hermit crab "Ẩn" for 300 pearls and the octopus "Mochi" marked
"Sắp có". Premium outfits are listed with "Sắp có" and cannot be obtained yet.

**Acceptance Scenarios**:

1. **Given** 300 pearls, **When** the user gets "Ẩn" and chooses it, **Then** "Ẩn" swims in the sea
   instead of Gret (outfits are for Gret only and are hidden on other mascots).
2. **Given** a premium item, **Then** it shows "Sắp có" and no purchase action.

### Edge Cases

- Sessions deleted with their habit: earned pearls drop; owned items stay owned; the balance shows
  0 instead of a negative number.
- "Xoá toàn bộ dữ liệu" removes the choices together with the profile box.
- A stored id that no longer exists in the catalog is ignored.
- Remove animations: previews are still.

## Requirements

- **FR-001**: Earned pearls MUST be Σ⌊focused seconds / 300⌋ over saved sessions; balance MUST be
  max(0, earned − Σ price of owned pearl items). Pearls MUST NOT be purchasable.
- **FR-002**: Items MUST be cosmetic, in slots head, eyes, neck, body, back, one worn per slot.
- **FR-003**: Unlock kinds: pearls (price), streak (best streak ≥ n, free), premium ("Sắp có", not
  obtainable in this version).
- **FR-004**: Choices (owned, worn, sea, mascot) MUST be stored in the profile box; unknown ids
  ignored; no change to existing records.
- **FR-005**: Hôm nay MUST show a wardrobe button at the top right of Gret's sea that opens
  `/gret-corner`; the screen has a preview with arrows to browse seas, the pearl balance, and the
  tabs Tủ đồ, Biển, Linh vật as in the design.
- **FR-006**: The chosen sea, mascot and Gret's outfit MUST be drawn on Hôm nay and in the focus
  session.
- **FR-007**: All text Vietnamese from `app_strings.dart`; colours from `app_theme.dart`; screen
  readers get item name, status and action.

## Success Criteria

- **SC-001**: From Hôm nay, an affordable item can be bought and worn in at most 4 taps.
- **SC-002**: 100% of existing data stays readable; existing users see pearls from past sessions.
