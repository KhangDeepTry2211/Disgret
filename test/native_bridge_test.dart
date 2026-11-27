// 2.1 Danh sách app: what Kotlin sends for getLaunchableApps (docs/architecture/native-bridge.md:
// a list of {packageName, name, icon (PNG bytes)}) must reach "Ứng dụng cần nhắc" as apps.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/services/native_bridge.dart';

void main() {
  final png = Uint8List.fromList([137, 80, 78, 71]);

  test('the list of maps Kotlin sends becomes installed apps', () {
    final apps = InstalledApp.listFrom([
      <Object?, Object?>{
        'packageName': 'com.google.android.youtube',
        'name': 'YouTube',
        'icon': png,
      },
      <Object?, Object?>{'packageName': 'com.android.chrome', 'name': 'Chrome', 'icon': png},
    ]);

    expect(apps.map((app) => app.packageName), [
      'com.google.android.youtube',
      'com.android.chrome',
    ]);
    expect(apps.first.name, 'YouTube');
    expect(apps.first.icon, png);
  });

  test('nothing, or entries without a package, give no apps', () {
    expect(InstalledApp.listFrom(null), isEmpty);
    expect(InstalledApp.listFrom('not a list'), isEmpty);
    expect(
      InstalledApp.listFrom([
        <Object?, Object?>{'name': 'No package'},
        'junk',
      ]),
      isEmpty,
    );
  });

  test('a missing icon or name still lists the app', () {
    final apps = InstalledApp.listFrom([
      <Object?, Object?>{'packageName': 'com.example.app'},
    ]);
    expect(apps.single.name, 'com.example.app');
    expect(apps.single.icon, isEmpty);
  });
}
