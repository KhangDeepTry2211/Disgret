# Design System (5.2)

> Moved verbatim from the original `CLAUDE.md` (section "Giao diện (5.2 Design system)") on 2026-11-22 so that `CLAUDE.md` and
> `AGENTS.md` stay short. Features 001 (three tabs, Hôm nay) and 002 (bounded motivation dose, no
> social features) have updated the parts they changed. The older text is in Vietnamese;
> translate a section to English when you substantially edit it (Constitution: docs in English).

## Giao diện (5.2 Design system)
Tên app: **DisGret**. Logo (feature 008): a white bubble holding a blue "D", with Gret peeking up
from the bottom-right corner of a sunny-sea blue (#1E88E5) rounded tile; two sun-yellow bubbles.
Phong cách: bố cục hiện đại, tối giản kiểu mạng xã hội (lấy cảm hứng từ Instagram) nhưng màu sắc theo thương hiệu DisGret:
KHÔNG dùng logo, tên, icon hay font độc quyền của Instagram.
- "Biển nắng" palette (feature 008, replaces "Ocean"; contrast checked in `test/brand_test.dart`):
  - Light: background #F3F8FD, cards #FFFFFF, dividers #D8E4F0, text #0B0F17, secondary text
    #56677F, primary (buttons, white text) #1565C0, links and selected items #0D47A1, rings and
    progress #0097A7.
  - Dark: background #07111F, cards #0F1C2E, dividers #1F3350, text #E8F1FF, secondary text
    #8FA3BF, primary #1B6ED4, links and selected items #6CB6FF, rings and progress #4DD0E1.
  - Sun highlight `AppColors.sun` #FFC93C (pearls, celebrations), text on it `AppColors.onSun`
    #5C3D00. Brand blue `AppColors.brand` #1E88E5 (logo tile, launcher icon, splash).
  - Heat map, light: #E3F2FD → #90CAF9 → #42A5F5 → #1565C0; dark: #10233D → #174A80 → #1B6ED4 →
    #4DD0E1. Read with `AppColors.heatOf(context)`.
  - ColorScheme: primary = main buttons; secondary = links, selected tabs, chips and ticks;
    tertiary = rings, progress bars, streak ring.
  - The sea, Gret, the café and the map keep their own illustration colours.
- KHÔNG dùng gradient trang trí: nút "Bắt đầu" (GradientPillButton), thanh tiến độ (GradientProgressBar), vòng streak, vòng tiến độ Focus đều tô màu đặc (giữ tên widget cũ). Chỉ còn lớp phủ đen mờ trên video Reels để chữ dễ đọc.
- Logo source: `assets/branding/logo.svg`, drawn by `AppLogo` with flutter_svg (Hôm nay header,
  onboarding). Launcher art: `assets/launcher/logo_free.svg`, the same logo without its tile and
  with Gret drawn whole, kept within 56 of 60 units of the centre, because the adaptive icon and the
  splash sit on the same blue and are cropped to a circle (with the tile, Gret was cut into a
  half-leaf). PNGs in `assets/launcher/` (not bundled): `logo.png` 1024 (tile, legacy icon) from
  logo.svg; `logo_foreground.png` 1024 (art at 65%, adaptive icon), `splash_android12.png` 1152
  (art at 823 px, Android 12+ splash) and `splash_logo.png` 512 (older splash) from logo_free.svg.
  After changing either SVG, render the PNGs again (for example headless Edge or Chrome with a
  separate `--user-data-dir`), then run `dart run flutter_launcher_icons` and
  `dart run flutter_native_splash:create`.
- Launcher icon and splash: background #1E88E5. Android only: the iOS folder is unsupported and
  keeps its old assets (the icon tool also rewrites an iOS build setting wrongly).
- Font: Be Vietnam Pro (google_fonts), hỗ trợ tiếng Việt tốt. Tiêu đề đậm 600–700, nội dung 400. File .ttf (400, 500, 600, 700) và giấy phép OFL nằm trong assets/fonts/; main.dart tắt `GoogleFonts.config.allowRuntimeFetching` nên không cần mạng. Dùng độ đậm mới thì phải thêm file .ttf tương ứng.
- Radius (feature 003): 16 for cards (`AppRadius.card`), 24 for the sea scene and other hero illustrations (`AppRadius.hero`), 999 for pills. Shadows very light or none; separate with thin lines.
- Icon nét mảnh (outline), dùng icon Material Symbols rounded.
- Motivation step (`lib/screens/motivation_screen.dart`, route `/motivation`, spec 002, ADR-0003): a bounded dose, not a feed.
  - Top bar: close X (left), position pill "1/3" (same style as the tag chips), "Bỏ qua" (right, before a session only).
  - One reel at a time: no swipe, no scrollable list, each reel plays once (no loop); a tap anywhere pauses or resumes at once. The video is shown whole (fitted, never cropped) over a blurred copy of itself (`AppReels.blurBackground`; black on web) and is lifted above the bottom text when there is room (`AppReels.overlayHeight`).
  - While playing, the bottom shows the title and tag chips on a dark gradient; after a distraction also the primary "Quay lại học".
  - When the reel ends or fails: a dark scrim (`AppColors.reelBlurScrim`) and `ReelEndCard` (`lib/widgets/reel_end_card.dart`) with a title, the primary "Bắt đầu N phút" (`GradientPillButton`, `AppReels.buttonHeight`), the text button "Chỉ 5 phút thôi" and an outlined "Tiếp" while reels remain; after a distraction only "Quay lại học".
  - No like, comment or share control, no counts, no social element anywhere.
- Thanh điều hướng dưới cùng 3 tab: Hôm nay, Thói quen, Tiến độ (ADR-0002, spec 001). Bước động lực (`/motivation`), phiên học (`/focus`) và Tổng kết (`/summary`) chiếm toàn màn hình, không có thanh tab. Khi đang có phiên, dải "phiên đang chạy" (running_session_banner.dart, nền primary) nằm ngay trên thanh tab: tên thói quen, "Còn mm:ss" hoặc "Đang nghỉ", chạm để về phiên.
- Hôm nay (today_screen.dart, feature 003): the sea (`SeaScene(full)`, 46% of the screen height, at least 300) fills the top of the screen behind a transparent header (logo, "DisGret" above the greeting by time of day with the student's name when set, e.g. "Chào buổi sáng, Khôi" (feature 007), the Góc của Gret pill with the wardrobe icon and pearl count, settings), which takes the surface colour once content scrolls under it; tapping Gret shows a line just below the header; the cards sit on a sheet with 24 px top corners overlapping the sea: a row of `ClarityCard` and `StreakCard`; the goal card (with identity sentence); the "Học tiếp" card (habit + minutes + "Đổi thói quen hoặc thời lượng" opening session_plan_sheet.dart); and exactly ONE session control: GradientPillButton "Bắt đầu" while something is due, otherwise the secondary OutlinedButton "Học thêm một phiên". All cards enter with `StaggeredEntrance`.

## Gret and the living sea (feature 003, ADR-0008)

- Gret is an original sea mascot drawn as stacked SVG layers on one 240×200 canvas
  (`assets/mascot/gret/`: body, cheeks, eyes and mouth per mood, z, sparkles). Moods: happy,
  neutral, sad, focused, sleeping, celebrating. Gret is never drawn hurt and never blames.
- Illustration palette (the only place colours outside the UI scheme are allowed, `AppSea` and the
  SVG files): body #22D3EE, fins #1BB8D4, belly #C6F1FA, cheeks #FBD5E3, eyes and mouth #0A2A6B,
  tongue #FF8FA3, sparkles and fish #FFC93C; sea bands clear → murky blend below 70% clarity;
  fish at ≥ 70%, litter below 40%. Dark mode shows a night sea with a moon and the same meaning.
- `SeaScene` variants: hero (Hôm nay, 210 high), compact (onboarding, Tổng kết, Góc của Gret, 170
  high), full (story onboarding and focus session). It takes an `overlay` (speech bubble, ring) and
  a `foreground` (focus distraction effects) and a `GretLook` (mascot, outfit, sea place).
- Onboarding is a story: progress segments, four story pages sharing one sea (hello; scrolling
  murks the sea; studying clears it; Gret calls you back), then one page per question (reel
  length, the quiz in Gret's thought bubble with large icon cards and a 400 ms happy reaction, the
  apps that pull the user away, the first goal) and "Biển của bạn đã sẵn sàng" for 1.2 s.
- Focus session: the sea fills the screen; the habit name and countdown ring sit in the sky; two
  stat cards and "Kết thúc sớm" below. Gret focuses (sleeps on a break); every 12 s a distraction
  drifts in and Gret bats it away; coming back after a distraction bursts three away.
- Tổng kết: compact sea with a celebrating Gret, "+N% độ trong" counting up, "+N ngọc trai", and a
  `StreakCard` that pulses when the streak grew.
- Motion tokens (`AppMotion`): entrance 280 ms with a 60 ms step and 12 dp rise, count-up 600 ms,
  ring fill 700 ms, sea colour 800 ms, sea loop 8 s, bob 2.4 s, blink every 3–6 s, reaction 400 ms,
  speech bubble 3 s, sea ready 1.2 s, story page 4 s, distraction every 12 s / drift 2.2 s / burst
  0.9 s, wiggle 420 ms; curve easeOutCubic.
- Reduced motion: with the system "remove animations" setting, nothing loops, numbers and scenes
  show their end state, story pages wait for a tap, the quiz answer and the finish go through at
  once, and no distraction effect runs.

## Lively buttons (feature 003, button styles 1–3 and 5)

Tokens: `AppButton` and `AppMotion.press` / `AppMotion.bubbleBurst` in `app_theme.dart`.

- Raised pill (style 1, `GradientPillButton`): the solid primary face stands on a darker edge
  (primary mixed 45% towards the shadow colour, `AppButton.edge` = 5 px). While pressed, the face
  sinks onto the edge in 70 ms and the phone gives a light tick. Disabled: flat grey, no edge.
  Hero height 72 (large text) for "Bắt đầu"; `AppButton.compact` (52) for Lưu, Tiếp tục, the
  onboarding "Tiếp" and the Góc của Gret buttons.
- Breathing (style 2, `breathing: true`): the button grows to 104% and back on the `AppMotion.bob`
  rhythm. Only the hero "Bắt đầu" on Hôm nay breathes: one invitation per screen.
- Bubbles (style 3, `bubbles: true` or `BubbleBurst.showFrom(context)`): 7 bubbles in the tertiary
  colour rise about 70 px from the widget and fade in 0.9 s. They are drawn in the root overlay,
  so they keep rising when a sheet closes. Used only for "done" moments: Lưu on the summary,
  obtaining an item with pearls, and ticking a habit card.
- Sticker chips (style 5, `StickerChip`): a `ChoiceChip` with a pastel `AppHabitColors` background,
  an icon and a 2 px border in its own colour when selected; it wiggles once (420 ms, at most
  0.1 rad) when it becomes selected. Used for the Tất cả / Sáng / Chiều / Tối filter on Thói quen
  (one row that fits a 412 dp phone, scrolls on smaller ones) and, in the large size, for the
  reel-length and "App nào hay kéo bạn đi nhất?" answers in onboarding.
- Rippling "+" (style F, `RippleAddButton`, chosen from the second round of references): the
  round "+" on Thói quen (`AppButton.fab` 60) is raised like the pill and sinks when pressed; two
  rings in the tertiary colour ripple out to 1.5× (so they stay on screen) and fade
  (`AppMotion.ripple` 1.8 s, half a period apart). While there is no habit yet they keep rippling
  as an invitation; otherwise they
  ripple `AppButton.ripplePulses` (3) times when the button appears and stop.
- Reduced motion: no breathing, no bubbles, no wiggle, no rings; the press still sinks, because it
  is feedback, not decoration.
- Not chosen: hold-to-confirm (style 4); from the second round, Gret peeking, the water-filled
  button, the chunky game button, the two-line button and the pebble button.

## Nhắc giờ học (feature 009, ADR-0006)

- A local notification at the habit's reminder time on its scheduled days, in Gret's voice: title
  "Gret đang đợi bạn 🐟", body "Tới giờ <thói quen> rồi, chỉ <n> phút thôi. Mình bắt đầu nhé?".
  Channel "Nhắc giờ học" (high importance). Status bar icon: a white fish (`ic_stat_gret`).
- Never the student's name (ADR-0012). Tapping opens DisGret on Hôm nay.
- The notification permission is asked once, the first time a reminder exists.

## Quán San Hô (feature 006, ADR-0011)

Tokens: `AppCafe` (colours by day and night, positions, sizes) and `AppMotion.cafeReplyDelay` in
`app_theme.dart`.

- Where: the focus session's scene when the study place is the café (the default). Chosen in the
  session plan sheet ("Học ở": sticker chips Biển của Gret / Quán San Hô); "Học tiếp" on Hôm nay
  shows "ở Quán San Hô".
- The room: wall with bunting and two lamps, a panel band, a plank floor (`SeaCafePainter`); two
  arched windows that look out on Gret's sea (the session habit's region) at the live clarity,
  still; the habit name and countdown ring hang on the wall like a clock (34% of the scene height,
  120–180), between the windows.
- Who: the owner Rùa (turtle) behind the counter on the left; three friends at tables (Ẩn · Toán,
  Mochi · Văn, Sao · Tiếng Anh; Gret takes a seat when the student wears one of them); Gret at the
  front table in the student's look. Sizes follow the scene height (friends 11%, 52–76; Gret 17%,
  84–120). Each friend has a "name · subject" pill.
