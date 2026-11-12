// 4.2 Ghi nhận – vòng tiến độ phút trên thẻ thói quen: chạm để tick, giữ lâu để chọn
// "Làm bản 2 phút" hoặc "Nghỉ phép". Tick xong thì vòng chạy đầy và nảy nhẹ (C4).
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'progress_ring.dart';

class HabitCheckRing extends StatefulWidget {
  const HabitCheckRing({
    required this.habitName,
    required this.progress,
    required this.done,
    this.minimal = false,
    this.freeze = false,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final String habitName;

  /// Mức hoàn thành hôm nay, từ 0 đến 1.
  final double progress;

  /// Hôm nay đã hoàn thành (kể cả bản 2 phút).
  final bool done;

  /// Hôm nay chỉ làm bản 2 phút.
  final bool minimal;

  /// Hôm nay nghỉ phép.
  final bool freeze;

  /// null thì không chạm được, ví dụ khi đã đủ phút từ phiên Focus.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<HabitCheckRing> createState() => _HabitCheckRingState();
}

class _HabitCheckRingState extends State<HabitCheckRing> with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: AppHabit.tickAnimation,
  );

  /// Phóng to 12% rồi thu về, chạy một lần khi vừa tick xong.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.12), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 1), weight: 1),
  ]).animate(CurvedAnimation(parent: _bounce, curve: Curves.easeOut));

  @override
  void didUpdateWidget(HabitCheckRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.done && !oldWidget.done) _bounce.forward(from: 0);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  String get _stateLabel {
    if (widget.freeze) return 'nghỉ phép';
    if (widget.minimal) return 'đã làm bản 2 phút';
    if (widget.done) return 'đã xong';
    return '${(widget.progress.clamp(0.0, 1.0) * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const innerSize = AppHabit.checkRing - 4 * AppHabit.checkRingStroke;

    final Widget center;
    if (widget.done && !widget.minimal) {
      // Hoàn thành: lõi tô màu nhấn, dấu tick màu chữ trên nền nhấn.
      center = Container(
        width: innerSize,
        height: innerSize,
        decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.tertiary),
        child: Icon(AppIcons.done, color: scheme.onTertiary),
      );
    } else if (widget.freeze || widget.minimal) {
      center = Icon(
        widget.freeze ? AppIcons.freeze : AppIcons.minimal,
        size: 22,
        color: scheme.tertiary,
      );
    } else {
      center = const SizedBox.shrink();
    }

    return Semantics(
      button: true,
      checked: widget.done,
      label: 'Hôm nay đã làm: ${widget.habitName}',
      value: _stateLabel,
      hint: widget.onLongPress == null ? null : 'Giữ lâu để chọn bản 2 phút hoặc nghỉ phép',
      excludeSemantics: true,
      child: InkResponse(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        radius: AppHabit.checkRing / 2 + AppSpacing.xs,
        child: ScaleTransition(
          scale: _scale,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: widget.freeze ? 0 : widget.progress.clamp(0.0, 1.0)),
            duration: AppHabit.tickAnimation,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => ProgressRing(
              progress: value,
              size: AppHabit.checkRing,
              strokeWidth: AppHabit.checkRingStroke,
              child: child!,
            ),
            child: center,
          ),
        ),
      ),
    );
  }
}
