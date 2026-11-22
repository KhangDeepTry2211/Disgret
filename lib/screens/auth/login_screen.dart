// F3 Màn Đăng nhập: tên đăng nhập + mật khẩu, lỗi hiện ngay dưới ô nhập bằng chữ đỏ.
// Đăng nhập xong thì hiện "Đang tải dữ liệu của bạn…" trong lúc sync_service gộp dữ liệu,
// rồi vào Trang chủ (router tự đưa vào quiz động lực nếu tài khoản chưa làm).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../providers/account_providers.dart';
import '../../router/app_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_dialogs.dart';
import 'auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;

  /// Đã đăng nhập, đang chờ tải dữ liệu về.
  bool _loadingData = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit => _username.text.isNotEmpty && _password.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // signIn gồm cả chờ tải dữ liệu; đổi sang màn chờ ngay khi Firebase nhận đăng nhập.
      await ref
          .read(accountActionsProvider)
          .signIn(
            _username.text,
            _password.text,
            onSignedIn: () {
              if (mounted) setState(() => _loadingData = true);
            },
          );
      if (mounted) context.go(AppRoutes.home);
    } on AuthFailure catch (failure) {
      if (mounted) {
        setState(() {
          _error = failure.message;
          _busy = false;
          _loadingData = false;
        });
      }
    }
  }

  void _showForgotPassword() {
    showAppBottomSheet<void>(
      context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text('Quên mật khẩu?', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tài khoản DisGret dùng tên đăng nhập, không gắn email hay số điện thoại, nên app '
              'chưa lấy lại mật khẩu tự động được. Hãy liên hệ nhóm phát triển để được hỗ trợ.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Đã hiểu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loadingData) return const _LoadingDataView();

    // Nút Back của hệ thống: mở từ màn chào thì về màn chào thay vì thoát app.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_busy) authBack(context);
      },
      child: _form(theme),
    );
  }

  Widget _form(ThemeData theme) {
    return AuthPage(
      bottom: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Chưa có tài khoản?', style: theme.textTheme.bodyMedium),
          TextButton(
            onPressed: _busy
                ? null
                : () => context.canPop()
                      ? context.pushReplacement(AppRoutes.signup)
                      : context.go(AppRoutes.signup),
            child: const Text('Đăng ký'),
          ),
        ],
      ),
      children: [
        Text('Đăng nhập', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        UsernameField(
          controller: _username,
          enabled: !_busy,
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: AppSpacing.md),
        PasswordField(
          controller: _password,
          enabled: !_busy,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _submit(),
        ),
        AuthErrorText(_error),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: _showForgotPassword, child: const Text('Quên mật khẩu?')),
        ),
        const SizedBox(height: AppSpacing.sm),
        AuthPrimaryButton(label: 'Đăng nhập', busy: _busy, onPressed: _canSubmit ? _submit : null),
      ],
    );
  }
}

/// Màn chờ ngắn sau khi đăng nhập, trong lúc tải và gộp dữ liệu trên mây.
class _LoadingDataView extends StatelessWidget {
  const _LoadingDataView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text('Đang tải dữ liệu của bạn…', style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
