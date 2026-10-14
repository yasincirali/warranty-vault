import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/time_rule.dart';
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
                    mainAxisExtent: 84 + VSpace.xl + 12 + MediaQuery.textScalerOf(context).scale(64),
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
          Stack(children: [
            Container(
              height: 84,
              color: context.c.tile,
              alignment: Alignment.center,
              child: ExcludeSemantics(
                child: Icon(ItemThumb.iconFor(view.item.category), size: 40, color: context.c.text),
              ),
            ),
            // Review round 2: whose rules apply, visible before opening.
            Positioned(
              top: VSpace.sm,
              right: VSpace.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.c.surface,
                  border: Border.all(color: context.c.border),
                  borderRadius: BorderRadius.circular(VRadius.sm - 2),
                ),
                child: Text(view.item.purchase.region,
                    semanticsLabel: regionName(l, view.item.purchase.region),
                    style: context.t.small.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.c.textSecondary)),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(VSpace.md, VSpace.sm + 2, VSpace.md, VSpace.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(view.item.name, style: context.t.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(status, style: context.t.small.copyWith(color: color), maxLines: 2),
              if (p != null) ...[
                const SizedBox(height: VSpace.sm),
                TimeRule(protection: p, today: today, urgent: view.next != null, compact: true),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

/// First run (review round 4): not an empty grid but the ways in, why the
/// photo matters, and a preview of the one graphic the user will get.
class _Empty extends StatelessWidget {
  const _Empty({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    void capture() => Navigator.of(context).push(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const CaptureConfirmScreen(),
        ));
    // TODO(capture): PDF picker; email forwarding row once inbound mail exists.
    final ways = [
      (Icons.document_scanner_outlined, l.wayPhoto, l.wayPhotoWhy),
      (Icons.description_outlined, l.wayPdf, l.wayPdfWhy),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.xxl, VSpace.xl, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.emptyTitle, style: context.t.title),
        const SizedBox(height: VSpace.sm),
        Text(l.emptyBody, style: context.t.body.copyWith(color: context.c.textSecondary)),
        const SizedBox(height: VSpace.xl),
        VCard(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.lg),
          child: Column(children: [
            for (final (i, w) in ways.indexed)
              InkWell(
                onTap: capture,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.symmetric(vertical: VSpace.md),
                  decoration: BoxDecoration(
                    border: i == ways.length - 1 ? null : Border(bottom: BorderSide(color: context.c.divider)),
                  ),
                  child: Row(children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: context.c.tile, borderRadius: BorderRadius.circular(VRadius.sm)),
                        child: Icon(w.$1, size: 20, color: context.c.text),
                      ),
                    ),
                    const SizedBox(width: VSpace.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(w.$2, style: context.t.label),
                        Text(w.$3, style: context.t.small.copyWith(color: context.c.textSecondary)),
                      ]),
                    ),
                    Icon(Icons.chevron_right, color: context.c.muted, size: 20),
                  ]),
                ),
              ),
          ]),
        ),
        const SizedBox(height: VSpace.lg),
        Container(
          padding: const EdgeInsets.all(VSpace.lg),
          decoration: BoxDecoration(
            border: Border.all(color: context.c.border),
            borderRadius: BorderRadius.circular(VRadius.lg),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.previewTitle, style: context.t.section.copyWith(color: context.c.textSecondary)),
            const SizedBox(height: VSpace.md),
            const _PreviewRule(),
            const SizedBox(height: VSpace.md),
            Text(l.previewBody, style: context.t.small.copyWith(color: context.c.textSecondary)),
          ]),
        ),
      ]),
    );
  }
}

/// A static sample of the time rule; decorative, so hidden from screen readers.
class _PreviewRule extends StatelessWidget {
  const _PreviewRule();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) => SizedBox(
            height: 16,
            child: Stack(alignment: Alignment.centerLeft, children: [
              Container(height: 6, decoration: BoxDecoration(color: context.c.track, borderRadius: BorderRadius.circular(3))),
              Container(
                width: box.maxWidth * .4,
                height: 6,
                decoration: BoxDecoration(color: context.c.text.withValues(alpha: .22), borderRadius: BorderRadius.circular(3)),
              ),
              Positioned(left: box.maxWidth * .5 - 1, child: Container(width: 2, height: 14, color: context.c.text)),
              Positioned(
                left: box.maxWidth * .4 - 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: context.c.surface,
                    shape: BoxShape.circle,
                    border: Border.all(width: 3, color: context.c.textSecondary),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
}
