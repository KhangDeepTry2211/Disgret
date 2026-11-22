// F2 Đăng nhập bằng tên + mật khẩu.
// Firebase chỉ nhận email, nên tên đăng nhập được đổi thành email ẩn "<ten>@disgret.app".
// Người dùng không bao giờ thấy email này. Các hàm kiểm tra và đổi lỗi là hàm thuần để test.
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_setup.dart';

/// Lỗi đăng nhập đã đổi sang câu tiếng Việt để hiện cho người dùng.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  /// Mã lỗi Firebase gặp lúc tên đăng nhập đã có người dùng (đăng ký quay về bước chọn tên).
  static const String usernameTaken = 'email-already-in-use';

  final String message;

  /// Mã lỗi gốc của Firebase, null nếu là lỗi nhập liệu hoặc không có máy chủ.
  final String? code;

  @override
  String toString() => message;
}

class AuthRules {
  AuthRules._();

  static const int minUsername = 3;
  static const int maxUsername = 20;
  static const int minPassword = 6;
  static const String emailDomain = 'disgret.app';
  static const String noServer = 'Không kết nối được máy chủ';

  static final RegExp _usernamePattern = RegExp(r'^[a-z0-9_.]+$');

  /// Chuyển chữ thường và bỏ mọi khoảng trắng: " Khang Tran " → "khangtran".
  static String normalizeUsername(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'\s'), '');

  /// Câu báo lỗi nếu tên không hợp lệ (sau khi chuẩn hoá), null nếu hợp lệ.
  static String? usernameError(String input) {
    final username = normalizeUsername(input);
    if (username.length < minUsername || username.length > maxUsername) {
      return 'Tên đăng nhập dài $minUsername–$maxUsername ký tự';
    }
    if (!_usernamePattern.hasMatch(username)) {
      return 'Tên đăng nhập chỉ gồm chữ a–z không dấu, số, dấu _ và dấu .';
    }
    return null;
  }

  static String? passwordError(String password) =>
      password.length < minPassword ? 'Mật khẩu cần ít nhất $minPassword ký tự' : null;

  static String emailFor(String username) => '${normalizeUsername(username)}@$emailDomain';

  /// Lấy lại tên đăng nhập từ email ẩn.
  static String usernameFromEmail(String email) => email.split('@').first;

  /// Đổi mã lỗi của FirebaseAuthException sang câu tiếng Việt.
  static String messageForCode(String code) => switch (code) {
    // Firebase mới gộp "sai mật khẩu" và "không có tài khoản" thành invalid-credential để
    // không lộ tên nào đã có người dùng.
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-email' ||
    'user-disabled' => 'Sai tên đăng nhập hoặc mật khẩu',
    'email-already-in-use' => 'Tên đăng nhập đã có người dùng',
    'weak-password' => 'Mật khẩu quá yếu, hãy dùng mật khẩu dài hơn',
    'network-request-failed' => 'Không có mạng, hãy kiểm tra kết nối rồi thử lại',
    'too-many-requests' => 'Thử quá nhiều lần, hãy đợi một lúc rồi thử lại',
    'operation-not-allowed' => 'Máy chủ chưa bật đăng nhập bằng mật khẩu',
    _ => 'Có lỗi xảy ra ($code), hãy thử lại',
  };
}

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Người dùng hiện tại; Firebase chưa sẵn sàng thì luôn là chưa đăng nhập.
  /// Dùng userChanges() để biết cả lúc tên hiển thị vừa được đặt sau khi đăng ký.
  Stream<AuthUser?> authStateChanges() => FirebaseSetup.isReady
      ? _auth.userChanges().map((user) => user == null ? null : AuthUser.fromFirebase(user))
      : Stream.value(null);

  /// Tạo tài khoản, trả về uid.
  Future<String> signUp(String username, String password) => _run(
    () async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: AuthRules.emailFor(username),
        password: password,
      );
      await credential.user?.updateDisplayName(AuthRules.normalizeUsername(username));
      return credential.user!.uid;
    },
    username,
    password,
  );

  /// Đăng nhập, trả về uid.
  Future<String> signIn(String username, String password) => _run(
    () async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: AuthRules.emailFor(username),
        password: password,
      );
      return credential.user!.uid;
    },
    username,
    password,
  );

  Future<void> signOut() async {
    if (FirebaseSetup.isReady) await _auth.signOut();
  }

  /// Kiểm tra dữ liệu nhập, gọi Firebase, đổi lỗi sang tiếng Việt.
  Future<String> _run(Future<String> Function() action, String username, String password) async {
    final inputError = AuthRules.usernameError(username) ?? AuthRules.passwordError(password);
    if (inputError != null) throw AuthFailure(inputError);
    if (!FirebaseSetup.isReady) throw const AuthFailure(AuthRules.noServer);
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(AuthRules.messageForCode(error.code), code: error.code);
    }
  }
}

/// Người dùng đã đăng nhập, chỉ giữ những gì giao diện cần. Không dùng thẳng User của Firebase
/// để test tạo được người dùng giả mà không cần Firebase.
class AuthUser {
  const AuthUser({required this.uid, required this.username, this.createdAt});

  factory AuthUser.fromFirebase(User user) {
    final name = user.displayName;
    return AuthUser(
      uid: user.uid,
      username: name != null && name.isNotEmpty
          ? name
          : AuthRules.usernameFromEmail(user.email ?? ''),
      createdAt: user.metadata.creationTime,
    );
  }

  final String uid;
  final String username;

  /// Ngày tạo tài khoản (ngày tham gia).
  final DateTime? createdAt;
}
