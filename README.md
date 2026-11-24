# DisGret

App Android giúp sinh viên **bắt đầu học** và **quay lại tập trung** sau khi bị xao nhãng.
MVP môn Tư Duy Tính Toán. Chạy hoàn toàn offline: dữ liệu lưu trên máy bằng Hive, không cần
đăng nhập, không có server.

Quy ước code nằm trong [AGENTS.md](AGENTS.md); màu sắc, mô hình dữ liệu và giao tiếp với phần Kotlin nằm trong [docs/architecture/](docs/architecture/).

## App làm gì

| Tính năng | Người dùng thấy gì |
|---|---|
| **Thói quen** (Habit tracker) | Đặt mục tiêu kèm câu bản sắc "Tôi là người…". Tạo thói quen lặp lại (hằng ngày, hằng tuần theo số ngày hoặc thứ, hằng tháng) hoặc việc một lần, chọn icon/emoji, màu, buổi trong ngày, ngày kết thúc, "Sau khi…" và phiên bản 2 phút. Chạm thẻ để đánh dấu xong, giữ lâu để làm bản 2 phút hoặc nghỉ phép. Mỗi thói quen có điểm sức mạnh 0–100%; vòng streak nhỏ ở **Hôm nay** đếm số ngày liên tiếp. |
| **Hôm nay** (màn đầu tiên) | Chỉ trả lời "bây giờ học gì, trong bao lâu": mục tiêu, thói quen tiếp theo, số phút, streak nhỏ và **một** nút **Bắt đầu**. Đổi thói quen hoặc số phút cho phiên tới bằng "Đổi thói quen hoặc thời lượng". |
| **Động lực** (anti-reel) | Bấm **Bắt đầu** thì xem tối đa 3 reel động lực hợp với hồ sơ của mình (làm quiz lúc mở app lần đầu). Không vuốt, không thích, không bình luận: mỗi reel phát một lần rồi dừng ở thẻ kết thúc với **Bắt đầu N phút**, **Chỉ 5 phút thôi** và **Tiếp** (nếu còn reel). **Bỏ qua** để vào học ngay. Sau xao nhãng chỉ xem đúng 1 reel rồi **Quay lại học** ([ADR-0003](docs/decisions/0003-anti-reel-bounded-dose.md)). |
| **Focus** (phiên học) | Đồng hồ đếm ngược toàn màn hình. Rời app giữa chừng thì bị tính một lần xao nhãng; ở các tab, dải "phiên đang chạy" phía trên thanh tab đưa về phiên bằng 1 chạm. Hết giờ hiện màn Tổng kết, lưu lại thì cộng phút vào thói quen. |
| **Reset break** | Đang học mà mở TikTok, YouTube, Chrome… thì DisGret hiện màn can thiệp: chờ vài giây rồi chọn **Quay lại học**, **Xem 1 reel động lực** hoặc **Nghỉ có chủ đích** (có hẹn giờ). |

Thanh dưới có 3 tab: **Hôm nay**, **Thói quen**, **Tiến độ**
([ADR-0002](docs/decisions/0002-three-tab-navigation-single-study-entry.md)). Tab **Tiến độ** gom
báo cáo thói quen (đoạn "Thói quen") và **thống kê phiên học** (đoạn "Phiên học") để kiểm chứng giả
thuyết trong báo cáo: phút tập trung 7 ngày, số lần Reset break chặn và tỉ lệ từng lựa chọn, tỉ lệ
reel dẫn tới bắt đầu học, thời gian trung bình để quay lại sau xao nhãng. Thành tích 9 cấp, lịch
nhiệt và Hành trình 66 ngày đã được cất đi
([ADR-0004](docs/decisions/0004-park-out-of-mvp-features.md),
[parked-features.md](docs/architecture/parked-features.md)).

## 4 tính năng nối với nhau

