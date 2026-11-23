// 5.3 Gret và biển sống: a number that counts up to its new value (spec 003 FR-014).
import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

class CountUpText extends StatelessWidget {
  const CountUpText({required this.value, required this.format, this.style, super.key});

  final int value;
  final String Function(int value) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final off = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: off ? value.toDouble() : 0, end: value.toDouble()),
      duration: off ? Duration.zero : AppMotion.countUp,
      curve: AppMotion.curve,
      builder: (context, shown, _) => Text(format(shown.round()), style: style),
    );
  }
}
