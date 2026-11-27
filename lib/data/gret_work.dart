// 3.2 Phiên học: Gret works at its own desk while the student studies (spec 019 user story 1).
// Pure: which task Gret does depends only on the session's focused time.

/// What Gret does at the desk, in turn.
enum WorkTask { writing, typing, reading }

/// The coral-rock desk on the sea floor, or the wooden desk in Quán San Hô.
enum DeskKind { coral, wood }

/// Gret at a desk: which desk, and the task (null on a break: Gret sleeps at an empty desk).
class MascotWork {
  const MascotWork({required this.desk, this.task});

  final DeskKind desk;
  final WorkTask? task;
}

abstract final class GretWork {
  /// Gret changes task this often, in session time (so 40 s in demo mode, where a minute lasts
  /// 20 s).
  static const Duration taskEvery = Duration(minutes: 2);

  /// The task after [focused] of the session: writing, typing, reading, writing…
  static WorkTask taskAt(Duration focused) {
    final turns = focused.isNegative ? 0 : focused.inSeconds ~/ taskEvery.inSeconds;
    return WorkTask.values[turns % WorkTask.values.length];
  }
}
