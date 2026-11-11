// 6.2 Mô hình dữ liệu – hồ sơ người dùng (chỉ có một, lưu local).
import 'motivation_type.dart';

class UserProfile {
  const UserProfile({
    required this.motivationTypes,
    required this.preferredReelLength,
    this.demoMode = false,
  });

  static const int defaultReelLength = 30;

  /// 1.1 Hai loại động lực có điểm quiz cao nhất.
  final List<MotivationType> motivationTypes;

  /// Độ dài reel ưa thích, tính bằng giây.
  final int preferredReelLength;

  /// Chế độ demo: đồng hồ phiên học và giờ nghỉ chạy nhanh hơn (xem
  /// FocusSessionTimer.demoTimeScale), để test và trình bày nhanh.
  final bool demoMode;

  UserProfile copyWith({List<MotivationType>? motivationTypes, bool? demoMode}) => UserProfile(
    motivationTypes: motivationTypes ?? this.motivationTypes,
    preferredReelLength: preferredReelLength,
    demoMode: demoMode ?? this.demoMode,
  );

  Map<String, dynamic> toMap() => {
    'motivationTypes': motivationTypes.map((type) => type.name).toList(),
    'preferredReelLength': preferredReelLength,
    'demoMode': demoMode,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    motivationTypes: (map['motivationTypes'] as List)
        .map((name) => MotivationType.values.byName(name as String))
        .toList(),
    preferredReelLength: map['preferredReelLength'] as int,
    // Hồ sơ lưu từ trước khi có trường này thì coi như chưa bật.
    demoMode: map['demoMode'] as bool? ?? false,
  );
}
