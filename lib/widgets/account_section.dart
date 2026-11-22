// F2 Mục "Tài khoản" trong Cài đặt (bản thử, sẽ làm đẹp sau):
// chưa đăng nhập thì có ô Tên đăng nhập / Mật khẩu và 2 nút Đăng nhập, Đăng ký;
// đã đăng nhập thì hiện tên, trạng thái đồng bộ, lần đồng bộ gần nhất và nút Đăng xuất.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/account_providers.dart';
import '../router/app_router.dart';
import '../services/auth_service.dart';
import '../services/firebase_setup.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import 'app_dialogs.dart';

class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final username = ref.watch(currentUsernameProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tài khoản', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: !FirebaseSetup.isReady
                ? Text(
                    '${AuthRules.noServer}. App vẫn lưu dữ liệu trên máy như bình thường.',
                    style: theme.textTheme.bodyMedium,
                  )
                : username == null
                ? const _SignInForm()
                : _SignedIn(username: username),
          ),
        ),
      ],
    );
  }
}

class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm();

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool signUp}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final actions = ref.read(accountActionsProvider);
    try {
      signUp
          ? await actions.signUp(_username.text, _password.text)
          : await actions.signIn(_username.text, _password.text);
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Đăng nhập để sao lưu và dùng dữ liệu trên nhiều máy.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _username,
          enabled: !_busy,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Tên đăng nhập',
            helperText: '3–20 ký tự: a–z, số, dấu _ và dấu .',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _password,
          enabled: !_busy,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            helperText: 'Ít nhất ${AuthRules.minPassword} ký tự',
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              icon: Icon(_obscure ? AppIcons.showPassword : AppIcons.hidePassword),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          onSubmitted: (_) => _submit(signUp: false),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _submit(signUp: true),
                child: const Text('Đăng ký'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () => _submit(signUp: false),
                child: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Đăng nhập'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SignedIn extends ConsumerWidget {
  const _SignedIn({required this.username});

  final String username;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Đăng xuất?',
      message:
          'Dữ liệu đã đồng bộ vẫn còn trên tài khoản. Máy này sẽ xoá dữ liệu và quay về '
          'như mới cài; đăng nhập lại để lấy về.',
      confirmLabel: 'Đăng xuất',
    );
    if (!confirmed) return;
    await ref.read(accountActionsProvider).signOut();
    if (context.mounted) context.go(AppRoutes.onboarding);
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sync = ref.watch(syncStatusProvider);
    final (icon, label) = switch (sync.status) {
      SyncStatus.synced => (AppIcons.synced, 'Đã đồng bộ'),
      SyncStatus.syncing => (AppIcons.syncing, 'Đang đồng bộ…'),
      SyncStatus.offline => (AppIcons.offline, 'Ngoại tuyến, sẽ đồng bộ khi có mạng'),
      SyncStatus.error => (AppIcons.syncError, 'Lỗi đồng bộ'),
    };
    final last = sync.lastSyncedAt?.toLocal();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(AppIcons.account),
          title: Text(username, style: theme.textTheme.titleMedium),
          subtitle: const Text('Đang đăng nhập'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            icon,
            color: sync.status == SyncStatus.error ? theme.colorScheme.error : null,
          ),
          title: Text(label),
          subtitle: Text(
            [
              if (last != null)
                'Gần nhất: ${_two(last.hour)}:${_two(last.minute)} '
                    '${_two(last.day)}/${_two(last.month)}/${last.year}',
              if (sync.status == SyncStatus.error && sync.error != null) sync.error!,
            ].join('\n'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          icon: const Icon(AppIcons.logout),
          label: const Text('Đăng xuất'),
          onPressed: () => _signOut(context, ref),
        ),
      ],
    );
  }
}
