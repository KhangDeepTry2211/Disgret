// 5.3 Gret và biển sống: which SVG layers draw a mascot in a mood (spec 003 FR-020).
// Every layer shares one 240×200 canvas (AppMascot.canvasWidth/Height), so later features can
// slot outfit layers and other species in without touching the mood logic.
import '../../data/gret_corner_catalog.dart';
import '../../data/mascot_mood.dart';
import '../../data/mascot_species.dart';
import '../../l10n/app_strings.dart';

export '../../data/mascot_species.dart' show MascotSpecies;

class MascotLook {
  MascotLook._();

  /// Gret's tail, drawn behind everything so it can wag (spec 013).
  static const String gretTail = 'assets/mascot/gret/tail.svg';

  /// Moods whose eyes are open and can blink.
  static bool canBlink(MascotMood mood) => switch (mood) {
    MascotMood.happy || MascotMood.neutral || MascotMood.sad || MascotMood.focused => true,
    MascotMood.sleeping || MascotMood.celebrating => false,
  };

  /// Layers from back to front. The body comes from the species; the face (cheeks, eyes, mouth,
  /// z, sparkles) is shared with Gret, since every species keeps its face in the same place.
  /// [outfit] maps a slot to its drawing (spec 004 FR-002).
  static List<String> layers(
    MascotMood mood, {
    MascotSpecies species = MascotSpecies.gret,
    bool blinking = false,
    Map<OutfitSlot, String> outfit = const {},
  }) {
    final face = MascotSpecies.gret.folder;
    final eyes = blinking && canBlink(mood) ? 'blink' : mood.name;
    return [
      if (species == MascotSpecies.gret) gretTail,
      ?outfit[OutfitSlot.back],
      '${species.folder}/body.svg',
      ?outfit[OutfitSlot.body],
      ?outfit[OutfitSlot.neck],
      '$face/cheeks.svg',
      '$face/eyes_$eyes.svg',
      '$face/mouth_${mood.name}.svg',
      ?outfit[OutfitSlot.eyes],
      ?outfit[OutfitSlot.head],
      if (mood == MascotMood.sleeping) '$face/zzz.svg',
      if (mood == MascotMood.celebrating) '$face/sparkles.svg',
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
  };

  /// What Gret can say in this mood when tapped.
  static List<String> lines(MascotMood mood) => switch (mood) {
    MascotMood.happy => AppStrings.gretHappy,
    MascotMood.neutral => AppStrings.gretNeutral,
    MascotMood.sad => AppStrings.gretSad,
    MascotMood.focused => AppStrings.gretFocused,
    MascotMood.sleeping => AppStrings.gretSleeping,
    MascotMood.celebrating => AppStrings.gretCelebrating,
  };
}
