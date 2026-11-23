// 5.3 Gret và biển sống: the mascot, drawn from stacked SVG layers, bobbing and blinking while
// idle (spec 003 FR-014, FR-015, FR-020). With "remove animations" on it stands still.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/gret_corner_catalog.dart';
import '../../data/mascot_mood.dart';
import '../../theme/app_theme.dart';
import 'mascot_look.dart';

class MascotView extends StatefulWidget {
  const MascotView({
    required this.mood,
    this.species = MascotSpecies.gret,
    this.outfit = const {},
    this.size = AppMascot.hero,
    this.onTap,
    super.key,
  });

  final MascotMood mood;
  final MascotSpecies species;

  /// Worn items by slot (drawing paths), spec 004.
  final Map<OutfitSlot, String> outfit;

  /// Width of the mascot; the height follows the shared 240×200 canvas.
  final double size;
  final VoidCallback? onTap;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(vsync: this, duration: AppMotion.bob);
  final math.Random _random = math.Random();
  Timer? _blinkTimer;
  bool _blinking = false;
  bool _animationsOff = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationsOff = MediaQuery.disableAnimationsOf(context);
    if (_animationsOff) {
      _bob.stop();
      _bob.value = 0;
      _blinkTimer?.cancel();
      _blinking = false;
    } else {
      if (!_bob.isAnimating) _bob.repeat(reverse: true);
      _scheduleBlink();
    }
  }

  @override
  void didUpdateWidget(MascotView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sleeping breathes slower than the other moods.
    final duration = widget.mood == MascotMood.sleeping ? AppMotion.bob * 1.6 : AppMotion.bob;
    if (_bob.duration != duration) {
      _bob.duration = duration;
      if (!_animationsOff) _bob.repeat(reverse: true);
    }
  }

  void _scheduleBlink() {
    if (_blinkTimer?.isActive ?? false) return;
    final seconds =
        AppMotion.blinkMinSeconds +
        _random.nextInt(AppMotion.blinkMaxSeconds - AppMotion.blinkMinSeconds + 1);
    _blinkTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted || _animationsOff) return;
      setState(() => _blinking = true);
      _blinkTimer = Timer(AppMotion.blink, () {
        if (!mounted) return;
        setState(() => _blinking = false);
        _scheduleBlink();
      });
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.size * AppMascot.canvasHeight / AppMascot.canvasWidth;
    final layers = MascotLook.layers(
      widget.mood,
      species: widget.species,
      blinking: _blinking,
      outfit: widget.outfit,
    );

    final drawing = SizedBox(
      width: widget.size,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [for (final path in layers) SvgPicture.asset(path, fit: BoxFit.contain)],
      ),
    );

    final animated = AnimatedBuilder(
      animation: _bob,
      child: drawing,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_bob.value);
        // Focused and sleeping breathe (slight scale); the others bob up and down.
        final breathing = widget.mood == MascotMood.focused || widget.mood == MascotMood.sleeping;
        return Transform.translate(
          offset: Offset(0, breathing ? 0 : -AppMascot.bobAmplitude * t),
          child: Transform.scale(scale: breathing ? 1 + 0.025 * t : 1, child: child),
        );
      },
    );

    return GestureDetector(onTap: widget.onTap, behavior: HitTestBehavior.opaque, child: animated);
  }
}
