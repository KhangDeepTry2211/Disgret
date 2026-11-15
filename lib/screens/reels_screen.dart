// 1.4 Màn Reels: vuốt dọc, mỗi trang một video hiện trọn vẹn trên nền mờ, tự phát và lặp lại.
//
// Cách quản lý video để không tốn RAM và không phát tiếng ngầm:
// - Chỉ tạo controller của trang hiện tại và trang kế; trang khác được giải phóng khi vuốt xong.
// - Rời khỏi tab thì giải phóng hết (tab Reels vẫn sống ngầm trong IndexedStack của go_router).
// - Danh sách reel chỉ tính một lần mỗi khi vào màn, không đổi trong lúc đang vuốt.
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../data/models/event.dart';
import '../data/models/reel.dart';
import '../data/repositories/event_repository.dart';
import '../providers/app_providers.dart';
import '../providers/focus_session_provider.dart';
import '../router/app_router.dart';
import '../services/reel_recommender.dart';
import '../services/reel_share.dart';
import '../services/reel_watch_tracker.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/gradient_progress_bar.dart';
import '../widgets/reel_action_column.dart';
import '../widgets/reel_comments_sheet.dart';

class ReelsScreen extends ConsumerWidget {
  const ReelsScreen({this.reelContext = ReelContext.start, super.key});

  /// Ngữ cảnh đề xuất: tab Reels dùng "start", sau khi xao nhãng (3.3) dùng "distracted".
  final String reelContext;

  /// Số phút của phiên học khi bấm nút trên reel.
  static const int quickStartMinutes = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reels = ref.watch(reelsProvider);

    // Nền video luôn tối nên icon thanh trạng thái phải sáng.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.videoBackground,
        body: reels.when(
          loading: () => const _LoadingIndicator(),
          error: (error, stackTrace) => const _CenterMessage('Không tải được danh sách reel.'),
          data: (allReels) => _ReelFeed(
            // Đổi ngữ cảnh thì tạo lại toàn bộ feed cho đơn giản.
            key: ValueKey(reelContext),
            allReels: allReels,
            reelContext: reelContext,
          ),
        ),
      ),
    );
  }
}

class _ReelFeed extends ConsumerStatefulWidget {
  const _ReelFeed({required this.allReels, required this.reelContext, super.key});

  final List<Reel> allReels;
  final String reelContext;

  @override
  ConsumerState<_ReelFeed> createState() => _ReelFeedState();
}

class _ReelFeedState extends ConsumerState<_ReelFeed> {
  // keepPage: false để mỗi lần vào lại tab đều bắt đầu từ reel đầu tiên.
  final PageController _pageController = PageController(keepPage: false);

  /// Controller đang sống, theo số trang.
  final Map<int, VideoPlayerController> _controllers = {};

  late final EventRepository _events;
  late final AppLifecycleListener _lifecycleListener;

  List<Reel> _reels = const [];
  int _currentPage = 0;
  bool _isActive = false;
  ReelWatchTracker _tracker = ReelWatchTracker();

