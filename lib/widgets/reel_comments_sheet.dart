// 1.4 Bottom sheet bình luận của một reel: cao ~60% màn hình, kéo xuống để đóng, tự đẩy lên khi
// bàn phím mở. Bình luận mới nhất nằm dưới cùng. Nhấn giữ bình luận của mình để xoá.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/reel_comment.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'app_dialogs.dart';

/// "vừa xong", "2 phút trước", "3 giờ trước", "5 ngày trước"; quá 30 ngày thì ghi ngày.
String timeAgo(DateTime now, DateTime time) {
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return 'vừa xong';
  if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
  if (diff.inDays < 1) return '${diff.inHours} giờ trước';
  if (diff.inDays <= 30) return '${diff.inDays} ngày trước';
  return '${time.day}/${time.month}/${time.year}';
}

Future<void> showReelCommentsSheet(BuildContext context, {required String reelId}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      // Bàn phím mở thì đẩy cả sheet lên, và không cao quá phần màn hình còn trống.
      final height = (media.size.height * AppReels.commentSheetFraction).clamp(
        0.0,
        media.size.height - media.viewInsets.bottom - media.padding.top - kToolbarHeight,
      );
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SizedBox(
          height: height,
          child: ReelCommentsSheet(reelId: reelId),
        ),
      );
    },
  );
}

class ReelCommentsSheet extends ConsumerStatefulWidget {
  const ReelCommentsSheet({required this.reelId, super.key});

  final String reelId;

  @override
  ConsumerState<ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends ConsumerState<ReelCommentsSheet> {
  final TextEditingController _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  bool get _canSend => _input.text.trim().isNotEmpty;

  Future<void> _send() async {
    if (!_canSend) return;
    final text = _input.text;
    _input.clear();
    await ref.read(reelCommentsProvider.notifier).add(widget.reelId, text);
  }

  Future<void> _confirmDelete(ReelComment comment) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xoá bình luận?',
      message: 'Bình luận này sẽ bị xoá.',
      confirmLabel: 'Xoá',
    );
    if (confirmed) await ref.read(reelCommentsProvider.notifier).delete(comment.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = ref.read(clockProvider)();
    final comments = [
      for (final comment in ref.watch(reelCommentsProvider))
        if (comment.reelId == widget.reelId) comment,
    ];

    return Column(
      children: [
        Text('Bình luận', style: theme.textTheme.titleMedium),
        const Divider(height: AppSpacing.md),
        Expanded(
          child: comments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Chưa có bình luận. Viết cảm nhận của bạn về video này nhé!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  // reverse: mới nhất ở dưới cùng và danh sách luôn bám đáy.
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[comments.length - 1 - index];
                    return _CommentTile(
                      comment: comment,
                      timeLabel: timeAgo(now, comment.createdAt),
                      onLongPress: comment.isMine ? () => _confirmDelete(comment) : null,
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  maxLength: ReelComment.maxLength,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Viết bình luận...',
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Gửi bình luận',
                onPressed: _canSend ? _send : null,
                icon: const Icon(AppIcons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.timeLabel, this.onLongPress});

  final ReelComment comment;
  final String timeLabel;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.secondaryContainer,
              child: Text(
                comment.authorLabel.characters.first.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSecondaryContainer),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: comment.authorLabel, style: theme.textTheme.labelLarge),
                        TextSpan(
                          text: '  $timeLabel',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(comment.text, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
