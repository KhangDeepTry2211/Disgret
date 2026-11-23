// 1.4 Liều động lực: danh sách reel hữu hạn, mỗi reel phát một lần rồi tới thẻ kết thúc.
// Pure state machine for the motivation step (spec 002, data-model.md). The screen only renders
// this state and plays the video; the rules live here so they can be unit-tested
// (test/motivation_dose_test.dart).
import '../data/models/reel.dart';
import 'reel_recommender.dart';

/// Where the step is.
enum MotivationPhase {
  /// The current reel is shown and plays once.
  playing,

  /// The current reel ended (or failed): the end card shows its actions.
  endCard,

  /// The step is finished: the caller starts, resumes or leaves.
  done,
}

/// Buttons the end card can show.
enum EndCardAction {
  /// "Bắt đầu N phút" with the planned duration.
  startPlanned,

  /// "Chỉ 5 phút thôi".
  smallStep,

  /// "Tiếp": the next reel of the playlist.
  next,

  /// "Quay lại học": back to the running session.
  backToSession,
}

class MotivationDose {
  /// [playlist] is cut to [ReelRecommender.limitFor] the [context]. An empty playlist starts
  /// in [MotivationPhase.done].
  MotivationDose({required this.context, required List<Reel> playlist})
    : playlist = List.unmodifiable(playlist.take(ReelRecommender.limitFor(context))) {
    if (this.playlist.isEmpty) _phase = MotivationPhase.done;
  }

  /// [ReelContext.start] or [ReelContext.distracted]; anything else behaves like start.
  final String context;
  final List<Reel> playlist;

  int _index = 0;
  MotivationPhase _phase = MotivationPhase.playing;

  int get index => _index;
  MotivationPhase get phase => _phase;
  bool get isEmpty => playlist.isEmpty;
  bool get isDistracted => context == ReelContext.distracted;

  /// The reel on screen; null when the playlist is empty.
  Reel? get current => isEmpty ? null : playlist[_index];

  /// 1-based position, used in the label and in the skip event.
  int get position => _index + 1;

  /// "1/3".
  String get positionLabel => '$position/${playlist.length}';

  /// "Tiếp" exists only before a session and only while another reel remains.
  bool get canGoNext => !isDistracted && _index < playlist.length - 1;

  /// "Bỏ qua" exists in every phase before a session, never after a distraction.
  bool get canSkip => !isDistracted && _phase != MotivationPhase.done;

  /// The end card's buttons, in display order; empty unless the end card is shown.
  List<EndCardAction> get endCardActions {
    if (_phase != MotivationPhase.endCard) return const [];
    if (isDistracted) return const [EndCardAction.backToSession];
    return [EndCardAction.startPlanned, EndCardAction.smallStep, if (canGoNext) EndCardAction.next];
  }

  /// The reel played to its end: show the end card (never loop).
  void videoEnded() {
    if (_phase == MotivationPhase.playing) _phase = MotivationPhase.endCard;
  }

  /// The reel could not be played: same as ending, so the user is never stuck.
  void videoFailed() => videoEnded();

  /// "Tiếp": from the end card to the next reel. Returns false when not allowed.
  bool next() {
    if (_phase != MotivationPhase.endCard || !canGoNext) return false;
    _index++;
    _phase = MotivationPhase.playing;
    return true;
  }

  /// "Bỏ qua".
  void skip() => _finish();

  /// "Bắt đầu N phút" or "Chỉ 5 phút thôi".
  void start() => _finish();

  /// "Quay lại học".
  void backToSession() => _finish();

  /// Close button or system Back.
  void leave() => _finish();

  void _finish() => _phase = MotivationPhase.done;
}
