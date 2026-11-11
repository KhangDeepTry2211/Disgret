// Kiểm thử 6.2: model lưu và đọc lại đúng qua Hive.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/event.dart';
import 'package:focus_app/data/models/goal.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/habit_log.dart';
import 'package:focus_app/data/models/motivation_type.dart';
import 'package:focus_app/data/models/reel.dart';
import 'package:focus_app/data/models/session.dart';
import 'package:focus_app/data/models/user_profile.dart';
import 'package:focus_app/data/repositories/event_repository.dart';
import 'package:focus_app/data/repositories/goal_repository.dart';
import 'package:focus_app/data/repositories/habit_log_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/profile_repository.dart';
import 'package:focus_app/data/repositories/reel_repository.dart';
import 'package:focus_app/data/repositories/session_repository.dart';
import 'package:hive/hive.dart';

import 'test_helpers.dart';

const Habit _habit = Habit(id: 'h1', goalId: 'g1', name: 'Ôn bài', minMinutesPerDay: 25);

Session _session({required String id, required DateTime start, required int focusedSeconds}) =>
    Session(
      id: id,
      habitId: _habit.id,
      start: start,
      plannedMinutes: 25,
      focusedSeconds: focusedSeconds,
      distractionCount: 0,
    );

void main() {
  setUp(openMemoryBoxes);

  tearDown(() async {
    await Hive.close();
  });

  group('Lưu và đọc lại qua Hive', () {
    test('UserProfile', () async {
      final repository = ProfileRepository();
      expect(repository.isOnboardingDone, isFalse);
      expect(repository.profile, isNull);

      await repository.completeOnboarding(
        const UserProfile(
          motivationTypes: [MotivationType.money, MotivationType.freedom],
          preferredReelLength: 60,
        ),
      );

      expect(repository.isOnboardingDone, isTrue);
      expect(repository.profile?.motivationTypes, [MotivationType.money, MotivationType.freedom]);
      expect(repository.profile?.preferredReelLength, 60);

      await repository.resetOnboarding();
      expect(repository.isOnboardingDone, isFalse);
      expect(repository.profile, isNotNull);
    });

    test('Goal và Habit', () async {
      await GoalRepository().save(const Goal(id: 'g1', title: 'Mục tiêu', reason: 'Lý do'));
      final habits = HabitRepository();
      await habits.save(_habit);
      await habits.save(const Habit(id: 'h2', goalId: 'g2', name: 'Khác', minMinutesPerDay: 10));

      final goal = GoalRepository().getById('g1');
      expect(goal?.title, 'Mục tiêu');
      expect(goal?.reason, 'Lý do');

      final ofGoal = habits.getByGoal('g1');
      expect(ofGoal.map((habit) => habit.name), ['Ôn bài']);
      expect(ofGoal.single.minMinutesPerDay, 25);
    });

    test('Session giữ đúng cả trường có thể null', () async {
      final repository = SessionRepository();
      final start = DateTime(2026, 11, 5, 20, 30);
      final end = start.add(const Duration(minutes: 25));
      await repository.save(
        Session(
          id: 'finished',
          habitId: 'h1',
          start: start,
          end: end,
          plannedMinutes: 25,
          focusedSeconds: 1400,
          distractionCount: 2,
          selfRating: 4,
        ),
      );
      await repository.save(_session(id: 'running', start: start, focusedSeconds: 600));

      final finished = repository.getById('finished');
      expect(finished?.start, start);
      expect(finished?.end, end);
      expect(finished?.focusedSeconds, 1400);
      expect(finished?.distractionCount, 2);
      expect(finished?.selfRating, 4);

      final running = repository.getById('running');
      expect(running?.end, isNull);
      expect(running?.selfRating, isNull);
    });

    test('Event lưu đúng tên sự kiện và meta', () async {
      final repository = EventRepository();
      await repository.log(EventType.interventionShown, meta: {'app': 'TikTok'});
      await repository.log(EventType.choseBreak);

      final events = repository.getAll();
      expect(events.map((event) => event.type), [
        EventType.interventionShown,
        EventType.choseBreak,
      ]);
      expect(events.first.meta['app'], 'TikTok');
      expect(events.first.toMap()['type'], 'intervention_shown');
      expect(events.last.meta, isEmpty);
    });

    test('delete xoá đúng bản ghi', () async {
      final repository = GoalRepository();
      await repository.save(const Goal(id: 'g1', title: 'A', reason: ''));
      await repository.delete('g1');
      expect(repository.getById('g1'), isNull);
    });

    test('HabitLog giữ đủ các trường, source lưu đúng chữ "manual"/"focus"', () async {
      final repository = HabitLogRepository();
      await repository.save(
        HabitLog(
          id: 'l1',
          habitId: 'h1',
          date: DateTime(2026, 3, 2),
          source: HabitLogSource.focus,
          minutes: 12,
          note: 'Ghi chú',
        ),
      );

      final log = repository.getById('l1');
      expect(log?.habitId, 'h1');
      expect(log?.date, DateTime(2026, 3, 2));
      expect(log?.source, HabitLogSource.focus);
      expect(log?.minutes, 12);
      expect(log?.note, 'Ghi chú');
      expect(log?.toMap()['source'], 'focus');
      expect(log?.toMap()['date'], '2026-03-02');
    });

    test('HabitLog chỉ giữ phần ngày, bỏ giờ phút', () {
      final log = HabitLog(
        id: 'l1',
        habitId: 'h1',
        date: DateTime(2026, 3, 2, 23, 59, 30),
        source: HabitLogSource.manual,
        minutes: 25,
      );
      expect(log.date, DateTime(2026, 3, 2));
    });
  });

  group('1.2 Kho nội dung', () {
    test('Đọc mảng "reels", bỏ qua "_huong_dan" và các trường không dùng', () {
      final reels = ReelRepository.parse('''
{
  "_huong_dan": "ghi chú",
  "reels": [
    {
      "id": "x1",
      "source": "asset",
      "title": "Tiêu đề",
      "tags": ["money", "family"],
      "lengthSec": 12,
      "assetPath": "assets/reels/x1.mp4",
      "creditUrl": "https://example.com",
      "context": ["start", "distracted"]
    }
  ]
}
''');

      final reel = reels.single;
      expect(reel.id, 'x1');
      expect(reel.title, 'Tiêu đề');
      expect(reel.assetPath, 'assets/reels/x1.mp4');
      expect(reel.tags, [MotivationType.money, MotivationType.family]);
      expect(reel.lengthSec, 12);
      expect(reel.context, [ReelContext.start, ReelContext.distracted]);
    });

    test('reels.json thật: đủ 6 reel, tag và context hợp lệ, file video tồn tại', () {
      expect(testReels, hasLength(6));
      for (final reel in testReels) {
        expect(File(reel.assetPath).existsSync(), isTrue, reason: reel.assetPath);
        expect(reel.tags, isNotEmpty, reason: reel.id);
        expect(reel.context, isNotEmpty, reason: reel.id);
        expect(
          reel.context.every((c) => c == ReelContext.start || c == ReelContext.distracted),
          isTrue,
          reason: reel.id,
        );
      }
    });

    testWidgets('ReelRepository đọc được reels.json qua asset đã khai báo trong pubspec', (
      tester,
    ) async {
      // Đọc asset là thao tác thật nên phải chạy ngoài đồng hồ giả của widget test.
      final reels = await tester.runAsync(() => ReelRepository().loadAll());
      expect(reels, hasLength(6));

      // File video cũng phải nằm trong bundle: thiếu khai báo thì màn Reels không phát được.
      final video = await tester.runAsync(() => rootBundle.load(reels!.first.assetPath));
      expect(video!.lengthInBytes, greaterThan(0));
    });
  });

  group('Sự kiện reel_watched', () {
    test('Lưu đủ reelId, số giây, xem hết; chỉ có startedFocus khi bấm bắt đầu học', () async {
      final repository = EventRepository();
      await repository.logReelWatched(reelId: 'r1', secondsWatched: 9, completed: false);
      await repository.logReelWatched(
        reelId: 'r2',
        secondsWatched: 15,
        completed: true,
        startedFocus: true,
      );

      final events = repository.getAll();
      expect(events.first.type, EventType.reelWatched);
      expect(events.first.toMap()['type'], 'reel_watched');
      expect(events.first.meta, {'reelId': 'r1', 'secondsWatched': 9, 'completed': false});
      expect(events.last.meta, {
        'reelId': 'r2',
        'secondsWatched': 15,
        'completed': true,
        'startedFocus': true,
      });
    });
  });

  group('HabitLogRepository', () {
    final today = DateTime(2026, 3, 2, 9);

    test('Tick tạo log manual với số phút tối thiểu của thói quen', () async {
      final repository = HabitLogRepository();
      await repository.markDone(_habit, today);

      final log = repository.getAll().single;
      expect(log.source, HabitLogSource.manual);
      expect(log.minutes, 25);
      expect(log.date, DateTime(2026, 3, 2));
    });

    test('Tick hai lần vẫn chỉ có một log và không mất ghi chú', () async {
      final repository = HabitLogRepository();
      await repository.markDone(_habit, today);
      await repository.saveNote(_habit.id, today, '  Hôm nay ổn  ');
      await repository.markDone(_habit, today);

      final log = repository.getAll().single;
      expect(log.note, 'Hôm nay ổn');
    });

    test('Ghi chú khi chưa tick thì không tạo log', () async {
      final repository = HabitLogRepository();
      await repository.saveNote(_habit.id, today, 'Không có log');
      expect(repository.getAll(), isEmpty);
    });

    test('Bỏ tick chỉ xoá log manual của đúng ngày đó', () async {
      final repository = HabitLogRepository();
      await repository.markDone(_habit, today);
      await repository.markDone(_habit, DateTime(2026, 3, 1));
      await repository.recordSession(_session(id: 's1', start: today, focusedSeconds: 600));

      await repository.unmarkDone(_habit.id, today);

      final logs = repository.getAll();
      expect(logs, hasLength(2));
      expect(logs.where((log) => log.source == HabitLogSource.focus), hasLength(1));
      expect(
        logs.where((log) => log.source == HabitLogSource.manual).single.date,
        DateTime(2026, 3, 1),
      );
    });

    test('recordSession ghi log focus với số phút tập trung thực', () async {
      final repository = HabitLogRepository();
      await repository.recordSession(_session(id: 's1', start: today, focusedSeconds: 750));

      final log = repository.getAll().single;
      expect(log.source, HabitLogSource.focus);
      expect(log.habitId, _habit.id);
      expect(log.minutes, 12); // 750 giây = 12 phút 30 giây, chỉ tính phút trọn vẹn.
      expect(log.date, DateTime(2026, 3, 2));
    });

    test('recordSession gọi lại cho cùng phiên thì không cộng dồn hai lần', () async {
      final repository = HabitLogRepository();
      final session = _session(id: 's1', start: today, focusedSeconds: 600);
      await repository.recordSession(session);
      await repository.recordSession(session);
      expect(repository.getAll(), hasLength(1));
    });

    test('recordSession bỏ qua phiên dưới 1 phút', () async {
      final repository = HabitLogRepository();
      await repository.recordSession(_session(id: 's1', start: today, focusedSeconds: 59));
      expect(repository.getAll(), isEmpty);
    });

    test('Phiên qua nửa đêm được tính cho ngày bắt đầu', () async {
      final repository = HabitLogRepository();
      await repository.recordSession(
        _session(id: 's1', start: DateTime(2026, 3, 1, 23, 50), focusedSeconds: 1800),
      );
      expect(repository.getAll().single.date, DateTime(2026, 3, 1));
    });

    test('deleteByHabit chỉ xoá log của thói quen đó', () async {
      final repository = HabitLogRepository();
      await repository.markDone(_habit, today);
      await repository.markDone(
        const Habit(id: 'h2', goalId: 'g1', name: 'Khác', minMinutesPerDay: 5),
        today,
      );

      await repository.deleteByHabit(_habit.id);
      expect(repository.getAll().single.habitId, 'h2');
    });
  });
}
