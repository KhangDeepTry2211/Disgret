// F1 Firebase: chỉ khởi tạo kết nối (chưa có đăng nhập hay đồng bộ).
// Dữ liệu chính vẫn ở Hive. Khởi tạo lỗi (thiếu cấu hình, không có mạng, nền tảng chưa hỗ trợ)
// thì app vẫn chạy bình thường như trước, chỉ không có Firebase.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../firebase_options.dart';

class FirebaseSetup {
  FirebaseSetup._();

  /// Chờ tối đa chừng này rồi bỏ qua, để màn hình đầu không bị treo khi mạng chậm.
  static const Duration timeout = Duration(seconds: 5);

  static bool _ready = false;

  /// Firebase đã khởi tạo xong chưa. Phần đăng nhập / đồng bộ sau này kiểm tra cờ này trước.
  static bool get isReady => _ready;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
          .timeout(timeout);
      _ready = true;
    } catch (error) {
      _ready = false;
      debugPrint('Không khởi tạo được Firebase, app chạy chỉ với Hive: $error');
    }
  }
}
