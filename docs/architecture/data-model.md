# Data Model (6.2) and Statistics (8.2)

> Moved verbatim from the original `CLAUDE.md` (section "Mô hình dữ liệu (6.2)", section "Thống kê và dữ liệu mẫu (8.2)") on 2026-11-22 so that `CLAUDE.md` and
> `AGENTS.md` stay short. Features 001 (three tabs, Hôm nay) and 002 (bounded motivation dose, no
> social features) have updated the parts they changed. The older text is in Vietnamese;
> translate a section to English when you substantially edit it (Constitution: docs in English).

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
  - 1.3 Ghim reel: reel có pinFirst chứa context hiện tại luôn đứng đầu, bỏ qua điểm và luật "vừa xem gần nhất"; các reel còn lại xếp theo điểm. Hiện r6 "Get back to work!" ghim cho "distracted", áp dụng cho mọi đường mở bước động lực sau xao nhãng.
  - 1.3 Playlist length (spec 002): `ReelRecommender.limitFor` = 3 for `start`, 1 for `distracted`. Score = 2 × matching motivation tags + 1 if not watched in the last 24 h − 2 if it is the reel watched most recently. Likes no longer count.
- Event: type (reel_watched, motivation_skipped, intervention_shown, chose_study, chose_reel, chose_break, session_distracted), time, meta
  - reel_watched: meta gồm reelId, secondsWatched, completed, startedFocus. Spec 002: one record per reel shown, written when the user leaves that reel or the app goes to the background; a later write replaces the same record (same id). Under 1 s is not recorded unless the reel ended, failed, a start action was used or "Quay lại học" was chosen. startedFocus is true only when a session started from the end card ("Bắt đầu N phút" / "Chỉ 5 phút thôi").
  - motivation_skipped (spec 002): meta `context` (start | distracted) and `position` (1-based reel index when "Bỏ qua" was pressed).
  - session_distracted: meta gồm awaySeconds, distractionIndex
  - reel_liked, reel_unliked, reel_commented, reel_shared: from versions before spec 002; never logged any more, kept only so old events still parse.
- Retired Hive boxes (`HiveBoxes.retired`): `reel_reactions` and `reel_comments` (old likes and comments). Never opened or read; names never reused; deleted from disk only by the explicit "Xoá toàn bộ dữ liệu" reset (ADR-0003).
  - intervention_shown: meta gồm packageName, appLabel, waitSeconds
  - chose_break: meta gồm minutes
- Danh sách app cần nhắc (2.1): danh sách packageName, lưu trong box `profile` với khóa `blocked_packages`; chưa có thì dùng danh sách mặc định trong BlockedAppsRepository.

## Thống kê và dữ liệu mẫu (8.2)
- Màn Thống kê mở từ Cài đặt. Phần tính nằm ở lib/services/focus_stats.dart (hàm thuần, có unit test), màn hình chỉ hiển thị.
  - Phút tập trung 7 ngày gần nhất: cộng focusedSeconds của Session theo ngày bắt đầu; biểu đồ cột vẽ bằng widget. Kèm số phiên và số ngày hoàn thành thói quen (từ HabitLog).
  - Reset break: số intervention_shown, tỉ lệ chose_study / chose_reel / chose_break trên tổng số lần đã chọn. Chỉ tính lựa chọn trên màn can thiệp, không tính sheet nhắc trong app (3.3).
  - Reels: số reel_watched và tỉ lệ có startedFocus ("Bắt đầu học ngay sau khi xem"). Thời gian quay lại: trung bình awaySeconds của session_distracted.
- "Tạo dữ liệu mẫu" (lib/data/mock_data.dart) dùng id cố định nên bấm nhiều lần không trùng. 1 mục tiêu có câu bản sắc, 7 thói quen đủ 7 màu, đủ Sáng/Chiều/Tối (và 1 thói quen "lúc nào cũng được"), có hằng tuần theo thứ (Chạy bộ T2, T4, T6), hằng tuần theo số ngày (Thiền 5 ngày/tuần) và 1 việc một lần hạn hôm nay; lịch sử 120 ngày có ngày bỏ, bỏ qua (skip), bản 2 phút, nghỉ phép (các ngày nghỉ phép cách nhau ≥ 7 ngày để luôn khác tuần dù hôm nay là thứ mấy); "Ôn bài" đủ 66 ngày (đủ 4 huy hiệu), "Đọc sách" bỏ hôm qua để hiện lời nhắc. sortOrder của thói quen mẫu bắt đầu từ 1 để thói quen tạo lúc onboarding (sortOrder 0) đứng đầu và được Focus chọn sẵn. Ngày thứ 6 trước hôm nay không thói quen nào được làm nên streak chung là 5. Hôm nay để trống (chỉ có "Làm bài tập" 10/30 phút) để demo xong một phiên thì streak tăng từ 5 lên 6. Có 5 phiên học, 8 lượt xem reel, 6 lần chặn kèm lựa chọn, 7 lần xao nhãng; mọi lượt xem reel mẫu đều cũ hơn 24 giờ để không làm lệch thứ tự đề xuất lúc demo.
