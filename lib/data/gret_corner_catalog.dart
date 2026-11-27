// 5.4 Góc của Gret: what can be worn, which seas and mascots exist, and how each one is unlocked
// (spec 004 FR-002, FR-003, ADR-0009). Pure data; names are UI text in Vietnamese, like the quiz.
import 'mascot_species.dart';

/// Where an outfit sits on the mascot. Drawn in this order, from back to front.
enum OutfitSlot { back, body, neck, eyes, head }

enum Rarity { common, rare, special }

enum UnlockKind {
  /// Always available.
  free,

  /// Spend [Unlock.amount] pearls.
  pearls,

  /// Opens when the best streak reaches [Unlock.amount] days; costs nothing.
  streak,

  /// Sold for real money later; listed as "Sắp có" and not obtainable in this version.
  premium,

  /// Earned by studying (spec 018): starts within 10 minutes after a habit's reminder.
  onTimeStarts,

  /// Earned by choosing "Quay lại học" on the intervention screen.
  interventionReturns,

  /// Earned by focused study, in hours.
  focusHours,

  /// Earned when one habit reaches [Unlock.amount] days done.
  habitDays,
}

class Unlock {
  const Unlock._(this.kind, this.amount);

  const Unlock.free() : this._(UnlockKind.free, 0);
  const Unlock.pearls(int price) : this._(UnlockKind.pearls, price);
  const Unlock.streak(int days) : this._(UnlockKind.streak, days);
  const Unlock.premium() : this._(UnlockKind.premium, 0);
  const Unlock.onTimeStarts(int times) : this._(UnlockKind.onTimeStarts, times);
  const Unlock.interventionReturns(int times) : this._(UnlockKind.interventionReturns, times);
  const Unlock.focusHours(int hours) : this._(UnlockKind.focusHours, hours);
  const Unlock.habitDays(int days) : this._(UnlockKind.habitDays, days);

  final UnlockKind kind;

  /// Price in pearls, streak days, or the goal of a study unlock.
  final int amount;

  /// Pearls this costs (0 unless bought with pearls).
  int get price => kind == UnlockKind.pearls ? amount : 0;

  /// Earned by studying (spec 018), see `StudyFacts`.
  bool get isStudy => switch (kind) {
    UnlockKind.onTimeStarts ||
    UnlockKind.interventionReturns ||
    UnlockKind.focusHours ||
    UnlockKind.habitDays => true,
    UnlockKind.free || UnlockKind.pearls || UnlockKind.streak || UnlockKind.premium => false,
  };
}

class CornerItem {
  const CornerItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.rarity,
    required this.unlock,
  });

  final String id;
  final String name;
  final OutfitSlot slot;
  final Rarity rarity;
  final Unlock unlock;

  /// The drawing, on the mascot's 240×200 canvas.
  String get asset => 'assets/mascot/outfits/$id.svg';
}

class SeaInfo {
  const SeaInfo({required this.place, required this.name, required this.unlock});

  final SeaPlace place;
  final String name;
  final Unlock unlock;

  /// Stored with the owned items when bought with pearls (spec 014).
  String get id => 'sea_${place.name}';
}

class MascotInfo {
  const MascotInfo({
    required this.species,
    required this.name,
    required this.unlock,
    this.kind = '',
  });

  final MascotSpecies species;
  final String name;
  final Unlock unlock;

  /// What kind of animal it is, shown under the name ("Cá ngựa").
  final String kind;

  /// Stored with the owned items, so it must not clash with an outfit id.
  String get id => 'mascot_${species.name}';
}

/// Where a decoration stands by Gret's home (spec 019): two spots on the rock ledge left of Gret,
/// one beside the shell house on the right. Stored by name; new values go last.
enum DecorSpot { leftBack, leftFront, byHouse }

/// A decoration for Gret's home, bought with pearls and placed in its spot (spec 019).
class DecorationInfo {
  const DecorationInfo({
    required this.id,
    required this.name,
    required this.spot,
    required this.unlock,
  });

