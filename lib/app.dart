// 5.1 Widget gốc của DisGret: gắn theme (5.2), router (5.1) và ngôn ngữ tiếng Việt.
import 'dart:io' show Platform; // Thêm thư viện kiểm tra HĐH
import 'package:flutter/foundation.dart'; // Để dùng kIsWeb
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
      onHide: () => ref.read(focusSessionProvider.notifier).onAppHidden(),
      onResume: () {
        ref.read(todayProvider.notifier).refresh();
        ref.read(focusSessionProvider.notifier).onAppResumed();
        _saveNativeEvents();
      },
    );
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

  Future<void> _saveNativeEvents() async {
    final repository = ref.read(eventRepositoryProvider);
    final events = await ref.read(nativeBridgeProvider).drainEvents();
    await repository.saveNativeEvents(events);
  }

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
      if (next.finishedOnTime) playSessionEndAlert();
      ref.read(routerProvider).go(AppRoutes.summary);
      return;
    }

    final nudge = next.nudge;
    if (nudge != null && !identical(nudge, previous?.nudge)) _respondToDistraction(nudge);
  }

  Future<void> _respondToDistraction(FocusNudge nudge) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    // THAY ĐỔI CHO iOS: Nếu là máy iOS, ÉP hiện luôn bảng hỏi can thiệp thay vì nhắc nhẹ.
    // Nếu là Android, vẫn giữ logic cũ của hàm shouldAskAfterNudge.
    final forceAskForIOS = !kIsWeb && Platform.isIOS;
    if (!forceAskForIOS && !shouldAskAfterNudge(nudge)) {
      showWelcomeBack(context);
      return;
    }

    if (_isAskingAfterDistraction) return;
    _isAskingAfterDistraction = true;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final choice = await askAfterDistraction(context, nudge);
    _isAskingAfterDistraction = false;

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
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}