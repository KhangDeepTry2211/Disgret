// 5.6 Quán San Hô: the chosen study place and who sits in the café (spec 006).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/study_place_repository.dart';
import '../data/sea_cafe.dart';
import '../data/study_place.dart';
import 'gret_corner_providers.dart';

final studyPlaceRepositoryProvider = Provider((ref) => StudyPlaceRepository());

class StudyPlaceNotifier extends Notifier<StudyPlace> {
  @override
  StudyPlace build() => ref.watch(studyPlaceRepositoryProvider).place;

  /// Kept until changed, however the next sessions start (FR-002).
  Future<void> choose(StudyPlace place) async {
    await ref.read(studyPlaceRepositoryProvider).save(place);
    state = place;
  }
}

final studyPlaceProvider = NotifierProvider<StudyPlaceNotifier, StudyPlace>(StudyPlaceNotifier.new);

/// The friends at the café tables (FR-005). Offline these are Gret's sea friends; a later online
/// feature can add real users' Grets here (ADR-0011).
final cafeFriendsProvider = Provider<List<SeaFriend>>(
  (ref) => SeaCafe.seated(ref.watch(gretLookProvider).species),
);
