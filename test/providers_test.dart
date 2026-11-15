// Kiểm thử state: mọi thao tác đi qua Notifier đều cập nhật ngay, không cần đọc lại Hive.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/date_utils.dart';
import 'package:focus_app/data/habit_progress.dart';
import 'package:focus_app/data/habit_science.dart';
import 'package:focus_app/data/models/event.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
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
    test('Thói quen mới có ngày bắt đầu là hôm nay và xếp cuối danh sách', () async {
      final goal = await goals().add(title: 'G', reason: 'R');
      final first = await habits().add(goalId: goal.id, name: 'A', minMinutesPerDay: 5);
      final second = await habits().add(goalId: goal.id, name: 'B', minMinutesPerDay: 5);
      expect(first.startDate, DateTime(2026, 3, 2));
      expect(second.sortOrder, greaterThan(first.sortOrder));
      expect(container.read(habitsProvider).map((habit) => habit.name), ['A', 'B']);

      // Đổi thứ tự bằng sortOrder thì danh sách đổi theo.
      await habits().edit(second.copyWith(sortOrder: -1));
      expect(container.read(habitsProvider).map((habit) => habit.name), ['B', 'A']);
    });

    test('Sắp xếp lại trong cùng loại: việc một lần giữ nguyên chỗ, sortOrder được lưu', () async {
      final goal = await goals().add(title: 'G', reason: 'R');
      await habits().add(goalId: goal.id, name: 'A', minMinutesPerDay: 5);
      await habits().create(
        Habit(id: '', goalId: goal.id, name: 'Việc', minMinutesPerDay: 5, type: HabitType.oneTime),
      );
      await habits().add(goalId: goal.id, name: 'B', minMinutesPerDay: 5);
      await habits().add(goalId: goal.id, name: 'C', minMinutesPerDay: 5);
      List<String> names() => container.read(habitsProvider).map((habit) => habit.name).toList();
      expect(names(), ['A', 'Việc', 'B', 'C']);

      // Trong loại "Thói quen" (A, B, C): chuyển C lên đầu.
      await habits().reorderWithinType(HabitType.regular, 2, 0);
      expect(names(), ['C', 'Việc', 'A', 'B']);
      final saved = HabitRepository().getAll()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      expect(saved.map((habit) => habit.name), ['C', 'Việc', 'A', 'B']);
    });

    test('"Xoá nhưng giữ lịch sử": ẩn khỏi danh sách, log còn, Thống kê vẫn tính', () async {
      final goal = await goals().add(title: 'G', reason: 'R');
      final habit = await habits().add(goalId: goal.id, name: 'A', minMinutesPerDay: 5);
      await logs().setDoneToday(habit, done: true);

      await habits().archive(habit.id);
      expect(container.read(habitsProvider), isEmpty);
      expect(container.read(allHabitsProvider).single.archived, isTrue);
      expect(container.read(habitLogsProvider), hasLength(1));
      final stats = await container.read(focusStatsProvider.future);
      expect(stats.habitDoneDays, 1);

      // Xoá mục tiêu thì xoá luôn thói quen đã ẩn và log của nó.
      await goals().remove(goal.id);
      expect(HabitRepository().getAll(), isEmpty);
      expect(container.read(habitLogsProvider), isEmpty);
    });

    test('Focus chọn thói quen đến hạn hôm nay, bỏ qua thói quen không có lịch', () async {
      final goal = await goals().add(title: 'G', reason: 'R');
      // Hôm nay 2/3/2026 là Thứ Hai; thói quen đầu chỉ làm Thứ Ba.
      await habits().create(
        Habit(
          id: '',
          goalId: goal.id,
          name: 'Thứ Ba',
          minMinutesPerDay: 5,
          repeat: HabitRepeat.weekly,
          weekdays: const [DateTime.tuesday],
        ),
      );
      final daily = await habits().add(goalId: goal.id, name: 'Hằng ngày', minMinutesPerDay: 5);
      expect(container.read(todayHabitProvider)?.id, daily.id);
    });

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
    test('Tạo dữ liệu mẫu: 1 mục tiêu, 7 thói quen, streak đúng như mô tả', () async {
      await container.read(appDataActionsProvider).createDemoData();

      final allHabits = container.read(habitsProvider);
      final allLogs = container.read(habitLogsProvider);
      final today = container.read(todayProvider);
      final goal = container.read(goalsProvider).single;
      expect(goal.identity, isNotEmpty);
      expect(allHabits, hasLength(7));
      expect(container.read(overallStreakProvider), 5);
      // Xếp theo sortOrder nên "Làm bài tập" đứng đầu: Focus lúc demo chọn thói quen này.
      expect(allHabits.first.id, 'demo_habit_exercise');
      expect(container.read(todayHabitProvider)?.id, 'demo_habit_exercise');

      // Đủ 7 màu khác nhau, đủ buổi Sáng/Chiều/Tối, có lặp lại theo tuần và việc một lần.
      expect(allHabits.map((habit) => habit.colorIndex).toSet(), hasLength(7));
      expect(
        allHabits.map((habit) => habit.timeOfDay).toSet(),
        containsAll([HabitTimeOfDay.morning, HabitTimeOfDay.afternoon, HabitTimeOfDay.evening]),
      );
      expect(allHabits.where((habit) => habit.weekdays.isNotEmpty), isNotEmpty);
      expect(allHabits.where((habit) => habit.isWeeklyByCount), isNotEmpty);
      final task = allHabits.singleWhere((habit) => habit.type == HabitType.oneTime);
      expect(task.dueDate, today);

      Habit habit(String id) => allHabits.firstWhere((habit) => habit.id == id);
      final review = habit('demo_habit_review');
      final exercise = habit('demo_habit_exercise');
      final reading = habit('demo_habit_reading');
      expect(HabitScience.habitStreak(review, allLogs, today: today), 5);
      expect(HabitScience.habitStreak(exercise, allLogs, today: today), 3);
      expect(HabitProgress.isDone(exercise, today, allLogs), isFalse);
      expect(HabitProgress.minutesOn(exercise, today, allLogs), 10);
      // Hôm nay chưa có thói quen nào xong, để demo học xong một phiên thì thấy streak tăng.
      for (final item in allHabits) {
        expect(HabitProgress.isDone(item, today, allLogs), isFalse, reason: item.name);
        expect(HabitProgress.markLogOn(item, today, allLogs), isNull, reason: item.name);
      }

      // Lịch sử 120 ngày, đủ loại ghi nhận để 3 chế độ xem và huy hiệu đều có số liệu.
      final sources = allLogs.map((log) => log.source).toSet();
      expect(sources, containsAll(HabitLogSource.values));
      final oldest = allLogs.map((log) => log.date).reduce((a, b) => a.isBefore(b) ? a : b);
      expect(daysBetween(oldest, today), 120);
      final reviewHistory = HabitHistory.of(review, allLogs);
      expect(HabitScience.journeyDays(reviewHistory), greaterThanOrEqualTo(66));
      expect(HabitScience.longestStreak(reviewHistory, today), greaterThan(10));
      expect(allLogs.where((log) => log.note.isNotEmpty), isNotEmpty);
      expect(HabitScience.missedYesterday(HabitHistory.of(reading, allLogs), today), isTrue);
      expect(HabitScience.missedYesterday(reviewHistory, today), isFalse);
      expect(container.read(averageStrengthProvider), greaterThan(0.3));

      // Thói quen T2, T4, T6 chỉ có ghi nhận vào đúng các thứ đó.
      final runDays = allLogs
          .where((log) => log.habitId == 'demo_habit_run')
          .map((log) => log.date);
      expect(runDays.map((day) => day.weekday).toSet(), {
        DateTime.monday,
        DateTime.wednesday,
        DateTime.friday,
      });
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
      expect(container.read(habitsProvider), hasLength(7));
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
