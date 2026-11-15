// 1.4 Cột nút Tim, Bình luận, Chia sẻ bên phải mỗi reel, và trái tim lớn nổi lên khi chạm đúp.
// Chỉ dùng icon Material, màu lấy từ app_theme.dart (AppColors.onVideo…, AppReels…).
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

class ReelActionColumn extends ConsumerWidget {
  const ReelActionColumn({
    required this.reelId,
    required this.onToggleLike,
    required this.onComments,
    required this.onShare,
    super.key,
  });

  final String reelId;
  final VoidCallback onToggleLike;
  final VoidCallback onComments;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(reelLikesProvider.select((ids) => ids.contains(reelId)));
    // Số bình luận thật của reel này, không bịa số liệu.
    final commentCount = ref.watch(
      reelCommentsProvider.select(
        (comments) => comments.where((comment) => comment.reelId == reelId).length,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          key: const ValueKey('reel_like'),
          semanticLabel: liked ? 'Bỏ thích' : 'Thích',
          label: liked ? 'Đã thích' : 'Thích',
          onTap: onToggleLike,
          icon: _BounceIcon(liked: liked),
        ),
        const SizedBox(height: AppSpacing.md),
        _ActionButton(
          key: const ValueKey('reel_comment'),
          semanticLabel: commentCount == 0 ? 'Bình luận' : 'Bình luận, $commentCount',
          // Chưa có bình luận thì ẩn số, chỉ hiện nhãn.
          label: commentCount == 0 ? 'Bình luận' : '$commentCount',
          onTap: onComments,
          icon: const Icon(
            AppIcons.comment,
            size: AppReels.actionIconSize,
            color: AppColors.onVideo,
            shadows: AppReels.onVideoShadows,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ActionButton(
          key: const ValueKey('reel_share'),
          semanticLabel: 'Chia sẻ',
          label: 'Chia sẻ',
          onTap: onShare,
          icon: const Icon(
            AppIcons.share,
            size: AppReels.actionIconSize,
            color: AppColors.onVideo,
            shadows: AppReels.onVideoShadows,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.semanticLabel,
    required this.label,
    required this.onTap,
    required this.icon,
    super.key,
  });

  final String semanticLabel;
  final String label;
  final VoidCallback onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: AppReels.actionWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: AppColors.onVideo, shadows: AppReels.onVideoShadows),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trái tim: đặc và màu nhấn khi đã thích, rỗng khi chưa; nảy nhẹ lúc vừa được thích.
class _BounceIcon extends StatefulWidget {
  const _BounceIcon({required this.liked});

  final bool liked;

  @override
  State<_BounceIcon> createState() => _BounceIconState();
}

class _BounceIconState extends State<_BounceIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppReels.likeBounceDuration,
  );

  @override
  void didUpdateWidget(_BounceIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.liked && !oldWidget.liked) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          Transform.scale(scale: 1 + 0.35 * math.sin(math.pi * _controller.value), child: child),
      child: Icon(
        widget.liked ? AppIcons.likeFilled : AppIcons.like,
        size: AppReels.actionIconSize,
        color: widget.liked ? AppColors.reelLiked : AppColors.onVideo,
        shadows: AppReels.onVideoShadows,
      ),
    );
  }
}

/// Trái tim lớn tại chỗ chạm đúp: phóng to, bay lên một đoạn rồi mờ đi, xong thì gọi [onEnd].
class BurstHeart extends StatelessWidget {
  const BurstHeart({required this.center, required this.onEnd, super.key});

  final Offset center;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - AppReels.burstHeartSize / 2,
      top: center.dy - AppReels.burstHeartSize / 2,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppReels.burstDuration,
          onEnd: onEnd,
          builder: (context, t, child) => Opacity(
            opacity: t < 0.5 ? 1 : (1 - (t - 0.5) * 2).clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, -60 * t),
              child: Transform.scale(
                scale: 0.6 + 0.6 * Curves.easeOut.transform(math.min(t * 3, 1)),
                child: child,
              ),
            ),
          ),
          child: const Icon(
            AppIcons.likeFilled,
            size: AppReels.burstHeartSize,
            color: AppColors.reelLiked,
            shadows: AppReels.onVideoShadows,
          ),
        ),
      ),
    );
  }
}
