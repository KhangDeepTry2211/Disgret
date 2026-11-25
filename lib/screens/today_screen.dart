// 5.1 Màn Hôm nay. 5.3 Gret và biển sống (feature 003). 5.4 Góc của Gret (feature 004).
// Answers only "what do I study now, and for how long" (spec 001 US1, ADR-0002): goal, next habit,
// planned minutes, a small streak and exactly ONE control into a session. The plan comes from
// sessionPlanProvider (lib/data/session_plan.dart). Feature 003 adds the living sea on top: Gret,
// the clarity ring and the streak card (spec 003 FR-009, FR-010). The sea fills the top of the
// screen behind a transparent header; the wardrobe button sits in the header so it never covers
// what Gret says.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/mascot_mood.dart';
import '../data/models/goal.dart';
import '../data/models/reel.dart';
import '../data/session_plan.dart';
import '../data/study_place.dart';
import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../providers/focus_session_provider.dart';
import '../providers/gret_corner_providers.dart';
import '../providers/sea_cafe_providers.dart';
import '../providers/sea_providers.dart';
import '../router/app_router.dart';
import '../services/focus_session_timer.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/empty_goal_view.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/mascot/mascot_bubbles.dart';
import '../widgets/mascot/mascot_look.dart';
import '../widgets/motion/staggered_entrance.dart';
import '../widgets/sea/clarity_card.dart';
import '../widgets/sea/sea_scene.dart';
import '../widgets/session_plan_sheet.dart';
import '../widgets/streak_card.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plan = ref.watch(sessionPlanProvider);
    final now = ref.watch(clockProvider)();
    final name = ref.watch(profileProvider)?.displayName ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // Transparent over the sea; the usual surface once the cards scroll under it.
        backgroundColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.scrolledUnder)
              ? theme.colorScheme.surface
              : AppColors.transparent,
        ),
        surfaceTintColor: AppColors.transparent,
        // No divider across the sky.
        shape: const Border(),
        // Status bar icons readable on the day sky (dark) and the night sea (light).
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: theme.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
          statusBarBrightness: theme.brightness,
        ),
        title: Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 5.1 "DisGret" first, then the greeting with the student's name (spec 007).
                  const Text(AppStrings.appName, overflow: TextOverflow.ellipsis),
                  Text(
                    AppStrings.greetingFor(now, name),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          const _CornerButton(),
          IconButton(
            icon: const Icon(AppIcons.settings),
            tooltip: AppStrings.settings,
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: switch (plan.state) {
        SessionPlanState.noGoal => const _WithSea(child: EmptyGoalView()),
        SessionPlanState.noHabit => _WithSea(child: _NoHabitView(goal: plan.goal!)),
        _ => _PlanView(plan: plan),
      },
    );
  }
}

/// The sea with Gret in it, filling Hôm nay and standing still behind the content (spec 010).
/// Tapping Gret shows a short line for its mood for a few seconds and never starts a session
/// (spec 003 FR-010). The content scrolls above the sea, so it gets [talk] for its Gret area.
class _SeaBackdrop extends ConsumerStatefulWidget {
  const _SeaBackdrop({required this.topInset, required this.builder});

  /// Height of the status bar and header drawn over the sky.
  final double topInset;

  /// The content over the sea; [talk] makes Gret say a line.
  final Widget Function(VoidCallback talk) builder;

  @override
  ConsumerState<_SeaBackdrop> createState() => _SeaBackdropState();
}

class _SeaBackdropState extends ConsumerState<_SeaBackdrop> {
  final math.Random _random = math.Random();
  Timer? _hide;
  String? _line;

