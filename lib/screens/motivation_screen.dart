// 1.4 Bước động lực (route /motivation): một liều reel có điểm dừng, không phải feed.
// Spec 002: up to 3 reels before a session, exactly 1 after a distraction (MotivationDose).
// Each reel plays once (no loop, no swipe) and ends on ReelEndCard, which leads into studying
// through StudyStarter (spec 001). No likes, comments, share or counts (ADR-0003).
// During a session the clock pauses while this screen is open (spec 001 research R5, FR-011).
//
// Video controllers: one per reel; only the current reel and the next one (preloaded) exist.
// Leaving the screen disposes them; being covered by another route pauses the current one.
//
// Watch records: one reel_watched per reel shown, written when the user leaves that reel or the
// app goes to the background; later writes replace the same record (EventRepository id).
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../data/models/reel.dart';
import '../data/repositories/event_repository.dart';
import '../data/repositories/hive_repository.dart' show newId;
import '../data/session_plan.dart';
import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../providers/focus_session_provider.dart';
import '../router/app_router.dart';
import '../services/motivation_dose.dart';
import '../services/reel_recommender.dart';
import '../services/reel_watch_tracker.dart';
import '../services/study_starter.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/gradient_progress_bar.dart';
import '../widgets/reel_end_card.dart';

class MotivationScreen extends ConsumerStatefulWidget {
  const MotivationScreen({this.reelContext = ReelContext.start, super.key});

  /// [ReelContext.start] before a session, [ReelContext.distracted] after a distraction.
  final String reelContext;

  @override
  ConsumerState<MotivationScreen> createState() => _MotivationScreenState();
}

class _MotivationScreenState extends ConsumerState<MotivationScreen> {
  /// Captured in initState: ref cannot be used after the widget is disposed.
  late final FocusSessionNotifier _session;

  @override
  void initState() {
    super.initState();
    _session = ref.read(focusSessionProvider.notifier);
    // Riverpod forbids state changes during build, so wait for the frame to finish.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _session.setWatchingReels(true);
    });
  }

  @override
  void dispose() {
    final session = _session;
    WidgetsBinding.instance.addPostFrameCallback((_) => session.setWatchingReels(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reels = ref.watch(reelsProvider);

    // The video background is always dark, so status bar icons must be light.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.videoBackground,
        body: reels.when(
          loading: () => const _Waiting(child: _LoadingIndicator()),
          error: (error, stackTrace) =>
              const _Waiting(child: _CenterMessage(AppStrings.reelsLoadError)),
          data: (allReels) => _DoseView(
            // A new context builds a new dose.
            key: ValueKey(widget.reelContext),
            allReels: allReels,
            reelContext: widget.reelContext,
          ),
        ),
      ),
    );
  }
}

/// Leaves the step: back to the running session, else back to the previous screen (Hôm nay).
void _leaveStep(BuildContext context, WidgetRef ref) {
  if (ref.read(focusSessionProvider).isRunning) {
    context.go(AppRoutes.focus);
  } else if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.today);
  }
}

