// 5.3–5.4 The mascots that can swim in the sea. Each species has its own body drawing; the face
// layers (eyes, mouth, cheeks, z, sparkles) are shared with Gret on the 240×200 canvas, so a new
// species only needs a body (spec 004).

enum MascotSpecies {
  gret,
  crab,
  octopus,

  /// 5.6 Quán San Hô only (spec 006): the owner Rùa and the friend Sao. Not in Góc của Gret.
  turtle,
  starfish;

  /// Folder of the species' body drawing.
  String get folder => 'assets/mascot/$name';
}

/// Places the sea can show (spec 004 user story 2). The last four are bought with pearls and
/// appear as their own islands on the sea map (spec 014). Stored by name; new values go last.
enum SeaPlace { home, coral, ice, deep, kelp, volcano, sunken, sunset }
