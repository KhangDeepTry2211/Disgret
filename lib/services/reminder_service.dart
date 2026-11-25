// 2.2 Nhắc giờ học (spec 009, ADR-0006): applies the reminder plan with local notifications only
// (no network). Reminders are one-shot notifications placed at absolute instants (UTC), so no
// time-zone database is needed; the plan is replaced as a whole every time it changes.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/reminder_plan.dart';
import '../l10n/app_strings.dart';

abstract class ReminderService {
  /// Replaces every pending reminder with [reminders].
  Future<void> replaceAll(List<PlannedReminder> reminders);

  /// Shows the system's notification permission dialog when it applies (Android 13+).
  Future<void> requestPermission();

  /// [onTap] runs when the student taps a reminder while DisGret is running.
  void listenForTaps(void Function() onTap);
}

/// Web and other platforms without local notifications.
class NoReminderService implements ReminderService {
  const NoReminderService();

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {}

  @override
  Future<void> requestPermission() async {}

  @override
  void listenForTaps(void Function() onTap) {}
}

class LocalReminderService implements ReminderService {
  static const String _channelId = 'study_reminders';

  /// White silhouette in android/app/src/main/res/drawable (status bar icons are one colour).
  static const String _smallIcon = 'ic_stat_gret';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;
  void Function()? _onTap;

  // A cold start from a reminder opens on Hôm nay by itself; a running app is sent there by
  // [_onTap].
  Future<void> _init() => _ready ??= _plugin
      .initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings(_smallIcon)),
        onDidReceiveNotificationResponse: (_) => _onTap?.call(),
      )
      .then((_) {});

  @override
  void listenForTaps(void Function() onTap) {
    _onTap = onTap;
    _init();
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    await _init();
    // Pending only: a reminder already shown stays in the notification shade.
    await _plugin.cancelAllPendingNotifications();
    for (final (id, reminder) in reminders.indexed) {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(reminder.at.toUtc(), tz.UTC),
        title: reminder.title,
        body: reminder.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            AppStrings.reminderChannel,
            channelDescription: AppStrings.reminderChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        // Inexact: no exact-alarm permission needed; a few minutes late is fine (R2.2).
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> requestPermission() async {
    await _init();
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
}