```text
        ┌───────────────────────┐   "Bắt đầu"    ┌───────────────────────┐
        │ HÔM NAY (4. thói quen)│ ─────────────► │ 1. ĐỘNG LỰC (reel)    │
        │ mục tiêu, streak      │                │ hoặc "Bỏ qua"         │
        └───────────────────────┘                └───────────┬───────────┘
                    ▲                                        │ "Bắt đầu N phút" / "Chỉ 5 phút thôi"
                    │ Lưu phiên: cộng phút,                  ▼
                    │ streak tăng                ┌───────────────────────┐
             ┌──────┴──────┐      hết giờ        │ 3. FOCUS              │
             │  Tổng kết   │ ◄────────────────── │ đếm giờ, đếm xao nhãng│
             └─────────────┘                     └───────────┬───────────┘
                                                             │ mở TikTok / YouTube
                                                             ▼
                                                 ┌───────────────────────┐
                    ┌─── Quay lại học ────────── │ 2. RESET BREAK        │
                    │                            │ màn can thiệp         │
                    │   ┌─ Xem 1 reel động lực ─ └───────────┬───────────┘
                    ▼   ▼                                    │ Nghỉ có chủ đích
              về FOCUS / ĐỘNG LỰC (ngữ cảnh "sau xao nhãng") ▼
                                                    nghỉ có hẹn giờ, hết giờ về FOCUS

        Mọi bước đều ghi sự kiện → tab TIẾN ĐỘ, đoạn "Phiên học" (8.2)
```

### Habit tracker có cơ sở khoa học

Phần tính nằm ở `lib/data/habit_science.dart` (hàm thuần, có unit test trong
`test/habit_science_test.dart`).

| Cơ chế | Luật | Cơ sở |
|---|---|---|
| Điểm sức mạnh 0–100% | Mỗi ngày: `điểm = điểm hôm trước × (1 − α) + α × done`, với `α = 1 − 0.05^(1/66) ≈ 0.0444`. `done` = 1 nếu tick, 0.5 nếu làm bản 2 phút, `phút Focus / phút tối thiểu` (tối đa 1) nếu học bằng Focus. Ngày nghỉ phép giữ nguyên điểm; hôm nay chưa làm thì chưa bị trừ. | Làm đều 66 ngày thì đạt 95%: 66 ngày là thời gian trung bình để một hành vi thành tự động (Lally và cộng sự, 2010). |
| Ngày nghỉ phép | Mỗi tuần (T2–CN) tối đa 1 ngày, không làm đứt chuỗi nhưng cũng không cộng vào chuỗi. | Lỡ một ngày không ảnh hưởng đáng kể tới việc hình thành thói quen (Lally, 2010); cho nghỉ có kế hoạch để tránh tâm lý "hỏng rồi, bỏ luôn". |
| Không bỏ 2 lần liên tiếp | Hôm qua bỏ thì thẻ hôm nay nhắc "Đừng bỏ 2 lần liên tiếp – làm bản 2 phút nhé". | Quy tắc "never miss twice" và quy tắc 2 phút (James Clear, *Atomic Habits*). |
| Hành trình 66 ngày | Tổng số ngày hoàn thành (không cần liên tiếp), huy hiệu 7 "Khởi động", 21 "Bền bỉ", 40 "Vững vàng", 66 "Thành thói quen". | Mốc 66 ngày của Lally (2010). |
| Ý định thực hiện | Mỗi thói quen ghi "Sau khi…" và "Tại…". | Implementation intentions (Gollwitzer & Sheeran, 2006). |
| Bản sắc | Mục tiêu có câu "Tôi là người…". | Thói quen dựa trên bản sắc (James Clear, *Atomic Habits*). |

Khi mở bước động lực sau xao nhãng (từ màn can thiệp hoặc từ sheet nhắc trong app), reel
**"Get back to work!"** là reel duy nhất được chiếu vì được ghim (`pinFirst` trong
`assets/reels/reels.json`).

## Cách chạy

Cần Flutter 3.47 trở lên (Dart 3.13) và Android Studio có máy ảo Android (Pixel, API 34+, bản
có Google Play).

```bash
flutter pub get
flutter run                      # chạy trên máy ảo đang mở
flutter test                     # chạy toàn bộ test
flutter build apk --release      # tạo build/app/outputs/flutter-apk/app-release.apk
```

- Phần Hôm nay, Thói quen, Tiến độ, bước động lực và phiên học chạy được cả trên web để thử nhanh:
  `flutter run -d chrome`.
  Reset break chỉ có trên Android.
- APK release đang ký bằng khoá debug: đủ để cài lên máy ảo hay máy thật để demo, chưa đưa lên
  cửa hàng được.
