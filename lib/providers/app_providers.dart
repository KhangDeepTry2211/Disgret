// 5.1, 6.2 Riverpod – nơi màn hình lấy dữ liệu dùng chung.
// Mỗi loại dữ liệu có một Notifier giữ danh sách hiện tại. Mọi thao tác thêm, sửa, xoá
// đều đi qua Notifier: ghi xuống Hive rồi gán lại state, nên màn hình tự cập nhật ngay.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/achievements.dart';
import '../data/date_utils.dart';
import '../data/habit_science.dart';
import '../data/hive_boxes.dart';
import '../data/mock_data.dart';
import '../data/models/goal.dart';
import '../data/models/habit.dart';
import '../data/models/habit_log.dart';
import '../data/models/motivation_type.dart';
import '../data/models/event.dart';
import '../data/models/reel.dart';
import '../data/models/reel_comment.dart';
import '../data/models/reel_reaction.dart';
import '../data/models/session.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/blocked_apps_repository.dart';
import '../data/repositories/event_repository.dart';
import '../data/repositories/goal_repository.dart';
import '../data/repositories/habit_log_repository.dart';
import '../data/repositories/habit_repository.dart';
import '../data/repositories/hive_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/reel_comment_repository.dart';
import '../data/repositories/reel_reaction_repository.dart';
import '../data/repositories/reel_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/session_plan.dart';
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
final reelReactionRepositoryProvider = Provider((ref) => ReelReactionRepository());
final reelCommentRepositoryProvider = Provider((ref) => ReelCommentRepository());
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

  Future<Goal> add({required String title, required String reason, String identity = ''}) async {
    final goal = Goal(id: newId(), title: title, reason: reason, identity: identity);
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

  /// Chỉ các thói quen đang dùng (bỏ thói quen đã "xoá nhưng giữ lịch sử"),
  /// sắp theo sortOrder; bằng nhau thì giữ thứ tự trong Hive.
  @override
  List<Habit> build() => _active(ref.watch(habitRepositoryProvider).getAll());

  static List<Habit> _active(List<Habit> all) {
    final active = all.where((habit) => !habit.archived).toList();
    // Dart không đảm bảo sort giữ thứ tự cũ khi bằng nhau nên so thêm vị trí ban đầu.
    final position = {for (var i = 0; i < active.length; i++) active[i].id: i};
    active.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : position[a.id]!.compareTo(position[b.id]!);
    });
    return active;
  }

  void _reload() => state = _active(_repository.getAll());

  /// Lưu thói quen mới từ bản nháp của màn tạo thói quen: gán id mới, ngày bắt đầu là hôm nay
  /// (nếu bản nháp chưa có) và xếp xuống cuối danh sách.
  Future<Habit> create(Habit draft) async {
    final orders = _repository.getAll().map((habit) => habit.sortOrder);
    final habit = Habit.fromMap({
      ...draft.toMap(),
      'id': newId(),
      'startDate': dateKey(draft.startDate ?? ref.read(todayProvider)),
      'sortOrder': orders.isEmpty ? 0 : orders.reduce((a, b) => a > b ? a : b) + 1,
    });
    await _repository.save(habit);
    _reload();
    return habit;
  }

  /// Cách tạo nhanh (onboarding): chỉ cần tên và số phút, các trường khác lấy mặc định.
  Future<Habit> add({
    required String goalId,
    required String name,
    required int minMinutesPerDay,
    String cue = '',
    String place = '',
    String minimalVersion = '',
    String icon = Habit.defaultIcon,
  }) => create(
    Habit(
      id: '',
      goalId: goalId,
      name: name,
      minMinutesPerDay: minMinutesPerDay,
      cue: cue,
      place: place,
      minimalVersion: minimalVersion,
      icon: icon,
    ),
  );

  Future<void> edit(Habit habit) async {
    await _repository.save(habit);
    _reload();
  }

  /// 4.1 Kéo thả trong màn "Thói quen của tôi": chuyển thói quen ở vị trí [oldIndex] sang
  /// [newIndex] trong danh sách cùng loại [type]. Các thói quen loại kia giữ nguyên chỗ; sau đó
  /// đánh lại sortOrder = vị trí cho cả danh sách và lưu những thói quen đổi chỗ.
  Future<void> reorderWithinType(HabitType type, int oldIndex, int newIndex) async {
    final all = [...state];
    final sameType = all.where((habit) => habit.type == type).toList();
    if (oldIndex < 0 || oldIndex >= sameType.length) return;
    final moved = sameType.removeAt(oldIndex);
    sameType.insert(newIndex.clamp(0, sameType.length), moved);

    // Đặt lại các thói quen loại [type] vào đúng những chỗ chúng đang chiếm.
    var next = 0;
    final reordered = [for (final habit in all) habit.type == type ? sameType[next++] : habit];
    for (var i = 0; i < reordered.length; i++) {
      if (reordered[i].sortOrder != i) {
        await _repository.save(reordered[i].copyWith(sortOrder: i));
      }
    }
    _reload();
  }

  /// 4.1 "Xoá nhưng giữ lịch sử": ẩn thói quen, log vẫn còn để Thống kê tính.
  Future<void> archive(String habitId) async {
    final habit = _repository.getById(habitId);
    if (habit == null) return;
    await _repository.save(habit.copyWith(archived: true));
    _reload();
  }

  /// "Xoá cả lịch sử": xoá thói quen kéo theo nhật ký của nó.
  Future<void> remove(String habitId) async {
    await ref.read(habitLogsProvider.notifier).removeByHabit(habitId);
    await _repository.delete(habitId);
    _reload();
  }

  /// Xoá mục tiêu thì xoá hết thói quen của nó, kể cả thói quen đã ẩn.
  Future<void> removeByGoal(String goalId) async {
    for (final habit in _repository.getByGoal(goalId)) {
      await remove(habit.id);
    }
  }
}