/// While the reel list loads (or failed): only a close button, and Back leaves.
class _Waiting extends ConsumerWidget {
  const _Waiting({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext buildContext, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leaveStep(buildContext, ref);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: IconButton(
                  icon: const Icon(AppIcons.close, color: AppColors.onVideo),
                  tooltip: AppStrings.close,
                  onPressed: () => _leaveStep(buildContext, ref),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseView extends ConsumerStatefulWidget {
  const _DoseView({required this.allReels, required this.reelContext, super.key});

  final List<Reel> allReels;
  final String reelContext;

  @override
  ConsumerState<_DoseView> createState() => _DoseViewState();
}

class _DoseViewState extends ConsumerState<_DoseView> {
  late final EventRepository _events;
  late final AppLifecycleListener _lifecycleListener;
  late final MotivationDose _dose;

  /// Live controllers by playlist index: the current reel and the preloaded next one.
  final Map<int, VideoPlayerController> _controllers = {};

  /// Watch record of the current reel.
  ReelWatchTracker _tracker = ReelWatchTracker();
  String? _watchEventId;
  bool _reelCompleted = false;
  bool _startedFocus = false;

  bool _isActive = true;

  VideoPlayerController? get _current => _controllers[_dose.index];

  @override
  void initState() {
    super.initState();
    _events = ref.read(eventRepositoryProvider);
    // Save the watch record as soon as the app goes to the background: the system may kill it.
    _lifecycleListener = AppLifecycleListener(onPause: _onAppPaused);

    // 1.3 Each opening computes its playlist from the latest profile and watch history.
    final playlist = ReelRecommender(widget.allReels).recommend(
      ref.read(profileProvider),
      widget.reelContext,
      _events.getAll(),
      now: ref.read(clockProvider)(),
    );
    _dose = MotivationDose(context: widget.reelContext, playlist: playlist);

    if (_dose.isEmpty) {
      // Nothing to show: go straight on (spec 002 edge case "No reel matches").
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _dose.isDistracted ? context.go(AppRoutes.focus) : _startSession(_planMinutes);
      });
    } else {
      _loadController(0);
      _loadController(1);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A covered route has TickerMode off: pause so nothing plays out of sight.
    final isActive = TickerMode.valuesOf(context).enabled;
    if (isActive == _isActive) return;
    _isActive = isActive;
    if (!isActive) _current?.pause();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _saveWatch();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  int get _planMinutes => ref.read(sessionPlanProvider).plannedMinutes;

  void _loadController(int index) {
    if (index >= _dose.playlist.length || _controllers.containsKey(index)) return;
    final controller = VideoPlayerController.asset(_dose.playlist[index].assetPath)
      ..setLooping(false);
    _controllers[index] = controller;
    controller.addListener(() => _onVideoChanged(index, controller));
    _initialize(index, controller);
  }

  Future<void> _initialize(int index, VideoPlayerController controller) async {
    try {
      await controller.initialize();
    } on PlatformException {
      // controller.value.hasError is now true; _onVideoChanged shows the end card.
      if (mounted && index == _dose.index) _onVideoChanged(index, controller);
      return;
    }
    if (!mounted || _controllers[index] != controller) return;
    setState(() {});
    if (index == _dose.index && _dose.phase == MotivationPhase.playing && _isActive) {
      await controller.play();
    }
  }

  void _onVideoChanged(int index, VideoPlayerController controller) {
    if (index != _dose.index || _dose.phase == MotivationPhase.done) return;
    final value = controller.value;
    if (value.isInitialized) _tracker.update(value.position, value.duration);
    if (_dose.phase != MotivationPhase.playing) return;

    if (value.hasError) {
      setState(_dose.videoFailed);
    } else if (value.isCompleted) {
      _reelCompleted = true;
      setState(_dose.videoEnded);
    }
  }

  void _togglePlay() {
    final video = _current;
    if (video == null || !video.value.isInitialized || _dose.phase != MotivationPhase.playing) {
      return;
    }
    video.value.isPlaying ? video.pause() : video.play();
  }

  /// Writes (or rewrites) the current reel's watch record. Under 1 second watched is not
  /// recorded unless the reel ended, failed or [force] is set (spec 002 contract).
  void _saveWatch({bool force = false}) {
    final reel = _dose.current;
    if (reel == null) return;
    final reachedEnd = _dose.phase == MotivationPhase.endCard;
    if (_tracker.secondsWatched == 0 &&
        !force &&
        !reachedEnd &&
        !_startedFocus &&
        _watchEventId == null) {
      return;
    }

    // Reserve the id now, so a later write replaces this record even before the first completes.
    final id = _watchEventId ??= newId();
    _events.logReelWatched(
      reelId: reel.id,
      secondsWatched: _tracker.secondsWatched,
      completed: _reelCompleted || _tracker.completed,
      startedFocus: _startedFocus,
      id: id,
    );
  }

  void _onAppPaused() {
    // Stay paused on the same frame when the user comes back (video_player would resume).
    _current?.pause();
    _saveWatch();
  }

  // ---------- Actions ----------

  /// "Bỏ qua": start the planned session at once.
  Future<void> _skip() async {
    _saveWatch();
    if (!_dose.isEmpty) {
      _events.logMotivationSkipped(context: widget.reelContext, position: _dose.position);
    }
    _current?.pause();
    if (await _startSession(_planMinutes)) _dose.skip();
  }

  /// End-card start: the reel gets startedFocus only if a session really started.
  Future<void> _startFromReel(int minutes) async {
    _current?.pause();
    if (!await _startSession(minutes)) return;
    _dose.start();
    _startedFocus = true;
    _saveWatch(force: true);
  }

  Future<bool> _startSession(int minutes) => StudyStarter.start(context, ref, minutes: minutes);

  /// "Quay lại học": back to the running session.
  void _backToSession() {
    _saveWatch(force: true);
    _dose.backToSession();
    context.go(AppRoutes.focus);
  }

  /// "Tiếp": next reel, already preloaded in the common case.
  void _next() {
    _saveWatch(force: true);
    final previous = _dose.index;
    if (!_dose.next()) return;

    setState(() {
      _controllers.remove(previous)?.dispose();
      _tracker = ReelWatchTracker();
      _watchEventId = null;
      _reelCompleted = false;
      _startedFocus = false;
      // The preloaded reel may already have failed: show its end card at once.
      if (_current?.value.hasError ?? false) _dose.videoFailed();
    });
    final controller = _current;
    if (controller != null && controller.value.isInitialized) controller.play();
    _loadController(_dose.index);
    _loadController(_dose.index + 1);
  }

  /// Close button or system Back.
  void _leave() {
    _current?.pause();
    _saveWatch();
    _dose.leave();
    _leaveStep(context, ref);
  }

  void _onEndCardAction(EndCardAction action) {
    switch (action) {
      case EndCardAction.startPlanned:
        _startFromReel(_planMinutes);
      case EndCardAction.smallStep:
        _startFromReel(SessionPlan.smallStepMinutes);
      case EndCardAction.next:
        _next();
      case EndCardAction.backToSession:
        _backToSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final planMinutes = ref.watch(sessionPlanProvider.select((plan) => plan.plannedMinutes));
    final reel = _dose.current;
    final video = _current;
    final isEndCard = _dose.phase == MotivationPhase.endCard;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Stack(
        key: const ValueKey('reel-stage'),
        fit: StackFit.expand,
        children: [
          if (reel == null)
            const _CenterMessage(AppStrings.noMatchingReel)
          else
            GestureDetector(
              // Tap anywhere to pause or resume (FR-006). No drag handlers: swiping does nothing.
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlay,
              child: video == null
                  ? const _LoadingIndicator()
                  : _VideoLayer(controller: video, showPausedIcon: !isEndCard),
            ),
          // A thin scrim at the top keeps the progress bar and buttons readable on bright video.
          const IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: double.infinity,
                height: 120,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: AppColors.reelTopScrimGradient),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: isEndCard
                ? const ColoredBox(color: AppColors.reelBlurScrim)
                : const Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: 0.5,
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(gradient: AppColors.reelScrimGradient),
                      ),
                    ),
                  ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: _VideoProgress(controller: video),
                ),
                _TopBar(
                  positionLabel: reel == null ? null : _dose.positionLabel,
                  position: _dose.position,
                  total: _dose.playlist.length,
                  onClose: _leave,
                  onSkip: _dose.isDistracted ? null : _skip,
                ),
                const Spacer(),
                if (reel != null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: isEndCard
                        ? ReelEndCard(
                            actions: _dose.endCardActions,
                            plannedMinutes: planMinutes,
                            onAction: _onEndCardAction,
                          )
                        : _ReelInfo(
                            reel: reel,
                            onBackToSession: _dose.isDistracted ? _backToSession : null,
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Close, position "1/3" and "Bỏ qua" (before a session only).
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.positionLabel,
    required this.position,
    required this.total,
    required this.onClose,
    required this.onSkip,
  });

  final String? positionLabel;
  final int position;
  final int total;
  final VoidCallback onClose;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final label = positionLabel;
    return Row(
      children: [
        IconButton(
          icon: const Icon(AppIcons.close, color: AppColors.onVideo),
          tooltip: AppStrings.close,
          onPressed: onClose,
        ),
        if (label != null)
          Semantics(
            label: AppStrings.reelPositionLabel(position, total),
            excludeSemantics: true,
            child: _Pill(label: label),
          ),
        const Spacer(),
        if (onSkip != null)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.onVideo),
            onPressed: onSkip,
            child: const Text(AppStrings.skip),
          ),
      ],
    );
  }
}

/// Title and tags of the playing reel; after a distraction also "Quay lại học".
class _ReelInfo extends StatelessWidget {
  const _ReelInfo({required this.reel, required this.onBackToSession});

