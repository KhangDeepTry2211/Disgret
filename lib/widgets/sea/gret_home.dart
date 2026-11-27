// 5.3 Gret và biển sống: Gret's home (spec 019 user story 5). Two rock ledges beside Gret: the
// right one carries the shell house and one decoration spot, the left one two spots. Hôm nay's
// cards cover the sea floor, so the home sits at Gret's level, like a little floating reef.
// Empty spots show a dashed ring; decorations are bought and placed in Góc của Gret.
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/gret_corner_catalog.dart';
import '../../theme/app_theme.dart';

class GretHomeLedge extends StatelessWidget {
  const GretHomeLedge({required this.right, required this.width, this.decor = const {}, super.key});

  /// The right ledge (house and one spot) or the left one (two spots).
  final bool right;
  final double width;

  /// Drawings of the placed decorations, by spot.
  final Map<DecorSpot, String> decor;

  static const double _canvasWidth = 220;
  static const double _canvasHeight = 160;
  static const double _decoSize = 80;
  static const double _decoTop = 36;

  /// Left edge of each spot on its ledge's canvas (scene_art.py).
  static const Map<DecorSpot, double> _spotLeft = {
    DecorSpot.leftBack: 22,
    DecorSpot.leftFront: 118,
    DecorSpot.byHouse: 10,
  };

  @override
  Widget build(BuildContext context) {
    final unit = width / _canvasWidth;
    final spots = right
        ? const [DecorSpot.byHouse]
        : const [DecorSpot.leftBack, DecorSpot.leftFront];

    Widget canvas(String asset) =>
        SvgPicture.asset(asset, width: width, height: _canvasHeight * unit, fit: BoxFit.fill);

    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: _canvasHeight * unit,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            canvas('assets/scene/home_ledge.svg'),
            if (right) canvas('assets/scene/home_house.svg'),
            for (final spot in spots)
              Positioned(
                left: _spotLeft[spot]! * unit,
                top: _decoTop * unit,
                child: SvgPicture.asset(
                  decor[spot] ?? 'assets/scene/deco_spot.svg',
                  width: _decoSize * unit,
                  height: _decoSize * unit,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Width of a ledge in a scene of [sceneWidth].
  static double widthIn(double sceneWidth) =>
      (sceneWidth * AppMascot.homeLedgeShare).clamp(0, AppMascot.homeLedgeMax);
}