- Moods: the friends study with the neutral face, smile when someone talks and during breaks;
  Gret keeps the session mood (focused, sleeping on a break).
- Lines: one speech bubble at a time above its speaker for 3 s, at these moments only: start
  (owner), back after a distraction, break start and end, halfway. Never scolding.
- Greetings: a row of small sticker chips at the bottom in the first minute and during breaks;
  Gret says the greeting, a friend replies 1.5 s later.
- Never shown as real people, no counts (ADR-0011). Reduced motion: nothing moves, bubbles appear
  without fading.

## Sea map (feature 005, ADR-0010)

- Full screen (`/sea-map`, `sea_map_screen.dart`), opened by the map button in the Thói quen app
  bar; the tab itself keeps its three list views and opens on "Theo ngày".
- One dark ocean (`AppSeaMap.ocean`) with faint wave lines. Each goal is an island with a wobbly
  outline (`IslandLayout.outline`), a shallow-water ring and a lighter heart, coloured by terrain
  (coral, ice, deep, home); islands sit on slots spiralling out from the centre, followed by two
  grey "Vùng chưa biết" seas.
- Darkness (`AppSeaMap.worldFog`) covers the world; soft circles open around discovered points
  (radius 70–230 with min(days, 66) / 66) and around Gret. The screen behind the world uses
  `AppSeaMap.fogOcean` so the world's edge does not show.
