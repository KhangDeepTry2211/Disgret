// 5.3 Gret và biển sống: short emotes over Gret's mood (spec 018 user story 4). An emote shows
// for AppMotion.emote, then Gret goes back to the mood of the sea:
//   love      Gret tapped on Hôm nay
//   wink      every third tap, and once when Hôm nay opens in the morning
//   proud     back to studying from the intervention screen
//   surprised a habit reaches 7, 21, 40 or 66 done days
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/habit_science.dart';
import '../data/mascot_mood.dart';
import '../data/sea_map.dart';
import '../theme/app_theme.dart';
import 'app_providers.dart';

abstract final class GretEmotes {
  /// Morning greetings wink until this hour.
  static const int morningUntilHour = 11;
  static const int morningFromHour = 5;

  /// Whether some habit went from below a milestone (7, 21, 40, 66 days) to on or above it.
  static bool reachedMilestone(Map<String, int> before, Map<String, int> after) {
    for (final entry in after.entries) {
      final previous = before[entry.key];
      if (previous == null) continue;
      final from = SeaMap.stageFor(previous);
      final to = SeaMap.stageFor(entry.value);
      if (to.index > from.index && to.index >= JourneyStage.warmUp.index) return true;
    }
    return false;
  }
}

class GretEmoteNotifier extends Notifier<MascotMood?> {
  Timer? _timer;
  bool _greeted = false;

  @override
  MascotMood? build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen<Map<String, int>>(_doneDaysProvider, (before, after) {
      if (before != null && GretEmotes.reachedMilestone(before, after)) {
        show(MascotMood.surprised);
      }
    });
    return null;
  }

  /// Shows [mood] for AppMotion.emote, replacing any emote still showing.
  void show(MascotMood mood) {
    _timer?.cancel();
    state = mood;
    _timer = Timer(AppMotion.emote, () => state = null);
  }

  /// Winks once per app run when Hôm nay opens in the morning.
  void greet(DateTime now) {
    if (_greeted) return;
    _greeted = true;
    if (now.hour >= GretEmotes.morningFromHour && now.hour < GretEmotes.morningUntilHour) {
      show(MascotMood.wink);
    }
  }
}

final gretEmoteProvider = NotifierProvider<GretEmoteNotifier, MascotMood?>(GretEmoteNotifier.new);

/// Done days per habit, to notice a milestone.
final _doneDaysProvider = Provider<Map<String, int>>(
  (ref) => {
    for (final history in ref.watch(allHabitHistoriesProvider))
      history.habit.id: HabitScience.journeyDays(history),
  },
);
