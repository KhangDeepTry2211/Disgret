// 3.1 Màn Focus: bước thiết lập, rồi đồng hồ đếm ngược. Trạng thái nằm ở FocusSessionNotifier
// nên phiên vẫn chạy khi chuyển tab.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/habit.dart';
import '../providers/app_providers.dart';
import '../providers/focus_session_provider.dart';
import '../router/app_router.dart';
import '../services/focus_session_timer.dart';
import '../services/time_format.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/minutes_picker.dart';
import '../widgets/progress_ring.dart';
import '../widgets/reset_break_sheet.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({this.startMinutes, super.key});

  /// Có giá trị khi mở Focus kèm số phút, ví dụ từ nút "Bắt đầu 5 phút" trên reel:
  /// bắt đầu phiên ngay, không qua bước chọn.
  final int? startMinutes;

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartRequest();
  }

  @override
  void didUpdateWidget(FocusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startMinutes != oldWidget.startMinutes) _handleStartRequest();
  }

  void _handleStartRequest() {
    final minutes = widget.startMinutes;
    if (minutes == null) return;

    // Chờ khung hình dựng xong mới đổi trạng thái và đường dẫn.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Xoá số phút khỏi đường dẫn, nếu không lần sau mở tab Focus sẽ tự bắt đầu lại.
      context.go(AppRoutes.focus);
      if (minutes >= 1 && minutes <= _SetupView.maxMinutes) _startQuickly(minutes);
    });
  }

  Future<void> _startQuickly(int minutes) async {
    final hasSession = ref.read(focusSessionProvider).phase != FocusPhase.setup;
    // Đang có phiên hoặc chưa có thói quen thì không có gì để bắt đầu, nên không cần hỏi quyền.
    if (hasSession || ref.read(todayHabitProvider) == null) return;

    final canStart = await confirmStartWithResetBreak(context, ref);
    if (canStart && mounted) {
      // Trong lúc chờ mà đã có phiên thì lệnh này không làm gì, nên không bao giờ tạo phiên chồng.
      ref.read(focusSessionProvider.notifier).startWithTodayHabit(minutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(focusSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Focus')),
      body: switch (session.phase) {
        FocusPhase.setup => const _SetupView(),
        FocusPhase.running => _RunningView(session: session),
        // Phiên vừa kết thúc: app.dart đang chuyển sang màn Tổng kết.
        FocusPhase.finished => const SizedBox.shrink(),
      },
    );
  }
}

/// Bước thiết lập: chọn thói quen và thời lượng.
class _SetupView extends ConsumerStatefulWidget {
  const _SetupView();

  static const List<int> presets = [5, 25, 45];
  static const int defaultMinutes = 25;
  static const int maxMinutes = 480;

  @override
  ConsumerState<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends ConsumerState<_SetupView> {
  final _formKey = GlobalKey<FormState>();
  final _minutes = TextEditingController(text: '${_SetupView.defaultMinutes}');

  /// Thói quen người dùng tự chọn; null nghĩa là dùng thói quen hôm nay.
  String? _selectedHabitId;

  /// Đang chờ kiểm tra quyền; bấm "Bắt đầu" hai lần cũng chỉ hỏi một lần.
  bool _isStarting = false;

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  Habit? _currentHabit(List<Habit> habits, Habit? todayHabit) {
    for (final habit in habits) {
      if (habit.id == _selectedHabitId) return habit;
    }
    return todayHabit;
  }

  Future<void> _start(Habit habit) async {
    if (_isStarting || !_formKey.currentState!.validate()) return;
    final minutes = int.parse(_minutes.text);

    _isStarting = true;
    final canStart = await confirmStartWithResetBreak(context, ref);
    _isStarting = false;

    if (canStart && mounted) {
      ref.read(focusSessionProvider.notifier).start(habit: habit, minutes: minutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habits = ref.watch(habitsProvider);
    final habit = _currentHabit(habits, ref.watch(todayHabitProvider));
    final isDemo = ref.watch(profileProvider)?.demoMode ?? false;

    if (habit == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bạn chưa có thói quen nào để bắt đầu.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.go(AppRoutes.habits),
                child: const Text('Tạo thói quen'),
              ),
            ],
          ),
        ),
      );
    }

    // Dùng SingleChildScrollView: ô nhập luôn được dựng nên Form kiểm tra đủ mọi ô.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              // Đổi thói quen từ bên ngoài (ví dụ vừa tick xong) thì ô chọn cũng đổi theo.
              key: ValueKey(habit.id),
              initialValue: habit.id,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Thói quen'),
              items: [
                for (final item in habits)
                  DropdownMenuItem(
                    value: item.id,
                    child: Text(item.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (id) => setState(() => _selectedHabitId = id),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Thời lượng', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            MinutesPicker(
              controller: _minutes,
              presets: _SetupView.presets,
              maxMinutes: _SetupView.maxMinutes,
            ),
            const SizedBox(height: AppSpacing.xl),
            GradientPillButton(label: 'Bắt đầu', onPressed: () => _start(habit)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Chỉ cần cam kết 5 phút đầu',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            if (isDemo) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Chế độ demo: 1 phút chỉ dài ${FocusSessionTimer.demoSecondsPerMinute} giây',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Phiên đang chạy: đồng hồ đếm ngược trong vòng tiến độ và số liệu tập trung.
class _RunningView extends ConsumerWidget {
  const _RunningView({required this.session});

  final FocusSessionState session;

  Future<void> _confirmFinishEarly(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(focusSessionProvider.notifier);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Kết thúc sớm?',
      message: 'Phiên học vẫn được lưu với thời gian bạn đã tập trung.',
      confirmLabel: 'Kết thúc',
    );
    if (confirmed) notifier.finishEarly();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(focusSessionProvider.notifier);
    final breakRemaining = session.breakRemaining;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            session.habit?.name ?? '',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: ProgressRing(
              progress: session.progress,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Thời lượng dài vẫn phải nằm gọn trong vòng tròn.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatClock(session.remaining),
                        style: theme.textTheme.displayMedium,
                      ),
                    ),
                    Text(
                      breakRemaining == null
                          ? 'Thời gian còn lại'
                          : 'Đang nghỉ – còn ${formatClock(breakRemaining)}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatRow(
            icon: AppIcons.focus,
            label: 'Tập trung thực',
            // Đồng hồ đếm ngược đã làm tròn lên nên số này phải cắt phần lẻ của giây,
            // để hai số cộng lại luôn đúng bằng thời lượng khi chưa rời app lần nào.
            value: formatClock(Duration(seconds: session.focused.inSeconds)),
          ),
          const SizedBox(height: AppSpacing.sm),
          _StatRow(
            icon: AppIcons.distraction,
            label: 'Số lần xao nhãng',
            value: '${session.distractionCount}',
          ),
          const SizedBox(height: AppSpacing.xl),
          if (breakRemaining != null) ...[
            FilledButton(onPressed: notifier.resumeFromBreak, child: const Text('Tiếp tục')),
            const SizedBox(height: AppSpacing.sm),
          ],
          OutlinedButton(
            onPressed: () => _confirmFinishEarly(context, ref),
            child: const Text('Kết thúc sớm'),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    );
  }
}