  final String id;
  final String name;
  final DecorSpot spot;
  final Unlock unlock;

  /// The drawing, on an 80×80 canvas standing at y 76 (assets/scene, scene_art.py).
  String get asset => 'assets/scene/$id.svg';
}

/// What the sea shows: which mascot swims, what it wears (drawings by slot), which sea, and the
/// decorations by Gret's home (drawings by spot, spec 019).
class GretLook {
  const GretLook({
    this.species = MascotSpecies.gret,
    this.outfit = const {},
    this.place = SeaPlace.home,
    this.decor = const {},
  });

  final MascotSpecies species;
  final Map<OutfitSlot, String> outfit;
  final SeaPlace place;
  final Map<DecorSpot, String> decor;
}

class GretCornerCatalog {
  GretCornerCatalog._();

  static const List<CornerItem> items = [
    CornerItem(
      id: 'pink_bow',
      name: 'Nơ hồng',
      slot: OutfitSlot.head,
      rarity: Rarity.common,
      unlock: Unlock.pearls(20),
    ),
    CornerItem(
      id: 'goggles',
      name: 'Kính bơi',
      slot: OutfitSlot.eyes,
      rarity: Rarity.common,
      unlock: Unlock.pearls(30),
    ),
    CornerItem(
      id: 'coral_scarf',
      name: 'Khăn san hô',
      slot: OutfitSlot.neck,
      rarity: Rarity.common,
      unlock: Unlock.pearls(30),
    ),
    CornerItem(
      id: 'sailor_hat',
      name: 'Mũ thuỷ thủ',
      slot: OutfitSlot.head,
      rarity: Rarity.common,
      unlock: Unlock.pearls(40),
    ),
    CornerItem(
      id: 'headphones',
      name: 'Tai nghe',
      slot: OutfitSlot.head,
      rarity: Rarity.rare,
      unlock: Unlock.pearls(80),
    ),
    CornerItem(
      id: 'life_vest',
      name: 'Áo phao',
      slot: OutfitSlot.body,
      rarity: Rarity.rare,
      unlock: Unlock.pearls(120),
    ),
    CornerItem(
      id: 'sunglasses',
      name: 'Kính râm',
      slot: OutfitSlot.eyes,
      rarity: Rarity.rare,
      unlock: Unlock.streak(3),
    ),
    CornerItem(
      id: 'coral_crown',
      name: 'Vương miện san hô',
      slot: OutfitSlot.head,
      rarity: Rarity.special,
      unlock: Unlock.streak(7),
    ),
    CornerItem(
      id: 'wizard_hat',
      name: 'Mũ phù thuỷ',
      slot: OutfitSlot.head,
      rarity: Rarity.special,
      unlock: Unlock.premium(),
    ),
    CornerItem(
      id: 'hero_cape',
      name: 'Áo choàng anh hùng',
      slot: OutfitSlot.back,
      rarity: Rarity.special,
      unlock: Unlock.premium(),
    ),
  ];

  static const List<SeaInfo> seas = [
    SeaInfo(place: SeaPlace.home, name: 'Biển nhà', unlock: Unlock.free()),
    SeaInfo(place: SeaPlace.coral, name: 'Rạn san hô', unlock: Unlock.streak(3)),
    SeaInfo(place: SeaPlace.ice, name: 'Biển băng', unlock: Unlock.streak(7)),
    SeaInfo(place: SeaPlace.deep, name: 'Đáy biển sâu', unlock: Unlock.streak(14)),
    // Bought with pearls, each an island on the sea map once bought (spec 014).
    SeaInfo(place: SeaPlace.kelp, name: 'Rừng tảo bẹ', unlock: Unlock.pearls(150)),
    SeaInfo(place: SeaPlace.volcano, name: 'Núi lửa ngầm', unlock: Unlock.pearls(200)),
    SeaInfo(place: SeaPlace.sunken, name: 'Thành phố chìm', unlock: Unlock.pearls(250)),
    SeaInfo(place: SeaPlace.sunset, name: 'Vịnh hoàng hôn', unlock: Unlock.pearls(300)),
  ];

