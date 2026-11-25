// 5.1 Màn onboarding: chỉ hiện ở lần mở app đầu tiên. Tất cả chỉ được lưu vào Hive khi hoàn
// thành trang cuối.
// 5.3 (feature 003, FR-011, FR-011a): a story told by Gret. Four story pages explain the app, then
// one page per question: reel length, the motivation quiz (1.1), the apps that pull the user away
// (2.1, Android only), the first goal and habit (4.1). A first goal ends on "your sea is ready".
// Design: docs/superpowers/specs/2026-11-23-story-onboarding-design.md.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/mascot_mood.dart';
import '../data/models/motivation_type.dart';
import '../data/models/user_profile.dart';
import '../data/motivation_quiz.dart';
import '../data/repositories/blocked_apps_repository.dart';
import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../providers/sea_providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/goal_form_fields.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/habit_form_fields.dart';
import '../widgets/mascot/mascot_bubbles.dart';
import '../widgets/mascot/mascot_view.dart';
import '../widgets/motion/staggered_entrance.dart';
import '../widgets/quiz_question_view.dart';
import '../widgets/sticker_chip.dart';
import '../widgets/sea/sea_scene.dart';

/// What one onboarding page shows.
enum _PageKind { story, name, reelLength, quiz, apps, goal }

class _Page {
  const _Page(this.kind, [this.index = 0]);

  final _PageKind kind;

  /// Story page or quiz question number.
  final int index;
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  static const List<int> _reelLengths = [15, 30, 60];

  final _formKey = GlobalKey<FormState>();
  final _goalTitle = TextEditingController();
  final _goalReason = TextEditingController();
  final _habitName = TextEditingController();
  final _habitMinutes = TextEditingController(text: '${HabitFormFields.defaultMinutes}');

  /// 5.1 Tên gọi (spec 007); replaying the introduction starts from the current name.
  final _name = TextEditingController();
  final List<MotivationType?> _answers = List.filled(motivationQuestions.length, null);

  /// Turns a story page by itself; it fills the current progress segment.
  late final AnimationController _storyClock = AnimationController(
    vsync: this,
    duration: AppMotion.storyPage,
  )..addStatusListener(_onStoryClock);

  late int _reelLength;

  /// The reminder list being edited on the app page; saved only at the end.
  late final Set<String> _blockedApps;

  /// Xem lại onboarding từ Cài đặt khi đã có mục tiêu thì không hỏi lại mục tiêu.
  late final bool _needsFirstGoal;
  late final List<_Page> _pages;

  int _step = 0;
  bool _held = false;
  bool _animationsOff = false;
  bool _saving = false;

  /// Everything is saved; the "your sea is ready" moment is showing.
  bool _seaReady = false;

  _Page get _page => _pages[_step];
  bool get _isStory => _page.kind == _PageKind.story;
  bool get _isLastPage => _step == _pages.length - 1;
  int get _firstQuestion => _pages.indexWhere((page) => page.kind != _PageKind.story);