  final Reel reel;
  final VoidCallback? onBackToSession;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onBack = onBackToSession;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(reel.title, style: textTheme.headlineSmall?.copyWith(color: AppColors.onVideo)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [for (final tag in reel.tags) _Pill(label: tag.label)],
        ),
        if (onBack != null) ...[
          const SizedBox(height: AppSpacing.md),
          GradientPillButton(
            label: AppStrings.backToStudy,
            height: AppReels.buttonHeight,
            onPressed: onBack,
          ),
        ],
      ],
    );
  }
}

/// Small label on the video (tag, position). Drawn by hand instead of Material's Chip: Chip has
/// a white surface underneath, which turns the translucent colour into a solid white block.
class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: const BoxDecoration(
        color: AppColors.onVideoChip,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onVideo),
      ),
    );
  }
}

/// The whole video over its own blur; with a spinner, an error message and a paused icon.
class _VideoLayer extends StatelessWidget {
  const _VideoLayer({required this.controller, required this.showPausedIcon});

  /// On web the video is a <video> element: it cannot be drawn twice or blurred.
  static const bool _showBlurredBackground = AppReels.blurBackground && !kIsWeb;

  final VideoPlayerController controller;
  final bool showPausedIcon;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        if (value.hasError) return const _CenterMessage(AppStrings.reelPlayError);
        if (!value.isInitialized) return const _LoadingIndicator();

