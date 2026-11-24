// 5.3 Gret và biển sống (button style 5): a pastel "sticker" chip with an icon that wiggles once
// when it becomes selected. Built on ChoiceChip, so selection, focus and screen-reader semantics
// stay standard. Colours come from AppHabitColors; nothing moves with "remove animations".
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class StickerChip extends StatefulWidget {
  const StickerChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.colour = 0,
    this.large = false,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  /// Index into [AppHabitColors.palette].
  final int colour;

  /// Bigger padding and text (onboarding answers).
  final bool large;

  @override
  State<StickerChip> createState() => _StickerChipState();
}

class _StickerChipState extends State<StickerChip> with SingleTickerProviderStateMixin {
  late final AnimationController _wiggle = AnimationController(
    vsync: this,
    duration: AppMotion.wiggle,
  );

  @override
  void didUpdateWidget(StickerChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.selected && widget.selected && !MediaQuery.disableAnimationsOf(context)) {
      _wiggle.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colours = AppHabitColors.of(widget.colour);
    final style = (widget.large ? theme.textTheme.titleSmall : theme.textTheme.labelLarge)
        ?.copyWith(color: colours.foreground);

    return AnimatedBuilder(
      animation: _wiggle,
      builder: (context, child) => Transform.rotate(
        angle: math.sin(_wiggle.value * 4 * math.pi) * (1 - _wiggle.value) * AppButton.chipWiggle,
        child: child,
      ),
      child: ChoiceChip(
        label: Text(widget.label),
        labelStyle: style,
        avatar: widget.icon == null
            ? null
            : Icon(widget.icon, size: AppStatCard.icon - 4, color: colours.foreground),
        selected: widget.selected,
        showCheckmark: false,
        backgroundColor: colours.background,
        selectedColor: colours.background,
        shape: const StadiumBorder(),
        side: BorderSide(
          color: widget.selected ? colours.foreground : AppColors.transparent,
          width: AppButton.chipBorder,
        ),
        padding: widget.large
            ? const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm)
            : null,
        // Small chips sit in one row (Tất cả, Sáng, Chiều, Tối): a tighter label keeps it on screen.
        labelPadding: widget.large
            ? null
            : const EdgeInsets.only(left: AppSpacing.xs, right: AppSpacing.xs),
        onSelected: widget.onSelected,
      ),
    );
  }
}
