// 3.1 Thiết lập phiên + 3.2 Phát hiện lơ là – trạng thái của phiên học.
// Notifier sống ở cấp ứng dụng nên phiên vẫn chạy khi chuyển tab. Phần tính toán nằm trong
// FocusSessionTimer; ở đây chỉ nối nó với giao diện, Hive, bộ đếm và màn hình sáng.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/habit_progress.dart';
import '../data/models/habit.dart';
import '../data/models/session.dart';
import '../data/repositories/hive_repository.dart';
import '../services/focus_session_timer.dart';
import '../services/native_bridge.dart';
import 'app_providers.dart';

/// chưa bắt đầu → đang chạy → kết thúc.
enum FocusPhase { setup, running, finished }

/// 3.3 Tín hiệu "người dùng vừa quay lại sau một lần xao nhãng" để giao diện phản hồi.
class FocusNudge {
  const FocusNudge({required this.distractionIndex, required this.away});

  final int distractionIndex;
  final Duration away;
}

/// Ảnh chụp trạng thái phiên tại một thời điểm, để giao diện hiển thị.
class FocusSessionState {
  const FocusSessionState({
    this.phase = FocusPhase.setup,
    this.habit,
    this.plannedMinutes = 0,
    this.remaining = Duration.zero,
    this.progress = 0,
    this.focused = Duration.zero,
    this.totalAway = Duration.zero,
    this.distractionCount = 0,
    this.isPaused = false,
    this.finishedOnTime = false,
    this.nudge,
    this.breakRemaining,
    this.interventionCount = 0,
    this.breakCount = 0,
  });

  final FocusPhase phase;
  final Habit? habit;
  final int plannedMinutes;
  final Duration remaining;

  /// Tỉ lệ thời gian đã trôi qua, từ 0 đến 1.
  final double progress;
  final Duration focused;
  final Duration totalAway;
  final int distractionCount;
  final bool isPaused;

  /// True nếu phiên chạy tới hết giờ, false nếu kết thúc sớm.
  final bool finishedOnTime;

  /// Chỉ có giá trị đúng ở lần cập nhật ngay sau khi người dùng quay lại.
  final FocusNudge? nudge;

  /// 2.4 Thời gian nghỉ còn lại; null nghĩa là không đang nghỉ.
  final Duration? breakRemaining;

  /// 2.3 Số lần Reset break đã chặn trong phiên.
  final int interventionCount;

  /// 2.4 Số lần nghỉ có chủ đích trong phiên.
  final int breakCount;

  bool get isRunning => phase == FocusPhase.running;
}

/// Kết quả khi lưu phiên, để màn Tổng kết biết có hiện thông báo streak không.
class FocusSaveResult {
  const FocusSaveResult({required this.habitCompleted, required this.streakGained});

  /// Phiên này làm thói quen hôm nay chuyển từ chưa xong sang hoàn thành.
  final bool habitCompleted;

  /// Phiên này làm streak chung tăng thêm.
  final bool streakGained;
}

/// Giữ màn hình sáng. Tách thành provider để test thay được, vì plugin không chạy trong test.
final screenAwakeProvider = Provider<Future<void> Function(bool enabled)>((ref) {
  return (enabled) async {
    if (kIsWeb) return; // Bản web chỉ để xem nhanh giao diện nên không cần giữ màn hình sáng.
    try {
      await WakelockPlus.toggle(enable: enabled);
    } on Exception catch (error) {
      // Không giữ được màn hình sáng thì phiên học vẫn phải chạy bình thường.
      debugPrint('Không đổi được trạng thái giữ màn hình sáng: $error');
    }
  };
});

class FocusSessionNotifier extends Notifier<FocusSessionState> {
  /// Đếm 4 lần mỗi giây để số giây hiển thị không bị nhảy cóc. Mỗi lần chỉ đọc lại đồng hồ,
  /// không cộng dồn gì nên bộ đếm chạy lệch hay bị dừng trong nền cũng không làm sai số liệu.
  static const Duration _tickInterval = Duration(milliseconds: 250);

  FocusSessionTimer? _timer;
  Timer? _ticker;
  String? _sessionId;

  /// Đồng hồ đang dừng vì người dùng ở màn Reels, không phải do chọn nghỉ.
  bool _pausedForReels = false;

