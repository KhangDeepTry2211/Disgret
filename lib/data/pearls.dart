// 5.4 Góc của Gret: pearls (ngọc trai) earned only by studying (spec 004 FR-001, ADR-0009).
// Pure functions: the balance is computed from saved sessions, never stored, so it cannot drift
// or be counted twice. Distractions never cost pearls.
import 'dart:math' as math;

import 'models/session.dart';

class Pearls {
  Pearls._();

  /// One pearl per five focused minutes of a session.
  static const int secondsPerPearl = 300;

  /// Pearls one session earns, rounded down.
  static int forSession(int focusedSeconds) =>
      focusedSeconds <= 0 ? 0 : focusedSeconds ~/ secondsPerPearl;

  /// Pearls earned by all saved sessions, each rounded down on its own.
  static int earned(Iterable<Session> sessions) =>
      sessions.fold(0, (sum, session) => sum + forSession(session.focusedSeconds));

  /// What the user can spend; never negative (sessions may be deleted with their habit).
  static int balance({required int earned, required int spent}) => math.max(0, earned - spent);
}
