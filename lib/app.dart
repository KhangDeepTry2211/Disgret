// 5.1 Widget gốc của DisGret: gắn theme (5.2), router (5.1) và ngôn ngữ tiếng Việt.
// Đồng thời nối phiên học với vòng đời app và phản hồi nhắc, vì những việc này phải chạy
// dù người dùng đang ở bất kỳ màn nào.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'data/models/reel.dart';
import 'providers/app_providers.dart';
import 'providers/focus_session_provider.dart';
import 'router/app_router.dart';
import 'services/native_bridge.dart';
import 'theme/app_theme.dart';
import 'widgets/focus_feedback.dart';

class DisGretApp extends ConsumerStatefulWidget {
  const DisGretApp({super.key});

  @override
  ConsumerState<DisGretApp> createState() => _DisGretAppState();
}

class _DisGretAppState extends ConsumerState<DisGretApp> {
  late final AppLifecycleListener _lifecycleListener;
  bool _isAskingAfterDistraction = false;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      // 3.2 Chỉ tính khi app thật sự bị ẩn. Kéo thanh thông báo chỉ làm app "inactive"
      // nên không chạm tới đây.
      onHide: () => ref.read(focusSessionProvider.notifier).onAppHidden(),
      onResume: () {
        // 4.2 App để nền qua đêm rồi mở lại thì "hôm nay" phải là ngày mới.
        ref.read(todayProvider.notifier).refresh();
        ref.read(focusSessionProvider.notifier).onAppResumed();
        _saveNativeEvents();
      },
    );
    // 2.3 Chờ khung hình đầu tiên: lúc đó router đã sẵn sàng để nhận lệnh chuyển màn.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(nativeBridgeProvider).listenForActions(_onNativeAction);
      _saveNativeEvents();
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  /// 8.2 Lấy sự kiện phần Kotlin đã ghi về lưu chung với các sự kiện khác.
  Future<void> _saveNativeEvents() async {
    final repository = ref.read(eventRepositoryProvider);
    final events = await ref.read(nativeBridgeProvider).drainEvents();
    await repository.saveNativeEvents(events);
  }

  /// 2.3, 2.4 Hành động từ màn can thiệp và service.
  void _onNativeAction(NativeAction action) {
    final notifier = ref.read(focusSessionProvider.notifier);
    final router = ref.read(routerProvider);
    final phase = ref.read(focusSessionProvider).phase;

    switch (action.name) {
      case NativeAction.interventionShown:
        notifier.onInterventionShown();
      case NativeAction.resumeFocus:
        if (phase == FocusPhase.running) router.go(AppRoutes.focus);
      case NativeAction.openReelsDistracted:
        // Phiên vừa hết giờ thì ở lại màn Tổng kết, không để mất phiên chưa lưu.
        if (phase != FocusPhase.finished) router.go(AppRoutes.reelsFor(ReelContext.distracted));
      case NativeAction.breakStarted:
        final minutes = action.minutes;
        if (minutes != null) notifier.onBreakStarted(minutes);
      case NativeAction.breakEnded:
        notifier.onBreakEnded();
        if (phase == FocusPhase.running) router.go(AppRoutes.focus);
    }
  }

  void _onSessionChanged(FocusSessionState? previous, FocusSessionState next) {
    final justFinished =
        previous?.phase != FocusPhase.finished && next.phase == FocusPhase.finished;
    if (justFinished) {
      if (next.finishedOnTime) playSessionEndAlert(); // 3.4 Âm báo khi hết giờ.
      ref.read(routerProvider).go(AppRoutes.summary);
      return;
    }

    final nudge = next.nudge;
    if (nudge != null && !identical(nudge, previous?.nudge)) _respondToDistraction(nudge);
  }

  /// 3.3 Lần 1 nhắc nhẹ, từ lần 2 hỏi người dùng muốn làm gì tiếp.
  Future<void> _respondToDistraction(FocusNudge nudge) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    if (!shouldAskAfterNudge(nudge)) {
      showWelcomeBack(context);
      return;
    }

    // Đang hỏi dở mà lại rời đi rồi quay lại thì giữ nguyên sheet đang mở, không chồng thêm.
    if (_isAskingAfterDistraction) return;
    _isAskingAfterDistraction = true;
    // Lời chào của lần trước có thể còn trên màn và che mất các nút bên dưới.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final choice = await askAfterDistraction(context, nudge);
    _isAskingAfterDistraction = false;

    // Trong lúc sheet đang mở, phiên có thể đã hết giờ.
    if (!mounted || !ref.read(focusSessionProvider).isRunning) return;

    switch (choice) {
      case NudgeChoice.keepStudying:
        break;
      case NudgeChoice.watchReel:
        ref.read(routerProvider).go(AppRoutes.reelsFor(ReelContext.distracted));
      case NudgeChoice.takeBreak:
        ref.read(focusSessionProvider.notifier).takeBreak(minutes: suggestedBreakMinutes);
        ref.read(routerProvider).go(AppRoutes.focus);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(focusSessionProvider, _onSessionChanged);

    return MaterialApp.router(
      title: 'DisGret',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
      // Chữ có sẵn của widget hệ thống (ví dụ nhãn nút Back) cũng là tiếng Việt.
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
