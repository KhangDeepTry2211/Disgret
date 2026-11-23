// 5.4 Góc của Gret: pearls, unlock rules and the user's choices (spec 004, ADR-0009). Widgets read
// these providers only; the rules live in lib/data (pearls.dart, gret_corner_catalog.dart).
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/gret_corner_catalog.dart';
import '../data/habit_science.dart';
import '../data/mascot_species.dart';
import '../data/models/session.dart';
import '../data/pearls.dart';
import '../data/repositories/gret_corner_repository.dart';
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
}

@immutable
class GretCornerState {
  const GretCornerState({
    this.owned = const {},
    this.worn = const {},
    this.sea = SeaPlace.home,
    this.mascot = MascotSpecies.gret,
  });

  final Set<String> owned;
  final Map<OutfitSlot, String> worn;
  final SeaPlace sea;
  final MascotSpecies mascot;

  /// Pearls spent on owned items and mascots.
  int get spent {
    var total = 0;
    for (final id in owned) {
      total += GretCornerCatalog.itemById(id)?.unlock.price ?? 0;
      total += GretCornerCatalog.mascotById(id)?.unlock.price ?? 0;
    }
    return total;
  }

  GretCornerState copyWith({
    Set<String>? owned,
    Map<OutfitSlot, String>? worn,
    SeaPlace? sea,
    MascotSpecies? mascot,
  }) => GretCornerState(
    owned: owned ?? this.owned,
    worn: worn ?? this.worn,
    sea: sea ?? this.sea,
    mascot: mascot ?? this.mascot,
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
    );
  }

  /// Same as [pearlBalanceProvider], computed here because that provider depends on this one.
  int get _balance => Pearls.balance(earned: ref.read(pearlsEarnedProvider), spent: state.spent);
  int get _bestStreak => ref.read(bestStreakProvider);

  /// Whether [unlock] is usable now, and if not, why.
  CornerLock lockOf(Unlock unlock, {required String id}) =>
      _lockOf(unlock, id: id, state: state, balance: _balance, bestStreak: _bestStreak);

  /// Spends pearls on an item or a mascot. Returns false when it is not allowed.
  Future<bool> obtain(String id) async {
    final unlock =
        GretCornerCatalog.itemById(id)?.unlock ?? GretCornerCatalog.mascotById(id)?.unlock;
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
    if (lockOf(info.unlock, id: 'sea_${place.name}') != CornerLock.none) return false;
    state = state.copyWith(sea: place);
    await _repository.saveSea(place);
    return true;
  }

  /// Chooses the mascot. Returns false when it is not obtained yet.
  Future<bool> chooseMascot(MascotSpecies species) async {
    final info = GretCornerCatalog.mascotOf(species);
    if (lockOf(info.unlock, id: info.id) != CornerLock.none) return false;
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
}) => switch (unlock.kind) {
  UnlockKind.free => CornerLock.none,
  UnlockKind.pearls => state.owned.contains(id) ? CornerLock.none : CornerLock.pearls,
  UnlockKind.streak => bestStreak >= unlock.amount ? CornerLock.none : CornerLock.streak,
  UnlockKind.premium => CornerLock.premium,
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
    outfit: isGret
        ? {
            for (final entry in corner.worn.entries)
              entry.key: GretCornerCatalog.itemById(entry.value)!.asset,
          }
        : const {},
  );
});
