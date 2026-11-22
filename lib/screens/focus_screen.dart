// 3.1 Màn Focus (phiên học).
// Full-screen running/break view only; habit and minutes are chosen on Hôm nay (spec 001,
// research R4). State lives in FocusSessionNotifier, so the session keeps running off-screen.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../providers/focus_session_provider.dart';
import '../router/app_router.dart';
import '../services/time_format.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/progress_ring.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  /// Back to the tabs; the session keeps running and the banner leads back here.
  static void _leave(BuildContext context) => context.go(AppRoutes.today);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(focusSessionProvider);

    return PopScope(
      // Opened with go(), so nothing is below it: system Back goes to Hôm nay instead of closing
      // the app.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const BackButtonIcon(),
            tooltip: AppStrings.back,
            onPressed: () => _leave(context),
          ),
          title: const Text(AppStrings.focusTitle),
        ),
        body: switch (session.phase) {
          FocusPhase.running => _RunningView(session: session),
          // No session: the router redirects to Hôm nay. Just finished: app.dart opens the
          // summary.
          FocusPhase.setup || FocusPhase.finished => const SizedBox.shrink(),
        },
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
