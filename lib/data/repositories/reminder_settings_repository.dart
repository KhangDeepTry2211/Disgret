// 2.2 Nhắc giờ học (spec 009 FR-004): whether DisGret has already asked for the notification
// permission, kept in the profile box so the student is asked only once.
import 'package:hive/hive.dart';

import '../hive_boxes.dart';

class ReminderSettingsRepository {
  static const String _askedKey = 'reminder_permission_asked';

  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.profile);

  bool get permissionAsked => _box.get(_askedKey) == true;

  Future<void> markPermissionAsked() => _box.put(_askedKey, true);
}