  @override
  void initState() {
    super.initState();
    _events = ref.read(eventRepositoryProvider);
    // Thoát ra màn hình chính thì lưu lượt xem ngay, vì app có thể bị hệ thống đóng sau đó.
    _lifecycleListener = AppLifecycleListener(onPause: _logCurrentWatch);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tab đang ẩn trong IndexedStack có TickerMode tắt: đây là cách biết người dùng đã rời tab.
    final isActive = TickerMode.valuesOf(context).enabled;
    if (isActive == _isActive) return;

    _isActive = isActive;
    if (isActive) {
      _enterFeed();
    } else {
      _leaveFeed();
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _leaveFeed();
    _pageController.dispose();
    super.dispose();
  }

  void _enterFeed() {
    // 1.3 Mỗi lần vào màn mới tính đề xuất, theo hồ sơ và lịch sử xem mới nhất.
    _reels = ReelRecommender(widget.allReels).recommend(
      ref.read(profileProvider),
      widget.reelContext,
      _events.getAll(),
      now: ref.read(clockProvider)(),
      likedReelIds: ref.read(reelLikesProvider),
    );
    _currentPage = 0;
    _tracker = ReelWatchTracker();
    _loadNearbyControllers();
  }

  void _leaveFeed() {
    _logCurrentWatch();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    // Không còn reel thì PageView bị gỡ, lần sau vào lại sẽ dựng mới từ trang đầu.
    _reels = const [];
  }

  /// Tạo controller của trang hiện tại và trang kế nếu chưa có.
  void _loadNearbyControllers() {
    for (final page in [_currentPage, _currentPage + 1]) {
      if (page < _reels.length && !_controllers.containsKey(page)) {
        _createController(page);
      }
    }
  }

  Future<void> _createController(int page) async {
    final controller = VideoPlayerController.asset(_reels[page].assetPath)..setLooping(true);
    _controllers[page] = controller;
    controller.addListener(() => _onVideoChanged(page, controller));

    try {
      await controller.initialize();
    } on PlatformException {
      // Video lỗi thì controller.value.hasError = true, trang đó tự hiện thông báo.
      return;
    }

    // Trong lúc chờ khởi tạo, người dùng có thể đã vuốt đi chỗ khác hoặc rời màn.
    if (!mounted || _controllers[page] != controller) return;
    setState(() {});
    if (page == _currentPage) await controller.play();
  }

  /// Giải phóng các trang không còn là trang hiện tại hay trang kế.
  void _disposeFarControllers() {
    final farPages = _controllers.keys
        .where((page) => page != _currentPage && page != _currentPage + 1)
        .toList();
    if (farPages.isEmpty) return;

    setState(() {
      for (final page in farPages) {
        _controllers.remove(page)!.dispose();
      }
    });
  }

  void _onVideoChanged(int page, VideoPlayerController controller) {
    if (page != _currentPage) return;
    _tracker.update(controller.value.position, controller.value.duration);
  }

  void _onPageChanged(int page) {
    _logCurrentWatch();
    _controllers[_currentPage]?.pause();

    final controller = _controllers[page];
    setState(() {
      _currentPage = page;
      _tracker = ReelWatchTracker(startPosition: controller?.value.position ?? Duration.zero);
    });

    if (controller != null && controller.value.isInitialized) controller.play();
    _loadNearbyControllers();
  }

  /// Ghi sự kiện reel_watched cho lượt xem đang theo dõi rồi bắt đầu lượt mới.
  /// Lướt qua dưới 1 giây thì không tính là đã xem, trừ khi bấm nút bắt đầu học từ reel đó.
  void _logCurrentWatch({bool startedFocus = false}) {
    if (_reels.isEmpty) return;
    if (_tracker.secondsWatched == 0 && !startedFocus) return;

    _events.logReelWatched(
      reelId: _reels[_currentPage].id,
      secondsWatched: _tracker.secondsWatched,
      completed: _tracker.completed,
      startedFocus: startedFocus,
    );
    _tracker = ReelWatchTracker(startPosition: _tracker.lastPosition);
  }

  void _startFocus() {
    _logCurrentWatch(startedFocus: true);
    context.go(AppRoutes.focusFor(ReelsScreen.quickStartMinutes));
  }

  /// 3.3 Đang có phiên học: chỉ quay về phiên đó, không tạo phiên mới.
  void _backToSession() {
    _logCurrentWatch();
    context.go(AppRoutes.focus);
  }

  /// Mở bình luận: tạm dừng video, đóng sheet thì phát lại nếu trước đó đang phát.
  Future<void> _openComments(Reel reel) async {
    final video = _controllers[_currentPage];
    final wasPlaying = video?.value.isPlaying ?? false;
    video?.pause();
    await showReelCommentsSheet(context, reelId: reel.id);
    if (wasPlaying && mounted && _isActive && _controllers[_currentPage] == video) video?.play();
  }

  Future<void> _share(Reel reel) async {
    final outcome = await ReelShare.share(reel);
    if (outcome != ReelShareOutcome.failed) {
      await _events.logReelAction(EventType.reelShared, reel.id);
    }
    if (!mounted) return;
    final message = switch (outcome) {
      ReelShareOutcome.copiedToClipboard => 'Đã chép nội dung chia sẻ',
      ReelShareOutcome.failed => 'Không chia sẻ được',
      ReelShareOutcome.shared => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInSession = ref.watch(focusSessionProvider.select((session) => session.isRunning));

    if (_reels.isEmpty) {
      return _isActive
          ? const _CenterMessage('Chưa có reel phù hợp.')
          : const SizedBox.expand(); // Tab đang ẩn thì không vẽ gì.
    }

    return NotificationListener<ScrollEndNotification>(
      // Chờ vuốt xong mới giải phóng, để trang cũ không bị đen khi còn đang trượt đi.
      onNotification: (notification) {
        _disposeFarControllers();
        return false;
      },
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _reels.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, page) => _ReelPage(
          reel: _reels[page],
          controller: _controllers[page],
          isCurrent: page == _currentPage,
          actionLabel: isInSession
              ? 'Quay lại học'
              : 'Bắt đầu ${ReelsScreen.quickStartMinutes} phút',
          onAction: isInSession ? _backToSession : _startFocus,
          onToggleLike: () => ref.read(reelLikesProvider.notifier).toggle(_reels[page].id),
          onDoubleTapLike: () =>
              ref.read(reelLikesProvider.notifier).setLiked(_reels[page].id, liked: true),
          onComments: () => _openComments(_reels[page]),
          onShare: () => _share(_reels[page]),
        ),
      ),
    );
  }
}

