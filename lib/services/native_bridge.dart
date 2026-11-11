// 7.1, 2.1, 7.2, 2.3, 2.4, 8.2 Cầu nối sang phần Kotlin qua MethodChannel "focus/native".
// Mọi lời gọi native đều đi qua _invoke. Trên web không có phần native nên _invoke không gọi gì
// và các hàm trả về giá trị mặc định, nhờ vậy nơi khác không cần tự kiểm tra kIsWeb.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 2.1 Một app cài trên máy.
class InstalledApp {
  const InstalledApp({required this.packageName, required this.name, required this.icon});

  final String packageName;
  final String name;

  /// Ảnh PNG nhỏ của icon.
  final Uint8List icon;
}

/// Hành động phần Kotlin gửi sang Flutter qua sự kiện onNativeAction.
class NativeAction {
  const NativeAction(this.name, {this.minutes});

  static const String interventionShown = 'intervention_shown';
  static const String resumeFocus = 'resume_focus';
  static const String openReelsDistracted = 'open_reels_distracted';
  static const String breakStarted = 'break_started';
  static const String breakEnded = 'break_ended';

  final String name;

  /// Chỉ có ở break_started: số phút người dùng chọn nghỉ.
  final int? minutes;
}

/// 7.1 Trạng thái 3 quyền của Reset break.
class GuardPermissions {
  const GuardPermissions({
    required this.usageAccess,
    required this.overlay,
    required this.notification,
  });

  final bool usageAccess;
  final bool overlay;
  final bool notification;

  /// Đủ để chặn app. Thiếu quyền thông báo thì service vẫn chạy, chỉ không thấy thông báo.
  bool get canGuard => usageAccess && overlay;
}

class NativeBridge {
  const NativeBridge();

  static const MethodChannel _channel = MethodChannel('focus/native');

  /// Reset break chỉ có trên Android.
  bool get isSupported => !kIsWeb;

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

  /// Bắt đầu nghe hành động từ phần Kotlin. Hành động xảy ra trước lúc này đang được giữ
  /// bên phía Kotlin, sẽ được gửi sang ngay sau khi Flutter báo sẵn sàng.
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
    final apps = await _invoke<List<Object?>>('getLaunchableApps') ?? const [];
    return [
      for (final app in apps.cast<Map<Object?, Object?>>())
        InstalledApp(
          packageName: app['packageName']! as String,
          name: app['name']! as String,
          icon: app['icon']! as Uint8List,
        ),
    ];
  }

  // ---------- 7.2 Theo dõi app đang mở ----------

  /// Bật theo dõi, hoặc đổi danh sách chặn nếu đang chạy. Trả về false nếu không bật được.
  /// [timeScale] là hệ số của chế độ demo, để giờ nghỉ chạy nhanh bằng đồng hồ của phiên.
  Future<bool> startGuard(List<String> blockedPackages, {int timeScale = 1}) async =>
      await _invoke<bool>('startGuard', {
        'blockedPackages': blockedPackages,
        'timeScale': timeScale,
      }) ??
      false;

  Future<void> stopGuard() => _invoke<void>('stopGuard');

  // ---------- 2.4 Nghỉ có chủ đích ----------

  /// Chuyển service sang chế độ nghỉ. Trả về false nếu service không chạy.
  Future<bool> startBreak(int minutes) async =>
      await _invoke<bool>('startBreak', {'minutes': minutes}) ?? false;

  /// Người dùng tự quay lại học trước giờ: service về chế độ chặn.
  Future<void> endBreak() => _invoke<void>('endBreak');

  // ---------- 2.3 Màn can thiệp ----------

  /// Mở ngay màn can thiệp, dùng cho nút "Thử màn can thiệp" trong Cài đặt.
  Future<void> showIntervention(String appName) =>
      _invoke<void>('showIntervention', {'appName': appName});

  // ---------- 8.2 Hàng đợi sự kiện ----------

  /// Lấy các sự kiện phần Kotlin đã ghi rồi xoá khỏi hàng đợi.
  /// Mỗi sự kiện gồm type, time (mili giây) và meta.
  Future<List<Map<String, dynamic>>> drainEvents() async {
    final events = await _invoke<String>('drainEvents');
    if (events == null) return const [];
    return (jsonDecode(events) as List<dynamic>).cast<Map<String, dynamic>>();
  }
}
