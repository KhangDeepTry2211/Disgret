# Implementation Plan: Góc của Gret

**Spec**: `specs/004-gret-corner/spec.md` · **ADR**: 0009 · **Design**:
`docs/superpowers/specs/2026-11-23-gret-corner-design.md`

## Technical context

Flutter, Riverpod 3, Hive (profile box), flutter_svg (already added by feature 003). No new
dependency, no network, no new Hive box.

## Structure

| Layer | File | Role |
|---|---|---|
| Pure logic | `lib/data/pearls.dart` | earned from sessions, balance, per-session gain |
| Catalog | `lib/data/gret_corner_catalog.dart` | items, seas, mascots, unlock rules (pure data) |
| Storage | `lib/data/repositories/gret_corner_repository.dart` | owned, worn, sea, mascot in the profile box |
| Providers | `lib/providers/gret_corner_providers.dart` | balance, best streak, `GretCornerNotifier`, `gretLookProvider` |
| Art | `assets/mascot/outfits/*.svg`, `assets/mascot/crab|octopus/body.svg` | 240×200 layers |
| Sea | `lib/widgets/sea/sea_painter.dart` | `SeaPlace` palettes and decorations |
| UI | `lib/screens/gret_corner_screen.dart` | route `/gret-corner` |

## Data model

- `CornerItem { id, name, slot, rarity, unlock }`, `SeaPlaceInfo { place, name, unlock }`,
  `MascotInfo { species, name, unlock }`; `Unlock = pearls(price) | streak(days) | premium | free`.
- Stored keys in the profile box: `corner_owned` (List<String>), `corner_worn` (Map slot → id),
  `corner_sea` (String), `corner_mascot` (String). Missing keys = nothing owned, home sea, Gret.
- `GretLook { species, outfitLayers, place }` read by `SeaScene`.

## Rules

- Earned = Σ⌊focusedSeconds / 300⌋; spent = Σ price of owned pearl items; balance = max(0, …).
- Best streak = max(current overall streak, longest streak of any habit).
- Outfits are drawn only on Gret.
