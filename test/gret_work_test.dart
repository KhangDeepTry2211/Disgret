// 3.2 Phiên học: Gret works at a desk while the student studies (spec 019 user story 1).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app/data/gret_corner_catalog.dart';
import 'package:focus_app/data/gret_work.dart';
import 'package:focus_app/data/mascot_mood.dart';
import 'package:focus_app/data/mascot_species.dart';
import 'package:focus_app/data/sea_cafe.dart';
import 'package:focus_app/widgets/cafe/cafe_diorama_painter.dart';
import 'package:focus_app/widgets/cafe/sea_cafe_painter.dart';
import 'package:focus_app/widgets/cafe/sea_cafe_scene.dart';
import 'package:focus_app/widgets/mascot/mascot_at_desk.dart';
import 'package:focus_app/widgets/mascot/mascot_view.dart';
import 'package:focus_app/widgets/sea/sea_scene.dart';
import 'package:hive/hive.dart';
import 'package:material_ui/material_ui.dart';

import 'test_helpers.dart';

Iterable<String> _svgs(WidgetTester tester) => tester
    .widgetList<SvgPicture>(find.byType(SvgPicture))
    .map((picture) => picture.bytesLoader)
    .whereType<SvgAssetLoader>()
    .map((loader) => loader.assetName);

void main() {
  group('GretWork.taskAt', () {
    test('writes, then types, then reads, two minutes each, then again', () {
      expect(GretWork.taskAt(Duration.zero), WorkTask.writing);
      expect(GretWork.taskAt(const Duration(minutes: 1, seconds: 59)), WorkTask.writing);
      expect(GretWork.taskAt(const Duration(minutes: 2)), WorkTask.typing);
      expect(GretWork.taskAt(const Duration(minutes: 4)), WorkTask.reading);
      expect(GretWork.taskAt(const Duration(minutes: 6)), WorkTask.writing);
      expect(GretWork.taskAt(const Duration(minutes: 25)), WorkTask.writing);
    });

    test('a negative time counts as the start', () {
      expect(GretWork.taskAt(const Duration(seconds: -5)), WorkTask.writing);
    });
  });

  group('MascotAtDesk', () {
    Future<void> pumpDesk(WidgetTester tester, {WorkTask? task, DeskKind desk = DeskKind.wood}) {
      stillAnimations(tester);
      return tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: MascotAtDesk(
              mood: task == null ? MascotMood.sleeping : MascotMood.focused,
              desk: desk,
              task: task,
              size: 160,
            ),
          ),
        ),
      );
    }

    testWidgets('each task puts its own props on the desk', (tester) async {
      await pumpDesk(tester, task: WorkTask.writing);
      expect(_svgs(tester), containsAll(['assets/scene/notebook.svg', 'assets/scene/pen.svg']));
      expect(_svgs(tester), contains('assets/scene/desk_wood.svg'));

      await pumpDesk(tester, task: WorkTask.typing);
      expect(_svgs(tester), contains('assets/scene/laptop.svg'));
      expect(_svgs(tester), isNot(contains('assets/scene/pen.svg')));

      await pumpDesk(tester, task: WorkTask.reading, desk: DeskKind.coral);
      expect(_svgs(tester), containsAll(['assets/scene/book.svg', 'assets/scene/book_page.svg']));
      expect(_svgs(tester), contains('assets/scene/desk_coral.svg'));
    });

    testWidgets('on a break Gret sleeps at an empty desk', (tester) async {
      await pumpDesk(tester);
      expect(_svgs(tester), contains('assets/scene/desk_wood.svg'));
      for (final prop in ['notebook', 'pen', 'laptop', 'book']) {
        expect(_svgs(tester), isNot(contains('assets/scene/$prop.svg')));
      }
      expect(tester.widget<MascotView>(find.byType(MascotView)).mood, MascotMood.sleeping);
    });

    testWidgets('every species sits at the desk', (tester) async {
      stillAnimations(tester);
      for (final species in MascotSpecies.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: MascotAtDesk(
              mood: MascotMood.focused,
              desk: DeskKind.coral,
              task: WorkTask.typing,
              species: species,
              size: 120,
            ),
          ),
        );
        expect(tester.widget<MascotView>(find.byType(MascotView)).species, species);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Scenes', () {
    setUp(openMemoryBoxes);
    tearDown(() async => Hive.close());

    testWidgets('the sea session puts Gret at the coral desk', (tester) async {
      stillAnimations(tester);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SeaScene(
              clarity: 80,
              mood: MascotMood.focused,
              variant: SeaSceneVariant.full,
              work: MascotWork(desk: DeskKind.coral, task: WorkTask.writing),
            ),
          ),
        ),
      );
      expect(tester.widget<MascotAtDesk>(find.byType(MascotAtDesk)).desk, DeskKind.coral);
    });

    testWidgets('Quán San Hô puts Gret at a wooden desk', (tester) async {
      stillAnimations(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SeaCafeScene(
              clarity: 80,
              windowPlace: SeaPlace.home,
              look: const GretLook(),
              gretMood: MascotMood.focused,
              friendMood: MascotMood.neutral,
              friends: SeaCafe.seated(MascotSpecies.gret),
              work: const MascotWork(desk: DeskKind.wood, task: WorkTask.typing),
            ),
          ),
        ),
      );
      final desk = tester.widget<MascotAtDesk>(find.byType(MascotAtDesk));
      expect(desk.desk, DeskKind.wood);
      expect(desk.task, WorkTask.typing);
    });

    testWidgets('the diorama look draws the café as an isometric room', (tester) async {
      stillAnimations(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SeaCafeScene(
              clarity: 80,
              windowPlace: SeaPlace.home,
              look: const GretLook(),
              gretMood: MascotMood.focused,
              friendMood: MascotMood.neutral,
              friends: SeaCafe.seated(MascotSpecies.gret),
              work: const MascotWork(desk: DeskKind.wood, task: WorkTask.reading),
              cafeLook: CafeLook.diorama,
            ),
          ),
        ),
      );
      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter);
      expect(painters.whereType<CafeDioramaPainter>(), hasLength(1));
      expect(painters.whereType<SeaCafePainter>(), isEmpty);
      expect(find.byType(MascotAtDesk), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
