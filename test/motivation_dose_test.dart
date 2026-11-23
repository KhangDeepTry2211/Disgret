// 1.4 Unit tests for the motivation dose state machine (spec 002 data-model.md).
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/models/reel.dart';
import 'package:focus_app/services/motivation_dose.dart';

Reel _reel(String id) => Reel(
  id: id,
  assetPath: '$id.mp4',
  title: id,
  tags: const [],
  lengthSec: 15,
  context: const [ReelContext.start, ReelContext.distracted],
);

final List<Reel> _three = [_reel('a'), _reel('b'), _reel('c')];

void main() {
  group('Playlist', () {
    test('Before a session: at most 3 reels, starts on the first one playing', () {
      final dose = MotivationDose(context: ReelContext.start, playlist: [..._three, _reel('d')]);

      expect(dose.playlist.map((reel) => reel.id), ['a', 'b', 'c']);
      expect(dose.index, 0);
      expect(dose.current?.id, 'a');
      expect(dose.phase, MotivationPhase.playing);
      expect(dose.position, 1);
      expect(dose.positionLabel, '1/3');
    });

    test('After a distraction: exactly 1 reel even if more are given', () {
      final dose = MotivationDose(context: ReelContext.distracted, playlist: _three);

      expect(dose.playlist.map((reel) => reel.id), ['a']);
      expect(dose.positionLabel, '1/1');
    });

    test('Empty playlist: done at once, no current reel', () {
      final dose = MotivationDose(context: ReelContext.start, playlist: const []);

      expect(dose.phase, MotivationPhase.done);
      expect(dose.isEmpty, isTrue);
      expect(dose.current, isNull);
      expect(dose.endCardActions, isEmpty);
    });

    test('Shorter playlist: the label shows the real count', () {
      final dose = MotivationDose(context: ReelContext.start, playlist: [_reel('a'), _reel('b')]);
      expect(dose.positionLabel, '1/2');
    });
  });

  group('Transitions', () {
    test('playing → endCard when the video ends; it never loops back to playing', () {
      final dose = MotivationDose(context: ReelContext.start, playlist: _three)..videoEnded();

      expect(dose.phase, MotivationPhase.endCard);
      dose.videoEnded();
      expect(dose.phase, MotivationPhase.endCard);
      expect(dose.index, 0);
    });

    test('A playback error shows the end card at once', () {
      final dose = MotivationDose(context: ReelContext.start, playlist: _three)..videoFailed();
      expect(dose.phase, MotivationPhase.endCard);
    });

    test('next() moves to the next reel only from the end card', () {
      final dose = MotivationDose(context: ReelContext.start, playlist: _three);

      expect(dose.next(), isFalse, reason: 'No skipping ahead while a reel plays');
      expect(dose.index, 0);

      dose.videoEnded();
      expect(dose.next(), isTrue);
      expect(dose.index, 1);
      expect(dose.phase, MotivationPhase.playing);
      expect(dose.positionLabel, '2/3');
    });

    test('No next() after the last reel', () {
      final dose = MotivationDose(context: ReelContext.start, playlist: _three);
      for (var i = 0; i < 2; i++) {
        dose
          ..videoEnded()
          ..next();
      }
      dose.videoEnded();

      expect(dose.index, 2);
      expect(dose.canGoNext, isFalse);
      expect(dose.next(), isFalse);
      expect(dose.phase, MotivationPhase.endCard);
    });

    test('next() never works after a distraction', () {
      final dose = MotivationDose(context: ReelContext.distracted, playlist: [_reel('a')])
        ..videoEnded();

      expect(dose.canGoNext, isFalse);
      expect(dose.next(), isFalse);
    });

    for (final finish in <String, void Function(MotivationDose)>{
      'skip': (dose) => dose.skip(),
      'start': (dose) => dose.start(),
      'backToSession': (dose) => dose.backToSession(),
      'leave': (dose) => dose.leave(),
    }.entries) {
      test('${finish.key}() → done, from playing and from the end card', () {
        final playing = MotivationDose(context: ReelContext.start, playlist: _three);
        finish.value(playing);
        expect(playing.phase, MotivationPhase.done);

        final ended = MotivationDose(context: ReelContext.start, playlist: _three)..videoEnded();
        finish.value(ended);
        expect(ended.phase, MotivationPhase.done);
        expect(ended.next(), isFalse);
      });
    }

    test('done is final: videoEnded() does not reopen the end card', () {
      final dose = MotivationDose(context: ReelContext.start, playlist: _three)
        ..skip()
        ..videoEnded();
      expect(dose.phase, MotivationPhase.done);
    });
  });

  group('Actions', () {
    test('Before a session: "Bỏ qua" while playing and on the end card', () {
      final dose = MotivationDose(context: ReelContext.start, playlist: _three);
      expect(dose.canSkip, isTrue);
      dose.videoEnded();
      expect(dose.canSkip, isTrue);
      dose.start();
      expect(dose.canSkip, isFalse);
    });

    test('After a distraction: no "Bỏ qua"', () {
      final dose = MotivationDose(context: ReelContext.distracted, playlist: _three);
      expect(dose.canSkip, isFalse);
    });

    test('End card before a session: start, 5 minutes, then "Tiếp" while reels remain', () {
      final dose = MotivationDose(context: ReelContext.start, playlist: _three)..videoEnded();
      expect(dose.endCardActions, [
        EndCardAction.startPlanned,
        EndCardAction.smallStep,
        EndCardAction.next,
      ]);

      dose
        ..next()
        ..videoEnded()
        ..next()
        ..videoEnded();
      expect(dose.endCardActions, [EndCardAction.startPlanned, EndCardAction.smallStep]);
    });

    test('End card after a distraction: only "Quay lại học"', () {
      final dose = MotivationDose(context: ReelContext.distracted, playlist: _three)..videoEnded();
      expect(dose.endCardActions, [EndCardAction.backToSession]);
    });

    test('No end-card actions while a reel plays', () {
      final dose = MotivationDose(context: ReelContext.start, playlist: _three);
      expect(dose.endCardActions, isEmpty);
    });

    test('Unknown context behaves like "start"', () {
      final dose = MotivationDose(context: 'other', playlist: _three);
      expect(dose.playlist, hasLength(3));
      expect(dose.isDistracted, isFalse);
      expect(dose.canSkip, isTrue);
    });
  });
}
