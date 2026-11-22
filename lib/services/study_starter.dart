// 3.1 Bắt đầu phiên học.
// The single start path (spec 001, research R3): "Bỏ qua", "Bắt đầu N phút" and "Chỉ 5 phút thôi"
// all come here, so the Reset break check is never skipped and sessions never overlap.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/app_providers.dart';
import '../providers/focus_session_provider.dart';
import '../router/app_router.dart';
import '../widgets/reset_break_sheet.dart';

class StudyStarter {
  StudyStarter._();

  /// Containers (one per running app) whose start is waiting for the Reset break check;
  /// a second tap must not ask again. Keyed by container so a fresh app never inherits it.
  static final Expando<bool> _starting = Expando<bool>('StudyStarter');

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
    final container = ProviderScope.containerOf(context, listen: false);
    if (phase != FocusPhase.setup || _starting[container] == true) return;

    final habit = ref.read(sessionPlanProvider).habit;
    if (habit == null) return;

    _starting[container] = true;
    final bool canStart;
    try {
      canStart = await confirmStartWithResetBreak(context, ref);
    } finally {
      _starting[container] = null;
    }
    if (!canStart || !context.mounted) return;

    // If a session started meanwhile, start() does nothing: never two sessions at once.
    ref.read(focusSessionProvider.notifier).start(habit: habit, minutes: minutes);
    ref.read(sessionPlanOverrideProvider.notifier).clear();
    router.go(AppRoutes.focus);
  }
}
