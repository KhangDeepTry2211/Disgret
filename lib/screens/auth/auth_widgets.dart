// F3 Phần dùng chung của màn đăng nhập và đăng ký: khung trang, ô mật khẩu có nút ẩn/hiện,
// dòng lỗi đỏ dưới ô nhập, nút chính có vòng xoay khi đang xử lý.
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';

/// Quay lại: mở từ Hồ sơ (push) thì pop; mở từ màn chào (go) thì không còn gì để pop nên về
/// màn chào.
void authBack(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(AppRoutes.welcome);

/// Khung trang: nút quay lại, nội dung cuộn được, giữa màn và giới hạn bề rộng trên web.
class AuthPage extends StatelessWidget {
  const AuthPage({
    required this.children,
    this.onBack,
    this.showBack = true,
    this.top,
    this.bottom,
    super.key,
  });

  final List<Widget> children;

  /// null thì dùng nút quay lại mặc định (pop).
  final VoidCallback? onBack;

  /// Ẩn nút quay lại (bước cuối của đăng ký: tài khoản đã tạo, không quay lại được).
  final bool showBack;

  /// Phần nằm ngay dưới AppBar, ví dụ thanh tiến độ của luồng đăng ký.
  final Widget? top;

  /// Phần dính ở đáy màn, ví dụ "Chưa có tài khoản? Đăng ký".
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: showBack ? BackButton(onPressed: onBack ?? () => authBack(context)) : null,
        bottom: top == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(AppAuth.progressHeight),
                child: top!,
              ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppAuth.maxContentWidth),
            child: Column(
              children: [
                Expanded(
                  child: ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: children),
                ),
                if (bottom != null)
                  Padding(padding: const EdgeInsets.all(AppSpacing.md), child: bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dòng lỗi đỏ ngay dưới ô nhập (không dùng hộp thoại).
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
      ),
    );
  }
}

/// Ô nhập tên đăng nhập: không tự viết hoa, không tự sửa, tự chuyển chữ thường và bỏ khoảng trắng.
class UsernameField extends StatelessWidget {
  const UsernameField({
    required this.controller,
    this.onChanged,
    this.prefixAt = false,
    this.suffix,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  /// Hiện tiền tố "@" (luồng đăng ký kiểu TikTok).
  final bool prefixAt;
  final Widget? suffix;
  final bool enabled;

  static final List<TextInputFormatter> formatters = [
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
    _LowerCaseFormatter(),
  ];

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.none,
      keyboardType: TextInputType.visiblePassword, // Bàn phím không gợi ý, không tự viết hoa.
      textInputAction: TextInputAction.next,
      inputFormatters: formatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Tên đăng nhập',
        prefixText: prefixAt ? '@' : null,
        suffixIcon: suffix,
      ),
    );
  }
}

class _LowerCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toLowerCase());
}

/// Ô mật khẩu có nút ẩn/hiện.
class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    this.label = 'Mật khẩu',
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.textInputAction = TextInputAction.done,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final TextInputAction textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _hidden,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          tooltip: _hidden ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
          icon: Icon(_hidden ? AppIcons.showPassword : AppIcons.hidePassword),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
    );
  }
}

/// Nút chính toàn chiều ngang: mờ khi [onPressed] null, có vòng xoay khi [busy].
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        // Đang xử lý thì khoá nút để không bấm hai lần.
        onPressed: busy ? null : onPressed,
        child: busy
            ? SizedBox.square(
                dimension: 22,
                // Nút bị khoá có nền nhạt nên vòng xoay dùng màu chính cho dễ thấy.
                child: CircularProgressIndicator(strokeWidth: 2.5, color: scheme.primary),
              )
            : Text(label),
      ),
    );
  }
}
