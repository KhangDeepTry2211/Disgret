// 3.4 Màn Tổng kết phiên: số liệu thật, tự đánh giá, lưu phiên và cập nhật streak.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/app_providers.dart';
import '../providers/focus_session_provider.dart';
import '../router/app_router.dart';
import '../services/time_format.dart';
import '../theme/app_theme.dart';
import '../widgets/streak_ring.dart';

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
    context.go(AppRoutes.home);
    notifier.reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streak = ref.watch(overallStreakProvider);
    final result = _saveResult;

    // Phiên học đã xong nên nút Back của hệ thống đưa về Trang chủ, không quay lại Focus.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Tổng kết')),
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
                      Center(child: StreakRing(days: streak, size: 144)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _session.finishedOnTime ? 'Làm tốt lắm!' : 'Đã ghi nhận phiên học',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium,
                      ),
                      if (result != null && (result.streakGained || result.habitCompleted)) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          // Thói quen xong nhưng streak không tăng khi hôm nay đã có
                          // thói quen khác hoàn thành, lúc đó không được báo +1.
                          result.streakGained
                              ? '+1 ngày streak 🔥'
                              : 'Đã hoàn thành thói quen hôm nay',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Card(
                        child: Column(
                          children: [
                            _StatRow(
                              icon: AppIcons.focus,
                              label: 'Thời gian tập trung',
                              value: formatSpoken(_session.focused),
                            ),
                            const Divider(),
                            _StatRow(
                              icon: AppIcons.schedule,
                              label: 'Thời lượng đã đặt',
                              value: '${_session.plannedMinutes} phút',
                            ),
                            const Divider(),
                            _StatRow(
                              icon: AppIcons.distraction,
                              label: 'Số lần xao nhãng',
                              value: '${_session.distractionCount}',
                            ),
                            const Divider(),
                            _StatRow(
                              icon: AppIcons.away,
                              label: 'Thời gian ở ngoài',
                              value: formatSpoken(_session.totalAway),
                            ),
                            // 2.3, 2.4 Trên web không có Reset break.
                            if (ref.read(nativeBridgeProvider).isSupported) ...[
                              const Divider(),
                              _StatRow(
                                icon: AppIcons.intervention,
                                label: 'Reset break đã chặn',
                                value: '${_session.interventionCount} lần',
                              ),
                              const Divider(),
                              _StatRow(
                                icon: AppIcons.breakTime,
                                label: 'Nghỉ có chủ đích',
                                value: '${_session.breakCount} lần',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Bạn đánh giá phiên này thế nào?',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var star = 1; star <= _maxRating; star++)
                            IconButton(
                              tooltip: '$star sao',
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
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú ngắn (không bắt buộc)',
                        ),
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
                        child: const Text('Về Trang chủ'),
                      ),
                    ),
                    if (!_isSaved) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving ? null : _save,
                          child: const Text('Lưu'),
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
