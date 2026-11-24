# Sea map (bản đồ biển) — design

Date: 2026-11-24 · Status: approved by the project lead in chat ("Duyệt, làm luôn") · Feature:
spec `specs/005-sea-map` · Decision record: ADR-0010.

## Intent

The lead wants the goals and habits to feel like exploring a sea: creating a goal adds a sea
region, each habit is a discovery point in it, and while the user works on a goal Gret goes there
and explores it, "like opening the map in Genshin Impact" (fog that clears, an exploration
percentage; mechanics only, no assets or names from that game). It serves S3: days of practice
become visible progress on a map that never goes backwards.

## Decisions taken with the lead

- One region per goal; each habit of the goal is a discovery point in the region.
- The fog clears with the **number of days the habit was done** (not necessarily in a row): a point
  is fully explored at 66 days, with milestones 7 / 21 / 40 / 66. The map never fogs over again.

## Goals, non-goals, anti-goals

- Goals: a "Bản đồ" view in the Thói quen tab; regions, points, fog, percentages; Gret standing in
  the region studied most recently; the focus session drawn in that region's sea.
- Non-goals: choosing a region's terrain by hand, moving points, rewards for exploring (pearls stay
  tied to focused minutes, ADR-0009), sharing the map.
- Anti-goals: fog coming back, any penalty for missed days, a map that pushes the daily tick list
  out of reach.

## Approaches considered

1. **Draw the map in code (`CustomPainter`) with the points as widgets on top (chosen).** Same
   technique as the sea, works offline, follows the user's own goals and habits.
2. A map package such as `flutter_map`: loads tiles over the network (forbidden) and is built for
   geography.
3. Pre-drawn map images: cannot follow a variable number of goals and habits.

## Design

- Thói quen tab: a "Bản đồ" view opened by a map button in the app bar (built that way instead of a
  fourth segment, which wrapped "Theo ngày" on two lines). The tab still opens on Theo ngày, where
  habits are ticked (builder's call: daily ticking stays one tap away). The time filter is hidden on
  the map.
- Regions: one per goal, in goal order, terrain cycling coral reef → ice sea → deep sea → home sea.
  Each region is a rounded island-shaped area on a dark ocean, alternating left and right down a
  scrolling map, with the goal title and its percentage.
- Points: one per habit of the goal (archived habits keep their point; deleting with history
  removes it). The kind cycles fish cave → shipwreck → kelp garden → treasure chest → coral temple
  → old anchor. With 0 days done the point is a "?"; from the first day it shows its icon; a clear
  circle around it grows with min(days, 66) / 66, and its label shows "n/66".
- Percentages: region = Σ min(days, 66) / (66 × points); map total = the same over all points.
- Gret: a small Gret stands in the region of the habit studied most recently (the latest habit log),
  or of the running session's habit.
- Tapping a region opens a sheet: goal, percentage, and each point with its habit, "n/66 ngày" and
  milestone ("Khởi động", "Bền bỉ", "Vững vàng", "Thành thói quen"). Tapping a "?" point shows how to
  discover it ("Làm … lần đầu để khám phá").
- Focus session: the sea is the terrain of the session habit's region (the chosen home sea of Góc
  của Gret still shows on Hôm nay).
- Nothing new is stored: everything is computed from goals, habits and habit logs.

## Amendment 2026-11-24: full-screen world map

The lead asked for the map to fill the screen and open bit by bit, like a game world map. The map
button now opens `/sea-map`: one dark ocean where each goal is an island with a natural, wobbly
outline on slots spiralling out from the centre, followed by two "Vùng chưa biết" seas waiting for
new goals. Darkness covers the whole world; soft circles open around discovered points (radius
70–230 with the days done) and around Gret. The map pans and pinch-zooms (0.2×–2.5×), with +/−,
"Về chỗ Gret", a back button, the title and the overall percentage on top. Opening glides from the
whole world to Gret's island (1.6 s; straight there with animations removed). Pins are teardrops
with the point icon and "n/66"; island labels read "<terrain> · Độ khám phá n%".

## Left to the builder

Island shapes and positions, fog drawing, icons, wording of the sheet.
