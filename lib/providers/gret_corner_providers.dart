// 5.4 Góc của Gret: pearls, unlock rules and the user's choices (spec 004, ADR-0009). Widgets read
// these providers only; the rules live in lib/data (pearls.dart, gret_corner_catalog.dart).
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/gret_corner_catalog.dart';
import '../data/habit_science.dart';
import '../data/mascot_species.dart';
import '../data/models/session.dart';
import '../data/models/event.dart';
import '../data/pearls.dart';
import '../data/sea_cafe.dart';
import '../data/repositories/gret_corner_repository.dart';
import '../data/study_unlocks.dart';
import 'app_providers.dart';

final gretCornerRepositoryProvider = Provider((ref) => GretCornerRepository());

/// Pearls earned by all saved sessions. Re-read when habit logs change: saving a session also
/// records its focus log.
final pearlsEarnedProvider = Provider<int>((ref) {
  ref.watch(habitLogsProvider);
  return Pearls.earned(_readSessions(ref));
});

List<Session> _readSessions(Ref ref) {
  try {
    return ref.read(sessionRepositoryProvider).getAll();
  } on Object catch (error) {
    debugPrint('Góc của Gret: sessions unreadable, counting no pearls ($error)');
    return const [];
  }
}

/// What the friends earned by studying count (spec 018). Re-read when habit logs change: saving a
/// session records its focus log, and a return from the intervention ends in a saved session.
final studyFactsProvider = Provider<StudyFacts>((ref) {
  ref.watch(habitLogsProvider);
  return StudyFacts.from(
    sessions: _readSessions(ref),
    habits: ref.watch(allHabitsProvider),
    events: _readEvents(ref),
    histories: ref.watch(allHabitHistoriesProvider),
  );
});

List<Event> _readEvents(Ref ref) {
  try {
    return ref.read(eventRepositoryProvider).getAll();
  } on Object catch (error) {
    debugPrint('Góc của Gret: events unreadable, counting no returns ($error)');
    return const [];
  }
}

/// The best streak ever reached, so a broken streak never locks anything again.
final bestStreakProvider = Provider<int>((ref) {
  final today = ref.watch(todayProvider);
  final longest = ref
      .watch(allHabitHistoriesProvider)
      .map((history) => HabitScience.longestStreak(history, today))
      .fold(0, math.max);
  return math.max(longest, ref.watch(overallStreakProvider));
});

/// Why an item cannot be used yet.
enum CornerLock {
  /// Usable now.
  none,

  /// Needs more pearls.
  pearls,

  /// Needs a longer streak.
  streak,

  /// Sold for real money later.
  premium,

  /// Earned by studying more (spec 018).
  study,
}

@immutable
class GretCornerState {
  const GretCornerState({
    this.owned = const {},
    this.worn = const {},
    this.sea = SeaPlace.home,
    this.mascot = MascotSpecies.gret,
    this.style = MascotStyle.soft,
    this.decor = const {},
    this.cafeLook = CafeLook.cosy,
  });

  final Set<String> owned;
  final Map<OutfitSlot, String> worn;
  final SeaPlace sea;
  final MascotSpecies mascot;

  /// How every mascot is drawn (spec 018).
  final MascotStyle style;

  /// Decorations placed by Gret's home, by spot (spec 019).
  final Map<DecorSpot, String> decor;

  /// How Quán San Hô is drawn (spec 019).
  final CafeLook cafeLook;

  /// Pearls spent on owned items, mascots and seas.
  int get spent {
    var total = 0;
    for (final id in owned) {
      total += GretCornerCatalog.itemById(id)?.unlock.price ?? 0;
      total += GretCornerCatalog.mascotById(id)?.unlock.price ?? 0;
      total += GretCornerCatalog.seaById(id)?.unlock.price ?? 0;
      total += GretCornerCatalog.decorationById(id)?.unlock.price ?? 0;
    }
    return total;
  }

  GretCornerState copyWith({
    Set<String>? owned,
    Map<OutfitSlot, String>? worn,
    SeaPlace? sea,
    MascotSpecies? mascot,
    MascotStyle? style,
    Map<DecorSpot, String>? decor,
    CafeLook? cafeLook,
  }) => GretCornerState(
    owned: owned ?? this.owned,
    worn: worn ?? this.worn,
    sea: sea ?? this.sea,
    mascot: mascot ?? this.mascot,
    style: style ?? this.style,
    decor: decor ?? this.decor,
    cafeLook: cafeLook ?? this.cafeLook,
  );
}

/// The user's choices in Góc của Gret. Every action checks the unlock rule again, so a stale
/// screen cannot spend pearls twice or wear a locked item.
class GretCornerNotifier extends Notifier<GretCornerState> {
  GretCornerRepository get _repository => ref.read(gretCornerRepositoryProvider);

  @override
  GretCornerState build() {
    final repository = ref.watch(gretCornerRepositoryProvider);
    return GretCornerState(
      owned: repository.owned,
      // Items removed from the catalog are dropped.
      worn: {
        for (final entry in repository.worn.entries)
          if (GretCornerCatalog.itemById(entry.value)?.slot == entry.key) entry.key: entry.value,
      },
      sea: repository.sea,
      mascot: repository.mascot,
      style: repository.style,
      decor: repository.decor,
      cafeLook: repository.cafeLook,
    );
  }

  /// Same as [pearlBalanceProvider], computed here because that provider depends on this one.
  int get _balance => Pearls.balance(earned: ref.read(pearlsEarnedProvider), spent: state.spent);
  int get _bestStreak => ref.read(bestStreakProvider);

