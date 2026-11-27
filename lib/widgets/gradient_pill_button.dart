// 5.2 Nút chính (Bắt đầu, Tiếp tục, Lưu…). Bảng màu Ocean không dùng gradient nên nút tô màu đặc
// (màu chính của theme); giữ tên cũ để không phải sửa các màn đang dùng.
// 5.3 (feature 003, button styles 1–3): a raised pill with a darker edge that sinks when pressed,
// an optional gentle breathing pulse for the one action that matters most on a screen, and
// optional bubbles rising when a task is done. A light tick on press. Nothing moves with "remove
// animations"; the press still sinks.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'motion/bubble_burst.dart';

class GradientPillButton extends StatefulWidget {
  const GradientPillButton({
    required this.label,
    required this.onPressed,
    this.height = 72,
    this.icon,
    this.trailingIcon,
    this.breathing = false,
    this.bubbles = false,
    super.key,
  });

  final String label;

  /// Null shows the button disabled.
  final VoidCallback? onPressed;
  final double height;
  final IconData? icon;

  /// After the label, for example an arrow on a forward action (spec 015).
  final IconData? trailingIcon;

  /// Gently grows and shrinks to invite a tap (use on one button per screen at most).
  final bool breathing;

  /// Bubbles rise from the button when it is pressed (for "done" moments).
  final bool bubbles;

  @override
  State<GradientPillButton> createState() => _GradientPillButtonState();
}

class _GradientPillButtonState extends State<GradientPillButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: AppMotion.bob,
  );
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBreath();
  }

  @override
  void didUpdateWidget(GradientPillButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBreath();
  }

  void _syncBreath() {
    final breathe = widget.breathing && _enabled && !MediaQuery.disableAnimationsOf(context);
    if (breathe && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!breathe) {
      _breath
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  void _handleTap() {
    if (!kIsWeb) HapticFeedback.selectionClick();
    if (widget.bubbles) BubbleBurst.showFrom(context);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final face = _enabled
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: AppButton.disabledFace);
    final edge = _enabled
        ? Color.lerp(scheme.primary, scheme.shadow, AppButton.edgeDarkness)!
        : AppColors.transparent;
    final foreground = _enabled
        ? scheme.onPrimary
        : scheme.onSurface.withValues(alpha: AppButton.disabledText);
    final textStyle =
        (widget.height >= AppButton.heroHeight
                ? theme.textTheme.headlineSmall
                : theme.textTheme.titleMedium)
            ?.copyWith(color: foreground);
    const sink = AppButton.edge;

    Widget button = SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // The darker edge under the face: the button "stands" on it.
          Positioned.fill(
            top: sink,
            child: DecoratedBox(
              decoration: BoxDecoration(color: edge, borderRadius: AppRadius.pillBorder),
            ),
          ),
          AnimatedPositioned(
            duration: AppMotion.press,
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            top: _pressed ? sink : 0,
            bottom: _pressed ? 0 : sink,
            child: DecoratedBox(
              decoration: BoxDecoration(color: face, borderRadius: AppRadius.pillBorder),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: foreground),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle,
                        ),
                      ),
                      if (widget.trailingIcon != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(widget.trailingIcon, color: foreground),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.breathing) {
      button = ScaleTransition(
        scale: Tween<double>(
          begin: 1,
          end: AppButton.breathScale,
        ).animate(CurvedAnimation(parent: _breath, curve: Curves.easeInOut)),
        child: button,
      );
    }

    return Semantics(
      container: true,
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: _enabled ? () => _setPressed(false) : null,
        onTap: _enabled ? _handleTap : null,
        child: button,
      ),
    );
  }
}
