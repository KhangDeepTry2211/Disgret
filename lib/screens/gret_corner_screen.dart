// 5.4 Góc của Gret: dress Gret, change the sea, choose a mascot (spec 004, ADR-0009).
// Pearls are earned only by studying; premium items are listed as "Sắp có".
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../data/gret_corner_catalog.dart';
import '../data/mascot_mood.dart';
import '../data/mascot_species.dart';
import '../data/sea_cafe.dart';
import '../data/sea_time.dart';
import '../data/study_unlocks.dart';
import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';
import '../providers/gret_corner_providers.dart';
import '../providers/sea_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/cafe/cafe_diorama_painter.dart';
import '../widgets/cafe/sea_cafe_painter.dart';
import '../widgets/gradient_pill_button.dart';
import '../widgets/mascot/mascot_view.dart';
import '../widgets/sea/sea_painter.dart';
import '../widgets/sea/sea_scene.dart';

class GretCornerScreen extends ConsumerStatefulWidget {
  const GretCornerScreen({super.key});

  @override
  ConsumerState<GretCornerScreen> createState() => _GretCornerScreenState();
}

class _GretCornerScreenState extends ConsumerState<GretCornerScreen> {
  /// The sea shown in the preview; may be a locked one the user is only looking at.
  SeaPlace? _preview;

