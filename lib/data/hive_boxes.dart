// 6.2 Lưu trữ local – tên các box Hive, mỗi loại dữ liệu nằm trong một box.
// F2: các box trong [synced] được đồng bộ với Firestore (users/{uid}/{box}/{id});
// box [device] chỉ thuộc máy này, không đồng bộ.
import 'package:hive/hive.dart';

import 'local_store.dart';

class HiveBoxes {
  HiveBoxes._();

  /// Hồ sơ: 2 bản ghi id cố định "profile" (UserProfile) và "blocked_apps" (danh sách app chặn).
  static const String profile = 'profile';
  static const String goals = 'goals';
  static const String habits = 'habits';
  static const String habitLogs = 'habit_logs';
  static const String sessions = 'sessions';
  static const String events = 'events';
  static const String reelReactions = 'reel_reactions';
  static const String reelComments = 'reel_comments';

  /// Trạng thái riêng của máy: đã qua onboarding chưa, cấp thành tích đã chúc mừng.
  /// Không đồng bộ, vì "Xem lại màn giới thiệu" ở máy này không được đá máy khác về onboarding.
  static const String device = 'device';

  /// F2 Các box đồng bộ lên Firestore. Reel gốc đọc từ asset (1.2) nên không có box.
  static const List<String> synced = [
    profile,
    goals,
    habits,
    habitLogs,
    sessions,
    events,
    reelReactions,
    reelComments,
  ];

  static const List<String> all = [...synced, device];

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

  // ---------- F2 Migrate dữ liệu cũ ----------

  // Khoá cũ trong box profile (trước F2).
  static const String _legacyProfileKey = 'user';
  static const String _legacyBlockedKey = 'blocked_packages';
  static const List<String> _legacyDeviceKeys = ['onboarding_done', 'celebrated_level'];

  /// Gọi lúc khởi động sau [openAll]: chuyển dữ liệu cũ sang dạng mới rồi bổ sung
  /// updatedAtMs / deleted cho bản ghi chưa có.
  static Future<void> migrate() async {
    final profileBox = Hive.box<dynamic>(profile);
    final deviceBox = Hive.box<dynamic>(device);

    for (final key in _legacyDeviceKeys) {
      if (!profileBox.containsKey(key)) continue;
      await deviceBox.put(key, profileBox.get(key));
      await profileBox.delete(key);
    }

    final legacyProfile = profileBox.get(_legacyProfileKey);
    if (legacyProfile is Map) {
      await profileBox.put('profile', Map<String, dynamic>.from(legacyProfile));
    }
    await profileBox.delete(_legacyProfileKey);

    final legacyBlocked = profileBox.get(_legacyBlockedKey);
    if (legacyBlocked is List) {
      await profileBox.put('blocked_apps', {'packages': legacyBlocked.cast<String>().toList()});
    }
    await profileBox.delete(_legacyBlockedKey);

    for (final name in synced) {
      await LocalStore.addMissingSyncFields(name);
    }
  }
}
