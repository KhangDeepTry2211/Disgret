// 7.1 Trước khi bắt đầu phiên Focus: nếu Reset break còn thiếu quyền thì hỏi người dùng.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/app_providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import 'app_dialogs.dart';

enum _ResetBreakChoice { grant, skip }

/// Trả về true nếu được bắt đầu phiên ngay. Chọn "Cấp quyền" hoặc đóng sheet thì chưa bắt đầu,
/// người dùng ở lại bước thiết lập và bấm "Bắt đầu" lại khi sẵn sàng.
Future<bool> confirmStartWithResetBreak(BuildContext context, WidgetRef ref) async {
  final native = ref.read(nativeBridgeProvider);
  // Không có app nào cần nhắc thì Reset break không có việc gì để làm, không cần hỏi.
  if (!native.isSupported || ref.read(blockedAppsProvider).isEmpty) return true;

  final permissions = await native.checkPermissions();
  if (permissions.canGuard) return true;
  if (!context.mounted) return false;

  final choice = await showAppBottomSheet<_ResetBreakChoice>(
    context,
    builder: (_) => const _ResetBreakSheet(),
  );
  if (!context.mounted) return false;

  if (choice == _ResetBreakChoice.grant) context.push(AppRoutes.resetBreakPermissions);
  return choice == _ResetBreakChoice.skip;
}

class _ResetBreakSheet extends StatelessWidget {
  const _ResetBreakSheet();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bật Reset break để chặn app gây xao nhãng?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ResetBreakChoice.grant),
          child: const Text('Cấp quyền'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(_ResetBreakChoice.skip),
          child: const Text('Học không cần Reset break'),
        ),
      ],
    );
  }
}
