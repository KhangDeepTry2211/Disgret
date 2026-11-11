// Kiểm thử state: mọi thao tác đi qua Notifier đều cập nhật ngay, không cần đọc lại Hive.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/habit_progress.dart';
import 'package:focus_app/data/models/event.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit_log.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/session.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/event_repository.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_log_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/data/repositories/session_repository.dart';
import 'package:focus_app/providers/app_providers.dart';
import 'package:hive/hive.dart';

import 'test_helpers.dart';

void main() {
  /// Đồng hồ giả: test đổi biến này để giả lập thời gian trôi qua.
  late DateTime now;
  late ProviderContainer container;

  GoalsNotifier goals() => container.read(goalsProvider.notifier);
  HabitsNotifier habits() => container.read(habitsProvider.notifier);
  HabitLogsNotifier logs() => container.read(habitLogsProvider.notifier);

  Session session({required String id, required String habitId, required int focusedSeconds}) =>
      Session(
        id: id,
        habitId: habitId,
        start: now,
        plannedMinutes: 25,
        focusedSeconds: focusedSeconds,
        distractionCount: 0,
      );

  setUp(() async {
    await openMemoryBoxes();
    now = DateTime(2026, 3, 2, 9);
    container = ProviderContainer(overrides: [clockProvider.overrideWithValue(() => now)]);
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
  });

  group('Thêm, sửa, xoá tự cập nhật state', () {
    test('Thêm và sửa mục tiêu cập nhật danh sách và mục tiêu hôm nay', () async {
      expect(container.read(todayGoalProvider), isNull);

      final goal = await goals().add(title: 'Mục tiêu', reason: 'Lý do');
      expect(container.read(goalsProvider).single.title, 'Mục tiêu');
      expect(container.read(todayGoalProvider)?.id, goal.id);

      await goals().edit(Goal(id: goal.id, title: 'Tên mới', reason: goal.reason));
      expect(container.read(todayGoalProvider)?.title, 'Tên mới');
      expect(GoalRepository().getById(goal.id)?.title, 'Tên mới');
    });

    test('Xoá mục tiêu kéo theo thói quen và nhật ký, không đụng mục tiêu khác', () async {
      final goal = await goals().add(title: 'Xoá', reason: 'R');
      final keptGoal = await goals().add(title: 'Giữ', reason: 'R');
      final habit = await habits().add(goalId: goal.id, name: 'A', minMinutesPerDay: 5);
      final keptHabit = await habits().add(goalId: keptGoal.id, name: 'B', minMinutesPerDay: 5);
      await logs().setDoneToday(habit, done: true);
      await logs().setDoneToday(keptHabit, done: true);

      await goals().remove(goal.id);

      expect(container.read(goalsProvider).single.id, keptGoal.id);
      expect(container.read(habitsProvider).single.id, keptHabit.id);
      expect(container.read(habitLogsProvider).single.habitId, keptHabit.id);
      // Hive cũng đã xoá thật, không chỉ state trong bộ nhớ.
      expect(HabitRepository().getAll().single.id, keptHabit.id);
      expect(HabitLogRepository().getAll().single.habitId, keptHabit.id);
    });

    test('Xoá thói quen kéo theo nhật ký và làm giảm streak', () async {
      final goal = await goals().add(title: 'G', reason: 'R');
      final habit = await habits().add(goalId: goal.id, name: 'A', minMinutesPerDay: 5);
      await logs().setDoneToday(habit, done: true);
      expect(container.read(overallStreakProvider), 1);

      await habits().remove(habit.id);

      expect(container.read(habitsProvider), isEmpty);
      expect(container.read(habitLogsProvider), isEmpty);
      expect(container.read(overallStreakProvider), 0);
    });
  });

  group('Ghi nhận hôm nay', () {
    test('Tick rồi bỏ tick cập nhật ngay trạng thái hoàn thành và streak', () async {
      final goal = await goals().add(title: 'G', reason: 'R');
      final habit = await habits().add(goalId: goal.id, name: 'A', minMinutesPerDay: 25);

      await logs().setDoneToday(habit, done: true);
      expect(container.read(habitLogsProvider).single.source, HabitLogSource.manual);
      expect(container.read(overallStreakProvider), 1);

      await logs().setDoneToday(habit, done: false);
      expect(container.read(habitLogsProvider), isEmpty);
      expect(container.read(overallStreakProvider), 0);
    });

    test(
      'Thói quen hôm nay là thói quen đầu tiên chưa làm, làm hết thì về đầu danh sách',
      () async {
        final goal = await goals().add(title: 'G', reason: 'R');
        final first = await habits().add(goalId: goal.id, name: 'A', minMinutesPerDay: 5);
        final second = await habits().add(goalId: goal.id, name: 'B', minMinutesPerDay: 5);
        expect(container.read(todayHabitProvider)?.id, first.id);

        await logs().setDoneToday(first, done: true);
        expect(container.read(todayHabitProvider)?.id, second.id);

        await logs().setDoneToday(second, done: true);
        expect(container.read(todayHabitProvider)?.id, first.id);
      },
    );

    test('Ghi chú lưu vào log manual của hôm nay', () async {
      final goal = await goals().add(title: 'G', reason: 'R');
      final habit = await habits().add(goalId: goal.id, name: 'A', minMinutesPerDay: 5);

      await logs().setDoneToday(habit, done: true);
      await logs().saveNoteToday(habit, 'Làm xong sớm');
      expect(container.read(habitLogsProvider).single.note, 'Làm xong sớm');
    });
  });

  group('recordSession (GĐ4 sẽ dùng)', () {
    test('Chưa đủ phút thì chưa hoàn thành, đủ phút thì hoàn thành và tăng streak', () async {
      final goal = await goals().add(title: 'G', reason: 'R');
      final habit = await habits().add(goalId: goal.id, name: 'A', minMinutesPerDay: 25);

      await logs().recordSession(session(id: 's1', habitId: habit.id, focusedSeconds: 10 * 60));
      var current = container.read(habitLogsProvider);
      expect(HabitProgress.isDone(habit, now, current), isFalse);
      expect(HabitProgress.minutesOn(habit, now, current), 10);
      expect(container.read(overallStreakProvider), 0);

      await logs().recordSession(session(id: 's2', habitId: habit.id, focusedSeconds: 15 * 60));
      current = container.read(habitLogsProvider);
      expect(HabitProgress.isDone(habit, now, current), isTrue);
      expect(container.read(overallStreakProvider), 1);
    });

    test('Bỏ tick không xoá phút học thật từ phiên Focus', () async {
      final goal = await goals().add(title: 'G', reason: 'R');
      final habit = await habits().add(goalId: goal.id, name: 'A', minMinutesPerDay: 25);

      await logs().recordSession(session(id: 's1', habitId: habit.id, focusedSeconds: 30 * 60));
      await logs().setDoneToday(habit, done: true);
      await logs().setDoneToday(habit, done: false);

      final remaining = container.read(habitLogsProvider).single;
      expect(remaining.source, HabitLogSource.focus);
      expect(remaining.minutes, 30);
    });
  });

  group('Sang ngày mới', () {
    test('Mở lại app sau nửa đêm: hết tick của hôm qua nhưng chuỗi vẫn giữ', () async {
      final goal = await goals().add(title: 'G', reason: 'R');
      final habit = await habits().add(goalId: goal.id, name: 'A', minMinutesPerDay: 5);
      await logs().setDoneToday(habit, done: true);

      now = DateTime(2026, 3, 3, 7);
      container.read(todayProvider.notifier).refresh();

      final today = container.read(todayProvider);
      expect(today, DateTime(2026, 3, 3));
      expect(HabitProgress.isDone(habit, today, container.read(habitLogsProvider)), isFalse);
      expect(container.read(overallStreakProvider), 1);

      // Tick sau đó được ghi cho ngày mới, không phải ngày cũ.
      await logs().setDoneToday(habit, done: true);
      expect(container.read(overallStreakProvider), 2);
      expect(container.read(habitLogsProvider), hasLength(2));
    });

    test('Bỏ qua trọn một ngày thì chuỗi về 0', () async {
      final goal = await goals().add(title: 'G', reason: 'R');
      final habit = await habits().add(goalId: goal.id, name: 'A', minMinutesPerDay: 5);
      await logs().setDoneToday(habit, done: true);

      now = DateTime(2026, 3, 4, 7);
      container.read(todayProvider.notifier).refresh();
      expect(container.read(overallStreakProvider), 0);
    });
  });

  group('Dữ liệu mẫu và xoá toàn bộ', () {
    test('Tạo dữ liệu mẫu: 1 mục tiêu, 2 thói quen, streak đúng như mô tả', () async {
      await container.read(appDataActionsProvider).createDemoData();

      final allHabits = container.read(habitsProvider);
      final allLogs = container.read(habitLogsProvider);
      final today = container.read(todayProvider);
      expect(container.read(goalsProvider), hasLength(1));
      expect(allHabits, hasLength(2));
      expect(container.read(overallStreakProvider), 5);

      final review = allHabits.firstWhere((habit) => habit.id == 'demo_habit_review');
      final exercise = allHabits.firstWhere((habit) => habit.id == 'demo_habit_exercise');
      expect(HabitProgress.habitStreak(review, allLogs, today: today), 5);
      expect(HabitProgress.habitStreak(exercise, allLogs, today: today), 3);
      expect(HabitProgress.isDone(exercise, today, allLogs), isFalse);
      expect(HabitProgress.minutesOn(exercise, today, allLogs), 10);
      // Hôm nay chưa có thói quen nào xong, để demo học xong một phiên thì thấy streak tăng.
      expect(HabitProgress.isDone(review, today, allLogs), isFalse);
    });

    test('Dữ liệu mẫu có phiên học và sự kiện cho Thống kê', () async {
      await container.read(appDataActionsProvider).createDemoData();

      final sessions = SessionRepository().getAll();
      expect(sessions, hasLength(5));
      expect(
        sessions.map((session) => session.focusedSeconds ~/ 60),
        unorderedEquals([10, 35, 40, 30, 15]),
      );
      final events = EventRepository().getAll();
      int count(EventType type) => events.where((event) => event.type == type).length;
      expect(count(EventType.reelWatched), 8);
      expect(count(EventType.interventionShown), 6);
      expect(count(EventType.sessionDistracted), 7);
      // Không có lượt xem nào trong 24 giờ qua, nên thứ tự đề xuất reel lúc demo không đổi.
      final now = container.read(clockProvider)();
      expect(
        events.where(
          (event) => event.type == EventType.reelWatched && now.difference(event.time).inHours < 24,
        ),
        isEmpty,
      );
    });

    test('Bấm tạo dữ liệu mẫu nhiều lần không sinh dữ liệu trùng', () async {
      final actions = container.read(appDataActionsProvider);
      await actions.createDemoData();
      final logCount = container.read(habitLogsProvider).length;
      final eventCount = EventRepository().getAll().length;

      await actions.createDemoData();
      expect(container.read(goalsProvider), hasLength(1));
      expect(container.read(habitsProvider), hasLength(2));
      expect(container.read(habitLogsProvider), hasLength(logCount));
      expect(SessionRepository().getAll(), hasLength(5));
      expect(EventRepository().getAll(), hasLength(eventCount));
    });

    test('Xoá toàn bộ: mất dữ liệu, hồ sơ và lịch sử xem reel', () async {
      await container
          .read(profileProvider.notifier)
          .completeOnboarding(
            const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 30),
          );
      await EventRepository().logReelWatched(reelId: 'r1', secondsWatched: 5, completed: false);
      await container.read(appDataActionsProvider).createDemoData();

      await container.read(appDataActionsProvider).clearAll();

      expect(container.read(goalsProvider), isEmpty);
      expect(container.read(habitsProvider), isEmpty);
      expect(container.read(habitLogsProvider), isEmpty);
      expect(container.read(todayGoalProvider), isNull);
      expect(container.read(overallStreakProvider), 0);
      expect(container.read(profileProvider), isNull);
      expect(ProfileRepository().isOnboardingDone, isFalse);
      expect(ProfileRepository().profile, isNull);
      expect(EventRepository().getAll(), isEmpty);
    });
  });

  group('1.1 Hồ sơ động lực', () {
    test('Làm lại quiz: đổi động lực, giữ độ dài reel, lưu xuống Hive và cập nhật ngay', () async {
      final profile = container.read(profileProvider.notifier);
      await profile.completeOnboarding(
        const UserProfile(motivationTypes: [MotivationType.career], preferredReelLength: 60),
      );

      await profile.updateMotivationTypes(const [MotivationType.money, MotivationType.freedom]);

      final current = container.read(profileProvider);
      expect(current?.motivationTypes, [MotivationType.money, MotivationType.freedom]);
      expect(current?.preferredReelLength, 60);
      expect(ProfileRepository().profile?.motivationTypes, [
        MotivationType.money,
        MotivationType.freedom,
      ]);
      expect(ProfileRepository().isOnboardingDone, isTrue);
    });
  });
}
