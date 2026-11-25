// 5.3 Màn chờ (spec 011): after the system splash, Gret swims across the brand blue with rising
// bubbles, above "DisGret" and "Đang lặn xuống biển…", for AppMotion.launch; then the screen fades
// into the app. With "remove animations" on, Gret rests in the middle and the screen goes away
// after the same time. It lives above the router, so it shows once per cold start.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/mascot_mood.dart';
import '../l10n/app_strings.dart';
import '../providers/gret_corner_providers.dart';
import '../providers/launch_providers.dart';
import '../theme/app_theme.dart';
import 'mascot/mascot_view.dart';

enum _Stage { showing, fading, gone }

class LaunchOverlay extends ConsumerStatefulWidget {
  const LaunchOverlay({required this.child, super.key});

  /// The app (the router's screens) under the launch screen.
  final Widget child;

  /// Key of the launch screen itself, for tests.
  static const Key sceneKey = ValueKey('launch-scene');

  @override
  ConsumerState<LaunchOverlay> createState() => _LaunchOverlayState();
}

class _LaunchOverlayState extends ConsumerState<LaunchOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _swim = AnimationController(
    vsync: this,
    duration: AppMotion.launch,
  );
  _Stage _stage = _Stage.gone;
  bool _animationsOff = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!ref.read(launchScreenProvider)) return;
    _stage = _Stage.showing;
    // Count from the first frame on screen: the first frame of a cold start can take a while
    // (much longer in debug builds), and the student should still see the whole swim.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _timer = Timer(AppMotion.launch, () {
        if (!mounted) return;
        // Without animations the screen simply goes; otherwise it fades for launchFade.
        setState(() => _stage = _animationsOff ? _Stage.gone : _Stage.fading);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationsOff = MediaQuery.disableAnimationsOf(context);
    if (_animationsOff) {
      _swim.stop();
    } else if (_stage == _Stage.showing && !_swim.isAnimating && !_swim.isCompleted) {
      _swim.forward();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _swim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_stage != _Stage.gone)
          // While fading, taps already reach the app underneath.
          IgnorePointer(
            ignoring: _stage == _Stage.fading,
            child: AnimatedOpacity(
              opacity: _stage == _Stage.fading ? 0 : 1,
              duration: AppMotion.launchFade,
              onEnd: () {
                if (mounted && _stage == _Stage.fading) setState(() => _stage = _Stage.gone);
              },
              child: AbsorbPointer(
                child: BlockSemantics(
                  child: _LaunchScene(
                    key: LaunchOverlay.sceneKey,
                    swim: _swim,
                    still: _animationsOff,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LaunchScene extends ConsumerWidget {
  const _LaunchScene({required this.swim, required this.still, super.key});

  final Animation<double> swim;

  /// Animations removed: Gret rests in the middle and the bubbles stay put.
  final bool still;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final look = ref.watch(gretLookProvider);
    final text = Theme.of(context).textTheme;
    final gretHeight = AppLaunch.gret * AppMascot.canvasHeight / AppMascot.canvasWidth;

    return Material(
      color: AppLaunch.background,
      child: AnimatedBuilder(
        animation: swim,
        child: MascotView(
          mood: MascotMood.happy,
          size: AppLaunch.gret,
          species: look.species,
          outfit: look.outfit,
        ),
        builder: (context, gret) {
          final t = still ? null : swim.value;
          return CustomPaint(
            painter: _BubblesPainter(progress: t ?? 0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: gretHeight + AppLaunch.wave * 2,
                    width: double.infinity,
                    child: LayoutBuilder(
                      builder: (context, lane) {
                        final centreX = t == null
                            ? 0.5
                            : AppLaunch.startX +
                                  (AppLaunch.endX - AppLaunch.startX) *
                                      AppMotion.curve.transform(t);
                        final wave = t == null ? 0.0 : math.sin(t * math.pi * 3) * AppLaunch.wave;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: lane.maxWidth * centreX - AppLaunch.gret / 2,
                              top: AppLaunch.wave + wave,
                              child: gret!,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppStrings.appName,
                    style: text.displaySmall?.copyWith(color: AppLaunch.title),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DecoratedBox(
                    decoration: const ShapeDecoration(color: AppColors.sun, shape: StadiumBorder()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        AppStrings.launchLine,
                        style: text.labelLarge?.copyWith(color: AppColors.onSun),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bubbles rising through the blue; [progress] 0–1 moves each one up by its own speed.
class _BubblesPainter extends CustomPainter {
  _BubblesPainter({required this.progress});

  final double progress;

  /// (x share, start y share, radius, rise per launch as a share of the height).
  static const List<(double, double, double, double)> _bubbles = [
    (0.10, 0.86, 7, 0.30),
    (0.22, 0.64, 4, 0.22),
    (0.34, 0.95, 10, 0.36),
    (0.58, 0.80, 5, 0.26),
    (0.70, 0.98, 8, 0.34),
    (0.84, 0.70, 6, 0.24),
    (0.92, 0.90, 4, 0.30),
    (0.16, 0.30, 5, 0.20),
    (0.78, 0.26, 7, 0.22),
    (0.46, 0.18, 4, 0.18),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = AppLaunch.bubble.withValues(alpha: 0.35);
    final ring = Paint()
      ..color = AppLaunch.bubble
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final (x, y, radius, rise) in _bubbles) {
      final top = (y - progress * rise) % 1.0;
      final centre = Offset(size.width * x, size.height * top);
      canvas.drawCircle(centre, radius, fill);
      canvas.drawCircle(centre, radius, ring);
    }
  }

  @override
  bool shouldRepaint(_BubblesPainter oldDelegate) => oldDelegate.progress != progress;
}