- Font Be Vietnam Pro nằm sẵn trong `assets/fonts/` nên không cần mạng.
- Đổi logo: thay `assets/branding/logo_tam.png` (512×512) và `assets/launcher/logo_foreground.png`
  (bản có khoảng đệm cho icon và màn khởi động Android 12+), rồi chạy
  `dart run flutter_launcher_icons` và `dart run flutter_native_splash:create`.

## Cấp quyền trên máy ảo

Reset break cần 2 quyền bắt buộc và 1 quyền nên có:

| Quyền | Để làm gì |
|---|---|
| Xem app đang dùng (Usage access) | Biết người dùng vừa mở TikTok, YouTube… |
| Hiện trên app khác (Display over other apps) | Hiện màn can thiệp đè lên app đó |
| Thông báo (không bắt buộc) | Thông báo đang học và "Hết giờ nghỉ rồi!" |

**Cách 1, trong app:** Hôm nay → biểu tượng bánh răng (Cài đặt) → **Quyền cho Reset break** →
bấm từng dòng, bật DisGret trong trang Cài đặt của máy rồi bấm Back. Khi bấm bắt đầu học mà
thiếu quyền, app cũng hỏi.

**Cách 2, bằng lệnh** (nhanh, làm được ngay sau khi cài, trước cả khi mở app):

```bash
adb shell appops set com.nhom.focus.focus_app GET_USAGE_STATS allow
adb shell appops set com.nhom.focus.focus_app SYSTEM_ALERT_WINDOW allow
adb shell pm grant com.nhom.focus.focus_app android.permission.POST_NOTIFICATIONS
```

Danh sách app bị nhắc mặc định: TikTok, Facebook, Instagram, YouTube, Chrome. Đổi trong
Cài đặt → **Ứng dụng cần nhắc**. Muốn xem trước màn can thiệp mà không cần học: Cài đặt →
**Thử màn can thiệp**.

## Kịch bản demo (khoảng 5 phút)

### Chuẩn bị trước buổi thuyết trình

1. Gỡ DisGret cũ trên máy ảo, kéo thả `build/app/outputs/flutter-apk/app-release.apk` vào cửa sổ
   máy ảo để cài.
2. Cấp 3 quyền bằng 3 lệnh ở trên.
3. Mở YouTube một lần, bỏ qua các màn chào và đăng nhập, để lúc demo YouTube vào thẳng trang chủ.
4. Bật quay màn hình làm video dự phòng: nút **…** (Extended controls) của máy ảo →
   **Record and Playback** / **Screen record** → Start.

### Trên lớp

1. **Onboarding.** Mở DisGret → 4 trang story Gret kể về app (tự lật sau 4 giây, chạm phải/trái
   để sang/lùi, **Bỏ qua** để vào thẳng câu hỏi) → chọn độ dài reel → **Tiếp tục** → trả lời 4
   câu quiz động lực trong khung suy nghĩ của Gret → chọn app hay kéo mình đi → **Tiếp tục**.
   Ở bước mục tiêu: nhập mục tiêu (ví dụ "Qua môn Tư Duy Tính Toán"), lý do, thói quen "Ôn bài",
   số phút tối thiểu chọn **Tự nhập → 1** → **Vào DisGret**.
   > Vì sao 1 phút: trong phiên "5 phút" của kịch bản, thời gian ở YouTube và chờ ở màn chặn bị trừ
   > vào thời gian tập trung, nên phiên chỉ còn khoảng 1–2 phút tập trung thật. Mức tối thiểu
   > 1 phút đảm bảo cuối phiên thói quen hoàn thành và streak tăng.
2. **Cài đặt** (bánh răng ở Hôm nay): bật **Chế độ demo** (1 phút chỉ dài 20 giây), bấm
   **Tạo dữ liệu mẫu** → quay lại: **Hôm nay** có mục tiêu, câu bản sắc, thói quen tiếp theo kèm
   số phút, vòng streak **5 ngày** và đúng một nút **Bắt đầu**.
   - (Không bắt buộc) Tab **Thói quen**: 7 thẻ màu pastel, lọc **Sáng / Chiều / Tối**; chuyển
     **Theo ngày**, **Tuần** (7 ô T2–CN) và **Tổng thể** (lưới chấm 20 tuần). Giữ lâu thẻ "Ôn bài
     Tư Duy Tính Toán" → **Xem chi tiết**: lịch tháng, biểu đồ sức mạnh 60 ngày, ghi chú.
     Tab **Tiến độ** → đoạn **Thói quen**: 4 ô số liệu, biểu đồ cột và đường (đổi kỳ được), lịch %
     hoàn thành.
     Đừng đánh dấu xong thói quen nào hôm nay, nếu không streak đã lên 6 trước khi demo phiên học.
