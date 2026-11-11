// Tiện ích dùng chung cho các file test.
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/app.dart';
import 'package:focus_app/data/hive_boxes.dart';
import 'package:focus_app/data/models/reel.dart';
import 'package:focus_app/data/repositories/reel_repository.dart';
import 'package:focus_app/providers/app_providers.dart';
import 'package:focus_app/providers/focus_session_provider.dart';
import 'package:focus_app/services/native_bridge.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Điện thoại nhỏ, để phát hiện lỗi tràn giao diện.
const Size smallPhone = Size(360, 640);

/// Mở các box Hive trong bộ nhớ: mỗi test bắt đầu như một lần cài app mới.
Future<void> openMemoryBoxes() async {
  for (final name in HiveBoxes.all) {
    await Hive.openBox<dynamic>(name, bytes: Uint8List(0));
  }
}

/// Dữ liệu thật trong reels.json, đọc trực tiếp từ file nên dùng được trong widget test.
final List<Reel> testReels = ReelRepository.parse(
  File(ReelRepository.assetPath).readAsStringSync(),
);

/// [clock] là đồng hồ giả: dùng khi test cần thời gian trôi qua, vì trong widget test
/// DateTime.now() không chạy theo tester.pump().
Future<void> pumpApp(
  WidgetTester tester, {
  Size size = smallPhone,
  DateTime Function()? clock,
  void Function(bool enabled)? onScreenAwakeChanged,
  FakeNativeBridge? native,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reelsProvider.overrideWith((ref) => testReels),
        // Plugin giữ màn hình sáng không chạy trong môi trường test.
        screenAwakeProvider.overrideWithValue(
          (enabled) async => onScreenAwakeChanged?.call(enabled),
        ),
        nativeBridgeProvider.overrideWithValue(native ?? FakeNativeBridge()),
        if (clock != null) clockProvider.overrideWithValue(clock),
      ],
      child: const DisGretApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Giả lập người dùng thoát khỏi app: đi đúng trình tự trạng thái như trên máy thật.
void hideApp(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
}

/// Giả lập người dùng quay lại app.
void showApp(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

/// Cuộn tới rồi bấm, vì nội dung có thể nằm ngoài màn hình nhỏ.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Phần Kotlin giả: mặc định đủ quyền, ghi lại các lệnh Flutter gửi xuống.
class FakeNativeBridge extends NativeBridge {
  FakeNativeBridge({
    this.usageAccess = true,
    this.overlay = true,
    this.notification = true,
    this.supported = true,
    this.apps = const [],
  });

  bool usageAccess;
  bool overlay;
  bool notification;
  final bool supported;
  final List<InstalledApp> apps;

  /// Danh sách chặn của từng lần startGuard.
  final List<List<String>> guardStarts = [];
  int guardStops = 0;

  /// Các lệnh mở màn hình của hệ thống, theo thứ tự.
  final List<String> opened = [];

  /// Đặt khác null để giữ lại kết quả kiểm tra quyền, giả lập native trả lời chậm.
  Completer<void>? permissionsGate;

  /// Theo dõi đang bật theo các lệnh đã gửi.
  bool isGuarding = false;

  /// Hệ số thời gian của lần startGuard gần nhất.
  int lastTimeScale = 1;

  /// Số phút của từng lần startBreak.
  final List<int> breakStarts = [];
  int breakEnds = 0;

  /// Sự kiện đang nằm trong hàng đợi phía Kotlin.
  final List<Map<String, dynamic>> queuedEvents = [];

  void Function(NativeAction action)? _onAction;

  /// Giả lập phần Kotlin gửi một hành động sang Flutter.
  void emit(String action, {int? minutes}) => _onAction!(NativeAction(action, minutes: minutes));

  @override
  void listenForActions(void Function(NativeAction action) onAction) {
    if (supported) _onAction = onAction;
  }

  @override
  bool get isSupported => supported;

  @override
  Future<bool> hasUsageAccess() async => usageAccess;

  @override
  Future<bool> hasOverlayPermission() async => overlay;

  @override
  Future<bool> hasNotificationPermission() async => notification;

  @override
  Future<GuardPermissions> checkPermissions() async {
    await permissionsGate?.future;
    return super.checkPermissions();
  }

  @override
  Future<void> openUsageAccessSettings() async => opened.add('usage');

  @override
  Future<void> openOverlaySettings() async => opened.add('overlay');

  @override
  Future<void> requestNotificationPermission() async => opened.add('notification');

  @override
  Future<List<InstalledApp>> getLaunchableApps() async => apps;

  @override
  Future<bool> startGuard(List<String> blockedPackages, {int timeScale = 1}) async {
    guardStarts.add(blockedPackages);
    lastTimeScale = timeScale;
    isGuarding = true;
    return true;
  }

  @override
  Future<bool> startBreak(int minutes) async {
    breakStarts.add(minutes);
    return isGuarding;
  }

  @override
  Future<void> endBreak() async => breakEnds++;

  @override
  Future<List<Map<String, dynamic>>> drainEvents() async {
    final events = [...queuedEvents];
    queuedEvents.clear();
    return events;
  }

  @override
  Future<void> stopGuard() async {
    guardStops++;
    isGuarding = false;
  }

  @override
  Future<void> showIntervention(String appName) async => opened.add('intervention:$appName');
}

/// Trình phát video giả: không phát gì thật, chỉ ghi lại video nào đang sống, đang phát,
/// và cho test tự đặt vị trí phát để giả lập thời gian trôi qua.
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  FakeVideoPlayerPlatform({
    this.videoDuration = const Duration(seconds: 15),
    this.videoSize = const Size(1080, 1920),
  });

  final Duration videoDuration;
  final Size videoSize;

  /// Video trong danh sách này sẽ báo lỗi khi khởi tạo.
  final Set<String> failingAssets = {};

  /// Toàn bộ video đã từng được tạo, theo thứ tự.
  final List<String> createdAssets = [];

  final Map<int, String> _assets = {};
  final Map<int, StreamController<VideoEvent>> _events = {};
  final Set<int> _playing = {};
  final Set<int> _looping = {};
  final Map<int, Duration> _positions = {};
  int _nextId = 1;

  /// Video đang được giữ trong bộ nhớ.
  List<String> get liveAssets => _assets.values.toList();

  /// Video đang phát.
  List<String> get playingAssets => [for (final id in _playing) _assets[id]!];

  bool isLooping(String asset) => _looping.contains(_idOf(asset));

  void setPosition(String asset, Duration position) => _positions[_idOf(asset)] = position;

  int _idOf(String asset) => _assets.entries.firstWhere((entry) => entry.value == asset).key;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = _nextId++;
    final asset = options.dataSource.asset!;
    createdAssets.add(asset);
    _assets[id] = asset;
    _positions[id] = Duration.zero;
    _events[id] = StreamController<VideoEvent>(
      // Bắt buộc có: thiếu onCancel thì lệnh cancel() của stream trả về một future nằm ngoài
      // đồng hồ giả của widget test, khiến controller.dispose() bị kẹt và không tới được dispose.
      onCancel: () async {},
      onListen: () {
        if (failingAssets.contains(asset)) {
          _events[id]!.addError(PlatformException(code: 'lỗi', message: 'Không mở được video'));
        } else {
          _events[id]!.add(
            VideoEvent(
              eventType: VideoEventType.initialized,
              duration: videoDuration,
              size: videoSize,
            ),
          );
        }
      },
    );
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> dispose(int playerId) async {
    _assets.remove(playerId);
    _playing.remove(playerId);
    _looping.remove(playerId);
    await _events.remove(playerId)?.close();
  }

  @override
  Future<void> play(int playerId) async => _playing.add(playerId);

  @override
  Future<void> pause(int playerId) async => _playing.remove(playerId);

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    looping ? _looping.add(playerId) : _looping.remove(playerId);
  }

  @override
  Future<Duration> getPosition(int playerId) async => _positions[playerId] ?? Duration.zero;

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async => _positions[playerId] = position;

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(int playerId, bool prevent) async {}

  @override
  Widget buildView(int playerId) => const SizedBox.expand();
}