  Future<void> _browse(int step) async {
    final seas = GretCornerCatalog.seas;
    final current = _preview ?? ref.read(gretCornerProvider).sea;
    final index = seas.indexWhere((sea) => sea.place == current);
    final next = seas[(index + step) % seas.length].place;
    setState(() => _preview = next);
    // Browsing to an open sea chooses it; a locked one is only previewed.
    await ref.read(gretCornerProvider.notifier).chooseSea(next);
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(pearlBalanceProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.cornerTitle),
          actions: [
            _PearlChip(pearls: balance),
            const SizedBox(width: AppSpacing.md),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: _Preview(
                place: _preview ?? ref.watch(gretCornerProvider).sea,
                onPrevious: () => _browse(-1),
                onNext: () => _browse(1),
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: AppStrings.cornerTabWardrobe),
                Tab(text: AppStrings.cornerTabSea),
                Tab(text: AppStrings.cornerTabMascots),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const _WardrobeTab(),
                  _SeaTab(onChosen: (place) => setState(() => _preview = place)),
                  const _MascotTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The current look in the previewed sea, with arrows to browse the seas.
class _Preview extends ConsumerWidget {
  const _Preview({required this.place, required this.onPrevious, required this.onNext});

  final SeaPlace place;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final look = ref.watch(gretLookProvider);
    final sea = ref.watch(seaStateProvider);
    final info = GretCornerCatalog.seaOf(place);
    final lock = ref.read(gretCornerProvider.notifier).lockOf(info.unlock, id: info.id);
    ref.watch(bestStreakProvider);

    return SeaScene(
      clarity: sea.clarity,
      mood: MascotMood.happy,
      variant: SeaSceneVariant.compact,
      look: GretLook(species: look.species, outfit: look.outfit, place: place),
      overlay: DecoratedBox(
        decoration: ShapeDecoration(color: theme.colorScheme.surface, shape: const StadiumBorder()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lock != CornerLock.none) ...[
                const Icon(AppIcons.lock, size: AppSpacing.md),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                lock == CornerLock.none
                    ? info.name
                    : lock == CornerLock.pearls
                    ? '${info.name} · ${AppStrings.cornerPrice(info.unlock.price)}'
                    : '${info.name} · ${AppStrings.cornerSeaLocked(info.unlock.amount)}',
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
      foreground: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.filledTonal(
            tooltip: AppStrings.cornerPreviousSea,
            onPressed: onPrevious,
            icon: const Icon(AppIcons.previous),
          ),
          IconButton.filledTonal(
            tooltip: AppStrings.cornerNextSea,
            onPressed: onNext,
            icon: const Icon(AppIcons.next),
          ),
        ],
      ),
    );
  }
}

class _PearlChip extends StatelessWidget {
  const _PearlChip({required this.pearls});

  final int pearls;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: AppStrings.cornerPearls(pearls),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: theme.colorScheme.secondaryContainer,
          shape: const StadiumBorder(),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.pearl, size: AppSpacing.md, color: AppSea.fishFin),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$pearls',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Shared labels ----------

String _rarityLabel(Rarity rarity) => switch (rarity) {
  Rarity.common => AppStrings.rarityCommon,
  Rarity.rare => AppStrings.rarityRare,
  Rarity.special => AppStrings.raritySpecial,
};

Color _rarityColour(Rarity rarity, ColorScheme scheme) => switch (rarity) {
  Rarity.common => scheme.outlineVariant,
  Rarity.rare => AppCorner.rare,
  Rarity.special => AppCorner.special,
};

/// What a card says about an item, mascot or sea that is not in use.
String _statusOf(Unlock unlock, CornerLock lock, {StudyFacts facts = const StudyFacts()}) =>
    switch (lock) {
      CornerLock.none =>
        unlock.kind == UnlockKind.pearls || unlock.isStudy
            ? AppStrings.cornerOwned
            : AppStrings.cornerFree,
      CornerLock.pearls => AppStrings.cornerPrice(unlock.price),
      CornerLock.streak => AppStrings.cornerStreak(unlock.amount),
      CornerLock.premium => AppStrings.cornerSoon,
      CornerLock.study => _studyProgress(unlock, facts, short: true),
    };

/// "2/5 lần đúng giờ", "6,5/10 giờ"… for a friend earned by studying (spec 018); [short] for the
/// narrow cards.
String _studyProgress(Unlock unlock, StudyFacts facts, {bool short = false}) {
  final progress = facts.progressOf(unlock);
  final done = progress.floor().clamp(0, unlock.amount);
  return switch (unlock.kind) {
    UnlockKind.onTimeStarts =>
      short
          ? AppStrings.cornerOnTimeShort(done, unlock.amount)
          : AppStrings.cornerOnTimeProgress(done, unlock.amount),
    UnlockKind.interventionReturns =>
      short
          ? AppStrings.cornerReturnsShort(done, unlock.amount)
          : AppStrings.cornerReturnsProgress(done, unlock.amount),
    UnlockKind.focusHours => AppStrings.cornerHoursProgress(
      progress.clamp(0, unlock.amount).toDouble(),
      unlock.amount,
    ),
    _ => AppStrings.cornerDaysProgress(done, unlock.amount),
  };
}

/// What has to be done to earn a friend (spec 018).
String _studyNeed(Unlock unlock) => switch (unlock.kind) {
  UnlockKind.onTimeStarts => AppStrings.cornerNeedOnTime(unlock.amount),
  UnlockKind.interventionReturns => AppStrings.cornerNeedReturns(unlock.amount),
  UnlockKind.focusHours => AppStrings.cornerNeedHours(unlock.amount),
  _ => AppStrings.cornerNeedDays(unlock.amount),
};

/// The one action for a locked or available entry, or the reason there is none.
class _UnlockAction extends ConsumerWidget {
  const _UnlockAction({
    required this.id,
    required this.name,
    required this.unlock,
    required this.inUse,
    required this.useLabel,
    required this.onUse,
    this.onStopUsing,
    this.stopLabel = AppStrings.cornerTakeOff,
  });

  final String id;
  final String name;
  final Unlock unlock;
  final bool inUse;
  final String useLabel;
  final Future<void> Function() onUse;
  final Future<void> Function()? onStopUsing;
  final String stopLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(gretCornerProvider.notifier);
    final balance = ref.watch(pearlBalanceProvider);
    ref.watch(gretCornerProvider);
    final lock = notifier.lockOf(unlock, id: id);

    Widget reason(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );

    switch (lock) {
      case CornerLock.premium:
        return reason(AppStrings.cornerPremium);
      case CornerLock.study:
        final progress = _studyProgress(unlock, ref.watch(studyFactsProvider));
        return reason('${_studyNeed(unlock)}\n${AppStrings.cornerSoFar(progress)}');
      case CornerLock.streak:
        return reason(AppStrings.cornerNeedStreak(unlock.amount));
      case CornerLock.pearls:
        if (balance < unlock.price) return reason(AppStrings.cornerMissing(unlock.price - balance));
        return GradientPillButton(
          icon: AppIcons.pearl,
          label: AppStrings.cornerObtain(unlock.price),
          height: AppButton.compact,
          bubbles: true,
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            if (!await notifier.obtain(id)) return;
            await onUse();
            navigator.pop();
            messenger.showSnackBar(SnackBar(content: Text(AppStrings.cornerGot(name))));
          },
        );
      case CornerLock.none:
        final stop = onStopUsing;
        if (inUse && stop != null) {
          return OutlinedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await stop();
              navigator.pop();
            },
            child: Text(stopLabel),
          );
        }
        if (inUse) return reason(AppStrings.cornerChosen);
        return GradientPillButton(
          label: useLabel,
          height: AppButton.compact,
          onPressed: () async {
            final navigator = Navigator.of(context);
            await onUse();
            navigator.pop();
          },
        );
    }
  }
}

