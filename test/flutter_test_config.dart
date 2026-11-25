// Runs before every test file: loads the app's real fonts (spec 011), so widget tests measure
// text the way the phone does and catch overflow with Baloo 2 and Nunito.
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/theme/app_theme.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final (family, file) in const [
    (AppFonts.heading, 'assets/fonts/Baloo2-Variable.ttf'),
    (AppFonts.body, 'assets/fonts/Nunito-Variable.ttf'),
  ]) {
    final bytes = File(file).readAsBytesSync();
    await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
  await testMain();
}
