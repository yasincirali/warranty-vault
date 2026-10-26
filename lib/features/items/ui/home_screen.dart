import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/widgets.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cabinet/cabinet_view.dart';
import '../../capture/add_item_screen.dart';
import '../../capture/after_save.dart';
import '../../search/search_screen.dart';
import '../../settings/settings_screen.dart';
import '../domain/item.dart';
import '../providers.dart';
import 'item_detail_screen.dart';
import 'item_photo.dart';

/// One screen, two questions answered in order:
/// 1. "Is anything about to run out?" → İlgilen (only when there is something)
/// 2. "What do I own?" → the cabinet (Tur 5): the user's own products,
///    photographed and standing on shelves they name themselves.
/// The most frequent action (adding a product) sits in the thumb zone.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final vault = ref.watch(vaultProvider).value;
    final views = ref.watch(itemViewsProvider).value;
    final today = ref.watch(clockProvider)();

    if (vault == null || views == null) {
      // BrandIntro covers this moment; an empty page keeps a second loader
      // from flashing underneath it.
      return const Scaffold(body: SizedBox.shrink());
    }
    final byId = {for (final v in views) v.item.id: v};
    final active = [for (final v in views) if (v.item.active) v];
    final urgent = active.where((v) => v.next != null).toList()
      ..sort((a, b) => a.next!.daysLeft(today)!.compareTo(b.next!.daysLeft(today)!));
    final disposed = vault.disposed;

    void discard(String id) {
      final name = byId[id]?.item.name ?? '';
      ref.read(vaultProvider.notifier).discard(id);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l.thrownOut(name)),
          action: SnackBarAction(label: l.undo, onPressed: () => ref.read(vaultProvider.notifier).restore(id)),
        ));
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          // Scrolling ends any typing (a shelf label) and drops the keyboard.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.lg, VSpace.xl, 0),
            sliver: SliverToBoxAdapter(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Semantics(header: true, child: Text(l.appTitle, style: context.t.display)),
                    if (active.isNotEmpty)
                      Text(l.cabinetCount(active.length),
                          style: context.t.small.copyWith(color: context.c.textSecondary)),
                  ]),
                ),
                if (active.isNotEmpty) ...[
                  VIconButton(
                    icon: Icons.search,
                    label: l.searchTitle,
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const SearchScreen())),
                  ),
                  const SizedBox(width: VSpace.sm),
                ],
                VIconButton(
                  icon: Icons.settings_outlined,
                  label: l.settingsTitle,
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ]),
            ),
          ),
          if (active.isEmpty && disposed.isEmpty)
            SliverToBoxAdapter(child: _Empty(l: l)),
          if (urgent.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.xl, VSpace.xl, 0),
              sliver: SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SectionTitle(l.attentionHeader(urgent.length)),
                  VCard(
                    padding: const EdgeInsets.symmetric(horizontal: VSpace.lg - 2),
                    child: Column(children: [
                      for (var i = 0; i < urgent.length; i++)
                        _AttentionRow(view: urgent[i], today: today, last: i == urgent.length - 1),
                    ]),
                  ),
                ]),
              ),
            ),
          if (active.isNotEmpty || disposed.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.xl, VSpace.xl, VSpace.xs),
              sliver: SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SectionTitle(l.allHeader(active.length)),
                  // The two gestures, said once in plain words; there is no
                  // tutorial to dismiss.
                  Text(l.cabinetHint, style: context.t.small.copyWith(color: context.c.textSecondary)),
                  // One quiet line while samples stand on the shelves; no
                  // dialog when the first own product arrives (it would
                  // interrupt the moment the user came for). Wrap, not Row:
                  // at 3.1× text the button drops under the sentence.
                  if (active.any((v) => v.item.sample))
                    Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text(l.samplesNote, style: context.t.small.copyWith(color: context.c.textSecondary)),
                      TextButton(
                        // Flush with the sentence above; 44 pt stays the tap height.
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(44, 44)),
                        onPressed: () => ref.read(vaultProvider.notifier).removeSamples(),
                        child: Text(l.samplesRemove),
                      ),
                    ]),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: LayoutBuilder(
                // iPad: the cabinet keeps phone proportions instead of
                // stretching four products across 1000 pt.
                builder: (context, box) {
                  final w = box.maxWidth > 560 ? 560.0 : box.maxWidth;
                  return Center(
                    child: CabinetView(
                      vault: vault,
                      views: byId,
                      today: today,
                      width: w,
                      onOpen: (id) => _openItem(context, id),
                      onDiscard: discard,
                    ),
                  );
                },
              ),
            ),
          ],
          if (disposed.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.lg, VSpace.xl, 0),
              sliver: SliverToBoxAdapter(child: _DisposedRow(items: disposed)),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.md, VSpace.xl, VSpace.md),
        child: FilledButton.icon(
          onPressed: () => _add(context),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(l.addItem),
        ),
      ),
    );
  }
}