  /// 2.4 Mốc hết giờ nghỉ; null nghĩa là không đang nghỉ.
  DateTime? _breakEndsAt;

  int _interventionCount = 0;
  int _breakCount = 0;

  /// App đang bị ẩn, tức người dùng đang ở app khác.
  bool _isAppHidden = false;

  /// Trong lần rời app này người dùng đã được nhắc rồi (màn chặn, hoặc thông báo hết giờ nghỉ),
  /// nên lúc quay lại không nhắc thêm lần nữa.
  bool _remindedWhileAway = false;

  /// Lấy sẵn ở build vì Riverpod không cho dùng ref trong onDispose,
  /// mà lúc huỷ phiên vẫn phải tắt được chế độ giữ màn hình sáng.
  late Future<void> Function(bool enabled) _setScreenAwake;

  /// 7.2 Cũng lấy sẵn vì lý do trên: lúc huỷ phiên vẫn phải tắt được việc theo dõi app.
  late NativeBridge _native;

  @override
  FocusSessionState build() {
    _setScreenAwake = ref.read(screenAwakeProvider);
    _native = ref.read(nativeBridgeProvider);
    // Đổi danh sách app cần nhắc giữa phiên thì áp dụng ngay.
    ref.listen(blockedAppsProvider, (_, _) {
      if (state.isRunning) unawaited(_syncGuard());
    });
    ref.onDispose(_stopBackgroundWork);
    return const FocusSessionState();
  }

  /// Bắt đầu phiên mới. Đang có phiên thì không làm gì: không bao giờ tạo phiên chồng lên nhau.
  void start({required Habit habit, required int minutes}) {
    if (state.phase != FocusPhase.setup) return;

    final isDemo = ref.read(profileProvider)?.demoMode ?? false;
    _timer = FocusSessionTimer(
      planned: Duration(minutes: minutes),
      clock: ref.read(clockProvider),
      timeScale: isDemo ? FocusSessionTimer.demoTimeScale : 1,
    );
    _sessionId = newId();
    _clearSessionMarks();
    _ticker = Timer.periodic(_tickInterval, (_) => tick());
    _setScreenAwake(true);
    state = _snapshot(habit: habit, minutes: minutes, phase: FocusPhase.running);
    unawaited(_syncGuard());
  }

  /// Bắt đầu với thói quen hôm nay, dùng khi mở Focus kèm số phút. Chưa có thói quen thì thôi,
  /// màn Focus sẽ hiện bước thiết lập.
  void startWithTodayHabit(int minutes) {
    final habit = ref.read(todayHabitProvider);
    if (habit != null) start(habit: habit, minutes: minutes);
  }

  /// Đọc lại đồng hồ và cập nhật giao diện; hết giờ thì kết thúc phiên.
  void tick() {
    final timer = _timer;
    if (timer == null || !state.isRunning) return;

    // Service thường báo hết giờ nghỉ trước. Mốc này để phòng khi không có service nào báo,
    // ví dụ học không cần Reset break mà vẫn chọn "Nghỉ 5 phút" trên sheet nhắc.
    final breakEndsAt = _breakEndsAt;
    if (breakEndsAt != null && !ref.read(clockProvider)().isBefore(breakEndsAt)) _endBreak(timer);

    if (timer.isTimeUp) {
      _finish(onTime: true);
    } else {
      state = _snapshot();
    }
  }

  // ---------- 3.2 Phát hiện lơ là ----------

  void onAppHidden() {
    _isAppHidden = true;
    if (state.isRunning) _timer?.leave();
  }

  void onAppResumed() {
    _isAppHidden = false;
    final wasReminded = _remindedWhileAway;
    _remindedWhileAway = false;

    final timer = _timer;
    if (timer == null || !state.isRunning) return;

    final result = timer.comeBack();
    if (result != null) _logDistraction(result);

    if (timer.isTimeUp) {
      _finish(onTime: true);
    } else if (result != null && !wasReminded) {
      state = _snapshot(
        nudge: FocusNudge(distractionIndex: result.distractionIndex, away: result.away),
      );
    } else {
      state = _snapshot();
    }
  }

  void _logDistraction(FocusReturn result) {
    ref
        .read(eventRepositoryProvider)
        .logSessionDistracted(
          awaySeconds: result.away.inSeconds,
          distractionIndex: result.distractionIndex,
        );
  }