  void _talk() {
    final lines = MascotLook.lines(ref.read(seaStateProvider).mood);
    _hide?.cancel();
    setState(() => _line = lines[_random.nextInt(lines.length)]);
    _hide = Timer(AppMotion.speechBubble, () {
      if (mounted) setState(() => _line = null);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sea = ref.watch(seaStateProvider);
    final line = _line;

    return Stack(
      children: [
        Positioned.fill(
          child: SeaScene(
            clarity: sea.clarity,
            mood: sea.mood,
            variant: SeaSceneVariant.full,
            look: ref.watch(gretLookProvider),
            gretAlignment: AppMascot.todayGretAlignment,
            skyShare: AppMascot.todaySkyShare,
            onMascotTap: _talk,
            // Below the header, so the line is never hidden behind it.
            overlay: line == null
                ? null
                : Padding(
                    padding: EdgeInsets.only(top: widget.topInset),
                    child: SpeechBubble(text: line),
                  ),
          ),
        ),
        Positioned.fill(child: widget.builder(_talk)),
      ],
    );
  }
}

/// The transparent top of the content: Gret shows through it, and tapping it taps Gret.
class _GretArea extends StatelessWidget {
  const _GretArea({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(height: MediaQuery.sizeOf(context).height * AppMascot.todayCardsTop),
    );
  }
}

/// 5.4 The Góc của Gret button in the header, with the pearls the user has (spec 004 FR-005).
class _CornerButton extends ConsumerWidget {
  const _CornerButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pearls = ref.watch(pearlBalanceProvider);

    return Tooltip(
      message: AppStrings.cornerOpen,
      child: Material(
        color: theme.colorScheme.surface,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.gretCorner),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.wardrobe, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Text('$pearls', style: theme.textTheme.labelLarge),
                Icon(AppIcons.pearl, size: AppSpacing.md, color: AppColors.sun),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty states keep their single call to action, on a card over a calm full-screen sea.
class _WithSea extends StatelessWidget {
  const _WithSea({required this.child});

  final Widget child;

  /// A neutral, half-clear sea: nothing has been planned yet.
  static const double _calmClarity = 55;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        const Positioned.fill(
          child: SeaScene(
            clarity: _calmClarity,
            mood: MascotMood.neutral,
            variant: SeaSceneVariant.full,
            gretAlignment: AppMascot.todayGretAlignment,
            skyShare: AppMascot.todaySkyShare,
          ),
        ),
        Column(
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * AppMascot.todayCardsTop),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md + bottomInset,
                ),
                child: DecoratedBox(
                  key: const ValueKey('today-empty-card'),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: AppRadius.cardBorder,
                  ),
                  child: ClipRRect(borderRadius: AppRadius.cardBorder, child: child),
                ),
              ),
            ),
          ],
        ),
      ],
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

    final clarity = ref.watch(seaStateProvider.select((sea) => sea.clarity));
    // The body runs behind the header: its top padding is the status bar plus the header.
    final topInset = MediaQuery.paddingOf(context).top;
    // The floating tab bar sits over the bottom of the screen (spec 010).
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return _SeaBackdrop(
      topInset: topInset,
      builder: (talk) => Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _GretArea(onTap: talk),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: StaggeredEntrance(
                    children: [
                      Row(
                        children: [
                          Expanded(child: ClarityCard(clarity: clarity)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: StreakCard(days: streak)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _GoalCard(goal: plan.goal!),
                      const SizedBox(height: AppSpacing.sm),
                      if (!isReady) ...[
                        _DayStatusCard(state: plan.state),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      _NextSessionCard(plan: plan),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md + bottomInset,
            ),
            child: SizedBox(
              width: double.infinity,
              // Exactly one control leads into a session (FR-004, SC-002). When today is already
              // done or a rest day, the extra session is a secondary action.
              child: isReady
                  ? GradientPillButton(
                      label: AppStrings.start,
                      // The one action that matters most here gently breathes (button style 2).
                      breathing: true,
                      onPressed: () => _openStudy(context, ref),
                    )
                  : OutlinedButton(
                      // On the sea it needs its own background to stay readable.
                      style: OutlinedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainer,
                      ),
                      onPressed: () => _openStudy(context, ref),
                      child: Text(AppStrings.extraSession, style: theme.textTheme.titleSmall),
                    ),
            ),
          ),
        ],
      ),
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
    final place = ref.watch(studyPlaceProvider);
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
            // 5.6 Where the session will take place (spec 006 FR-002).
            if (place == StudyPlace.cafe)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(AppIcons.cafe, size: 18, color: secondaryColor),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      AppStrings.nextPlaceCafe,
                      style: theme.textTheme.bodyMedium?.copyWith(color: secondaryColor),
                    ),
                  ],
                ),
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
