// 6.2 Mô hình dữ liệu – các loại động lực của người dùng.

enum MotivationType {
  money('Tiền bạc'),
  family('Gia đình'),
  career('Sự nghiệp'),
  proveYourself('Chứng minh bản thân'),
  freedom('Tự do');

  const MotivationType(this.label);

  /// Tên hiển thị trên giao diện.
  final String label;
}