- Pins: light teardrops with the point icon and an "n/66" pill; a grey "?" circle before discovery.
  Island labels on a dark pill: goal title and "<terrain> · Độ khám phá n%".
- Controls on top of the map: back, title and overall percentage; +/− (×1.4); "Về chỗ Gret". Pan and
  pinch-zoom between 0.2× and 2.5×. Opening glides from the whole world to Gret's island
  (`AppMotion.mapOpen`, 1.6 s); buttons glide in 0.6 s; with reduced motion the view jumps.

## Góc của Gret (feature 004, ADR-0009)

- Route `/gret-corner`, opened from the wardrobe button on the Hôm nay sea. App bar: title and the
  pearl balance chip. Preview: compact sea with the current look and arrows to browse seas (a
  locked sea is only previewed, with its streak requirement). Tabs Tủ đồ, Biển, Linh vật.
- Cards: three per row, preview, name, "rarity · status". Rarity colours (`AppCorner`): common =
  outline, rare #7F77DD, special #E8A600; the worn or chosen card has a primary border. Tapping a
  card opens a sheet with the single action that applies or the reason it is locked.
- New mascots reuse Gret's face layers; only a body is drawn per species
  (`assets/mascot/crab/`, `assets/mascot/octopus/`). Outfits live in `assets/mascot/outfits/`, on
  the same canvas, drawn in the order back, body, neck, eyes, head.
