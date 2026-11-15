// 4.1 Đặt mục tiêu – màn "Tạo thói quen" / "Sửa thói quen" (một trang cuộn), gồm:
// tab Thói quen / Việc một lần; tên; icon (hàng chọn nhanh + "Xem tất cả"); 12 màu pastel;
// Lặp lại: Hằng ngày / Hằng tuần (số ngày hoặc thứ cụ thể) / Hằng tháng (chọn ngày);
// Làm vào: Sáng / Chiều / Tối; Kết thúc vào (Ngày / Sau N ngày); Nhắc nhở (chỉ lưu giờ);
// số phút tối thiểu; "Sau khi…" và "Bản 2 phút" (không bắt buộc).
// Chỉ lưu khi bấm "Lưu"; đóng giữa chừng thì không có gì thay đổi.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/date_utils.dart';
import '../data/habit_icon_catalog.dart';
import '../data/models/goal.dart';
import '../data/models/habit.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_form_fields.dart';
import '../widgets/habit_icon_picker.dart';
import '../widgets/minutes_picker.dart';

class HabitFormScreen extends ConsumerStatefulWidget {
  const HabitFormScreen({required this.goalId, this.habitId, super.key});

  final String goalId;

  /// null là tạo thói quen mới.
  final String? habitId;

  /// Số ngày tối đa của "Kết thúc sau N ngày" (10 năm).
  static const int maxEndAfterDays = 3650;

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Habit? _habit;

  late HabitType _type;
  late String _icon;
  late int _colorIndex;
  late HabitRepeat _repeat;

  /// Hằng tuần: true là chọn thứ cụ thể, false là chọn số ngày mỗi tuần.
  late bool _weeklyByWeekdays;
  late int _daysPerWeek;
  late Set<int> _weekdays;
  late Set<int> _monthDays;
  late HabitTimeOfDay _timeOfDay;
  late bool _endEnabled;
  late HabitEndRule _endRule;
  late DateTime _endDate;
  late int _endAfterDays;
  late bool _reminderEnabled;
  late TimeOfDay _reminderTime;
  late DateTime _dueDate;

  late final TextEditingController _name;
  late final TextEditingController _minutes;
  late final TextEditingController _cue;
  late final TextEditingController _minimal;

  /// Lỗi của phần Lặp lại (chưa chọn thứ hoặc ngày nào), hiện sau khi bấm Lưu.
  String? _repeatError;

  @override
  void initState() {
    super.initState();
    final today = ref.read(todayProvider);
    final habit = ref.read(habitsProvider).where((habit) => habit.id == widget.habitId).firstOrNull;
    _habit = habit;

    _type = habit?.type ?? HabitType.regular;
    _icon = habit?.icon ?? HabitIconCatalog.quickPicks.first;
    _colorIndex = habit?.colorIndex ?? 0;
    _repeat = habit?.repeat ?? HabitRepeat.daily;
    _weeklyByWeekdays = habit != null && habit.weekdays.isNotEmpty;
    _daysPerWeek = habit?.daysPerWeek ?? 5;
    if (_daysPerWeek == 7 && habit?.repeat != HabitRepeat.weekly) _daysPerWeek = 5;
    _weekdays = {...?habit?.weekdays};
    _monthDays = {...?habit?.monthDays};
    _timeOfDay = habit?.timeOfDay ?? HabitTimeOfDay.anytime;
    _endEnabled = habit != null && habit.endRule != HabitEndRule.never;
    _endRule = habit?.endRule == HabitEndRule.afterDays
        ? HabitEndRule.afterDays
        : HabitEndRule.onDate;
    _endDate = habit?.endDate ?? addDays(today, 30);
    _endAfterDays = habit?.endAfterDays ?? Habit.defaultEndAfterDays;
    _reminderEnabled = habit?.reminderEnabled ?? false;
    _reminderTime = _parseTime(habit?.reminderTime ?? Habit.defaultReminderTime);
    _dueDate = habit?.dueDate ?? today;

    _name = TextEditingController(text: habit?.name);
    _minutes = TextEditingController(
      text: '${habit?.minMinutesPerDay ?? HabitFormFields.defaultMinutes}',
    );
    _cue = TextEditingController(
      text: habit == null || habit.cue.isEmpty ? '' : 'Sau khi ${habit.cue}',
    );
    _minimal = TextEditingController(text: habit?.minimalVersion);
  }

