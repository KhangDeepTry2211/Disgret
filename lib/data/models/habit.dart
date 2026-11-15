// 6.2 Mô hình dữ liệu – thói quen thuộc một mục tiêu.
// 4.1 Các trường cue, place, minimalVersion theo "ý định thực hiện" (implementation intention):
// ghi rõ làm SAU KHI việc gì và Ở ĐÂU thì dễ làm thật hơn là chỉ hứa "sẽ học".
// Lịch lặp lại, giờ trong ngày, ngày kết thúc, nhắc nhở: xem habit_schedule.dart.
// Mọi trường thêm sau GĐ6B đều có giá trị mặc định nên dữ liệu cũ vẫn đọc được.
import '../date_utils.dart';

/// Thói quen lặp lại, hay việc chỉ làm một lần.
enum HabitType { regular, oneTime }

/// Lặp lại hằng ngày, hằng tuần (theo số ngày hoặc thứ cụ thể), hằng tháng (theo ngày).
enum HabitRepeat { daily, weekly, monthly }

/// Buổi trong ngày nên làm.
enum HabitTimeOfDay { morning, afternoon, evening, anytime }

/// Khi nào thói quen kết thúc: không kết thúc, đến một ngày, hoặc sau N ngày kể từ ngày bắt đầu.
enum HabitEndRule { never, onDate, afterDays }

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
    this.type = HabitType.regular,
    this.colorIndex = 0,
    this.repeat = HabitRepeat.daily,
    this.daysPerWeek = 7,
    this.weekdays = const [],
    this.monthDays = const [],
    this.timeOfDay = HabitTimeOfDay.anytime,
    this.endRule = HabitEndRule.never,
    this.endDate,
    this.endAfterDays = defaultEndAfterDays,
    this.reminderEnabled = false,
    this.reminderTime = defaultReminderTime,
    this.sortOrder = 0,
    this.startDate,
    this.dueDate,
    this.archived = false,
  });

  /// Icon mặc định cho thói quen cũ chưa chọn icon, xem AppIcons.habitIcons.
  static const String defaultIcon = 'book';
  static const int defaultEndAfterDays = 30;
  static const String defaultReminderTime = '07:00';

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

  /// Tên icon Material (khoá trong AppIcons.habitIcons) hoặc một emoji, ví dụ "📚".
  /// Lưu tên chứ không lưu mã icon để bản release vẫn lược bớt được font icon.
  final String icon;

  final HabitType type;

  /// Vị trí trong bảng 12 màu pastel AppHabitColors.palette.
  final int colorIndex;

  final HabitRepeat repeat;

  /// Hằng tuần theo số ngày: làm đủ bấy nhiêu ngày mỗi tuần, ngày nào cũng được (1–7).
  /// Chỉ dùng khi [weekdays] rỗng.
  final int daysPerWeek;

  /// Hằng tuần theo thứ cụ thể: DateTime.monday (1) ... DateTime.sunday (7).
  final List<int> weekdays;

  /// Hằng tháng: các ngày trong tháng (1–31).
  final List<int> monthDays;

  final HabitTimeOfDay timeOfDay;

  final HabitEndRule endRule;

  /// Ngày cuối cùng (tính cả ngày đó) khi [endRule] là onDate.
  final DateTime? endDate;

  /// Số ngày, tính cả ngày bắt đầu, khi [endRule] là afterDays.
  final int endAfterDays;

  /// Nhắc nhở: hiện chỉ lưu lại, chưa gửi thông báo.
  final bool reminderEnabled;

  /// Giờ nhắc dạng "HH:mm".
  final String reminderTime;

  /// Thứ tự hiển thị; bằng nhau thì giữ thứ tự trong Hive.
  final int sortOrder;

  /// Ngày tạo thói quen (chỉ ngày). Dữ liệu cũ không có thì coi như đã bắt đầu từ lâu.
  final DateTime? startDate;

  /// Hạn của việc một lần (chỉ ngày).
  final DateTime? dueDate;

  /// "Xoá nhưng giữ lịch sử": ẩn khỏi mọi màn, log vẫn còn cho Thống kê.
  final bool archived;

  bool get isWeeklyByCount => repeat == HabitRepeat.weekly && weekdays.isEmpty;

  Habit copyWith({
    String? name,
    int? minMinutesPerDay,
    String? cue,
    String? place,
    String? minimalVersion,
    String? icon,
    int? colorIndex,
    int? sortOrder,
    bool? archived,
  }) => Habit(
    id: id,
    goalId: goalId,
    name: name ?? this.name,
    minMinutesPerDay: minMinutesPerDay ?? this.minMinutesPerDay,
    cue: cue ?? this.cue,
    place: place ?? this.place,
    minimalVersion: minimalVersion ?? this.minimalVersion,
    icon: icon ?? this.icon,
    type: type,
    colorIndex: colorIndex ?? this.colorIndex,
    repeat: repeat,
    daysPerWeek: daysPerWeek,
    weekdays: weekdays,
    monthDays: monthDays,
    timeOfDay: timeOfDay,
    endRule: endRule,
    endDate: endDate,
    endAfterDays: endAfterDays,
    reminderEnabled: reminderEnabled,
    reminderTime: reminderTime,
    sortOrder: sortOrder ?? this.sortOrder,
    startDate: startDate,
    dueDate: dueDate,
    archived: archived ?? this.archived,
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
    'type': type.name,
    'colorIndex': colorIndex,
    'repeat': repeat.name,
    'daysPerWeek': daysPerWeek,
    'weekdays': weekdays,
    'monthDays': monthDays,
    'timeOfDay': timeOfDay.name,
    'endRule': endRule.name,
    'endDate': endDate == null ? null : dateKey(endDate!),
    'endAfterDays': endAfterDays,
    'reminderEnabled': reminderEnabled,
    'reminderTime': reminderTime,
    'sortOrder': sortOrder,
    'startDate': startDate == null ? null : dateKey(startDate!),
    'dueDate': dueDate == null ? null : dateKey(dueDate!),
    'archived': archived,
  };

  /// Dữ liệu cũ thiếu trường nào thì lấy giá trị mặc định của trường đó.
  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
    id: map['id'] as String,
    goalId: map['goalId'] as String,
    name: map['name'] as String,
    minMinutesPerDay: map['minMinutesPerDay'] as int,
    cue: map['cue'] as String? ?? '',
    place: map['place'] as String? ?? '',
    minimalVersion: map['minimalVersion'] as String? ?? '',
    icon: map['icon'] as String? ?? defaultIcon,
    type: _enum(HabitType.values, map['type'], HabitType.regular),
    colorIndex: map['colorIndex'] as int? ?? 0,
    repeat: _enum(HabitRepeat.values, map['repeat'], HabitRepeat.daily),
    daysPerWeek: map['daysPerWeek'] as int? ?? 7,
    weekdays: _ints(map['weekdays']),
    monthDays: _ints(map['monthDays']),
    timeOfDay: _enum(HabitTimeOfDay.values, map['timeOfDay'], HabitTimeOfDay.anytime),
    endRule: _enum(HabitEndRule.values, map['endRule'], HabitEndRule.never),
    endDate: _date(map['endDate']),
    endAfterDays: map['endAfterDays'] as int? ?? defaultEndAfterDays,
    reminderEnabled: map['reminderEnabled'] as bool? ?? false,
    reminderTime: map['reminderTime'] as String? ?? defaultReminderTime,
    sortOrder: map['sortOrder'] as int? ?? 0,
    startDate: _date(map['startDate']),
    dueDate: _date(map['dueDate']),
    archived: map['archived'] as bool? ?? false,
  );

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.where((value) => value.name == name).firstOrNull ?? fallback;

  static List<int> _ints(Object? list) => (list as List? ?? const []).cast<int>().toList();

  static DateTime? _date(Object? text) => text == null ? null : DateTime.parse(text as String);
}