  static const List<MascotInfo> mascots = [
    MascotInfo(species: MascotSpecies.gret, name: 'Gret', kind: 'Cá', unlock: Unlock.free()),
    MascotInfo(
      species: MascotSpecies.crab,
      name: 'Bơ',
      kind: 'Cua ẩn sĩ',
      unlock: Unlock.pearls(300),
    ),
    // Friends earned by studying (spec 018).
    MascotInfo(
      species: MascotSpecies.seahorse,
      name: 'Tép',
      kind: 'Cá ngựa',
      unlock: Unlock.onTimeStarts(5),
    ),
    MascotInfo(
      species: MascotSpecies.pufferfish,
      name: 'Phồng',
      kind: 'Cá nóc',
      unlock: Unlock.interventionReturns(5),
    ),
    MascotInfo(
      species: MascotSpecies.jellyfish,
      name: 'Mây',
      kind: 'Sứa',
      unlock: Unlock.focusHours(10),
    ),
    MascotInfo(
      species: MascotSpecies.octopus,
      name: 'Mochi',
      kind: 'Bạch tuộc',
      unlock: Unlock.focusHours(30),
    ),
    MascotInfo(
      species: MascotSpecies.penguin,
      name: 'Bông',
      kind: 'Cánh cụt',
      unlock: Unlock.habitDays(21),
    ),
    MascotInfo(
      species: MascotSpecies.whale,
      name: 'Bự',
      kind: 'Cá voi',
      unlock: Unlock.habitDays(66),
    ),
  ];

  /// Decorations for Gret's home (spec 019), two per spot.
  static const List<DecorationInfo> decorations = [
    DecorationInfo(
      id: 'deco_jelly_lantern',
      name: 'Đèn lồng sứa',
      spot: DecorSpot.leftBack,
      unlock: Unlock.pearls(40),
    ),
    DecorationInfo(
      id: 'deco_coral_garden',
      name: 'Vườn san hô mini',
      spot: DecorSpot.leftBack,
      unlock: Unlock.pearls(100),
    ),
    DecorationInfo(
      id: 'deco_sand_castle',
      name: 'Lâu đài cát',
      spot: DecorSpot.leftFront,
      unlock: Unlock.pearls(60),
    ),
    DecorationInfo(
      id: 'deco_kelp_swing',
      name: 'Xích đu rong',
      spot: DecorSpot.leftFront,
      unlock: Unlock.pearls(80),
    ),
    DecorationInfo(
      id: 'deco_mailbox',
      name: 'Hộp thư san hô',
      spot: DecorSpot.byHouse,
      unlock: Unlock.pearls(60),
    ),
    DecorationInfo(
      id: 'deco_treasure_chest',
      name: 'Rương báu vàng',
      spot: DecorSpot.byHouse,
      unlock: Unlock.pearls(150),
    ),
  ];

  static DecorationInfo? decorationById(String id) {
    for (final decoration in decorations) {
      if (decoration.id == id) return decoration;
    }
    return null;
  }

  static CornerItem? itemById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  static SeaInfo seaOf(SeaPlace place) => seas.firstWhere((sea) => sea.place == place);

  static SeaInfo? seaById(String id) {
    for (final sea in seas) {
      if (sea.id == id) return sea;
    }
    return null;
  }

  /// The pearl seas among [owned] ids, in catalog order (spec 014).
  static List<SeaPlace> boughtSeas(Set<String> owned) => [
    for (final sea in seas)
      if (sea.unlock.kind == UnlockKind.pearls && owned.contains(sea.id)) sea.place,
  ];

  static MascotInfo mascotOf(MascotSpecies species) =>
      mascots.firstWhere((mascot) => mascot.species == species);

  static MascotInfo? mascotById(String id) {
    for (final mascot in mascots) {
      if (mascot.id == id) return mascot;
    }
    return null;
  }
}
