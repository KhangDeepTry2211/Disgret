// 5.3 Gret và biển sống: children fade in and rise slightly one after another when the screen
// opens (spec 003 FR-014). With "remove animations" on, they are shown at once (FR-015).
import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({required this.children, super.key});

  final List<Widget> children;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _total(widget.children.length),
  );
  bool _started = false;

  static Duration _total(int count) =>
      AppMotion.entrance + AppMotion.entranceStep * (count > 0 ? count - 1 : 0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _total(widget.children.length).inMilliseconds;
    final step = AppMotion.entranceStep.inMilliseconds;
    final length = AppMotion.entrance.inMilliseconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _Entering(
            animation: CurvedAnimation(
              parent: _controller,
              curve: Interval(
                (i * step / total).clamp(0.0, 1.0),
                ((i * step + length) / total).clamp(0.0, 1.0),
                curve: AppMotion.curve,
              ),
            ),
            child: widget.children[i],
          ),
      ],
    );
  }
}

class _Entering extends StatelessWidget {
  const _Entering({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, AppMotion.entranceOffset * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }
}
