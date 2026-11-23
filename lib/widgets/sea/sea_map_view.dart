// 5.5 Bản đồ biển: the "Bản đồ" view of the Thói quen tab (spec 005, ADR-0010). One island per
// goal, one point per habit, fog that clears with the days done, and Gret in the region studied
// last. Tapping a region lists its points; tapping a "?" says which habit discovers it.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/gret_corner_catalog.dart';
import '../../data/mascot_mood.dart';
import '../../data/sea_map.dart';
import '../../l10n/app_strings.dart';
import '../../providers/gret_corner_providers.dart';
import '../../providers/sea_map_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../mascot/mascot_view.dart';
import 'sea_map_painter.dart';

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

class SeaMapView extends ConsumerWidget {
  const SeaMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final data = ref.watch(seaMapProvider);
    final look = ref.watch(gretLookProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - AppSpacing.md * 2;
        final layout = SeaMapLayout.of(data, width);

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xxl * 2,
          ),
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    shape: const StadiumBorder(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      AppStrings.mapExplored(_percent(data.progress)),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    AppStrings.mapHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.heroBorder,
              child: SizedBox(
                key: const ValueKey('sea-map'),
                width: width,
                height: layout.height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(child: CustomPaint(painter: SeaMapPainter(layout))),
                    ),
                    for (final region in layout.regions)
                      Positioned.fromRect(
                        rect: region.rect,
                        child: Semantics(
                          button: true,
                          label: AppStrings.mapRegionSemantics(
                            region.region.goal.title,
                            _seaName(region.region),
                            _percent(region.region.progress),
                          ),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _showRegion(context, region.region),
                          ),
                        ),
                      ),
                    for (final region in layout.regions)
                      Positioned(
                        left: region.rect.left + AppSpacing.md,
                        top: region.rect.top + AppSpacing.sm,
                        right: region.rect.right < width
                            ? width - region.rect.right + AppMascot.small
                            : AppMascot.small,
                        child: IgnorePointer(child: _RegionLabel(region: region.region)),
                      ),
                    for (final region in layout.regions)
                      for (var j = 0; j < region.points.length; j++)
                        Positioned(
                          left: region.points[j].dx - AppSeaMap.pointSize,
                          top: region.points[j].dy - AppSeaMap.pointSize / 2,
                          width: AppSeaMap.pointSize * 2,
                          child: _PointButton(
                            key: ValueKey('map-point-${region.region.points[j].habit.id}'),
                            point: region.region.points[j],
                            onTap: () => _onPoint(context, region.region, region.region.points[j]),
                          ),
                        ),
                    for (final region in layout.regions)
                      if (region.region.goal.id == data.gretGoalId)
                        Positioned(
                          left: region.rect.right - AppSeaMap.gretSize - AppSpacing.sm,
                          top: region.rect.top,
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
          ],
        );
      },
    );
  }

  void _onPoint(BuildContext context, MapRegion region, MapPoint point) {
    if (point.discovered) {
      _showRegion(context, region);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppStrings.mapDiscoverHint(point.habit.name))));
  }

  void _showRegion(BuildContext context, MapRegion region) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _RegionSheet(region: region),
    );
  }
}

/// The goal title and "terrain · n%" on the island.
class _RegionLabel extends StatelessWidget {
  const _RegionLabel({required this.region});

  final MapRegion region;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.cardBorder,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                region.goal.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                AppStrings.mapRegionLine(_seaName(region), _percent(region.progress)),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A discovery point: its icon (or "?") and, once found, "n/66".
class _PointButton extends StatelessWidget {
  const _PointButton({required this.point, required this.onTap, super.key});

  final MapPoint point;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final found = point.discovered;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: found ? AppSeaMap.pointFound : AppSeaMap.pointHidden,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox.square(
                dimension: AppSeaMap.pointSize,
                child: Icon(
                  found ? _kindIcon(point.kind) : AppIcons.pointHidden,
                  color: found ? AppSeaMap.pointFoundIcon : AppSeaMap.pointHiddenIcon,
                ),
              ),
            ),
          ),
          if (found) ...[
            const SizedBox(height: AppSpacing.xs),
            DecoratedBox(
              decoration: ShapeDecoration(
                color: theme.colorScheme.surface,
                shape: const StadiumBorder(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  AppStrings.mapDays(point.daysDone, SeaMap.fullDays),
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A region's goal, progress and points.
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
                              ? islandColour(region.place)
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
