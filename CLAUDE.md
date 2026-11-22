# Focus App – MVP môn Tư Duy Tính Toán

App giúp sinh viên bắt đầu học và quay lại tập trung sau khi bị xao nhãng.
Vòng chính: Habit tracker (mục tiêu) → Anti-reel reels (động lực) → Focus mode (học) → tổng kết → streak.
Nhánh phụ: đang học mà mở TikTok → Reset break (màn can thiệp) → quay lại học / xem reel / nghỉ có hẹn giờ.

## Ràng buộc MVP
- Chỉ Android. Dữ liệu chính lưu local bằng Hive. Firebase đã nối (F1) và có đăng nhập + đồng bộ Firestore (F2), xem 2 mục bên dưới. Chưa đăng nhập hoặc không có mạng thì app vẫn phải chạy được chỉ với Hive.
- Flutter + Riverpod + go_router + Material 3. Toàn bộ chữ trên giao diện bằng tiếng Việt.
- Phần theo dõi app khác viết bằng Kotlin native, gọi qua MethodChannel tên "focus/native".
- Mỗi phần code ghi mã thành phần theo sơ đồ phân rã trong comment, ví dụ `// 2.3 Màn can thiệp`.

## Môi trường test
- Không có điện thoại Android thật: test trên máy ảo Android (Pixel, API 34+, bản có Google Play).
- App dùng để test chặn: YouTube và Chrome (có sẵn trong máy ảo), thêm TikTok nếu đã cài.
- Danh sách app chặn mặc định (2.1): TikTok, Facebook, Instagram, YouTube, Chrome.
- Nếu máy ảo chậm, GĐ1–GĐ4 có thể chạy tạm bằng `flutter run -d chrome`; code phải chạy được trên cả web lẫn Android (không gọi MethodChannel khi chạy trên web, dùng `kIsWeb` để bỏ qua).
- Reset break (GĐ5) chỉ test trên máy ảo Android hoặc máy thật, không chạy trên web.

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
- Bo góc 12 cho thẻ, 999 cho nút dạng viên thuốc. Bóng đổ rất nhẹ hoặc không có; phân tách bằng đường kẻ mảnh.
- Icon nét mảnh (outline), dùng icon Material Symbols rounded.
- Màn Reels: vuốt dọc, video hiện trọn vẹn không bị cắt (co vừa khung), phía sau là chính video đó làm mờ (tắt bằng `AppReels.blurBackground`; trên web nền chỉ là màu đen). Chữ và nút nổi ở đáy, có lớp mờ gradient đen để chữ dễ đọc.
  - Tim / Bình luận / Chia sẻ (reel_action_column.dart): cột dọc bên phải, trên nút "Bắt đầu 5 phút"; icon Material, bóng mờ AppReels.onVideoShadows, màu đã thích AppColors.reelLiked. Tim đổi đặc/rỗng và nảy nhẹ; chạm ĐÚP vào video = thích (tim lớn BurstHeart bay lên, không bỏ thích). Chạm đơn tạm dừng/phát NGAY, không chờ: chạm thứ hai trong AppReels.doubleTapWindow thì hoàn lại lần đổi đó rồi thích (không dùng onDoubleTap vì nó làm chạm đơn trễ ~300ms). Số bình luận thật hiện dưới nút Bình luận, bằng 0 thì ẩn số; không có số lượt thích giả.
  - Bình luận (reel_comments_sheet.dart): bottom sheet cao ~60%, mới nhất ở dưới, tối đa 300 ký tự, nhấn giữ bình luận của mình để xoá (có xác nhận). Mở sheet thì tạm dừng video, đóng thì phát lại.
  - Chia sẻ (reel_share.dart): share_plus, chỉ chia sẻ đoạn chữ (không gửi video). Không mở được bảng chia sẻ thì chép clipboard + SnackBar "Đã chép nội dung chia sẻ".
