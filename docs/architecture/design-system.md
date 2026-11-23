# Design System (5.2)

> Moved verbatim from the original `CLAUDE.md` (section "Giao diện (5.2 Design system)") on 2026-11-22 so that `CLAUDE.md` and
> `AGENTS.md` stay short. Features 001 (three tabs, Hôm nay) and 002 (bounded motivation dose, no
> social features) have updated the parts they changed. The older text is in Vietnamese;
> translate a section to English when you substantially edit it (Constitution: docs in English).

## Giao diện (5.2 Design system)
Tên app: **DisGret**. Logo: chữ D trắng và cyan trên nền vuông bo góc xanh navy.
Phong cách: bố cục hiện đại, tối giản kiểu mạng xã hội (lấy cảm hứng từ Instagram) nhưng màu sắc theo thương hiệu DisGret:
KHÔNG dùng logo, tên, icon hay font độc quyền của Instagram.
- Bảng màu "Ocean" – xanh nước biển + đen (logo vẫn giữ màu navy #0A2A6B / cyan #22D3EE riêng của nó):
  - Chế độ TỐI (A – "Biển đêm"): nền #06090F, bề mặt thẻ #0E1726, đường kẻ #1C2940, chữ #E8F1FF, chữ phụ #8A9BB5, màu chính (nút) #1F7AE0 chữ trắng, màu nhấn (vòng tiến độ, streak, điểm sức mạnh, link, tab đang chọn) #4CC9F0.
  - Chế độ SÁNG (B – "Mực & đại dương"): nền #F4F7FB, bề mặt thẻ #FFFFFF, đường kẻ #DCE3EE, chữ #0B0F17, chữ phụ #5A6B85, màu chính #0B4F9C chữ trắng, màu nhấn #1E9BD7 (link và trạng thái đang chọn dùng #0B4F9C vì #1E9BD7 hơi nhạt trên nền trắng).
  - Lịch nhiệt 4 mức – tối: #12233D → #163E6E → #1F7AE0 → #4CC9F0; sáng: #E3ECF7 → #A9C8EA → #3D86D1 → #0B4F9C. Lấy bằng `AppColors.heatOf(context)`.
  - Trong ColorScheme: primary = nút chính; secondary = chữ link, tab/chip/ô tick đang chọn; tertiary = màu nhấn cho vòng/thanh tiến độ, vòng streak.
- KHÔNG dùng gradient trang trí: nút "Bắt đầu" (GradientPillButton), thanh tiến độ (GradientProgressBar), vòng streak, vòng tiến độ Focus đều tô màu đặc (giữ tên widget cũ). Chỉ còn lớp phủ đen mờ trên video Reels để chữ dễ đọc.
- Logo: assets/branding/logo_tam.png (bản tạm 512×512, cắt từ ảnh chụp; sẽ thay bằng file gốc cùng tên khi nhóm có). Hiện trên màn onboarding và AppBar trang chủ.
- Icon app và màn khởi động: tạo bằng flutter_launcher_icons và flutter_native_splash (cấu hình cuối pubspec.yaml), nền #0A2A6B. assets/launcher/logo_foreground.png là logo có khoảng đệm (chiếm 72% khung) cho icon adaptive và màn khởi động Android 12+, vì launcher cắt icon theo hình tròn; file này không đóng gói vào app. Đổi logo thì chạy lại `dart run flutter_launcher_icons` và `dart run flutter_native_splash:create`.
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
- Hôm nay (today_screen.dart, feature 003): the sea (`SeaScene(full)`, 46% of the screen height, at least 300) fills the top of the screen behind a transparent header (logo, greeting by time of day, "DisGret", the Góc của Gret pill with the wardrobe icon and pearl count, settings), which takes the surface colour once content scrolls under it; tapping Gret shows a line just below the header; the cards sit on a sheet with 24 px top corners overlapping the sea: a row of `ClarityCard` and `StreakCard`; the goal card (with identity sentence); the "Học tiếp" card (habit + minutes + "Đổi thói quen hoặc thời lượng" opening session_plan_sheet.dart); and exactly ONE session control: GradientPillButton "Bắt đầu" while something is due, otherwise the secondary OutlinedButton "Học thêm một phiên". All cards enter with `StaggeredEntrance`.

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

## Sea map (feature 005, ADR-0010)

- Thói quen tab: a map button in the app bar (lit while shown) switches to `SeaMapView`; the three
  list views stay as they were and the tab still opens on "Theo ngày". The time filter is hidden on
  the map.
- A dark ocean (`AppSeaMap.ocean`) with faint wave lines; one rounded island per goal, alternating
  left and right, coloured by terrain (coral, ice, deep, home). Fog (`AppSeaMap.fog` with soft white
  puffs) covers each island, with a soft clear circle around each discovered point whose radius grows
  from 30 to 120 with min(days, 66) / 66.
- Points: white circles with the point icon and an "n/66" pill once found, a grey "?" before.
  Region labels sit on a surface pill; a small Gret (the chosen mascot and outfit) stands at the top
  right of the region studied last. Tapping a region opens a sheet with its points, days and
  milestone.

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
- Tab Thói quen (habits_screen.dart, theo ảnh 01–06 trong design/habit_kit/): đầu màn có logo, tiêu đề, menu ⋮ (Thêm mục tiêu, Quản lý mục tiêu); 3 chế độ Theo ngày / Tuần / Tổng thể (đổi tên từ "Hôm nay" để không trùng tên tab); chip lọc Tất cả / Sáng / Chiều / Tối theo timeOfDay (thói quen "lúc nào cũng được" chỉ hiện ở Tất cả); nút tròn "+" nổi mở màn Tạo thói quen.
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