- Bảng 12 màu pastel cho thẻ thói quen: AppHabitColors.palette trong app_theme.dart, mỗi màu có nền và màu chữ đậm cùng tông, dùng chung cho sáng và tối.
- Màn Tạo/Sửa thói quen (habit_form_screen.dart, theo ảnh 07–11 trong design/habit_kit/): một trang cuộn, tab Thói quen / Việc một lần, tên, icon (5 chọn nhanh + "Xem tất cả" mở habit_icon_picker.dart: tìm kiếm không dấu, tab Icon / Emoji), 12 màu, Lặp lại, Làm vào, Kết thúc vào, Nhắc nhở, số phút, "Sau khi…", "Bản 2 phút", nút Lưu viên thuốc màu primary.
- Tab Thói quen (habits_screen.dart, theo ảnh 01–06 trong design/habit_kit/): đầu màn có logo, tiêu đề, menu ⋮ (Thêm mục tiêu, Quản lý mục tiêu); 3 chế độ Theo ngày / Tuần / Tổng thể (đổi tên từ "Hôm nay" để không trùng tên tab); chip lọc Tất cả / Sáng / Chiều / Tối (sticker chips, see Lively buttons) theo timeOfDay (thói quen "lúc nào cũng được" chỉ hiện ở Tất cả); nút tròn "+" nổi mở màn Tạo thói quen.
  - Theo ngày (habit_today_card.dart): thói quen đến hạn là thẻ nền pastel, emoji/icon bên trái, tên đậm. Chạm = xong (dải ✓ trượt + rung nhẹ, thẻ chuyển xuống "Đã xong"); chạm thẻ đã xong để bỏ (trừ khi đủ phút nhờ Focus). Vuốt phải = xong, vuốt trái = "Bỏ qua" (log skip, xuống "Đã bỏ qua"). Giữ lâu: Làm bản 2 phút, Nghỉ phép, Bắt đầu Focus (chọn thói quen này cho kế hoạch rồi mở bước động lực), Xem chi tiết, Sửa, Xoá. Có phút Focus chưa đủ thì hiện "x/y phút" và vạch tiến độ mỏng.
  - Tuần (HabitWeekCard): tên, tần suất, 7 ô T2–CN; chạm ô đổi chưa làm → xong → bỏ qua → chưa làm; ngày tương lai và ngày đủ phút nhờ Focus thì khoá.
  - Tổng thể (HabitOverallCard): lưới chấm 20 tuần, màu chấm AppHabitColors.levelColor theo mức hoàn thành.
