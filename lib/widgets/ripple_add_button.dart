// 5.3 Lively buttons (style F): the round "+" that opens "Tạo thói quen". Raised like the pill
// buttons (it sinks onto a darker edge when pressed), with two rings rippling out of it. While
// there is no habit yet the rings keep rippling as an invitation; otherwise they ripple
// [AppButton.ripplePulses] times when the button appears and stop. Nothing moves with "remove
// animations"; the press still sinks.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class RippleAddButton extends StatefulWidget {
  const RippleAddButton({
    required this.tooltip,
    required this.onPressed,
    this.keepRippling = false,
    super.key,
  });

  static const Key ringKey = ValueKey('ripple-ring');
  static const Key faceKey = ValueKey('ripple-face');

  final String tooltip;
  final VoidCallback onPressed;

  /// Ripple until this turns false (no habit yet), instead of a few pulses.
  final bool keepRippling;

  @override
  State<RippleAddButton> createState() => _RippleAddButtonState();
}

class _RippleAddButtonState extends State<RippleAddButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: AppMotion.ripple,
  );
  bool _pulsed = false;
  bool _pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(RippleAddButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The first habit was just added: the invitation is over.
    if (oldWidget.keepRippling && !widget.keepRippling) _ripple.stop();
    _sync();
  }

  void _sync() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _ripple.stop();
      return;
    }
    if (widget.keepRippling) {
      if (!_ripple.isAnimating) _ripple.repeat();
    } else if (!_pulsed) {
      _ripple.repeat(count: AppButton.ripplePulses);
    }
    _pulsed = true;
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  void _handleTap() {
    if (!kIsWeb) HapticFeedback.selectionClick();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final edge = Color.lerp(scheme.primary, scheme.shadow, AppButton.edgeDarkness)!;
    const size = AppButton.fab;
    const sink = AppButton.edge;

    final rings = AnimatedBuilder(
      animation: _ripple,
      builder: (context, _) {
        if (!_ripple.isAnimating) return const SizedBox.shrink();
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final offset in const [0.0, 0.5])
              Builder(
                builder: (context) {
                  final t = (_ripple.value + offset) % 1;
                  return Positioned.fill(
                    child: Transform.scale(
                      scale: 1 + (AppButton.rippleScale - 1) * t,
                      child: DecoratedBox(
                        key: RippleAddButton.ringKey,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.tertiary.withValues(
                              alpha: AppButton.rippleAlpha * (1 - t),
                            ),
                            width: AppButton.rippleStroke,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );

    return Semantics(
      container: true,
      button: true,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: _handleTap,
          child: SizedBox(
            width: size,
            height: size + sink,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(left: 0, top: 0, width: size, height: size, child: rings),
                // The darker edge the face stands on.
                Positioned(
                  left: 0,
                  top: sink,
                  width: size,
                  height: size,
                  child: DecoratedBox(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: edge),
                  ),
                ),
                AnimatedPositioned(
                  duration: AppMotion.press,
                  curve: Curves.easeOut,
                  left: 0,
                  width: size,
                  height: size,
                  top: _pressed ? sink : 0,
                  child: DecoratedBox(
                    key: RippleAddButton.faceKey,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary),
                    child: Icon(AppIcons.add, color: scheme.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
