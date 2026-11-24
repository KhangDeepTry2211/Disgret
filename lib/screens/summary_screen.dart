// 3.4 Màn Tổng kết phiên: số liệu thật, tự đánh giá, lưu phiên và cập nhật streak.
// 5.3 (feature 003 US4, FR-013): Gret celebrates in the sea after the session, with the clarity
// gained ("+N% độ trong"), the pearls earned (spec 004) and a streak card that lights up when the
// streak grew. Rating, note and saving are unchanged.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/mascot_mood.dart';
import '../data/pearls.dart';
import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../providers/focus_session_provider.dart';
import '../providers/gret_corner_providers.dart';
import '../providers/sea_providers.dart';
import '../router/app_router.dart';
import '../services/time_format.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/motion/count_up_text.dart';
import '../widgets/sea/sea_scene.dart';
import '../widgets/streak_card.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  static const int _maxRating = 5;

  final _note = TextEditingController();

  /// Số liệu của phiên vừa xong; giữ cố định để không đổi khi phiên được đặt lại lúc rời màn.
  late final FocusSessionState _session;

  int? _rating;
  FocusSaveResult? _saveResult;
  bool _isSaving = false;

  bool get _isSaved => _saveResult != null;

  @override
  void initState() {
    super.initState();
    _session = ref.read(focusSessionProvider);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaved || _isSaving) return;
    setState(() => _isSaving = true); // Khoá nút để bấm hai lần không lưu hai lần.

    final result = await ref
        .read(focusSessionProvider.notifier)
        .save(rating: _rating, note: _note.text.trim());
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _saveResult = result;
    });
  }

  /// Rời màn mà chưa bấm "Lưu" thì vẫn lưu, để không mất thời gian học thật.
  Future<void> _goHome() async {
    await _save();
    if (!mounted) return;
    final notifier = ref.read(focusSessionProvider.notifier);
    context.go(AppRoutes.today);
    notifier.reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streak = ref.watch(overallStreakProvider);
    final result = _saveResult;
    final gain = ref.watch(clarityGainProvider);
    final pearls = Pearls.forSession(_session.focused.inSeconds);
    final celebrate = _session.finishedOnTime || gain > 0;

    // Phiên học đã xong nên nút Back của hệ thống đưa về Hôm nay, không quay lại Focus.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(AppStrings.summaryTitle),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                // Dùng SingleChildScrollView để ô ghi chú không bị gỡ khi cuộn lúc đang nhập.
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SeaScene(
                        clarity: ref.watch(clarityAfterSessionProvider),
                        mood: celebrate ? MascotMood.celebrating : MascotMood.happy,
                        variant: SeaSceneVariant.compact,
                        look: ref.watch(gretLookProvider),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _session.finishedOnTime
                            ? AppStrings.summaryWellDone
                            : AppStrings.summaryRecorded,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium,
                      ),
                      if (gain > 0 || pearls > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            if (gain > 0)
                              _GainPill(
                                icon: AppIcons.clarity,
                                child: CountUpText(
                                  value: gain,
                                  format: AppStrings.clarityGain,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            if (pearls > 0)
                              _GainPill(
                                icon: AppIcons.pearl,
                                child: Text(
                                  AppStrings.pearlGain(pearls),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (result != null && (result.streakGained || result.habitCompleted)) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          // Thói quen xong nhưng streak không tăng khi hôm nay đã có
                          // thói quen khác hoàn thành, lúc đó không được báo +1.
                          result.streakGained
                              ? AppStrings.summaryStreakGained
                              : AppStrings.summaryHabitDone,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      StreakCard(days: streak, highlight: result?.streakGained ?? false),
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        child: Column(
                          children: [
                            _StatRow(
                              icon: AppIcons.focus,
                              label: AppStrings.summaryFocused,
                              value: formatSpoken(_session.focused),
                            ),
                            const Divider(),
                            _StatRow(
                              icon: AppIcons.schedule,
                              label: AppStrings.summaryPlanned,
                              value: AppStrings.summaryMinutes(_session.plannedMinutes),
                            ),
                            const Divider(),
                            _StatRow(
                              icon: AppIcons.distraction,
                              label: AppStrings.distractionsLabel,
                              value: '${_session.distractionCount}',
                            ),
                            const Divider(),
                            _StatRow(
                              icon: AppIcons.away,
                              label: AppStrings.summaryAway,
                              value: formatSpoken(_session.totalAway),
                            ),
                            // 2.3, 2.4 Trên web không có Reset break.
                            if (ref.read(nativeBridgeProvider).isSupported) ...[
                              const Divider(),
                              _StatRow(
                                icon: AppIcons.intervention,
                                label: AppStrings.summaryBlocked,
                                value: AppStrings.summaryTimes(_session.interventionCount),
                              ),
                              const Divider(),
                              _StatRow(
                                icon: AppIcons.breakTime,
                                label: AppStrings.summaryBreaks,
                                value: AppStrings.summaryTimes(_session.breakCount),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        AppStrings.summaryRatingPrompt,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var star = 1; star <= _maxRating; star++)
                            IconButton(
                              tooltip: AppStrings.summaryStars(star),
                              color: theme.colorScheme.secondary,
                              icon: Icon(
                                star <= (_rating ?? 0) ? AppIcons.starFilled : AppIcons.star,
                              ),
                              onPressed: _isSaved ? null : () => setState(() => _rating = star),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _note,
                        enabled: !_isSaved,
                        maxLength: 140,
                        minLines: 1,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(labelText: AppStrings.summaryNote),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _goHome,
                        child: const Text(AppStrings.backToToday),
                      ),
                    ),
                    if (!_isSaved) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: GradientPillButton(
                          label: AppStrings.save,
                          height: AppButton.compact,
                          bubbles: true,
                          onPressed: _isSaving ? null : _save,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
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

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: AppSpacing.sm),
          // Hai bên cùng Expanded thì giá trị luôn sát lề phải, các dòng thẳng hàng với nhau.
          Expanded(
            child: Text(value, textAlign: TextAlign.end, style: theme.textTheme.titleSmall),
          ),
        ],
      ),
    );
  }
}

/// A small rounded badge for what the session earned (clarity, pearls).
class _GainPill extends StatelessWidget {
  const _GainPill({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: ShapeDecoration(color: scheme.secondaryContainer, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.md + AppSpacing.xs, color: scheme.onSecondaryContainer),
            const SizedBox(width: AppSpacing.xs),
            child,
          ],
        ),
      ),
    );
  }
}
