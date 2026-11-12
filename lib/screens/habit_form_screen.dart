// 4.1 Đặt mục tiêu – tạo hoặc sửa thói quen theo 4 bước, có thanh tiến độ:
// (1) bản sắc "Tôi muốn trở thành người…" (lưu vào mục tiêu),
// (2) tên thói quen, số phút mỗi ngày và icon,
// (3) "Sau khi…" và "Tại…" (ý định thực hiện),
// (4) phiên bản 2 phút, kèm câu xác nhận "Sau khi ăn tối, tôi sẽ học 25 phút tại bàn học."
// Chỉ lưu khi bấm "Lưu thói quen" ở bước cuối; đóng giữa chừng thì không có gì thay đổi.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/habit_science.dart';
import '../data/models/goal.dart';
import '../data/models/habit.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/goal_form_fields.dart';
import '../widgets/gradient_progress_bar.dart';
import '../widgets/habit_form_fields.dart';

class HabitFormScreen extends ConsumerStatefulWidget {
  const HabitFormScreen({required this.goalId, this.habitId, super.key});

  final String goalId;

  /// null là tạo thói quen mới.
  final String? habitId;

  static const int stepCount = 4;

  static const List<String> identitySuggestions = [
    'học đều mỗi ngày',
    'giữ lời hứa với bản thân',
    'không bỏ cuộc giữa chừng',
    'chủ động với việc học',
  ];
  static const List<String> cueSuggestions = ['ăn tối', 'đi học về', 'ăn sáng', 'thức dậy'];
  static const List<String> placeSuggestions = [
    'bàn học',
    'thư viện',
    'phòng tự học',
    'quán cà phê',
  ];
  static const List<String> minimalSuggestions = [
    'Mở sách đọc 1 trang',
    'Làm 1 câu bài tập',
    'Xem lại ghi chú 2 phút',
  ];

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Habit? _habit;
  late String _goalId;
  late String _icon;
  late final TextEditingController _identity;
  late final TextEditingController _name;
  late final TextEditingController _minutes;
  late final TextEditingController _cue;
  late final TextEditingController _place;
  late final TextEditingController _minimal;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    final habits = ref.read(habitsProvider);
    _habit = habits.where((habit) => habit.id == widget.habitId).firstOrNull;
    _goalId = _habit?.goalId ?? widget.goalId;
    _icon = _habit?.icon ?? Habit.defaultIcon;
    _identity = TextEditingController(text: _goalOf(ref.read(goalsProvider))?.identity);
    _name = TextEditingController(text: _habit?.name);
    _minutes = TextEditingController(
      text: '${_habit?.minMinutesPerDay ?? HabitFormFields.defaultMinutes}',
    );
    _cue = TextEditingController(text: _habit?.cue);
    _place = TextEditingController(text: _habit?.place);
    _minimal = TextEditingController(text: _habit?.minimalVersion);
  }

  @override
  void dispose() {
    for (final controller in [_identity, _name, _minutes, _cue, _place, _minimal]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isEdit => widget.habitId != null;

  Goal? _goalOf(List<Goal> goals) => goals.where((goal) => goal.id == _goalId).firstOrNull;

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    if (_step < HabitFormScreen.stepCount - 1) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  void _back() => setState(() => _step--);

  Future<void> _save() async {
    final goal = _goalOf(ref.read(goalsProvider));
    if (goal == null) return;
    final identity = _identity.text.trim();
    if (identity != goal.identity) {
      await ref.read(goalsProvider.notifier).edit(goal.copyWith(identity: identity));
    }

    final habits = ref.read(habitsProvider.notifier);
    final name = _name.text.trim();
    final minutes = int.parse(_minutes.text);
    final existing = _habit;
    if (existing == null) {
      await habits.add(
        goalId: goal.id,
        name: name,
        minMinutesPerDay: minutes,
        cue: _cue.text.trim(),
        place: _place.text.trim(),
        minimalVersion: _minimal.text.trim(),
        icon: _icon,
      );
    } else {
      await habits.edit(
        existing.copyWith(
          name: name,
          minMinutesPerDay: minutes,
          cue: _cue.text.trim(),
          place: _place.text.trim(),
          minimalVersion: _minimal.text.trim(),
          icon: _icon,
        ),
      );
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goals = ref.watch(goalsProvider);
    final goal = _goalOf(goals);
    final missing = goal == null || (_isEdit && _habit == null);

    return PopScope(
      // Nút Back của máy quay về bước trước, ở bước đầu thì đóng màn.
      canPop: _step == 0 || missing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(AppIcons.close),
            tooltip: 'Đóng',
            onPressed: () => context.pop(),
          ),
          title: Text(_isEdit ? 'Sửa thói quen' : 'Thói quen mới'),
        ),
        body: missing
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Không tìm thấy mục tiêu hoặc thói quen này. Có thể nó vừa bị xoá.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              )
            : Column(
                children: [
                  _StepHeader(step: _step),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Form(
                        key: _formKey,
                        child: switch (_step) {
                          0 => _identityStep(goals),
                          1 => _habitStep(),
                          2 => _cueStep(),
                          _ => _minimalStep(),
                        },
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          if (_step > 0) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _back,
                                child: const Text('Quay lại'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: _next,
                              child: Text(
                                _step == HabitFormScreen.stepCount - 1 ? 'Lưu thói quen' : 'Tiếp',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _identityStep(List<Goal> goals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepIntro(
          title: 'Bạn muốn trở thành người như thế nào?',
          body:
              'Thói quen bền hơn khi gắn với con người bạn muốn trở thành, không chỉ với kết quả. '
              'Mỗi lần làm là một lá phiếu cho con người đó.',
        ),
        if (!_isEdit && goals.length > 1) ...[
          Text('Thuộc mục tiêu', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final goal in goals)
                ChoiceChip(
                  label: Text(goal.title, overflow: TextOverflow.ellipsis),
                  showCheckmark: false,
                  selected: goal.id == _goalId,
                  onSelected: (_) => setState(() {
                    _goalId = goal.id;
                    _identity.text = goal.identity;
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        IdentityField(controller: _identity),
        _Suggestions(
          options: HabitFormScreen.identitySuggestions,
          onSelected: (value) => setState(() => _identity.text = value),
        ),
      ],
    );
  }

  Widget _habitStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepIntro(
          title: 'Thói quen nhỏ nào đưa bạn tới đó?',
          body: 'Chọn một việc cụ thể và số phút tối thiểu mỗi ngày. Nhỏ mà đều thắng lớn mà bỏ.',
        ),
        HabitFormFields(nameController: _name, minutesController: _minutes),
        const SizedBox(height: AppSpacing.lg),
        Text('Biểu tượng', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        _IconPicker(selected: _icon, onSelected: (icon) => setState(() => _icon = icon)),
      ],
    );
  }

  Widget _cueStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepIntro(
          title: 'Khi nào và ở đâu?',
          body:
              'Gắn thói quen vào một việc bạn vẫn làm hằng ngày và một nơi cố định. '
              'Nghiên cứu về "ý định thực hiện" (Gollwitzer & Sheeran, 2006) cho thấy '
              'ghi rõ khi nào, ở đâu giúp dễ làm thật hơn hẳn.',
        ),
        TextFormField(
          controller: _cue,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: 'Sau khi… (không bắt buộc)',
            prefixText: 'Sau khi ',
          ),
        ),
        _Suggestions(
          options: HabitFormScreen.cueSuggestions,
          onSelected: (value) => setState(() => _cue.text = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _place,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Tại… (không bắt buộc)', prefixText: 'Tại '),
        ),
        _Suggestions(
          options: HabitFormScreen.placeSuggestions,
          onSelected: (value) => setState(() => _place.text = value),
        ),
      ],
    );
  }

  Widget _minimalStep() {
    final theme = Theme.of(context);
    final identity = _identity.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepIntro(
          title: 'Phiên bản 2 phút',
          body:
              'Ngày mệt, làm bản thật nhỏ của thói quen để không đứt chuỗi. '
              'Bắt đầu dễ đến mức không thể từ chối.',
        ),
        TextFormField(
          controller: _minimal,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Phiên bản 2 phút (không bắt buộc)'),
          onChanged: (_) => setState(() {}),
        ),
        _Suggestions(
          options: HabitFormScreen.minimalSuggestions,
          onSelected: (value) => setState(() => _minimal.text = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.habitIcon(_icon), size: 20, color: theme.colorScheme.tertiary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Cam kết của bạn',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  HabitScience.intentionSentence(
                    name: _name.text,
                    minutes: int.tryParse(_minutes.text) ?? HabitFormFields.defaultMinutes,
                    cue: _cue.text,
                    place: _place.text,
                  ),
                  style: theme.textTheme.titleMedium,
                ),
                if (_minimal.text.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Ngày mệt: ${_minimal.text.trim()}.', style: theme.textTheme.bodyMedium),
                ],
                if (identity.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Vì tôi là người $identity.', style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Bước 2/4 · Thói quen" và thanh tiến độ.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  static const List<String> _names = ['Bản sắc', 'Thói quen', 'Khi nào, ở đâu', 'Bản 2 phút'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bước ${step + 1}/${HabitFormScreen.stepCount} · ${_names[step]}',
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          GradientProgressBar(value: (step + 1) / HabitFormScreen.stepCount, height: 6),
        ],
      ),
    );
  }
}

class _StepIntro extends StatelessWidget {
  const _StepIntro({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Các gợi ý bấm vào là điền sẵn.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.options, required this.onSelected});

  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in options)
          ActionChip(label: Text(option), onPressed: () => onSelected(option)),
      ],
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final entry in AppIcons.habitIcons.entries)
          Semantics(
            button: true,
            selected: entry.key == selected,
            label: 'Biểu tượng ${entry.key}',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onSelected(entry.key),
              customBorder: const CircleBorder(),
              child: Container(
                width: AppHabit.iconTile,
                height: AppHabit.iconTile,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: entry.key == selected ? scheme.secondary : null,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Icon(
                  entry.value,
                  color: entry.key == selected ? scheme.onSecondary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