  @override
  void dispose() {
    for (final controller in [_name, _minutes, _cue, _minimal]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isEdit => widget.habitId != null;
  bool get _isOneTime => _type == HabitType.oneTime;

  static TimeOfDay _parseTime(String text) {
    final parts = text.split(':');
    return TimeOfDay(hour: int.tryParse(parts.first) ?? 7, minute: int.tryParse(parts.last) ?? 0);
  }

  static String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime day) {
    final today = ref.read(todayProvider);
    final prefix = day == today ? 'Hôm nay' : weekdayLong[day.weekday - 1];
    return '$prefix, ${day.day}/${day.month}/${day.year}';
  }

  Goal? _goalOf(List<Goal> goals) {
    final goalId = _habit?.goalId ?? widget.goalId;
    return goals.where((goal) => goal.id == goalId).firstOrNull;
  }

  /// Lưu phần sau "Sau khi": người dùng gõ "Sau khi ăn tối" hay "ăn tối" đều thành "ăn tối".
  String _cueWithoutPrefix() {
    final cue = _cue.text.trim();
    const prefix = 'sau khi ';
    return cue.toLowerCase().startsWith(prefix) ? cue.substring(prefix.length).trim() : cue;
  }

  /// Phần Lặp lại có lỗi không (chỉ kiểm tra khi là thói quen lặp lại).
  String? _validateRepeat() {
    if (_isOneTime) return null;
    if (_repeat == HabitRepeat.weekly && _weeklyByWeekdays && _weekdays.isEmpty) {
      return 'Chọn ít nhất một thứ trong tuần';
    }
    if (_repeat == HabitRepeat.monthly && _monthDays.isEmpty) {
      return 'Chọn ít nhất một ngày trong tháng';
    }
    return null;
  }

  Future<void> _save() async {
    final repeatError = _validateRepeat();
    setState(() => _repeatError = repeatError);
    final fieldsValid = _formKey.currentState!.validate();
    if (!fieldsValid || repeatError != null) return;

    final goal = _goalOf(ref.read(goalsProvider));
    if (goal == null) return;
    final existing = _habit;
    final weekly = !_isOneTime && _repeat == HabitRepeat.weekly;

    final draft = Habit(
      id: existing?.id ?? '',
      goalId: goal.id,
      name: _name.text.trim(),
      minMinutesPerDay: int.parse(_minutes.text),
      cue: _cueWithoutPrefix(),
      place: existing?.place ?? '',
      minimalVersion: _minimal.text.trim(),
      icon: _icon,
      type: _type,
      colorIndex: _colorIndex,
      repeat: _isOneTime ? HabitRepeat.daily : _repeat,
      daysPerWeek: weekly && !_weeklyByWeekdays ? _daysPerWeek : 7,
      weekdays: weekly && _weeklyByWeekdays ? (_weekdays.toList()..sort()) : const [],
      monthDays: !_isOneTime && _repeat == HabitRepeat.monthly
          ? (_monthDays.toList()..sort())
          : const [],
      timeOfDay: _timeOfDay,
      endRule: !_isOneTime && _endEnabled ? _endRule : HabitEndRule.never,
      endDate: _endDate,
      endAfterDays: _endAfterDays,
      reminderEnabled: _reminderEnabled,
      reminderTime: _formatTime(_reminderTime),
      sortOrder: existing?.sortOrder ?? 0,
      startDate: existing?.startDate,
      dueDate: _isOneTime ? _dueDate : null,
    );

    final notifier = ref.read(habitsProvider.notifier);
    if (existing == null) {
      await notifier.create(draft);
    } else {
      await notifier.edit(draft);
    }
    if (mounted) context.pop();
  }

  Future<void> _openIconPicker() async {
    final picked = await showHabitIconPicker(context, selected: _icon, colorIndex: _colorIndex);
    if (picked != null) setState(() => _icon = picked);
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: addDays(today, HabitFormScreen.maxEndAfterDays),
    );
    if (picked != null) setState(() => onPicked(dateOnly(picked)));
  }

