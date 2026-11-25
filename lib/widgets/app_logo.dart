// 5.2 Logo DisGret (spec 008): a white bubble holding a blue "D", with Gret peeking up from the
// bottom-right corner of a sunny-sea blue tile. One SVG source, drawn crisp at every size; the
// launcher icon and splash PNGs are rendered from the same file.
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 32, super.key});

  static const String assetPath = 'assets/branding/logo.svg';

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(assetPath, width: size, height: size, semanticsLabel: 'Logo DisGret');
  }
}
