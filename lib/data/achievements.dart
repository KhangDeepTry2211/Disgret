// 4.2 Thành tích – cấp độ theo TỔNG số lần hoàn thành của mọi thói quen (kể cả thói quen đã
// "xoá nhưng giữ lịch sử"). Tách riêng với 4 huy hiệu Hành trình 66 ngày của từng thói quen.
// Toàn bộ là hàm thuần, có unit test (test/achievements_test.dart).
import 'habit_science.dart';

class Achievements {
  Achievements._();

  /// Số lần hoàn thành cần có để đạt cấp 1, 2, ... 9.
  static const List<int> levels = [10, 30, 66, 100, 200, 365, 500, 750, 1000];

  /// Tổng số lần hoàn thành: mỗi thói quen mỗi ngày làm xong được tính 1 lần.
  static int totalCompletions(Iterable<HabitHistory> histories) =>
      histories.fold(0, (sum, history) => sum + history.doneDays.length);

  /// Cấp hiện tại (0 = chưa đạt cấp nào, tối đa [levels].length).
  static int levelFor(int total) => levels.where((target) => total >= target).length;

  /// Số lần cần cho cấp kế tiếp; null nếu đã đạt cấp cao nhất.
  static int? nextTarget(int total) {
    for (final target in levels) {
      if (total < target) return target;
    }
    return null;
  }

  /// Tiến độ từ cấp hiện tại tới cấp kế tiếp, từ 0 đến 1 (đã đạt cấp cao nhất thì 1).
  static double progressToNext(int total) {
    final next = nextTarget(total);
    if (next == null) return 1;
    final level = levelFor(total);
    final previous = level == 0 ? 0 : levels[level - 1];
    return (total - previous) / (next - previous);
  }
}
