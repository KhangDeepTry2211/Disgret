// 5.3 Gret và biển sống: the sea with Gret in it (spec 003 FR-007, FR-014–FR-018, contract
// ui-gret-sea.md). One looping controller per scene; with "remove animations" on, everything is
// still and the water shows its final colour at once.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/gret_corner_catalog.dart';
import '../../data/sea_time.dart';
import '../../providers/app_providers.dart';

import '../../data/mascot_mood.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../motion/reaction_wiggle.dart';
import 'sea_painter.dart';

enum SeaSceneVariant { hero, compact, full }

class SeaScene extends ConsumerStatefulWidget {
  const SeaScene({
    required this.clarity,
    required this.mood,
    this.variant = SeaSceneVariant.hero,
    this.onMascotTap,
    this.overlay,
    this.foreground,
    this.gretReaction = 0,
    this.look = const GretLook(),
    this.gretAlignment = SeaScene.defaultGretAlignment,
    this.skyShare = SeaPainter.defaultSkyShare,
    super.key,
  });

  /// 0–100.
  final double clarity;
  final MascotMood mood;
  final SeaSceneVariant variant;
  final VoidCallback? onMascotTap;

  /// Drawn above Gret (for example a speech bubble).
  final Widget? overlay;

  /// Fills the whole scene above Gret (for example the focus session's distraction effects).
  final Widget? foreground;

  /// Gret wiggles once each time this number changes (it batted a distraction away).
  final int gretReaction;

  /// The mascot, its outfit and the sea place (Góc của Gret, spec 004).
  final GretLook look;

  /// Where Gret swims by default, as an alignment inside the scene.
  static const Alignment defaultGretAlignment = Alignment(0, 0.45);

  /// Where Gret swims in this scene (Hôm nay puts Gret higher, spec 010).
  final Alignment gretAlignment;

  /// Share of the scene above the water.
  final double skyShare;

  @override
  ConsumerState<SeaScene> createState() => _SeaSceneState();
}

class _SeaSceneState extends ConsumerState<SeaScene> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: AppMotion.seaLoop,
  );
  bool _animationsOff = false;

  /// Turns the sea at the coming 06:00 or 18:00 while it stays open (spec 013).
  Timer? _turn;
  DateTime? _turnAt;

  void _turnAtNextSwitch(DateTime now) {
    final at = SeaTime.nextSwitch(now);
    if (at == _turnAt) return;
    _turnAt = at;
    _turn?.cancel();
    _turn = Timer(at.difference(now), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationsOff = MediaQuery.disableAnimationsOf(context);
    if (_animationsOff) {
      _loop.stop();
      _loop.value = 0;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _turn?.cancel();
    _loop.dispose();
    super.dispose();
  }

  double get _mascotSize => switch (widget.variant) {
    SeaSceneVariant.hero => AppMascot.hero,
    SeaSceneVariant.compact => AppMascot.compact,
    SeaSceneVariant.full => AppMascot.full,
  };

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final isNight = SeaTime.isNight(now);
    _turnAtNextSwitch(now);
    final label = AppStrings.seaSemantics(
      MascotLook.moodLabel(widget.mood),
      widget.clarity.round(),
    );

    final scene = TweenAnimationBuilder<double>(
      tween: Tween(end: widget.clarity),
      duration: _animationsOff ? Duration.zero : AppMotion.seaColour,
      curve: AppMotion.curve,
      builder: (context, clarity, child) => CustomPaint(
        painter: SeaPainter(
          loop: _loop,
          clarity: clarity,
          isNight: isNight,
          place: widget.look.place,
          skyShare: widget.skyShare,
        ),
        child: child,
      ),
      child: Stack(
        children: [
          Align(
            alignment: widget.gretAlignment,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ReactionWiggle(
                  trigger: widget.gretReaction,
                  child: MascotView(
                    mood: widget.mood,
                    size: _mascotSize,
                    species: widget.look.species,
                    outfit: widget.look.outfit,
                    onTap: widget.onMascotTap,
                  ),
                ),
                // A2 (spec 013): Gret lets out a few bubbles while awake.
                if (!_animationsOff && widget.mood != MascotMood.sleeping)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _MouthBubbles(loop: _loop)),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.foreground != null) Positioned.fill(child: widget.foreground!),
          if (widget.overlay != null)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                // On the sky, so it takes the sky's light or dark colours (spec 013).
                child: Theme(
                  data: AppTheme.forSky(night: isNight),
                  child: widget.overlay!,
                ),
              ),
            ),
        ],
      ),
    );

    final sized = switch (widget.variant) {
      SeaSceneVariant.hero => SizedBox(height: AppMascot.heroSceneHeight, child: scene),
      SeaSceneVariant.compact => SizedBox(height: AppMascot.compactSceneHeight, child: scene),
      SeaSceneVariant.full => SizedBox.expand(child: scene),
    };

    return Semantics(
      container: true,
      label: label,
      child: RepaintBoundary(
        child: widget.variant == SeaSceneVariant.full
            ? sized
            : ClipRRect(borderRadius: AppRadius.heroBorder, child: sized),
      ),
    );
  }
}

/// Bubbles rising from the mascot's mouth (the mouth sits at the same spot on every species).
class _MouthBubbles extends CustomPainter {
  _MouthBubbles({required this.loop}) : super(repaint: loop);

  final Animation<double> loop;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final progress = (loop.value * 3 + i / 3) % 1;
      final at = Offset(
        size.width * (0.44 - 0.1 * progress) + math.sin(progress * 6) * 3,
        size.height * (0.62 - 0.9 * progress),
      );
      canvas.drawCircle(
        at,
        2.5 + i,
        Paint()
          ..color = AppSea.bubble.withValues(alpha: AppSea.bubble.a * (1 - progress))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_MouthBubbles oldDelegate) => oldDelegate.loop != loop;
}
