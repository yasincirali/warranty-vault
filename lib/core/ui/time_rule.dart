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

/// One protection drawn on a time axis shared with the item's other
/// protections (Rafım Ar-Ge 25 Oct, yasin "yap"). Stacked under each other
/// they show what the separate rows only listed: the return window is a
/// sliver at the start, the maker's year ends inside the legal two years,
/// and "today" is one line through all of them. Same language as
/// [TimeRule]: grey track, darker for the part that has passed, an ended
/// protection one muted bar, the deadline colour only as a dot on an end
/// within 30 days (a whole orange bar shouted), a tick at
/// the month the burden of proof moves. The row's sentence carries the
/// meaning; this is the picture of it, so it is hidden from screen readers.
class TimeBand extends StatelessWidget {
  const TimeBand({
    super.key,
    required this.protection,
    required this.today,
    required this.axisStart,
    required this.axisEnd,
    this.urgent = false,
  });

  final Protection protection;
  final DateTime today;
  final DateTime axisStart;
  final DateTime axisEnd;
  final bool urgent;

  /// The axis for [protections]: purchase to the latest fixed end. null when
  /// there is nothing to draw (no fixed ends, or all on one day).
  static (DateTime, DateTime)? axisOf(Iterable<Protection> protections) {
    final drawn = protections.where((p) => p.end != null && p.status != ProtectionStatus.unverified).toList();
    if (drawn.isEmpty) return null;
    final start = drawn.map((p) => p.start).reduce((a, b) => a.isBefore(b) ? a : b);
    final end = drawn.map((p) => p.end!).reduce((a, b) => a.isAfter(b) ? a : b);
    return end.difference(start).inDays <= 0 ? null : (start, end);
  }

  @override
  Widget build(BuildContext context) {
    final p = protection;
    if (p.end == null || p.status == ProtectionStatus.unverified) return const SizedBox.shrink();
    final total = axisEnd.difference(axisStart).inDays.toDouble();
    double x(DateTime d) => (d.difference(axisStart).inDays / total).clamp(0.0, 1.0);
    final from = x(p.start), to = x(p.end!), now = x(today);
    final passed = (now.clamp(from, to) - from);
    final proof = p.presumptionEnd == null ? null : x(p.presumptionEnd!);
    final ended = p.status == ProtectionStatus.ended;
    const h = 6.0;

    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: VMotion.of(context, VMotion.ruleFill),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            // At least the bar's own height, so a 14-day window on a two-year
            // axis is still a visible sliver rather than nothing.
            final spanW = ((to - from) * w).clamp(h, w);
            return SizedBox(
              height: 14,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: from * w,
                    width: spanW,
                    child: Container(
                      height: h,
                      decoration: BoxDecoration(
                        color: ended ? context.c.text.withValues(alpha: .12) : context.c.track,
                        borderRadius: BorderRadius.circular(h / 2),
                      ),
                    ),
                  ),
                  if (!ended)
                    Positioned(
                      left: from * w,
                      width: (passed * w * v).clamp(0.0, spanW),
                      child: Container(
                        height: h,
                        decoration: BoxDecoration(
                          color: context.c.text.withValues(alpha: .22),
                          borderRadius: BorderRadius.circular(h / 2),
                        ),
                      ),
                    ),
                  if (proof != null && proof > from && proof < to)
                    Positioned(
                      left: proof * w - 1,
                      child: Container(width: 2, height: 12, color: context.c.textSecondary),
                    ),
                  if (urgent && !ended)
                    Positioned(
                      left: from * w + spanW - 10,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: context.c.deadline, shape: BoxShape.circle),
                      ),
                    ),
                  // Today: the same x on every band, so the rows read as one line.
                  if (now > 0 && now < 1)
                    Positioned(
                      left: now * w - .75,
                      child: Container(width: 1.5, height: 14, color: context.c.text),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
