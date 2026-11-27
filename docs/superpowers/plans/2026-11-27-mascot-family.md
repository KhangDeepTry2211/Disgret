# Mascot family (spec 018) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (native, chosen by
> the lead for this redesign) to implement this plan task-by-task. Steps use checkbox (`- [ ]`)
> syntax for tracking.

**Goal:** Rename the crab to Bơ, add six friends earned by studying, draw every mascot in three
styles the student picks in Góc của Gret (3D mềm by default), add four emotes, and redraw the
intervention screen's Gret from the new art.

**Architecture:** Study unlocks are a pure rule (`lib/data/study_unlocks.dart`) over sessions,
events, habits and habit histories, read by the Góc của Gret notifier next to pearls and streaks.
The style is one more stored choice of Góc của Gret; `MascotLook.layers` builds the asset paths for
a style, and `MascotView` reads the style from an inherited `MascotStyleScope` placed under
`MaterialApp` (default 3D mềm, so widgets pumped alone still work). All art comes from one Python
generator that defines each shape once and renders it in the three styles; the same generator's
output feeds the vector-drawable converter for Android.

**Tech Stack:** Flutter 3.50, Riverpod 3, Hive, flutter_svg; Python 3 (scratch generator, not
shipped); Kotlin VectorDrawable.

**Spec:** `specs/018-mascot-family/spec.md`

## Global Constraints

- Shared 240×200 canvas; face at eyes (92,104)/(140,104), mouth (116,130), cheeks (76,124)/(156,124)
  in every style; Gret's body keeps ellipse (115,112) rx 72 ry 62 so outfits fit.
- Colours only inside the SVG files (FR-005); no real-money unlocks (ADR-0009).
- Unknown stored style → `MascotStyle.soft`; unknown stored mascot → Gret (existing rule).
- Nothing new stored except the chosen style and mascots the student chooses.
- UI text Vietnamese in `AppStrings`; code and docs English.
- Kotlin change → run `docs/architecture/native-manual-checklist.md` and record it.

## Review Focus

- A study friend's progress dips (a habit day unticked) after it was chosen: the choice must stay
  (choosing stores the id in `owned`; the lock is `owned || progress >= goal`).
- Five sessions started inside one reminder window on one day: counts once (distinct habit+day).
- A habit without a reminder, or a session on an unscheduled day before the reminder: not on time.
- Large text / small screen: the "Nét vẽ" chips wrap and the mascot grid still scrolls.
- Reduced motion: emotes still show (they are layers, not animations).

---

### Task 1: Bơ, new friends and study unlocks

**Files:**
- Modify: `lib/data/mascot_species.dart` (append `seahorse, pufferfish, jellyfish, penguin, whale`;
  add `enum MascotStyle { classic, flat, soft }`)
- Modify: `lib/data/gret_corner_catalog.dart` (new `UnlockKind`s and constructors, catalog)
- Create: `lib/data/study_unlocks.dart`
- Modify: `lib/providers/gret_corner_providers.dart`, `lib/data/sea_cafe.dart` (comment)
- Test: `test/study_unlocks_test.dart`, `test/gret_corner_providers_test.dart`

**Interfaces (produces):**
- `UnlockKind.onTimeStarts | interventionReturns | focusHours | habitDays`;
  `const Unlock.onTimeStarts(int times)`, `.interventionReturns(int times)`, `.focusHours(int hours)`,
  `.habitDays(int days)`; `bool get isStudy`.
- `class StudyFacts { onTimeStarts, interventionReturns, focusedSeconds, bestHabitDays }` with
  `static StudyFacts from({sessions, habits, events, histories})`,
  `bool reached(Unlock)`, `double progressOf(Unlock)` (hours as a double, others as counts).
- `StudyUnlocks.onTimeWindow = Duration(minutes: 10)`.
- `CornerLock.study`; `studyFactsProvider`; `GretCornerNotifier.chooseMascot` adds a study
  friend's id to `owned`.
- Catalog order and unlocks: Gret free, Bơ pearls 300, Tép onTimeStarts 5, Phồng
  interventionReturns 5, Mây focusHours 10, Mochi focusHours 30, Bông habitDays 21, Bự habitDays 66.

- [ ] Tests: `on-time start counts a session 0–10 min after the habit's reminder, once per habit and
  day`; `not on time without a reminder or 11 min late`; `returns count chose_study events`;
  `focused hours sum focusedSeconds`; `best habit days is the largest done-day count`;
  `reached/progressOf per kind`; provider: `study friend locked until reached, stays chosen after
  progress dips`; catalog: `crab is called Bơ`, `Mochi needs 30 focus hours`.
