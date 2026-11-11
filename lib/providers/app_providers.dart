// 5.1, 6.2 Riverpod – nơi màn hình lấy dữ liệu dùng chung.
// Mỗi loại dữ liệu có một Notifier giữ danh sách hiện tại. Mọi thao tác thêm, sửa, xoá
// đều đi qua Notifier: ghi xuống Hive rồi gán lại state, nên màn hình tự cập nhật ngay.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/date_utils.dart';
import '../data/habit_progress.dart';
import '../data/hive_boxes.dart';
import '../data/mock_data.dart';
import '../data/models/goal.dart';
import '../data/models/habit.dart';
import '../data/models/habit_log.dart';
import '../data/models/motivation_type.dart';
import '../data/models/reel.dart';
import '../data/models/session.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/blocked_apps_repository.dart';
import '../data/repositories/event_repository.dart';
import '../data/repositories/goal_repository.dart';
import '../data/repositories/habit_log_repository.dart';
import '../data/repositories/habit_repository.dart';
import '../data/repositories/hive_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/reel_repository.dart';
import '../data/repositories/session_repository.dart';
import '../services/focus_stats.dart';
import '../services/native_bridge.dart';

// ---------- Repository ----------

final profileRepositoryProvider = Provider((ref) => ProfileRepository());
final goalRepositoryProvider = Provider((ref) => GoalRepository());
final habitRepositoryProvider = Provider((ref) => HabitRepository());
final habitLogRepositoryProvider = Provider((ref) => HabitLogRepository());
final sessionRepositoryProvider = Provider((ref) => SessionRepository());
final reelRepositoryProvider = Provider((ref) => ReelRepository());
final eventRepositoryProvider = Provider((ref) => EventRepository());
final blockedAppsRepositoryProvider = Provider((ref) => BlockedAppsRepository());

/// Cầu nối sang phần Kotlin; tách thành provider để test thay bằng bản giả.
final nativeBridgeProvider = Provider<NativeBridge>((ref) => const NativeBridge());

// ---------- Ngày hôm nay ----------

/// Đồng hồ của app; tách riêng để test giả lập được việc sang ngày mới.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Ngày đang hiển thị. Được làm mới mỗi khi app quay lại từ nền (xem app.dart),
/// nếu không thì app để qua đêm vẫn hiện dấu tick của hôm qua.
class TodayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(ref.read(clockProvider)());

  void refresh() => state = dateOnly(ref.read(clockProvider)());
}

final todayProvider = NotifierProvider<TodayNotifier, DateTime>(TodayNotifier.new);

// ---------- 1.1 Hồ sơ động lực ----------

class ProfileNotifier extends Notifier<UserProfile?> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  UserProfile? build() => ref.watch(profileRepositoryProvider).profile;

  Future<void> completeOnboarding(UserProfile profile) async {
    await _repository.completeOnboarding(profile);
    state = profile;
  }

  /// Làm lại quiz: chỉ đổi động lực, giữ nguyên các lựa chọn khác trong hồ sơ.
  Future<void> updateMotivationTypes(List<MotivationType> types) =>
      _save(_currentOrDefault.copyWith(motivationTypes: types));

  /// Bật hoặc tắt chế độ demo trong Cài đặt.
  Future<void> setDemoMode(bool enabled) => _save(_currentOrDefault.copyWith(demoMode: enabled));

  UserProfile get _currentOrDefault =>
      state ??
      const UserProfile(motivationTypes: [], preferredReelLength: UserProfile.defaultReelLength);

  Future<void> _save(UserProfile profile) async {
    await _repository.saveProfile(profile);
    state = profile;
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);

// ---------- 1.2 Kho nội dung ----------

/// Danh sách reel đọc từ asset, chỉ đọc một lần rồi giữ lại.
final reelsProvider = FutureProvider<List<Reel>>(
  (ref) => ref.watch(reelRepositoryProvider).loadAll(),
);

// ---------- 4.1 Đặt mục tiêu ----------

