// 5.3–5.4 Gret's home in the sea: decorations bought with pearls and placed by the house, and
// Gret sleeping at home late at night (spec 019 user story 5).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/gret_corner_catalog.dart';
import 'package:focus_app/data/mascot_mood.dart';
import 'package:focus_app/data/models/session.dart';
import 'package:focus_app/data/repositories/gret_corner_repository.dart';
import 'package:focus_app/data/repositories/session_repository.dart';
import 'package:focus_app/data/sea_cafe.dart';
import 'package:focus_app/data/sea_time.dart';
import 'package:focus_app/providers/app_providers.dart';
import 'package:focus_app/providers/gret_corner_providers.dart';
import 'package:focus_app/providers/sea_providers.dart';
import 'package:hive/hive.dart';

import 'test_helpers.dart';

void main() {
  late DateTime now;
  late ProviderContainer container;
  GretCornerNotifier corner() => container.read(gretCornerProvider.notifier);

  setUp(() async {
    await openMemoryBoxes();
    now = DateTime(2026, 11, 27, 15);
    container = ProviderContainer(overrides: [clockProvider.overrideWithValue(() => now)]);
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
  });

  Future<void> earn(int pearls) async {
    await SessionRepository().save(
      Session(
        id: 'study',
        habitId: 'h1',
        start: now,
        plannedMinutes: 25,
        focusedSeconds: pearls * 300,
        distractionCount: 0,
      ),
    );
    container.invalidate(pearlsEarnedProvider);
  }

  test('six decorations for three spots, bought with pearls only', () {
    expect(GretCornerCatalog.decorations, hasLength(6));
    expect(GretCornerCatalog.decorations.map((d) => d.spot).toSet(), DecorSpot.values.toSet());
    for (final decoration in GretCornerCatalog.decorations) {
      expect(decoration.unlock.kind, UnlockKind.pearls);
      expect(decoration.asset, startsWith('assets/scene/deco_'));
    }
    expect(GretCornerCatalog.decorationById('deco_treasure_chest')!.unlock.price, 150);
  });

  test(
    'a bought decoration is placed in its spot; another replaces it; it can be put away',
    () async {
      await earn(200);
      expect(await corner().placeDecoration('deco_jelly_lantern'), isFalse, reason: 'Not bought');
      expect(await corner().obtain('deco_jelly_lantern'), isTrue);
      expect(await corner().placeDecoration('deco_jelly_lantern'), isTrue);
      expect(container.read(gretCornerProvider).decor, {DecorSpot.leftBack: 'deco_jelly_lantern'});
      expect(container.read(gretCornerProvider).spent, 40);

      expect(await corner().obtain('deco_coral_garden'), isTrue);
      await corner().placeDecoration('deco_coral_garden');
      expect(container.read(gretCornerProvider).decor[DecorSpot.leftBack], 'deco_coral_garden');
      expect(container.read(gretLookProvider).decor, {
        DecorSpot.leftBack: 'assets/scene/deco_coral_garden.svg',
      });

      await corner().removeDecoration(DecorSpot.leftBack);
      expect(container.read(gretCornerProvider).decor, isEmpty);
    },
  );

  test('placements survive a restart; unknown ids and spots are dropped', () async {
    await earn(100);
    await corner().obtain('deco_mailbox');
    await corner().placeDecoration('deco_mailbox');
    await Hive.box<dynamic>(
      'profile',
    ).put('corner_decor', {'byHouse': 'deco_mailbox', 'roof': 'deco_mailbox', 'leftBack': 'gone'});
    expect(GretCornerRepository().decor, {DecorSpot.byHouse: 'deco_mailbox'});
    final fresh = ProviderContainer(overrides: [clockProvider.overrideWithValue(() => now)]);
    addTearDown(fresh.dispose);
    expect(fresh.read(gretCornerProvider).decor, {DecorSpot.byHouse: 'deco_mailbox'});
  });

  test('Quán San Hô is cosy by default; an unknown look reads cosy; the choice is kept', () async {
    expect(container.read(gretCornerProvider).cafeLook, CafeLook.cosy);
    await Hive.box<dynamic>('profile').put('corner_cafe_look', 'castle');
    expect(GretCornerRepository().cafeLook, CafeLook.cosy);
    await corner().chooseCafeLook(CafeLook.diorama);
    expect(GretCornerRepository().cafeLook, CafeLook.diorama);
    expect(container.read(gretCornerProvider).cafeLook, CafeLook.diorama);
  });

  group('Late night', () {
    test('from 23:00 to 05:59', () {
      expect(SeaTime.isLateNight(DateTime(2026, 11, 27, 22, 59)), isFalse);
      expect(SeaTime.isLateNight(DateTime(2026, 11, 27, 23)), isTrue);
      expect(SeaTime.isLateNight(DateTime(2026, 11, 28, 3)), isTrue);
      expect(SeaTime.isLateNight(DateTime(2026, 11, 28, 6)), isFalse);
    });

    test('Gret sleeps at home late at night, not in the evening', () {
      now = DateTime(2026, 11, 27, 23, 30);
      final late = ProviderContainer(overrides: [clockProvider.overrideWithValue(() => now)]);
      addTearDown(late.dispose);
      expect(late.read(seaStateProvider).mood, MascotMood.sleeping);

      now = DateTime(2026, 11, 27, 21);
      final evening = ProviderContainer(overrides: [clockProvider.overrideWithValue(() => now)]);
      addTearDown(evening.dispose);
      expect(evening.read(seaStateProvider).mood, isNot(MascotMood.sleeping));
    });
  });
}
