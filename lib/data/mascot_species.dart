// 5.3–5.4 The mascots that can swim in the sea. Each species has its own body drawing; the face
// layers (eyes, mouth, cheeks, z, sparkles) are shared by every species of a drawing style on the
// 240×200 canvas, so a new species only needs a body (spec 004, spec 018).

enum MascotSpecies {
  gret,
  crab,
  octopus,

  /// 5.6 Quán San Hô only (spec 006): the owner Rùa and the friend Sao. Not in Góc của Gret.
  turtle,
  starfish,

  /// Friends earned by studying (spec 018). Stored by name; new values go last.
  seahorse,
  pufferfish,
  jellyfish,
  penguin,
  whale;

  /// Folder of the species' body drawing in the classic style.
  String get folder => 'assets/mascot/$name';
}

/// How every mascot is drawn, chosen in Góc của Gret (spec 018). [soft] is the default.
enum MascotStyle {
  /// The first drawings: flat fills, big eyes, no outline.
  classic,

  /// Chibi with a warm dark-brown outline, flat fills and bead eyes.
  flat,

  /// The same chibi shapes with soft 3D shading, a tonal outline and glossy bean eyes.
  soft,
}

/// Places the sea can show (spec 004 user story 2). The last four are bought with pearls and
/// appear as their own islands on the sea map (spec 014). Stored by name; new values go last.
enum SeaPlace { home, coral, ice, deep, kelp, volcano, sunken, sunset }