  Future<void> _pickEndAfterDays() async {
    final days = await showDialog<int>(
      context: context,
      builder: (_) => _NumberDialog(initial: _endAfterDays, max: HabitFormScreen.maxEndAfterDays),
    );
    if (days != null) setState(() => _endAfterDays = days);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) setState(() => _reminderTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = _goalOf(ref.watch(goalsProvider));
    final missing = goal == null || (_isEdit && _habit == null);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.close),
          tooltip: 'Đóng',
          onPressed: () => context.pop(),
        ),
        title: Text(_isEdit ? 'Sửa thói quen' : 'Tạo thói quen'),
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
                Expanded(
                  // Dùng SingleChildScrollView chứ không dùng ListView: mọi ô luôn được dựng
                  // nên Form kiểm tra được cả ô ở cuối trang (ví dụ số phút tự nhập).
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<HabitType>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(value: HabitType.regular, label: Text('Thói quen')),
                                ButtonSegment(
                                  value: HabitType.oneTime,
                                  label: Text('Việc một lần'),
                                ),
                              ],
                              selected: {_type},
                              onSelectionChanged: (selected) =>
                                  setState(() => _type = selected.first),
                            ),
                          ),
                          _Section(
                            title: _isOneTime ? 'Tên việc' : 'Tên thói quen',
                            child: TextFormField(
                              controller: _name,
                              maxLength: 60,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: _isOneTime ? 'Ví dụ: Nộp bài tập lớn' : 'Ví dụ: Ôn bài',
                              ),
                              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                              validator: (value) => (value == null || value.trim().isEmpty)
                                  ? 'Hãy đặt tên cho ${_isOneTime ? 'việc này' : 'thói quen'}'
                                  : null,
                            ),
                          ),
                          _Section(
                            title: 'Biểu tượng',
                            trailing: TextButton.icon(
                              onPressed: _openIconPicker,
                              iconAlignment: IconAlignment.end,
                              icon: const Icon(AppIcons.arrowForward, size: 18),
                              label: const Text('Xem tất cả'),
                            ),
                            child: _QuickIcons(
                              selected: _icon,
                              colorIndex: _colorIndex,
                              onSelected: (icon) => setState(() => _icon = icon),
                            ),
                          ),
                          _Section(
                            title: 'Màu sắc',
                            child: _ColorGrid(
                              selected: _colorIndex,
                              onSelected: (index) => setState(() => _colorIndex = index),
                            ),
                          ),
                          if (_isOneTime)
                            _Section(
                              title: 'Khi nào',
                              child: _ValueRow(
                                icon: AppIcons.calendar,
                                text: _formatDate(_dueDate),
                                tooltip: 'Đổi ngày',
                                onTap: () =>
                                    _pickDate(initial: _dueDate, onPicked: (day) => _dueDate = day),
                              ),
                            )
                          else
                            _Section(title: 'Lặp lại', child: _repeatSection()),
                          _Section(
                            title: 'Làm vào',
                            child: _PillRow<HabitTimeOfDay>(
                              options: const {
                                HabitTimeOfDay.morning: 'Sáng',
                                HabitTimeOfDay.afternoon: 'Chiều',
                                HabitTimeOfDay.evening: 'Tối',
                              },
                              selected: _timeOfDay,
                              // Bấm lại buổi đang chọn thì bỏ chọn: làm lúc nào cũng được.
                              onSelected: (value) => setState(
                                () => _timeOfDay = value == _timeOfDay
                                    ? HabitTimeOfDay.anytime
                                    : value,
                              ),
                            ),
                          ),
                          if (!_isOneTime)
                            _Section(
                              title: 'Kết thúc vào',
                              trailing: Switch(
                                value: _endEnabled,
                                onChanged: (value) => setState(() => _endEnabled = value),
                              ),
                              child: _endEnabled ? _endSection() : null,
                            ),
                          _Section(
                            title: 'Nhắc nhở',
                            trailing: Switch(
                              value: _reminderEnabled,
                              onChanged: (value) => setState(() => _reminderEnabled = value),
                            ),
                            child: _reminderEnabled
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _ValueRow(
                                        icon: AppIcons.alarm,
                                        text: _formatTime(_reminderTime),
                                        tooltip: 'Đổi giờ nhắc',
                                        onTap: _pickReminderTime,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Bản này mới lưu giờ nhắc, chưa gửi thông báo.',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                          _Section(
                            title: 'Số phút tối thiểu mỗi lần',
                            child: MinutesPicker(
                              controller: _minutes,
                              presets: HabitFormFields.minutePresets,
                              maxMinutes: HabitFormFields.maxMinutes,
                            ),
                          ),
                          _Section(
                            title: 'Sau khi… (không bắt buộc)',
                            child: TextFormField(
                              controller: _cue,
                              maxLength: 60,
                              decoration: const InputDecoration(hintText: 'Sau khi ăn tối'),
                            ),
                          ),
                          _Section(
                            title: 'Bản 2 phút (không bắt buộc)',
                            child: TextFormField(
                              controller: _minimal,
                              maxLength: 80,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText: 'Việc thật nhỏ cho ngày mệt, ví dụ: Đọc 1 trang',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(onPressed: _save, child: const Text('Lưu')),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _repeatSection() {
    final theme = Theme.of(context);
    final Widget detail = switch (_repeat) {
      HabitRepeat.daily => Text('Mỗi ngày', style: theme.textTheme.bodyMedium),
      HabitRepeat.weekly => _weeklySection(),
      HabitRepeat.monthly => _MonthDayGrid(
        selected: _monthDays,
        onToggle: (day) => setState(() {
          _monthDays.contains(day) ? _monthDays.remove(day) : _monthDays.add(day);
          _repeatError = null;
        }),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PillRow<HabitRepeat>(
          options: const {
            HabitRepeat.daily: 'Hằng ngày',
            HabitRepeat.weekly: 'Hằng tuần',
            HabitRepeat.monthly: 'Hằng tháng',
          },
          selected: _repeat,
          onSelected: (value) => setState(() {
            _repeat = value;
            _repeatError = null;
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        detail,
        if (_repeatError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _repeatError!,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _weeklySection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: const Text('Số ngày mỗi tuần'),
              showCheckmark: false,
              selected: !_weeklyByWeekdays,
              onSelected: (_) => setState(() {
                _weeklyByWeekdays = false;
                _repeatError = null;
              }),
            ),
            ChoiceChip(
              label: const Text('Thứ cố định'),
              showCheckmark: false,
              selected: _weeklyByWeekdays,
              onSelected: (_) => setState(() => _weeklyByWeekdays = true),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_weeklyByWeekdays) ...[
          Text('Vào các thứ', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          _DotRow(
            labels: weekdayShort,
            isSelected: (i) => _weekdays.contains(i + 1),
            semanticsLabel: (i) => weekdayLong[i],
            onTap: (i) => setState(() {
              _weekdays.contains(i + 1) ? _weekdays.remove(i + 1) : _weekdays.add(i + 1);
              _repeatError = null;
            }),
          ),
        ] else ...[
          Text('$_daysPerWeek ngày mỗi tuần', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          _DotRow(
            labels: const ['1', '2', '3', '4', '5', '6', '7'],
            isSelected: (i) => _daysPerWeek == i + 1,
            semanticsLabel: (i) => '${i + 1} ngày mỗi tuần',
            onTap: (i) => setState(() => _daysPerWeek = i + 1),
          ),
        ],
      ],
    );
  }

  Widget _endSection() {
    return Column(
      children: [
        _PillRow<HabitEndRule>(
          options: const {HabitEndRule.onDate: 'Ngày', HabitEndRule.afterDays: 'Sau số ngày'},
          selected: _endRule,
          onSelected: (value) => setState(() => _endRule = value),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_endRule == HabitEndRule.onDate)
          _ValueRow(
            icon: AppIcons.calendar,
            text: _formatDate(_endDate),
            tooltip: 'Đổi ngày kết thúc',
            onTap: () => _pickDate(initial: _endDate, onPicked: (day) => _endDate = day),
          )
        else
          _ValueRow(
            icon: AppIcons.repeatDays,
            text: 'Sau $_endAfterDays ngày',
            tooltip: 'Đổi số ngày',
            onTap: _pickEndAfterDays,
          ),
      ],
    );
  }
}

/// Một phần của màn: tiêu đề (kèm nút bên phải nếu có) và nội dung.
class _Section extends StatelessWidget {
  const _Section({required this.title, this.child, this.trailing});

  final String title;
  final Widget? child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: AppHabit.pillChoice,
            child: Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                ?trailing,
              ],
            ),
          ),
          if (child != null) ...[const SizedBox(height: AppSpacing.sm), child!],
        ],
      ),
    );
  }
}

