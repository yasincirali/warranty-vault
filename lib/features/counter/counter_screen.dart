import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../rights/rights_engine.dart';
import '../items/domain/item.dart';
import '../items/providers.dart';
import '../items/ui/documents.dart';

/// "Kasada göster": the screen you turn towards the shop assistant.
/// Review round 1: the most common real moment is standing at a counter
/// without the paper receipt. Big, high-contrast facts, one sentence of the
/// right, the invoice image. Nothing to tap through.
///
/// TODO(counter): the sentence in the seller's language (needs per-region
/// strings) and raising screen brightness (needs a platform plugin).
class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(itemViewProvider(itemId)).value;
    if (view == null) return const Scaffold();
    final item = view.item;
    final p = view.primary;
    final active = p != null && p.status == ProtectionStatus.active && p.end != null;
    final claimable = active && (p.kind == ProtectionKind.legal || p.kind == ProtectionKind.manufacturer || p.kind == ProtectionKind.extended);

    final facts = [
      (l.fieldDate, fmtDate(context, item.purchase.date)),
      if (item.price != null) (l.fieldAmount, fmtMoney(context, item.price!)),
      if (item.serial != null) (l.fieldSerial, item.serial!),
    ];
    final big = context.t.label.copyWith(fontSize: 19, fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()]);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.c.background,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: VSpace.md),
          child: Center(child: VIconButton(icon: Icons.close, label: l.close, onPressed: () => Navigator.of(context).pop())),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.sm, VSpace.xl, VSpace.xxl),
        children: [
          Text('${l.counterTitle} · ${item.store}', style: context.t.section.copyWith(color: context.c.textSecondary)),
          const SizedBox(height: VSpace.xs),
          Semantics(header: true, child: Text(item.name, style: context.t.display.copyWith(fontSize: 28))),
          const SizedBox(height: VSpace.lg),
          VCard(
            padding: const EdgeInsets.symmetric(horizontal: VSpace.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final (i, f) in facts.indexed)
                Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  decoration: BoxDecoration(
                    border: i == facts.length - 1 ? null : Border(bottom: BorderSide(color: context.c.divider)),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: VSpace.md,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: VSpace.xs,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: VSpace.md),
                        child: Text(f.$1, style: context.t.body.copyWith(color: context.c.textSecondary)),
                      ),
                      Text(f.$2, style: big),
                    ],
                  ),
                ),
            ]),
          ),
          if (claimable) ...[
            const SizedBox(height: VSpace.md),
            VCard(
              padding: const EdgeInsets.all(VSpace.lg),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: l.counterRight(kindLabel(l, p.kind), fmtDate(context, p.end!)),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' ${l.counterAsk}'),
                ]),
                style: context.t.body.copyWith(fontSize: 16),
              ),
            ),
          ],
          const SizedBox(height: VSpace.md),
          _Receipt(item: item),
        ],
      ),
    );
  }
}

/// The stored receipt, big enough to read across a counter; a tap opens it
/// full screen to zoom in on the date or the serial. Without one the
/// placeholder says so instead of leaving an empty frame.
class _Receipt extends ConsumerWidget {
  const _Receipt({required this.item});
  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final doc = item.receipt;
    if (doc == null || doc.isPdf) {
      return Semantics(
        button: doc != null,
        child: InkWell(
          borderRadius: BorderRadius.circular(VRadius.lg),
          onTap: doc == null ? null : () => openDoc(context, ref, item, doc),
          child: Container(
            height: 150,
            decoration: BoxDecoration(color: context.c.tile, borderRadius: BorderRadius.circular(VRadius.lg)),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(doc == null ? Icons.description_outlined : Icons.picture_as_pdf_outlined,
                  size: 18, color: context.c.textSecondary),
              const SizedBox(width: VSpace.sm),
              Flexible(
                child: Text(doc == null ? l.counterNoInvoice : l.counterOpenPdf,
                    style: context.t.label.copyWith(color: context.c.textSecondary)),
              ),
            ]),
          ),
        ),
      );
    }
    final store = ref.watch(vaultStoreProvider);
    final w = MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context);
    return Semantics(
      button: true,
      label: l.counterReceiptA11y,
      child: GestureDetector(
        onTap: () => openDoc(context, ref, item, doc),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(VRadius.lg),
          child: Image(
            // Screen width is all it is ever drawn at.
            image: ResizeImage(store.photo(doc.path), width: w.round(), policy: ResizeImagePolicy.fit),
            fit: BoxFit.fitWidth,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
