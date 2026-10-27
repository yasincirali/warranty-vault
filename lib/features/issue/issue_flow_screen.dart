import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/ui/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../rights/advice.dart';
import '../counter/counter_screen.dart';
import '../items/domain/item.dart';
import '../items/providers.dart';
import '../items/ui/documents.dart';

/// "Bir sorun var": ask one question, give one recommended path.
/// The user never has to learn consumer law; the engine picks the
/// strongest, cheapest remedy and says why in one sentence.
class IssueFlowScreen extends ConsumerStatefulWidget {
  const IssueFlowScreen({super.key, required this.itemId});
  final String itemId;

  @override
  ConsumerState<IssueFlowScreen> createState() => _IssueFlowScreenState();
}

class _IssueFlowScreenState extends ConsumerState<IssueFlowScreen> {
  IssueType _issue = IssueType.defect;

  /// Papers the product had when the flow opened; what is added here on top
  /// is the evidence step done.
  int? _docsAtOpen;

  Future<void> _addEvidence() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final c = ProviderScope.containerOf(context, listen: false);
    final source = await showModalBottomSheet<DocSource>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(VSpace.xl, 0, VSpace.xl, VSpace.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SectionTitle(l.stepEvidenceAdd),
            Text(l.stepEvidence, style: sheet.t.small.copyWith(color: sheet.c.textSecondary)),
            const SizedBox(height: VSpace.lg),
            ...docSourceButtons(sheet, l, pdf: false),
          ]),
        ),
      ),
    );
    if (source == null || !mounted) return;
    await saveDoc(c, messenger, l, widget.itemId, DocKind.other, source, announce: false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(itemViewProvider(widget.itemId)).value;
    final today = ref.watch(clockProvider)();
    if (view == null) return const Scaffold();
    _docsAtOpen ??= view.item.documents.length;
    final added = view.item.documents.length - _docsAtOpen!;

    final advice = adviseFor(_issue, view.protections, today);
    final store = view.item.store;
    final text = switch (advice.action) {
      AdviceAction.returnItem => l.adviceReturn(store),
      AdviceAction.rejectGoods => l.adviceReject(store),
      AdviceAction.askSellerRepair => l.adviceSellerRepair(store),
      AdviceAction.askManufacturer => l.adviceManufacturer,
      AdviceAction.checkLocalRules => l.adviceCheckLocal,
      AdviceAction.insurance => l.adviceInsurance,
      AdviceAction.notCovered => l.adviceNotCovered,
    };
    final claim = switch (advice.action) {
      AdviceAction.returnItem ||
      AdviceAction.rejectGoods ||
      AdviceAction.askSellerRepair ||
      AdviceAction.askManufacturer => true,
      _ => false,
    };

    final options = {
      IssueType.defect: l.issueDefect,
      IssueType.arrivedDamaged: l.issueDamaged,
      IssueType.notAsDescribed: l.issueNotAsDescribed,
      IssueType.lostOrStolen: l.issueLost,
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.c.background,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: VSpace.md),
          child: Center(child: VIconButton(icon: Icons.close, label: l.close, onPressed: () => Navigator.of(context).pop())),
        ),
        title: Text(view.item.name, style: context.t.small.copyWith(color: context.c.textSecondary)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.sm, VSpace.xl, VSpace.xxl),
        children: [
          Semantics(header: true, child: Text(l.whatHappened, style: context.t.title)),
          const SizedBox(height: VSpace.md),
          VCard(
            padding: const EdgeInsets.symmetric(horizontal: VSpace.lg),
            child: Column(children: [
              for (final (i, e) in options.entries.indexed)
                _RadioRow(
                  label: e.value,
                  selected: _issue == e.key,
                  last: i == options.length - 1,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _issue = e.key);
                  },
                ),
            ]),
          ),
          const SizedBox(height: VSpace.md),
          // 2-pt ink frame, not a tinted fill (review round 3): "this is the answer".
          VCard(
            color: context.c.adviceSurface,
            borderColor: context.c.adviceBorder,
            borderWidth: 2,
            padding: const EdgeInsets.all(VSpace.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.recommended, style: context.t.section.copyWith(color: context.c.adviceTitle)),
              const SizedBox(height: VSpace.sm - 2),
              Text(text, style: context.t.body),
              if (advice.sellerBearsProof != null) ...[
                const SizedBox(height: VSpace.sm),
                Text(advice.sellerBearsProof! ? l.proofSeller : l.proofBuyer,
                    style: context.t.small.copyWith(color: context.c.textSecondary)),
              ],
              if (claim) ...[
                const SizedBox(height: VSpace.md),
                // Only steps the app really does (Rafım Ar-Ge 24 Oct): "we write
                // the message" waits for the claim assistant, it is not promised.
                // The first step is done here, not described (27 Oct, yasin
                // "yap"): the photo lands in the product's papers; the second
                // is the button below.
                _EvidenceStep(added: added, onTap: _addEvidence),
                Padding(
                  padding: const EdgeInsets.only(top: VSpace.sm, bottom: VSpace.xs),
                  child: Text('2. ${l.stepShowProof}', style: context.t.small),
                ),
                // Review round 1: "what if they say no?" answered up front.
                Container(
                  margin: const EdgeInsets.only(top: VSpace.sm),
                  padding: const EdgeInsets.only(top: VSpace.sm + 2),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: context.c.divider))),
                  child: Text(l.adviceIfRefused, style: context.t.small.copyWith(color: context.c.textSecondary)),
                ),
              ],
            ]),
          ),
        ],
      ),
      bottomNavigationBar: claim
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.md, VSpace.xl, VSpace.md),
              // The proof the seller asks for, ready to hand over the counter.
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => CounterScreen(itemId: widget.itemId),
                )),
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: Text(l.showAtCounter),
              ),
            )
          : null,
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({required this.label, required this.selected, required this.last, required this.onTap});
  final String label;
  final bool selected;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              border: last ? null : Border(bottom: BorderSide(color: context.c.divider)),
            ),
            child: Row(children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: VSpace.md),
                  child: Text(label,
                      style: context.t.body.copyWith(fontWeight: selected ? FontWeight.w600 : null)),
                ),
              ),
              ExcludeSemantics(
                child: Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selected ? context.c.accent : context.c.muted,
                ),
              ),
            ]),
          ),
        ),
      );
}

