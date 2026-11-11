// 6.2 Lưu trữ local – tên các box Hive, mỗi loại dữ liệu nằm trong một box.
import 'package:hive/hive.dart';

class HiveBoxes {
  HiveBoxes._();

  static const String profile = 'profile';
  static const String goals = 'goals';
  static const String habits = 'habits';
  static const String habitLogs = 'habit_logs';
  static const String sessions = 'sessions';
  static const String events = 'events';

  /// Reel đọc từ asset (1.2) nên không có box riêng.
  static const List<String> all = [profile, goals, habits, habitLogs, sessions, events];

  /// Mở toàn bộ box; gọi một lần lúc khởi động, trước khi dùng repository.
  static Future<void> openAll() async {
    for (final name in all) {
      await Hive.openBox<dynamic>(name);
    }
  }

  /// Xoá toàn bộ dữ liệu người dùng, đưa app về trạng thái như mới cài.
  static Future<void> clearUserData() async {
    for (final name in all) {
      await Hive.box<dynamic>(name).clear();
    }
  }
}
