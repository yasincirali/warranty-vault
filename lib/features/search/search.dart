import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rights/rights_engine.dart';
import '../items/domain/item.dart';
import '../items/providers.dart';

/// Lower-case, accents and Turkish letters folded: "ŞARJ", "sarj" and
/// "Şarj" find the same thing, and "Istanbul" finds "İstanbul".
String foldForSearch(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    b.write(_fold[c] ?? c.toLowerCase());
  }
  return b.toString();
}

const _fold = {
  'I': 'i', 'İ': 'i', 'ı': 'i', 'Ş': 's', 'ş': 's', 'Ğ': 'g', 'ğ': 'g', //
  'Ü': 'u', 'ü': 'u', 'Ö': 'o', 'ö': 'o', 'Ç': 'c', 'ç': 'c',
  'Ä': 'a', 'ä': 'a', 'ß': 'ss', 'É': 'e', 'é': 'e', 'È': 'e', 'è': 'e',
  'Á': 'a', 'á': 'a', 'Í': 'i', 'í': 'i', 'Ó': 'o', 'ó': 'o', 'Ú': 'u', 'ú': 'u',
};

/// One folded string per product: name, store, serial and the shelf it
/// stands on. Built once per cabinet change, so typing only scans strings.
class SearchEntry {
  const SearchEntry(this.view, this.name, this.haystack);
  final ItemView view;
  final String name;
  final String haystack;
}

final searchIndexProvider = FutureProvider<List<SearchEntry>>((ref) async {
  final views = await ref.watch(itemViewsProvider.future);
  final vault = await ref.watch(vaultProvider.future);
  final shelf = {for (final s in vault.shelves) s.id: s.label};
  return [
    for (final v in views)
      if (v.item.active)
        SearchEntry(
          v,
          foldForSearch(v.item.name),
          foldForSearch([v.item.name, v.item.store, v.item.serial ?? '', shelf[v.item.shelfId] ?? ''].join(' ')),
        ),
  ];
});

/// Every word of the query must appear (in any order): "sony kulak" finds
/// "Sony WH-1000XM5 kulaklık". Name matches come before the rest.
List<ItemView> searchItems(List<SearchEntry> index, String query) {
  final words = foldForSearch(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return const [];
  final hits = <(int, ItemView)>[];
  for (final e in index) {
    if (!words.every(e.haystack.contains)) continue;
    final inName = e.name.contains(words.first);
    hits.add((inName ? 0 : 1, e.view));
  }
  hits.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    return c != 0 ? c : a.$2.item.name.compareTo(b.$2.item.name);
  });
  return [for (final h in hits) h.$2];
}

/// What the search page lists before a letter is typed (UX defteri 26 Ekim):
/// every product, the one whose protection runs out first on top. That is
/// the question people most often open the app with ("what is about to
/// end?"); no filters or chips, the order answers it. Products without a
/// fixed end come next, products whose protections are all over last.
List<ItemView> soonestEnding(List<SearchEntry> index) {
  int rank(ItemView v) {
    final p = v.primary;
    if (p == null || p.status != ProtectionStatus.active) return 2;
    return p.end == null ? 1 : 0;
  }

  final all = [for (final e in index) e.view];
  // List.sort is not stable; the index position breaks ties so equal
  // products keep the cabinet's order.
  final pos = {for (final (i, v) in all.indexed) v: i};
  return all
    ..sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      if (rank(a) == 0) {
        final e = a.primary!.end!.compareTo(b.primary!.end!);
        if (e != 0) return e;
      }
      return pos[a]!.compareTo(pos[b]!);
    });
}
