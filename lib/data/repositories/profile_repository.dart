// 6.2 Lưu trữ local – hồ sơ người dùng và cờ "đã qua onboarding".
import 'package:hive/hive.dart';

import '../hive_boxes.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  static const String _profileKey = 'user';
  static const String _onboardingDoneKey = 'onboarding_done';

  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.profile);

  /// False ở lần mở app đầu tiên; router dựa vào đây để vào onboarding hay home.
  bool get isOnboardingDone => _box.get(_onboardingDoneKey, defaultValue: false) as bool;

  UserProfile? get profile {
    final value = _box.get(_profileKey);
    return value == null ? null : UserProfile.fromMap(Map<String, dynamic>.from(value as Map));
  }

  Future<void> saveProfile(UserProfile profile) => _box.put(_profileKey, profile.toMap());

  /// Lưu hồ sơ và đánh dấu đã xong onboarding.
  Future<void> completeOnboarding(UserProfile profile) async {
    await saveProfile(profile);
    await _box.put(_onboardingDoneKey, true);
  }

  /// Cho phép xem lại onboarding, hồ sơ đã lưu vẫn được giữ.
  Future<void> resetOnboarding() => _box.put(_onboardingDoneKey, false);
}
