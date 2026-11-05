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

## Mô hình dữ liệu (6.2)
- UserProfile: motivationTypes (tiền bạc, gia đình, sự nghiệp, chứng minh bản thân, tự do), preferredReelLength
- Goal: title, reason; Habit: goalId, name, minMinutesPerDay
- Session: habitId, start, end, plannedMinutes, focusedSeconds, distractionCount, selfRating
- Reel: id, assetPath, title, tags (motivation type), lengthSec
- Event: type (reel_watched, intervention_shown, chose_study, chose_reel, chose_break), time, meta

## Quy tắc làm việc
- Code phải chạy được sau mỗi bước. Sau khi sửa, chạy `flutter analyze` và sửa hết lỗi.
- Ưu tiên code đơn giản, dễ giải thích khi báo cáo, hơn là code tối ưu.