        return Stack(
          fit: StackFit.expand,
          children: [
            if (_showBlurredBackground)
              _BlurredVideoBackground(controller: controller, videoSize: value.size),
            _WholeVideo(controller: controller, aspectRatio: value.aspectRatio),
            if (showPausedIcon && !value.isPlaying)
              const Center(child: Icon(AppIcons.play, size: 96, color: AppColors.onVideoSecondary)),
          ],
        );
      },
    );
  }
}

/// Background: the same video, scaled to cover the page and blurred. Shares the controller.
class _BlurredVideoBackground extends StatelessWidget {
  const _BlurredVideoBackground({required this.controller, required this.videoSize});

  final VideoPlayerController controller;
  final Size videoSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: AppReels.blurSigma, sigmaY: AppReels.blurSigma),
            child: FittedBox(
              fit: BoxFit.cover,
              // Clip before blurring so the hidden part is not blurred for nothing.
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: videoSize.width,
                height: videoSize.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
        const ColoredBox(color: AppColors.reelBlurScrim),
      ],
    );
  }
}

/// Main layer: the video fitted inside the page, nothing cropped.
class _WholeVideo extends StatelessWidget {
  const _WholeVideo({required this.controller, required this.aspectRatio});

  final VideoPlayerController controller;
  final double aspectRatio;

  /// How far to lift the video above the page centre so the text below does not cover it.
  /// A tall portrait video leaves no room to avoid the text, so it stays centred.
  double _liftAboveOverlay(Size page) {
    final videoHeight = math.min(page.height, page.width / aspectRatio);
    final freeHeight = page.height - videoHeight;
    if (freeHeight < AppReels.overlayHeight) return 0;
    return math.max(0, AppReels.overlayHeight - freeHeight / 2);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Transform.translate(
        offset: Offset(0, -_liftAboveOverlay(constraints.biggest)),
        child: Center(
          child: AspectRatio(aspectRatio: aspectRatio, child: VideoPlayer(controller)),
        ),
      ),
    );
  }
}

/// Thin progress bar that follows the video.
class _VideoProgress extends StatelessWidget {
  const _VideoProgress({required this.controller});

  static const double _height = 3;

  final VideoPlayerController? controller;

  @override
  Widget build(BuildContext context) {
    final video = controller;
    if (video == null) {
      return const GradientProgressBar(
        value: 0,
        height: _height,
        trackColor: AppColors.onVideoTrack,
      );
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: video,
      builder: (context, value, child) {
        final total = value.duration.inMilliseconds;
        return GradientProgressBar(
          value: total == 0 ? 0 : value.position.inMilliseconds / total,
          height: _height,
          trackColor: AppColors.onVideoTrack,
        );
      },
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: AppColors.onVideoSecondary));
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onVideo),
        ),
      ),
    );
  }
}
