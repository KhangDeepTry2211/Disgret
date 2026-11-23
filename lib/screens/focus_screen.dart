// 3.1 Màn Focus (phiên học).
// Full-screen running/break view only; habit and minutes are chosen on Hôm nay (spec 001,
// research R4). State lives in FocusSessionNotifier, so the session keeps running off-screen.
// 5.3 (feature 003, FR-012, FR-012a): the session happens in Gret's sea. Gret focuses while the
// session runs and sleeps during a break; the water follows the live clarity, and Gret bats
// distractions away.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../providers/focus_session_provider.dart';
import '../providers/gret_corner_providers.dart';
import '../providers/sea_providers.dart';
import '../router/app_router.dart';
import '../services/time_format.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/progress_ring.dart';
import '../widgets/sea/distraction_swat.dart';
import '../widgets/sea/sea_scene.dart';

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

/// Phiên đang chạy: biển của Gret với đồng hồ đếm ngược, số liệu tập trung và các nút.
class _RunningView extends ConsumerWidget {
  const _RunningView({required this.session});

  final FocusSessionState session;

  Future<void> _confirmFinishEarly(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(focusSessionProvider.notifier);
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.finishEarlyTitle,
      message: AppStrings.finishEarlyMessage,
      confirmLabel: AppStrings.finishEarlyConfirm,
    );
    if (confirmed) notifier.finishEarly();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(focusSessionProvider.notifier);
    final onBreak = session.breakRemaining != null;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _FocusSea(session: session)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: AppIcons.focus,
                  label: AppStrings.focusedLabel,
                  // Đồng hồ đếm ngược đã làm tròn lên nên số này phải cắt phần lẻ của giây,
                  // để hai số cộng lại luôn đúng bằng thời lượng khi chưa rời app lần nào.
                  value: formatClock(Duration(seconds: session.focused.inSeconds)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: AppIcons.distraction,
                  label: AppStrings.distractionsLabel,
                  value: '${session.distractionCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (onBreak) ...[
            FilledButton(
              onPressed: notifier.resumeFromBreak,
              child: const Text(AppStrings.continueLabel),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          OutlinedButton(
            onPressed: () => _confirmFinishEarly(context, ref),
            child: const Text(AppStrings.finishEarly),
          ),
        ],
      ),
    );
  }
}

/// The sea with Gret, the habit name and the countdown ring in the sky, and Gret batting
/// distractions away.
class _FocusSea extends ConsumerStatefulWidget {
  const _FocusSea({required this.session});

  final FocusSessionState session;

  @override
  ConsumerState<_FocusSea> createState() => _FocusSeaState();
}

class _FocusSeaState extends ConsumerState<_FocusSea> {
  int _swats = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.session;
    final breakRemaining = session.breakRemaining;
    final sea = ref.watch(seaStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final ringSize = (constraints.maxHeight * AppMascot.focusRingShare).clamp(
          AppMascot.focusRingMin,
          AppMascot.focusRingMax,
        );

        return ClipRRect(
          borderRadius: AppRadius.heroBorder,
          child: SeaScene(
            clarity: sea.clarity,
            mood: sea.mood,
            variant: SeaSceneVariant.full,
            look: ref.watch(gretLookProvider),
            gretReaction: _swats,
            foreground: DistractionSwatLayer(
              active: breakRemaining == null,
              distractions: session.distractionCount,
              onSwat: () => setState(() => _swats++),
            ),
            overlay: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.habit?.name ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                ProgressRing(
                  progress: session.progress,
                  size: ringSize,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
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
                              ? AppStrings.focusRemaining
                              : AppStrings.focusBreakRemaining(formatClock(breakRemaining)),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A small card with an icon badge, a number and its label (Tập trung thực, Số lần xao nhãng).
class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppStatCard.padding),
        child: Row(
          children: [
            Container(
              width: AppStatCard.badge,
              height: AppStatCard.badge,
              decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(icon, size: AppStatCard.icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: theme.textTheme.titleLarge),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
