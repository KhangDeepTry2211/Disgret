// 1.2 Kho nội dung – một video reel tạo động lực, đọc từ assets/reels/reels.json.
import 'motivation_type.dart';

/// Ngữ cảnh đề xuất reel, chính là giá trị trong trường "context" của reels.json.
class ReelContext {
  ReelContext._();

  /// Trước khi học.
  static const String start = 'start';

  /// Sau khi xao nhãng.
  static const String distracted = 'distracted';
}

class Reel {
  const Reel({
    required this.id,
    required this.assetPath,
    required this.title,
    required this.tags,
    required this.lengthSec,
    required this.context,
    this.pinFirst = const [],
  });

  final String id;
  final String assetPath;
  final String title;
  final List<MotivationType> tags;
  final int lengthSec;

  /// Các ngữ cảnh phù hợp với reel này, xem [ReelContext].
  final List<String> context;

  /// 1.3 Ghim reel: mở Reels với một trong các ngữ cảnh này thì reel luôn đứng đầu,
  /// không cần xét điểm. Ví dụ "Get back to work!" ghim cho ngữ cảnh "distracted".
  final List<String> pinFirst;

  /// Các trường khác trong JSON (source, creditUrl) không dùng nên được bỏ qua.
  factory Reel.fromMap(Map<String, dynamic> map) => Reel(
    id: map['id'] as String,
    assetPath: map['assetPath'] as String,
    title: map['title'] as String,
    tags: (map['tags'] as List)
        .map((name) => MotivationType.values.byName(name as String))
        .toList(),
    lengthSec: map['lengthSec'] as int,
    context: (map['context'] as List).cast<String>().toList(),
    // Trường không bắt buộc: reel không ghim thì không cần ghi.
    pinFirst: (map['pinFirst'] as List? ?? const []).cast<String>().toList(),
  );
}
