// 5.5 Bản đồ biển, full screen (spec 005, ADR-0010): one ocean where every goal is an island, each
// habit a landmark that grows with its stage (spec 012), and the darkness opens around what was
// explored. The map glides from the whole
// world to Gret's island when it opens; it pans, pinch-zooms, and has +/− and "Về chỗ Gret".
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/gret_corner_catalog.dart';
import '../data/mascot_mood.dart';
import '../data/mascot_species.dart';
import '../data/sea_map.dart';
import '../l10n/app_strings.dart';
import '../providers/gret_corner_providers.dart';
import '../providers/sea_map_providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/mascot/mascot_view.dart';
import '../widgets/sea/landmark_look.dart';
import '../widgets/sea/sea_world.dart';

String _kindName(PointKind kind) => switch (kind) {
  PointKind.fishCave => AppStrings.mapFishCave,
  PointKind.shipwreck => AppStrings.mapShipwreck,
  PointKind.kelpGarden => AppStrings.mapKelpGarden,
  PointKind.treasure => AppStrings.mapTreasure,
  PointKind.coralTemple => AppStrings.mapCoralTemple,
  PointKind.oldAnchor => AppStrings.mapOldAnchor,
};

IconData _kindIcon(PointKind kind) => switch (kind) {
  PointKind.fishCave => AppIcons.fishCave,
  PointKind.shipwreck => AppIcons.shipwreck,
  PointKind.kelpGarden => AppIcons.kelpGarden,
  PointKind.treasure => AppIcons.treasure,
  PointKind.coralTemple => AppIcons.coralTemple,
  PointKind.oldAnchor => AppIcons.oldAnchor,
};

String _stageName(JourneyStage stage) => switch (stage) {
  JourneyStage.hidden => AppStrings.mapStageHidden,
  JourneyStage.found => AppStrings.mapStageFound,
  JourneyStage.warmUp => AppStrings.mapStageWarmUp,
  JourneyStage.steady => AppStrings.mapStageSteady,
  JourneyStage.solid => AppStrings.mapStageSolid,
  JourneyStage.formed => AppStrings.mapStageFormed,
};

int _percent(double progress) => (progress * 100).round();

String _seaName(MapRegion region) => GretCornerCatalog.seaOf(region.place).name;

class SeaMapScreen extends ConsumerStatefulWidget {
  const SeaMapScreen({super.key});

  @override
  ConsumerState<SeaMapScreen> createState() => _SeaMapScreenState();
}