- Thanh điều hướng dưới cùng 4 tab: Trang chủ, Reels, Focus, Thói quen.
- Bảng 12 màu pastel cho thẻ thói quen: AppHabitColors.palette trong app_theme.dart, mỗi màu có nền và màu chữ đậm cùng tông, dùng chung cho sáng và tối.
- Màn Tạo/Sửa thói quen (habit_form_screen.dart, theo ảnh 07–11 trong design/habit_kit/): một trang cuộn, tab Thói quen / Việc một lần, tên, icon (5 chọn nhanh + "Xem tất cả" mở habit_icon_picker.dart: tìm kiếm không dấu, tab Icon / Emoji), 12 màu, Lặp lại, Làm vào, Kết thúc vào, Nhắc nhở, số phút, "Sau khi…", "Bản 2 phút", nút Lưu viên thuốc màu primary.
- Tab Thói quen (habits_screen.dart, theo ảnh 01–06 trong design/habit_kit/): đầu màn có logo, tiêu đề, menu ⋮ (Thêm mục tiêu, Quản lý mục tiêu); 3 tab Hôm nay / Tuần / Tổng thể; chip lọc Tất cả / Sáng / Chiều / Tối theo timeOfDay (thói quen "lúc nào cũng được" chỉ hiện ở Tất cả); nút tròn "+" nổi mở màn Tạo thói quen.
  - Hôm nay (habit_today_card.dart): thói quen đến hạn là thẻ nền pastel, emoji/icon bên trái, tên đậm. Chạm = xong (dải ✓ trượt + rung nhẹ, thẻ chuyển xuống "Đã xong"); chạm thẻ đã xong để bỏ (trừ khi đủ phút nhờ Focus). Vuốt phải = xong, vuốt trái = "Bỏ qua" (log skip, xuống "Đã bỏ qua"). Giữ lâu: Làm bản 2 phút, Nghỉ phép, Bắt đầu Focus, Xem chi tiết, Sửa, Xoá. Có phút Focus chưa đủ thì hiện "x/y phút" và vạch tiến độ mỏng.
  - Tuần (HabitWeekCard): tên, tần suất, 7 ô T2–CN; chạm ô đổi chưa làm → xong → bỏ qua → chưa làm; ngày tương lai và ngày đủ phút nhờ Focus thì khoá.
  - Tổng thể (HabitOverallCard): lưới chấm 20 tuần, màu chấm AppHabitColors.levelColor theo mức hoàn thành.
