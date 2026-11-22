// F3 Đăng ký nhiều bước kiểu TikTok, có thanh tiến độ mảnh ở trên:
//   Bước 1 chọn tên đăng nhập (@ten, kiểm tra ngay khi gõ),
//   Bước 2 tạo mật khẩu (điều kiện tick dần, nhập lại), bấm "Tạo tài khoản",
//   Bước 3 "Chào mừng @ten!" → Bắt đầu (router đưa vào quiz động lực nếu chưa làm).
// Đang dùng thử mà có dữ liệu thì đăng ký xong dữ liệu được gộp lên tài khoản (sync_service).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../providers/account_providers.dart';
import '../../router/app_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import 'auth_widgets.dart';

/// Kiểm tra mật khẩu cho danh sách điều kiện ở bước 2 (hàm thuần).
class PasswordChecks {
  PasswordChecks._();

  static bool longEnough(String password) => AuthRules.passwordError(password) == null;

  /// Có cả chữ và số: chỉ khuyến nghị, không bắt buộc.
  static bool hasLetterAndDigit(String password) =>
      RegExp(r'[A-Za-z]').hasMatch(password) && RegExp(r'\d').hasMatch(password);
}

class SignupFlow extends ConsumerStatefulWidget {
  const SignupFlow({super.key});

  @override
  ConsumerState<SignupFlow> createState() => _SignupFlowState();
}

class _SignupFlowState extends ConsumerState<SignupFlow> {
  static const int _usernameStep = 0;
  static const int _passwordStep = 1;
  static const int _welcomeStep = 2;
  static const int _stepCount = 3;

  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  int _step = _usernameStep;
  bool _busy = false;

  /// Lỗi từ máy chủ ở bước tên (tên đã có người dùng) và ở bước mật khẩu.
  String? _usernameServerError;
  String? _passwordServerError;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String get _name => AuthRules.normalizeUsername(_username.text);

  /// Lỗi tên hiện ngay khi gõ; ô trống thì chưa báo.
  String? get _usernameError =>
      _usernameServerError ??
      (_username.text.isEmpty ? null : AuthRules.usernameError(_username.text));

  bool get _usernameOk => _username.text.isNotEmpty && AuthRules.usernameError(_name) == null;

  bool get _passwordsMatch => _confirm.text == _password.text;

  bool get _passwordOk =>
      PasswordChecks.longEnough(_password.text) && _confirm.text.isNotEmpty && _passwordsMatch;

  void _back() {
    if (_busy || _step == _welcomeStep) return;
    if (_step == _usernameStep) {
      authBack(context);
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _createAccount() async {
    if (!_passwordOk || _busy) return;
    setState(() {
      _busy = true;
      _passwordServerError = null;
    });
    try {
      final merged = await ref.read(accountActionsProvider).signUp(_name, _password.text);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = _welcomeStep;
      });
      if (merged) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã lưu dữ liệu của bạn vào tài khoản')));
      }
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (failure.code == AuthFailure.usernameTaken) {
          // Tên đã có người dùng: quay về bước 1, báo lỗi ngay dưới ô tên.
          _usernameServerError = failure.message;
          _step = _usernameStep;
        } else {
          _passwordServerError = failure.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      // Nút Back của hệ thống đi cùng đường với nút quay lại trên AppBar: về bước trước, ở bước
      // đầu thì về màn chào; bước chào mừng thì không quay lại được.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: AuthPage(
        showBack: _step != _welcomeStep,
        onBack: _back,
        top: LinearProgressIndicator(
          value: (_step + 1) / _stepCount,
          minHeight: AppAuth.progressHeight,
          color: scheme.tertiary,
          backgroundColor: scheme.outlineVariant,
        ),
        children: switch (_step) {
          _usernameStep => _usernameChildren(context),
          _passwordStep => _passwordChildren(context),
          _ => _welcomeChildren(context),
        },
      ),
    );
  }

  List<Widget> _usernameChildren(BuildContext context) {
    final theme = Theme.of(context);
    return [
      Text('Chọn tên đăng nhập', style: theme.textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Tên này dùng để đăng nhập và hiện trên Hồ sơ của bạn.',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: AppSpacing.lg),
      UsernameField(
        controller: _username,
        prefixAt: true,
        onChanged: (_) => setState(() => _usernameServerError = null),
        suffix: _usernameOk && _usernameServerError == null
            ? Icon(AppIcons.valid, color: theme.colorScheme.tertiary, semanticLabel: 'Tên hợp lệ')
            : null,
      ),
      AuthErrorText(_usernameError),
      const SizedBox(height: AppSpacing.sm),
      Text(
        '${AuthRules.minUsername}–${AuthRules.maxUsername} ký tự, chỉ gồm chữ a–z không dấu, '
        'số, dấu gạch dưới (_) và dấu chấm (.).',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: AppSpacing.lg),
      AuthPrimaryButton(
        label: 'Tiếp',
        onPressed: _usernameOk && _usernameServerError == null
            ? () => setState(() => _step = _passwordStep)
            : null,
      ),
    ];
  }

  List<Widget> _passwordChildren(BuildContext context) {
    final theme = Theme.of(context);
    final mismatch = _confirm.text.isNotEmpty && !_passwordsMatch;
    return [
      Text('Tạo mật khẩu', style: theme.textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.lg),
      PasswordField(
        controller: _password,
        enabled: !_busy,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() => _passwordServerError = null),
      ),
      const SizedBox(height: AppSpacing.sm),
      _Rule(
        label: 'Ít nhất ${AuthRules.minPassword} ký tự',
        met: PasswordChecks.longEnough(_password.text),
      ),
      _Rule(
        label: 'Có cả chữ và số (khuyến nghị)',
        met: PasswordChecks.hasLetterAndDigit(_password.text),
      ),
      const SizedBox(height: AppSpacing.md),
      PasswordField(
        controller: _confirm,
        label: 'Nhập lại mật khẩu',
        enabled: !_busy,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _createAccount(),
      ),
      AuthErrorText(mismatch ? 'Mật khẩu nhập lại không khớp' : _passwordServerError),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Hãy nhớ kỹ mật khẩu, app chưa hỗ trợ lấy lại mật khẩu.',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: AppSpacing.lg),
      AuthPrimaryButton(
        label: 'Tạo tài khoản',
        busy: _busy,
        onPressed: _passwordOk ? _createAccount : null,
      ),
    ];
  }

  List<Widget> _welcomeChildren(BuildContext context) {
    final theme = Theme.of(context);
    return [
      const SizedBox(height: AppSpacing.xl),
      Center(
        child: UserAvatar(username: _name, size: AppAuth.avatarLarge),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text('Chào mừng @$_name!', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Tài khoản đã sẵn sàng. Dữ liệu của bạn sẽ được đồng bộ trên mọi thiết bị đăng nhập.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: AppSpacing.xl),
      // Router tự đưa vào quiz động lực nếu chưa làm, không thì vào Trang chủ.
      AuthPrimaryButton(label: 'Bắt đầu', onPressed: () => context.go(AppRoutes.home)),
    ];
  }
}

/// Một dòng điều kiện mật khẩu: tick khi đạt.
class _Rule extends StatelessWidget {
  const _Rule({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = met ? theme.colorScheme.tertiary : theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(met ? AppIcons.valid : AppIcons.ruleUnmet, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
