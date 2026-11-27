// 5.4 Góc của Gret: pearls earned by studying and the catalog (spec 004 FR-001–FR-003, ADR-0009).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/gret_corner_catalog.dart';
import 'package:focus_app/data/mascot_species.dart';
import 'package:focus_app/data/models/session.dart';
import 'package:focus_app/data/pearls.dart';

Session _session(int focusedSeconds) => Session(
  id: 's$focusedSeconds',
  habitId: 'h1',
  start: DateTime(2026, 11, 23, 9),
  plannedMinutes: 25,
  focusedSeconds: focusedSeconds,
  distractionCount: 3,
);

void main() {
  group('Pearls', () {
    test('one pearl per 5 focused minutes of a session, rounded down', () {
      expect(Pearls.forSession(25 * 60), 5);
      expect(Pearls.forSession(12 * 60), 2);
      expect(Pearls.forSession(4 * 60 + 59), 0);
      expect(Pearls.forSession(-10), 0);
    });

    test('earned adds every session on its own (spec scenario 1: 25 + 12 minutes = 7)', () {
      expect(Pearls.earned([_session(25 * 60), _session(12 * 60)]), 7);
      expect(Pearls.earned(const []), 0);
    });

    test('distractions never cost pearls', () {
      final calm = _session(25 * 60);
      final distracted = Session(
        id: 'd',
        habitId: 'h1',
        start: DateTime(2026, 11, 23),
        plannedMinutes: 25,
        focusedSeconds: 25 * 60,
        distractionCount: 9,
      );
      expect(Pearls.earned([distracted]), Pearls.earned([calm]));
    });

    test('the balance is earned minus spent and never below zero', () {
      expect(Pearls.balance(earned: 50, spent: 20), 30);
      expect(Pearls.balance(earned: 10, spent: 40), 0);
    });
  });

  group('Catalog', () {
    test('ids are unique across outfits and mascots', () {
      final ids = [
        for (final item in GretCornerCatalog.items) item.id,
        for (final mascot in GretCornerCatalog.mascots) mascot.id,
      ];
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every outfit and mascot body has its drawing', () {
      for (final item in GretCornerCatalog.items) {
        expect(File(item.asset).existsSync(), isTrue, reason: item.asset);
      }
      for (final species in MascotSpecies.values) {
        expect(File('${species.folder}/body.svg').existsSync(), isTrue, reason: species.name);
      }
    });

    test(
      '10 outfits, 8 seas (4 bought with pearls, spec 014) and 8 mascots; premium only listed',
      () {
        expect(GretCornerCatalog.items, hasLength(10));
        expect(GretCornerCatalog.seas, hasLength(8));
        expect(GretCornerCatalog.mascots, hasLength(8));
        final premium = GretCornerCatalog.items.where((i) => i.unlock.kind == UnlockKind.premium);
        expect(premium, hasLength(2));
        // Mochi is earned by studying since spec 018; no mascot is sold.
        expect(
          GretCornerCatalog.mascots.where((m) => m.unlock.kind == UnlockKind.premium),
          isEmpty,
        );
      },
    );

    test('the home sea and Gret are free; seas open at streaks 3, 7 and 14', () {
      expect(GretCornerCatalog.seaOf(SeaPlace.home).unlock.kind, UnlockKind.free);
      expect(GretCornerCatalog.mascotOf(MascotSpecies.gret).unlock.kind, UnlockKind.free);
      expect(
        [
          for (final sea in GretCornerCatalog.seas)
            if (sea.unlock.kind == UnlockKind.streak) sea.unlock.amount,
        ],
        [3, 7, 14],
      );
    });

    test('unknown ids are not found', () {
      expect(GretCornerCatalog.itemById('nope'), isNull);
    });
  });
}
