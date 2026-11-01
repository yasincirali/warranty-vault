import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/brand_mark.dart';
import '../../../core/ui/time_rule.dart';
import '../../../core/ui/widgets.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../rights/rights_engine.dart';
import '../../capture/add_item_screen.dart';
import '../../counter/counter_screen.dart';
import '../../issue/issue_flow_screen.dart';
import '../../reminders/notification_access_row.dart';
import '../domain/item.dart';
import '../providers.dart';
import 'documents.dart';
import 'item_photo.dart';

/// Answer first: the top card says where the user stands today in one
/// number and one sentence. The list below is the evidence for it.
class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.itemId});
  final String itemId;

  /// Scroll offset after which the photo and name row has left the screen
  /// and the name moves into the bar.
  static const titleAfter = 88.0;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  /// Scrolled past the name: the bar shows it small, with a hairline under
  /// it. Before, a long page scrolled up under an empty bar and the user
  /// lost which product they were reading about (Rafım design review,
  /// 1 Nov 2026). The standard iOS large-title pattern, without the large
  /// title: the name already sits big next to the photo.
  bool _scrolled = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    final past = n.metrics.pixels > ItemDetailScreen.titleAfter;
    if (past != _scrolled) setState(() => _scrolled = past);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final itemId = widget.itemId;
    final l = AppLocalizations.of(context);
    final view = ref.watch(itemViewProvider(itemId)).value;
    final today = ref.watch(clockProvider)();

    if (view == null) {
      return Scaffold(body: Center(child: VLoader(label: l.loading)));
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
        scrolledUnderElevation: 0,
        // Fades in; with reduce motion it just appears (VMotion.of).
        title: AnimatedOpacity(
          opacity: _scrolled ? 1 : 0,
          duration: VMotion.of(context, VMotion.quick),
          child: ExcludeSemantics(
            // The header below is still the page's heading for screen readers.
            excluding: !_scrolled,
            child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.t.label),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: AnimatedOpacity(
            opacity: _scrolled ? 1 : 0,
            duration: VMotion.of(context, VMotion.quick),
            child: Divider(height: 1, thickness: 1, color: context.c.divider),
          ),
        ),
        actions: [
          VIconButton(
            icon: Icons.edit_outlined,
            label: l.edit,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => AddItemScreen(editing: item),
            )),
          ),
          const SizedBox(width: VSpace.md),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(VSpace.xl, 0, VSpace.xl, VSpace.xxl),
        children: [
          Row(children: [
            Hero(tag: itemHeroTag(item.id), flightShuttleBuilder: itemHeroShuttle, child: ItemPhoto(item: item, size: 96)),
            const SizedBox(width: VSpace.lg - 2),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Semantics(header: true, child: Text(item.name, style: context.t.title)),
                Text(meta, style: context.t.small.copyWith(color: context.c.textSecondary)),
                // Review round 2: people move and buy abroad; say whose rules apply.
                // A line, not a bordered pill (Rafım Ar-Ge 30 Oct): pills are
                // tappable everywhere else in the app and this one was not.
                const SizedBox(height: VSpace.xs),
                // Tappable since 1 Nov 2026 (Rafım design review): "which
                // rules" and "where do they come from" are one question, so
                // the country line opens the sources sheet and the separate
                // "Where does this period come from?" button under the answer
                // is gone. A link with a chevron, still not a pill.
                if (view.primary case final p? when p.sources.isNotEmpty)
                  _RulesLink(
                    text: l.rulesOf(regionName(l, item.purchase.region)),
                    onTap: () => _showSources(context, p, regionName(l, item.purchase.region)),
                  )
                else
                  _Note(Icons.public, l.rulesOf(regionName(l, item.purchase.region))),
                // Said in words, not only by a colour: why no reminder comes.
                if (item.sample) _Note(Icons.science_outlined, l.sampleTag),
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
                  axis: TimeBand.axisOf(view.protections),
                  urgent: identical(view.protections[i], view.next),
                  primary: identical(view.protections[i], view.primary),
                  last: i == view.protections.length - 1,
                  // Tick words once per card: "today" on the top band,
                  // "proof on you" on the first band with a proof tick.
                  todayLabel: i == 0 ? l.bandToday : null,
                  proofLabel: i == _proofRow(view.protections) ? l.bandProof : null,
                ),
            ]),
          ),
          // Right under the dates it would have warned about.
          if (!item.sample && item.active && view.next != null) const NotificationAccessRow(onItem: true),
          const SizedBox(height: VSpace.lg),
          DocumentsSection(item: item),
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
          // No time rule here (Rafım Ar-Ge 26 Oct 22:20, yasin "yap"): the
          // same protection is drawn once, in the bands below, where it is
          // the bold row. Two pictures of one period made the page longer
          // and pushed the receipt below the first screen.
          Text(kindLabel(l, p!.kind), style: context.t.label),
        ],
        const SizedBox(height: VSpace.sm),
        Text(body, style: context.t.body),
        // The sources sheet opens from the country line under the name.
      ]),
    );
  }
}

/// One protection: its name and end date, and under them its band on the
/// time axis all the item's protections share ([TimeBand]).
class _ProtectionRow extends StatelessWidget {
  const _ProtectionRow({
    required this.p,
    required this.today,
    required this.axis,
    required this.urgent,
    required this.primary,
    required this.last,
    this.todayLabel,
    this.proofLabel,
  });
  final Protection p;
  final DateTime today;
  final (DateTime, DateTime)? axis;
  final bool urgent;