class _SeaMapScreenState extends ConsumerState<SeaMapScreen> with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  late final AnimationController _glide = AnimationController(vsync: this)
    ..addListener(() {
      final animation = _glideAnimation;
      if (animation != null) _transform.value = animation.value;
    });
  Animation<Matrix4>? _glideAnimation;
  Size? _viewport;
  bool _opened = false;

  @override
  void dispose() {
    _glide.dispose();
    _transform.dispose();
    super.dispose();
  }

  /// A view that puts [worldPoint] at the centre of the viewport at [scale].
  Matrix4 _view(Offset worldPoint, double scale, Size viewport) =>
      Matrix4.diagonal3Values(scale, scale, scale)..setTranslationRaw(
        viewport.width / 2 - worldPoint.dx * scale,
        viewport.height / 2 - worldPoint.dy * scale,
        0,
      );

  void _glideTo(Matrix4 target, Duration duration) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _glide.stop();
      _transform.value = target;
      return;
    }
    _glideAnimation = Matrix4Tween(
      begin: _transform.value.clone(),
      end: target,
    ).animate(CurvedAnimation(parent: _glide, curve: Curves.easeInOutCubic));
    _glide
      ..duration = duration
      ..forward(from: 0);
  }

  Offset _gretPoint(SeaWorldLayout layout, SeaMapData data) {
    final goalId = data.gretGoalId;
    final island = goalId == null ? null : layout.islandOf(goalId);
    return island?.centre ?? layout.size.center(Offset.zero);
  }

  /// Opening: the whole world first, then a slow glide to Gret's island (straight there with
  /// animations removed).
  void _open(Size viewport, SeaWorldLayout layout, SeaMapData data) {
    if (_opened) return;
    _opened = true;
    final overviewScale = math
        .min(viewport.width / layout.size.width, viewport.height / layout.size.height)
        .clamp(AppSeaMap.minScale, AppSeaMap.focusScale);
    final focus = _view(_gretPoint(layout, data), AppSeaMap.focusScale, viewport);
    if (MediaQuery.disableAnimationsOf(context)) {
      _transform.value = focus;
      return;
    }
    _transform.value = _view(layout.size.center(Offset.zero), overviewScale, viewport);
    _glideTo(focus, AppMotion.mapOpen);
  }

  /// Zooms around the centre of the screen.
  void _zoom(double factor) {
    final viewport = _viewport;
    if (viewport == null) return;
    final scale = (_transform.value.getMaxScaleOnAxis() * factor).clamp(
      AppSeaMap.minScale,
      AppSeaMap.maxScale,
    );
    final centre = _transform.toScene(viewport.center(Offset.zero));
    _glideTo(_view(centre, scale, viewport), AppMotion.mapGlide);
  }

  void _toGret(SeaWorldLayout layout, SeaMapData data) {
    final viewport = _viewport;
    if (viewport == null) return;
    _glideTo(_view(_gretPoint(layout, data), AppSeaMap.focusScale, viewport), AppMotion.mapGlide);
  }

  void _onPin(MapRegion region, MapPoint point) {
    if (point.discovered) {
      _showRegion(region);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppStrings.mapDiscoverHint(point.habit.name))));
  }

  /// A bought sea's island (spec 014): make it Gret's sea.
  void _showSea(SeaPlace place) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _SeaIslandSheet(place: place),
    );
  }

  void _showRegion(MapRegion region) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _RegionSheet(region: region),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = ref.watch(seaMapProvider);
    final look = ref.watch(gretLookProvider);
    final layout = SeaWorldLayout.of(
      data,
      boughtSeas: GretCornerCatalog.boughtSeas(ref.watch(gretCornerProvider).owned),
    );
    final padding = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppSeaMap.fogOcean,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final viewport = constraints.biggest;
            _viewport = viewport;
            if (!_opened) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _open(viewport, layout, data);
              });
            }

            return Stack(
              children: [
                InteractiveViewer(
                  key: const ValueKey('sea-map'),
                  transformationController: _transform,
                  constrained: false,
                  minScale: AppSeaMap.minScale,
                  maxScale: AppSeaMap.maxScale,
                  boundaryMargin: const EdgeInsets.all(AppSeaMap.worldMargin),
                  onInteractionStart: (_) => _glide.stop(),
                  child: SizedBox.fromSize(
                    size: layout.size,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: SeaWorldPainter(layout: layout, gretGoalId: data.gretGoalId),
                            ),
                          ),
                        ),
                        for (final island in layout.known)
                          Positioned.fromRect(
                            rect: island.bounds,
                            child: Semantics(
                              button: true,
                              label: AppStrings.mapRegionSemantics(
                                island.region!.goal.title,
                                _seaName(island.region!),
                                _percent(island.region!.progress),
                              ),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _showRegion(island.region!),
                              ),
                            ),
                          ),
                        for (final island in layout.bought)
                          Positioned.fromRect(
                            rect: island.bounds,
                            child: Semantics(
                              button: true,
                              label: AppStrings.mapSeaSemantics(
                                GretCornerCatalog.seaOf(island.sea!).name,
                              ),
                              child: GestureDetector(
                                key: ValueKey('map-sea-${island.sea!.name}'),
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _showSea(island.sea!),
                              ),
                            ),
                          ),
                        for (final island in layout.islands)
                          Positioned(
                            left: island.labelAnchor.dx - island.radiusX,
                            top: island.labelAnchor.dy - AppSpacing.xl,
                            width: island.radiusX * 2,
                            child: IgnorePointer(
                              child: Center(child: _IslandLabel(island: island)),
                            ),
                          ),
                        for (final island in layout.known)
                          for (var j = 0; j < island.points.length; j++)
                            Positioned(
                              // The landmark stands on its point; "n/66" hangs below it.
                              left: island.points[j].dx - AppSeaMap.landmarkSize / 2,
                              top: island.points[j].dy - _Landmark.height * _Landmark.groundLine,
                              width: AppSeaMap.landmarkSize,
                              child: _Landmark(
                                key: ValueKey('map-point-${island.region!.points[j].habit.id}'),
                                point: island.region!.points[j],
                                onTap: () => _onPin(island.region!, island.region!.points[j]),
                              ),
                            ),
                        for (final island in layout.known)
                          if (island.region!.goal.id == data.gretGoalId)
                            Positioned(
                              left: island.gretSpot.dx - AppSeaMap.gretSize / 2,
                              top: island.gretSpot.dy - AppSeaMap.gretSize / 2,
                              child: IgnorePointer(
                                child: Semantics(
                                  label: AppStrings.mapGretHere,
                                  child: MascotView(
                                    key: const ValueKey('map-gret'),
                                    mood: MascotMood.happy,
                                    size: AppSeaMap.gretSize,
                                    species: look.species,
                                    outfit: look.outfit,
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          _RoundButton(
                            tooltip: AppStrings.back,
                            icon: const BackButtonIcon(),
                            onPressed: () =>
                                context.canPop() ? context.pop() : context.go(AppRoutes.habits),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              AppStrings.mapTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppSeaMap.labelTitle,
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: const ShapeDecoration(
                              color: AppSeaMap.pointFound,
                              shape: StadiumBorder(),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              child: Text(
                                AppStrings.mapExplored(_percent(data.progress)),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppSeaMap.pointFoundIcon,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpacing.md,
                  bottom: padding.bottom + AppSpacing.xxl * 2,
                  child: Column(
                    children: [
                      _RoundButton(
                        tooltip: AppStrings.mapZoomIn,
                        icon: const Icon(AppIcons.add),
                        onPressed: () => _zoom(AppSeaMap.zoomStep),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _RoundButton(
                        tooltip: AppStrings.mapZoomOut,
                        icon: const Icon(AppIcons.zoomOut),
                        onPressed: () => _zoom(1 / AppSeaMap.zoomStep),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: padding.bottom + AppSpacing.md,
                  child: Center(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppSeaMap.pointFound,
                        foregroundColor: AppSeaMap.pointFoundIcon,
                      ),
                      icon: const Icon(AppIcons.locate),
                      label: const Text(AppStrings.mapToGret),
                      onPressed: () => _toGret(layout, data),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.tooltip, required this.icon, required this.onPressed});

  final String tooltip;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: AppSeaMap.controlBg,
        foregroundColor: AppSeaMap.controlIcon,
      ),
      icon: icon,
      onPressed: onPressed,
    );
  }
}

/// The name of an island and its exploration, or "Vùng chưa biết".
class _IslandLabel extends StatelessWidget {
  const _IslandLabel({required this.island});

  final IslandLayout island;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final region = island.region;
    final sea = island.sea;

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppSeaMap.labelBg, borderRadius: AppRadius.cardBorder),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: sea != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    GretCornerCatalog.seaOf(sea).name,
                    style: theme.textTheme.titleSmall?.copyWith(color: AppSeaMap.labelTitle),
                  ),
                  Text(
                    AppStrings.mapGretSea,
                    style: theme.textTheme.labelSmall?.copyWith(color: AppSeaMap.labelSub),
                  ),
                ],
              )
            : region == null
            ? Text(
                AppStrings.mapUnknown,
                style: theme.textTheme.labelMedium?.copyWith(color: AppSeaMap.unknownLabel),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    region.goal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(color: AppSeaMap.labelTitle),
                  ),
                  Text(
                    AppStrings.mapExploration(_seaName(region), _percent(region.progress)),
                    style: theme.textTheme.labelSmall?.copyWith(color: AppSeaMap.labelSub),
                  ),
                ],
              ),
      ),
    );
  }
}

