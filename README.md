# DisGret

App Android giúp sinh viên **bắt đầu học** và **quay lại tập trung** sau khi bị xao nhãng.
MVP môn Tư Duy Tính Toán. Chạy hoàn toàn offline: dữ liệu lưu trên máy bằng Hive, không cần
đăng nhập, không có server.

Quy ước code, màu sắc và giao tiếp với phần Kotlin nằm trong [CLAUDE.md](CLAUDE.md).

## App làm gì

| Tính năng | Người dùng thấy gì |
|---|---|
| **Thói quen** (Habit tracker) | Đặt mục tiêu kèm câu bản sắc "Tôi là người…". Tạo thói quen lặp lại (hằng ngày, hằng tuần theo số ngày hoặc thứ, hằng tháng) hoặc việc một lần, chọn icon/emoji, màu, buổi trong ngày, ngày kết thúc, "Sau khi…" và phiên bản 2 phút. Chạm vòng tiến độ để tick, giữ lâu để làm bản 2 phút hoặc nghỉ phép. Mỗi thói quen có điểm sức mạnh 0–100%, lịch nhiệt, Hành trình 66 ngày; vòng streak ở Trang chủ đếm số ngày liên tiếp. |
| **Reels** (anti-reel) | Trước khi học, xem 1–3 reel động lực hợp với hồ sơ của mình (làm quiz lúc mở app lần đầu), rồi bấm "Bắt đầu 5 phút". |
| **Focus** | Đồng hồ đếm ngược. Rời app giữa chừng thì bị tính một lần xao nhãng; hết giờ hiện màn Tổng kết, lưu lại thì cộng phút vào thói quen. |
| **Reset break** | Đang học mà mở TikTok, YouTube, Chrome… thì DisGret hiện màn can thiệp: chờ vài giây rồi chọn **Quay lại học**, **Xem 1 reel động lực** hoặc **Nghỉ có chủ đích** (có hẹn giờ). |

Ngoài ra: màn **Thống kê** (mở từ Cài đặt) gom số liệu để kiểm chứng giả thuyết trong báo cáo:
phút tập trung 7 ngày, số lần Reset break chặn và tỉ lệ từng lựa chọn, tỉ lệ reel dẫn tới bắt đầu
học, thời gian trung bình để quay lại sau xao nhãng.

## 4 tính năng nối với nhau