/// Hàng nút viên thuốc chia đều chiều ngang, chọn một.
class _PillRow<T> extends StatelessWidget {
  const _PillRow({required this.options, required this.selected, required this.onSelected});

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entries = options.entries.toList();

    return Row(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Semantics(
              button: true,
              selected: entries[i].key == selected,
              child: Material(
                color: entries[i].key == selected ? scheme.secondary : Colors.transparent,
                shape: StadiumBorder(
                  side: entries[i].key == selected
                      ? BorderSide.none
                      : BorderSide(color: scheme.outlineVariant),
                ),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => onSelected(entries[i].key),
                  child: SizedBox(
                    height: AppHabit.pillChoice,
                    child: Center(
                      child: Text(
                        entries[i].value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: entries[i].key == selected ? scheme.onSecondary : scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Hàng 7 ô tròn: số ngày mỗi tuần hoặc các thứ trong tuần.
class _DotRow extends StatelessWidget {
  const _DotRow({
    required this.labels,
    required this.isSelected,
    required this.semanticsLabel,
    required this.onTap,
  });

  final List<String> labels;
  final bool Function(int index) isSelected;
  final String Function(int index) semanticsLabel;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < labels.length; i++)
          _Dot(
            label: labels[i],
            selected: isSelected(i),
            semanticsLabel: semanticsLabel(i),
            onTap: () => onTap(i),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.label,
    required this.selected,
    required this.onTap,
    this.semanticsLabel,
    this.size = AppHabit.dayDot,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticsLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? scheme.secondary : null,
            border: selected ? null : Border.all(color: scheme.outlineVariant),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? scheme.onSecondary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Lịch chọn ngày trong tháng (1–31), 7 ô mỗi hàng.
class _MonthDayGrid extends StatelessWidget {
  const _MonthDayGrid({required this.selected, required this.onToggle});

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = selected.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            days.isEmpty ? 'Chọn các ngày trong tháng' : 'Hằng tháng vào ngày ${days.join(', ')}',
            style: theme.textTheme.bodyMedium,
          ),
          const Divider(height: AppSpacing.lg),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.xs,
            crossAxisSpacing: AppSpacing.xs,
            children: [
              for (var day = 1; day <= 31; day++)
                Center(
                  child: _Dot(
                    label: '$day',
                    selected: selected.contains(day),
                    semanticsLabel: 'Ngày $day',
                    size: AppHabit.dayDot - AppSpacing.xs,
                    onTap: () => onToggle(day),
                  ),
                ),
            ],
          ),
          Text(
            'Tháng không có ngày 29–31 thì làm vào ngày cuối tháng.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Hàng 5 icon chọn nhanh; icon đang chọn luôn đứng đầu nếu không có sẵn trong hàng.
class _QuickIcons extends StatelessWidget {
  const _QuickIcons({required this.selected, required this.colorIndex, required this.onSelected});

  final String selected;
  final int colorIndex;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final picks = HabitIconCatalog.quickPicks.contains(selected)
        ? HabitIconCatalog.quickPicks
        : [selected, ...HabitIconCatalog.quickPicks.take(HabitIconCatalog.quickPicks.length - 1)];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final icon in picks)
          HabitIconChoice(
            icon: icon,
            colorIndex: colorIndex,
            selected: icon == selected,
            onTap: () => onSelected(icon),
          ),
      ],
    );
  }
}

/// Lưới 12 màu pastel; màu đang chọn có dấu tick màu đậm cùng tông.
class _ColorGrid extends StatelessWidget {
  const _ColorGrid({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  static const List<String> _names = [
    'Xanh trời',
    'Xanh biển',
    'Xanh nước',
    'Ngọc',
    'Bạc hà',
    'Chanh non',
    'Vàng kem',
    'Đào',
    'Hồng',
    'Tím nhạt',
    'Oải hương',
    'Bạc',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < AppHabitColors.palette.length; i++)
          Semantics(
            button: true,
            selected: i == selected,
            label: 'Màu ${_names[i]}',
            excludeSemantics: true,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onSelected(i),
              child: Center(
                child: Container(
                  width: AppHabit.colorDot,
                  height: AppHabit.colorDot,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppHabitColors.palette[i].background,
                    border: i == selected ? Border.all(color: scheme.onSurface, width: 2) : null,
                  ),
                  child: i == selected
                      ? Icon(AppIcons.done, color: AppHabitColors.palette[i].foreground)
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Ô hiện một giá trị (ngày, giờ, số ngày) kèm nút sửa; bấm cả ô để đổi.
class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.icon,
    required this.text,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardBorder,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        customBorder: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, color: scheme.secondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
              IconButton(icon: const Icon(AppIcons.editValue), tooltip: tooltip, onPressed: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hộp thoại nhập số ngày cho "Kết thúc sau N ngày".
class _NumberDialog extends StatefulWidget {
  const _NumberDialog({required this.initial, required this.max});

  final int initial;
  final int max;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _days = TextEditingController(text: '${widget.initial}');

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) Navigator.of(context).pop(int.parse(_days.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kết thúc sau bao nhiêu ngày?'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _days,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(suffixText: 'ngày'),
          validator: (value) {
            final days = int.tryParse(value ?? '');
            if (days == null || days < 1 || days > widget.max) {
              return 'Nhập số ngày từ 1 đến ${widget.max}';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Huỷ')),
        TextButton(onPressed: _submit, child: const Text('Xong')),
      ],
    );
  }
}
