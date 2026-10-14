import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/time_rule.dart';
import '../../../core/ui/widgets.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../rights/rights_engine.dart';
import '../../counter/counter_screen.dart';
import '../../issue/issue_flow_screen.dart';
import '../domain/item.dart';
import '../providers.dart';

/// Answer first: the top card says where the user stands today in one
/// number and one sentence. The list below is the evidence for it.
class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final view = ref.watch(itemViewProvider(itemId)).value;
    final today = ref.watch(clockProvider)();

    if (view == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));
    }
    final item = view.item;
    final meta = [
      item.store,
      fmtDate(context, item.purchase.date),
      if (item.price != null) fmtMoney(context, item.price!),
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.c.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          VIconButton(icon: Icons.edit_outlined, label: l.edit, onPressed: () {}),
          const SizedBox(width: VSpace.md),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(VSpace.xl, 0, VSpace.xl, VSpace.xxl),
        children: [
          Row(children: [
            ItemThumb(item.category, size: 72, iconSize: 40),
            const SizedBox(width: VSpace.lg - 2),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Semantics(header: true, child: Text(item.name, style: context.t.title)),
                Text(meta, style: context.t.small.copyWith(color: context.c.textSecondary)),
                // Review round 2: people move and buy abroad; say whose rules apply.
                const SizedBox(height: VSpace.xs + 2),
                _Chip(l.rulesOf(regionName(l, item.purchase.region))),
              ]),
            ),
          ]),
          const SizedBox(height: VSpace.lg + 2),
          _AnswerCard(view: view, today: today),
          const SizedBox(height: VSpace.md),
          VCard(
            padding: const EdgeInsets.symmetric(horizontal: VSpace.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < view.protections.length; i++)
                _ProtectionRow(
                  p: view.protections[i],
                  today: today,
                  urgent: identical(view.protections[i], view.next),
                  last: i == view.protections.length - 1,
                ),
            ]),
          ),
          const SizedBox(height: VSpace.md),
          // One strong action instead of two small shortcuts (review round 1):
          // the moment that matters is showing proof to someone else.
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => CounterScreen(itemId: itemId),
            )),
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: Text(l.showAtCounter),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(VSize.button),
              foregroundColor: context.c.text,
              backgroundColor: context.c.surface,
              side: BorderSide(color: context.c.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.md)),
            ),
          ),
          const SizedBox(height: VSpace.lg),
          Text(l.disclaimer, style: context.t.small.copyWith(color: context.c.textSecondary)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.md, VSpace.xl, VSpace.md),
        child: FilledButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => IssueFlowScreen(itemId: itemId),
          )),
          child: Text(l.problemButton),
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.view, required this.today});
  final ItemView view;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = view.primary;
    final active = p != null && p.status == ProtectionStatus.active;
    final unverifiedOnly = p != null && p.status == ProtectionStatus.unverified;

    final String body;
    if (unverifiedOnly) {
      body = l.answerUnverified;
    } else if (!active) {
      body = l.answerNone;
    } else {
      body = switch (p.kind) {
        ProtectionKind.returnWindow => l.answerReturn,
        ProtectionKind.shortTermReject => l.answerReject,
        ProtectionKind.manufacturer => l.answerManufacturer,
        ProtectionKind.extended => l.answerExtended,
        ProtectionKind.legal => l.answerLegal,
      };
    }
    final urgent = view.next != null;
    // Under 60 days the number alone is the answer ("28" + "days left");
    // longer periods keep their units ("1 yıl 7 ay" + "kaldı").
    final days = active && p.end != null ? dateOnly(p.end!).difference(dateOnly(today)).inDays : null;
    final shortCount = days != null && days < 60;
    final big = !active
        ? null
        : p.end == null
            ? l.noFixedEnd
            : shortCount
                ? '$days'
                : remainingLabel(l, today, p.end!);
    final unit = days == null ? null : (shortCount ? l.daysLeft(days) : l.left);

    return VCard(
      padding: const EdgeInsets.all(VSpace.lg + 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.todayStatus, style: context.t.section.copyWith(color: context.c.textSecondary)),
        if (big != null) ...[
          const SizedBox(height: VSpace.sm - 2),
          // Number big, unit small (review round 3); Wrap so 3× text never clips.
          Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: VSpace.sm, children: [
            Text(big, style: context.t.bigNumber.copyWith(color: urgent ? context.c.deadline : context.c.text)),
            if (unit != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: context.t.bigUnit.copyWith(color: urgent ? context.c.deadline : context.c.text)),
              ),
          ]),
          Text(kindLabel(l, p!.kind), style: context.t.label),
          if (p.end != null) ...[
            const SizedBox(height: VSpace.lg),
            TimeRule(protection: p, today: today, urgent: urgent),
          ],
        ],
        const SizedBox(height: VSpace.sm),
        Text(body, style: context.t.body),
        if (p != null && p.sources.isNotEmpty)
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, VSize.minTap),
              alignment: Alignment.centerLeft,
            ),
            onPressed: () {},
            child: Text(l.whereFrom),
          ),
      ]),
    );
  }
}

class _ProtectionRow extends StatelessWidget {
  const _ProtectionRow({required this.p, required this.today, required this.urgent, required this.last});
  final Protection p;
  final DateTime today;
  final bool urgent;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final active = p.status == ProtectionStatus.active;
    final right = switch (p.status) {
      ProtectionStatus.unverified => l.notVerified,
      ProtectionStatus.ended => l.endedOn(fmtDate(context, p.end!)),
      ProtectionStatus.active =>
        p.end == null ? l.noFixedEnd : l.endsOn(fmtDate(context, p.end!)),
    };
    final color = urgent
        ? context.c.deadline
        : (active ? context.c.text : context.c.textSecondary);

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: context.c.divider)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: VSpace.md,
        runSpacing: VSpace.xs,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: VSpace.md),
            child: Text(kindLabel(l, p.kind),
                style: active ? context.t.label : context.t.body.copyWith(color: context.c.textSecondary)),
          ),
          Text(right,
              style: context.t.small.copyWith(color: color, fontWeight: urgent ? FontWeight.w600 : null)),
          // Review round 2: an unverified rule says why there is no date,
          // instead of leaving an empty cell the user reads as "no right".
          if (p.status == ProtectionStatus.unverified)
            Padding(
              padding: const EdgeInsets.only(bottom: VSpace.md),
              child: Text(l.notVerifiedWhy, style: context.t.small.copyWith(color: context.c.textSecondary)),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.sm + 1, vertical: VSpace.xs),
        decoration: BoxDecoration(
          border: Border.all(color: context.c.border),
          borderRadius: BorderRadius.circular(VRadius.sm - 1),
        ),
        child: Text(text, style: context.t.small.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.c.textSecondary)),
      );
}
