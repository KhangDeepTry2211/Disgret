// 5.3 Gret và biển sống (button style 3): a handful of bubbles rise from a widget when a task is
// done (Lưu, đổi ngọc trai, tick a habit). Drawn in the root overlay, so they keep rising even
// when the button disappears or a sheet closes. Nothing shows with "remove animations".
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

class BubbleBurst {
  BubbleBurst._();

  static void showFrom(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    final box = context.findRenderObject();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (box is! RenderBox || !box.hasSize || overlay == null) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final colour = Theme.of(context).colorScheme.tertiary;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BubbleBurstView(rect: rect, colour: colour, onDone: entry.remove),
    );
    overlay.insert(entry);
  }
}

class _BubbleBurstView extends StatefulWidget {
  const _BubbleBurstView({required this.rect, required this.colour, required this.onDone});

  final Rect rect;
  final Color colour;
  final VoidCallback onDone;

  @override
  State<_BubbleBurstView> createState() => _BubbleBurstViewState();
}

class _BubbleBurstViewState extends State<_BubbleBurstView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.bubbleBurst,
  );
  final math.Random _random = math.Random();
  late final List<({double x, double size, double rise, double delay})> _bubbles = [
    for (var i = 0; i < AppButton.bubbleCount; i++)
      (
        x: 0.1 + _random.nextDouble() * 0.8,
        size: AppButton.bubbleMin + _random.nextDouble() * AppButton.bubbleSpread,
        rise: AppButton.bubbleRise * (0.7 + _random.nextDouble() * 0.6),
        delay: i / AppButton.bubbleCount * 0.3,
      ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Stack(
          children: [
            for (final bubble in _bubbles)
              Builder(
                builder: (context) {
                  final t = ((_controller.value - bubble.delay) / (1 - bubble.delay)).clamp(
                    0.0,
                    1.0,
                  );
                  return Positioned(
                    left: widget.rect.left + widget.rect.width * bubble.x - bubble.size / 2,
                    top:
                        widget.rect.top +
                        widget.rect.height * 0.4 -
                        Curves.easeOut.transform(t) * bubble.rise,
                    child: Opacity(
                      opacity: t == 0 ? 0 : 1 - t,
                      child: Container(
                        width: bubble.size,
                        height: bubble.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.colour.withValues(alpha: AppButton.bubbleAlpha),
                          border: Border.all(color: AppColors.white, width: 1.5),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
