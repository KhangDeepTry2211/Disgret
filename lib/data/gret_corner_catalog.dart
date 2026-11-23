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
}

class Unlock {
  const Unlock._(this.kind, this.amount);

  const Unlock.free() : this._(UnlockKind.free, 0);
  const Unlock.pearls(int price) : this._(UnlockKind.pearls, price);
  const Unlock.streak(int days) : this._(UnlockKind.streak, days);
  const Unlock.premium() : this._(UnlockKind.premium, 0);

  final UnlockKind kind;

  /// Price in pearls, or streak days.
  final int amount;

  /// Pearls this costs (0 unless bought with pearls).
  int get price => kind == UnlockKind.pearls ? amount : 0;
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
}

class MascotInfo {
  const MascotInfo({required this.species, required this.name, required this.unlock});

  final MascotSpecies species;
  final String name;
  final Unlock unlock;

  /// Stored with the owned items, so it must not clash with an outfit id.
  String get id => 'mascot_${species.name}';
}

/// What the sea shows: which mascot swims, what it wears (drawings by slot) and which sea.
class GretLook {
  const GretLook({
    this.species = MascotSpecies.gret,
    this.outfit = const {},
    this.place = SeaPlace.home,
  });

  final MascotSpecies species;
  final Map<OutfitSlot, String> outfit;
  final SeaPlace place;
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
  ];

  static const List<MascotInfo> mascots = [
    MascotInfo(species: MascotSpecies.gret, name: 'Gret', unlock: Unlock.free()),
    MascotInfo(species: MascotSpecies.crab, name: 'Ẩn', unlock: Unlock.pearls(300)),
    MascotInfo(species: MascotSpecies.octopus, name: 'Mochi', unlock: Unlock.premium()),
  ];

  static CornerItem? itemById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  static SeaInfo seaOf(SeaPlace place) => seas.firstWhere((sea) => sea.place == place);

  static MascotInfo mascotOf(MascotSpecies species) =>
      mascots.firstWhere((mascot) => mascot.species == species);

  static MascotInfo? mascotById(String id) {
    for (final mascot in mascots) {
      if (mascot.id == id) return mascot;
    }
    return null;
  }
}
