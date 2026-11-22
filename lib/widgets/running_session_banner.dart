// 3.1, 5.1 Dải phiên đang chạy.
// Shown above the tab bar: habit name and remaining time (or "Đang nghỉ"); one tap opens the
// session (spec 001 FR-008, SC-003).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../providers/focus_session_provider.dart';
import '../router/app_router.dart';
import '../services/time_format.dart';
import '../theme/app_theme.dart';

class RunningSessionBanner extends ConsumerWidget {
  const RunningSessionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(focusSessionProvider);
    if (!session.isRunning) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final onColor = theme.colorScheme.onPrimary;
    final status = session.breakRemaining != null
        ? AppStrings.sessionOnBreak
        : AppStrings.sessionRemaining(formatClock(session.remaining));

    return Semantics(
      button: true,
      label: '${AppStrings.openSession}: ${session.habit?.name ?? ''}, $status',
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.primary,
        child: InkWell(
          key: const ValueKey('running-session-banner'),
          onTap: () => context.go(AppRoutes.focus),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(AppIcons.focus, size: 20, color: onColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    session.habit?.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(color: onColor),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(status, style: theme.textTheme.labelLarge?.copyWith(color: onColor)),
                const SizedBox(width: AppSpacing.xs),
                Icon(AppIcons.next, size: 20, color: onColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
