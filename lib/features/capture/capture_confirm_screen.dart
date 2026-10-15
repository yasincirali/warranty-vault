import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/brand_mark.dart';
import '../../core/ui/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../items/providers.dart';
import 'receipt_draft.dart';

final receiptReaderProvider = Provider<ReceiptReader>((_) => DemoReceiptReader());

// TODO(capture): camera + document edge detection; the draft below comes
// from DemoReceiptReader until `fis-oku` is wired.
final _draftProvider = FutureProvider.autoDispose<ReceiptDraft>(
    (ref) => ref.watch(receiptReaderProvider).read(const []));

/// "Doğru mu?": the reader's result is never saved without a look.
/// Unsure fields carry an icon and a sentence, not just a colour.
class CaptureConfirmScreen extends ConsumerWidget {
  const CaptureConfirmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final draft = ref.watch(_draftProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.c.background,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: VSpace.md),
          child: Center(child: VIconButton(icon: Icons.close, label: l.close, onPressed: () => Navigator.of(context).pop())),
        ),
      ),
      body: draft.when(
        loading: () => Center(child: VLoader(label: l.loading)),
        error: (_, _) => Center(child: Text(l.emptyTitle)),
        data: (d) => ListView(
          padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.sm, VSpace.xl, VSpace.xxl),
          children: [
            Semantics(header: true, child: Text(l.isItRight, style: context.t.title)),
            const SizedBox(height: VSpace.xs),
            Text(l.readFromInvoice, style: context.t.small.copyWith(color: context.c.textSecondary)),
            const SizedBox(height: VSpace.md),
            VCard(
              padding: const EdgeInsets.symmetric(horizontal: VSpace.lg),
              child: Column(children: [
                _FieldRow(label: l.fieldProduct, value: d.product.value, confidence: d.product.confidence),
                _FieldRow(label: l.fieldStore, value: d.store.value, confidence: d.store.confidence),
                _FieldRow(label: l.fieldDate, value: fmtDate(context, d.date.value), confidence: d.date.confidence),
                _FieldRow(label: l.fieldAmount, value: fmtMoney(context, d.amount.value), confidence: d.amount.confidence),
                if (d.serial != null)
                  _FieldRow(
                      label: l.fieldSerial,
                      value: d.serial!.value ?? '—',
                      confidence: d.serial!.confidence,
                      last: true),
              ]),
            ),
            const SizedBox(height: VSpace.md),
            Text(l.countryNote(d.region), style: context.t.small.copyWith(color: context.c.textSecondary)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.md, VSpace.xl, VSpace.md),
        child: Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => ref.invalidate(_draftProvider),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(VSize.button)),
              child: Text(l.retake),
            ),
          ),
          const SizedBox(width: VSpace.sm),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: draft.hasValue
                  ? () async {
                      await ref.read(vaultProvider.notifier).add(draft.requireValue.toItem());
                      ref.invalidate(itemViewsProvider);
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  : null,
              child: Text(l.save),
            ),
          ),
        ]),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value, required this.confidence, this.last = false});
  final String label;
  final String value;
  final double confidence;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final unsure = confidence < ReceiptDraft.sureThreshold;
    return Semantics(
      label: unsure ? '$label: $value. ${l.checkThis}' : '$label: $value',
      button: true,
      excludeSemantics: true,
      child: InkWell(
        // TODO(capture): inline edit sheet per field.
        onTap: () {},
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(vertical: VSpace.sm + 2),
          decoration: BoxDecoration(
            border: last ? null : Border(bottom: BorderSide(color: context.c.divider)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: context.t.small.copyWith(color: context.c.textSecondary)),
                Text(value, style: context.t.label),
                if (unsure)
                  Text(l.checkThis, style: context.t.small.copyWith(color: context.c.deadline)),
              ]),
            ),
            if (unsure) Icon(Icons.help_outline, color: context.c.deadline, size: 20),
          ]),
        ),
      ),
    );
  }
}
