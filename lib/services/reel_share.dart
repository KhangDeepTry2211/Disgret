// 1.4 Chia sẻ reel: chỉ chia sẻ ĐOẠN CHỮ (tiêu đề + lời rủ học cùng DisGret), không gửi file video
// vì video chỉ dùng demo trên lớp. Không mở được bảng chia sẻ (ví dụ trình duyệt không hỗ trợ)
// thì chép nội dung vào clipboard.
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/reel.dart';

/// Kết quả chia sẻ: dùng để quyết định có hiện SnackBar "Đã chép nội dung chia sẻ" hay không.
enum ReelShareOutcome { shared, copiedToClipboard, failed }

class ReelShare {
  ReelShare._();

  /// Nội dung chia sẻ.
  static String textFor(Reel reel) =>
      '${reel.title}\n\nMình đang dùng DisGret để tập trung học thay vì lướt reel. Học cùng mình nhé!';

  /// Hàm mở bảng chia sẻ của hệ điều hành. Test thay bằng hàm giả vì plugin không chạy trong test.
  @visibleForTesting
  static Future<ShareResult> Function(String text) openShareSheet = (text) =>
      SharePlus.instance.share(ShareParams(text: text));

  static Future<ReelShareOutcome> share(Reel reel) async {
    final text = textFor(reel);
    try {
      final result = await openShareSheet(text);
      if (result.status != ShareResultStatus.unavailable) return ReelShareOutcome.shared;
    } catch (_) {
      // Không có bảng chia sẻ (web cũ, máy ảo, test): chuyển sang chép clipboard.
    }

    try {
      await Clipboard.setData(ClipboardData(text: text));
      return ReelShareOutcome.copiedToClipboard;
    } catch (_) {
      return ReelShareOutcome.failed;
    }
  }
}
