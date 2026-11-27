// 3.2 Phiên học: Gret at its own desk, working while the student studies (spec 019 user story 1).
// The mascot sits behind the desk (the desk hides it below the mouth) and the props move, never
// the limbs, so every species and drawing style works the same: the pen crosses the notebook,
// the laptop's keys light up, a page of the book turns. With "remove animations" all of it is
// still.
import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/gret_corner_catalog.dart';
import '../../data/gret_work.dart';
import '../../data/mascot_mood.dart';
import '../../data/mascot_species.dart';
import '../../theme/app_theme.dart';
import 'mascot_view.dart';

class MascotAtDesk extends StatefulWidget {
  const MascotAtDesk({
    required this.mood,
    required this.desk,
    this.task,
    this.species = MascotSpecies.gret,
    this.outfit = const {},
    this.size = AppMascot.full,
    this.onTap,
    super.key,
  });

  final MascotMood mood;
  final DeskKind desk;

  /// What Gret is doing; null on a break (an empty desk).
  final WorkTask? task;
  final MascotSpecies species;
  final Map<OutfitSlot, String> outfit;

  /// Width of the mascot, as for [MascotView]; the desk is wider.
  final double size;
  final VoidCallback? onTap;

  @override
  State<MascotAtDesk> createState() => _MascotAtDeskState();
}

class _MascotAtDeskState extends State<MascotAtDesk> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: AppMotion.deskLoop,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop
        ..stop()
        ..value = 0;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.size / AppMascot.canvasWidth;
    final deskTop =
        (AppMascot.deskTopOnMascot * AppMascot.canvasHeight - AppMascot.deskTopY) * unit;
    final width = AppMascot.deskCanvasWidth * unit;
    final deskHeight = AppMascot.deskCanvasHeight * unit;
    final inset = (AppMascot.deskCanvasWidth - AppMascot.canvasWidth) / 2 * unit;

    Widget layer(String name) => SvgPicture.asset(
      'assets/scene/$name.svg',
      width: width,
      height: deskHeight,
      fit: BoxFit.fill,
    );

    final task = widget.task;
    return SizedBox(
      width: width,
      height: deskTop + deskHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: inset,
            top: 0,
            child: MascotView(
              mood: widget.mood,
              species: widget.species,
              outfit: widget.outfit,
              size: widget.size,
              onTap: widget.onTap,
            ),
          ),
          Positioned(
            left: 0,
            top: deskTop,
            child: layer(widget.desk == DeskKind.coral ? 'desk_coral' : 'desk_wood'),
          ),
          if (task != null)
            Positioned(
              left: 0,
              top: deskTop,
              child: AnimatedBuilder(
                animation: _loop,
                builder: (context, _) => _props(task, _loop.value, unit, layer),
              ),
            ),
        ],
      ),
    );
  }

  Widget _props(WorkTask task, double t, double unit, Widget Function(String) layer) {
    switch (task) {
      case WorkTask.writing:
        // The pen writes along a line, twice per loop, one line lower the second time.
        final phase = (t * 2) % 1;
        final line = t < 0.5 ? 0.0 : _lineStep;
        final wobble = math.sin(phase * math.pi * 12) * _penWobble;
        return Stack(
          children: [
            layer('notebook'),
            Transform.translate(
              offset: Offset(
                (_penFrom + (_penTo - _penFrom) * phase) * unit,
                (line + wobble) * unit,
              ),
              child: layer('pen'),
            ),
          ],
        );
      case WorkTask.typing:
        final lit = (t * _keyBlinks).floor().isEven;
        return Stack(
          children: [
            layer('laptop'),
            Opacity(opacity: lit ? 1 : _keysDim, child: layer('laptop_keys')),
          ],
        );
      case WorkTask.reading:
        // A page turns over the spine during the first part of the loop, then rests.
        final flip = (t / _flipShare).clamp(0.0, 1.0);
        return Stack(
          children: [
            layer('book'),
            Transform(
              alignment: const Alignment(_spineX / AppMascot.deskCanvasWidth * 2 - 1, 0),
              transform: Matrix4.diagonal3Values(math.cos(flip * math.pi), 1, 1),
              child: layer('book_page'),
            ),
          ],
        );
    }
  }

  // Geometry of the props on the desk canvas (scene_art.py), in mascot units.
  static const double _penFrom = -30;
  static const double _penTo = 44;
  static const double _lineStep = 4;
  static const double _penWobble = 1.5;
  static const int _keyBlinks = 10;
  static const double _keysDim = 0.2;
  static const double _flipShare = 0.35;
  static const double _spineX = 98;
}

/// A mascot sitting behind furniture, on the same canvas as [MascotAtDesk]: [behind] layers (a
/// chair back) are drawn first, then the mascot, then [front] layers (a table and what is on it,
/// or the café counter). Names are files in assets/scene (spec 019).
class MascotSeated extends StatelessWidget {
  const MascotSeated({
    required this.mood,
    required this.species,
    required this.size,
    this.behind = const [],
    this.front = const [],
    super.key,
  });

  final MascotMood mood;
  final MascotSpecies species;
  final double size;
  final List<String> behind;
  final List<String> front;

  @override
  Widget build(BuildContext context) {
    final unit = size / AppMascot.canvasWidth;
    final deskTop =
        (AppMascot.deskTopOnMascot * AppMascot.canvasHeight - AppMascot.deskTopY) * unit;
    final width = AppMascot.deskCanvasWidth * unit;
    final deskHeight = AppMascot.deskCanvasHeight * unit;
    final inset = (AppMascot.deskCanvasWidth - AppMascot.canvasWidth) / 2 * unit;

    Widget layer(String name) => Positioned(
      left: 0,
      top: deskTop,
      child: SvgPicture.asset(
        'assets/scene/$name.svg',
        width: width,
        height: deskHeight,
        fit: BoxFit.fill,
      ),
    );

    return SizedBox(
      width: width,
      height: deskTop + deskHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final name in behind) layer(name),
          Positioned(
            left: inset,
            top: 0,
            child: MascotView(mood: mood, species: species, size: size),
          ),
          for (final name in front) layer(name),
        ],
      ),
    );
  }
}