  /// Whether [unlock] is usable now, and if not, why.
  CornerLock lockOf(Unlock unlock, {required String id}) => _lockOf(
    unlock,
    id: id,
    state: state,
    balance: _balance,
    bestStreak: _bestStreak,
    facts: ref.read(studyFactsProvider),
  );

  /// Spends pearls on an item, a mascot or a sea. Returns false when it is not allowed.
  Future<bool> obtain(String id) async {
    final unlock =
        GretCornerCatalog.itemById(id)?.unlock ??
        GretCornerCatalog.mascotById(id)?.unlock ??
        GretCornerCatalog.seaById(id)?.unlock ??
        GretCornerCatalog.decorationById(id)?.unlock;
    if (unlock == null || unlock.kind != UnlockKind.pearls || state.owned.contains(id)) {
      return false;
    }
    if (_balance < unlock.price) return false;
    final owned = {...state.owned, id};
    state = state.copyWith(owned: owned);
    await _repository.saveOwned(owned);
    return true;
  }

  /// Wears an item (replacing the one in its slot). Returns false when it is locked.
  Future<bool> wear(String id) async {
    final item = GretCornerCatalog.itemById(id);
    if (item == null || lockOf(item.unlock, id: id) != CornerLock.none) return false;
    final worn = {...state.worn, item.slot: id};
    state = state.copyWith(worn: worn);
    await _repository.saveWorn(worn);
    return true;
  }

  Future<void> takeOff(OutfitSlot slot) async {
    final worn = {...state.worn}..remove(slot);
    state = state.copyWith(worn: worn);
    await _repository.saveWorn(worn);
  }

  /// Chooses the sea. Returns false when the sea is still locked.
  Future<bool> chooseSea(SeaPlace place) async {
    final info = GretCornerCatalog.seaOf(place);
    if (lockOf(info.unlock, id: info.id) != CornerLock.none) return false;
    state = state.copyWith(sea: place);
    await _repository.saveSea(place);
    return true;
  }

  /// Places a bought decoration in its spot by Gret's home, replacing the one there (spec 019).
  /// Returns false when it is not bought.
  Future<bool> placeDecoration(String id) async {
    final decoration = GretCornerCatalog.decorationById(id);
    if (decoration == null || lockOf(decoration.unlock, id: id) != CornerLock.none) return false;
    final decor = {...state.decor, decoration.spot: id};
    state = state.copyWith(decor: decor);
    await _repository.saveDecor(decor);
    return true;
  }

  /// Puts away the decoration in [spot].
  Future<void> removeDecoration(DecorSpot spot) async {
    final decor = {...state.decor}..remove(spot);
    state = state.copyWith(decor: decor);
    await _repository.saveDecor(decor);
  }

  /// Draws Quán San Hô as [look] (spec 019); always allowed.
  Future<void> chooseCafeLook(CafeLook look) async {
    state = state.copyWith(cafeLook: look);
    await _repository.saveCafeLook(look);
  }

  /// Draws every mascot in [style] (spec 018); always allowed.
  Future<void> chooseStyle(MascotStyle style) async {
    state = state.copyWith(style: style);
    await _repository.saveStyle(style);
  }

  /// Chooses the mascot. Returns false when it is not obtained yet. A friend earned by studying
  /// is kept once chosen, even if its progress later goes down (a habit day unticked).
  Future<bool> chooseMascot(MascotSpecies species) async {
    final info = GretCornerCatalog.mascotOf(species);
    if (lockOf(info.unlock, id: info.id) != CornerLock.none) return false;
    if (info.unlock.isStudy && !state.owned.contains(info.id)) {
      final owned = {...state.owned, info.id};
      state = state.copyWith(owned: owned);
      await _repository.saveOwned(owned);
    }
    state = state.copyWith(mascot: species);
    await _repository.saveMascot(species);
    return true;
  }
}

CornerLock _lockOf(
  Unlock unlock, {
  required String id,
  required GretCornerState state,
  required int balance,
  required int bestStreak,
  required StudyFacts facts,
}) => switch (unlock.kind) {
  UnlockKind.free => CornerLock.none,
  UnlockKind.pearls => state.owned.contains(id) ? CornerLock.none : CornerLock.pearls,
  UnlockKind.streak => bestStreak >= unlock.amount ? CornerLock.none : CornerLock.streak,
  UnlockKind.premium => CornerLock.premium,
  UnlockKind.onTimeStarts ||
  UnlockKind.interventionReturns ||
  UnlockKind.focusHours ||
  UnlockKind.habitDays =>
    state.owned.contains(id) || facts.reached(unlock) ? CornerLock.none : CornerLock.study,
};

final gretCornerProvider = NotifierProvider<GretCornerNotifier, GretCornerState>(
  GretCornerNotifier.new,
);

/// Pearls the user can spend.
final pearlBalanceProvider = Provider<int>(
  (ref) => Pearls.balance(
    earned: ref.watch(pearlsEarnedProvider),
    spent: ref.watch(gretCornerProvider).spent,
  ),
);

/// What the sea shows on Hôm nay and in the focus session. Outfits are drawn on Gret only.
final gretLookProvider = Provider<GretLook>((ref) {
  final corner = ref.watch(gretCornerProvider);
  final isGret = corner.mascot == MascotSpecies.gret;
  return GretLook(
    species: corner.mascot,
    place: corner.sea,
    decor: {
      for (final entry in corner.decor.entries)
        entry.key: GretCornerCatalog.decorationById(entry.value)!.asset,
    },
    outfit: isGret
        ? {
            for (final entry in corner.worn.entries)
              entry.key: GretCornerCatalog.itemById(entry.value)!.asset,
          }
        : const {},
  );
});
