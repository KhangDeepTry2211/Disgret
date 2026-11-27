// 5.3 Gret và biển sống: which SVG layers draw a mascot in a mood (spec 003 FR-020), in one of the
// three drawing styles (spec 018). Every layer shares one 240×200 canvas
// (AppMascot.canvasWidth/Height), so outfit layers and other species slot in without touching the
// mood logic.
import '../../data/gret_corner_catalog.dart';
import '../../data/mascot_mood.dart';
import '../../data/mascot_species.dart';
import '../../l10n/app_strings.dart';

export '../../data/mascot_species.dart' show MascotSpecies, MascotStyle;

class MascotLook {
  MascotLook._();

  /// Folder of a style's face layers and tail. The classic style keeps the first drawings, whose
  /// face layers live with Gret.
  static String folderOf(MascotStyle style) => switch (style) {
    MascotStyle.classic => 'assets/mascot/gret',
    MascotStyle.flat => 'assets/mascot/flat',
    MascotStyle.soft => 'assets/mascot/soft',
  };

  /// Gret's tail, drawn behind everything so it can wag (spec 013).
  static String tailOf(MascotStyle style) => '${folderOf(style)}/tail.svg';

  /// Whether [path] is a tail layer (it wags in MascotView).
  static bool isTail(String path) => path.endsWith('/tail.svg');

  /// The body drawing of [species] in [style].
  static String bodyOf(MascotSpecies species, MascotStyle style) => style == MascotStyle.classic
      ? '${species.folder}/body.svg'
      : '${folderOf(style)}/body_${species.name}.svg';

  /// Moods whose eyes are open and can blink.
  static bool canBlink(MascotMood mood) => switch (mood) {
    MascotMood.happy ||
    MascotMood.neutral ||
    MascotMood.sad ||
    MascotMood.focused ||
    MascotMood.surprised => true,
    MascotMood.sleeping ||
    MascotMood.celebrating ||
    MascotMood.love ||
    MascotMood.proud ||
    MascotMood.wink => false,
  };

  /// What floats around the mascot in a mood, if anything.
  static String? _extra(MascotMood mood) => switch (mood) {
    MascotMood.sleeping => 'zzz',
    MascotMood.celebrating => 'sparkles',
    MascotMood.love => 'hearts',
    MascotMood.proud => 'sparkle',
    MascotMood.surprised => 'burst',
    MascotMood.happy ||
    MascotMood.neutral ||
    MascotMood.sad ||
    MascotMood.focused ||
    MascotMood.wink => null,
  };

  /// Layers from back to front. The body comes from the species; the face (cheeks, eyes, mouth,
  /// extras) is shared by every species of a style, since each keeps its face in the same place.
  /// [outfit] maps a slot to its drawing (spec 004 FR-002).
  static List<String> layers(
    MascotMood mood, {
    MascotSpecies species = MascotSpecies.gret,
    MascotStyle style = MascotStyle.soft,
    bool blinking = false,
    Map<OutfitSlot, String> outfit = const {},
  }) {
    final face = folderOf(style);
    final eyes = blinking && canBlink(mood) ? 'blink' : mood.name;
    final extra = _extra(mood);
    return [
      if (species == MascotSpecies.gret) tailOf(style),
      ?outfit[OutfitSlot.back],
      bodyOf(species, style),
      ?outfit[OutfitSlot.body],
      ?outfit[OutfitSlot.neck],
      '$face/cheeks.svg',
      '$face/eyes_$eyes.svg',
      '$face/mouth_${mood.name}.svg',
      ?outfit[OutfitSlot.eyes],
      ?outfit[OutfitSlot.head],
      if (extra != null) '$face/$extra.svg',
    ];
  }

  /// Short Vietnamese description of the mood for screen readers.
  static String moodLabel(MascotMood mood) => switch (mood) {
    MascotMood.happy => AppStrings.moodHappy,
    MascotMood.neutral => AppStrings.moodNeutral,
    MascotMood.sad => AppStrings.moodSad,
    MascotMood.focused => AppStrings.moodFocused,
    MascotMood.sleeping => AppStrings.moodSleeping,
    MascotMood.celebrating => AppStrings.moodCelebrating,
    MascotMood.love => AppStrings.moodLove,
    MascotMood.surprised => AppStrings.moodSurprised,
    MascotMood.proud => AppStrings.moodProud,
    MascotMood.wink => AppStrings.moodWink,
  };

  /// What Gret can say in this mood when tapped.
  static List<String> lines(MascotMood mood) => switch (mood) {
    MascotMood.happy => AppStrings.gretHappy,
    MascotMood.neutral => AppStrings.gretNeutral,
    MascotMood.sad => AppStrings.gretSad,
    MascotMood.focused => AppStrings.gretFocused,
    MascotMood.sleeping => AppStrings.gretSleeping,
    MascotMood.celebrating => AppStrings.gretCelebrating,
    MascotMood.love => AppStrings.gretLove,
    MascotMood.surprised => AppStrings.gretSurprised,
    MascotMood.proud => AppStrings.gretProud,
    MascotMood.wink => AppStrings.gretWink,
  };
}
