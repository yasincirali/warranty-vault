import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../rights/rights_engine.dart';
import '../format.dart';
import '../theme/tokens.dart';

/// The app's one graphic: how much of a protection has passed, where today
/// is, and (full size) the month the burden of proof moves to the buyer.
/// Review round 3 chose it as the signature element because it answers a
/// question the text alone answers slowly ("am I halfway or nearly out?").
///
/// [compact] is the thin version under grid tiles: no labels, no marker.
class TimeRule extends StatelessWidget {
  const TimeRule({super.key, required this.protection, required this.today, this.urgent = false, this.compact = false});

  final Protection protection;
  final DateTime today;
  final bool urgent;
  final bool compact;

  static double? _fraction(DateTime start, DateTime? end, DateTime at) {
    if (end == null) return null;
    final total = end.difference(start).inDays;
    if (total <= 0) return 1;
    return (at.difference(start).inDays / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final p = protection;
    final ended = p.status == ProtectionStatus.ended;
    final f = ended ? 1.0 : _fraction(p.start, p.end, today);
    // No fixed end (Australia, lifetime warranty): nothing to draw honestly.
    if (f == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final marker = compact ? null : _fraction(p.start, p.end, p.presumptionEnd ?? p.start);
    final showMarker = marker != null && p.presumptionEnd != null && marker > 0 && marker < 1;
    final height = compact ? 4.0 : 6.0;

    final bar = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: f),
      duration: VMotion.of(context, VMotion.ruleFill),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        return SizedBox(
          height: compact ? height : 16,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
            Container(
              height: height,
              decoration: BoxDecoration(color: context.c.track, borderRadius: BorderRadius.circular(height / 2)),
            ),
            Container(
              width: w * v,
              height: height,
              decoration: BoxDecoration(
                color: context.c.text.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            if (showMarker)
              Positioned(
                left: w * marker - 1,
                child: Container(width: 2, height: 14, color: context.c.text),
              ),
            if (!compact && !ended)
              Positioned(
                left: w * v - 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: context.c.surface,
                    shape: BoxShape.circle,
                    border: Border.all(width: 3, color: urgent ? context.c.deadline : context.c.text),
                  ),
                ),
              ),
          ]),
        );
      }),
    );

    final semantics = l.ruleSemantics((f * 100).round());
    if (compact) return Semantics(label: semantics, excludeSemantics: true, child: bar);

    final months = p.presumptionEnd == null
        ? null
        : (p.presumptionEnd!.year - p.start.year) * 12 + p.presumptionEnd!.month - p.start.month;
    final small = context.t.small.copyWith(fontSize: 12.5, color: context.c.textSecondary);
    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        bar,
        const SizedBox(height: VSpace.sm),
        // Wrap, not Row: at large text sizes the three labels stack instead of clipping.
        Wrap(alignment: WrapAlignment.spaceBetween, spacing: VSpace.sm, runSpacing: VSpace.xs, children: [
          Text(fmtDate(context, p.start), style: small),
          if (showMarker && months != null) Text(l.ruleProofMonth(months), style: small),
          Text(fmtDate(context, p.end!),
              style: small.copyWith(
                  color: urgent ? context.c.deadline : null, fontWeight: urgent ? FontWeight.w600 : null)),
        ]),
      ]),
    );
  }
}