/// A habit's landmark (spec 012): its drawing with the growth layers of its stage and "n/66" once
/// found, a "?" buoy before.
class _Landmark extends StatelessWidget {
  const _Landmark({required this.point, required this.onTap, super.key});

  final MapPoint point;
  final VoidCallback onTap;

  static final double height =
      AppSeaMap.landmarkSize * LandmarkLook.canvas.height / LandmarkLook.canvas.width;

  /// Where the drawings touch the ground, as a share of their height.
  static const double groundLine = 0.88;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final found = point.discovered;

    final pin = SizedBox(
      width: AppSeaMap.landmarkSize,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final layer in LandmarkLook.layers(point.kind, point.stage))
            SvgPicture.asset(layer, fit: BoxFit.contain),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: found
          ? AppStrings.mapPointSemantics(
              point.habit.name,
              _kindName(point.kind),
              '${AppStrings.mapDaysLong(point.daysDone, SeaMap.fullDays)}, ${_stageName(point.stage)}',
            )
          : AppStrings.mapHiddenSemantics(point.habit.name),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            pin,
            if (found) ...[
              DecoratedBox(
                decoration: const ShapeDecoration(
                  color: AppSeaMap.pointFound,
                  shape: StadiumBorder(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    AppStrings.mapDays(point.daysDone, SeaMap.fullDays),
                    style: theme.textTheme.labelSmall?.copyWith(color: AppSeaMap.pointFoundIcon),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A bought sea's island: its name and the one action, making it Gret's sea (spec 014).
class _SeaIslandSheet extends ConsumerWidget {
  const _SeaIslandSheet({required this.place});

  final SeaPlace place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inUse = ref.watch(gretCornerProvider).sea == place;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              GretCornerCatalog.seaOf(place).name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            Text(
              AppStrings.mapGretSea,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (inUse)
              Text(
                AppStrings.mapSeaInUse,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              GradientPillButton(
                label: AppStrings.mapChooseSea,
                height: AppButton.compact,
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await ref.read(gretCornerProvider.notifier).chooseSea(place);
                  navigator.pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// A region's goal, exploration and points.
class _RegionSheet extends StatelessWidget {
  const _RegionSheet({required this.region});

  final MapRegion region;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(region.goal.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.mapRegionLine(_seaName(region), _percent(region.progress)),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.pillBorder,
              child: LinearProgressIndicator(value: region.progress),
            ),
            const SizedBox(height: AppSpacing.md),
            if (region.points.isEmpty) ...[
              Text(AppStrings.mapEmptyRegion, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(AppRoutes.habitForm(region.goal.id));
                },
                child: const Text(AppStrings.addHabit),
              ),
            ] else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final point in region.points)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: point.discovered
                              ? AppSeaMap.pointFound
                              : AppSeaMap.pointHidden,
                          child: Icon(
                            point.discovered ? _kindIcon(point.kind) : AppIcons.pointHidden,
                            color: point.discovered
                                ? AppSeaMap.pointFoundIcon
                                : AppSeaMap.pointHiddenIcon,
                          ),
                        ),
                        title: Text(point.habit.name),
                        subtitle: Text(
                          point.discovered
                              ? '${_kindName(point.kind)} · '
                                    '${AppStrings.mapDaysLong(point.daysDone, SeaMap.fullDays)} · '
                                    '${_stageName(point.stage)}'
                              : AppStrings.mapDiscoverHint(point.habit.name),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
