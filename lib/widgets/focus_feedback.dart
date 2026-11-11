// 3.3 Phản hồi nhắc khi quay lại sau một lần xao nhãng, và 3.4 âm báo khi hết giờ.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/focus_session_provider.dart';
import '../services/time_format.dart';
import '../theme/app_theme.dart';
import 'app_dialogs.dart';

/// Lựa chọn của người dùng trong bottom sheet nhắc.
enum NudgeChoice { keepStudying, watchReel, takeBreak }

/// Từ lần xao nhãng này trở đi thì nhắc bằng bottom sheet thay vì SnackBar.
const int _sheetFromIndex = 2;

/// Từ lần xao nhãng này trở đi thì gợi ý nghỉ.
const int _suggestBreakFromIndex = 4;

/// Thời lượng nghỉ được gợi ý trên sheet nhắc.
const int suggestedBreakMinutes = 5;

/// Lần đầu chỉ nhắc nhẹ; trả về false nếu đã nhắc xong và không cần hỏi gì thêm.
bool shouldAskAfterNudge(FocusNudge nudge) => nudge.distractionIndex >= _sheetFromIndex;

/// Lần 1: rung nhẹ và SnackBar.
void showWelcomeBack(BuildContext context) {
  if (!kIsWeb) HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Chào mừng quay lại! Tiếp tục nào 💪')));
}

/// Từ lần 2: hỏi người dùng muốn làm gì tiếp. Đóng sheet coi như chọn học tiếp.
Future<NudgeChoice> askAfterDistraction(BuildContext context, FocusNudge nudge) async {
  final choice = await showAppBottomSheet<NudgeChoice>(
    context,
    builder: (_) => _DistractionSheet(nudge: nudge),
  );
  return choice ?? NudgeChoice.keepStudying;
}

/// 3.4 Hết giờ: rung và phát âm nhẹ. Máy tắt rung hay tắt tiếng thì hệ thống tự bỏ qua.
void playSessionEndAlert() {
  if (kIsWeb) return;
  HapticFeedback.heavyImpact();
  SystemSound.play(SystemSoundType.click);
}

class _DistractionSheet extends StatelessWidget {
  const _DistractionSheet({required this.nudge});

  final FocusNudge nudge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestBreak = nudge.distractionIndex >= _suggestBreakFromIndex;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bạn vừa rời đi ${formatSpoken(nudge.away)}. Xem 1 reel động lực rồi quay lại?',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(NudgeChoice.watchReel),
                child: const Text('Xem reel'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(NudgeChoice.keepStudying),
                child: const Text('Học tiếp'),
              ),
            ),
          ],
        ),
        if (suggestBreak) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Có vẻ bạn mệt rồi, nghỉ $suggestedBreakMinutes phút nhé?',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(NudgeChoice.takeBreak),
            child: const Text('Nghỉ $suggestedBreakMinutes phút'),
          ),
        ],
      ],
    );
  }
}
