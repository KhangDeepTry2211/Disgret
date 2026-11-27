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
import '../data/sea_time.dart';
import '../data/date_utils.dart';
import '../data/session_plan.dart';
import '../data/today_tasks.dart';
import '../data/study_place.dart';
import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../providers/focus_session_provider.dart';
import '../providers/gret_corner_providers.dart';
import '../providers/gret_emote_provider.dart';
import '../providers/launch_providers.dart';
import '../providers/reminder_providers.dart';
import '../providers/sea_cafe_providers.dart';
import '../providers/sea_providers.dart';
import '../router/app_router.dart';
import '../services/focus_session_timer.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/empty_goal_view.dart';
import '../widgets/hold_to_start_button.dart';
import '../widgets/icon_tile.dart';
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
    final plan = ref.watch(sessionPlanProvider);
    final now = ref.watch(clockProvider)();
    final name = ref.watch(profileProvider)?.displayName ?? '';
    // The header sits on the sky, which follows the clock rather than dark mode (spec 013).
    final sky = AppTheme.forSky(night: SeaTime.isNight(now));

    final header = AppBar(
      // Transparent over the sea; the sky's surface once the cards scroll under it.
      backgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.scrolledUnder)
            ? sky.colorScheme.surface
            : AppColors.transparent,
      ),
      surfaceTintColor: AppColors.transparent,
      // No divider across the sky.
      shape: const Border(),
      // Status bar icons readable on the day sky (dark) and the night sky (light).
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: sky.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: sky.brightness,
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
                  style: sky.textTheme.bodySmall,
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
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: header.preferredSize,
        child: Theme(data: sky, child: header),
      ),
      body: switch (plan.state) {
        SessionPlanState.noGoal => const _WithSea(child: EmptyGoalView()),
        SessionPlanState.noHabit => _WithSea(child: _NoHabitView(goal: plan.goal!)),
        _ => _PlanView(plan: plan),
      },
    );
  }
}

