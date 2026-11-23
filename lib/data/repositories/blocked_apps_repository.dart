// 2.1 Danh sách app – lưu packageName của các app cần nhắc, nằm trong box hồ sơ.
import 'package:hive/hive.dart';

import '../hive_boxes.dart';

class BlockedAppsRepository {
  static const String _key = 'blocked_packages';

  /// Mặc định bật khi chưa từng chỉnh. TikTok có hai package tuỳ khu vực.
  static const Set<String> defaultPackages = {
    'com.zhiliaoapp.musically',
    'com.ss.android.ugc.trill',
    'com.facebook.katana',
    'com.instagram.android',
    'com.google.android.youtube',
    'com.android.chrome',
  };

  /// Apps offered on the onboarding question "App nào hay kéo bạn đi nhất?" (spec 003
  /// FR-011a), by the name shown on the chip.
  static const Map<String, Set<String>> onboardingApps = {
    'TikTok': {'com.zhiliaoapp.musically', 'com.ss.android.ugc.trill'},
    'YouTube': {'com.google.android.youtube'},
    'Instagram': {'com.instagram.android'},
    'Facebook': {'com.facebook.katana'},
    'Chrome': {'com.android.chrome'},
  };

  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.profile);

  Set<String> get packages {
    final saved = _box.get(_key) as List<dynamic>?;
    return saved == null ? defaultPackages : saved.cast<String>().toSet();
  }

  Future<void> save(Set<String> packages) => _box.put(_key, packages.toList());
}