- Báo cáo (report_screen.dart, ảnh 13–15, nút trên AppBar tab Thói quen): 4 ô (chuỗi hiện tại, tỉ lệ hoàn thành, lần hoàn thành, ngày hoàn hảo), biểu đồ cột "Đã hoàn thành" và đường "Tỉ lệ hoàn thành" (fl_chart, menu chọn kỳ Tuần này / Tuần trước / Tháng này / Tháng trước / 6 tháng / Năm nay / Tất cả, cột/điểm đang chọn có bong bóng giá trị), lịch tháng vòng tròn theo % (month_calendar.dart). Tính cả thói quen đã ẩn (chỉ các ngày đã làm).
- "Thói quen của tôi" (my_habits_screen.dart, ảnh 17, menu ⋮): 2 tab Thói quen / Việc một lần, kéo tay kéo để sắp xếp (HabitsNotifier.reorderWithinType lưu sortOrder).
- Thành tích (achievements_screen.dart, menu ⋮): 9 cấp theo tổng số lần hoàn thành của mọi thói quen (10, 30, 66, 100, 200, 365, 500, 750, 1000; lib/data/achievements.dart), huy hiệu lục giác tự vẽ (level_badge.dart). Lên cấp thì MainShell hiện hộp thoại chúc mừng một lần, cấp đã chúc mừng lưu ở box profile khoá `celebrated_level`; "Tạo dữ liệu mẫu" lưu luôn cấp hiện tại nên không chúc mừng. Tách riêng với 4 huy hiệu Hành trình 66 ngày.
- Màn chi tiết (ảnh 16): nút Sửa / Xoá trên AppBar, 6 ô số liệu (thêm Lần hoàn thành, Sức mạnh), lịch tháng tô ngày đã xong bằng màu thói quen.
- Trang chủ vẫn dùng HabitCard (vòng tiến độ phút, streak, sức mạnh, nhắc "Đừng bỏ 2 lần liên tiếp", ghi chú). Màn chi tiết: /habit/:id (biểu đồ đường bằng fl_chart, lịch nhiệt tự vẽ, màu AppColors.heatOf(context)).
- TẤT CẢ màu, font, bo góc, khoảng cách đặt trong MỘT file lib/theme/app_theme.dart (kèm class AppColors, AppSpacing, AppRadius). Màn hình không được viết mã màu cứng, phải lấy từ theme, để sau này đổi giao diện chỉ cần sửa một chỗ.
- Riêng màn can thiệp (2.3) viết bằng Kotlin nên không đọc được file trên: màu của nó nằm trong android/app/src/main/res/values/colors.xml (hiện dùng màu chế độ tối A: disgret_navy = #06090F làm nền, disgret_cyan = #4CC9F0 làm nút; tên màu giữ nguyên). Đổi màu thương hiệu thì phải sửa cả hai nơi.

## Mô hình dữ liệu (6.2)
- UserProfile: motivationTypes (tiền bạc, gia đình, sự nghiệp, chứng minh bản thân, tự do), preferredReelLength, demoMode
- Goal: title, reason, identity (câu sau "Tôi là người…", mặc định rỗng)
- Habit: goalId, name, minMinutesPerDay, cue (phần sau "Sau khi…"), place (phần sau "Tại…", form mới không còn ô này nhưng dữ liệu cũ vẫn giữ), minimalVersion (bản 2 phút), icon (khoá trong AppIcons.habitIcons hoặc một emoji, mặc định "book"), type (regular / oneTime), colorIndex (0–11, bảng AppHabitColors.palette), repeat (daily / weekly / monthly), daysPerWeek (hằng tuần theo số ngày, dùng khi weekdays rỗng), weekdays (1 = T2 … 7 = CN), monthDays (1–31), timeOfDay (morning / afternoon / evening / anytime), endRule (never / onDate / afterDays) + endDate + endAfterDays, reminderEnabled + reminderTime "HH:mm" (chỉ lưu, chưa gửi thông báo), sortOrder, startDate (ngày tạo), dueDate (việc một lần), archived ("Xoá nhưng giữ lịch sử"). Mọi trường mới đều có mặc định để đọc được dữ liệu cũ; enum lạ thì lấy mặc định
- HabitLog: habitId, date (chỉ ngày), source (manual, focus, minimal, freeze, skip), minutes, note
  - manual/minimal/freeze/skip là đánh dấu cả ngày, mỗi ngày tối đa một loại, id "<loại>_<habitId>_<yyyy-MM-dd>"; focus là phút thật từ phiên Focus
  - Hoàn thành (giữ chuỗi) = manual, minimal, hoặc tổng phút focus ≥ minMinutesPerDay. freeze không phải hoàn thành nhưng không làm đứt chuỗi. skip (chủ động bỏ qua) vẫn tính là chưa làm
- Lịch (lib/data/habit_schedule.dart, hàm thuần, test trong test/habit_schedule_test.dart): đến hạn = trong khoảng startDate–ngày kết thúc và khớp lịch (oneTime đúng dueDate; daily mọi ngày; weekly theo thứ; weekly theo số ngày khi tuần này chưa làm đủ; monthly đúng ngày, ngày 29–31 mà tháng không có thì làm ngày cuối tháng). Ngày không có lịch là "ngày nghỉ" như ngày nghỉ phép: không đứt chuỗi, giữ điểm sức mạnh
- habitsProvider chỉ có thói quen chưa ẩn, sắp theo sortOrder; allHabitsProvider có cả thói quen đã ẩn (dùng cho Thống kê). Xoá thói quen bằng bottom sheet 2 lựa chọn: "Xoá nhưng giữ lịch sử" (archive) / "Xoá cả lịch sử" (remove)
- Báo cáo (habit_science.dart, test trong test/report_logic_test.dart): ngày hoàn hảo = có ít nhất một thói quen đến hạn và tất cả đều xong (nghỉ phép không tính, ngày không có gì đến hạn không tính); tỉ lệ = lần xong / lần phải làm (ngày đã làm luôn được tính nên không vượt 100%); gom theo kỳ: tuần → 7 cột ngày, tháng → cột 7 ngày, 6 tháng / năm → cột tháng, tất cả → cột tháng (quá 12 tháng thì cột năm).
- Habit tracker khoa học (lib/data/habit_science.dart, hàm thuần, test trong test/habit_science_test.dart): điểm sức mạnh `điểm = điểm × (1 − α) + α × done`, α = 1 − 0.05^(1/66) (done: manual 1, minimal 0.5, focus phút/min tối đa 1; freeze giữ điểm; hôm nay chỉ cộng không trừ); mỗi tuần T2–CN tối đa 1 ngày freeze; nhắc "Đừng bỏ 2 lần liên tiếp" khi hôm qua bỏ; Hành trình 66 ngày với huy hiệu 7/21/40/66.
- Session: habitId, start, end, plannedMinutes, focusedSeconds, distractionCount, awaySeconds, selfRating, note
- Reel: id, assetPath, title, tags (motivation type), lengthSec, context (start, distracted), pinFirst (danh sách context, mặc định rỗng)
  - 1.3 Ghim reel: reel có pinFirst chứa context hiện tại luôn đứng đầu, bỏ qua điểm và luật "vừa xem gần nhất"; các reel còn lại xếp theo điểm, tổng tối đa 3. Hiện r6 "Get back to work!" ghim cho "distracted", áp dụng cho mọi đường mở Reels sau xao nhãng.
- Event: type (reel_watched, intervention_shown, chose_study, chose_reel, chose_break, session_distracted), time, meta
  - reel_watched: meta gồm reelId, secondsWatched, completed, startedFocus
  - session_distracted: meta gồm awaySeconds, distractionIndex
  - reel_liked, reel_unliked, reel_commented, reel_shared (1.4): meta gồm reelId
- ReelReaction (box reel_reactions, id = reelId): reelId, liked, likedAt. Bỏ thích giữ bản ghi với liked = false.
- ReelComment (box reel_comments): id, reelId, text, createdAt, updatedAt, deleted (xoá mềm), author (null = của người dùng, "Người dùng mẫu" cho dữ liệu mẫu). updatedAt/deleted có sẵn để sau này đồng bộ Firebase theo luật "bản mới hơn thắng".
- Đề xuất reel (1.3) thêm luật +1 điểm nếu reel có tag trùng với tag của một reel đã thích (ReelRecommender.score, tham số likedTags).
  - intervention_shown: meta gồm packageName, appLabel, waitSeconds
  - chose_break: meta gồm minutes
- Danh sách app cần nhắc (2.1): danh sách packageName, là bản ghi id `blocked_apps` ({packages: [...]}) trong box `profile`; chưa có thì dùng danh sách mặc định trong BlockedAppsRepository.
- UserProfile là bản ghi id `profile` trong box `profile`. Cờ đã qua onboarding (`onboarding_done`), cấp đã chúc mừng (`celebrated_level`) và đã chọn dùng thử (`guest_mode`, F3) nằm trong box `device` (riêng của máy, không đồng bộ). Trước F2 các khoá này nằm trong box profile (`user`, `blocked_packages`, ...); HiveBoxes.migrate() tự chuyển khi mở app.

## Thống kê và dữ liệu mẫu (8.2)
- Màn Thống kê mở từ Cài đặt. Phần tính nằm ở lib/services/focus_stats.dart (hàm thuần, có unit test), màn hình chỉ hiển thị.
  - Phút tập trung 7 ngày gần nhất: cộng focusedSeconds của Session theo ngày bắt đầu; biểu đồ cột vẽ bằng widget. Kèm số phiên và số ngày hoàn thành thói quen (từ HabitLog).
  - Reset break: số intervention_shown, tỉ lệ chose_study / chose_reel / chose_break trên tổng số lần đã chọn. Chỉ tính lựa chọn trên màn can thiệp, không tính sheet nhắc trong app (3.3).
  - Reels: số reel_watched và tỉ lệ có startedFocus; dòng "Reel đã thích" (số ReelReaction có liked). Thời gian quay lại: trung bình awaySeconds của session_distracted.
- "Tạo dữ liệu mẫu" (lib/data/mock_data.dart) dùng id cố định nên bấm nhiều lần không trùng. 1 mục tiêu có câu bản sắc, 7 thói quen đủ 7 màu, đủ Sáng/Chiều/Tối (và 1 thói quen "lúc nào cũng được"), có hằng tuần theo thứ (Chạy bộ T2, T4, T6), hằng tuần theo số ngày (Thiền 5 ngày/tuần) và 1 việc một lần hạn hôm nay; lịch sử 120 ngày có ngày bỏ, bỏ qua (skip), bản 2 phút, nghỉ phép (các ngày nghỉ phép cách nhau ≥ 7 ngày để luôn khác tuần dù hôm nay là thứ mấy); "Ôn bài" đủ 66 ngày (đủ 4 huy hiệu), "Đọc sách" bỏ hôm qua để hiện lời nhắc. sortOrder của thói quen mẫu bắt đầu từ 1 để thói quen tạo lúc onboarding (sortOrder 0) đứng đầu và được Focus chọn sẵn. Ngày thứ 6 trước hôm nay không thói quen nào được làm nên streak chung là 5. Hôm nay để trống (chỉ có "Làm bài tập" 10/30 phút) để demo xong một phiên thì streak tăng từ 5 lên 6. Có 5 phiên học, 8 lượt xem reel, thích r1 và r3, 4 bình luận của "Người dùng mẫu" (r1, r3, r5), 6 lần chặn kèm lựa chọn, 7 lần xao nhãng; mọi lượt xem reel mẫu đều cũ hơn 24 giờ để không làm lệch thứ tự đề xuất lúc demo.

## Firebase (F1)
- Project ID: **disgret-qs8m** (tên hiển thị DisGret, gói Spark miễn phí, chủ project: tài khoản Google của Khang). Console: https://console.firebase.google.com/project/disgret-qs8m/overview
- Firestore: database `(default)`, bản Standard, đặt ở `asia-southeast1` (Singapore). Đăng nhập: đã bật Email/Password (chưa có màn đăng nhập trong app).
- App đã đăng ký: Android `com.nhom.focus.focus_app` và web. Cấu hình nằm trong `lib/firebase_options.dart` và `android/app/google-services.json` (sinh bằng flutterfire, đã commit; đây là cấu hình công khai, không phải mật khẩu, bảo mật nằm ở rules).
- Gói: firebase_core, firebase_auth, cloud_firestore. Gradle có plugin `com.google.gms.google-services` (flutterfire tự thêm).
- Khởi tạo: `lib/services/firebase_setup.dart` (`FirebaseSetup.init()` gọi trong main.dart sau khi mở Hive), bọc try/catch và chờ tối đa 5 giây; lỗi hay không có mạng thì app vẫn chạy bằng Hive. Kiểm tra `FirebaseSetup.isReady` trước khi dùng Firebase. Test không gọi main.dart nên không cần Firebase.
- Rules (`firestore.rules`, khai báo trong `firebase.json`): chỉ chủ tài khoản đọc/ghi `users/{uid}/**`, còn lại chặn hết. Sửa rules xong thì deploy: `firebase deploy --only firestore:rules --project disgret-qs8m`.
- Các lệnh đã dùng để cài:
  - `npm install -g firebase-tools`, `dart pub global activate flutterfire_cli` (thêm `%LOCALAPPDATA%\Pub\Cache\bin` vào PATH người dùng)
  - `firebase login`, `firebase projects:create disgret-qs8m --display-name "DisGret"` (lần đầu phải chấp nhận điều khoản Google Cloud trên console)
  - Firestore tạo trên Firebase Console (lệnh `firebase firestore:databases:create` báo API chưa bật)
  - `flutter pub add firebase_core firebase_auth cloud_firestore`
  - `flutterfire configure --project=disgret-qs8m --platforms=android,web --android-package-name=com.nhom.focus.focus_app --yes`
  - `firebase deploy --only firestore:rules --project disgret-qs8m`
- Thành viên khác trong nhóm:
  - Chỉ chạy app: `git pull` rồi `flutter pub get`, `flutter run`. Không cần cài gì thêm vì file cấu hình đã có trong repo.
  - Cần quản lý Firebase (deploy rules, xem dữ liệu, cấu hình lại): nhờ Khang thêm email vào project (Console → Project settings → Users and permissions), rồi cài Node.js, `npm install -g firebase-tools`, `dart pub global activate flutterfire_cli`, chạy `firebase login`.
  - Thêm nền tảng (ví dụ iOS trên Mac): `flutterfire configure --project=disgret-qs8m --platforms=android,ios,web`, rồi commit lại `lib/firebase_options.dart` và file cấu hình mới.

## Tài khoản + đồng bộ (F2)
- Đăng nhập (lib/services/auth_service.dart): tên đăng nhập 3–20 ký tự [a-z0-9_.] (tự chuyển chữ thường, bỏ khoảng trắng), app đổi thành email ẩn `<ten>@disgret.app`; mật khẩu ≥ 6 ký tự. Hàm thuần trong `AuthRules` (normalizeUsername, usernameError, passwordError, emailFor, messageForCode đổi mã FirebaseAuthException sang tiếng Việt). displayName = tên đăng nhập. FirebaseSetup.isReady = false thì coi như chưa đăng nhập, báo "Không kết nối được máy chủ".
- Provider (lib/providers/account_providers.dart): authStateProvider (User?, theo `userChanges()`), currentUsernameProvider, syncStatusProvider (SyncState: status offline / syncing / synced / error, lastSyncedAt, error), syncServiceProvider, syncControllerProvider (DisGretApp theo dõi: đăng nhập thì start, đăng xuất thì stop), accountActionsProvider (signIn, signUp, signOut).
- Lưu trữ (lib/data/local_store.dart): mỗi bản ghi đồng bộ là Map trong Hive có thêm `updatedAtMs` (millisecondsSinceEpoch, UTC) và `deleted`. Các trường này do LocalStore / HiveRepository quản lý, model không phải khai báo (riêng ReelComment có sẵn `deleted` cùng ý nghĩa; `updatedAt` dạng ISO của nó là trường riêng của model). HiveRepository: save() tự gán updatedAtMs; delete() là xoá mềm; getAll()/getById() bỏ qua bản đã xoá; getAllRaw(), applyRemote() (ghi không kích hoạt đẩy lên), purgeAll() cho đồng bộ. Mỗi lần ghi từ app, `LocalStore.changes` báo (box, id) cho sync_service. Migrate lúc mở app: thiếu updatedAtMs thì gán bây giờ, thiếu deleted thì false.
- Luật gộp (lib/services/sync_merge.dart, hàm thuần, test trong test/sync_test.dart): "bản mới hơn thắng" theo updatedAtMs; bằng nhau giữ local; chỉ một bên có thì bên đó thắng; xoá mềm là bản ghi bình thường nên xoá mới hơn thì thắng, sửa sau khi xoá thì bản sửa thắng.
- Đồng bộ (lib/services/sync_service.dart): Firestore `users/{uid}/{box}/{id}`, đúng rules F1. Đăng nhập: tải toàn bộ về và gộp → đẩy bản local mới hơn (nên dữ liệu có sẵn trên máy được gộp vào tài khoản) → nghe snapshots() từng box (bỏ qua document có hasPendingWrites, tức chính máy này vừa ghi). Đẩy lên: gom thay đổi ~1 giây rồi ghi WriteBatch (tối đa 400 thao tác/batch); mất mạng thì Firestore giữ trong cache và tự đẩy khi có mạng. Bản từ mây về thắng thì ghi xuống Hive và gọi reloadLocalData() để giao diện tải lại. Không bao giờ xoá thật document trên mây.
- Đăng xuất (hỏi xác nhận): đẩy nốt thay đổi (chờ tối đa 5 giây) → dừng nghe → xoá thật mọi box (kể cả box device) → đăng xuất Firebase. Máy quay về như mới cài (vào onboarding), không tạo hồ sơ mặc định: nếu tạo hồ sơ mới thì updatedAtMs của nó mới hơn, lần đăng nhập sau sẽ ghi đè hồ sơ trên mây.
- Xoá toàn bộ dữ liệu khi đã đăng nhập: xoá mềm mọi bản ghi (AppDataActions.clearAll(syncDeletion: true)) để đồng bộ lên mây, hộp thoại ghi rõ "sẽ xoá trên mọi thiết bị". Chưa đăng nhập thì xoá thật như cũ. "Tạo dữ liệu mẫu" ghi qua repository nên tự đồng bộ.
- Box ĐỒNG BỘ (HiveBoxes.synced): profile (UserProfile + blocked_apps), goals, habits, habit_logs, sessions, events, reel_reactions, reel_comments.
- KHÔNG đồng bộ: box device (onboarding_done, celebrated_level, guest_mode), reel gốc (assets/reels/reels.json), trạng thái phiên Focus đang chạy (chỉ nằm trong bộ nhớ, Session chỉ được lưu khi phiên kết thúc), quyền Android và FocusGuardService.
- authStateProvider trả về `AuthUser` (uid, username, createdAt) chứ không phải User của Firebase, để test dùng FakeAuthService. firebaseReadyProvider bọc FirebaseSetup.isReady để test giả lập có máy chủ. AccountActions.signIn / signUp chờ lượt đồng bộ đầu tiên (SyncService.start trả về cùng một Future nếu gọi lại với cùng uid, tối đa 20 giây); signIn trả về true nếu tài khoản đã làm quiz (khi đó đánh dấu onboarding xong trên máy); signUp trả về true nếu có dữ liệu trên máy được gộp lên. SyncService.resync() cho nút "Đồng bộ ngay".

## Màn chào, đăng nhập, đăng ký, hồ sơ (F3)
- Route mới: `/welcome` (lib/screens/auth/welcome_screen.dart), `/login` (login_screen.dart), `/signup` (signup_flow.dart), `/profile` (lib/screens/profile_screen.dart). Phần dùng chung của màn đăng nhập/đăng ký: lib/screens/auth/auth_widgets.dart (AuthPage, UsernameField tự chữ thường + bỏ khoảng trắng + bàn phím không tự viết hoa/sửa, PasswordField có ẩn/hiện, AuthErrorText chữ đỏ colorScheme.error, AuthPrimaryButton mờ khi chưa đủ, vòng xoay khi đang xử lý). Avatar: lib/widgets/user_avatar.dart. Kích thước trong AppAuth (app_theme.dart).
- Router redirect (app_router.dart, chạy lại mỗi khi đăng nhập/đăng xuất nhờ refreshListenable):
  1. Chưa đăng nhập, chưa guestMode và chưa qua onboarding → /welcome (chỉ cho ở /welcome, /login, /signup).
  2. Đang ở /login hoặc /signup thì không đẩy đi (các màn này tự chuyển khi xong: màn chờ tải dữ liệu, bước Chào mừng).
  3. Chưa qua onboarding → /onboarding (quiz động lực cũ chạy SAU khi đăng ký hoặc chọn dùng thử).
  4. Đã qua onboarding mà ở /onboarding hoặc /welcome → /home.
  - "Đã qua onboarding" cũng tính là đã qua màn chào, nên người dùng cũ (và test gọi completeOnboarding) vào thẳng Trang chủ. HiveBoxes.migrate() bật guest_mode cho máy đã qua onboarding từ trước F3. resetOnboarding ("Xem lại màn giới thiệu") bật guest_mode để không bị đưa về màn chào.
  - Từ màn chào mở /login, /signup bằng `go` (không push): đăng nhập xong router chạy lại redirect theo đường dẫn gốc, nếu gốc vẫn là /welcome thì sẽ bị đẩy sang onboarding giữa chừng. Nút quay lại (AppBar và Back hệ thống) dùng authBack(): pop được thì pop (mở từ Hồ sơ), không thì về /welcome.
- Màn chào: logo + DisGret + khẩu hiệu; nút "Đăng nhập", "Tạo tài khoản mới", chữ "Dùng thử không cần tài khoản" (hộp thoại "Dữ liệu chỉ lưu trên máy này…" → setGuestMode(true) → quiz). Không có máy chủ (firebaseReadyProvider = false) thì bấm Đăng nhập/Đăng ký hiện "Không kết nối được máy chủ" và gợi ý dùng thử.
- Đăng nhập: lỗi dưới ô (không hộp thoại), "Quên mật khẩu?" mở bottom sheet giải thích (tài khoản không gắn email nên không lấy lại tự động được), "Chưa có tài khoản? Đăng ký". Firebase nhận đăng nhập thì đổi sang màn chờ "Đang tải dữ liệu của bạn…" tới khi gộp xong rồi vào /home.
- Đăng ký 3 bước, thanh tiến độ mảnh: (1) tên có tiền tố @, kiểm tra ngay khi gõ (tick màu tertiary / lỗi đỏ); (2) mật khẩu, điều kiện "≥ 6 ký tự" (bắt buộc) và "có chữ và số" (khuyến nghị), nhập lại phải khớp, ghi chú chưa hỗ trợ lấy lại mật khẩu; tên đã có người dùng (AuthFailure.code = email-already-in-use) thì quay về bước 1 báo lỗi; (3) "Chào mừng @ten!" + avatar chữ cái lớn, "Bắt đầu" → /home (router đưa vào quiz nếu chưa làm). Dùng thử có dữ liệu thì báo "Đã lưu dữ liệu của bạn vào tài khoản".
- Hồ sơ (mở bằng avatar tròn trên AppBar Trang chủ, thay icon Cài đặt cũ; avatar có chấm đám mây trạng thái đồng bộ, ẩn khi dùng thử): đã đăng nhập thì avatar chữ cái (nền colorScheme.primary), @tên, ngày tham gia, 3 số liệu (Streak dài nhất = longestStreak lớn nhất của mọi thói quen kể cả đã ẩn, Phiên tập trung = số Session, Thói quen = số thói quen đang có), thẻ đồng bộ + "Đồng bộ ngay", dòng Cài đặt, Đăng xuất (xác nhận "Dữ liệu trên máy này sẽ được xoá, dữ liệu vẫn còn trong tài khoản" → về /welcome, guest_mode tắt vì box device bị xoá). Dùng thử: avatar xám, "Bạn đang dùng thử", thẻ "Tạo tài khoản để lưu dữ liệu và dùng trên nhiều thiết bị" với nút Tạo tài khoản / Đăng nhập (push từ /home).
- Cài đặt không còn form đăng nhập; dòng "Tài khoản" dẫn tới /profile. Cài đặt mở từ Hồ sơ (test dùng openSettingsFromHome trong test_helpers.dart).
- Test: test/auth_screens_test.dart dùng FakeAuthService + FakeSyncService (fakeAccountOverrides trong test_helpers.dart, truyền qua `pumpApp(overrides: …)`), không gọi Firebase.

## MethodChannel focus/native
Phần Kotlin nằm trong android/app/src/main/kotlin/com/nhom/focus/focus_app/. Phía Flutter mọi lời gọi đi qua lib/services/native_bridge.dart; trên web các hàm này không gọi gì và trả về giá trị mặc định.

### Flutter gọi xuống Kotlin

| Hàm | Tham số | Trả về | Việc làm |
|---|---|---|---|
| nativeReady | | | Flutter đã sẵn sàng nhận onNativeAction; Kotlin gửi nốt các hành động đang giữ |
| hasUsageAccess | | bool | 7.1 Đã có quyền xem app đang dùng chưa |
| openUsageAccessSettings | | | 7.1 Mở trang cấp quyền đó trong Cài đặt của máy |
| hasOverlayPermission | | bool | 7.1 Đã có quyền hiện đè lên app khác chưa |
| openOverlaySettings | | | 7.1 Mở trang cấp quyền đó trong Cài đặt của máy |
| hasNotificationPermission | | bool | 7.1 Đã cho phép thông báo chưa |
| requestNotificationPermission | | | 7.1 Hiện hộp thoại xin quyền; đã từ chối hẳn thì mở Cài đặt của máy |
| getLaunchableApps | | danh sách {packageName, name, icon (PNG)} | 2.1 Các app có biểu tượng ngoài màn hình chính, trừ DisGret và launcher |
| startGuard | blockedPackages: danh sách packageName; timeScale: hệ số chế độ demo | bool (có bật được không) | 7.2 Bật FocusGuardService, hoặc đổi danh sách chặn nếu đang chạy |
| stopGuard | | | 7.2 Dừng FocusGuardService |
| startBreak | minutes | bool (service có đang chạy không) | 2.4 Chuyển service sang chế độ nghỉ, dùng cho "Nghỉ 5 phút" trên sheet nhắc |
| endBreak | | | 2.4 Người dùng bấm "Tiếp tục" trước giờ: service về chế độ chặn |
| showIntervention | appName: tên app hiện trên màn | | 2.3 Mở ngay InterventionActivity ở chế độ thử (đủ 3 lựa chọn, không ghi sự kiện, không tính giờ nghỉ) |
| drainEvents | | chuỗi JSON: danh sách {type, time (mili giây), meta} | 8.2 Trả về rồi xoá hàng đợi sự kiện; Flutter gọi khi mở app và mỗi khi app quay lại foreground |

### Kotlin gửi lên Flutter: sự kiện onNativeAction
Tham số: action, và minutes với break_started. Flutter chưa sẵn sàng thì Kotlin giữ lại, gửi sau khi nhận nativeReady.

| action | Gửi khi | Flutter làm gì |
|---|---|---|
| intervention_shown | Màn chặn vừa mở | Đếm số lần chặn; lần rời app này không nhắc thêm khi quay lại |
| resume_focus | Bấm "Quay lại học" hoặc Back trên màn chặn (qua Intent) | Về màn Focus. Lần xao nhãng vẫn được đếm khi app hiện lại |
| open_reels_distracted | Bấm "Xem 1 reel động lực" (qua Intent) | Mở Reels với context distracted |
| break_started | Chọn số phút nghỉ trên màn chặn (đi thẳng qua kênh, không qua Intent vì DisGret không mở lên) | Tạm dừng phiên |
| break_ended | Hết giờ nghỉ (đi thẳng qua kênh), và khi bấm thông báo hết giờ (qua Intent) | Phiên chạy tiếp, về màn Focus |

MainActivity đọc extra `native_action` trong cả onCreate và onNewIntent, chỉ nhận các hành động đi qua Intent ở bảng trên vì Activity này mở được từ app khác.

### Quy tắc
- Bật được theo dõi (startGuard) cần quyền xem app đang dùng và quyền hiện đè. Quyền thông báo không bắt buộc: thiếu thì vẫn chặn được, chỉ không thấy các thông báo.
- Service chạy suốt phiên và giữ số lần chặn. Thời gian chờ ở màn chặn: lần 1 là 10 giây, mỗi lần sau +5 giây, tối đa 30 giây.
- Ở chế độ chặn, app bị chặn đang ở trên cùng mà màn chặn không hiện thì mở lại, vì có app tự mở thêm màn của nó đè lên màn chặn. Cùng một lần mở app (cùng app, trong vòng 5 giây) chỉ đếm 1 lần.
- Đang nghỉ thì không chặn app nào. Hết giờ mà còn ở trong app bị chặn thì màn chặn hiện lại ngay. Chế độ demo: đồng hồ phiên và giờ nghỉ chạy nhanh gấp 3 lần (1 phút = 20 giây, hằng số FocusSessionTimer.demoTimeScale), thời gian chờ ở màn chặn thì không. Không tăng lên 6 lần: thời gian ở ngoài app vẫn bị trừ vào phiên, nên phiên "Bắt đầu 5 phút" phải đủ 100 giây cho 3 lần chặn (chờ 10 + 15 + 20 giây) trong kịch bản demo ở README.md.
- "Thử màn can thiệp" không ghi sự kiện, không tăng thời gian chờ, không bắt đầu giờ nghỉ thật.
- Các file Kotlin: NativeChannel (nhận lời gọi), NativeActions (gửi hành động lên Flutter), EventQueue (8.2), AppPermissions (7.1), InstalledApps (2.1), FocusGuardService (7.2, 2.2, 2.4), InterventionActivity (2.3), MainActivity (mở kênh, đọc hành động trong Intent, dừng service khi Activity mất đi).

## Quy tắc làm việc
- Code phải chạy được sau mỗi bước. Sau khi sửa, chạy `flutter analyze` và sửa hết lỗi.
- Định dạng bằng `dart format lib test` (độ rộng 100, đặt trong analysis_options.yaml).
- README.md có kịch bản demo và bảng ánh xạ mã sơ đồ phân rã → file; thêm file hay đổi luồng demo thì cập nhật README.
- Ưu tiên code đơn giản, dễ giải thích khi báo cáo, hơn là code tối ưu.
