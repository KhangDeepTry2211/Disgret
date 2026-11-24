// 5.6 Quán San Hô: who studies in the café with Gret and what they say at each moment of the
// session (spec 006 FR-005–FR-007, ADR-0011). Pure rules, no state: the café view counts the lines
// said so far and passes the count in, so speakers rotate and tests can predict every line.
import '../l10n/app_strings.dart';
import 'gret_corner_catalog.dart';
import 'mascot_species.dart';

/// One of Gret's sea friends: a character, never a real user.
class SeaFriend {
  const SeaFriend({required this.species, required this.name, required this.subject});

  final MascotSpecies species;
  final String name;

  /// What the friend studies (for the owner: their role).
  final String subject;

  String get label => '$name · $subject';
}

/// The moments the friends react to (FR-006).
enum CafeMoment { started, returned, breakStarted, breakEnded, halfway }

/// A line said in the café, shown in a speech bubble above its speaker.
class CafeLine {
  const CafeLine({required this.speaker, required this.text});

  final SeaFriend speaker;
  final String text;
}

abstract final class SeaCafe {
  /// The owner stands at the counter and greets the student when a session starts.
  static const SeaFriend owner = SeaFriend(
    species: MascotSpecies.turtle,
    name: AppStrings.cafeOwnerName,
    subject: AppStrings.cafeOwnerRole,
  );

  /// Friends in seating order; the first three the student is not wearing sit at the tables.
  /// Ẩn, Mochi and Gret keep their Góc của Gret names.
  static final List<SeaFriend> roster = [
    _fromCatalog(MascotSpecies.crab, AppStrings.subjectMaths),
    _fromCatalog(MascotSpecies.octopus, AppStrings.subjectLiterature),
    const SeaFriend(
      species: MascotSpecies.starfish,
      name: AppStrings.cafeStarfishName,
      subject: AppStrings.subjectEnglish,
    ),
    _fromCatalog(MascotSpecies.gret, AppStrings.subjectBiology),
  ];

  static const int tables = 3;

  /// Greetings are open while the student has focused less than this, and during breaks.
  static const Duration greetWindow = Duration(minutes: 1);

  static const List<String> greetings = AppStrings.cafeGreetings;

  static SeaFriend _fromCatalog(MascotSpecies species, String subject) =>
      SeaFriend(species: species, name: GretCornerCatalog.mascotOf(species).name, subject: subject);

  /// The friends at the tables: never the species the student is wearing.
  static List<SeaFriend> seated(MascotSpecies worn) =>
      roster.where((friend) => friend.species != worn).take(tables).toList();

  /// What is said at [moment]; [count] is the number of lines already said this session.
  static CafeLine lineFor(
    CafeMoment moment, {
    required List<SeaFriend> seated,
    required int count,
  }) {
    final variants = switch (moment) {
      CafeMoment.started => AppStrings.cafeStarted,
      CafeMoment.returned => AppStrings.cafeReturned,
      CafeMoment.breakStarted => AppStrings.cafeBreakStarted,
      CafeMoment.breakEnded => AppStrings.cafeBreakEnded,
      CafeMoment.halfway => AppStrings.cafeHalfway,
    };
    final speaker = moment == CafeMoment.started ? owner : seated[count % seated.length];
    return CafeLine(speaker: speaker, text: variants[count % variants.length]);
  }

  /// A friend's reply to the student's greeting number [greeting].
  static CafeLine replyTo(int greeting, {required List<SeaFriend> seated, required int count}) {
    final variants = AppStrings.cafeReplies[greeting];
    return CafeLine(
      speaker: seated[count % seated.length],
      text: variants[count % variants.length],
    );
  }

  /// The moment between two states of the session, if any. One update gives at most one line:
  /// a break starting or ending wins over a distraction, which wins over halfway.
  static CafeMoment? momentAfter({
    required int distractionsBefore,
    required int distractionsNow,
    required bool onBreakBefore,
    required bool onBreakNow,
    required double progressBefore,
    required double progressNow,
  }) {
    if (!onBreakBefore && onBreakNow) return CafeMoment.breakStarted;
    if (onBreakBefore && !onBreakNow) return CafeMoment.breakEnded;
    if (distractionsNow > distractionsBefore) return CafeMoment.returned;
    if (progressBefore < 0.5 && progressNow >= 0.5) return CafeMoment.halfway;
    return null;
  }

  static bool greetingsOpen({required bool onBreak, required Duration focused}) =>
      onBreak || focused < greetWindow;
}
