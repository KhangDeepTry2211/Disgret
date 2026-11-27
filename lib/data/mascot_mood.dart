// 5.3 Gret và biển sống: Gret's mood from the sea clarity and the session state (spec 003 FR-006).

/// What Gret's face and pose show. The last four are short emotes (spec 018).
enum MascotMood {
  happy,
  neutral,
  sad,
  focused,
  sleeping,
  celebrating,
  love,
  surprised,
  proud,
  wink,
}

/// Clarity band shown as a label next to the clarity ring.
enum ClarityLevel {
  clear,
  hazy,
  murky;

  /// Happy at 70 or more, neutral from 40, sad below 40 (same thresholds as [moodFor]).
  static ClarityLevel of(double clarity) {
    if (clarity >= happyAt) return clear;
    if (clarity >= sadBelow) return hazy;
    return murky;
  }

  static const double happyAt = 70;
  static const double sadBelow = 40;
}

/// The summary celebrates; a running session shows Gret focused (or sleeping on a break);
/// otherwise the mood follows the clarity band.
MascotMood moodFor({
  required double clarity,
  bool isSessionRunning = false,
  bool isOnBreak = false,
  bool isSummary = false,
}) {
  if (isSummary) return MascotMood.celebrating;
  if (isSessionRunning) return isOnBreak ? MascotMood.sleeping : MascotMood.focused;
  return switch (ClarityLevel.of(clarity)) {
    ClarityLevel.clear => MascotMood.happy,
    ClarityLevel.hazy => MascotMood.neutral,
    ClarityLevel.murky => MascotMood.sad,
  };
}
