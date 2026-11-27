// 2.1 Hôm nay (spec 016, the lead's Farmly "HOLD TO START"): a white bar with a round glowing
// button. Holding anywhere on the bar for AppMotion.holdToStart fills a sun-yellow ring, grows the
// glow and walks through three short lines; at full it starts. Letting go early drains the ring;
// a quick tap only asks to hold longer. Screen readers start it with a double-tap.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class HoldToStartButton extends StatefulWidget {
  const HoldToStartButton({
    required this.title,
    required this.action,
    required this.onStart,
    super.key,
  });

  /// The left line, for example "Sẵn sàng chưa?" or "Học thêm một phiên".
  final String title;

  /// The word in the round button under "Giữ để", for example "Bắt đầu" or "Học thêm".
  final String action;
  final VoidCallback onStart;

  @override
  State<HoldToStartButton> createState() => _HoldToStartButtonState();
}

class _HoldToStartButtonState extends State<HoldToStartButton> with SingleTickerProviderStateMixin {
  late final AnimationController _charge =
      AnimationController(
        vsync: this,
        duration: AppMotion.holdToStart,
        // The fill is feedback, not decoration: it keeps its full time with "remove animations".
        animationBehavior: AnimationBehavior.preserve,
      )..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        // Medium, so it never feels like the heavy "time is up" alert of a session.
        HapticFeedback.mediumImpact();
        _charge.value = 0;
        widget.onStart();
      });
  bool _hint = false;
  Timer? _hintTimer;

  void _down(PointerDownEvent event) {
    _hintTimer?.cancel();
    setState(() => _hint = false);
    HapticFeedback.selectionClick();
    _charge.forward();
  }

  void _up(PointerEvent event) {
    if (!_charge.isAnimating) return;
    // Barely charged: it was a tap, so say how to start.
    final tapShare = AppMotion.holdTapLimit.inMilliseconds / AppMotion.holdToStart.inMilliseconds;
    if (_charge.value < tapShare) {
      setState(() => _hint = true);
      _hintTimer = Timer(AppMotion.speechBubble, () {
        if (mounted) setState(() => _hint = false);
      });
    }
    _charge.reverse();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _charge.dispose();
    super.dispose();
  }

  String _line(double progress) {
    if (progress == 0) return _hint ? AppStrings.holdLonger : AppStrings.holdToStartHint;
    final lines = AppStrings.holdLines;
    return lines[math.min(lines.length - 1, (progress * lines.length).floor())];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: '${widget.title}. ${AppStrings.holdSemantics}',
      onTap: widget.onStart,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: AnimatedBuilder(
          animation: _charge,
          builder: (context, _) {
            final progress = _charge.value;
            return Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: AppRadius.pillBorder,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          _line(progress),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox.square(
                    dimension: AppHold.button,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: progress,
                        track: scheme.surfaceContainerHighest,
                        glow: AppColors.sun,
                      ),
                      child: Center(
                        child: Container(
                          width: AppHold.core,
                          height: AppHold.core,
                          decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.holdTop,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onPrimary,
                                ),
                              ),
                              Text(
                                widget.action,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The glow behind the button, the ring's track and the sun-yellow charge.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.track, required this.glow});

  final double progress;
  final Color track;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - AppHold.ring;
    canvas.drawCircle(
      centre,
      radius + AppHold.ring + AppHold.glow * progress - AppHold.glow / 2,
      Paint()..color = glow.withValues(alpha: 0.2 + 0.4 * progress),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppHold.ring
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(centre, radius, stroke..color = track);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        stroke..color = glow,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.track != track || oldDelegate.glow != glow;
}
