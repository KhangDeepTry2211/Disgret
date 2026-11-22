// 5.1, 4.2, 8.2 Tab Tiến độ.
// Habit report and study statistics in one place (spec 001 US3, FR-012), reusing ReportView and
// StatsView.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'report_screen.dart';
import 'stats_screen.dart';

enum _ProgressView { habits, sessions }

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  _ProgressView _view = _ProgressView.habits;

  @override
  Widget build(BuildContext context) {
    // A finished session and a ticked habit both write a habit log, so no log means no history.
    final hasHistory = ref.watch(habitLogsProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text(AppStrings.tabProgress)),
      body: !hasHistory
          ? const _EmptyProgress()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<_ProgressView>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: _ProgressView.habits,
                          label: Text(AppStrings.progressHabits),
                        ),
                        ButtonSegment(
                          value: _ProgressView.sessions,
                          label: Text(AppStrings.progressSessions),
                        ),
                      ],
                      selected: {_view},
                      onSelectionChanged: (selection) => setState(() => _view = selection.first),
                    ),
                  ),
                ),
                Expanded(
                  child: switch (_view) {
                    _ProgressView.habits => const ReportView(),
                    _ProgressView.sessions => const StatsView(),
                  },
                ),
              ],
            ),
    );
  }
}

class _EmptyProgress extends StatelessWidget {
  const _EmptyProgress();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.stats, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.progressEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
