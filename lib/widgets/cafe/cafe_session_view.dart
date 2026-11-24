// 5.6 Quán San Hô during a focus session (spec 006 FR-003, FR-006, FR-007): turns changes of the
// session into café moments, shows one speech bubble at a time and offers the ready-made greetings
// in the first minute and during breaks. Nothing is stored or sent.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/gret_corner_catalog.dart';
import '../../data/mascot_mood.dart';
import '../../data/sea_cafe.dart';
import '../../providers/focus_session_provider.dart';
import '../../providers/gret_corner_providers.dart';
import '../../providers/sea_cafe_providers.dart';
import '../../providers/sea_map_providers.dart';
import '../../providers/sea_providers.dart';
import '../../theme/app_theme.dart';
import '../sea/distraction_swat.dart';
import '../sticker_chip.dart';
import 'sea_cafe_scene.dart';

class CafeSessionView extends ConsumerStatefulWidget {
  const CafeSessionView({required this.session, required this.clock, super.key});

  final FocusSessionState session;

  /// The habit name and the countdown ring, hung on the café wall.
  final Widget clock;

  @override
  ConsumerState<CafeSessionView> createState() => _CafeSessionViewState();
}

class _CafeSessionViewState extends ConsumerState<CafeSessionView> {
  /// Lines said so far in this view; speakers and variants rotate with it.
  int _said = 0;
  CafeLine? _line;
  String? _gretLine;
  Timer? _lineTimer;
  int _swats = 0;

  bool _onBreak(FocusSessionState session) => session.breakRemaining != null;

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    // Only a session that has just started is greeted, not one reopened from the banner later.
    if (!_onBreak(session) && session.focused < SeaCafe.greetWindow) {
      _line = SeaCafe.lineFor(
        CafeMoment.started,
        seated: ref.read(cafeFriendsProvider),
        count: _said++,
      );
      _lineTimer = Timer(AppMotion.speechBubble, _clear);
    }
  }

  @override
  void didUpdateWidget(CafeSessionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.session;
    final now = widget.session;
    final moment = SeaCafe.momentAfter(
      distractionsBefore: before.distractionCount,
      distractionsNow: now.distractionCount,
      onBreakBefore: _onBreak(before),
      onBreakNow: _onBreak(now),
      progressBefore: before.progress,
      progressNow: now.progress,
    );
    if (moment != null) {
      _show(SeaCafe.lineFor(moment, seated: ref.read(cafeFriendsProvider), count: _said++));
    }
  }

  void _show(CafeLine line, {String? gretLine}) {
    _lineTimer?.cancel();
    _lineTimer = Timer(AppMotion.speechBubble, _clear);
    setState(() {
      _line = line;
      _gretLine = gretLine;
    });
  }

  void _clear() {
    if (!mounted) return;
    setState(() {
      _line = null;
      _gretLine = null;
    });
  }

  /// Gret says the greeting, then a friend replies once Gret's bubble is gone.
  void _greet(int greeting) {
    final reply = SeaCafe.replyTo(greeting, seated: ref.read(cafeFriendsProvider), count: _said++);
    _lineTimer?.cancel();
    _lineTimer = Timer(AppMotion.cafeReplyDelay, () {
      if (mounted) _show(reply);
    });
    setState(() {
      _line = null;
      _gretLine = SeaCafe.greetings[greeting];
    });
  }

  @override
  void dispose() {
    _lineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final onBreak = _onBreak(session);
    final sea = ref.watch(seaStateProvider);
    final look = ref.watch(gretLookProvider);
    final friends = ref.watch(cafeFriendsProvider);
    // The windows look out on the sea of the habit's goal region (spec 005 FR-005).
    final windowPlace = ref.watch(sessionSeaPlaceProvider) ?? look.place;
    final greetingsOpen = SeaCafe.greetingsOpen(onBreak: onBreak, focused: session.focused);

    return SeaCafeScene(
      clarity: sea.clarity,
      windowPlace: windowPlace,
      look: GretLook(species: look.species, outfit: look.outfit, place: windowPlace),
      gretMood: sea.mood,
      // The friends study calmly, and look up and smile when someone talks or during a break.
      friendMood: onBreak || _line != null ? MascotMood.happy : MascotMood.neutral,
      friends: friends,
      line: _line,
      gretLine: _gretLine,
      gretReaction: _swats,
      overlay: widget.clock,
      foreground: DistractionSwatLayer(
        active: !onBreak,
        distractions: session.distractionCount,
        onSwat: () => setState(() => _swats++),
      ),
      bottom: greetingsOpen ? _Greetings(onGreet: _greet) : null,
    );
  }
}

/// The ready-made greetings as a row of small sticker chips.
class _Greetings extends StatelessWidget {
  const _Greetings({required this.onGreet});

  final ValueChanged<int> onGreet;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < SeaCafe.greetings.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            StickerChip(
              label: SeaCafe.greetings[i],
              colour: AppCafe.greetingColours[i],
              selected: false,
              onSelected: (_) => onGreet(i),
            ),
          ],
        ],
      ),
    );
  }
}
