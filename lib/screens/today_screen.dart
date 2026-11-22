// 5.1 Màn Hôm nay.
// Answers only "what do I study now, and for how long" (spec 001 US1, ADR-0002): goal, next habit,
// planned minutes, a small streak and exactly ONE control into a session. The plan comes from
// sessionPlanProvider (lib/data/session_plan.dart).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/goal.dart';
import '../data/models/reel.dart';
import '../data/session_plan.dart';
import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../providers/focus_session_provider.dart';
import '../router/app_router.dart';
import '../services/focus_session_timer.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/empty_goal_view.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/session_plan_sheet.dart';
import '../widgets/streak_ring.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(sessionPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppLogo(size: 32),
            SizedBox(width: AppSpacing.sm),
            Text(AppStrings.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.settings),
            tooltip: AppStrings.settings,
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: switch (plan.state) {
        SessionPlanState.noGoal => const EmptyGoalView(),
        SessionPlanState.noHabit => _NoHabitView(goal: plan.goal!),
        _ => _PlanView(plan: plan),
      },
    );
  }
}

/// "Bắt đầu" (or the secondary extra-session action): opens the motivation step before a session,
/// or the running session if there is one (no second session, FR-008).
void _openStudy(BuildContext context, WidgetRef ref) {
  if (ref.read(focusSessionProvider).isRunning) {
    context.go(AppRoutes.focus);
  } else {
    context.push(AppRoutes.motivationFor(ReelContext.start));
  }
}

class _PlanView extends ConsumerWidget {
  const _PlanView({required this.plan});

  final SessionPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final streak = ref.watch(overallStreakProvider);
    final isReady = plan.state == SessionPlanState.ready;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Center(child: StreakRing(days: streak, size: 96, ringWidth: 6)),
              const SizedBox(height: AppSpacing.lg),
              _GoalCard(goal: plan.goal!),
              const SizedBox(height: AppSpacing.md),
              if (!isReady) ...[
                _DayStatusCard(state: plan.state),
                const SizedBox(height: AppSpacing.md),
              ],
              _NextSessionCard(plan: plan),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            width: double.infinity,
            // Exactly one control leads into a session (FR-004, SC-002). When today is already
            // done or a rest day, the extra session is a secondary action.
            child: isReady
                ? GradientPillButton(
                    label: AppStrings.start,
                    onPressed: () => _openStudy(context, ref),
                  )
                : OutlinedButton(
                    onPressed: () => _openStudy(context, ref),
                    child: Text(AppStrings.extraSession, style: theme.textTheme.titleSmall),
                  ),
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.goal, size: 20, color: secondaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  AppStrings.todayGoalLabel,
                  style: theme.textTheme.labelLarge?.copyWith(color: secondaryColor),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(goal.title, style: theme.textTheme.titleMedium),
            if (goal.identity.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.identity(goal.identity),
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.tertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The habit and duration of the next session, with the change-plan action (FR-003).
class _NextSessionCard extends ConsumerWidget {
  const _NextSessionCard({required this.plan});

  final SessionPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDemo = ref.watch(profileProvider)?.demoMode ?? false;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.focus, size: 20, color: secondaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  AppStrings.nextHabitLabel,
                  style: theme.textTheme.labelLarge?.copyWith(color: secondaryColor),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: Text(plan.habit?.name ?? '', style: theme.textTheme.titleLarge)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  AppStrings.minutes(plan.plannedMinutes),
                  style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ),
            if (isDemo)
              Text(
                AppStrings.demoHint(FocusSessionTimer.demoSecondsPerMinute),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => showSessionPlanSheet(context),
                child: const Text(AppStrings.changePlan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today is complete, or a rest day by schedule.
class _DayStatusCard extends StatelessWidget {
  const _DayStatusCard({required this.state});

  final SessionPlanState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = state == SessionPlanState.allDoneToday;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(isDone ? AppIcons.check : AppIcons.breakTime, color: theme.colorScheme.tertiary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDone ? AppStrings.allDoneTitle : AppStrings.restDayTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isDone ? AppStrings.allDoneMessage : AppStrings.restDayMessage,
                    style: theme.textTheme.bodySmall,
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

class _NoHabitView extends StatelessWidget {
  const _NoHabitView({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.habits, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.noHabitTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.noHabitMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              icon: const Icon(AppIcons.add),
              label: const Text(AppStrings.addHabit),
              onPressed: () => context.push(AppRoutes.habitForm(goal.id)),
            ),
          ],
        ),
      ),
    );
  }
}
