import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../rights/advice.dart';
import '../../rights/rights_engine.dart';
import '../../rights/rule_set.dart';
import 'data/demo_item_repository.dart';
import 'data/item_repository.dart';
import 'data/supabase_item_repository.dart';
import 'domain/item.dart';

/// "Today" is injected so tests and screenshots are deterministic.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

final ruleSetProvider = FutureProvider<RuleSet>((ref) async =>
    RuleSet.fromJsonString(await rootBundle.loadString('assets/rules/rules.json')));

final itemRepositoryProvider = Provider<ItemRepository>((ref) => Env.hasBackend
    ? SupabaseItemRepository(Supabase.instance.client)
    : DemoItemRepository());

/// Every item with its protections for today, most urgent first.
final itemViewsProvider = FutureProvider<List<ItemView>>((ref) async {
  final rules = await ref.watch(ruleSetProvider.future);
  final items = await ref.watch(itemRepositoryProvider).list();
  final today = ref.watch(clockProvider)();
  final engine = RightsEngine(rules);
  return [
    for (final i in items)
      () {
        final ps = engine.evaluate(i.purchase, today);
        return ItemView(i, ps, nextDeadline(ps, today));
      }(),
  ];
});

final itemViewProvider = FutureProvider.family<ItemView?, String>((ref, id) async {
  final all = await ref.watch(itemViewsProvider.future);
  for (final v in all) {
    if (v.item.id == id) return v;
  }
  return null;
});
