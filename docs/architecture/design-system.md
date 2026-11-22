# Design System (5.2)

> Moved verbatim from the original `CLAUDE.md` (section "Giao diện (5.2 Design system)") on 2026-11-22 so that `CLAUDE.md` and
> `AGENTS.md` stay short. The text describes the app **before** features 001 and 002 (four tabs,
> Reels feed with likes/comments/share); those features update it. It is written in Vietnamese;
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
