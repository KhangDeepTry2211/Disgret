// 5.4 Góc của Gret: the drawing style every mascot uses (spec 018). Placed under MaterialApp from
// the student's choice, so MascotView does not need Riverpod; without a scope (a widget pumped on
// its own) mascots are drawn in 3D mềm, the default.
import 'package:material_ui/material_ui.dart';

import '../../data/mascot_species.dart';

class MascotStyleScope extends InheritedWidget {
  const MascotStyleScope({required this.style, required super.child, super.key});

  final MascotStyle style;

  static const MascotStyle fallback = MascotStyle.soft;

  static MascotStyle of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MascotStyleScope>()?.style ?? fallback;

  @override
  bool updateShouldNotify(MascotStyleScope oldWidget) => style != oldWidget.style;
}
