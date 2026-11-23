// 5.3 Gret và biển sống: Gret's speech bubble (tail pointing at Gret) and thought bubble
// (trailing dots), used on Hôm nay, the onboarding and the quiz.
import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

/// A rounded bubble with a small tail at the bottom centre.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({required this.text, this.style, super.key});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = theme.colorScheme.surfaceContainer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Bubble(text: text, colour: colour, style: style),
        CustomPaint(size: AppMascot.bubbleTail, painter: _TailPainter(colour)),
      ],
    );
  }
}

/// A rounded bubble followed by two shrinking dots, like a thought.
class ThoughtBubble extends StatelessWidget {
  const ThoughtBubble({required this.text, this.style, super.key});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colour = Theme.of(context).colorScheme.surfaceContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Bubble(text: text, colour: colour, style: style),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.lg, top: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(size: AppMascot.thoughtDotLarge, colour: colour),
              const SizedBox(width: AppSpacing.xs),
              _Dot(size: AppMascot.thoughtDotSmall, colour: colour),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.colour, this.style});

  final String text;
  final Color colour;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colour,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Text(text, textAlign: TextAlign.center, style: style ?? theme.textTheme.bodyMedium),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.colour});

  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colour,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = colour);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.colour != colour;
}
