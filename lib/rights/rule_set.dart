import 'dart:convert';

/// One region's consumer-law rule, read from `assets/rules/rules.json`.
///
/// The JSON file is the single source: the app, the server and the Phase 0
/// web tool all read it, so a rule change reaches every surface together.
class RegionRule {
  const RegionRule({
    required this.code,
    required this.name,
    required this.verified,
    this.legalMonths,
    this.reasonableDuration = false,
    this.presumptionMonths,
    this.distanceWithdrawalDays,
    this.shortTermRejectDays,
    this.repairExtensionMonths,
    this.repairExtensionFrom,
    this.repairExtensionVerified = false,
    this.sources = const [],
  });

  final String code;
  final String name;

  /// False until the rule is checked against an official text. An unverified
  /// region never shows a legal right; only the manufacturer warranty.
  final bool verified;
  final int? legalMonths;

  /// Australia-style rule: protection lasts "a reasonable time" with no
  /// fixed end date.
  final bool reasonableDuration;
  final int? presumptionMonths;
  final int? distanceWithdrawalDays;
  final int? shortTermRejectDays;
  final int? repairExtensionMonths;
  final DateTime? repairExtensionFrom;
  final bool repairExtensionVerified;
  final List<String> sources;
}

class RuleSet {
  const RuleSet({required this.version, required this.regions});

  final int version;
  final Map<String, RegionRule> regions;

  RegionRule? operator [](String code) => regions[code];

  /// Parses the rules file. A region may name a `base` region; its own keys
  /// override the base's (Germany = EU baseline + its own presumption).
  factory RuleSet.fromJsonString(String source) {
    final root = jsonDecode(source) as Map<String, dynamic>;
    final raw = (root['regions'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as Map<String, dynamic>));

    Map<String, dynamic> resolved(String code, [Set<String>? seen]) {
      final own = raw[code]!;
      final base = own['base'] as String?;
      if (base == null) return own;
      final visited = {...?seen, code};
      if (visited.contains(base)) {
        throw FormatException('Rules: base cycle at $code');
      }
      return {...resolved(base, visited), ...own};
    }

    DateTime? date(Object? v) => v == null ? null : DateTime.parse(v as String);

    final regions = <String, RegionRule>{};
    for (final code in raw.keys) {
      final m = resolved(code);
      regions[code] = RegionRule(
        code: code,
        name: m['name'] as String,
        verified: m['verified'] as bool? ?? false,
        legalMonths: m['legalMonths'] as int?,
        reasonableDuration: m['reasonableDuration'] as bool? ?? false,
        presumptionMonths: m['presumptionMonths'] as int?,
        distanceWithdrawalDays: m['distanceWithdrawalDays'] as int?,
        shortTermRejectDays: m['shortTermRejectDays'] as int?,
        repairExtensionMonths: m['repairExtensionMonths'] as int?,
        repairExtensionFrom: date(m['repairExtensionFrom']),
        repairExtensionVerified: m['repairExtensionVerified'] as bool? ?? false,
        sources: (m['sources'] as List? ?? const []).cast<String>(),
      );
    }
    return RuleSet(version: root['version'] as int, regions: regions);
  }
}