/// The sea with Gret in it, filling Hôm nay behind the content (spec 010). Since 2026-11-27 the
/// sea and Gret stay put while the cards scroll over them (lead's request), and the sea's
/// animations pause while a scroll is under way, so scrolling only moves the cards.
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

  /// Taps so far: every third one is a wink instead of love (spec 018).
  int _taps = 0;

  @override
  void initState() {
    super.initState();
    // Gret winks at the morning greeting when DisGret opens with its launch screen, once per app
    // run (spec 018).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !ref.read(launchScreenProvider)) return;
      ref.read(gretEmoteProvider.notifier).greet(ref.read(clockProvider)());
    });
  }

  /// True from the start to the end of a scroll of the cards: the sea's tickers are muted then.
  final ValueNotifier<bool> _scrolling = ValueNotifier(false);

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollStartNotification) _scrolling.value = true;
    if (notification is ScrollEndNotification) _scrolling.value = false;
    return false;
  }

  void _talk() {
    final lines = MascotLook.lines(ref.read(seaStateProvider).mood);
    _taps++;
    ref.read(gretEmoteProvider.notifier).show(_taps % 3 == 0 ? MascotMood.wink : MascotMood.love);
    _hide?.cancel();
    setState(() => _line = lines[_random.nextInt(lines.length)]);
    _hide = Timer(AppMotion.speechBubble, () {
      if (mounted) setState(() => _line = null);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    _scrolling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sea = ref.watch(seaStateProvider);
    final look = ref.watch(gretLookProvider);
    final line = _line;

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder<bool>(
              valueListenable: _scrolling,
              builder: (context, scrolling, scene) =>
                  TickerMode(enabled: !scrolling, child: scene!),
              child: SeaScene(
                clarity: sea.clarity,
                mood: sea.mood,
                variant: SeaSceneVariant.full,
                look: look,
                gretAlignment: AppMascot.todayGretAlignment,
                skyShare: AppMascot.todaySkyShare,
                onMascotTap: _talk,
                showHome: true,
                // Below the header, so the line is never hidden behind it.
                overlay: line == null
                    ? null
                    : Padding(
                        padding: EdgeInsets.only(top: widget.topInset),
                        child: SpeechBubble(text: line),
                      ),
              ),
            ),
          ),
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: widget.builder(_talk),
            ),
          ),
        ],
      ),
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
                          Expanded(
                            child: ClarityCard(
                              clarity: clarity,
                              onTap: () => context.go(AppRoutes.progress),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: StreakCard(
                              days: streak,
                              onTap: () => context.go(AppRoutes.progress),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const _Shortcuts(),
                      const SizedBox(height: AppSpacing.sm),
                      _GoalCard(goal: plan.goal!),
                      const SizedBox(height: AppSpacing.sm),
                      if (!isReady) ...[
                        _DayStatusCard(state: plan.state),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      _NextSessionCard(plan: plan),
                      const _TodayTasksCard(),
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
              // Hold to start, like starting an engine (spec 016): one control, two titles.
              child: HoldToStartButton(
                title: isReady ? AppStrings.holdReady : AppStrings.extraSession,
                action: isReady ? AppStrings.start : AppStrings.holdMore,
                onStart: () => _openStudy(context, ref),
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

/// "Lối tắt" (spec 015): four pastel tiles to the rest of DisGret. None of them starts a session
/// (ADR-0002: "Bắt đầu" stays the one way in).
class _Shortcuts extends ConsumerWidget {
  const _Shortcuts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pearls = ref.watch(pearlBalanceProvider);
    final today = ref.watch(todayProvider);
    final remindersLeft = ref
        .watch(reminderPlanProvider)
        .where((reminder) => dateOnly(reminder.at) == today)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.shortcuts, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _Shortcut(
                  key: const ValueKey('shortcut-map'),
                  icon: AppIcons.map,
                  colour: AppHabitColors.of(0),
                  label: AppStrings.shortcutMap,
                  onTap: () => context.push(AppRoutes.seaMap),
                ),
                _Shortcut(
                  key: const ValueKey('shortcut-corner'),
                  icon: AppIcons.wardrobe,
                  colour: AppHabitColors.of(6),
                  label: AppStrings.shortcutCorner,
                  tag: pearls > 0 ? '$pearls' : null,
                  onTap: () => context.push(AppRoutes.gretCorner),
                ),
                _Shortcut(
                  key: const ValueKey('shortcut-reminders'),
                  icon: AppIcons.bell,
                  colour: AppHabitColors.of(9),
                  label: AppStrings.shortcutReminders,
                  badge: remindersLeft,
                  onTap: () => context.go(AppRoutes.habits),
                ),
                _Shortcut(
                  key: const ValueKey('shortcut-progress'),
                  icon: AppIcons.stats,
                  colour: AppHabitColors.of(4),
                  label: AppStrings.shortcutProgress,
                  onTap: () => context.go(AppRoutes.progress),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.colour,
    required this.label,
    required this.onTap,
    this.badge = 0,
    this.tag,
    super.key,
  });

  final IconData icon;
  final HabitColor colour;
  final String label;
  final VoidCallback onTap;
  final int badge;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: AppRadius.cardBorder,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                IconTile(icon: icon, colour: colour, badge: badge, tag: tag),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Việc hôm nay" (spec 015): the habits scheduled today, with a round tick, the minutes and the
/// reminder time. Tapping a row opens the habit; hidden when nothing is scheduled.
class _TodayTasksCard extends ConsumerWidget {
  const _TodayTasksCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurfaceVariant;
    final tasks = TodayTasks.of(
      habits: ref.watch(habitsProvider),
      logs: ref.watch(habitLogsProvider),
      today: ref.watch(todayProvider),
    );
    if (tasks.isEmpty) return const SizedBox.shrink();
    final done = tasks.where((task) => task.done).length;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.todayTasks, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.todayTasksDone(done, tasks.length),
                style: theme.textTheme.bodySmall?.copyWith(color: secondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: AppRadius.pillBorder,
                child: LinearProgressIndicator(
                  value: done / tasks.length,
                  minHeight: 4,
                  color: theme.colorScheme.primary,
                  backgroundColor: AppColors.heatOf(context).first,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final task in tasks)
                InkWell(
                  borderRadius: AppRadius.cardBorder,
                  onTap: () => context.push(AppRoutes.habitDetail(task.habit.id)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
                    child: Row(
                      children: [
                        _Tick(done: task.done),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            AppStrings.todayTaskLine(task.habit.name, task.habit.minMinutesPerDay),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: task.done ? secondary : null,
                              decoration: task.done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (task.time != null)
                          Text(
                            task.time!,
                            style: theme.textTheme.bodySmall?.copyWith(color: secondary),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: AppIconTile.badge + 2,
      height: AppIconTile.badge + 2,
      decoration: BoxDecoration(
        color: done ? scheme.primary : null,
        shape: BoxShape.circle,
        border: done ? null : Border.all(color: scheme.outline, width: 1.5),
      ),
      child: done
          ? Icon(AppIcons.done, size: AppIconTile.badge - 4, color: scheme.onPrimary)
          : null,
    );
  }
}
