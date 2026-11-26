// 5.5 Bản đồ biển (spec 012 FR-002): a habit's landmark grows by stage, layer by layer.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/sea_map.dart';
import 'package:focus_app/widgets/sea/landmark_look.dart';

void main() {
  const kind = PointKind.shipwreck;
  final base = LandmarkLook.base(kind);

  test('a hidden habit is a "?" buoy', () {
    expect(LandmarkLook.layers(kind, JourneyStage.hidden), [LandmarkLook.buoy]);
  });

  test('the landmark gains a layer at 7, 21, 40 and 66 days', () {
    expect(LandmarkLook.layers(kind, JourneyStage.found), [base]);
    expect(LandmarkLook.layers(kind, JourneyStage.warmUp), [LandmarkLook.kelp, base]);
    expect(LandmarkLook.layers(kind, JourneyStage.steady), [
      LandmarkLook.kelp,
      base,
      LandmarkLook.fish,
    ]);
    expect(LandmarkLook.layers(kind, JourneyStage.solid), [
      LandmarkLook.kelp,
      base,
      LandmarkLook.fish,
      LandmarkLook.creature,
    ]);
    expect(LandmarkLook.layers(kind, JourneyStage.formed), [
      LandmarkLook.kelp,
      base,
      LandmarkLook.fish,
      LandmarkLook.creature,
      LandmarkLook.flag,
    ]);
  });

  test('every kind has its own drawing, and every drawing exists', () {
    final bases = {for (final kind in PointKind.values) LandmarkLook.base(kind)};
    expect(bases, hasLength(PointKind.values.length));
    for (final path in [
      ...bases,
      LandmarkLook.buoy,
      LandmarkLook.kelp,
      LandmarkLook.fish,
      LandmarkLook.creature,
      LandmarkLook.flag,
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
