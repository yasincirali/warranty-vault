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
    final big = context.t.counterFact;

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
          Text('${item.receipt == null ? l.counterTitleNoProof : l.counterTitle} · ${item.store}', style: context.t.section.copyWith(color: context.c.textSecondary)),
          const SizedBox(height: VSpace.xs),
          Semantics(header: true, child: Text(item.name, style: context.t.counterName)),
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
                style: context.t.bodyLarge,
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
    if (doc == null) return _AddProof(itemId: item.id);
    if (doc.isPdf) {
      return Semantics(
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(VRadius.lg),
          onTap: () => openDoc(context, ref, item, doc),
          child: Container(
            height: 150,
            decoration: BoxDecoration(color: context.c.tile, borderRadius: BorderRadius.circular(VRadius.lg)),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.picture_as_pdf_outlined, size: 18, color: context.c.textSecondary),
              const SizedBox(width: VSpace.sm),
              Flexible(
                child: Text(l.counterOpenPdf,
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

/// No receipt yet (Rafım Ar-Ge 28 Oct): a dashed frame that adds one,
/// instead of a grey box that only said so. At the counter people mostly
/// have a screenshot or an order email already, so the gallery comes first.
/// Saved as the receipt; the screen rebuilds with it in this same place.
class _AddProof extends ConsumerWidget {
  const _AddProof({required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    Future<void> add(DocSource source) => saveDoc(
          ProviderScope.containerOf(context, listen: false),
          ScaffoldMessenger.of(context),
          l,
          itemId,
          DocKind.receipt,
          source,
          announce: false,
        );
    return CustomPaint(
      painter: _Dashed(context.c.muted),
      child: Padding(
        padding: const EdgeInsets.all(VSpace.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Semantics(header: true, child: Text(l.counterAddProof, style: context.t.label, textAlign: TextAlign.center)),
          const SizedBox(height: VSpace.xs),
          Text(l.counterProofHint, style: context.t.small.copyWith(color: context.c.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: VSpace.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: VSpace.sm,
            runSpacing: VSpace.sm,
            children: [
              for (final (s, icon, label) in [
                (DocSource.gallery, Icons.photo_library_outlined, l.docFromGallery),
                (DocSource.camera, Icons.photo_camera_outlined, l.docFromCamera),
                (DocSource.pdf, Icons.picture_as_pdf_outlined, l.docFromFile),
              ])
                OutlinedButton.icon(
                  onPressed: () => add(s),
                  icon: Icon(icon, size: 18),
                  label: Text(label),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(VSize.minTap, VSize.minTap),
                    foregroundColor: context.c.text,
                    backgroundColor: context.c.surface,
                    side: BorderSide(color: context.c.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.md)),
                  ),
                ),
            ],
          ),
        ]),
      ),
    );
  }
}

class _Dashed extends CustomPainter {
  const _Dashed(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(VRadius.lg)));
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Dashed old) => old.color != color;
}
