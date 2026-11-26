// 5.3 Gret và biển sống (spec 013 FR-001): the sea is day from 06:00 to 17:59 and night from 18:00
// to 05:59, by the phone's clock.
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/sea_time.dart';

void main() {
  test('night runs from 18:00 to 05:59, day from 06:00 to 17:59', () {
    expect(SeaTime.isNight(DateTime(2026, 11, 25, 0, 30)), isTrue);
    expect(SeaTime.isNight(DateTime(2026, 11, 25, 5, 59)), isTrue);
    expect(SeaTime.isNight(DateTime(2026, 11, 25, 6)), isFalse);
    expect(SeaTime.isNight(DateTime(2026, 11, 25, 17, 59)), isFalse);
    expect(SeaTime.isNight(DateTime(2026, 11, 25, 18)), isTrue);
  });

  test('the sea switches next at the coming 06:00 or 18:00', () {
    expect(SeaTime.nextSwitch(DateTime(2026, 11, 25, 3)), DateTime(2026, 11, 25, 6));
    expect(SeaTime.nextSwitch(DateTime(2026, 11, 25, 6)), DateTime(2026, 11, 25, 18));
    expect(SeaTime.nextSwitch(DateTime(2026, 11, 25, 17, 59, 30)), DateTime(2026, 11, 25, 18));
    expect(SeaTime.nextSwitch(DateTime(2026, 11, 30, 18)), DateTime(2026, 12, 1, 6));
  });
}
