// 3.1 Bắt đầu phiên học: một lối vào duy nhất cho mọi nút bắt đầu (spec 001, research R3).
// "Bỏ qua", "Bắt đầu N phút" và "Chỉ 5 phút thôi" đều đi qua đây, nên bước hỏi quyền Reset break
// không bao giờ bị bỏ qua và không bao giờ tạo phiên chồng lên nhau.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/app_providers.dart';
import '../providers/focus_session_provider.dart';
import '../router/app_router.dart';
import '../widgets/reset_break_sheet.dart';

class StudyStarter {
  StudyStarter._();

  /// A start is waiting for the Reset break check; a second tap must not ask again.
  static bool _isStarting = false;

  /// Starts a session for the Hôm nay plan habit with [minutes] and opens `/focus`.
  ///
  /// - A session is already running: only opens `/focus`.
  /// - No habit in the plan: does nothing.
  /// - The Reset break check is declined: stays where the user is.
  static Future<void> start(BuildContext context, WidgetRef ref, {required int minutes}) async {
    final router = GoRouter.of(context);
    final phase = ref.read(focusSessionProvider).phase;
    if (phase == FocusPhase.running) {
      router.go(AppRoutes.focus);
      return;
    }
    if (phase != FocusPhase.setup || _isStarting) return;

    final habit = ref.read(sessionPlanProvider).habit;
    if (habit == null) return;

    _isStarting = true;
    final bool canStart;
    try {
      canStart = await confirmStartWithResetBreak(context, ref);
    } finally {
      _isStarting = false;
    }
    if (!canStart || !context.mounted) return;

    // If a session started meanwhile, start() does nothing: never two sessions at once.
    ref.read(focusSessionProvider.notifier).start(habit: habit, minutes: minutes);
    ref.read(sessionPlanOverrideProvider.notifier).clear();
    router.go(AppRoutes.focus);
  }
}
