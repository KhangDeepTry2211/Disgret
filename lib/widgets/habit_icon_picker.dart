// 4.1 Màn chọn icon (bottom sheet): ô tìm kiếm, 2 tab Icon / Emoji, lưới chọn, Huỷ / Chọn.
import 'package:material_ui/material_ui.dart';

import '../data/habit_icon_catalog.dart';
import '../theme/app_theme.dart';
import 'habit_icon_view.dart';

/// Mở màn chọn icon; trả về icon đã chọn, hoặc null nếu huỷ.
Future<String?> showHabitIconPicker(
  BuildContext context, {
  required String selected,
  required int colorIndex,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _HabitIconPicker(selected: selected, colorIndex: colorIndex),
    ),
  );
}

/// Một ô icon vuông bo góc; ô đang chọn tô màu pastel của thói quen và có viền nhấn.
class HabitIconChoice extends StatelessWidget {
  const HabitIconChoice({
    required this.icon,
    required this.colorIndex,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String icon;
  final int colorIndex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = AppHabitColors.of(colorIndex);

    return Semantics(
      button: true,
      selected: selected,
      label: 'Biểu tượng $icon',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: AppRadius.cardBorder,
        onTap: onTap,
        child: Container(
          width: AppHabit.iconTile + AppSpacing.sm,
          height: AppHabit.iconTile + AppSpacing.sm,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color.background : null,
            borderRadius: AppRadius.cardBorder,
            border: Border.all(
              color: selected ? scheme.secondary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: HabitIconView(
            icon: icon,
            size: 28,
            color: selected ? color.foreground : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _HabitIconPicker extends StatefulWidget {
  const _HabitIconPicker({required this.selected, required this.colorIndex});

  final String selected;
  final int colorIndex;

  @override
  State<_HabitIconPicker> createState() => _HabitIconPickerState();
}

class _HabitIconPickerState extends State<_HabitIconPicker> {
  late String _selected = widget.selected;

  /// Mở sẵn tab chứa icon đang chọn.
  late bool _emojiTab = !HabitIconView.isMaterialIcon(widget.selected);
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = HabitIconCatalog.search(
      _emojiTab ? HabitIconCatalog.emojis : HabitIconCatalog.icons,
      _search.text,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      child: Column(
        children: [
          Text('Chọn biểu tượng', style: theme.textTheme.titleLarge),
          const Divider(height: AppSpacing.lg),
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              hintText: 'Tìm biểu tượng, ví dụ: sách, chạy',
              prefixIcon: Icon(AppIcons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Icon')),
                ButtonSegment(value: true, label: Text('Emoji')),
              ],
              selected: {_emojiTab},
              onSelectionChanged: (selected) => setState(() => _emojiTab = selected.first),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: options.isEmpty
                ? Center(
                    child: Text(
                      'Không có biểu tượng nào khớp "${_search.text.trim()}".',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : GridView.count(
                    crossAxisCount: 5,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    children: [
                      for (final option in options)
                        Center(
                          child: HabitIconChoice(
                            icon: option.value,
                            colorIndex: widget.colorIndex,
                            selected: option.value == _selected,
                            onTap: () => setState(() => _selected = option.value),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Huỷ'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: const Text('Chọn'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
