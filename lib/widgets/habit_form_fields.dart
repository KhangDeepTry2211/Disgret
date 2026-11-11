// 4.1 Đặt mục tiêu – các ô nhập thói quen, dùng chung cho bottom sheet và onboarding.
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'minutes_picker.dart';

class HabitFormFields extends StatelessWidget {
  const HabitFormFields({required this.nameController, required this.minutesController, super.key});

  static const List<int> minutePresets = [5, 15, 25, 45];
  static const int defaultMinutes = 25;

  /// Một ngày có 1440 phút nên không thể đặt mức tối thiểu cao hơn.
  static const int maxMinutes = 1440;

  final TextEditingController nameController;

  /// Giữ số phút ở dạng chữ. Chọn nhanh hay tự nhập đều ghi vào đây.
  final TextEditingController minutesController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: nameController,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Tên thói quen'),
          // Đang báo lỗi thì kiểm tra lại khi gõ, để dòng lỗi biến mất ngay khi nhập đúng.
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Hãy đặt tên cho thói quen' : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Số phút tối thiểu mỗi ngày', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        MinutesPicker(
          controller: minutesController,
          presets: minutePresets,
          maxMinutes: maxMinutes,
        ),
      ],
    );
  }
}
