# Góc của Gret (wardrobe, seas, mascots) — design

Date: 2026-11-23 · Status: approved by the project lead in chat ("Duyệt, làm luôn") · Feature:
spec `specs/004-gret-corner` · Decision record: ADR-0009.

## Intent

Students need a reason to come back day after day (scenario S3). The lead asked for a wardrobe to
dress Gret, a map to change the sea, and new mascots besides Gret, opened from a button at the top
right of Gret's sea. Reference: the lead's screenshot of "Góc học tập" on toantudo.id.vn (scene
preview with arrows, tabs, a wardrobe grid with rarity and "đang mặc / n bộ"); ideas only, no
assets copied.

## Decisions taken with the lead

- **Pearls (ngọc trai) are earned only by studying and can never be bought with money.** They are
  what motivates. Distractions never take pearls away; the user spends them only by choice.
- Items sold for real money are designed and listed now but show "Sắp có"; payment is a later,
  separate feature with its own ADR (Google Play Billing, network, minors).
- First version works fully offline.

## Goals, non-goals, anti-goals

- Goals: a "Góc của Gret" screen with three tabs (Tủ đồ, Biển, Linh vật); 10 outfits for Gret,
  4 seas, 3 mascots; the chosen look shown on Hôm nay and in the focus session.
- Non-goals: real-money checkout; outfits for mascots other than Gret; trading, gifting, social.
- Anti-goals: pearls lost for a distraction; anything that can be bought instead of studied for;
  timers or "limited offers" that pressure the user; ranking users.

## Approaches considered

1. **Pearls computed from saved sessions; only choices are stored (chosen).** Earned =
   Σ⌊focused minutes / 5⌋ over all saved sessions; balance = earned − Σ price of owned items.
   Nothing can drift or be counted twice, and existing users start with pearls from their history.
2. A stored balance increased after each session: needs a migration for existing users and can be
   counted twice when a session is saved again.

## Design

- Earning: 1 pearl per 5 focused minutes of a session (a 25-minute session = 5 pearls).
- Prices: common 20–40, rare 80–150; some items open at a 3/7/14-day streak (best streak ever, so
  a broken streak never locks anything again); premium items show "Sắp có".
- Catalog v1 (all vector art drawn in code, Gret's 240×200 canvas):
  - Outfits (slots head, eyes, neck, body, back; one item per slot): sailor hat, goggles, coral
    scarf, pink bow, headphones (rare), life vest (rare) for pearls; sunglasses (streak 3) and
    coral crown (streak 7); wizard hat and hero cape premium.
  - Seas: home (free), coral reef (streak 3), ice sea (streak 7), deep sea (streak 14).
  - Mascots: Gret (free), hermit crab "Ẩn" (300 pearls), octopus "Mochi" (premium). New mascots
    reuse Gret's face layers, so only a body is drawn per species.
- Screen: route `/gret-corner`, opened by a wardrobe button at the top right of the sea on Hôm nay.
  Preview of the current look in the chosen sea with arrows to browse seas; pearl balance in the
  app bar; tabs Tủ đồ (equipped line, owned count, filter chips Tất cả / Đã có / Ngọc trai / Chuỗi
  ngày / Cửa hàng, grid of cards with preview, name, rarity and status), Biển, Linh vật. Tapping a
  card opens a sheet with the single action that applies: Đổi (n ngọc trai), Mặc / Cởi, Chọn, or
  the reason it is locked / "Sắp có".
- Storage: owned items, equipped items, sea and mascot are stored in the profile box (like the
  blocked-apps list); no new box, no change to existing records.

## Left to the builder

Exact art, names of the Vietnamese item labels, layout spacing, within `app_theme.dart` tokens.
