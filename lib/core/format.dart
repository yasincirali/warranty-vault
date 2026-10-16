import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../features/items/domain/item.dart';
import '../l10n/generated/app_localizations.dart';
import '../rights/rights_engine.dart';

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

String fmtDate(BuildContext context, DateTime d) => fmtDateIn(_locale(context), d);

String fmtMoney(BuildContext context, Money m) => fmtMoneyIn(_locale(context), m);

/// The same formats without a widget tree, for files made outside a screen
/// (the inventory export): one formatting rule for screen, PDF and sheet.
String fmtDateIn(String locale, DateTime d) => DateFormat.yMMMd(locale).format(d);

String fmtMoneyIn(String locale, Money m) =>
    NumberFormat.simpleCurrency(locale: locale, name: m.currency).format(m.amount);

String categoryLabel(AppLocalizations l, ItemCategory c) => switch (c) {
      ItemCategory.laptop => l.catLaptop,
      ItemCategory.phone => l.catPhone,
      ItemCategory.headphones => l.catHeadphones,
      ItemCategory.tv => l.catTv,
      ItemCategory.appliance => l.catAppliance,
      ItemCategory.vacuum => l.catVacuum,
      ItemCategory.other => l.catOther,
    };

String channelLabel(AppLocalizations l, SalesChannel c) => switch (c) {
      SalesChannel.store => l.channelStore,
      SalesChannel.online => l.channelOnline,
    };

String kindLabel(AppLocalizations l, ProtectionKind k) => switch (k) {
      ProtectionKind.returnWindow => l.kindReturn,
      ProtectionKind.shortTermReject => l.kindReject,
      ProtectionKind.manufacturer => l.kindManufacturer,
      ProtectionKind.extended => l.kindExtended,
      ProtectionKind.legal => l.kindLegal,
    };

/// "1 yıl 5 ay", "10 ay", "28 gün": the largest two units that matter.
/// Under two months we count days, because that is when people act.
String remainingLabel(AppLocalizations l, DateTime today, DateTime end) {
  final from = dateOnly(today);
  final to = dateOnly(end);
  final days = to.difference(from).inDays;
  if (days < 60) return l.durDays(days < 0 ? 0 : days);
  var months = (to.year - from.year) * 12 + to.month - from.month;
  if (to.day < from.day) months -= 1;
  final years = months ~/ 12;
  final rest = months % 12;
  if (years == 0) return l.durMonths(rest);
  if (rest == 0) return l.durYears(years);
  return '${l.durYears(years)} ${l.durMonths(rest)}';
}

/// Country names for the regions in rules.json; unknown codes show as-is
/// rather than guessing a name.
String regionName(AppLocalizations l, String code) => switch (code) {
      'DE' => l.regionDE,
      'EU' => l.regionEU,
      'GB' => l.regionGB,
      'TR' => l.regionTR,
      'US' => l.regionUS,
      'AU' => l.regionAU,
      _ => code,
    };
