// 5.4 Góc của Gret – lưu món đã có, món đang mặc, vùng biển và linh vật, nằm trong box hồ sơ
// (spec 004 FR-004). Pearls are never stored: they are computed from saved sessions.
import 'package:hive/hive.dart';

import '../gret_corner_catalog.dart';
import '../hive_boxes.dart';
import '../mascot_species.dart';
import '../sea_cafe.dart';

class GretCornerRepository {
  static const String _ownedKey = 'corner_owned';
  static const String _wornKey = 'corner_worn';
  static const String _seaKey = 'corner_sea';
  static const String _mascotKey = 'corner_mascot';
  static const String _styleKey = 'corner_mascot_style';
  static const String _decorKey = 'corner_decor';
  static const String _cafeLookKey = 'corner_cafe_look';

  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.profile);

  /// Ids of items and mascots obtained (with pearls; streak items need no record).
  Set<String> get owned =>
      ((_box.get(_ownedKey) as List<dynamic>?) ?? const []).cast<String>().toSet();

  /// Worn item id by slot. Unknown slots are ignored, so older or newer versions stay readable.
  Map<OutfitSlot, String> get worn {
    final raw = (_box.get(_wornKey) as Map<dynamic, dynamic>?) ?? const {};
    final slots = OutfitSlot.values.asNameMap();
    return {
      for (final entry in raw.entries)
        if (slots[entry.key] != null && entry.value is String)
          slots[entry.key]!: entry.value as String,
    };
  }

  SeaPlace get sea => SeaPlace.values.asNameMap()[_box.get(_seaKey)] ?? SeaPlace.home;

  MascotSpecies get mascot =>
      MascotSpecies.values.asNameMap()[_box.get(_mascotKey)] ?? MascotSpecies.gret;

  Future<void> saveOwned(Set<String> ids) => _box.put(_ownedKey, ids.toList());

  Future<void> saveWorn(Map<OutfitSlot, String> worn) =>
      _box.put(_wornKey, {for (final entry in worn.entries) entry.key.name: entry.value});

  Future<void> saveSea(SeaPlace place) => _box.put(_seaKey, place.name);

  Future<void> saveMascot(MascotSpecies species) => _box.put(_mascotKey, species.name);

  /// How every mascot is drawn (spec 018); unknown or missing reads as 3D mềm.
  MascotStyle get style => MascotStyle.values.asNameMap()[_box.get(_styleKey)] ?? MascotStyle.soft;

  Future<void> saveStyle(MascotStyle style) => _box.put(_styleKey, style.name);

  /// Placed decoration id by spot (spec 019). Unknown spots and ids are ignored.
  Map<DecorSpot, String> get decor {
    final raw = (_box.get(_decorKey) as Map<dynamic, dynamic>?) ?? const {};
    final spots = DecorSpot.values.asNameMap();
    return {
      for (final entry in raw.entries)
        if (spots[entry.key] != null &&
            GretCornerCatalog.decorationById('${entry.value}')?.spot == spots[entry.key])
          spots[entry.key]!: entry.value as String,
    };
  }

  /// How Quán San Hô is drawn (spec 019); unknown or missing reads as the cosy room.
  CafeLook get cafeLook => CafeLook.values.asNameMap()[_box.get(_cafeLookKey)] ?? CafeLook.cosy;

  Future<void> saveCafeLook(CafeLook look) => _box.put(_cafeLookKey, look.name);

  Future<void> saveDecor(Map<DecorSpot, String> decor) =>
      _box.put(_decorKey, {for (final entry in decor.entries) entry.key.name: entry.value});
}
