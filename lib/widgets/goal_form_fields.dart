// 4.1 Đặt mục tiêu – các ô nhập mục tiêu, dùng chung cho bottom sheet và onboarding.
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class GoalFormFields extends StatelessWidget {
  const GoalFormFields({
    required this.titleController,
    required this.reasonController,
    this.identityController,
    super.key,
  });

  final TextEditingController titleController;
  final TextEditingController reasonController;

  /// Câu bản sắc "Tôi là người…", không bắt buộc. null thì không hiện ô này (onboarding).
  final TextEditingController? identityController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: titleController,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Tên mục tiêu'),
          // Đang báo lỗi thì kiểm tra lại khi gõ, để dòng lỗi biến mất ngay khi nhập đúng.
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Hãy đặt tên cho mục tiêu' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: reasonController,
          maxLength: 200,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Vì sao bạn muốn điều này?'),
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Hãy ghi lại lý do của bạn' : null,
        ),
        if (identityController != null) ...[
          const SizedBox(height: AppSpacing.md),
          IdentityField(controller: identityController!),
        ],
      ],
    );
  }
}

/// 4.1 Ô nhập câu bản sắc: người dùng chỉ gõ phần sau "Tôi là người", ví dụ "học đều mỗi ngày".
class IdentityField extends StatelessWidget {
  const IdentityField({required this.controller, this.autofocus = false, super.key});

  final TextEditingController controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      maxLength: 80,
      textCapitalization: TextCapitalization.none,
      decoration: const InputDecoration(
        labelText: 'Tôi muốn trở thành người… (không bắt buộc)',
        prefixText: 'Tôi là người ',
      ),
    );
  }
}
