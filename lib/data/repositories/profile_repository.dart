// 6.2 Lưu trữ local – hồ sơ người dùng và cờ "đã qua onboarding".
// F2: hồ sơ là bản ghi id "profile" trong box profile (được đồng bộ); cờ onboarding và cấp
// đã chúc mừng nằm trong box device (riêng của máy, không đồng bộ).
import 'package:hive/hive.dart';

import '../hive_boxes.dart';
import '../local_store.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  /// Id cố định của bản ghi hồ sơ, cũng là id document trên Firestore.
  static const String profileId = 'profile';
  static const String _onboardingDoneKey = 'onboarding_done';
  static const String _celebratedLevelKey = 'celebrated_level';
  static const String guestModeKey = 'guest_mode';

  Box<dynamic> get _device => Hive.box<dynamic>(HiveBoxes.device);

  /// False ở lần mở app đầu tiên; router dựa vào đây để vào onboarding hay home.
  bool get isOnboardingDone => _device.get(_onboardingDoneKey, defaultValue: false) as bool;

  UserProfile? get profile {
    final record = LocalStore.read(HiveBoxes.profile, profileId);
    return record == null ? null : UserProfile.fromMap(record);
  }

  Future<void> saveProfile(UserProfile profile) =>
      LocalStore.write(HiveBoxes.profile, profileId, profile.toMap());

  /// Lưu hồ sơ và đánh dấu đã xong onboarding.
  Future<void> completeOnboarding(UserProfile profile) async {
    await saveProfile(profile);
    await _device.put(_onboardingDoneKey, true);
  }

  /// Đánh dấu đã xong onboarding mà không đổi hồ sơ: dùng khi đăng nhập vào tài khoản đã làm
  /// quiz động lực ở máy khác.
  Future<void> markOnboardingDone() => _device.put(_onboardingDoneKey, true);

  /// Cho phép xem lại onboarding, hồ sơ đã lưu vẫn được giữ. Bật luôn guestMode để router
  /// không đưa về màn chào (người đang ở trong app thì đã qua màn chào rồi).
  Future<void> resetOnboarding() async {
    await _device.put(_onboardingDoneKey, false);
    if (!isGuestMode) await _device.put(guestModeKey, true);
  }

  /// F3 Đã chọn "Dùng thử không cần tài khoản" ở màn chào. Riêng của máy, không đồng bộ;
  /// đăng xuất thì box device bị xoá nên cờ này cũng tắt.
  bool get isGuestMode => _device.get(guestModeKey, defaultValue: false) as bool;

  Future<void> setGuestMode(bool enabled) => _device.put(guestModeKey, enabled);

  /// 4.2 Cấp thành tích cao nhất đã hiện hộp thoại chúc mừng, để mỗi cấp chỉ chúc mừng một lần.
  int get celebratedLevel => _device.get(_celebratedLevelKey, defaultValue: 0) as int;

  Future<void> saveCelebratedLevel(int level) => _device.put(_celebratedLevelKey, level);
}