final habitsProvider = NotifierProvider<HabitsNotifier, List<Habit>>(HabitsNotifier.new);

/// Mọi thói quen kể cả đã "xoá nhưng giữ lịch sử", dùng cho Thống kê (8.2).
/// Theo dõi habitsProvider để tự tính lại mỗi khi thói quen thay đổi.
final allHabitsProvider = Provider<List<Habit>>((ref) {
  ref.watch(habitsProvider);
  return ref.read(habitRepositoryProvider).getAll();
});

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

  /// Đánh dấu hôm nay: làm bản 2 phút, nghỉ phép, bỏ qua (skip)...
  Future<void> setMarkToday(Habit habit, HabitLogSource source) =>
      setMarkOn(habit, ref.read(todayProvider), source);

  /// Đánh dấu một ngày bất kỳ (bảng Tuần cho sửa các ngày đã qua). Mỗi ngày chỉ một loại.
  Future<void> setMarkOn(Habit habit, DateTime day, HabitLogSource source) async {
    await _repository.setMark(habit, day, source);
    state = _repository.getAll();
  }

  /// Bỏ đánh dấu của một ngày; phút Focus thật vẫn giữ.
  Future<void> clearMarksOn(Habit habit, DateTime day) async {
    await _repository.clearMarks(habit.id, day);
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

// ---------- 1.4 Thích và bình luận reel ----------

/// Id các reel người dùng đang thích.
class ReelLikesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(reelReactionRepositoryProvider).likedIds();

  /// Đặt trạng thái thích. Trả về true nếu có thay đổi (chạm đúp vào reel đã thích thì không đổi).
  Future<bool> setLiked(String reelId, {required bool liked}) async {
    if (state.contains(reelId) == liked) return false;
    // Đổi state trước khi chờ ghi xuống Hive, như BlockedAppsNotifier.
    state = liked ? {...state, reelId} : ({...state}..remove(reelId));
    await ref
        .read(reelReactionRepositoryProvider)
        .save(ReelReaction(reelId: reelId, liked: liked, likedAt: ref.read(clockProvider)()));
    await ref
        .read(eventRepositoryProvider)
        .logReelAction(liked ? EventType.reelLiked : EventType.reelUnliked, reelId);
    return true;
  }

  Future<void> toggle(String reelId) => setLiked(reelId, liked: !state.contains(reelId));
}

