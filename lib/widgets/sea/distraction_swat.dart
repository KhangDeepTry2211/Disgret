// 5.3 Gret và biển sống: Gret guards the study session (spec 003 FR-012a). Now and then a
// distraction (a reel, a notification, a message) drifts towards Gret and pops when Gret bats it
// away; coming back after a real distraction bursts several away at once. Decorative only: it
// changes no data, and nothing runs with animations removed (FR-015) or during a break.
import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';
import 'sea_scene.dart';

class DistractionSwatLayer extends StatefulWidget {
  const DistractionSwatLayer({
    required this.active,
    required this.distractions,
    required this.onSwat,
    super.key,
  });

  /// The session is running (not on a break).
  final bool active;

  /// Distractions so far in the session; an increase bursts a few distractions away.
  final int distractions;

  /// Gret batted a distraction away (the scene wiggles Gret).
  final VoidCallback onSwat;

  @override
  State<DistractionSwatLayer> createState() => _DistractionSwatLayerState();
}

class _DistractionSwatLayerState extends State<DistractionSwatLayer> with TickerProviderStateMixin {
  /// Share of the drift spent travelling; the rest is the pop.
  static const double _travel = 0.7;

  /// Where the burst sends its three distractions.
  static const List<Alignment> _burstTargets = [
    Alignment(-1.2, -0.3),
    Alignment(1.2, 0),
    Alignment(0.2, -1.2),
  ];

  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: AppMotion.distractionDrift,
  )..addListener(_onDriftTick);
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: AppMotion.distractionBurst,
  );
  final math.Random _random = math.Random();
  Timer? _next;
  bool _animationsOff = false;
  bool _swatted = false;
  Alignment _from = Alignment.centerLeft;
  IconData _icon = AppIcons.distractions.first;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationsOff = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(DistractionSwatLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.distractions > oldWidget.distractions && widget.active && !_animationsOff) {
      _burst.forward(from: 0);
      // The parent rebuilds on a swat, which must not happen while this widget is building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSwat();
      });
    }
    _sync();
  }

  @override
  void dispose() {
    _next?.cancel();
    _drift.dispose();
    _burst.dispose();
    super.dispose();
  }

  /// Schedules the next drifting distraction while the session runs; stops otherwise.
  void _sync() {
    if (widget.active && !_animationsOff) {
      if (!(_next?.isActive ?? false) && !_drift.isAnimating) {
        _next = Timer(AppMotion.distractionEvery, _launch);
      }
    } else {
      _next?.cancel();
      _drift
        ..stop()
        ..value = 0;
    }
  }

  void _launch() {
    if (!mounted) return;
    setState(() {
      final fromLeft = _random.nextBool();
      _from = Alignment(fromLeft ? -1.3 : 1.3, -0.1 + _random.nextDouble() * 0.6);
      _icon = AppIcons.distractions[_random.nextInt(AppIcons.distractions.length)];
      _swatted = false;
    });
    _drift.forward(from: 0).whenComplete(() {
      if (mounted) _sync();
    });
  }

  void _onDriftTick() {
    if (!_swatted && _drift.value >= _travel) {
      _swatted = true;
      widget.onSwat();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Decorative: no touches, nothing for screen readers.
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: Listenable.merge([_drift, _burst]),
          builder: (context, _) => Stack(
            children: [
              if (_drift.isAnimating) _buildDrift(),
              if (_burst.isAnimating) ..._buildBurst(),
            ],
          ),
        ),
      ),
    );
  }

  /// One distraction travelling to Gret, then popping.
  Widget _buildDrift() {
    final t = _drift.value;
    final travel = AppMotion.curve.transform((t / _travel).clamp(0.0, 1.0));
    final pop = ((t - _travel) / (1 - _travel)).clamp(0.0, 1.0);
    // It stops just before Gret, on the side it came from.
    final target = Alignment(_from.x.sign * 0.5, SeaScene.defaultGretAlignment.y - 0.1);

    return Align(
      key: const ValueKey('distraction-bubble'),
      alignment: Alignment.lerp(_from, target, travel)!,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 1 - pop,
            child: Transform.scale(
              scale: 1 + pop * AppMascot.reactionScale,
              child: _Distraction(icon: _icon),
            ),
          ),
          if (pop > 0) _Sparkles(progress: pop),
        ],
      ),
    );
  }

  /// Three distractions flung away from Gret at once.
  List<Widget> _buildBurst() {
    final t = AppMotion.curve.transform(_burst.value);
    return [
      for (var i = 0; i < _burstTargets.length; i++)
        Align(
          key: ValueKey('distraction-burst-$i'),
          alignment: Alignment.lerp(SeaScene.defaultGretAlignment, _burstTargets[i], t)!,
          child: Opacity(
            opacity: 1 - t,
            child: Transform.rotate(
              angle: t * math.pi * (i.isEven ? 1 : -1),
              child: _Distraction(icon: AppIcons.distractions[i % AppIcons.distractions.length]),
            ),
          ),
        ),
      Align(
        alignment: SeaScene.defaultGretAlignment,
        child: _Sparkles(progress: t),
      ),
    ];
  }
}

/// A distraction: a round badge with a reel, notification or message icon.
class _Distraction extends StatelessWidget {
  const _Distraction({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: AppStatCard.badge,
      height: AppStatCard.badge,
      decoration: BoxDecoration(color: scheme.errorContainer, shape: BoxShape.circle),
      child: Icon(icon, size: AppStatCard.icon, color: scheme.onErrorContainer),
    );
  }
}

/// Sparkles growing and fading where a distraction popped.
class _Sparkles extends StatelessWidget {
  const _Sparkles({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 1 - progress,
      child: Icon(AppIcons.sparkle, size: AppStatCard.badge * (1 + progress), color: AppSea.fish),
    );
  }
}