class _ReelPage extends StatefulWidget {
  const _ReelPage({
    required this.reel,
    required this.controller,
    required this.isCurrent,
    required this.actionLabel,
    required this.onAction,
    required this.onToggleLike,
    required this.onDoubleTapLike,
    required this.onComments,
    required this.onShare,
  });

  final Reel reel;
  final VideoPlayerController? controller;
  final bool isCurrent;

  /// Nút dưới video: "Bắt đầu 5 phút", hoặc "Quay lại học" khi đang có phiên.
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onToggleLike;
  final VoidCallback onDoubleTapLike;
  final VoidCallback onComments;
  final VoidCallback onShare;

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> {
  /// Trái tim lớn đang bay, mỗi lần chạm đúp một trái.
  final List<({int id, Offset center})> _hearts = [];
  int _nextHeartId = 0;

  DateTime? _lastTapAt;
  Offset _lastTapPosition = Offset.zero;

  void _togglePlay() {
    final video = widget.controller;
    if (video == null || !video.value.isInitialized) return;
    video.value.isPlaying ? video.pause() : video.play();
  }

  /// Phân biệt chạm đơn và chạm đúp mà KHÔNG chờ: chạm đầu tạm dừng/phát ngay (không trễ);
  /// nếu chạm thứ hai tới kịp thì đổi lại trạng thái phát rồi thích video.
  /// (GestureDetector.onDoubleTap bắt chạm đơn phải chờ ~300ms nên không dùng.)
  void _onTapUp(TapUpDetails details) {
    final now = DateTime.now();
    final lastAt = _lastTapAt;
    final isDoubleTap =
        lastAt != null &&
        now.difference(lastAt) <= AppReels.doubleTapWindow &&
        (details.localPosition - _lastTapPosition).distance <= AppReels.doubleTapSlop;

    if (isDoubleTap) {
      _lastTapAt = null;
      _togglePlay(); // Hoàn lại lần đổi của chạm đầu.
      widget.onDoubleTapLike();
      setState(() => _hearts.add((id: _nextHeartId++, center: details.localPosition)));
    } else {
      _lastTapAt = now;
      _lastTapPosition = details.localPosition;
      _togglePlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final video = widget.controller;
    final reel = widget.reel;

    return GestureDetector(
      // Chạm vào bất cứ đâu để tạm dừng/phát, chạm đúp để thích; các nút tự xử lý phần của nó.
      behavior: HitTestBehavior.opaque,
      onTapUp: _onTapUp,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (video == null)
            const _LoadingIndicator()
          else
            _VideoLayer(controller: video, isCurrent: widget.isCurrent),
          // Lớp mờ mỏng ở đỉnh để đồng hồ và thanh tiến độ vẫn rõ trên video sáng.
          const Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: double.infinity,
              height: 120,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.reelTopScrimGradient),
              ),
            ),
          ),
          // Lớp mờ gradient đen ở nửa dưới để chữ dễ đọc.
          const Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.5,
              widthFactor: 1,
              child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.reelScrimGradient)),
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
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tiêu đề và chip tag bên trái, cột Tim / Bình luận / Chia sẻ bên phải.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reel.title,
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: AppColors.onVideo,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.xs,
                                  children: [
                                    for (final tag in reel.tags) _TagChip(label: tag.label),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ReelActionColumn(
                            reelId: reel.id,
                            onToggleLike: widget.onToggleLike,
                            onComments: widget.onComments,
                            onShare: widget.onShare,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GradientPillButton(
                        label: widget.actionLabel,
                        height: 56,
                        onPressed: widget.onAction,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final heart in _hearts)
            BurstHeart(
              key: ValueKey(heart.id),
              center: heart.center,
              onEnd: () => setState(() => _hearts.removeWhere((item) => item.id == heart.id)),
            ),
        ],
      ),
    );
  }
}

