// 5.6 Quán San Hô: the café scene of the focus session (spec 006 FR-003–FR-005, FR-009). Gret sits
// at the front table, the owner stands at the counter, the friends study at their tables, and the
// windows look out on Gret's sea at its live clarity. Only shows what it is given: the moments and
// the bubbles are decided by CafeSessionView.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/gret_work.dart';
import '../../data/gret_corner_catalog.dart';
import '../../data/mascot_mood.dart';
import '../../data/mascot_species.dart';
import '../../data/sea_cafe.dart';
import '../../data/sea_time.dart';
import '../../l10n/app_strings.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../mascot/mascot_bubbles.dart';
import '../mascot/mascot_view.dart';
import '../motion/reaction_wiggle.dart';
import '../mascot/mascot_at_desk.dart';
import '../sea/sea_painter.dart';
import 'cafe_diorama_painter.dart';
import 'sea_cafe_painter.dart';

class SeaCafeScene extends ConsumerWidget {
  const SeaCafeScene({
    required this.clarity,
    required this.windowPlace,
    required this.look,
    required this.gretMood,
    required this.friendMood,
    required this.friends,
    this.line,
    this.gretLine,
    this.overlay,
    this.foreground,
    this.bottom,
    this.gretReaction = 0,
    this.work,
    this.cafeLook = CafeLook.cosy,
    super.key,
  });

  /// Sea clarity 0–100, seen through the windows.
  final double clarity;

  /// Which sea the windows look out on.
  final SeaPlace windowPlace;

  /// The student's mascot and outfit, at the front table.
  final GretLook look;
  final MascotMood gretMood;

  /// How the owner and the friends look (studying, cheering, on a break).
  final MascotMood friendMood;

  /// The friends at the tables, at most [AppCafe.seats] of them.
  final List<SeaFriend> friends;

  /// What the owner or a friend is saying now.
  final CafeLine? line;

  /// What Gret is saying now (a greeting).
  final String? gretLine;

  /// Hangs on the wall above everyone (the habit name and the countdown ring).
  final Widget? overlay;

  /// Fills the scene above the characters (the distraction swat effect).
  final Widget? foreground;

  /// Sits along the bottom edge (the greetings).
  final Widget? bottom;

  /// Gret wiggles once each time this number changes.
  final int gretReaction;

  /// During a session Gret works at a wooden desk at the front (spec 019); null keeps the table.
  final MascotWork? work;

  /// The cosy room or the isometric diorama room (spec 019).
  final CafeLook cafeLook;

  bool get _diorama => cafeLook == CafeLook.diorama;
  Alignment get _ownerAt => _diorama ? AppCafe.dioramaOwner : AppCafe.owner;
  List<Alignment> get _seatsAt => _diorama ? AppCafe.dioramaSeats : AppCafe.seats;
  Alignment get _gretAt => _diorama ? AppCafe.dioramaGret : AppCafe.gret;

  Alignment _speakerAt(SeaFriend speaker) {
    if (speaker == SeaCafe.owner) return _ownerAt;
    final seat = friends.indexOf(speaker);
    return seat < 0 || seat >= _seatsAt.length ? _gretAt : _seatsAt[seat];
  }