3. **Hôm nay → Bắt đầu** → bước động lực toàn màn hình (không có thanh tab): reel **1/3** phát
   một lần; vuốt không đổi reel; chạm để tạm dừng. Hết reel (khoảng 15–25 giây) thì hiện thẻ kết
   thúc: **Bắt đầu N phút**, **Chỉ 5 phút thôi**, **Tiếp**. (Không bắt buộc: **Tiếp** để xem reel
   2/3.) → **Chỉ 5 phút thôi** → màn phiên học trong biển của Gret: Gret tập trung, đồng hồ đếm
   ngược từ 05:00 (thật ra 100 giây), thỉnh thoảng một xao nhãng trôi tới và bị Gret hất văng. (Hoặc
   **Bỏ qua** bất cứ lúc nào để vào học ngay với số phút của Hôm nay.)
   - (Không bắt buộc) Bấm mũi tên quay lại → về Hôm nay, phiên vẫn chạy; dải "phiên đang chạy"
     trên thanh tab có ở cả 3 tab, chạm để về phiên. Bấm **Bắt đầu** lúc này cũng chỉ mở lại
     phiên đang chạy, không tạo phiên mới.
4. **Lần chặn 1.** Bấm Home, mở YouTube → màn can thiệp đếm ngược **10 giây** →
   **Quay lại học** → về màn phiên học, số lần xao nhãng là 1.
5. **Lần chặn 2.** Mở YouTube → chờ **15 giây** → **Xem 1 reel động lực** → bước động lực chiếu
   đúng một reel **"Get back to work!"** (1/1, không có **Bỏ qua** hay **Tiếp**; đồng hồ phiên tạm
   dừng khi xem) → **Quay lại học**.
6. **Lần chặn 3.** Mở YouTube → chờ **20 giây** → **Nghỉ có chủ đích** → **5 phút** → giờ nghỉ
   bắt đầu, YouTube không bị chặn nữa.
7. **Mở lại DisGret trước khi hết giờ nghỉ.** Màn phiên học hiện "Đang nghỉ – còn …". Chờ hết giờ
   nghỉ (100 giây, thông báo "Hết giờ nghỉ rồi!") hoặc bấm **Tiếp tục** để học tiếp ngay.
   > Đừng ở lại YouTube lúc hết giờ nghỉ: màn chặn sẽ hiện lại ngay (lần 4, chờ 25 giây) và ăn
   > hết thời gian còn lại của phiên.
8. **Hết giờ.** Phiên chạy nốt khoảng nửa phút rồi tự mở **Tổng kết**: thời gian tập trung,
   3 lần xao nhãng, Reset break đã chặn 3 lần, 1 lần nghỉ có chủ đích → chọn số sao →
   **Lưu** → hiện **"+1 ngày streak 🔥"** → **Về Hôm nay**: vòng streak lên **6 ngày**.
9. **Góc của Gret.** Ở **Hôm nay**, bấm nút móc áo góc phải cảnh biển (kèm số ngọc trai: 1 ngọc
   cho mỗi 5 phút tập trung) → tab **Tủ đồ**: đổi **Nơ hồng** (20 ngọc) → **Mặc** → về Hôm nay
   thấy Gret đeo nơ. Tab **Biển**: rạn san hô, biển băng, đáy biển sâu mở theo chuỗi ngày; tab
   **Linh vật**: cua **Ẩn** (300 ngọc), bạch tuộc **Mochi** "Sắp có" (bán bằng tiền thật sau).
10. **Bản đồ biển.** Tab **Thói quen** → nút bản đồ trên thanh tiêu đề: bản đồ toàn màn hình
   lướt từ toàn cảnh vào đảo có Gret. Mỗi mục tiêu là một đảo, mỗi thói quen là một ghim ("?" khi
   chưa làm ngày nào, rồi "n/66"); bóng tối tan dần quanh ghim theo số ngày đã làm. Kéo, chụm để
   phóng to, nút +/− và **Về chỗ Gret**; chạm vào đảo để xem từng điểm và mốc 7/21/40/66 ngày.
   Phiên học diễn ra ở biển của đảo đó.
