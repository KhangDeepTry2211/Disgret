// 2.2 Nhắc giờ học (spec 009): the reminders to schedule now, and the service that schedules them.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/habit_progress.dart';
import '../data/reminder_plan.dart';
import '../data/repositories/reminder_settings_repository.dart';
import '../services/reminder_service.dart';
import 'app_providers.dart';

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => kIsWeb || defaultTargetPlatform != TargetPlatform.android
      ? const NoReminderService()
      : LocalReminderService(),
);

final reminderSettingsRepositoryProvider = Provider((ref) => ReminderSettingsRepository());

/// Rebuilt whenever habits, habit logs or the day change; app.dart applies it.
final reminderPlanProvider = Provider<List<PlannedReminder>>((ref) {
  final habits = ref.watch(habitsProvider);
  final logs = ref.watch(habitLogsProvider);
  final today = ref.watch(todayProvider);
  final now = ref.watch(clockProvider)();
  return ReminderPlan.upcoming(
    habits: habits,
    doneToday: {
      for (final habit in habits)
        if (HabitProgress.isDone(habit, today, logs)) habit.id,
    },
    now: now,
  );
});