```text
        ┌───────────────────────┐   "Bắt đầu"    ┌───────────────────────┐
        │ 4. THÓI QUEN          │ ─────────────► │ 1. REELS              │
        │ mục tiêu, streak      │                │ reel động lực         │
        └───────────────────────┘                └───────────┬───────────┘
                    ▲                                        │ "Bắt đầu 5 phút"
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
              về FOCUS / REELS (ngữ cảnh "sau xao nhãng")     ▼
                                                    nghỉ có hẹn giờ, hết giờ về FOCUS

        Mọi bước đều ghi sự kiện → màn THỐNG KÊ (8.2)
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

Khi mở Reels sau xao nhãng (từ màn can thiệp hoặc từ sheet nhắc trong app), reel
**"Get back to work!"** luôn đứng đầu vì được ghim (`pinFirst` trong `assets/reels/reels.json`).

## Cách chạy

Cần Flutter 3.47 trở lên (Dart 3.13) và Android Studio có máy ảo Android (Pixel, API 34+, bản
có Google Play).

```bash
flutter pub get
flutter run                      # chạy trên máy ảo đang mở
flutter test                     # chạy toàn bộ test
flutter build apk --release      # tạo build/app/outputs/flutter-apk/app-release.apk
```

- Phần Thói quen, Reels, Focus chạy được cả trên web để thử nhanh: `flutter run -d chrome`.
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

**Cách 1, trong app:** Trang chủ → biểu tượng bánh răng (Cài đặt) → **Quyền cho Reset break** →
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

1. **Onboarding.** Mở DisGret → chọn độ dài reel → **Tiếp tục** → trả lời 4 câu quiz động lực.
   Ở bước mục tiêu: nhập mục tiêu (ví dụ "Qua môn Tư Duy Tính Toán"), lý do, thói quen "Ôn bài",
   số phút tối thiểu chọn **Tự nhập → 1** → **Vào DisGret**.
   > Vì sao 1 phút: trong phiên "5 phút" của kịch bản, thời gian ở YouTube và chờ ở màn chặn bị trừ
   > vào thời gian tập trung, nên phiên chỉ còn khoảng 1–2 phút tập trung thật. Mức tối thiểu
   > 1 phút đảm bảo cuối phiên thói quen hoàn thành và streak tăng.
2. **Cài đặt** (bánh răng ở Trang chủ): bật **Chế độ demo** (1 phút chỉ dài 20 giây), bấm
   **Tạo dữ liệu mẫu** → quay lại: Trang chủ có vòng streak **5 ngày**, câu bản sắc và điểm
   sức mạnh trung bình.
   - (Không bắt buộc) Trang chủ: thẻ "Đọc sách 10 trang" nhắc "Đừng bỏ 2 lần liên tiếp".
     Tab **Thói quen**: 7 thẻ màu pastel, lọc **Sáng / Chiều / Tối**; chuyển **Tuần** (7 ô
     T2–CN) và **Tổng thể** (lưới chấm 20 tuần). Giữ lâu thẻ "Ôn bài Tư Duy Tính Toán" →
     **Xem chi tiết**: lịch tháng, biểu đồ sức mạnh 60 ngày, đủ 4 huy hiệu (66/66 ngày), lịch 16 tuần.
     Nút **Báo cáo** trên tab Thói quen: 4 ô số liệu, biểu đồ cột và đường (đổi kỳ được), lịch %
     hoàn thành. Menu ⋮ → **Thành tích**: lưới 9 cấp theo tổng số lần hoàn thành.
     Đừng đánh dấu xong thói quen nào hôm nay, nếu không streak đã lên 6 trước khi demo phiên học.
3. **Bắt đầu** → màn Reels: xem một reel, vuốt lên xem reel khác nếu muốn →
   **Bắt đầu 5 phút** → màn Focus đếm ngược từ 05:00 (thật ra 100 giây).
4. **Lần chặn 1.** Bấm Home, mở YouTube → màn can thiệp đếm ngược **10 giây** →
   **Quay lại học** → về Focus, số lần xao nhãng là 1.
5. **Lần chặn 2.** Mở YouTube → chờ **15 giây** → **Xem 1 reel động lực** → Reels mở với
   **"Get back to work!"** đứng đầu (đồng hồ phiên tạm dừng khi xem) → **Quay lại học**.
6. **Lần chặn 3.** Mở YouTube → chờ **20 giây** → **Nghỉ có chủ đích** → **5 phút** → giờ nghỉ
   bắt đầu, YouTube không bị chặn nữa.
7. **Mở lại DisGret trước khi hết giờ nghỉ.** Focus hiện "Đang nghỉ – còn …". Chờ hết giờ nghỉ
   (100 giây, thông báo "Hết giờ nghỉ rồi!") hoặc bấm **Tiếp tục** để học tiếp ngay.
   > Đừng ở lại YouTube lúc hết giờ nghỉ: màn chặn sẽ hiện lại ngay (lần 4, chờ 25 giây) và ăn
   > hết thời gian còn lại của phiên.
8. **Hết giờ.** Phiên chạy nốt khoảng nửa phút rồi tự mở **Tổng kết**: thời gian tập trung,
   3 lần xao nhãng, Reset break đã chặn 3 lần, 1 lần nghỉ có chủ đích → chọn số sao →
   **Lưu** → hiện **"+1 ngày streak 🔥"** → **Về Trang chủ**: vòng streak lên **6 ngày**.
9. **Thống kê.** Cài đặt → **Thống kê**: biểu đồ phút tập trung 7 ngày, tỉ lệ lựa chọn trên màn
   can thiệp, tỉ lệ reel dẫn tới bắt đầu học, thời gian quay lại trung bình (dữ liệu mẫu cộng
   với lượt demo vừa xong).

## Mã sơ đồ phân rã → file code

Mỗi file ghi mã thành phần ở dòng đầu. `kotlin/` là
`android/app/src/main/kotlin/com/nhom/focus/focus_app/`, `res/` là `android/app/src/main/res/`.

| Mã | Thành phần | File chính |
|---|---|---|
| 1.1 | Hồ sơ động lực (quiz) | `lib/data/motivation_quiz.dart`, `lib/screens/quiz_screen.dart`, `lib/widgets/quiz_question_view.dart`, `lib/data/models/user_profile.dart` |
| F2 | Đăng nhập tên + mật khẩu, đồng bộ Hive ⇄ Firestore | `lib/services/auth_service.dart`, `lib/services/sync_service.dart`, `lib/services/sync_merge.dart`, `lib/data/local_store.dart`, `lib/providers/account_providers.dart`, `lib/widgets/account_section.dart` |
| F1 | Nối Firebase | `lib/services/firebase_setup.dart`, `lib/firebase_options.dart`, `android/app/google-services.json`, `firebase.json`, `firestore.rules` |
| 1.2 | Kho nội dung reel | `assets/reels/reels.json`, `lib/data/models/reel.dart`, `lib/data/repositories/reel_repository.dart` |
| 1.3 | Đề xuất reel theo luật, ghim reel | `lib/services/reel_recommender.dart` |
| 1.4 | Màn Reels, ghi lượt xem, Tim / Bình luận / Chia sẻ | `lib/screens/reels_screen.dart`, `lib/services/reel_watch_tracker.dart`, `lib/services/reel_share.dart`, `lib/widgets/reel_action_column.dart`, `lib/widgets/reel_comments_sheet.dart`, `lib/data/models/reel_reaction.dart`, `lib/data/models/reel_comment.dart`, `lib/data/repositories/reel_reaction_repository.dart`, `lib/data/repositories/reel_comment_repository.dart` |
| 2.1 | Danh sách app cần nhắc | `lib/screens/blocked_apps_screen.dart`, `lib/data/repositories/blocked_apps_repository.dart`, `kotlin/InstalledApps.kt` |
| 2.2 | Phát hiện mở app bị chặn | `kotlin/FocusGuardService.kt` |
| 2.3 | Màn can thiệp | `kotlin/InterventionActivity.kt`, `res/layout/activity_intervention.xml`, `res/values/strings.xml`, `res/values/colors.xml` |
| 2.4 | Nghỉ có chủ đích | `kotlin/FocusGuardService.kt`, `lib/providers/focus_session_provider.dart` |
| 3.1 | Thiết lập phiên, đồng hồ | `lib/screens/focus_screen.dart`, `lib/services/focus_session_timer.dart`, `lib/providers/focus_session_provider.dart`, `lib/widgets/minutes_picker.dart` |
| 3.2 | Phát hiện lơ là | `lib/services/focus_session_timer.dart`, `lib/providers/focus_session_provider.dart`, `lib/app.dart` |
| 3.3 | Phản hồi sau xao nhãng | `lib/widgets/focus_feedback.dart`, `lib/app.dart`, `lib/screens/main_shell.dart` |
| 3.4 | Tổng kết phiên | `lib/screens/summary_screen.dart`, `lib/data/models/session.dart`, `lib/services/time_format.dart` |
| 4.1 | Đặt mục tiêu, tạo/sửa/xoá thói quen, lịch lặp lại, chọn icon | `lib/screens/habits_screen.dart`, `lib/screens/habit_form_screen.dart`, `lib/data/habit_schedule.dart`, `lib/data/habit_icon_catalog.dart`, `lib/widgets/habit_icon_picker.dart`, `lib/widgets/habit_icon_view.dart`, `lib/screens/onboarding_screen.dart`, `lib/widgets/goal_habit_sheets.dart`, `lib/widgets/goal_form_fields.dart`, `lib/widgets/habit_form_fields.dart`, `lib/widgets/empty_goal_view.dart`, `lib/widgets/edit_delete_menu.dart`, `lib/widgets/app_dialogs.dart` |
| 4.2 | Ghi nhận, streak, điểm sức mạnh, lịch nhiệt, màn chi tiết, Báo cáo, Thành tích | `lib/data/habit_progress.dart`, `lib/data/habit_science.dart`, `lib/data/achievements.dart`, `lib/data/repositories/habit_log_repository.dart`, `lib/widgets/habit_today_card.dart`, `lib/widgets/habit_week_card.dart`, `lib/widgets/habit_card.dart`, `lib/widgets/habit_check_ring.dart`, `lib/widgets/habit_heat_map.dart`, `lib/widgets/month_calendar.dart`, `lib/widgets/level_badge.dart`, `lib/screens/habit_detail_screen.dart`, `lib/screens/report_screen.dart`, `lib/screens/achievements_screen.dart`, `lib/screens/my_habits_screen.dart` |
| 5.1 | Khung app, điều hướng, các màn chính | `lib/main.dart`, `lib/app.dart`, `lib/router/app_router.dart`, `lib/screens/main_shell.dart`, `lib/screens/home_screen.dart`, `lib/screens/settings_screen.dart`, `lib/providers/app_providers.dart`, `kotlin/MainActivity.kt` |
| 5.2 | Giao diện (design system) | `lib/theme/app_theme.dart`, `lib/widgets/app_logo.dart`, `lib/widgets/gradient_pill_button.dart`, `lib/widgets/gradient_progress_bar.dart`, `lib/widgets/progress_ring.dart`, `lib/widgets/streak_ring.dart`, `assets/fonts/`, `assets/branding/`, `assets/launcher/` |
| 6.2 | Mô hình dữ liệu, lưu trữ Hive | `lib/data/models/`, `lib/data/repositories/`, `lib/data/hive_boxes.dart`, `lib/data/date_utils.dart`, `lib/data/mock_data.dart` |
| 7.1 | Quyền | `lib/screens/reset_break_permissions_screen.dart`, `lib/widgets/reset_break_sheet.dart`, `kotlin/AppPermissions.kt` |
| 7.2 | Dịch vụ theo dõi app, cầu nối Kotlin | `kotlin/FocusGuardService.kt`, `kotlin/NativeChannel.kt`, `kotlin/NativeActions.kt`, `lib/services/native_bridge.dart` |
| 8.2 | Nhật ký sự kiện, Thống kê | `lib/data/repositories/event_repository.dart`, `kotlin/EventQueue.kt`, `lib/services/focus_stats.dart`, `lib/screens/stats_screen.dart` |

Test nằm trong `test/`, mỗi file ứng với một phần ở trên (ví dụ `reel_recommender_test.dart` cho
1.3, `stats_test.dart` cho 8.2).
