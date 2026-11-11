# Focus App – MVP môn Tư Duy Tính Toán

App giúp sinh viên bắt đầu học và quay lại tập trung sau khi bị xao nhãng.
Vòng chính: Habit tracker (mục tiêu) → Anti-reel reels (động lực) → Focus mode (học) → tổng kết → streak.
Nhánh phụ: đang học mà mở TikTok → Reset break (màn can thiệp) → quay lại học / xem reel / nghỉ có hẹn giờ.

## Ràng buộc MVP
- Chỉ Android. Chỉ lưu local bằng Hive. KHÔNG dùng Firebase, KHÔNG làm đăng nhập.
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
- Bảng màu thương hiệu (từ logo):
  - Xanh dương đậm (primary): #0A2A6B
  - Trắng: #FFFFFF
  - Cyan nhấn (accent): #22D3EE
  - Teal (cyan đậm, dùng cho chữ/link trên nền trắng vì cyan nhạt khó đọc): #0891B2
- Nền sáng: nền #FFFFFF, bề mặt thẻ #F4F7FC, chữ chính #0A2A6B, chữ phụ #5B6B8C, đường kẻ mảnh #E0E4EC.
- Chế độ tối: nền #07142F, bề mặt #0F2350, chữ #F4F7FC, chữ phụ #9FB0CF; accent vẫn #22D3EE.
- Gradient nhấn: #0A2A6B → #0891B2 → #22D3EE. Chỉ dùng cho điểm nhấn: nút "Bắt đầu", vòng streak, viền avatar, thanh tiến độ. Phần còn lại giữ nền trắng sạch sẽ.
- Nút chính: nền #0A2A6B chữ trắng; nút nổi bật (Bắt đầu): gradient. Link và trạng thái đang chọn: #0891B2.
- Logo: assets/branding/logo_tam.png (bản tạm 512×512, cắt từ ảnh chụp; sẽ thay bằng file gốc cùng tên khi nhóm có). Hiện trên màn onboarding và AppBar trang chủ.
- Icon app và màn khởi động: tạo bằng flutter_launcher_icons và flutter_native_splash (cấu hình cuối pubspec.yaml), nền #0A2A6B. assets/launcher/logo_foreground.png là logo có khoảng đệm (chiếm 72% khung) cho icon adaptive và màn khởi động Android 12+, vì launcher cắt icon theo hình tròn; file này không đóng gói vào app. Đổi logo thì chạy lại `dart run flutter_launcher_icons` và `dart run flutter_native_splash:create`.
- Font: Be Vietnam Pro (google_fonts), hỗ trợ tiếng Việt tốt. Tiêu đề đậm 600–700, nội dung 400. File .ttf (400, 500, 600, 700) và giấy phép OFL nằm trong assets/fonts/; main.dart tắt `GoogleFonts.config.allowRuntimeFetching` nên không cần mạng. Dùng độ đậm mới thì phải thêm file .ttf tương ứng.
- Bo góc 12 cho thẻ, 999 cho nút dạng viên thuốc. Bóng đổ rất nhẹ hoặc không có; phân tách bằng đường kẻ mảnh.
- Icon nét mảnh (outline), dùng icon Material Symbols rounded.
- Màn Reels: vuốt dọc, video hiện trọn vẹn không bị cắt (co vừa khung), phía sau là chính video đó làm mờ (tắt bằng `AppReels.blurBackground`; trên web nền chỉ là màu đen). Chữ và nút nổi ở đáy, có lớp mờ gradient đen để chữ dễ đọc.
- Thanh điều hướng dưới cùng 4 tab: Trang chủ, Reels, Focus, Thói quen.
- TẤT CẢ màu, font, bo góc, khoảng cách đặt trong MỘT file lib/theme/app_theme.dart (kèm class AppColors, AppSpacing, AppRadius). Màn hình không được viết mã màu cứng, phải lấy từ theme, để sau này đổi giao diện chỉ cần sửa một chỗ.
- Riêng màn can thiệp (2.3) viết bằng Kotlin nên không đọc được file trên: màu của nó nằm trong android/app/src/main/res/values/colors.xml. Đổi màu thương hiệu thì phải sửa cả hai nơi.

## Mô hình dữ liệu (6.2)
- UserProfile: motivationTypes (tiền bạc, gia đình, sự nghiệp, chứng minh bản thân, tự do), preferredReelLength, demoMode
- Goal: title, reason; Habit: goalId, name, minMinutesPerDay
- HabitLog: habitId, date (chỉ ngày), source (manual, focus), minutes, note
- Session: habitId, start, end, plannedMinutes, focusedSeconds, distractionCount, awaySeconds, selfRating, note
- Reel: id, assetPath, title, tags (motivation type), lengthSec, context (start, distracted), pinFirst (danh sách context, mặc định rỗng)
  - 1.3 Ghim reel: reel có pinFirst chứa context hiện tại luôn đứng đầu, bỏ qua điểm và luật "vừa xem gần nhất"; các reel còn lại xếp theo điểm, tổng tối đa 3. Hiện r6 "Get back to work!" ghim cho "distracted", áp dụng cho mọi đường mở Reels sau xao nhãng.
- Event: type (reel_watched, intervention_shown, chose_study, chose_reel, chose_break, session_distracted), time, meta
  - reel_watched: meta gồm reelId, secondsWatched, completed, startedFocus
  - session_distracted: meta gồm awaySeconds, distractionIndex
  - intervention_shown: meta gồm packageName, appLabel, waitSeconds
  - chose_break: meta gồm minutes
- Danh sách app cần nhắc (2.1): danh sách packageName, lưu trong box `profile` với khóa `blocked_packages`; chưa có thì dùng danh sách mặc định trong BlockedAppsRepository.

## Thống kê và dữ liệu mẫu (8.2)
- Màn Thống kê mở từ Cài đặt. Phần tính nằm ở lib/services/focus_stats.dart (hàm thuần, có unit test), màn hình chỉ hiển thị.
  - Phút tập trung 7 ngày gần nhất: cộng focusedSeconds của Session theo ngày bắt đầu; biểu đồ cột vẽ bằng widget. Kèm số phiên và số ngày hoàn thành thói quen (từ HabitLog).
  - Reset break: số intervention_shown, tỉ lệ chose_study / chose_reel / chose_break trên tổng số lần đã chọn. Chỉ tính lựa chọn trên màn can thiệp, không tính sheet nhắc trong app (3.3).
  - Reels: số reel_watched và tỉ lệ có startedFocus. Thời gian quay lại: trung bình awaySeconds của session_distracted.
- "Tạo dữ liệu mẫu" (lib/data/mock_data.dart) dùng id cố định nên bấm nhiều lần không trùng. Hôm nay để trống (chỉ có "Làm bài tập" 10/30 phút) để demo xong một phiên thì streak tăng từ 5 lên 6. Có 5 phiên học, 8 lượt xem reel, 6 lần chặn kèm lựa chọn, 7 lần xao nhãng; mọi lượt xem reel mẫu đều cũ hơn 24 giờ để không làm lệch thứ tự đề xuất lúc demo.

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
