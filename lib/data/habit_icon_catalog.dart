// 4.1 Danh mục icon và emoji cho màn chọn icon, kèm từ khoá tiếng Việt để tìm kiếm.
// Icon Material lưu bằng khoá (xem AppIcons.habitIcons), emoji lưu nguyên ký tự.

/// Một lựa chọn trong màn chọn icon: [value] là giá trị lưu vào Habit.icon.
typedef HabitIconOption = ({String value, String keywords});

class HabitIconCatalog {
  HabitIconCatalog._();

  /// Icon Material (khoá trong AppIcons.habitIcons) và từ khoá.
  static const List<HabitIconOption> icons = [
    (value: 'book', keywords: 'sách học ôn bài'),
    (value: 'edit', keywords: 'viết bài tập ghi chép'),
    (value: 'reading', keywords: 'đọc sách truyện'),
    (value: 'school', keywords: 'trường lớp học đại học'),
    (value: 'laptop', keywords: 'máy tính laptop làm việc'),
    (value: 'code', keywords: 'lập trình code'),
    (value: 'language', keywords: 'ngoại ngữ tiếng anh dịch'),
    (value: 'math', keywords: 'toán tính máy tính'),
    (value: 'science', keywords: 'khoa học thí nghiệm hoá'),
    (value: 'idea', keywords: 'ý tưởng sáng tạo suy nghĩ'),
    (value: 'brush', keywords: 'vẽ mỹ thuật hội hoạ'),
    (value: 'camera', keywords: 'chụp ảnh máy ảnh'),
    (value: 'music', keywords: 'nhạc âm nhạc hát'),
    (value: 'headphones', keywords: 'nghe tai nghe podcast'),
    (value: 'fitness', keywords: 'tập gym thể dục tạ'),
    (value: 'run', keywords: 'chạy bộ thể thao'),
    (value: 'bike', keywords: 'đạp xe xe đạp'),
    (value: 'walk', keywords: 'đi bộ dạo'),
    (value: 'meditation', keywords: 'thiền yoga thư giãn'),
    (value: 'water', keywords: 'uống nước'),
    (value: 'food', keywords: 'ăn uống bữa ăn nấu'),
    (value: 'sleep', keywords: 'ngủ sớm đêm'),
    (value: 'sun', keywords: 'dậy sớm buổi sáng nắng'),
    (value: 'heart', keywords: 'sức khoẻ yêu thương tim'),
    (value: 'money', keywords: 'tiết kiệm tiền tài chính'),
    (value: 'clean', keywords: 'dọn dẹp nhà cửa'),
    (value: 'plant', keywords: 'cây hoa tưới cây'),
    (value: 'phone_off', keywords: 'bỏ điện thoại mạng xã hội'),
    (value: 'call', keywords: 'gọi điện gia đình'),
    (value: 'task', keywords: 'việc cần làm nhiệm vụ'),
  ];

  /// Emoji hệ thống và từ khoá.
  static const List<HabitIconOption> emojis = [
    (value: '📚', keywords: 'sách học ôn bài'),
    (value: '✏️', keywords: 'viết bút chì bài tập'),
    (value: '📝', keywords: 'ghi chép ghi chú'),
    (value: '🎓', keywords: 'tốt nghiệp đại học'),
    (value: '💻', keywords: 'máy tính lập trình'),
    (value: '🧠', keywords: 'não suy nghĩ ghi nhớ'),
    (value: '🔬', keywords: 'khoa học kính hiển vi'),
    (value: '🧮', keywords: 'toán tính'),
    (value: '🌏', keywords: 'ngoại ngữ thế giới địa lý'),
    (value: '🎨', keywords: 'vẽ mỹ thuật màu'),
    (value: '🎸', keywords: 'đàn guitar nhạc'),
    (value: '🎧', keywords: 'nghe nhạc podcast'),
    (value: '🏃', keywords: 'chạy bộ thể thao'),
    (value: '🏋️', keywords: 'tập gym tạ'),
    (value: '🚴', keywords: 'đạp xe'),
    (value: '🧘', keywords: 'thiền yoga'),
    (value: '⚽', keywords: 'bóng đá thể thao'),
    (value: '🏀', keywords: 'bóng rổ thể thao'),
    (value: '🏸', keywords: 'cầu lông thể thao'),
    (value: '💧', keywords: 'uống nước'),
    (value: '🥗', keywords: 'ăn rau ăn uống lành mạnh'),
    (value: '🍎', keywords: 'trái cây táo ăn uống'),
    (value: '😴', keywords: 'ngủ sớm'),
    (value: '☀️', keywords: 'dậy sớm buổi sáng'),
    (value: '🌙', keywords: 'buổi tối đêm'),
    (value: '💰', keywords: 'tiết kiệm tiền'),
    (value: '🧹', keywords: 'dọn dẹp nhà cửa'),
    (value: '🌱', keywords: 'cây phát triển bản thân'),
    (value: '📵', keywords: 'bỏ điện thoại mạng xã hội'),
    (value: '📞', keywords: 'gọi điện gia đình'),
    (value: '❤️', keywords: 'yêu thương sức khoẻ tim'),
    (value: '🎯', keywords: 'mục tiêu tập trung'),
    (value: '🏆', keywords: 'chiến thắng cúp thành tích'),
    (value: '⏰', keywords: 'báo thức giờ giấc'),
    (value: '✅', keywords: 'việc cần làm hoàn thành'),
  ];

  /// 5 lựa chọn hiện sẵn trên màn tạo thói quen (trước khi bấm "Xem tất cả").
  static const List<String> quickPicks = ['📚', 'book', '✏️', '💻', '🏃'];

  /// Lọc theo từ khoá, không phân biệt hoa thường và có dấu hay không dấu.
  static List<HabitIconOption> search(List<HabitIconOption> options, String query) {
    final normalized = foldVietnamese(query.trim());
    if (normalized.isEmpty) return options;
    return options.where((option) => foldVietnamese(option.keywords).contains(normalized)).toList();
  }

  static const String _withMarks =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  static const String _withoutMarks =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

  /// Chữ thường, bỏ dấu tiếng Việt: "Đọc Sách" → "doc sach".
  static String foldVietnamese(String text) {
    final buffer = StringBuffer();
    for (final char in text.toLowerCase().split('')) {
      final index = _withMarks.indexOf(char);
      buffer.write(index < 0 ? char : _withoutMarks[index]);
    }
    return buffer.toString();
  }
}
