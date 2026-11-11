// 3.1, 4.1 Chọn số phút: các mức nhanh dạng chip hoặc tự nhập. Dùng cho thói quen (4.1) và phiên học (3.1).
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class MinutesPicker extends StatefulWidget {
  const MinutesPicker({
    required this.controller,
    required this.presets,
    required this.maxMinutes,
    super.key,
  });

  /// Giữ số phút ở dạng chữ. Chọn nhanh hay tự nhập đều ghi vào đây.
  final TextEditingController controller;
  final List<int> presets;
  final int maxMinutes;

  @override
  State<MinutesPicker> createState() => _MinutesPickerState();
}

class _MinutesPickerState extends State<MinutesPicker> {
  late bool _isCustom;

  @override
  void initState() {
    super.initState();
    // Số phút có sẵn không nằm trong các mức nhanh thì mở sẵn ô tự nhập.
    _isCustom = !widget.presets.contains(int.tryParse(widget.controller.text));
  }

  void _selectPreset(int minutes) {
    setState(() {
      _isCustom = false;
      widget.controller.text = '$minutes';
    });
  }

  String? _validateCustomMinutes(String? value) {
    final minutes = int.tryParse(value ?? '');
    if (minutes == null || minutes < 1 || minutes > widget.maxMinutes) {
      return 'Nhập số phút từ 1 đến ${widget.maxMinutes}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = int.tryParse(widget.controller.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final minutes in widget.presets)
              ChoiceChip(
                label: Text('$minutes phút'),
                showCheckmark: false,
                selected: !_isCustom && selected == minutes,
                onSelected: (_) => _selectPreset(minutes),
              ),
            ChoiceChip(
              label: const Text('Tự nhập'),
              showCheckmark: false,
              selected: _isCustom,
              onSelected: (_) => setState(() => _isCustom = true),
            ),
          ],
        ),
        if (_isCustom) ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: widget.controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: const InputDecoration(labelText: 'Số phút', suffixText: 'phút'),
            autovalidateMode: AutovalidateMode.onUserInteractionIfError,
            validator: _validateCustomMinutes,
          ),
        ],
      ],
    );
  }
}
