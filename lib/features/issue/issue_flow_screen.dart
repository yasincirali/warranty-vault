import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/ui/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../rights/advice.dart';
import '../items/providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(itemViewProvider(widget.itemId)).value;
    final today = ref.watch(clockProvider)();
    if (view == null) return const Scaffold();

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
                for (final (n, s) in [l.stepDocsReady, l.stepAddEvidence, l.stepWeDraft].indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: VSpace.xs),
                    child: Text('${n + 1}. $s', style: context.t.small),
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
              child: FilledButton(onPressed: () {}, child: Text(l.continueButton)),
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