/// A sheet with a big preview, the name, the rarity and the single action.
Future<void> _showSheet(
  BuildContext context, {
  required Widget preview,
  required String name,
  required String detail,
  required Widget action,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: preview),
              const SizedBox(height: AppSpacing.md),
              Text(name, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              action,
            ],
          ),
        ),
      );
    },
  );
}

// ---------- Tủ đồ ----------

enum _Filter { all, owned, pearls, streak, shop }

class _WardrobeTab extends ConsumerStatefulWidget {
  const _WardrobeTab();

  @override
  ConsumerState<_WardrobeTab> createState() => _WardrobeTabState();
}

class _WardrobeTabState extends ConsumerState<_WardrobeTab> {
  _Filter _filter = _Filter.all;

  static String _label(_Filter filter) => switch (filter) {
    _Filter.all => AppStrings.cornerFilterAll,
    _Filter.owned => AppStrings.cornerFilterOwned,
    _Filter.pearls => AppStrings.cornerFilterPearls,
    _Filter.streak => AppStrings.cornerFilterStreak,
    _Filter.shop => AppStrings.cornerFilterShop,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corner = ref.watch(gretCornerProvider);
    ref.watch(bestStreakProvider);
    final notifier = ref.read(gretCornerProvider.notifier);
    CornerLock lockOf(CornerItem item) => notifier.lockOf(item.unlock, id: item.id);

    const items = GretCornerCatalog.items;
    final available = items.where((item) => lockOf(item) == CornerLock.none).length;
    final shown = items.where(
      (item) => switch (_filter) {
        _Filter.all => true,
        _Filter.owned => lockOf(item) == CornerLock.none,
        _Filter.pearls => item.unlock.kind == UnlockKind.pearls,
        _Filter.streak => item.unlock.kind == UnlockKind.streak,
        _Filter.shop => item.unlock.kind == UnlockKind.premium,
      },
    );
    final wornNames = [for (final id in corner.worn.values) GretCornerCatalog.itemById(id)?.name]
        .nonNulls
        .join(', ');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                wornNames.isEmpty
                    ? AppStrings.cornerNothingWorn
                    : AppStrings.cornerWornList(wornNames),
                style: theme.textTheme.titleSmall,
              ),
            ),
            Text(
              AppStrings.cornerOwnedCount(available, items.length),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (corner.mascot != MascotSpecies.gret) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.cornerGretOnly,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final filter in _Filter.values)
              ChoiceChip(
                label: Text(_label(filter)),
                selected: _filter == filter,
                onSelected: (_) => setState(() => _filter = filter),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: AppCorner.cardAspect,
          children: [
            for (final item in shown)
              _CornerCard(
                key: ValueKey('corner-item-${item.id}'),
                preview: MascotView(
                  mood: MascotMood.happy,
                  size: AppCorner.cardMascot,
                  outfit: {item.slot: item.asset},
                ),
                name: item.name,
                rarity: item.rarity,
                status: corner.worn[item.slot] == item.id
                    ? AppStrings.cornerWearing
                    : _statusOf(item.unlock, lockOf(item)),
                highlighted: corner.worn[item.slot] == item.id,
                onTap: () => _openItem(context, item),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppStrings.cornerPearlsHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  void _openItem(BuildContext context, CornerItem item) {
    final notifier = ref.read(gretCornerProvider.notifier);
    _showSheet(
      context,
      preview: MascotView(
        mood: MascotMood.happy,
        size: AppCorner.sheetMascot,
        outfit: {item.slot: item.asset},
      ),
      name: item.name,
      detail: _rarityLabel(item.rarity),
      action: Consumer(
        builder: (context, ref, _) => _UnlockAction(
          id: item.id,
          name: item.name,
          unlock: item.unlock,
          inUse: ref.watch(gretCornerProvider).worn[item.slot] == item.id,
          useLabel: AppStrings.cornerWear,
          onUse: () async => notifier.wear(item.id),
          onStopUsing: () => notifier.takeOff(item.slot),
        ),
      ),
    );
  }
}

/// A grid card: preview, name, and rarity with status.
class _CornerCard extends StatelessWidget {
  const _CornerCard({
    required this.preview,
    required this.name,
    required this.rarity,
    required this.status,
    required this.highlighted,
    required this.onTap,
    super.key,
  });

  final Widget preview;
  final String name;
  final Rarity rarity;
  final String status;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rarityColour = _rarityColour(rarity, scheme);

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: highlighted,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardBorder,
            side: BorderSide(
              color: highlighted ? scheme.primary : rarityColour,
              width: highlighted ? 2 : 1.5,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Column(
                children: [
                  Expanded(
                    child: Center(child: ExcludeSemantics(child: preview)),
                  ),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium,
                  ),
                  Text(
                    '${_rarityLabel(rarity)} · $status',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: highlighted ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Biển ----------

class _SeaTab extends ConsumerWidget {
  const _SeaTab({required this.onChosen});

  final ValueChanged<SeaPlace> onChosen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final corner = ref.watch(gretCornerProvider);
    ref.watch(bestStreakProvider);
    final notifier = ref.read(gretCornerProvider.notifier);
    final isNight = SeaTime.isNight(ref.watch(clockProvider)());

    return ListView(
      key: const ValueKey('corner-sea-list'),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final sea in GretCornerCatalog.seas)
          Builder(
            builder: (context) {
              final lock = notifier.lockOf(sea.unlock, id: sea.id);
              final chosen = corner.sea == sea.place;
              return Card(
                key: ValueKey('corner-sea-${sea.place.name}'),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppSpacing.sm),
                  leading: ClipRRect(
                    borderRadius: AppRadius.cardBorder,
                    child: SizedBox(
                      width: AppCorner.seaThumbWidth,
                      height: AppCorner.seaThumbHeight,
                      child: CustomPaint(
                        painter: SeaPainter(
                          loop: kAlwaysDismissedAnimation,
                          clarity: 85,
                          isNight: isNight,
                          place: sea.place,
                        ),
                      ),
                    ),
                  ),
                  title: Text(sea.name),
                  subtitle: Text(chosen ? AppStrings.cornerChosen : _statusOf(sea.unlock, lock)),
                  trailing: chosen
                      ? Icon(AppIcons.check, color: theme.colorScheme.primary)
                      : lock == CornerLock.none
                      ? null
                      : const Icon(AppIcons.lock),
                  onTap: lock == CornerLock.pearls
                      // A pearl sea opens the same sheet as outfits to buy it (spec 014).
                      ? () => _showSheet(
                          context,
                          preview: ClipRRect(
                            borderRadius: AppRadius.cardBorder,
                            child: SizedBox(
                              width: AppCorner.sheetSeaWidth,
                              height: AppCorner.sheetSeaHeight,
                              child: CustomPaint(
                                painter: SeaPainter(
                                  loop: kAlwaysDismissedAnimation,
                                  clarity: 85,
                                  isNight: isNight,
                                  place: sea.place,
                                ),
                              ),
                            ),
                          ),
                          name: sea.name,
                          detail: AppStrings.cornerTabSea,
                          action: _UnlockAction(
                            id: sea.id,
                            name: sea.name,
                            unlock: sea.unlock,
                            inUse: chosen,
                            useLabel: AppStrings.cornerChoose,
                            onUse: () async {
                              if (await notifier.chooseSea(sea.place)) onChosen(sea.place);
                            },
                          ),
                        )
                      : lock == CornerLock.none && !chosen
                      ? () async {
                          if (await notifier.chooseSea(sea.place)) onChosen(sea.place);
                        }
                      : null,
                ),
              );
            },
          ),
        // Decorations for Gret's home (spec 019).
        const SizedBox(height: AppSpacing.md),
        Text(AppStrings.cornerDecorTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppStrings.cornerDecorHint,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: AppCorner.cardAspect,
          children: [
            for (final decoration in GretCornerCatalog.decorations)
              Builder(
                builder: (context) {
                  final placed = corner.decor[decoration.spot] == decoration.id;
                  return _CornerCard(
                    key: ValueKey('corner-decor-${decoration.id}'),
                    preview: SvgPicture.asset(decoration.asset, height: AppCorner.cardMascot),
                    name: decoration.name,
                    rarity: decoration.unlock.price >= 100 ? Rarity.rare : Rarity.common,
                    status: placed
                        ? AppStrings.cornerPlaced
                        : _statusOf(
                            decoration.unlock,
                            notifier.lockOf(decoration.unlock, id: decoration.id),
                          ),
                    highlighted: placed,
                    onTap: () => _showSheet(
                      context,
                      preview: SvgPicture.asset(decoration.asset, height: AppCorner.sheetMascot),
                      name: decoration.name,
                      detail: AppStrings.cornerDecorDetail,
                      action: Consumer(
                        builder: (context, ref, _) => _UnlockAction(
                          id: decoration.id,
                          name: decoration.name,
                          unlock: decoration.unlock,
                          inUse:
                              ref.watch(gretCornerProvider).decor[decoration.spot] == decoration.id,
                          useLabel: AppStrings.cornerPlace,
                          stopLabel: AppStrings.cornerPutAway,
                          onUse: () async => notifier.placeDecoration(decoration.id),
                          onStopUsing: () async => notifier.removeDecoration(decoration.spot),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

// ---------- Linh vật ----------

class _MascotTab extends ConsumerWidget {
  const _MascotTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final corner = ref.watch(gretCornerProvider);
    ref.watch(pearlBalanceProvider);
    final facts = ref.watch(studyFactsProvider);
    final notifier = ref.read(gretCornerProvider.notifier);
    final theme = Theme.of(context);
    final isNight = SeaTime.isNight(ref.watch(clockProvider)());

    return ListView(
      key: const ValueKey('corner-mascot-list'),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // The drawing style of every mascot, seen at once on the sea above (spec 018).
        Text(AppStrings.cornerStyleTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final style in MascotStyle.values)
              ChoiceChip(
                key: ValueKey('corner-style-${style.name}'),
                label: Text(_styleLabel(style)),
                selected: corner.style == style,
                onSelected: (_) => notifier.chooseStyle(style),
              ),
          ],
        ),
        // How Quán San Hô looks during café sessions (spec 019).
        const SizedBox(height: AppSpacing.md),
        Text(AppStrings.cornerCafeTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final cafe in CafeLook.values)
              ChoiceChip(
                key: ValueKey('corner-cafe-${cafe.name}'),
                label: Text(cafe == CafeLook.cosy ? AppStrings.cafeCosy : AppStrings.cafeDiorama),
                selected: corner.cafeLook == cafe,
                onSelected: (_) => notifier.chooseCafeLook(cafe),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.cardBorder,
          child: SizedBox(
            height: AppCorner.cafePreviewHeight,
            child: CustomPaint(
              key: ValueKey('corner-cafe-preview-${corner.cafeLook.name}'),
              size: Size.infinite,
              painter: corner.cafeLook == CafeLook.cosy
                  ? SeaCafePainter(isNight: isNight)
                  : CafeDioramaPainter(isNight: isNight),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: AppCorner.cardAspect,
          children: [
            for (final mascot in GretCornerCatalog.mascots)
              _CornerCard(
                key: ValueKey('corner-mascot-${mascot.species.name}'),
                preview: MascotView(
                  mood: MascotMood.happy,
                  size: AppCorner.cardMascot,
                  species: mascot.species,
                ),
                name: mascot.name,
                rarity: switch (mascot.unlock.kind) {
                  UnlockKind.free => Rarity.common,
                  UnlockKind.premium => Rarity.special,
                  _ => Rarity.rare,
                },
                status: corner.mascot == mascot.species
                    ? AppStrings.cornerChosen
                    : _statusOf(
                        mascot.unlock,
                        notifier.lockOf(mascot.unlock, id: mascot.id),
                        facts: facts,
                      ),
                highlighted: corner.mascot == mascot.species,
                onTap: () => _showSheet(
                  context,
                  // A friend already earned greets with love (spec 018).
                  preview: MascotView(
                    mood: notifier.lockOf(mascot.unlock, id: mascot.id) == CornerLock.none
                        ? MascotMood.love
                        : MascotMood.happy,
                    size: AppCorner.sheetMascot,
                    species: mascot.species,
                  ),
                  name: mascot.name,
                  detail: mascot.kind.isEmpty ? AppStrings.cornerTabMascots : mascot.kind,
                  action: Consumer(
                    builder: (context, ref, _) => _UnlockAction(
                      id: mascot.id,
                      name: mascot.name,
                      unlock: mascot.unlock,
                      inUse: ref.watch(gretCornerProvider).mascot == mascot.species,
                      useLabel: AppStrings.cornerChoose,
                      onUse: () async => notifier.chooseMascot(mascot.species),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static String _styleLabel(MascotStyle style) => switch (style) {
    MascotStyle.classic => AppStrings.styleClassic,
    MascotStyle.flat => AppStrings.styleFlat,
    MascotStyle.soft => AppStrings.styleSoft,
  };
}