void _openItem(BuildContext context, String id) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: id)));

Future<void> _add(BuildContext context) async {
  // Held now: the empty cabinet that opened the add screen is gone once
  // its first product lands, the navigator and the container are not.
  final nav = Navigator.of(context);
  final c = ProviderScope.containerOf(context, listen: false);
  final id = await nav.push<String>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => const AddItemScreen(),
  ));
  if (id != null) await afterSave(nav, c, id);
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.view, required this.today, required this.last});
  final ItemView view;
  final DateTime today;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final next = view.next!;
    return InkWell(
      onTap: () => _openItem(context, view.item.id),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: VSpace.sm + 2),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: context.c.divider)),
        ),
        child: Row(children: [
          ItemPhoto(item: view.item),
          const SizedBox(width: VSpace.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(view.item.name, style: context.t.label),
              // A sentence, not a badge: readable without colour.
              Text(l.endsIn(kindLabel(l, next.kind), next.daysLeft(today)!),
                  style: context.t.small.copyWith(color: context.c.deadline)),
            ]),
          ),
          Icon(Icons.chevron_right, color: context.c.muted, size: 20),
        ]),
      ),
    );
  }
}

/// Thrown-out things are not deleted: one row opens the list, each can go
/// back on its shelf.
class _DisposedRow extends ConsumerWidget {
  const _DisposedRow({required this.items});
  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(VRadius.sm),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheet) => Consumer(
          builder: (sheet, ref, _) {
            final gone = ref.watch(vaultProvider).value?.disposed ?? const <Item>[];
            return SafeArea(
              child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(VSpace.xl, 0, VSpace.xl, VSpace.lg), children: [
                SectionTitle(l.disposedHeader(gone.length)),
                for (final item in gone)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: VSpace.xs),
                    child: Row(children: [
                      ItemPhoto(item: item),
                      const SizedBox(width: VSpace.md),
                      Expanded(child: Text(item.name, style: context.t.label)),
                      TextButton(
                        onPressed: () => ref.read(vaultProvider.notifier).restore(item.id),
                        child: Text(l.putBack),
                      ),
                    ]),
                  ),
              ]),
            );
          },
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: VSize.minTap),
        alignment: Alignment.centerLeft,
        child: Row(children: [
          Icon(Icons.delete_outline, size: 20, color: context.c.textSecondary),
          const SizedBox(width: VSpace.sm),
          Expanded(child: Text(l.disposedHeader(items.length), style: context.t.label.copyWith(color: context.c.textSecondary))),
          Icon(Icons.chevron_right, color: context.c.muted, size: 20),
        ]),
      ),
    );
  }
}

/// First run: the empty cabinet itself, so the first screen already shows
/// what the app is (UX defteri 26 Ekim). One way in, the "Add product"
/// button below (the dashed place on the shelf does the same); the camera
/// or gallery choice comes on the add screen, not here. The sample cabinet
/// is a quiet link for someone who wants to try the shelves first.
class _Empty extends ConsumerWidget {
  const _Empty({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: VSpace.xxl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.xl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.emptyCabinetTitle, style: context.t.title),
            const SizedBox(height: VSpace.sm),
            Text(l.emptyCabinetBody, style: context.t.body.copyWith(color: context.c.textSecondary)),
          ]),
        ),
        const SizedBox(height: VSpace.xl),
        LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth > 560 ? 560.0 : box.maxWidth;
            return Center(child: EmptyCabinet(width: w, onAdd: () => _add(context)));
          },
        ),
        const SizedBox(height: VSpace.sm),
        Center(
          child: TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            onPressed: () => ref.read(vaultProvider.notifier).loadSample(desk: l.sampleDesk, living: l.sampleLiving, kitchen: l.sampleKitchen),
            child: Text(l.sampleTry),
          ),
        ),
      ]),
    );
  }
}
