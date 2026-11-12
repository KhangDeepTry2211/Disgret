// 7.1, 2.1, 7.2, 2.3, 2.4, 8.2 Cầu nối sang phần Kotlin qua MethodChannel "focus/native".
// Trên web và iOS không gọi native và trả về giá trị mặc định.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class InstalledApp {
  const InstalledApp({required this.packageName, required this.name, required this.icon});

  factory InstalledApp.fromJson(Map<String, dynamic> json) {
    final iconData = json['icon'];
    return InstalledApp(
      packageName: json['packageName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: iconData is String && iconData.isNotEmpty
          ? base64Decode(iconData)
          : Uint8List(0),
    );
  }

  final String packageName;
  final String name;
  final Uint8List icon;
}

class NativeAction {
  const NativeAction(this.name, {this.minutes});

  static const String interventionShown = 'intervention_shown';
  static const String resumeFocus = 'resume_focus';
  static const String openReelsDistracted = 'open_reels_distracted';
  static const String breakStarted = 'break_started';
  static const String breakEnded = 'break_ended';

  final String name;
  final int? minutes;
}

class GuardPermissions {
  const GuardPermissions({
    required this.usageAccess,
    required this.overlay,
    required this.notification,
  });

  final bool usageAccess;
  final bool overlay;
  final bool notification;

  bool get canGuard => usageAccess && overlay;
}

class NativeBridge {
  const NativeBridge();

  static const MethodChannel _channel = MethodChannel('focus/native');

  /// Chỉ hỗ trợ Android native. Trên iOS và Web sẽ tắt.
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    if (!isSupported) return null;
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      debugPrint('Lỗi native khi gọi $method: $error');
    } on MissingPluginException catch (error) {
      debugPrint('Không tìm thấy hàm native $method: $error');
    }
    return null;
  }

  Future<bool> _ask(String method) async => await _invoke<bool>(method) ?? false;

  // ---------- Hành động từ Kotlin sang Flutter ----------

  void listenForActions(void Function(NativeAction action) onAction) {
    if (!isSupported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onNativeAction') return;
      final arguments = call.arguments as Map<Object?, Object?>;
      onAction(NativeAction(arguments['action']! as String, minutes: arguments['minutes'] as int?));
    });
    _invoke<void>('nativeReady');
  }

  // ---------- 7.1 Quyền truy cập ----------

  Future<bool> hasUsageAccess() => _ask('hasUsageAccess');
  Future<void> openUsageAccessSettings() => _invoke<void>('openUsageAccessSettings');
  Future<bool> hasOverlayPermission() => _ask('hasOverlayPermission');
  Future<void> openOverlaySettings() => _invoke<void>('openOverlaySettings');
  Future<bool> hasNotificationPermission() => _ask('hasNotificationPermission');
  Future<void> requestNotificationPermission() => _invoke<void>('requestNotificationPermission');

  Future<GuardPermissions> checkPermissions() async => GuardPermissions(
    usageAccess: await hasUsageAccess(),
    overlay: await hasOverlayPermission(),
    notification: await hasNotificationPermission(),
  );

  // ---------- 2.1 Danh sách app ----------

  Future<List<InstalledApp>> getLaunchableApps() async {
    final raw = await _invoke<String>('getLaunchableApps');
    if (raw == null) return const [];
    return (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(InstalledApp.fromJson)
        .toList();
  }

  // ---------- 7.2 Theo dõi app đang mở ----------

  Future<bool> startGuard(List<String> blockedPackages, {int timeScale = 1}) async =>
      await _invoke<bool>('startGuard', {
        'blockedPackages': blockedPackages,
        'timeScale': timeScale,
      }) ??
      false;

  Future<void> stopGuard() => _invoke<void>('stopGuard');

  // ---------- 2.4 Nghỉ có chủ đích ----------

  Future<bool> startBreak(int minutes) async =>
      await _invoke<bool>('startBreak', {'minutes': minutes}) ?? false;

  Future<void> endBreak() => _invoke<void>('endBreak');

  // ---------- 2.3 Màn can thiệp ----------

  Future<void> showIntervention(String appName) =>
      _invoke<void>('showIntervention', {'appName': appName});

  // ---------- 8.2 Hàng đợi sự kiện ----------

  Future<List<Map<String, dynamic>>> drainEvents() async {
    final events = await _invoke<String>('drainEvents');
    if (events == null) return const [];
    return (jsonDecode(events) as List<dynamic>).cast<Map<String, dynamic>>();
  }
}