  // ---------- Tạm dừng ----------

  /// 3.3 Xem reel trong phiên: đồng hồ dừng, không tính xao nhãng cũng không tính tập trung.
  void setWatchingReels(bool isWatching) {
    final timer = _timer;
    if (timer == null || !state.isRunning) return;

    if (isWatching && !timer.isPaused) {
      _pausedForReels = true;
      _pause(timer);
    } else if (!isWatching && _pausedForReels) {
      _pausedForReels = false;
      _resume(timer);
    }
  }

  /// 3.3 Người dùng chọn nghỉ trên sheet nhắc trong app: báo service chuyển sang chế độ nghỉ.
  void takeBreak({required int minutes}) {
    if (_beginBreak(minutes)) unawaited(_native.startBreak(minutes));
  }

  /// 2.4 Người dùng bấm "Tiếp tục" trong lúc nghỉ: báo service về chế độ chặn.
  void resumeFromBreak() {
    final timer = _timer;
    if (timer == null || !state.isRunning || _breakEndsAt == null) return;
    _endBreak(timer);
    unawaited(_native.endBreak());
  }

  // ---------- 2.3, 2.4 Hành động từ màn can thiệp và service ----------

  /// 2.3 Màn chặn vừa hiện.
  void onInterventionShown() {
    if (_timer == null || !state.isRunning) return;
    _interventionCount++;
    _remindedWhileAway = true;
    state = _snapshot();
  }

  /// 2.4 Người dùng đã chọn nghỉ ngay trên màn chặn, service đã ở chế độ nghỉ rồi.
  void onBreakStarted(int minutes) => _beginBreak(minutes);

  /// 2.4 Service báo hết giờ nghỉ.
  void onBreakEnded() {
    final timer = _timer;
    if (timer != null && state.isRunning && _breakEndsAt != null) _endBreak(timer);
  }

  /// Dừng đồng hồ để nghỉ. Trả về false nếu không có gì để nghỉ, hoặc đang nghỉ rồi.
  bool _beginBreak(int minutes) {
    final timer = _timer;
    if (timer == null || !state.isRunning || _breakEndsAt != null) return false;

    // Đoạn đã ở ngoài trước lúc chọn nghỉ vẫn là 1 lần xao nhãng; thời gian nghỉ thì không.
    final closing = timer.comeBack();
    if (closing != null) _logDistraction(closing);

    _pausedForReels = false; // Đang xem reel mà chọn nghỉ thì từ giờ đây là giờ nghỉ.
    _breakEndsAt = ref.read(clockProvider)().add(Duration(minutes: minutes) ~/ timer.timeScale);
    _breakCount++;
    _pause(timer);
    return true;
  }

  void _endBreak(FocusSessionTimer timer) {
    _breakEndsAt = null;
    _resume(timer);
    // Hết giờ nghỉ mà chưa quay lại thì từ lúc này tính là đang rời app, như mọi lần rời app khác.
    // Người dùng đã được thông báo nhắc rồi nên lúc quay lại không nhắc thêm.
    if (_isAppHidden) {
      timer.leave();
      _remindedWhileAway = true;
    }
  }

  void _clearSessionMarks() {
    _pausedForReels = false;
    _breakEndsAt = null;
    _interventionCount = 0;
    _breakCount = 0;
    _remindedWhileAway = false;
  }

  void _pause(FocusSessionTimer timer) {
    timer.pause();
    _setScreenAwake(false);
    state = _snapshot();
  }

  void _resume(FocusSessionTimer timer) {
    timer.resume();
    _setScreenAwake(true);
    state = _snapshot();
  }

  // ---------- 7.2 Theo dõi app đang mở ----------

  /// Số thứ tự của lệnh mới nhất. Kiểm tra quyền mất một lúc, trong lúc đó phiên có thể đã kết thúc,
  /// đã chuyển sang nghỉ hoặc danh sách app đã đổi, nên lệnh nào không còn mới nhất thì tự bỏ.
  int _latestGuardRequest = 0;

