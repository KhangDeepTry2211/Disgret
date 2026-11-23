// 5.3 Gret và biển sống: a quick left-right turn each time [trigger] changes, for Gret batting a
// distraction away (spec 003 FR-012a). Nothing moves when animations are removed (FR-015).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

class ReactionWiggle extends StatefulWidget {
  const ReactionWiggle({required this.trigger, required this.child, super.key});

  final int trigger;
  final Widget child;

  @override
  State<ReactionWiggle> createState() => _ReactionWiggleState();
}

class _ReactionWiggleState extends State<ReactionWiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.wiggle,
  );

  @override
  void didUpdateWidget(ReactionWiggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
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
      // Two swings that fade out: sin over two full periods, damped by (1 - t).
      builder: (context, child) => Transform.rotate(
        angle:
            math.sin(_controller.value * 4 * math.pi) *
            (1 - _controller.value) *
            AppMascot.wiggleTurns *
            2 *
            math.pi,
        child: child,
      ),
      child: widget.child,
    );
  }
}