/// Step 1 as a row the user acts on. Done is said in words and with a
/// check, not only by colour.
class _EvidenceStep extends StatelessWidget {
  const _EvidenceStep({required this.added, required this.onTap});
  final int added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final done = added > 0;
    return Semantics(
      button: true,
      label: done ? '${l.stepEvidenceAdd}. ${l.stepEvidenceDone(added)}' : l.stepEvidenceAdd,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.sm),
        child: Container(
          constraints: const BoxConstraints(minHeight: VSize.minTap + 4),
          padding: const EdgeInsets.symmetric(horizontal: VSpace.md, vertical: VSpace.sm),
          decoration: BoxDecoration(
            color: context.c.surface,
            border: Border.all(color: context.c.border),
            borderRadius: BorderRadius.circular(VRadius.sm),
          ),
          child: Row(children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: context.c.tile, borderRadius: BorderRadius.circular(VRadius.sm - 2)),
              child: done
                  ? Icon(Icons.check, size: 16, color: context.c.text)
                  : Text('1', style: context.t.small.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: VSpace.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.stepEvidenceAdd, style: context.t.label),
                if (done) Text(l.stepEvidenceDone(added), style: context.t.small.copyWith(color: context.c.textSecondary)),
              ]),
            ),
            const SizedBox(width: VSpace.sm),
            Text(l.stepEvidenceButton, style: context.t.label.copyWith(decoration: TextDecoration.underline)),
          ]),
        ),
      ),
    );
  }
}