final reelLikesProvider = NotifierProvider<ReelLikesNotifier, Set<String>>(ReelLikesNotifier.new);

/// Bình luận chưa xoá của mọi reel, cũ nhất trước.
class ReelCommentsNotifier extends Notifier<List<ReelComment>> {
  ReelCommentRepository get _repository => ref.read(reelCommentRepositoryProvider);

  @override
  List<ReelComment> build() =>
      ref
          .watch(reelCommentRepositoryProvider)
          .getAll()
          .where((comment) => !comment.deleted)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  /// Thêm bình luận của người dùng. Chuỗi rỗng thì không thêm; quá dài thì cắt còn 300 ký tự.
  Future<bool> add(String reelId, String text) async {
    var trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length > ReelComment.maxLength) {
      trimmed = trimmed.substring(0, ReelComment.maxLength);
    }
    final now = ref.read(clockProvider)();
    final comment = ReelComment(
      id: newId(),
      reelId: reelId,
      text: trimmed,
      createdAt: now,
      updatedAt: now,
    );
    state = [...state, comment];
    await _repository.save(comment);
    await ref.read(eventRepositoryProvider).logReelAction(EventType.reelCommented, reelId);
    return true;
  }

  /// Xoá mềm: giữ bản ghi với deleted = true để sau này đồng bộ.
  Future<void> delete(String id) async {
    final comment = state.where((item) => item.id == id).firstOrNull;
    if (comment == null) return;
    state = [
      for (final item in state)
        if (item.id != id) item,
    ];
    await _repository.save(comment.copyWith(deleted: true, updatedAt: ref.read(clockProvider)()));
  }
}