class GoalsNotifier extends Notifier<List<Goal>> {
  GoalRepository get _repository => ref.read(goalRepositoryProvider);

  @override
  List<Goal> build() => ref.watch(goalRepositoryProvider).getAll();

  Future<Goal> add({required String title, required String reason}) async {
    final goal = Goal(id: newId(), title: title, reason: reason);
    await _repository.save(goal);
    state = _repository.getAll();
    return goal;
  }

  Future<void> edit(Goal goal) async {
    await _repository.save(goal);
    state = _repository.getAll();
  }

  /// Xoá mục tiêu kéo theo các thói quen và nhật ký của chúng.
  Future<void> remove(String goalId) async {
    await ref.read(habitsProvider.notifier).removeByGoal(goalId);
    await _repository.delete(goalId);
    state = _repository.getAll();
  }
}

final goalsProvider = NotifierProvider<GoalsNotifier, List<Goal>>(GoalsNotifier.new);

class HabitsNotifier extends Notifier<List<Habit>> {
  HabitRepository get _repository => ref.read(habitRepositoryProvider);

  @override
  List<Habit> build() => ref.watch(habitRepositoryProvider).getAll();

  Future<Habit> add({
    required String goalId,
    required String name,
    required int minMinutesPerDay,
  }) async {
    final habit = Habit(
      id: newId(),
      goalId: goalId,
      name: name,
      minMinutesPerDay: minMinutesPerDay,
    );
    await _repository.save(habit);
    state = _repository.getAll();
    return habit;
  }

  Future<void> edit(Habit habit) async {
    await _repository.save(habit);
    state = _repository.getAll();
  }

  /// Xoá thói quen kéo theo nhật ký của nó.
  Future<void> remove(String habitId) async {
    await ref.read(habitLogsProvider.notifier).removeByHabit(habitId);
    await _repository.delete(habitId);
    state = _repository.getAll();
  }

  Future<void> removeByGoal(String goalId) async {
    for (final habit in state.where((habit) => habit.goalId == goalId).toList()) {
      await remove(habit.id);
    }
  }
}

final habitsProvider = NotifierProvider<HabitsNotifier, List<Habit>>(HabitsNotifier.new);

// ---------- 4.2 Ghi nhận ----------

class HabitLogsNotifier extends Notifier<List<HabitLog>> {
  HabitLogRepository get _repository => ref.read(habitLogRepositoryProvider);

  @override
  List<HabitLog> build() => ref.watch(habitLogRepositoryProvider).getAll();

  /// Ô tick "Hôm nay đã làm": tick tạo log manual, bỏ tick xoá log manual của hôm nay.
  Future<void> setDoneToday(Habit habit, {required bool done}) async {
    final today = ref.read(todayProvider);
    if (done) {
      await _repository.markDone(habit, today);
    } else {
      await _repository.unmarkDone(habit.id, today);
    }
    state = _repository.getAll();
  }

  Future<void> saveNoteToday(Habit habit, String note) async {
    await _repository.saveNote(habit.id, ref.read(todayProvider), note);
    state = _repository.getAll();
  }

  /// GĐ4 gọi hàm này khi kết thúc phiên Focus.
  Future<void> recordSession(Session session) async {
    await _repository.recordSession(session);
    state = _repository.getAll();
  }

  Future<void> removeByHabit(String habitId) async {
    await _repository.deleteByHabit(habitId);
    state = _repository.getAll();
  }
}

final habitLogsProvider = NotifierProvider<HabitLogsNotifier, List<HabitLog>>(
  HabitLogsNotifier.new,
);

// ---------- 2.1 Danh sách app ----------

/// Các app sẽ bị nhắc khi mở trong lúc đang học.
class BlockedAppsNotifier extends Notifier<Set<String>> {
  BlockedAppsRepository get _repository => ref.read(blockedAppsRepositoryProvider);

  @override
  Set<String> build() => ref.watch(blockedAppsRepositoryProvider).packages;

