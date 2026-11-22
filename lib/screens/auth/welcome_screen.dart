// F3 Màn chào: hiện khi mở app mà chưa đăng nhập và chưa chọn "Dùng thử" (router quyết định).
// Logo, tên app, khẩu hiệu ở trên; dưới cùng là Đăng nhập, Tạo tài khoản mới, Dùng thử.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../providers/account_providers.dart';
import '../../providers/app_providers.dart';
import '../../router/app_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  /// Hiện khi bấm Đăng nhập / Đăng ký mà không có máy chủ.
  bool _showNoServer = false;

  void _openAuth(String route) {
    if (!ref.read(firebaseReadyProvider)) {
      setState(() => _showNoServer = true);
      return;
    }
    // Dùng go (không push): đăng nhập xong router chạy lại redirect theo đường dẫn gốc; nếu gốc
    // vẫn là /welcome thì sẽ bị đưa đi giữa chừng, mất màn chờ và bước "Chào mừng".
    context.go(route);
  }

  Future<void> _tryAsGuest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dùng thử'),
        content: const Text(
          'Dữ liệu chỉ lưu trên máy này, bạn có thể tạo tài khoản sau trong Hồ sơ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(profileRepositoryProvider).setGuestMode(true);
    // Router đưa vào quiz động lực nếu chưa làm, không thì vào Trang chủ.
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppAuth.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const AppLogo(size: AppAuth.welcomeLogo),
                            const SizedBox(height: AppSpacing.md),
                            Text('DisGret', style: theme.textTheme.headlineMedium),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Bắt đầu học nhanh, quay lại tập trung sau mỗi lần xao nhãng.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_showNoServer) ...[
                    Text(
                      '${AuthRules.noServer}. Bạn có thể dùng thử trước, tạo tài khoản sau.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  FilledButton(
                    onPressed: () => _openAuth(AppRoutes.login),
                    child: const Text('Đăng nhập'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => _openAuth(AppRoutes.signup),
                    child: const Text('Tạo tài khoản mới'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: _tryAsGuest,
                    child: const Text('Dùng thử không cần tài khoản'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
