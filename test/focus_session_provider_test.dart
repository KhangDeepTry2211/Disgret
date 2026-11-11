// 3.1–3.4, 7.2 Kiểm thử FocusSessionNotifier: trạng thái phiên, lưu phiên, thói quen, streak
// và việc bật tắt theo dõi app.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/event.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/habit_log.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/event_repository.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_log_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/data/repositories/session_repository.dart';
import 'package:focus_app/providers/app_providers.dart';
import 'package:focus_app/providers/focus_session_provider.dart';
import 'package:focus_app/services/focus_session_timer.dart';
import 'package:hive/hive.dart';

import 'test_helpers.dart';

const Habit _habit = Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 25);
const Habit _otherHabit = Habit(id: 'h2', goalId: 'g1', name: 'Bài tập', minMinutesPerDay: 25);

void main() {
  late DateTime now;
  late ProviderContainer container;
  late List<bool> screenAwakeCalls;
  late FakeNativeBridge native;

  void wait(Duration duration) => now = now.add(duration);

  FocusSessionNotifier notifier() => container.read(focusSessionProvider.notifier);
  FocusSessionState state() => container.read(focusSessionProvider);

  setUp(() async {
    await openMemoryBoxes();
    now = DateTime(2026, 3, 2, 9);
    screenAwakeCalls = [];
    native = FakeNativeBridge();
    await GoalRepository().save(const Goal(id: 'g1', title: 'Mục tiêu', reason: 'Lý do'));
    await HabitRepository().save(_habit);
    await HabitRepository().save(_otherHabit);
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        screenAwakeProvider.overrideWithValue((enabled) async => screenAwakeCalls.add(enabled)),
        nativeBridgeProvider.overrideWithValue(native),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
  });

  group('7.2 Theo dõi app đang mở trong phiên', () {
    /// Chờ các lệnh gửi xuống native chạy xong.
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('Bắt đầu phiên thì bật theo dõi với danh sách app cần nhắc', () async {
      await container
          .read(blockedAppsProvider.notifier)
          .setBlocked('com.example.game', blocked: true);

      notifier().start(habit: _habit, minutes: 25);
      await settle();

      expect(native.guardStarts.single, contains('com.example.game'));
      expect(native.guardStarts.single, contains('com.google.android.youtube'));
      expect(native.isGuarding, isTrue);
    });

    test('Thiếu quyền thì không bật theo dõi nhưng phiên vẫn chạy', () async {
      native.overlay = false;

      notifier().start(habit: _habit, minutes: 25);
      await settle();

      expect(native.guardStarts, isEmpty);
      expect(state().phase, FocusPhase.running);
    });

    test('Chỉ thiếu quyền thông báo thì vẫn bật theo dõi', () async {
      native.notification = false;

      notifier().start(habit: _habit, minutes: 25);
      await settle();

      expect(native.guardStarts, hasLength(1));
    });

    test('Không có app nào cần nhắc thì không bật theo dõi', () async {
      final blockedApps = container.read(blockedAppsProvider.notifier);
      for (final package in container.read(blockedAppsProvider).toList()) {
        await blockedApps.setBlocked(package, blocked: false);
      }

      notifier().start(habit: _habit, minutes: 25);
      await settle();

      expect(native.guardStarts, isEmpty);
    });

    test('Hết giờ thì tắt theo dõi', () async {
      notifier().start(habit: _habit, minutes: 25);
      await settle();

      wait(const Duration(minutes: 25));
      notifier().tick();

      expect(native.isGuarding, isFalse);
    });

    test('Kết thúc sớm thì tắt theo dõi', () async {
      notifier().start(habit: _habit, minutes: 25);
      await settle();

      notifier().finishEarly();

      expect(native.isGuarding, isFalse);
    });

    test('Đặt lại phiên thì tắt theo dõi', () async {
      notifier().start(habit: _habit, minutes: 25);
      await settle();

      notifier().reset();

      expect(native.isGuarding, isFalse);
    });

    test('Huỷ phiên khi xoá toàn bộ dữ liệu thì tắt theo dõi', () async {
      notifier().start(habit: _habit, minutes: 25);
      await settle();

      container.invalidate(focusSessionProvider);
      container.read(focusSessionProvider);

      expect(native.isGuarding, isFalse);
    });

    test('Phiên kết thúc trong lúc chờ kiểm tra quyền thì không bật theo dõi', () async {
      native.permissionsGate = Completer<void>();

      notifier().start(habit: _habit, minutes: 25);
      notifier().finishEarly();
      native.permissionsGate!.complete();
      await settle();

      expect(native.guardStarts, isEmpty);
      expect(native.isGuarding, isFalse);
    });

    test(
      'Nghỉ từ sheet: service chuyển chế độ chứ không tắt, học tiếp thì về chế độ chặn',
      () async {
        notifier().start(habit: _habit, minutes: 25);
        await settle();

        notifier().takeBreak(minutes: 5);
        await settle();
        expect(native.breakStarts, [5]);
        expect(
          native.isGuarding,
          isTrue,
          reason: 'Service phải sống để giữ số lần chặn trong phiên',
        );

        notifier().resumeFromBreak();
        await settle();
        expect(native.breakEnds, 1);
        expect(native.guardStarts, hasLength(1), reason: 'Không khởi động lại service');
      },
    );

    test('Xem reel trong phiên vẫn giữ theo dõi', () async {
      notifier().start(habit: _habit, minutes: 25);
      await settle();

      notifier().setWatchingReels(true);
      await settle();

      expect(native.isGuarding, isTrue);
    });

    test('Đổi danh sách app giữa phiên thì áp dụng ngay', () async {
      notifier().start(habit: _habit, minutes: 25);
      await settle();

      await container
          .read(blockedAppsProvider.notifier)
          .setBlocked('com.example.game', blocked: true);
      await settle();

      expect(native.guardStarts, hasLength(2));
      expect(native.guardStarts.last, contains('com.example.game'));
    });

    test('Tắt hết app giữa phiên thì tắt theo dõi', () async {
      notifier().start(habit: _habit, minutes: 25);
      await settle();

      final blockedApps = container.read(blockedAppsProvider.notifier);
      for (final package in container.read(blockedAppsProvider).toList()) {
        await blockedApps.setBlocked(package, blocked: false);
      }
      await settle();

      expect(native.isGuarding, isFalse);
    });

    test('Đổi danh sách app lúc đang nghỉ thì service cập nhật, phiên vẫn đang nghỉ', () async {
      notifier().start(habit: _habit, minutes: 25);
      await settle();
      notifier().takeBreak(minutes: 5);

      await container
          .read(blockedAppsProvider.notifier)
          .setBlocked('com.example.game', blocked: true);
      await settle();

      expect(native.guardStarts.last, contains('com.example.game'));
      expect(state().isPaused, isTrue);
      expect(state().breakRemaining, isNotNull);
    });

    test('Chế độ demo truyền hệ số thời gian xuống service', () async {
      await ProfileRepository().saveProfile(
        const UserProfile(motivationTypes: [], preferredReelLength: 30, demoMode: true),
      );

      notifier().start(habit: _habit, minutes: 25);
      await settle();

      expect(native.lastTimeScale, FocusSessionTimer.demoTimeScale);
    });

    test('Đổi danh sách app liên tiếp thì lệnh cuối cùng có hiệu lực', () async {
      notifier().start(habit: _habit, minutes: 25);
      await settle();

      final blockedApps = container.read(blockedAppsProvider.notifier);
      // Không chờ giữa các lần đổi: lệnh trước vẫn đang kiểm tra quyền khi lệnh sau tới.
      final pending = [
        blockedApps.setBlocked('com.example.a', blocked: true),
        blockedApps.setBlocked('com.example.b', blocked: true),
      ];
      await Future.wait(pending);
      await settle();

      expect(native.guardStarts.last, containsAll(<String>['com.example.a', 'com.example.b']));
    });

    test('Đổi danh sách app khi không có phiên thì không bật theo dõi', () async {
      container.read(focusSessionProvider);

      await container
          .read(blockedAppsProvider.notifier)
          .setBlocked('com.example.game', blocked: true);
      await settle();

      expect(native.guardStarts, isEmpty);
    });
  });

  group('Vòng đời phiên', () {
    test('Chưa bắt đầu → đang chạy → kết thúc', () {
      expect(state().phase, FocusPhase.setup);

      notifier().start(habit: _habit, minutes: 25);
      expect(state().phase, FocusPhase.running);
      expect(state().plannedMinutes, 25);
      expect(state().habit?.id, 'h1');
      expect(state().remaining, const Duration(minutes: 25));

      wait(const Duration(minutes: 25));
      notifier().tick();
      expect(state().phase, FocusPhase.finished);
      expect(state().finishedOnTime, isTrue);
      expect(state().remaining, Duration.zero);
    });

    test('Bộ đếm chỉ đọc lại đồng hồ: bỏ lỡ nhiều nhịp vẫn đúng', () {
      notifier().start(habit: _habit, minutes: 25);
      wait(const Duration(minutes: 10));

      notifier().tick();

      expect(state().remaining, const Duration(minutes: 15));
      expect(state().focused, const Duration(minutes: 10));
      expect(state().progress, closeTo(0.4, 0.001));
    });

    test('Đang có phiên thì không tạo phiên mới chồng lên', () {
      notifier().start(habit: _habit, minutes: 25);
      wait(const Duration(minutes: 1));

      notifier().start(habit: _otherHabit, minutes: 5);
      notifier().startWithTodayHabit(5);
      notifier().tick();

      expect(state().habit?.id, 'h1');
      expect(state().plannedMinutes, 25);
      expect(state().remaining, const Duration(minutes: 24));
    });

    test('Mở kèm số phút: dùng thói quen hôm nay, là thói quen đầu tiên chưa làm', () async {
      await container.read(habitLogsProvider.notifier).setDoneToday(_habit, done: true);

      notifier().startWithTodayHabit(5);

      expect(state().phase, FocusPhase.running);
      expect(state().habit?.id, 'h2');
      expect(state().plannedMinutes, 5);
    });

    test('Chưa có thói quen nào thì không bắt đầu được, ở lại bước thiết lập', () async {
      await container.read(habitsProvider.notifier).remove('h1');
      await container.read(habitsProvider.notifier).remove('h2');

      notifier().startWithTodayHabit(5);

      expect(state().phase, FocusPhase.setup);
    });

    test('Giữ màn hình sáng khi chạy, tắt khi kết thúc', () {
      notifier().start(habit: _habit, minutes: 25);
      expect(screenAwakeCalls.last, isTrue);

      notifier().finishEarly();
      expect(screenAwakeCalls.last, isFalse);
    });

    test('Kết thúc sớm: giữ thời gian thực tế, không phải hết giờ', () {
      notifier().start(habit: _habit, minutes: 25);
      wait(const Duration(minutes: 7));

      notifier().finishEarly();

      expect(state().phase, FocusPhase.finished);
      expect(state().finishedOnTime, isFalse);
      expect(state().focused, const Duration(minutes: 7));
    });

    test('Đặt lại thì về bước thiết lập, bắt đầu được phiên mới', () {
      notifier().start(habit: _habit, minutes: 25);
      notifier().finishEarly();
      notifier().reset();
      expect(state().phase, FocusPhase.setup);

      notifier().start(habit: _otherHabit, minutes: 5);
      expect(state().phase, FocusPhase.running);
      expect(state().distractionCount, 0);
    });
  });

  group('Phát hiện lơ là', () {
    test('Rời ≥ 3 giây: tính xao nhãng, báo cho giao diện và ghi sự kiện', () {
      notifier().start(habit: _habit, minutes: 25);
      wait(const Duration(minutes: 1));

      notifier().onAppHidden();
      wait(const Duration(seconds: 42));
      notifier().onAppResumed();

      expect(state().distractionCount, 1);
      expect(state().nudge?.distractionIndex, 1);
      expect(state().nudge?.away, const Duration(seconds: 42));
      expect(state().totalAway, const Duration(seconds: 42));
      expect(state().focused, const Duration(minutes: 1));

      final event = EventRepository().getAll().single;
      expect(event.type, EventType.sessionDistracted);
      expect(event.toMap()['type'], 'session_distracted');
      expect(event.meta, {'awaySeconds': 42, 'distractionIndex': 1});
    });

    test('Rời dưới 3 giây: không báo gì, không ghi sự kiện', () {
      notifier().start(habit: _habit, minutes: 25);

      notifier().onAppHidden();
      wait(const Duration(seconds: 2));
      notifier().onAppResumed();

      expect(state().distractionCount, 0);
      expect(state().nudge, isNull);
      expect(EventRepository().getAll(), isEmpty);
    });

    test('Lời nhắc chỉ có ở đúng lần cập nhật sau khi quay lại', () {
      notifier().start(habit: _habit, minutes: 25);
      notifier().onAppHidden();
      wait(const Duration(seconds: 10));
      notifier().onAppResumed();
      expect(state().nudge, isNotNull);

      notifier().tick();
      expect(state().nudge, isNull);
    });

    test('Chưa bắt đầu phiên thì ẩn app không có tác dụng gì', () {
      notifier().onAppHidden();
      wait(const Duration(minutes: 5));
      notifier().onAppResumed();

      expect(state().phase, FocusPhase.setup);
      expect(EventRepository().getAll(), isEmpty);
    });

    test('Hết giờ khi đang ở ngoài: quay lại thì kết thúc luôn, không nhắc, vẫn ghi sự kiện', () {
      notifier().start(habit: _habit, minutes: 5);
      wait(const Duration(minutes: 4));
      notifier().onAppHidden();
      wait(const Duration(minutes: 30));

      notifier().onAppResumed();

      expect(state().phase, FocusPhase.finished);
      expect(state().finishedOnTime, isTrue);
      expect(state().nudge, isNull);
      expect(state().focused, const Duration(minutes: 4));
      expect(state().totalAway, const Duration(minutes: 1));
      expect(EventRepository().getAll().single.meta['awaySeconds'], 30 * 60);
    });

    test('Bộ đếm phát hiện hết giờ trong nền cũng khép lại lần rời đi', () {
      notifier().start(habit: _habit, minutes: 5);
      wait(const Duration(minutes: 4));
      notifier().onAppHidden();
      wait(const Duration(minutes: 1));

      notifier().tick();

      expect(state().phase, FocusPhase.finished);
      expect(state().distractionCount, 1);
      expect(EventRepository().getAll(), hasLength(1));
    });
  });

  group('Tạm dừng', () {
    test('Xem reel: đồng hồ dừng, không tính xao nhãng; rời Reels thì chạy tiếp', () {
      notifier().start(habit: _habit, minutes: 25);
      wait(const Duration(minutes: 5));

      notifier().setWatchingReels(true);
      expect(state().isPaused, isTrue);
      wait(const Duration(minutes: 3));
      notifier().tick();
      expect(state().remaining, const Duration(minutes: 20));

      notifier().setWatchingReels(false);
      expect(state().isPaused, isFalse);
      wait(const Duration(minutes: 1));
      notifier().tick();

      expect(state().remaining, const Duration(minutes: 19));
      expect(state().focused, const Duration(minutes: 6));
      expect(state().distractionCount, 0);
    });

    test('Rời app khi đang xem reel không tính là xao nhãng', () {
      notifier().start(habit: _habit, minutes: 25);
      notifier().setWatchingReels(true);

      notifier().onAppHidden();
      wait(const Duration(minutes: 2));
      notifier().onAppResumed();

      expect(state().distractionCount, 0);
      expect(state().nudge, isNull);
    });

    test('Đang nghỉ mà đi qua tab Reels thì vẫn đang nghỉ, không tự chạy lại', () {
      notifier().start(habit: _habit, minutes: 25);
      notifier().takeBreak(minutes: 5);

      notifier().setWatchingReels(true);
      notifier().setWatchingReels(false);

      expect(state().isPaused, isTrue);

      notifier().resumeFromBreak();
      expect(state().isPaused, isFalse);
    });

    test('Không có phiên thì vào tab Reels không ảnh hưởng gì', () {
      notifier().setWatchingReels(true);
      notifier().setWatchingReels(false);
      expect(state().phase, FocusPhase.setup);
    });
  });

  group('2.3 Quay lại từ màn chặn', () {
    /// Rời app, màn chặn hiện, rồi quay lại sau khoảng thời gian cho trước.
    void blockedFor(Duration duration) {
      notifier().onAppHidden();
      notifier().onInterventionShown();
      wait(duration);
      notifier().onAppResumed();
    }

    test('Vẫn tính 1 lần xao nhãng nhưng không nhắc thêm, kể cả từ lần thứ 2', () {
      notifier().start(habit: _habit, minutes: 25);

      blockedFor(const Duration(seconds: 20));
      expect(state().distractionCount, 1);
      expect(state().totalAway, const Duration(seconds: 20));
      expect(state().nudge, isNull);

      blockedFor(const Duration(seconds: 20));
      expect(state().distractionCount, 2);
      expect(state().nudge, isNull);
    });

    test('Chỉ bỏ nhắc cho đúng lần rời app đó, lần rời app thường sau đó vẫn nhắc', () {
      notifier().start(habit: _habit, minutes: 25);
      blockedFor(const Duration(seconds: 20));

      notifier().onAppHidden();
      wait(const Duration(seconds: 20));
      notifier().onAppResumed();

      expect(state().distractionCount, 2);
      expect(state().nudge?.distractionIndex, 2);
    });

    test('Đếm số lần chặn trong phiên, phiên mới đếm lại từ đầu', () {
      notifier().start(habit: _habit, minutes: 25);
      blockedFor(const Duration(seconds: 20));
      blockedFor(const Duration(seconds: 20));
      expect(state().interventionCount, 2);

      notifier().finishEarly();
      expect(state().interventionCount, 2, reason: 'Màn Tổng kết còn cần số này');

      notifier().reset();
      notifier().start(habit: _habit, minutes: 25);
      expect(state().interventionCount, 0);
    });

    test('Không có phiên thì bỏ qua', () {
      notifier().onInterventionShown();
      expect(state().interventionCount, 0);
      expect(state().phase, FocusPhase.setup);
    });
  });

  group('2.4 Nghỉ có chủ đích', () {
    /// Đang học thì mở app bị chặn, chờ ở màn chặn rồi chọn nghỉ.
    void chooseBreakOnBlockScreen({int minutes = 5}) {
      notifier().onAppHidden();
      notifier().onInterventionShown();
      wait(const Duration(seconds: 15));
      notifier().onBreakStarted(minutes);
    }

    test('Đoạn trước lúc chọn nghỉ là 1 lần xao nhãng, thời gian nghỉ thì không', () {
      notifier().start(habit: _habit, minutes: 25);
      wait(const Duration(minutes: 1));

      chooseBreakOnBlockScreen();
      expect(state().isPaused, isTrue);
      expect(state().breakCount, 1);
      expect(state().distractionCount, 1);
      expect(state().totalAway, const Duration(seconds: 15));

      final remaining = state().remaining;
      wait(const Duration(minutes: 3));
      notifier().tick();

      expect(state().remaining, remaining, reason: 'Đồng hồ của phiên đứng yên');
      expect(state().distractionCount, 1);
      expect(state().totalAway, const Duration(seconds: 15));
      expect(state().breakRemaining, const Duration(minutes: 2));
    });

    test('Đang nghỉ mà ra vào DisGret thì không tính xao nhãng, không nhắc', () {
      notifier().start(habit: _habit, minutes: 25);
      chooseBreakOnBlockScreen();

      notifier().onAppResumed();
      wait(const Duration(seconds: 30));
      notifier().onAppHidden();
      wait(const Duration(seconds: 30));
      notifier().onAppResumed();

      expect(state().distractionCount, 1);
      expect(state().nudge, isNull);
    });

    test(
      'Hết giờ khi đang ở app khác: đồng hồ chạy tiếp, phần quá giờ tính là ở ngoài, không nhắc',
      () {
        notifier().start(habit: _habit, minutes: 25);
        chooseBreakOnBlockScreen();
        wait(const Duration(minutes: 5));

        notifier().onBreakEnded();
        expect(state().isPaused, isFalse);
        expect(state().breakRemaining, isNull);

        wait(const Duration(minutes: 1));
        notifier().onAppResumed();

        expect(state().distractionCount, 2);
        expect(state().totalAway, const Duration(minutes: 1, seconds: 15));
        expect(state().nudge, isNull);
      },
    );

    test('Hết giờ khi đang ở trong DisGret: học tiếp ngay, không tính xao nhãng', () {
      notifier().start(habit: _habit, minutes: 25);
      notifier().takeBreak(minutes: 5);
      wait(const Duration(minutes: 5));

      notifier().onBreakEnded();
      wait(const Duration(minutes: 1));
      notifier().tick();

      expect(state().isPaused, isFalse);
      expect(state().distractionCount, 0);
      expect(state().focused, const Duration(minutes: 1));
    });

    test('Không có service báo hết giờ thì tự hết theo đồng hồ', () {
      native.overlay = false;
      notifier().start(habit: _habit, minutes: 25);
      notifier().takeBreak(minutes: 5);

      wait(const Duration(minutes: 4));
      notifier().tick();
      expect(state().isPaused, isTrue);

      wait(const Duration(minutes: 1));
      notifier().tick();
      expect(state().isPaused, isFalse);
      expect(state().breakRemaining, isNull);
    });

    test(
      'Bấm "Tiếp tục" trước giờ thì báo service; thông báo hết giờ tới muộn không ảnh hưởng',
      () {
        notifier().start(habit: _habit, minutes: 25);
        notifier().takeBreak(minutes: 5);
        wait(const Duration(minutes: 1));

        notifier().resumeFromBreak();
        expect(native.breakEnds, 1);
        expect(state().isPaused, isFalse);

        notifier().setWatchingReels(true);
        notifier().onBreakEnded();
        expect(
          state().isPaused,
          isTrue,
          reason: 'Đồng hồ đang dừng vì xem reel, không phải vì nghỉ',
        );
      },
    );

    test('Không đang nghỉ thì "Tiếp tục" không làm gì', () {
      notifier().start(habit: _habit, minutes: 25);
      notifier().setWatchingReels(true);

      notifier().resumeFromBreak();

      expect(state().isPaused, isTrue);
      expect(native.breakEnds, 0);
    });

    test('Đang xem reel mà chọn nghỉ: chuyển thành giờ nghỉ, hết giờ thì đồng hồ chạy tiếp', () {
      notifier().start(habit: _habit, minutes: 25);
      notifier().setWatchingReels(true);
      notifier().onAppHidden();

      notifier().onBreakStarted(5);
      expect(state().breakRemaining, const Duration(minutes: 5));
      expect(state().distractionCount, 0);

      notifier().onBreakEnded();
      expect(state().isPaused, isFalse);
    });

    test('Chế độ demo: giờ nghỉ cũng nhanh gấp 3 lần', () async {
      await ProfileRepository().saveProfile(
        const UserProfile(motivationTypes: [], preferredReelLength: 30, demoMode: true),
      );
      notifier().start(habit: _habit, minutes: 25);

      notifier().takeBreak(minutes: 5);
      wait(const Duration(seconds: 50));
      notifier().tick();
      expect(state().breakRemaining, const Duration(minutes: 2, seconds: 30));

      wait(const Duration(seconds: 50));
      notifier().tick();
      expect(state().isPaused, isFalse, reason: '5 phút demo chỉ dài 100 giây thật');
    });

    test('Kết thúc sớm trong lúc nghỉ: thời gian nghỉ không tính vào tập trung', () {
      notifier().start(habit: _habit, minutes: 25);
      wait(const Duration(minutes: 2));
      notifier().takeBreak(minutes: 5);
      wait(const Duration(minutes: 3));

      notifier().finishEarly();

      expect(state().phase, FocusPhase.finished);
      expect(state().focused, const Duration(minutes: 2));
      expect(state().breakRemaining, isNull);
      expect(state().breakCount, 1);
      expect(native.isGuarding, isFalse);
    });

    test('Đang nghỉ rồi thì chọn nghỉ lần nữa không đếm thêm', () {
      notifier().start(habit: _habit, minutes: 25);
      notifier().takeBreak(minutes: 5);
      notifier().onBreakStarted(10);

      expect(state().breakCount, 1);
      expect(state().breakRemaining, const Duration(minutes: 5));
    });

    test('Không có phiên thì bỏ qua', () {
      notifier().onBreakStarted(5);
      notifier().onBreakEnded();
      notifier().takeBreak(minutes: 5);

      expect(state().phase, FocusPhase.setup);
      expect(native.breakStarts, isEmpty);
    });
  });

  group('Lưu phiên', () {
    test('Lưu đủ số liệu thật vào SessionRepository', () async {
      notifier().start(habit: _habit, minutes: 25);
      wait(const Duration(minutes: 5));
      notifier().onAppHidden();
      wait(const Duration(minutes: 1));
      notifier().onAppResumed();
      wait(const Duration(minutes: 19));
      notifier().tick();

      await notifier().save(rating: 4, note: 'Tốt');

      final session = SessionRepository().getAll().single;
      expect(session.habitId, 'h1');
      expect(session.start, DateTime(2026, 3, 2, 9));
      expect(session.end, DateTime(2026, 3, 2, 9, 25));
      expect(session.plannedMinutes, 25);
      expect(session.focusedSeconds, 24 * 60);
      expect(session.distractionCount, 1);
      expect(session.awaySeconds, 60);
      expect(session.selfRating, 4);
      expect(session.note, 'Tốt');
    });

    test('Ghi log focus với số phút tập trung thực', () async {
      notifier().start(habit: _habit, minutes: 25);
      wait(const Duration(minutes: 12, seconds: 30));
      notifier().finishEarly();

      await notifier().save();

      final log = HabitLogRepository().getAll().single;
      expect(log.source, HabitLogSource.focus);
      expect(log.habitId, 'h1');
      expect(log.minutes, 12);
      expect(SessionRepository().getAll().single.selfRating, isNull);
    });

    test('Đủ phút tối thiểu: thói quen hoàn thành và streak tăng', () async {
      notifier().start(habit: _habit, minutes: 25);
      wait(const Duration(minutes: 25));
      notifier().tick();

      final result = await notifier().save();

      expect(result.habitCompleted, isTrue);
      expect(result.streakGained, isTrue);
      expect(container.read(overallStreakProvider), 1);
    });

    test('Chưa đủ phút tối thiểu: chưa hoàn thành, streak không đổi', () async {
      notifier().start(habit: _habit, minutes: 5);
      wait(const Duration(minutes: 5));
      notifier().tick();

      final result = await notifier().save();

      expect(result.habitCompleted, isFalse);
      expect(result.streakGained, isFalse);
      expect(container.read(overallStreakProvider), 0);
    });

    test('Nhiều phiên ngắn cộng lại đủ phút thì phiên cuối làm hoàn thành', () async {
      notifier().start(habit: _habit, minutes: 15);
      wait(const Duration(minutes: 15));
      notifier().tick();
      expect((await notifier().save()).habitCompleted, isFalse);
      notifier().reset();

      notifier().start(habit: _habit, minutes: 10);
      wait(const Duration(minutes: 10));
      notifier().tick();
      expect((await notifier().save()).habitCompleted, isTrue);
    });

    test('Thói quen xong nhưng hôm nay đã có streak từ thói quen khác: không báo +1', () async {
      await container.read(habitLogsProvider.notifier).setDoneToday(_otherHabit, done: true);
      expect(container.read(overallStreakProvider), 1);

      notifier().start(habit: _habit, minutes: 25);
      wait(const Duration(minutes: 25));
      notifier().tick();
      final result = await notifier().save();

      expect(result.habitCompleted, isTrue);
      expect(result.streakGained, isFalse);
    });

    test('Thói quen đã xong từ trước thì phiên này không tính là làm hoàn thành', () async {
      await container.read(habitLogsProvider.notifier).setDoneToday(_habit, done: true);

      notifier().start(habit: _habit, minutes: 25);
      wait(const Duration(minutes: 25));
      notifier().tick();
      final result = await notifier().save();

      expect(result.habitCompleted, isFalse);
      expect(result.streakGained, isFalse);
    });

    test('Lưu hai lần không bị tính trùng', () async {
      notifier().start(habit: _habit, minutes: 25);
      wait(const Duration(minutes: 10));
      notifier().finishEarly();

      await notifier().save();
      await notifier().save();

      expect(SessionRepository().getAll(), hasLength(1));
      expect(HabitLogRepository().getAll(), hasLength(1));
    });
  });

  group('Chế độ demo', () {
    Future<void> enableDemo() async {
      await container.read(profileProvider.notifier).setDemoMode(true);
    }

    test('Lưu vào Hive và không làm mất các lựa chọn khác trong hồ sơ', () async {
      await container
          .read(profileProvider.notifier)
          .completeOnboarding(const UserProfile(motivationTypes: [], preferredReelLength: 60));
      await enableDemo();

      expect(ProfileRepository().profile?.demoMode, isTrue);
      expect(ProfileRepository().profile?.preferredReelLength, 60);

      await container.read(profileProvider.notifier).updateMotivationTypes(const []);
      expect(ProfileRepository().profile?.demoMode, isTrue, reason: 'Làm lại quiz không tắt demo');
    });

    test('Phiên 25 phút hết sau 500 giây thật, thói quen và streak vẫn cập nhật', () async {
      await enableDemo();
      notifier().start(habit: _habit, minutes: 25);

      wait(const Duration(seconds: 499));
      notifier().tick();
      expect(state().phase, FocusPhase.running);

      wait(const Duration(seconds: 1));
      notifier().tick();
      expect(state().phase, FocusPhase.finished);
      expect(state().focused, const Duration(minutes: 25));

      final result = await notifier().save();
      expect(SessionRepository().getAll().single.focusedSeconds, 25 * 60);
      expect(HabitLogRepository().getAll().single.minutes, 25);
      expect(result.habitCompleted, isTrue);
      expect(result.streakGained, isTrue);
    });

    test('Bật demo khi phiên đang chạy không đổi tốc độ phiên đó', () async {
      notifier().start(habit: _habit, minutes: 25);
      await enableDemo();

      wait(const Duration(minutes: 1));
      notifier().tick();

      expect(state().remaining, const Duration(minutes: 24));
    });
  });
}