  Future<void> setBlocked(String packageName, {required bool blocked}) async {
    final updated = {...state};
    blocked ? updated.add(packageName) : updated.remove(packageName);
    // Đổi state trước khi chờ ghi xuống Hive: bấm hai công tắc liền nhau thì lần sau
    // đã thấy kết quả của lần trước, không làm mất lựa chọn nào.
    state = updated;
    await _repository.save(updated);
  }
}

final blockedAppsProvider = NotifierProvider<BlockedAppsNotifier, Set<String>>(
  BlockedAppsNotifier.new,
);

/// App cài trên máy. Đọc icon khá lâu nên giữ lại khi đang mở màn, rời màn thì bỏ
/// để lần sau mở lại thấy được app vừa cài.
final installedAppsProvider = FutureProvider.autoDispose<List<InstalledApp>>(
  (ref) => ref.watch(nativeBridgeProvider).getLaunchableApps(),
);

// ---------- Dữ liệu cho Trang chủ và Focus ----------

/// Mục tiêu hiển thị ở Trang chủ: mục tiêu đầu tiên.
class TodayGoalNotifier extends Notifier<Goal?> {
  @override
  Goal? build() {
    final goals = ref.watch(goalsProvider);
    return goals.isEmpty ? null : goals.first;
  }
}

final todayGoalProvider = NotifierProvider<TodayGoalNotifier, Goal?>(TodayGoalNotifier.new);

/// Thói quen nên làm tiếp: thói quen đầu tiên chưa hoàn thành hôm nay;
/// làm hết rồi thì lấy thói quen đầu tiên. Màn Focus dùng giá trị này.
class TodayHabitNotifier extends Notifier<Habit?> {
  @override
  Habit? build() {
    final habits = ref.watch(habitsProvider);
    final logs = ref.watch(habitLogsProvider);
    final today = ref.watch(todayProvider);

    for (final habit in habits) {
      if (!HabitProgress.isDone(habit, today, logs)) return habit;
    }
    return habits.isEmpty ? null : habits.first;
  }
}

final todayHabitProvider = NotifierProvider<TodayHabitNotifier, Habit?>(TodayHabitNotifier.new);

/// Streak chung hiện trên vòng streak.
final overallStreakProvider = Provider<int>((ref) {
  return HabitProgress.overallStreak(
    ref.watch(habitsProvider),
    ref.watch(habitLogsProvider),
    today: ref.watch(todayProvider),
  );
});

// ---------- 8.2 Thống kê ----------

/// Tính lại mỗi lần mở màn Thống kê: sự kiện và phiên học được ghi thẳng xuống Hive
/// chứ không qua Notifier, nên không có state nào để theo dõi.
/// Dùng FutureProvider để màn hình hiện được thông báo khi đọc dữ liệu bị lỗi.
final focusStatsProvider = FutureProvider.autoDispose<FocusStats>((ref) async {
  return FocusStats.from(
    events: ref.read(eventRepositoryProvider).getAll(),
    sessions: ref.read(sessionRepositoryProvider).getAll(),
    habits: ref.watch(habitsProvider),
    logs: ref.watch(habitLogsProvider),
    today: ref.watch(todayProvider),
  );
});

// ---------- Thao tác trên toàn bộ dữ liệu (Cài đặt) ----------

class AppDataActions {
  AppDataActions(this._ref);

  final Ref _ref;

  Future<void> createDemoData() async {
    await MockData.createDemoData(now: _ref.read(clockProvider)());
    _reloadAll();
  }

  Future<void> clearAll() async {
    await HiveBoxes.clearUserData();
    _reloadAll();
  }

  void _reloadAll() {
    _ref.invalidate(profileProvider);
    _ref.invalidate(goalsProvider);
    _ref.invalidate(habitsProvider);
    _ref.invalidate(habitLogsProvider);
    _ref.invalidate(blockedAppsProvider);
  }
}

final appDataActionsProvider = Provider(AppDataActions.new);
