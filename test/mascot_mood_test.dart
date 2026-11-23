// 5.3 Unit tests for Gret's mood (spec 003 FR-006).
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/mascot_mood.dart';

void main() {
  test('clarity thresholds: happy at 70+, neutral 40–69, sad below 40', () {
    expect(moodFor(clarity: 100), MascotMood.happy);
    expect(moodFor(clarity: 70), MascotMood.happy);
    expect(moodFor(clarity: 69.9), MascotMood.neutral);
    expect(moodFor(clarity: 40), MascotMood.neutral);
    expect(moodFor(clarity: 39.9), MascotMood.sad);
    expect(moodFor(clarity: 0), MascotMood.sad);
  });

  test('a running session overrides the clarity', () {
    expect(moodFor(clarity: 10, isSessionRunning: true), MascotMood.focused);
    expect(moodFor(clarity: 90, isSessionRunning: true, isOnBreak: true), MascotMood.sleeping);
  });

  test('the summary always celebrates', () {
    expect(moodFor(clarity: 5, isSummary: true), MascotMood.celebrating);
    expect(moodFor(clarity: 5, isSummary: true, isSessionRunning: true), MascotMood.celebrating);
  });

  test('clarity labels follow the same thresholds', () {
    expect(ClarityLevel.of(85), ClarityLevel.clear);
    expect(ClarityLevel.of(55), ClarityLevel.hazy);
    expect(ClarityLevel.of(12), ClarityLevel.murky);
  });
}
