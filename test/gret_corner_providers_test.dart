// 5.4 Góc của Gret: pearls from sessions, obtaining and wearing items, seas and mascots
// (spec 004 user stories 1–3, FR-001–FR-004).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/gret_corner_catalog.dart';
import 'package:focus_app/data/mascot_species.dart';
import 'package:focus_app/data/models/habit.dart';
import 'package:focus_app/data/models/habit_log.dart';
import 'package:focus_app/data/models/session.dart';
import 'package:focus_app/data/repositories/gret_corner_repository.dart';
import 'package:focus_app/data/repositories/habit_log_repository.dart';
import 'package:focus_app/data/repositories/habit_repository.dart';
import 'package:focus_app/data/repositories/session_repository.dart';
import 'package:focus_app/providers/app_providers.dart';
import 'package:focus_app/providers/gret_corner_providers.dart';
import 'package:hive/hive.dart';

import 'test_helpers.dart';

void main() {
  late DateTime now;
  late ProviderContainer container;

  GretCornerNotifier corner() => container.read(gretCornerProvider.notifier);
  int balance() => container.read(pearlBalanceProvider);

  /// Saves sessions worth [minutes] focused minutes in total (one session each).
  Future<void> study(List<int> minutes) async {
    for (var i = 0; i < minutes.length; i++) {
      await SessionRepository().save(
        Session(
          id: 's${minutes.length}_$i',
          habitId: 'h1',
          start: now,
          plannedMinutes: 25,
          focusedSeconds: minutes[i] * 60,
          distractionCount: 1,
        ),
      );
    }
    container.invalidate(pearlsEarnedProvider);
  }

  /// Ticks a habit on [days] consecutive days ending today, so the streak reaches [days].
  Future<void> streakOf(int days) async {
    await HabitRepository().save(
      Habit(
        id: 'h1',
        goalId: 'g1',
        name: 'Ôn bài',
        minMinutesPerDay: 5,
        startDate: now.subtract(Duration(days: days + 1)),
      ),
    );
    for (var d = 0; d < days; d++) {
      final day = now.subtract(Duration(days: d));
      await HabitLogRepository().save(
        HabitLog(id: 'log$d', habitId: 'h1', date: day, minutes: 5, source: HabitLogSource.manual),
      );
    }
    container.invalidate(habitsProvider);
    container.invalidate(allHabitsProvider);
    container.invalidate(habitLogsProvider);
  }

  setUp(() async {
    await openMemoryBoxes();
    now = DateTime(2026, 11, 23, 9);
    container = ProviderContainer(overrides: [clockProvider.overrideWithValue(() => now)]);
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
  });

  test('a new user has no pearls, home sea, Gret and nothing worn', () {
    expect(balance(), 0);
    final state = container.read(gretCornerProvider);
    expect(state.sea, SeaPlace.home);
    expect(state.mascot, MascotSpecies.gret);
    expect(state.worn, isEmpty);
    expect(container.read(gretLookProvider).outfit, isEmpty);
  });

  test('pearls come from saved sessions (25 + 12 minutes = 7)', () async {
    await study([25, 12]);
    expect(balance(), 7);
  });

  test('obtaining an item spends pearls; not enough pearls changes nothing', () async {
    await study([100]); // 20 pearls

    expect(await corner().obtain('goggles'), isFalse, reason: '30 > 20');
    expect(balance(), 20);

    expect(await corner().obtain('pink_bow'), isTrue);
    expect(balance(), 0);
    expect(await corner().obtain('pink_bow'), isFalse, reason: 'Already owned');
    expect(GretCornerRepository().owned, {'pink_bow'});
  });

  test('wearing: one item per slot, shown in the look; taking off removes it', () async {
    await study([200, 200]); // 80 pearls
    await corner().obtain('pink_bow');
    await corner().obtain('sailor_hat');

    expect(await corner().wear('pink_bow'), isTrue);
    expect(await corner().wear('sailor_hat'), isTrue);
    expect(container.read(gretCornerProvider).worn, {OutfitSlot.head: 'sailor_hat'});
    expect(container.read(gretLookProvider).outfit, {
      OutfitSlot.head: 'assets/mascot/outfits/sailor_hat.svg',
    });

    await corner().takeOff(OutfitSlot.head);
    expect(container.read(gretLookProvider).outfit, isEmpty);
    expect(GretCornerRepository().worn, isEmpty);
  });

  test('items not obtained, streak items too early and premium items cannot be worn', () async {
    expect(await corner().wear('goggles'), isFalse);
    expect(await corner().wear('sunglasses'), isFalse, reason: 'Streak 3 needed');
    expect(await corner().wear('wizard_hat'), isFalse, reason: 'Premium: Sắp có');
    expect(await corner().obtain('wizard_hat'), isFalse, reason: 'Pearls never buy premium');
  });

  test('a 3-day streak opens the sunglasses and the coral reef, not the ice sea', () async {
    await streakOf(3);
    expect(container.read(bestStreakProvider), greaterThanOrEqualTo(3));

    expect(await corner().wear('sunglasses'), isTrue);
    expect(await corner().chooseSea(SeaPlace.coral), isTrue);
    expect(await corner().chooseSea(SeaPlace.ice), isFalse);
    expect(container.read(gretLookProvider).place, SeaPlace.coral);
    expect(GretCornerRepository().sea, SeaPlace.coral);
  });

  test('the crab costs 300 pearls; another mascot hides Gret\'s outfit', () async {
    await study([1500, 100]); // 300 + 20 pearls
    await corner().obtain('pink_bow');
    await corner().wear('pink_bow');

    expect(await corner().chooseMascot(MascotSpecies.crab), isFalse, reason: 'Not obtained');
    expect(await corner().obtain(GretCornerCatalog.mascotOf(MascotSpecies.crab).id), isTrue);
    expect(await corner().chooseMascot(MascotSpecies.crab), isTrue);

    final look = container.read(gretLookProvider);
    expect(look.species, MascotSpecies.crab);
    expect(look.outfit, isEmpty);
    expect(await corner().chooseMascot(MascotSpecies.octopus), isFalse, reason: '30 focus hours');
  });

  test('10 focus hours open Mây; Mochi waits for 30 (spec 018)', () async {
    await study([600]);
    MascotInfo of(MascotSpecies species) => GretCornerCatalog.mascotOf(species);

    expect(
      corner().lockOf(of(MascotSpecies.octopus).unlock, id: 'mascot_octopus'),
      CornerLock.study,
    );
    expect(await corner().chooseMascot(MascotSpecies.octopus), isFalse);
    expect(await corner().chooseMascot(MascotSpecies.jellyfish), isTrue);
    expect(container.read(gretLookProvider).species, MascotSpecies.jellyfish);
  });

  test('a chosen study friend stays open when its progress dips (spec 018)', () async {
    await streakOf(21);
    expect(await corner().chooseMascot(MascotSpecies.whale), isFalse, reason: 'Needs 66 days');
    expect(await corner().chooseMascot(MascotSpecies.penguin), isTrue);
    expect(container.read(gretCornerProvider).owned, contains('mascot_penguin'));

    await HabitLogRepository().delete('log0');
    container.invalidate(habitLogsProvider);
    final penguin = GretCornerCatalog.mascotOf(MascotSpecies.penguin);
    expect(container.read(studyFactsProvider).bestHabitDays, 20);
    expect(corner().lockOf(penguin.unlock, id: penguin.id), CornerLock.none);
    expect(await corner().chooseMascot(MascotSpecies.gret), isTrue);
    expect(await corner().chooseMascot(MascotSpecies.penguin), isTrue);
  });

  test('earned friends cost no pearls', () async {
    await study([600]);
    await corner().chooseMascot(MascotSpecies.jellyfish);
    expect(container.read(gretCornerProvider).spent, 0);
  });

  test('choices survive a restart; unknown stored ids are ignored', () async {
    await study([200]);
    await corner().obtain('pink_bow');
    await corner().wear('pink_bow');
    await Hive.box<dynamic>('profile').put('corner_worn', {'head': 'pink_bow', 'tail': 'x'});

    final fresh = ProviderContainer(overrides: [clockProvider.overrideWithValue(() => now)]);
    addTearDown(fresh.dispose);
    expect(fresh.read(gretCornerProvider).worn, {OutfitSlot.head: 'pink_bow'});
    expect(fresh.read(gretCornerProvider).owned, {'pink_bow'});
  });

  test('deleted sessions never make the balance negative', () async {
    await study([200]); // 40 pearls
    await corner().obtain('sailor_hat');
    for (final session in SessionRepository().getAll()) {
      await SessionRepository().delete(session.id);
    }
    container.invalidate(pearlsEarnedProvider);

    expect(balance(), 0);
    expect(container.read(gretCornerProvider).owned, {'sailor_hat'});
  });
}