- [ ] Run, see them fail; implement; run `flutter test` on those files, see them pass.

### Task 2: Art generator (three styles, four emotes)

**Files:**
- Create (scratch, kept in the spec folder for regeneration): `specs/018-mascot-family/mascot_art.py`
- Create: `assets/mascot/flat/*.svg`, `assets/mascot/soft/*.svg`,
  `assets/mascot/{seahorse,pufferfish,jellyfish,penguin,whale}/body.svg`,
  `assets/mascot/gret/{eyes,mouth}_{love,surprised,proud,wink}.svg`, `gret/{hearts,sparkle,burst}.svg`
- Modify: `pubspec.yaml` (asset folders)

Per style: `body_<species>.svg` for the 10 species, `tail.svg`, `cheeks.svg`,
`eyes_<mood|blink>.svg`, `mouth_<mood>.svg`, `zzz.svg`, `sparkles.svg`, `hearts.svg`,
`sparkle.svg`, `burst.svg`. Classic keeps today's files and adds only the missing ones.
Styles: classic = flat fills, no outline; flat = outline #4A3428 w4, bead eyes #2A1C14, cheeks
#FFB3C7; soft = radial gradients in `userSpaceOnUse` (light top-left → base → shade), tonal outline
(darker shade of the fill, w3), soft shadow ellipse under the body, cheeks with freckles, eyes "C ·
Hạt đậu bóng".

- [ ] Generate; render a contact sheet (all species × styles × moods) with headless Edge and look
  at it; fix shapes until every face sits on its body.

### Task 3: Styles and emotes in the app

**Files:**
- Modify: `lib/data/mascot_mood.dart` (append `love, surprised, proud, wink`),
  `lib/widgets/mascot/mascot_look.dart`, `lib/widgets/mascot/mascot_view.dart`
- Create: `lib/widgets/mascot/mascot_style_scope.dart`, `lib/providers/gret_emote_provider.dart`
- Modify: `lib/data/repositories/gret_corner_repository.dart`, `gret_corner_providers.dart`,
  `lib/app.dart`, `lib/screens/gret_corner_screen.dart`, `today_screen.dart`,
  `summary_screen.dart`, `lib/providers/sea_providers.dart`, `app_providers.dart` (milestone)
- Test: `test/gret_sea_widgets_test.dart`, `test/gret_corner_screen_test.dart`,
  `test/mascot_family_test.dart`

**Interfaces:**
- `MascotLook.layers(mood, {species, style = MascotStyle.soft, blinking, outfit})`,
  `MascotLook.tailOf(MascotStyle)`, `MascotLook.isTail(String)`.
- `MascotStyleScope({required MascotStyle style, required Widget child})`,
  `static MascotStyle of(BuildContext)` → soft when absent. `MascotView({style})` overrides it.
- Repository `style` / `saveStyle`; state `style`; `GretCornerNotifier.chooseStyle(MascotStyle)`.
- `gretEmoteProvider` (`Notifier<MascotMood?>`, `show(MascotMood)`, clears after
  `AppMotion.emote` = 2.5 s); `seaStateProvider` mood = emote ?? rule.
- Triggers: Today tap → love (wink one tap in three); Today opened before 11:00 → wink once;
  chose_study action → proud; summary of a session finished on time → proud; a habit reaching
  7/21/40/66 done days → surprised; an earned friend's sheet → love.
- Strings: `cornerStyleTitle` 'Nét vẽ', labels 'Cổ điển' / 'Phẳng viền' / '3D mềm', progress and
  need texts per study kind, moods and lines for the four emotes.

- [ ] Tests first: layer paths per style; tail detection; scope default; choosing a style persists
  and redraws; the Linh vật tab shows the 8 friends with progress text; tap emote; summary proud.
- [ ] Implement until green.

### Task 4: Intervention Gret from the new art

**Files:**
- Modify: scratch `svg2vector.py` (gradients via `aapt:attr`, stroke-linejoin, opacity)
- Regenerate: `android/app/src/main/res/drawable/gret_tail.xml`, `gret_front.xml` from
  `assets/mascot/soft/{tail, body_gret, cheeks, eyes_focused, mouth_neutral}.svg`
- Modify: `GretGuardView.kt` (fin outline paint), `res/values/colors.xml` (`gret_fin_outline`)

- [ ] Build the debug APK; open "Thử màn can thiệp"; capture; run the native checklist.

### Task 5: Gates and docs

- [ ] `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`.
- [ ] `specs/018-mascot-family/tasks.md`, spec status, design-system paragraph, README map line.
- [ ] Emulator: Góc của Gret (three styles, eight friends), Hôm nay tap emote.
