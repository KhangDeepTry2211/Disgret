// 2.1 Danh sách app – lưu packageName của các app cần nhắc.
// F2: là bản ghi id "blocked_apps" trong box profile, được đồng bộ như dữ liệu khác.
import '../hive_boxes.dart';
import '../local_store.dart';

class BlockedAppsRepository {
  /// Id cố định của bản ghi, cũng là id document trên Firestore.
  static const String recordId = 'blocked_apps';

  /// Mặc định bật khi chưa từng chỉnh. TikTok có hai package tuỳ khu vực.
  static const Set<String> defaultPackages = {
    'com.zhiliaoapp.musically',
    'com.ss.android.ugc.trill',
    'com.facebook.katana',
    'com.instagram.android',
    'com.google.android.youtube',
    'com.android.chrome',
  };

  Set<String> get packages {
    final saved = LocalStore.read(HiveBoxes.profile, recordId)?['packages'] as List?;
    return saved == null ? defaultPackages : saved.cast<String>().toSet();
  }

  Future<void> save(Set<String> packages) =>
      LocalStore.write(HiveBoxes.profile, recordId, {'packages': packages.toList()});
}
