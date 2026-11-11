// 5.1 Điểm khởi động: mở Hive (6.2) rồi chạy giao diện.
import 'package:flutter/foundation.dart' show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 5.2 Font Be Vietnam Pro nằm sẵn trong assets/fonts/: không tải qua mạng, nên lúc demo
  // không có wifi chữ vẫn đúng font.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Giấy phép OFL của font hiện trong trang giấy phép của app.
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Be Vietnam Pro'], license);
  });

  await Hive.initFlutter();
  await HiveBoxes.openAll();

  runApp(const ProviderScope(child: DisGretApp()));
}
