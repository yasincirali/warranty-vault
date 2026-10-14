import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/widgets.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../rights/rights_engine.dart';
import '../../capture/capture_confirm_screen.dart';
import '../domain/item.dart';
import '../providers.dart';
import 'item_detail_screen.dart';

/// One screen, two questions answered in order:
/// 1. "Is anything about to run out?" → İlgilen (only when there is something)
/// 2. "What do I own?" → the grid
/// The most frequent action (adding a receipt) sits in the thumb zone.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final views = ref.watch(itemViewsProvider);
    final today = ref.watch(clockProvider)();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: views.when(
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (e, _) => Center(child: Text(l.emptyTitle)),
          data: (all) {
            final urgent = all.where((v) => v.next != null).toList()
              ..sort((a, b) => a.next!.daysLeft(today)!.compareTo(b.next!.daysLeft(today)!));
            return CustomScrollView(slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.lg, VSpace.xl, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(l.appTitle, style: context.t.display),
                      ),
                    ),
                    VIconButton(icon: Icons.search, label: l.searchItems, onPressed: () {}),
                  ]),
                ),
              ),
              if (all.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _Empty(l: l)),
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
              if (all.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.xl, VSpace.xl, VSpace.sm),
                  sliver: SliverToBoxAdapter(child: SectionTitle(l.allHeader(all.length))),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: VSpace.xl),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: VSpace.md - 2,
                    crossAxisSpacing: VSpace.md - 2,
                    // Grows with Dynamic Type instead of clipping the text.
                    mainAxisExtent: 96 + VSpace.xl + MediaQuery.textScalerOf(context).scale(64),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ItemTile(view: all[i], today: today),
                    childCount: all.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ]);
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.md, VSpace.xl, VSpace.md),
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const CaptureConfirmScreen(),
          )),
          icon: const Icon(Icons.document_scanner_outlined),
          label: Text(l.addReceipt),
        ),
      ),
    );
  }
}

void _openItem(BuildContext context, String id) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: id)));

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
          ItemThumb(view.item.category),
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

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.view, required this.today});
  final ItemView view;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = view.primary;
    final active = p != null && p.status == ProtectionStatus.active;
    final status = !active
        ? l.protectionEnded
        : l.statusLine(kindLabel(l, p.kind),
            p.end == null ? l.noFixedEnd : remainingLabel(l, today, p.end!));
    final color = !active
        ? context.c.muted
        : (view.next != null ? context.c.deadline : context.c.text);

    return Material(
      color: context.c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VRadius.lg),
        side: BorderSide(color: context.c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openItem(context, view.item.id),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            height: 96,
            color: context.c.tile,
            alignment: Alignment.center,
            child: ExcludeSemantics(
              child: Icon(ItemThumb.iconFor(view.item.category), size: 44, color: context.c.text),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(VSpace.md, VSpace.sm + 2, VSpace.md, VSpace.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(view.item.name, style: context.t.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(status, style: context.t.small.copyWith(color: color), maxLines: 2),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(VSpace.xxl),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(l.emptyTitle, style: context.t.title, textAlign: TextAlign.center),
          const SizedBox(height: VSpace.sm),
          Text(l.emptyBody,
              style: context.t.body.copyWith(color: context.c.textSecondary),
              textAlign: TextAlign.center),
        ]),
      );
}
