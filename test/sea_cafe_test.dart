// 5.6 Quán San Hô: the study place preference, the place recorded on a session, the sea friends
// and what they say (spec 006 FR-001, FR-005–FR-008).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/gret_corner_catalog.dart';
import 'package:focus_app/data/mascot_species.dart';
import 'package:focus_app/data/models/session.dart';
import 'package:focus_app/data/repositories/gret_corner_repository.dart';
import 'package:focus_app/data/sea_cafe.dart';
import 'package:focus_app/data/study_place.dart';
import 'package:focus_app/providers/gret_corner_providers.dart';
import 'package:focus_app/providers/sea_cafe_providers.dart';
import 'package:hive/hive.dart';

import 'test_helpers.dart';

void main() {
  setUp(openMemoryBoxes);
  tearDown(() async => Hive.close());

  group('Study place (FR-001)', () {
    test('parses known names and rejects others', () {
      expect(StudyPlace.tryParse('cafe'), StudyPlace.cafe);
      expect(StudyPlace.tryParse('sea'), StudyPlace.sea);
      expect(StudyPlace.tryParse('moon'), isNull);
      expect(StudyPlace.tryParse(null), isNull);
      expect(StudyPlace.tryParse(3), isNull);
    });

    test('a student who never chose studies in the café', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(studyPlaceProvider), StudyPlace.cafe);
    });

    test('the choice is kept', () async {
      final first = ProviderContainer();
      await first.read(studyPlaceProvider.notifier).choose(StudyPlace.sea);
      expect(first.read(studyPlaceProvider), StudyPlace.sea);
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);
      expect(second.read(studyPlaceProvider), StudyPlace.sea);
    });
  });

  group('Sea friends (FR-005)', () {
    List<MascotSpecies> species(List<SeaFriend> friends) => [
      for (final friend in friends) friend.species,
    ];

    test('with Gret worn, Ẩn, Mochi and Sao sit at the tables', () {
      expect(species(SeaCafe.seated(MascotSpecies.gret)), [
        MascotSpecies.crab,
        MascotSpecies.octopus,
        MascotSpecies.starfish,
      ]);
    });

    test('the worn species never sits at a table; Gret takes the free seat', () {
      expect(species(SeaCafe.seated(MascotSpecies.crab)), [
        MascotSpecies.octopus,
        MascotSpecies.starfish,
        MascotSpecies.gret,
      ]);
      final withOctopus = species(SeaCafe.seated(MascotSpecies.octopus));
      expect(withOctopus, hasLength(3));
      expect(withOctopus.toSet(), hasLength(3));
      expect(withOctopus, isNot(contains(MascotSpecies.octopus)));
    });

    test('the owner is Rùa the turtle; labels read "name · subject"', () {
      expect(SeaCafe.owner.species, MascotSpecies.turtle);
      expect(SeaCafe.owner.name, 'Rùa');
      expect(SeaCafe.seated(MascotSpecies.gret).first.label, 'Ẩn · Toán');
    });

    test('the café seats the friends for the mascot the student wears', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(cafeFriendsProvider).first.name, 'Ẩn');

      await GretCornerRepository().saveMascot(MascotSpecies.crab);
      container.invalidate(gretCornerProvider);
      expect(species(container.read(cafeFriendsProvider)), isNot(contains(MascotSpecies.crab)));
    });

    test('Ẩn and Mochi have the same names as in Góc của Gret', () {
      for (final friend in SeaCafe.roster) {
        if (friend.species == MascotSpecies.crab || friend.species == MascotSpecies.octopus) {
          expect(friend.name, GretCornerCatalog.mascotOf(friend.species).name);
        }
      }
    });
  });

  group('What the friends say (FR-006, FR-007)', () {
    final seated = SeaCafe.seated(MascotSpecies.gret);

    test('the owner greets when the session starts', () {
      expect(SeaCafe.lineFor(CafeMoment.started, seated: seated, count: 0).speaker, SeaCafe.owner);
    });

    test('other moments rotate between the seated friends', () {
      final speakers = [
        for (var count = 0; count < 3; count++)
          SeaCafe.lineFor(CafeMoment.returned, seated: seated, count: count).speaker,
      ];
      expect(speakers, seated);
    });

    test('every moment and every greeting has a line', () {
      for (final moment in CafeMoment.values) {
        for (var count = 0; count < 4; count++) {
          expect(SeaCafe.lineFor(moment, seated: seated, count: count).text, isNotEmpty);
        }
      }
      for (var greeting = 0; greeting < SeaCafe.greetings.length; greeting++) {
        final reply = SeaCafe.replyTo(greeting, seated: seated, count: greeting);
        expect(reply.text, isNotEmpty);
        expect(seated, contains(reply.speaker));
      }
    });

    CafeMoment? moment({
      int distractions = 0,
      bool onBreak = false,
      double progress = 0.2,
      int distractionsBefore = 0,
      bool onBreakBefore = false,
      double progressBefore = 0.2,
    }) => SeaCafe.momentAfter(
      distractionsBefore: distractionsBefore,
      distractionsNow: distractions,
      onBreakBefore: onBreakBefore,
      onBreakNow: onBreak,
      progressBefore: progressBefore,
      progressNow: progress,
    );

    test('session changes map to moments', () {
      expect(moment(), isNull);
      expect(moment(distractions: 1), CafeMoment.returned);
      expect(moment(onBreak: true), CafeMoment.breakStarted);
      expect(moment(onBreakBefore: true), CafeMoment.breakEnded);
      expect(moment(progressBefore: 0.49, progress: 0.5), CafeMoment.halfway);
      expect(moment(progressBefore: 0.5, progress: 0.6), isNull);
    });

    test('a distraction and a break in the same update give only the break line', () {
      expect(moment(distractions: 1, onBreak: true), CafeMoment.breakStarted);
      expect(moment(distractions: 1, progressBefore: 0.4, progress: 0.6), CafeMoment.returned);
    });

    test('greetings are open in the first minute and during breaks', () {
      expect(SeaCafe.greetingsOpen(onBreak: false, focused: const Duration(seconds: 59)), isTrue);
      expect(SeaCafe.greetingsOpen(onBreak: false, focused: const Duration(minutes: 1)), isFalse);
      expect(SeaCafe.greetingsOpen(onBreak: true, focused: const Duration(minutes: 20)), isTrue);
    });
  });

  group('Session place (FR-008)', () {
    final start = DateTime(2026, 3, 2, 9);
    Map<String, dynamic> oldSession() => {
      'id': 's1',
      'habitId': 'h1',
      'start': start.toIso8601String(),
      'end': null,
      'plannedMinutes': 25,
      'focusedSeconds': 1500,
      'distractionCount': 0,
    };

    test('sessions saved before the café read as studied in the sea', () {
      expect(Session.fromMap(oldSession()).place, StudyPlace.sea);
      expect(Session.fromMap({...oldSession(), 'place': 'moon'}).place, StudyPlace.sea);
    });

    test('the place survives a save and a read', () {
      final session = Session(
        id: 's2',
        habitId: 'h1',
        start: start,
        plannedMinutes: 25,
        focusedSeconds: 60,
        distractionCount: 0,
        place: StudyPlace.cafe,
      );

      expect(Session.fromMap(session.toMap()).place, StudyPlace.cafe);
    });
  });
}