  @override
  void initState() {
    super.initState();
    _reelLength = ref.read(profileProvider)?.preferredReelLength ?? UserProfile.defaultReelLength;
    _name.text = ref.read(profileProvider)?.displayName ?? '';
    _needsFirstGoal = ref.read(goalsProvider).isEmpty;
    _blockedApps = {...ref.read(blockedAppsProvider)};
    _pages = [
      for (var i = 0; i < _StoryPage.count; i++) _Page(_PageKind.story, i),
      // Gret has just said hello: it asks the student's name first (spec 007).
      const _Page(_PageKind.name),
      const _Page(_PageKind.reelLength),
      for (var i = 0; i < motivationQuestions.length; i++) _Page(_PageKind.quiz, i),
      // Reminders when a distracting app opens only exist on Android (spec 003 FR-011a).
      if (ref.read(nativeBridgeProvider).isSupported) const _Page(_PageKind.apps),
      if (_needsFirstGoal) const _Page(_PageKind.goal),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationsOff = MediaQuery.disableAnimationsOf(context);
    _syncStoryClock();
  }

  @override
  void dispose() {
    _storyClock.dispose();
    _goalTitle.dispose();
    _goalReason.dispose();
    _habitName.dispose();
    _habitMinutes.dispose();
    _name.dispose();
    super.dispose();
  }

  /// Story pages turn by themselves, except with "remove animations" on or while held.
  void _syncStoryClock() {
    final runs = _isStory && !_held && !_saving && !_animationsOff;
    if (!runs) {
      _storyClock.stop();
    } else if (!_storyClock.isAnimating) {
      _storyClock.forward();
    }
  }

  void _onStoryClock(AnimationStatus status) {
    if (status == AnimationStatus.completed) _goNext();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _storyClock.value = 0;
    _syncStoryClock();
  }

  void _goNext() {
    if (_saving) return;
    if (_isLastPage) {
      _finish();
    } else {
      _goTo(_step + 1);
    }
  }

  void _goBack() {
    if (_saving || _step == 0) return;
    _goTo(_step - 1);
  }

  void _hold(bool held) {
    _held = held;
    _syncStoryClock();
  }

  void _selectAnswer(MotivationType type) {
    if (_saving) return;
    _answers[_page.index] = type;
    _goNext();
  }

  void _toggleApp(Set<String> packages, bool selected) {
    setState(() => selected ? _blockedApps.addAll(packages) : _blockedApps.removeAll(packages));
  }

  Future<void> _finish() async {
    if (_saving) return;
    if (_page.kind == _PageKind.goal && !_formKey.currentState!.validate()) return;
    setState(() => _saving = true); // Khoá nút để bấm hai lần không tạo trùng mục tiêu.
    _syncStoryClock();

    if (_needsFirstGoal) {
      final goal = await ref
          .read(goalsProvider.notifier)
          .add(title: _goalTitle.text.trim(), reason: _goalReason.text.trim());
      await ref
          .read(habitsProvider.notifier)
          .add(
            goalId: goal.id,
            name: _habitName.text.trim(),
            minMinutesPerDay: int.parse(_habitMinutes.text),
          );
    }
    if (_pages.any((page) => page.kind == _PageKind.apps)) {
      await ref.read(blockedAppsProvider.notifier).replaceAll(_blockedApps);
    }
    // Đánh dấu xong sau cùng: lỡ tắt app giữa chừng thì lần sau vẫn vào lại onboarding.
    await ref
        .read(profileProvider.notifier)
        .completeOnboarding(
          UserProfile(
            motivationTypes: topMotivationTypes(_answers.nonNulls.toList()),
            preferredReelLength: _reelLength,
            // Xem lại onboarding không được tắt chế độ demo đang bật.
            demoMode: ref.read(profileProvider)?.demoMode ?? false,
            displayName: UserProfile.cleanName(_name.text),
          ),
        );
    if (!mounted) return;
    if (_needsFirstGoal && !_animationsOff) {
      setState(() => _seaReady = true);
      await Future<void>.delayed(AppMotion.seaReady);
      if (!mounted) return;
    }
    context.go(AppRoutes.today);
  }

  @override
  Widget build(BuildContext context) {
    // Từ trang thứ hai trở đi, nút Back của hệ thống về trang trước thay vì thoát app.
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: _seaReady
              ? const _SeaReadyView()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        0,
                      ),
                      child: _StoryProgress(
                        key: const ValueKey('story-progress'),
                        count: _pages.length,
                        current: _step,
                        clock: _storyClock,
                        fillCurrent: !_isStory || _animationsOff,
                      ),
                    ),
                    SizedBox(
                      height: AppSpacing.xxl,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _isStory
                              ? TextButton(
                                  onPressed: () => _goTo(_firstQuestion),
                                  child: const Text(AppStrings.storySkip),
                                )
                              : null,
                        ),
                      ),
                    ),
                    Expanded(child: _isStory ? _buildStory() : _buildQuestion(context)),
                    Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: _buildButtons()),
                  ],
                ),
        ),
      ),
    );
  }

  /// Tap the right two thirds for the next page, the left third for the previous one; hold to
  /// pause.
  Widget _buildStory() {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) =>
            details.localPosition.dx < constraints.maxWidth / 3 ? _goBack() : _goNext(),
        onLongPressStart: (_) => _hold(true),
        onLongPressEnd: (_) => _hold(false),
        onLongPressCancel: () => _hold(false),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _StoryPage(index: _page.index),
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    // Dùng SingleChildScrollView: ô nhập luôn được dựng nên Form kiểm tra đủ mọi ô.
    // Mỗi trang một khoá riêng để trang mới luôn hiện từ trên cùng.
    return SingleChildScrollView(
      key: ValueKey(_step),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: switch (_page.kind) {
        _PageKind.name => _buildName(),
        _PageKind.reelLength => _buildReelLength(),
        _PageKind.quiz => QuizQuestionView(
          questionIndex: _page.index,
          selected: _answers[_page.index],
          onSelected: _selectAnswer,
        ),
        _PageKind.apps => _buildApps(context),
        _PageKind.goal => _buildFirstGoal(context),
        _PageKind.story => const SizedBox.shrink(),
      },
    );
  }

  /// 5.1 Gret asks what to call the student; leaving it empty is fine (spec 007).
  Widget _buildName() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GretAsks(text: AppStrings.nameQuestion),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          maxLength: UserProfile.maxNameLength,
          decoration: const InputDecoration(
            labelText: AppStrings.nameLabel,
            hintText: AppStrings.nameHint,
          ),
        ),
        Text(
          AppStrings.namePrivacy,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildReelLength() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GretAsks(text: AppStrings.reelLengthQuestion),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var i = 0; i < _reelLengths.length; i++)
              StickerChip(
                label: AppStrings.reelSeconds(_reelLengths[i]),
                icon: AppIcons.reels,
                colour: const [3, 0, 9][i],
                large: true,
                selected: _reelLengths[i] == _reelLength,
                onSelected: (_) => setState(() => _reelLength = _reelLengths[i]),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildApps(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GretAsks(text: AppStrings.appsQuestion),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppStrings.appsHint,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (i, MapEntry(key: name, value: packages))
                in BlockedAppsRepository.onboardingApps.entries.indexed)
              StickerChip(
                label: name,
                colour: const [8, 7, 9, 0, 5][i % 5],
                large: true,
                selected: _blockedApps.containsAll(packages),
                onSelected: (selected) => _toggleApp(packages, selected),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFirstGoal(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SpeechBubble(text: AppStrings.gretGoalPrompt),
          const Center(
            child: MascotView(mood: MascotMood.happy, size: AppMascot.small),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(AppStrings.firstGoalTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.firstGoalMessage,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          GoalFormFields(titleController: _goalTitle, reasonController: _goalReason),
          const SizedBox(height: AppSpacing.md),
          HabitFormFields(nameController: _habitName, minutesController: _habitMinutes),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    if (_isStory) {
      return GradientPillButton(label: AppStrings.continueLabel, onPressed: _goNext);
    }

    // Ở trang quiz, chọn thẻ là tự sang câu tiếp nên không cần nút đi tiếp.
    final nextLabel = switch (_page.kind) {
      _PageKind.quiz || _PageKind.story => null,
      _PageKind.goal => AppStrings.enterApp,
      _ => _isLastPage ? AppStrings.enterApp : AppStrings.continueLabel,
    };
    return Row(
      children: [
        OutlinedButton(onPressed: _saving ? null : _goBack, child: const Text(AppStrings.back)),
        if (nextLabel != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GradientPillButton(
              label: nextLabel,
              height: AppButton.compact,
              onPressed: _saving ? null : _goNext,
            ),
          ),
        ],
      ],
    );
  }
}

/// One segment per page; past pages full, the current story page filling with [clock].
class _StoryProgress extends StatelessWidget {
  const _StoryProgress({
    required this.count,
    required this.current,
    required this.clock,
    required this.fillCurrent,
    super.key,
  });

  final int count;
  final int current;
  final Animation<double> clock;

  /// Question pages (and story pages without animations) show their segment full.
  final bool fillCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: AppStrings.storyProgress(current + 1, count),
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: clock,
          builder: (context, _) => Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: AppStory.segmentGap),
                Expanded(
                  child: ClipRRect(
                    borderRadius: AppRadius.pillBorder,
                    child: Container(
                      height: AppStory.segmentHeight,
                      color: scheme.outlineVariant,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: i < current
                            ? 1
                            : i > current
                            ? 0
                            : (fillCurrent ? 1 : clock.value),
                        heightFactor: 1,
                        child: ColoredBox(color: scheme.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the four story pages. The pages share one sea so its water changes in place: clear,
/// murky, clear again (spec 003 FR-011).
class _StoryPage extends StatelessWidget {
  const _StoryPage({required this.index});

  final int index;

  static const List<String> _lines = [
    AppStrings.storyHello,
    AppStrings.storyScroll,
    AppStrings.storyStudy,
    AppStrings.storyCallBack,
  ];
  static const List<MascotMood> _moods = [
    MascotMood.happy,
    MascotMood.sad,
    MascotMood.happy,
    MascotMood.focused,
  ];

  /// Illustration values (not the user's clarity): litter below 40, fish from 70.
  static const List<double> _clarity = [85, 20, 90, 90];

  static int get count => _lines.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = theme.textTheme.headlineMedium;
    final animationsOff = MediaQuery.disableAnimationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (index == 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: AppSpacing.xl),
              const SizedBox(width: AppSpacing.sm),
              Text(AppStrings.appName, style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(AppStrings.headlineTop, textAlign: TextAlign.center, style: headline),
          Text(
            AppStrings.headlineBottom,
            textAlign: TextAlign.center,
            style: headline?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Expanded(
          key: const ValueKey('story-sea'),
          child: ClipRRect(
            borderRadius: AppRadius.heroBorder,
            child: SeaScene(
              clarity: _clarity[index],
              mood: _moods[index],
              variant: SeaSceneVariant.full,
              // Gret's line sits in the sky above the water.
              overlay: AnimatedSwitcher(
                duration: animationsOff ? Duration.zero : AppMotion.entrance,
                child: SpeechBubble(
                  key: ValueKey(index),
                  text: _lines[index],
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Gret asking a question in a thought bubble, as on the quiz pages.
class _GretAsks extends StatelessWidget {
  const _GretAsks({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const MascotView(mood: MascotMood.neutral, size: AppMascot.small),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ThoughtBubble(text: text, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

/// "Biển của bạn đã sẵn sàng": the user's sea with a happy Gret, shown for about 1.2 s after
/// the first goal is saved (spec 003 FR-011).
class _SeaReadyView extends ConsumerWidget {
  const _SeaReadyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clarity = ref.watch(seaStateProvider).clarity;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StaggeredEntrance(
          children: [
            SeaScene(clarity: clarity, mood: MascotMood.happy, variant: SeaSceneVariant.compact),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.seaReady,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
