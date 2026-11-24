// 5.1 Đổi kế hoạch phiên học.
// Change the habit and minutes of the next session from Hôm nay (spec 001 FR-003). The choice
// lasts one session: starting it resets the plan.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/session_plan.dart';
import '../data/study_place.dart';
import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../providers/sea_cafe_providers.dart';
import '../theme/app_theme.dart';
import 'app_dialogs.dart';
import 'minutes_picker.dart';
import 'sticker_chip.dart';

/// Opens the plan sheet; the choice is written to [sessionPlanOverrideProvider].
Future<void> showSessionPlanSheet(BuildContext context) =>
    showAppBottomSheet<void>(context, builder: (_) => const SessionPlanSheet());

class SessionPlanSheet extends ConsumerStatefulWidget {
  const SessionPlanSheet({super.key});

  static const List<int> presets = [5, 25, 45];

  @override
  ConsumerState<SessionPlanSheet> createState() => _SessionPlanSheetState();
}

class _SessionPlanSheetState extends ConsumerState<SessionPlanSheet> {
  /// 5.6 The two study places as sticker chips (AppHabitColors index for the colour).
  static const _places = [
    (StudyPlace.sea, AppStrings.placeSea, AppIcons.sea, 0),
    (StudyPlace.cafe, AppStrings.placeCafe, AppIcons.cafe, 7),
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minutes;
  String? _habitId;
  late StudyPlace _place;

  @override
  void initState() {
    super.initState();
    final plan = ref.read(sessionPlanProvider);
    _habitId = plan.habit?.id;
    _place = ref.read(studyPlaceProvider);
    _minutes = TextEditingController(text: '${plan.plannedMinutes}');
  }

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(sessionPlanOverrideProvider.notifier)
        .choose(habitId: _habitId, minutes: int.tryParse(_minutes.text));
    // 5.6 The place is a lasting preference, unlike the habit and minutes (spec 006 FR-002).
    ref.read(studyPlaceProvider.notifier).choose(_place);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habits = ref.watch(habitsProvider);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.planSheetTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _habitId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: AppStrings.planHabit),
            items: [
              for (final habit in habits)
                DropdownMenuItem(
                  value: habit.id,
                  child: Text(habit.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) => setState(() => _habitId = id),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(AppStrings.planDuration, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          MinutesPicker(
            controller: _minutes,
            presets: SessionPlanSheet.presets,
            maxMinutes: SessionPlan.maxMinutes,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(AppStrings.planPlace, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (place, label, icon, colour) in _places)
                StickerChip(
                  label: label,
                  icon: icon,
                  colour: colour,
                  selected: _place == place,
                  onSelected: (_) => setState(() => _place = place),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: _apply, child: const Text(AppStrings.planApply)),
        ],
      ),
    );
  }
}
