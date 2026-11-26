// 5.3 Gret và biển sống (spec 013): the sea is day from 06:00 to 17:59 and night from 18:00 to
// 05:59, by the phone's clock rather than dark mode.
abstract final class SeaTime {
  static const int dayStarts = 6;
  static const int nightStarts = 18;

  static bool isNight(DateTime now) => now.hour < dayStarts || now.hour >= nightStarts;

  /// The coming 06:00 or 18:00, when an open sea turns.
  static DateTime nextSwitch(DateTime now) {
    if (now.hour < dayStarts) return DateTime(now.year, now.month, now.day, dayStarts);
    if (now.hour < nightStarts) return DateTime(now.year, now.month, now.day, nightStarts);
    return DateTime(now.year, now.month, now.day + 1, dayStarts);
  }
}