  /// Bật theo dõi nếu đủ quyền và có app cần nhắc. Thiếu quyền thì phiên học vẫn chạy bình thường.
  Future<void> _syncGuard() async {
    final blocked = ref.read(blockedAppsProvider);
    if (blocked.isEmpty) {
      _stopGuard();
      return;
    }

    final request = ++_latestGuardRequest;
    final timeScale = _timer?.timeScale ?? 1;
    final permissions = await _native.checkPermissions();
    if (request == _latestGuardRequest && permissions.canGuard) {
      await _native.startGuard(blocked.toList(), timeScale: timeScale);
    }
  }

  void _stopGuard() {
    _latestGuardRequest++;
    unawaited(_native.stopGuard());
  }

  // ---------- Kết thúc ----------

  /// Kết thúc sớm: phiên vẫn được giữ với thời gian thực tế.
  void finishEarly() {
    if (state.isRunning) _finish(onTime: false);
  }

  void _finish({required bool onTime}) {
    final closing = _timer!.finish();
    if (closing != null) _logDistraction(closing);

    _breakEndsAt = null;
    _stopBackgroundWork();
    state = _snapshot(phase: FocusPhase.finished, finishedOnTime: onTime);
  }

  /// Tắt mọi thứ chỉ cần trong lúc học: bộ đếm, giữ màn hình sáng, theo dõi app.
  void _stopBackgroundWork() {
    _ticker?.cancel();
    _ticker = null;
    _setScreenAwake(false);
    _stopGuard();
  }

  /// 3.4 Lưu phiên rồi cập nhật thói quen và streak. Gọi lại nhiều lần cũng không bị tính trùng,
  /// vì id phiên không đổi.
  Future<FocusSaveResult> save({int? rating, String note = ''}) async {
    final timer = _timer!;
    final habit = state.habit!;
    final today = ref.read(todayProvider);
    final wasDone = HabitProgress.isDone(habit, today, ref.read(habitLogsProvider));
    final streakBefore = ref.read(overallStreakProvider);

    final session = Session(
      id: _sessionId!,
      habitId: habit.id,
      start: timer.startedAt,
      end: timer.endedAt,
      plannedMinutes: state.plannedMinutes,
      focusedSeconds: state.focused.inSeconds,
      distractionCount: state.distractionCount,
      awaySeconds: state.totalAway.inSeconds,
      selfRating: rating,
      note: note,
    );
    await ref.read(sessionRepositoryProvider).save(session);
    await ref.read(habitLogsProvider.notifier).recordSession(session);

    final isDone = HabitProgress.isDone(habit, today, ref.read(habitLogsProvider));
    return FocusSaveResult(
      habitCompleted: isDone && !wasDone,
      streakGained: ref.read(overallStreakProvider) > streakBefore,
    );
  }

  /// Về lại bước thiết lập, sẵn sàng cho phiên tiếp theo.
  void reset() {
    _stopBackgroundWork();
    _timer = null;
    _sessionId = null;
    _clearSessionMarks();
    state = const FocusSessionState();
  }

  FocusSessionState _snapshot({
    Habit? habit,
    int? minutes,
    FocusPhase? phase,
    bool finishedOnTime = false,
    FocusNudge? nudge,
  }) {
    final timer = _timer!;
    final breakEndsAt = _breakEndsAt;
    return FocusSessionState(
      breakRemaining: breakEndsAt == null ? null : _breakTimeLeft(breakEndsAt, timer),
      interventionCount: _interventionCount,
      breakCount: _breakCount,
      phase: phase ?? state.phase,
      habit: habit ?? state.habit,
      plannedMinutes: minutes ?? state.plannedMinutes,
      remaining: timer.remaining,
      progress: timer.progress,
      focused: timer.focused,
      totalAway: timer.totalAway,
      distractionCount: timer.distractionCount,
      isPaused: timer.isPaused,
      finishedOnTime: finishedOnTime,
      nudge: nudge,
    );
  }

  /// Thời gian nghỉ còn lại, theo cùng thang thời gian với đồng hồ của phiên.
  Duration _breakTimeLeft(DateTime breakEndsAt, FocusSessionTimer timer) {
    final left = breakEndsAt.difference(ref.read(clockProvider)()) * timer.timeScale;
    return left.isNegative ? Duration.zero : left;
  }
}

final focusSessionProvider = NotifierProvider<FocusSessionNotifier, FocusSessionState>(
  FocusSessionNotifier.new,
);
