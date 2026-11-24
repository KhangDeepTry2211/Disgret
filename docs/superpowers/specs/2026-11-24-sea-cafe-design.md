# Quán San Hô (sea café) — design

Date: 2026-11-24 · Status: approved by the project lead in chat ("Duyệt, làm luôn") · Feature: spec
`specs/006-sea-cafe` · Decision record: ADR-0011.

## Intent

The lead wants students to stop feeling that they study alone ("để các bạn không có cảm giác học 1
mình"). The reference is a "Phòng trà" study room (screenshot from toantudo.id.vn): tables and
seats, everyone studying in the same room, greetings only with ready-made phrases. In DisGret the
room is a café under Gret's sea where Gret studies next to its sea friends. It serves S1 (it is
easier to start when others are already studying) and S2 (friends welcome you back after a
distraction).

Offline first; real people later, in a separate feature.

## Decisions taken with the lead

- Offline first, online later. Online needs a backend, which the constitution forbids today
  (Principle II), so it will need a constitution amendment, its own ADR and a safety review for
  users under 18.
- The companions are **Gret's sea friends**: characters with names, clearly not real people.
- Everyone studies on **their own plan** (habit, minutes, breaks); there is no shared room clock.
  The friends take a break when the student does.
- **Approach A**: the café is a scene of the focus session, chosen in the session plan; "Bắt đầu"
  stays the only way into a session (ADR-0002).
- **The café is the default place** until the student chooses Gret's sea; Gret's sea stays
  visible through the café windows.

## Goals, non-goals, anti-goals

- Goals: a "Học ở" choice (Biển của Gret / Quán San Hô); the café scene during the focus session; an
  owner and three friends who study and react to the session; ready-made greetings; reduced motion;
  light and dark themes.
- Non-goals: online presence or real users; visiting other users' seas; choosing a seat; spending
  pearls in the café or new rewards (pearls stay tied to focused minutes, ADR-0009); making the new
  species wearable in Góc của Gret; changes to Hôm nay's sea, the summary screen or the Kotlin
  intervention screen; a shared clock.
- Anti-goals: friends shown as real users or any "N người đang học" count; any free-text input;
  friends who talk so much they pull attention from studying; friends who scold or guilt-trip; a
  second entry into a study session.

## Approaches considered

1. **The café is a scene of the focus screen (chosen).** One new choice in the plan sheet; the
   focus screen draws the café instead of the sea; the timer, distraction handling, sea clarity and
   pearls are untouched. The friends' rules are pure logic, and "who sits in the café" is one
   provider that an online feature can later feed with real users.
2. The café is one more sea in Góc của Gret. Least work, but it mixes decoration with "where I
   study", needs a trip to the wardrobe, and cannot change per session.
3. The café is its own screen with the session inside. Freest layout (seat picking), but it becomes
   a second entry into a study session (ADR-0002) and duplicates the focus screen.

## Design

### Choosing the place

- The session plan sheet ("Đổi thói quen hoặc thời lượng") gets a "Học ở" row with two sticker
  chips: "Biển của Gret" and "Quán San Hô". Applying the sheet saves the choice in the profile box
  under `study_place` (enum `StudyPlace { sea, cafe }`; missing or unknown values read as `cafe`,
  so every student, new or existing, studies in the café until they choose Gret's sea).
- The choice is a lasting preference, not a one-session override: it applies to every session until
  changed, however the session starts.
- The "Học tiếp" card on Hôm nay shows the place under the habit when it is the café
  ("ở Quán San Hô"), so the choice is visible before "Bắt đầu".
- Hôm nay's own sea is unchanged.

### The café scene

- Shown in place of `SeaScene(full)` in `_FocusSea`, inside the same rounded hero. The habit name,
  the progress ring with the remaining time, the break text and the distraction swat effect stay
  as they are, on top of the café.
- The back wall has round windows that look out on Gret's sea: the terrain is the session
  habit's region (spec 005 FR-005), otherwise the home sea chosen in Góc của Gret; the water clears
  and murks with sea clarity, so the brand mechanic stays visible (builder's call).
- The owner stands behind a counter; three friends sit at small tables, each with a small label
  "name · subject" (e.g. "Ẩn · Toán"); Gret sits at the front table, wearing the user's current
  look (species and outfit from Góc của Gret).
- Roster: the owner Rùa (turtle, new species), Ẩn (crab), Mochi (octopus), Sao (starfish, new
  species) and Gret (fish). The café shows the owner and three friends, never the species the user
  is currently wearing (so a user who wears Ẩn sees Gret at a table instead). The two new species
  only need a body drawing on the shared 240×200 canvas; they are not added to the Góc của Gret
  catalog in this feature.
- Friends use `MascotView` moods: `focused` while studying, `happy` when they cheer or greet,
  `happy` with a cup during a break.
- Light theme: a café by day; dark theme: by night with the lamps on. Colours are `AppCafe` tokens
  in `app_theme.dart`. The scene works on a 360×640 phone.

### What the friends say

- A pure function in `lib/data/sea_cafe.dart` maps a session moment to a speaker and a line:
  session started (the owner greets), back after a distraction (one friend welcomes you back, the
  others look up), break started, break over, halfway through. Speakers rotate so the same friend
  does not always talk; the choice is deterministic for a given session so it can be tested.
- One speech bubble at a time, shown for `AppMotion.speechBubble` (3 s). No lines between moments: the
  friends study quietly.
- Lines are kind and short, two or three variants per moment, in `AppStrings`. They never scold.

### Greetings

- Small sticker chips under the scene: "Chào cả quán!", "Cố lên nhé!", "Mình nghỉ chút", "Cảm ơn
  nha!". Tapping one shows the student's line above Gret and one friend replies with a ready-made
  line.
- The chips show during the first minute of the session and during breaks, and are hidden while
  studying, so the café does not become a toy that pulls attention from studying (builder's call).
- Nothing is stored or sent.

### Reduced motion and accessibility

- With "remove animations": the friends do not bob or move, bubbles appear and disappear without
  animation, nothing loops.
- The scene has one semantics label ("Quán San Hô: Gret đang học cùng Rùa, Ẩn, Mochi");
  each bubble is announced once as a polite live region.

### Data

- New profile key `study_place`. A saved `Session` gets an optional `place` field (default `sea`),
  so the team can compare café and sea sessions in the course report; no screen shows it yet
  (builder's call; old sessions read as `sea`).

### Seam for online later (not built now)

- `cafeCompanionsProvider` returns the seats to draw (character, look, label, mood). Offline it
  returns the sea friends. A future online feature can add real users' Grets to it; only greetings
  from the ready-made list would ever be shared.

### Tests

- Unit: the line rules (moment → speaker and line, rotation, the worn species excluded),
  `StudyPlace` parsing and default.
- Widget: choosing the café in the plan sheet persists and shows on "Học tiếp"; the focus screen
  shows the café when chosen and the sea otherwise; greetings show at the start and in breaks and
  are hidden while studying; a greeting gets a reply; reduced motion schedules no frames; no
  overflow on 360×640.
- Emulator: a full session in the café, light theme, including a distraction and a break.

## Left to the builder

The drawing of the café and the two new species, positions of tables and windows, the exact
wording of lines and greetings, the icons, and where the swat effect sits in the café.