  static Alignment _lifted(Alignment at) =>
      Alignment(at.x, (at.y - AppCafe.bubbleLift).clamp(-1.0, 1.0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Day or night by the clock, like the sea outside (spec 013).
    final isNight = SeaTime.isNight(ref.watch(clockProvider)());
    final animationsOff = MediaQuery.disableAnimationsOf(context);
    final seated = friends.take(AppCafe.seats.length).toList();
    final names = [SeaCafe.owner.name, for (final friend in seated) friend.name];

    return Semantics(
      container: true,
      label: AppStrings.cafeSemantics(names),
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            // Everyone is a little smaller in the diorama room, which floats with a margin.
            final scale = _diorama ? AppCafe.dioramaScale : 1.0;
            final friendSize =
                (size.height * AppCafe.friendShare).clamp(AppCafe.friendMin, AppCafe.friendMax) *
                scale;
            final gretSize =
                (size.height * AppCafe.gretShare).clamp(AppCafe.gretMin, AppCafe.gretMax) * scale;

            Widget bubble(Alignment at, String? text) => Positioned.fill(
              child: AnimatedSwitcher(
                duration: animationsOff ? Duration.zero : AppMotion.reaction,
                child: text == null
                    ? const SizedBox.shrink()
                    : Align(
                        key: ValueKey(text),
                        alignment: _lifted(at),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: size.width * AppCafe.bubbleMaxShare,
                          ),
                          child: Semantics(liveRegion: true, child: SpeechBubble(text: text)),
                        ),
                      ),
              ),
            );

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _diorama
                        ? CafeDioramaPainter(isNight: isNight)
                        : SeaCafePainter(isNight: isNight),
                  ),
                ),
                if (!_diorama)
                  for (final at in AppCafe.hangingPlants)
                    Align(
                      alignment: at,
                      child: SvgPicture.asset(
                        'assets/scene/cafe_plant_hanging.svg',
                        height: size.height * AppCafe.hangingPlantShare,
                      ),
                    ),
                if (!_diorama)
                  for (final window in const [AppCafe.leftWindow, AppCafe.rightWindow])
                    _Window(
                      rect: Rect.fromLTWH(
                        window.left * size.width,
                        window.top * size.height,
                        window.width * size.width,
                        window.height * size.height,
                      ),
                      clarity: clarity,
                      place: windowPlace,
                      isNight: isNight,
                    ),
                Align(
                  alignment: _ownerAt,
                  child: _Seat(
                    friend: SeaCafe.owner,
                    mood: friendMood,
                    size: friendSize,
                    isNight: isNight,
                    atCounter: true,
                  ),
                ),
                for (var i = 0; i < seated.length; i++)
                  Align(
                    alignment: _seatsAt[i],
                    child: _Seat(
                      friend: seated[i],
                      mood: friendMood,
                      size: friendSize,
                      isNight: isNight,
                    ),
                  ),
                if (work != null)
                  Align(
                    alignment: _gretAt,
                    child: ReactionWiggle(
                      trigger: gretReaction,
                      child: MascotAtDesk(
                        mood: gretMood,
                        desk: work!.desk,
                        task: work!.task,
                        size: gretSize,
                        species: look.species,
                        outfit: look.outfit,
                      ),
                    ),
                  )
                else
                  Align(
                    alignment: _gretAt,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReactionWiggle(
                          trigger: gretReaction,
                          child: MascotView(
                            mood: gretMood,
                            size: gretSize,
                            species: look.species,
                            outfit: look.outfit,
                          ),
                        ),
                        _Table(
                          size: Size(
                            gretSize * AppCafe.gretTableScale,
                            gretSize * AppCafe.tableHeight,
                          ),
                          isNight: isNight,
                        ),
                      ],
                    ),
                  ),
                if (!_diorama)
                  for (final at in AppCafe.floorPlants)
                    Align(
                      alignment: at,
                      child: SvgPicture.asset(
                        'assets/scene/cafe_plant_pot.svg',
                        height: size.height * AppCafe.floorPlantShare,
                      ),
                    ),
                if (foreground != null) Positioned.fill(child: foreground!),
                if (overlay != null)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      // On the café wall, which follows the clock (spec 013).
                      child: Theme(
                        data: AppTheme.forSky(night: isNight),
                        child: overlay!,
                      ),
                    ),
                  ),
                bubble(line == null ? _gretAt : _speakerAt(line!.speaker), line?.text),
                bubble(_gretAt, gretLine),
                if (bottom != null) Align(alignment: Alignment.bottomCenter, child: bottom),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// An arched window looking out on Gret's sea (still: the café itself does not loop).
class _Window extends StatelessWidget {
  const _Window({
    required this.rect,
    required this.clarity,
    required this.place,
    required this.isNight,
  });

  final Rect rect;
  final double clarity;
  final SeaPlace place;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(top: Radius.circular(rect.width / 2));

    return Positioned.fromRect(
      rect: rect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: CustomPaint(
              painter: SeaPainter(
                loop: const AlwaysStoppedAnimation(0),
                clarity: clarity,
                isNight: isNight,
                place: place,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: isNight ? AppCafe.frameNight : AppCafe.frame,
                width: AppCafe.windowFrame,
              ),
            ),
          ),
          // Tied curtains (spec 019).
          Positioned.fill(
            child: SvgPicture.asset('assets/scene/cafe_curtains.svg', fit: BoxFit.fill),
          ),
        ],
      ),
    );
  }
}

/// The owner behind the counter, or a friend at a small table, with a "name · subject" label.
class _Seat extends StatelessWidget {
  const _Seat({
    required this.friend,
    required this.mood,
    required this.size,
    required this.isNight,
    this.atCounter = false,
  });

  final SeaFriend friend;
  final MascotMood mood;
  final bool atCounter;
  final bool isNight;

  /// Width of the character.
  final double size;

  /// What lies on a friend's table, by subject.
  static String _propOf(SeaFriend friend) => switch (friend.subject) {
    AppStrings.subjectMaths => 'cafe_maths',
    AppStrings.subjectLiterature => 'cafe_literature',
    AppStrings.subjectEnglish => 'cafe_english',
    _ => 'cafe_biology',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MascotSeated(
          mood: mood,
          species: friend.species,
          size: size,
          behind: atCounter ? const [] : const ['cafe_chair'],
          front: atCounter ? const ['cafe_counter'] : ['cafe_table', _propOf(friend), 'cafe_cup'],
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: AppRadius.pillBorder,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
            child: Text(friend.label, style: theme.textTheme.labelSmall, maxLines: 1),
          ),
        ),
      ],
    );
  }
}

/// A round café table seen from the front.
class _Table extends StatelessWidget {
  const _Table({required this.size, required this.isNight});

  final Size size;
  final bool isNight;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: isNight ? AppCafe.tableNight : AppCafe.table,
        borderRadius: BorderRadius.all(Radius.elliptical(size.width / 2, size.height / 2)),
      ),
    ),
  );
}
