// 6.2 Mô hình dữ liệu – thói quen thuộc một mục tiêu.
// 4.1 Các trường cue, place, minimalVersion theo "ý định thực hiện" (implementation intention):
// ghi rõ làm SAU KHI việc gì và Ở ĐÂU thì dễ làm thật hơn là chỉ hứa "sẽ học".

class Habit {
  const Habit({
    required this.id,
    required this.goalId,
    required this.name,
    required this.minMinutesPerDay,
    this.cue = '',
    this.place = '',
    this.minimalVersion = '',
    this.icon = defaultIcon,
  });

  /// Icon mặc định cho thói quen cũ chưa chọn icon, xem AppIcons.habitIcons.
  static const String defaultIcon = 'book';

  /// Khoá để Session tham chiếu tới qua habitId.
  final String id;
  final String goalId;
  final String name;
  final int minMinutesPerDay;

  /// Phần sau "Sau khi…", ví dụ "ăn tối". Rỗng nghĩa là chưa đặt.
  final String cue;

  /// Phần sau "Tại…", ví dụ "bàn học". Rỗng nghĩa là chưa đặt.
  final String place;

  /// Phiên bản 2 phút cho ngày mệt, ví dụ "Đọc lại 1 trang ghi chú".
  final String minimalVersion;

  /// Tên icon (khoá trong AppIcons.habitIcons). Lưu tên chứ không lưu mã icon
  /// để bản release vẫn lược bớt được font icon không dùng.
  final String icon;

  Habit copyWith({
    String? name,
    int? minMinutesPerDay,
    String? cue,
    String? place,
    String? minimalVersion,
    String? icon,
  }) => Habit(
    id: id,
    goalId: goalId,
    name: name ?? this.name,
    minMinutesPerDay: minMinutesPerDay ?? this.minMinutesPerDay,
    cue: cue ?? this.cue,
    place: place ?? this.place,
    minimalVersion: minimalVersion ?? this.minimalVersion,
    icon: icon ?? this.icon,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'goalId': goalId,
    'name': name,
    'minMinutesPerDay': minMinutesPerDay,
    'cue': cue,
    'place': place,
    'minimalVersion': minimalVersion,
    'icon': icon,
  };

  /// Dữ liệu cũ chưa có 4 trường mới thì lấy giá trị mặc định.
  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
    id: map['id'] as String,
    goalId: map['goalId'] as String,
    name: map['name'] as String,
    minMinutesPerDay: map['minMinutesPerDay'] as int,
    cue: map['cue'] as String? ?? '',
    place: map['place'] as String? ?? '',
    minimalVersion: map['minimalVersion'] as String? ?? '',
    icon: map['icon'] as String? ?? defaultIcon,
  );
}