11. **Tiến độ.** Tab **Tiến độ** → đoạn **Phiên học**: biểu đồ phút tập trung 7 ngày, tỉ lệ lựa
   chọn trên màn can thiệp, tỉ lệ reel dẫn tới bắt đầu học, thời gian quay lại trung bình (dữ liệu
   mẫu cộng với lượt demo vừa xong).

## Mã sơ đồ phân rã → file code

Mỗi file ghi mã thành phần ở dòng đầu. `kotlin/` là
`android/app/src/main/kotlin/com/nhom/focus/focus_app/`, `res/` là `android/app/src/main/res/`.

| Mã | Thành phần | File chính |
|---|---|---|
| 1.1 | Hồ sơ động lực (quiz) | `lib/data/motivation_quiz.dart`, `lib/screens/quiz_screen.dart`, `lib/widgets/quiz_question_view.dart`, `lib/data/models/user_profile.dart` |
| 1.2 | Kho nội dung reel | `assets/reels/reels.json`, `lib/data/models/reel.dart`, `lib/data/repositories/reel_repository.dart` |
| 1.3 | Đề xuất reel theo luật, ghim reel | `lib/services/reel_recommender.dart` |
| 1.4 | Bước động lực (route `/motivation`): liều reel có điểm dừng, thẻ kết thúc, ghi lượt xem và lượt bỏ qua | `lib/screens/motivation_screen.dart`, `lib/services/motivation_dose.dart`, `lib/widgets/reel_end_card.dart`, `lib/services/reel_watch_tracker.dart` |
| 2.1 | Danh sách app cần nhắc | `lib/screens/blocked_apps_screen.dart`, `lib/data/repositories/blocked_apps_repository.dart`, `kotlin/InstalledApps.kt` |
| 2.2 | Phát hiện mở app bị chặn | `kotlin/FocusGuardService.kt` |
| 2.3 | Màn can thiệp | `kotlin/InterventionActivity.kt`, `res/layout/activity_intervention.xml`, `res/values/strings.xml`, `res/values/colors.xml` |
| 2.4 | Nghỉ có chủ đích | `kotlin/FocusGuardService.kt`, `lib/providers/focus_session_provider.dart` |
| 3.1 | Bắt đầu phiên (một lối vào), đồng hồ, dải phiên đang chạy | `lib/services/study_starter.dart`, `lib/screens/focus_screen.dart`, `lib/services/focus_session_timer.dart`, `lib/providers/focus_session_provider.dart`, `lib/widgets/running_session_banner.dart`, `lib/widgets/minutes_picker.dart` |
| 3.2 | Phát hiện lơ là | `lib/services/focus_session_timer.dart`, `lib/providers/focus_session_provider.dart`, `lib/app.dart` |
| 3.3 | Phản hồi sau xao nhãng | `lib/widgets/focus_feedback.dart`, `lib/app.dart`, `lib/screens/motivation_screen.dart` (dừng đồng hồ khi xem động lực) |
| 3.4 | Tổng kết phiên | `lib/screens/summary_screen.dart`, `lib/data/models/session.dart`, `lib/services/time_format.dart` |
| 4.1 | Đặt mục tiêu, tạo/sửa/xoá thói quen, lịch lặp lại, chọn icon | `lib/screens/habits_screen.dart`, `lib/screens/habit_form_screen.dart`, `lib/data/habit_schedule.dart`, `lib/data/habit_icon_catalog.dart`, `lib/widgets/habit_icon_picker.dart`, `lib/widgets/habit_icon_view.dart`, `lib/screens/onboarding_screen.dart`, `lib/widgets/goal_habit_sheets.dart`, `lib/widgets/goal_form_fields.dart`, `lib/widgets/habit_form_fields.dart`, `lib/widgets/empty_goal_view.dart`, `lib/widgets/edit_delete_menu.dart`, `lib/widgets/app_dialogs.dart` |
| 4.2 | Ghi nhận, streak, điểm sức mạnh, màn chi tiết, Báo cáo (trong Tiến độ) | `lib/data/habit_progress.dart`, `lib/data/habit_science.dart`, `lib/data/repositories/habit_log_repository.dart`, `lib/widgets/habit_today_card.dart`, `lib/widgets/habit_week_card.dart`, `lib/widgets/habit_check_ring.dart`, `lib/widgets/habit_heat_map.dart`, `lib/widgets/month_calendar.dart`, `lib/screens/habit_detail_screen.dart`, `lib/screens/report_screen.dart` (`ReportView`), `lib/screens/my_habits_screen.dart`. Đã cất (ADR-0004): `lib/data/achievements.dart`, `lib/widgets/level_badge.dart`, `lib/screens/achievements_screen.dart`, `lib/widgets/habit_card.dart`, `lib/widgets/habit_journey.dart` |
| 5.1 | Khung app, 3 tab, Hôm nay, kế hoạch phiên, Tiến độ, chuỗi giao diện | `lib/main.dart`, `lib/app.dart`, `lib/router/app_router.dart`, `lib/screens/main_shell.dart`, `lib/screens/today_screen.dart`, `lib/data/session_plan.dart`, `lib/widgets/session_plan_sheet.dart`, `lib/screens/progress_screen.dart`, `lib/screens/settings_screen.dart`, `lib/providers/app_providers.dart`, `lib/l10n/app_strings.dart`, `kotlin/MainActivity.kt` |
| 5.2 | Giao diện (design system) | `lib/theme/app_theme.dart`, `lib/widgets/app_logo.dart`, `lib/widgets/gradient_pill_button.dart`, `lib/widgets/gradient_progress_bar.dart`, `lib/widgets/progress_ring.dart`, `lib/widgets/streak_ring.dart`, `assets/fonts/`, `assets/branding/`, `assets/launcher/` |
| 5.3 | Gret và biển sống: độ trong của biển, Gret trên Hôm nay, onboarding dạng story, phiên học trong biển | `lib/data/sea_clarity.dart`, `lib/data/mascot_mood.dart`, `lib/providers/sea_providers.dart`, `lib/widgets/sea/`, `lib/widgets/mascot/`, `lib/widgets/motion/`, `assets/mascot/gret/`, `lib/screens/onboarding_screen.dart`, `lib/screens/focus_screen.dart` |
| 5.4 | Góc của Gret: ngọc trai, tủ đồ, vùng biển, linh vật | `lib/data/pearls.dart`, `lib/data/gret_corner_catalog.dart`, `lib/data/mascot_species.dart`, `lib/data/repositories/gret_corner_repository.dart`, `lib/providers/gret_corner_providers.dart`, `lib/screens/gret_corner_screen.dart`, `assets/mascot/outfits/`, `assets/mascot/crab/`, `assets/mascot/octopus/` |
| 5.5 | Bản đồ biển: mỗi mục tiêu một đảo, mỗi thói quen một điểm khám phá, toàn màn hình | `lib/data/sea_map.dart`, `lib/providers/sea_map_providers.dart`, `lib/widgets/sea/sea_world.dart`, `lib/screens/sea_map_screen.dart`, `lib/screens/habits_screen.dart` |
| 6.2 | Mô hình dữ liệu, lưu trữ Hive | `lib/data/models/`, `lib/data/repositories/`, `lib/data/hive_boxes.dart`, `lib/data/date_utils.dart`, `lib/data/mock_data.dart` |
| 7.1 | Quyền | `lib/screens/reset_break_permissions_screen.dart`, `lib/widgets/reset_break_sheet.dart`, `kotlin/AppPermissions.kt` |
| 7.2 | Dịch vụ theo dõi app, cầu nối Kotlin | `kotlin/FocusGuardService.kt`, `kotlin/NativeChannel.kt`, `kotlin/NativeActions.kt`, `lib/services/native_bridge.dart` |
| 8.2 | Nhật ký sự kiện, thống kê phiên học (trong Tiến độ) | `lib/data/repositories/event_repository.dart`, `kotlin/EventQueue.kt`, `lib/services/focus_stats.dart`, `lib/screens/stats_screen.dart` (`StatsView`) |

Test nằm trong `test/`, mỗi file ứng với một phần ở trên (ví dụ `reel_recommender_test.dart` cho
1.3, `stats_test.dart` cho 8.2, `session_plan_test.dart` và `navigation_test.dart` cho 5.1).
