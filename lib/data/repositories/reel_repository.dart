// 1.2 Kho nội dung – danh sách reel đọc từ asset, không lưu trong Hive.
import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/reel.dart';

class ReelRepository {
  static const String assetPath = 'assets/reels/reels.json';

  /// Đọc toàn bộ reel. Chỉ lấy mảng "reels", các key khác như "_huong_dan" bị bỏ qua.
  Future<List<Reel>> loadAll() async => parse(await rootBundle.loadString(assetPath));

  static List<Reel> parse(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    return (data['reels'] as List)
        .map((item) => Reel.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