final reelCommentsProvider = NotifierProvider<ReelCommentsNotifier, List<ReelComment>>(
  ReelCommentsNotifier.new,
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

// ---------- Dữ liệu cho Hôm nay và phiên học ----------

/// Mục tiêu hiển thị ở Hôm nay: mục tiêu đầu tiên.
class TodayGoalNotifier extends Notifier<Goal?> {
  @override
  Goal? build() {
    final goals = ref.watch(goalsProvider);
    return goals.isEmpty ? null : goals.first;
  }
}

final todayGoalProvider = NotifierProvider<TodayGoalNotifier, Goal?>(TodayGoalNotifier.new);

/// Thói quen nên làm tiếp: thói quen đầu tiên đến hạn hôm nay (habit_schedule.dart) mà chưa
/// hoàn thành; không còn thì lấy thói quen đầu tiên. Màn Focus dùng giá trị này.
class TodayHabitNotifier extends Notifier<Habit?> {
  @override
  Habit? build() {
    final habits = ref.watch(habitsProvider);
    final logs = ref.watch(habitLogsProvider);
    final today = ref.watch(todayProvider);

    for (final habit in habits) {
      final history = HabitHistory.of(habit, logs);
      if (history.isDueOn(today) && !history.isDone(today)) return habit;
    }
    return habits.isEmpty ? null : habits.first;
  }
}

final todayHabitProvider = NotifierProvider<TodayHabitNotifier, Habit?>(TodayHabitNotifier.new);

/// Streak chung hiện trên vòng streak; ngày nghỉ phép không làm đứt chuỗi (4.2).
final overallStreakProvider = Provider<int>((ref) {
  return HabitScience.overallStreak(
    ref.watch(habitsProvider),
    ref.watch(habitLogsProvider),
    today: ref.watch(todayProvider),
  );
});

/// 4.2 Lịch sử từng thói quen (theo id), dựng lại mỗi khi danh sách thói quen hoặc log đổi.
/// Các thẻ, lịch nhiệt và màn chi tiết dùng chung nên không phải tính lại nhiều lần.
final habitHistoriesProvider = Provider<Map<String, HabitHistory>>((ref) {
  final logs = ref.watch(habitLogsProvider);
  return {for (final habit in ref.watch(habitsProvider)) habit.id: HabitHistory.of(habit, logs)};
});

/// 4.2 Báo cáo và Thành tích dùng lịch sử của MỌI thói quen, kể cả thói quen đã ẩn
/// ("xoá nhưng giữ lịch sử"), để số lần hoàn thành không bị mất.
final allHabitHistoriesProvider = Provider<List<HabitHistory>>((ref) {
  final logs = ref.watch(habitLogsProvider);
  return [for (final habit in ref.watch(allHabitsProvider)) HabitHistory.of(habit, logs)];
});

/// 4.2 Tổng số lần hoàn thành và cấp thành tích hiện tại.
final completionTotalProvider = Provider<int>(
  (ref) => Achievements.totalCompletions(ref.watch(allHabitHistoriesProvider)),
);

final achievementLevelProvider = Provider<int>(
  (ref) => Achievements.levelFor(ref.watch(completionTotalProvider)),
);

/// 4.2 Điểm sức mạnh trung bình của các thói quen, hiện ở Trang chủ.
final averageStrengthProvider = Provider<double>((ref) {
  return HabitScience.averageStrength(
    ref.watch(habitsProvider),
    ref.watch(habitLogsProvider),
    today: ref.watch(todayProvider),
  );
});

// ---------- 5.1 Kế hoạch phiên học tiếp theo (Hôm nay) ----------

/// The user's choice for the next session only (data-model.md SessionPlanOverride).
/// Empty means "use the plan rule"; cleared when a session starts.
class SessionPlanOverride {
  const SessionPlanOverride({this.habitId, this.minutes});

  final String? habitId;
  final int? minutes;
}

class SessionPlanOverrideNotifier extends Notifier<SessionPlanOverride> {
  @override
  SessionPlanOverride build() => const SessionPlanOverride();

  /// Habit card "Bắt đầu Focus": pick the habit; its own minutes apply.
  void chooseHabit(String? habitId) => state = SessionPlanOverride(habitId: habitId);

  /// Plan sheet on Hôm nay: pick both habit and minutes.
  void choose({required String? habitId, required int? minutes}) =>
      state = SessionPlanOverride(habitId: habitId, minutes: minutes);

  void clear() => state = const SessionPlanOverride();
}

final sessionPlanOverrideProvider =
    NotifierProvider<SessionPlanOverrideNotifier, SessionPlanOverride>(
      SessionPlanOverrideNotifier.new,
    );

/// What Hôm nay proposes: goal, next habit, planned minutes and screen state
/// (pure rule in lib/data/session_plan.dart).
final sessionPlanProvider = Provider<SessionPlan>((ref) {
  final override = ref.watch(sessionPlanOverrideProvider);
  return SessionPlan.next(
    goals: ref.watch(goalsProvider),
    habits: ref.watch(habitsProvider),
    logs: ref.watch(habitLogsProvider),
    today: ref.watch(todayProvider),
    overrideHabitId: override.habitId,
    overrideMinutes: override.minutes,
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
    reactions: ref.read(reelReactionRepositoryProvider).getAll(),
    // Tính cả thói quen đã "xoá nhưng giữ lịch sử" để số ngày hoàn thành không bị mất.
    habits: ref.watch(allHabitsProvider),
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
    // Dữ liệu mẫu không phải công sức thật: lưu luôn cấp hiện tại là "đã chúc mừng" TRƯỚC khi
    // các màn tải lại, để hộp thoại chúc mừng lên cấp không bật lên.
    final logs = _ref.read(habitLogRepositoryProvider).getAll();
    final histories = [
      for (final habit in _ref.read(habitRepositoryProvider).getAll()) HabitHistory.of(habit, logs),
    ];
    await _ref
        .read(profileRepositoryProvider)
        .saveCelebratedLevel(Achievements.levelFor(Achievements.totalCompletions(histories)));
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
    _ref.invalidate(reelLikesProvider);
    _ref.invalidate(reelCommentsProvider);
  }
}

final appDataActionsProvider = Provider(AppDataActions.new);
