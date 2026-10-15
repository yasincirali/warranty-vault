import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rights/advice.dart';
import '../../rights/rights_engine.dart';
import '../../rights/rule_set.dart';
import '../capture/subject_lift.dart';
import 'data/demo_vault.dart';
import 'data/vault_store.dart';
import 'domain/item.dart';
import 'domain/vault.dart';

/// "Today" is injected so tests and screenshots are deterministic.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

final ruleSetProvider = FutureProvider<RuleSet>((ref) async =>
    RuleSet.fromJsonString(await rootBundle.loadString('assets/rules/rules.json')));

/// main() overrides this with a [LocalVaultStore] in Application Support.
final vaultStoreProvider = Provider<VaultStore>((_) => MemoryVaultStore());

final vaultProvider = AsyncNotifierProvider<VaultController, Vault>(VaultController.new);

/// Every change to the cabinet goes through here, so the shelf rules
/// ([normalize]) run after each one and the file is always saved in the
/// state the user sees.
class VaultController extends AsyncNotifier<Vault> {
  final _rand = Random();

  String _id(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rand.nextInt(1 << 20).toRadixString(36)}';
  String _shelfId() => _id('s');

  @override
  Future<Vault> build() async {
    final stored = await ref.watch(vaultStoreProvider).load();
    return normalize(stored, newShelfId: _shelfId);
  }

  Vault get _v => state.requireValue;

  Future<void> _commit(Vault next) async {
    state = AsyncData(next);
    try {
      await ref.read(vaultStoreProvider).save(next);
    } catch (e, s) {
      // The cabinet stays usable in memory; the next successful save
      // writes everything. Reported, not swallowed.
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s, library: 'vault'));
    }
  }

  /// Adds [draft] (its id is replaced) and returns the new id.
  Future<String> add(Item draft, {LiftedPhoto? photo}) async {
    final id = _id('i');
    var item = draft.copyWith(id: id);
    if (photo != null) {
      final rel = await ref.read(vaultStoreProvider).savePhoto('$id.png', photo.png);
      item = item.copyWith(photoPath: rel, photoAspect: photo.aspect, photoCutout: photo.cutout);
    }
    await _commit(normalize(Vault(items: [..._v.items, item], shelves: _v.shelves), newShelfId: _shelfId));
    return id;
  }

  Future<void> move(String itemId, int shelfIndex, int insertAt) =>
      _commit(moveItem(_v, itemId, shelfIndex, insertAt, newShelfId: _shelfId));

  /// Thrown out of the cabinet. Undo is [restore].
  Future<void> discard(String itemId) {
    final now = ref.read(clockProvider)();
    return _commit(normalize(
      Vault(
        items: [for (final i in _v.items) i.id == itemId ? i.copyWith(disposedAt: now) : i],
        shelves: _v.shelves,
      ),
      newShelfId: _shelfId,
    ));
  }

  /// Back to the shelf it came from (or the first with room if that shelf
  /// is gone).
  Future<void> restore(String itemId) {
    final item = _v.items.firstWhere((i) => i.id == itemId).copyWith(clearDisposed: true);
    return _commit(normalize(
      Vault(items: [for (final i in _v.items) if (i.id != itemId) i, item], shelves: _v.shelves),
      newShelfId: _shelfId,
    ));
  }

  /// Dymo label on a shelf. 24 characters is what fits the tape at the
  /// largest text size without covering the products.
  Future<void> relabel(String shelfId, String label) {
    var text = label.trim();
    if (text.length > 24) text = text.substring(0, 24);
    return _commit(normalize(
      Vault(
        items: _v.items,
        shelves: [for (final s in _v.shelves) s.id == shelfId ? s.withLabel(text) : s],
      ),
      newShelfId: _shelfId,
    ));
  }

  /// Sample cabinet for testers; only offered while the cabinet is empty.
  Future<void> loadSample({required String desk, required String living, required String kitchen}) {
    final sample = demoVault(desk: desk, living: living, kitchen: kitchen);
    return _commit(normalize(
      Vault(items: [..._v.items, ...sample.items], shelves: [...sample.shelves, ..._v.shelves]),
      newShelfId: _shelfId,
    ));
  }
}

/// Every item still in the cabinet with its protections for today.
final itemViewsProvider = FutureProvider<List<ItemView>>((ref) async {
  final rules = await ref.watch(ruleSetProvider.future);
  final vault = await ref.watch(vaultProvider.future);
  final today = ref.watch(clockProvider)();
  final engine = RightsEngine(rules);
  return [
    for (final i in vault.items)
      () {
        final ps = engine.evaluate(i.purchase, today);
        return ItemView(i, ps, i.active ? nextDeadline(ps, today) : null);
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