/// Chip tag nổi trên video. Tự vẽ thay vì dùng Chip của Material: Chip có lớp nền trắng
/// bên dưới nên màu trong suốt thành khối trắng đặc, làm mất chữ trắng.
class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

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

/// Video hiện trọn vẹn trên nền mờ; kèm vòng chờ, thông báo lỗi và biểu tượng khi đang tạm dừng.
class _VideoLayer extends StatelessWidget {
  const _VideoLayer({required this.controller, required this.isCurrent});

  /// Trên web, video là một thẻ <video> nên không vẽ được 2 lần và không làm mờ được.
  static const bool _showBlurredBackground = AppReels.blurBackground && !kIsWeb;

  final VideoPlayerController controller;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        if (value.hasError) return const _CenterMessage('Không phát được video này.');
        if (!value.isInitialized) return const _LoadingIndicator();

        return Stack(
          fit: StackFit.expand,
          children: [
            if (_showBlurredBackground)
              _BlurredVideoBackground(controller: controller, videoSize: value.size),
            _WholeVideo(controller: controller, aspectRatio: value.aspectRatio),
            if (isCurrent && !value.isPlaying)
              const Center(child: Icon(AppIcons.play, size: 96, color: AppColors.onVideoSecondary)),
          ],
        );
      },
    );
  }
}

/// Lớp nền: chính video đó phóng kín trang rồi làm mờ. Dùng chung controller với lớp chính.
class _BlurredVideoBackground extends StatelessWidget {
  const _BlurredVideoBackground({required this.controller, required this.videoSize});

  final VideoPlayerController controller;
  final Size videoSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ClipRect giữ độ mờ trong trang, không loang sang trang bên cạnh khi đang vuốt.
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: AppReels.blurSigma, sigmaY: AppReels.blurSigma),
            child: FittedBox(
              fit: BoxFit.cover,
              // Cắt phần thừa trước khi làm mờ để không tốn công làm mờ phần không nhìn thấy.
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

/// Lớp chính: video co vừa khung, không cắt mất phần nào.
class _WholeVideo extends StatelessWidget {
  const _WholeVideo({required this.controller, required this.aspectRatio});

  final VideoPlayerController controller;
  final double aspectRatio;

  /// Khoảng cần đẩy video lên so với giữa trang để không nằm dưới chữ và nút.
  /// Video dọc cao gần hết trang thì không đủ chỗ để tránh, giữ nguyên ở giữa.
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

/// Thanh tiến độ mảnh chạy theo video.
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
