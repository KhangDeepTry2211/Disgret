// 6.2 Mô hình dữ liệu – thói quen thuộc một mục tiêu.

class Habit {
  const Habit({
    required this.id,
    required this.goalId,
    required this.name,
    required this.minMinutesPerDay,
  });

  /// Khoá để Session tham chiếu tới qua habitId.
  final String id;
  final String goalId;
  final String name;
  final int minMinutesPerDay;

  Map<String, dynamic> toMap() => {
    'id': id,
    'goalId': goalId,
    'name': name,
    'minMinutesPerDay': minMinutesPerDay,
  };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
    id: map['id'] as String,
    goalId: map['goalId'] as String,
    name: map['name'] as String,
    minMinutesPerDay: map['minMinutesPerDay'] as int,
  );
}