  /// The protection the answer card above talks about: its name is bold
  /// (weight, not colour, so it reads without colour vision) and it keeps
  /// what that card's rule used to say, the proof month and, for screen
  /// readers, how much of the period has passed.
  final bool primary;
  final bool last;
  final String? todayLabel;
  final String? proofLabel;

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
    final end = p.presumptionEnd;
    // The month the burden of proof moves, while it is still ahead: after
    // it the sentence would describe the past.
    final proofMonth = primary && active && end != null && end.isAfter(today)
        ? (end.year - p.start.year) * 12 + end.month - p.start.month
        : null;
    final color = urgent
        ? context.c.deadline
        : (active ? context.c.text : context.c.textSecondary);

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: context.c.divider)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: VSpace.md,
          runSpacing: VSpace.xs,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VSpace.md),
              child: Text(kindLabel(l, p.kind),
                  style: !active
                      ? context.t.body.copyWith(color: context.c.textSecondary)
                      : primary
                          ? context.t.label.copyWith(fontWeight: FontWeight.w700)
                          : context.t.label),
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
        if (axis case (final from, final to) when p.end != null && p.status != ProtectionStatus.unverified)
          Padding(
            padding: EdgeInsets.only(bottom: proofMonth == null ? VSpace.md : VSpace.xs),
            child: Semantics(
              label: primary ? l.ruleSemantics(_passedPercent(p, today)) : null,
              child: TimeBand(
                protection: p,
                today: today,
                axisStart: from,
                axisEnd: to,
                urgent: urgent,
                todayLabel: todayLabel,
                proofLabel: proofLabel,
                label: p.end == null ? null : l.durDays(dateOnly(p.end!).difference(dateOnly(today)).inDays.clamp(0, 99999)),
              ),
            ),
          ),
        if (proofMonth != null)
          Padding(
            padding: const EdgeInsets.only(bottom: VSpace.md),
            child: Text(l.ruleProofMonth(proofMonth), style: context.t.small.copyWith(color: context.c.textSecondary)),
          ),
      ]),
    );
  }
}

/// The first protection whose band draws a proof tick (the tick sits
/// strictly inside its period), or -1.
int _proofRow(List<Protection> ps) => ps.indexWhere((p) {
      final pe = p.presumptionEnd;
      return pe != null &&
          p.end != null &&
          p.status != ProtectionStatus.unverified &&
          pe.isAfter(p.start) &&
          pe.isBefore(p.end!);
    });

int _passedPercent(Protection p, DateTime today) {
  if (p.status == ProtectionStatus.ended) return 100;
  final total = p.end!.difference(p.start).inDays;
  if (total <= 0) return 100;
  return (today.difference(p.start).inDays / total * 100).clamp(0, 100).round();
}

class _Note extends StatelessWidget {
  const _Note(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: VSpace.xs),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ExcludeSemantics(child: Icon(icon, size: 14, color: context.c.textSecondary)),
          ),
          const SizedBox(width: VSpace.xs + 2),
          Expanded(child: Text(text, style: context.t.caption.copyWith(color: context.c.textSecondary))),
        ]),
      );
}

/// The "worked out with X rules" line as a link to the sources sheet: same
/// icon and caption as [_Note], plus a chevron and a 44 pt tap height.
class _RulesLink extends StatelessWidget {
  const _RulesLink({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.c.textSecondary;
    return Semantics(
      button: true,
      label: text,
      hint: AppLocalizations.of(context).whereFrom,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: VSize.minTap),
          child: Row(children: [
            Icon(Icons.public, size: 14, color: muted),
            const SizedBox(width: VSpace.xs + 2),
            Flexible(child: Text(text, style: context.t.caption.copyWith(color: context.c.text))),
            Icon(Icons.chevron_right, size: 16, color: muted),
          ]),
        ),
      ),
    );
  }
}

/// Where a legal period comes from: the page the rule was verified against
/// (`rules.json` sources). Shown as the address and opened in the browser,
/// so our summary stays one tap away from its source. Called "source", not
/// "official text": not every region's source is a statute yet.
Future<void> _showSources(BuildContext context, Protection p, String region) {
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) {
      final l = AppLocalizations.of(sheet);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(VSpace.xl, 0, VSpace.xl, VSpace.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Semantics(header: true, child: Text(l.whereFrom, style: sheet.t.title)),
            const SizedBox(height: VSpace.sm),
            Text(l.sourcesBody(region), style: sheet.t.body.copyWith(color: sheet.c.textSecondary)),
            const SizedBox(height: VSpace.md),
            for (final url in p.sources)
              InkWell(
                onTap: () async {
                  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  if (!ok) messenger.showSnackBar(SnackBar(content: Text(l.sourceOpenFailed)));
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: VSize.minTap),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: VSpace.sm),
                    child: Row(children: [
                      ExcludeSemantics(child: Icon(Icons.open_in_new, size: 18, color: sheet.c.textSecondary)),
                      const SizedBox(width: VSpace.md),
                      Expanded(
                        child: Semantics(
                          link: true,
                          child: Text(
                            Uri.parse(url).host,
                            style: sheet.t.label.copyWith(decoration: TextDecoration.underline),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            const SizedBox(height: VSpace.md),
            Text(l.disclaimer, style: sheet.t.small.copyWith(color: sheet.c.textSecondary)),
          ]),
        ),
      );
    },
  );
}
