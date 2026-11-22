# Native Bridge: MethodChannel `focus/native`

> Moved verbatim from the original `CLAUDE.md` (section "MethodChannel focus/native") on 2026-11-22 so that `CLAUDE.md` and
> `AGENTS.md` stay short. The text describes the app **before** features 001 and 002 (four tabs,
> Reels feed with likes/comments/share); those features update it. It is written in Vietnamese;
> translate a section to English when you substantially edit it (Constitution: docs in English).

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
| resume_focus | Bấm "Quay lại học" hoặc Back trên màn chặn (qua Intent) | Về màn phiên học (`/focus`). Lần xao nhãng vẫn được đếm khi app hiện lại |
| open_reels_distracted | Bấm "Xem 1 reel động lực" (qua Intent) | Mở bước động lực `/motivation?context=distracted` (không có phiên thì router về `/today`) |
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