- Tiến độ (progress_screen.dart): SegmentedButton "Thói quen" (ReportView) | "Phiên học" (StatsView); chưa có lịch sử thì hiện trạng thái trống "Tiến độ sẽ hiện ở đây sau phiên học đầu tiên."
- Báo cáo (report_screen.dart → ReportView, ảnh 13–15, đoạn "Thói quen" của tab Tiến độ): 4 ô (chuỗi hiện tại, tỉ lệ hoàn thành, lần hoàn thành, ngày hoàn hảo), biểu đồ cột "Đã hoàn thành" và đường "Tỉ lệ hoàn thành" (fl_chart, menu chọn kỳ Tuần này / Tuần trước / Tháng này / Tháng trước / 6 tháng / Năm nay / Tất cả, cột/điểm đang chọn có bong bóng giá trị), lịch tháng vòng tròn theo % (month_calendar.dart). Tính cả thói quen đã ẩn (chỉ các ngày đã làm).
- "Thói quen của tôi" (my_habits_screen.dart, ảnh 17, menu ⋮): 2 tab Thói quen / Việc một lần, kéo tay kéo để sắp xếp (HabitsNotifier.reorderWithinType lưu sortOrder).
- ĐÃ CẤT (ADR-0004, parked-features.md) — Thành tích (achievements_screen.dart, không còn lối vào): 9 cấp theo tổng số lần hoàn thành của mọi thói quen (10, 30, 66, 100, 200, 365, 500, 750, 1000; lib/data/achievements.dart), huy hiệu lục giác tự vẽ (level_badge.dart). Trước đây lên cấp thì MainShell hiện hộp thoại chúc mừng một lần (đã bỏ), cấp đã chúc mừng lưu ở box profile khoá `celebrated_level`; "Tạo dữ liệu mẫu" lưu luôn cấp hiện tại nên không chúc mừng. Tách riêng với 4 huy hiệu Hành trình 66 ngày.
- Màn chi tiết (ảnh 16): nút Sửa / Xoá trên AppBar, 6 ô số liệu (thêm Lần hoàn thành, Sức mạnh), lịch tháng tô ngày đã xong bằng màu thói quen.
- HabitCard (vòng tiến độ phút, streak, sức mạnh, nhắc "Đừng bỏ 2 lần liên tiếp", ghi chú) ĐÃ CẤT: Hôm nay không còn danh sách thói quen. Màn chi tiết: /habit/:id (biểu đồ đường bằng fl_chart; Hành trình 66 ngày và lịch nhiệt 16 tuần đã cất).
- TẤT CẢ màu, font, bo góc, khoảng cách đặt trong MỘT file lib/theme/app_theme.dart (kèm class AppColors, AppSpacing, AppRadius). Màn hình không được viết mã màu cứng, phải lấy từ theme, để sau này đổi giao diện chỉ cần sửa một chỗ.
- Riêng màn can thiệp (2.3) viết bằng Kotlin nên không đọc được file trên: màu của nó nằm trong android/app/src/main/res/values/colors.xml (hiện dùng màu chế độ tối A: disgret_navy = #06090F làm nền, disgret_cyan = #4CC9F0 làm nút; tên màu giữ nguyên). Đổi màu thương hiệu thì phải sửa cả hai nơi.
