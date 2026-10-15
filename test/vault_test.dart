import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/features/items/data/demo_vault.dart';
import 'package:warranty_vault/features/items/data/vault_store.dart';
import 'package:warranty_vault/features/items/domain/item.dart';
import 'package:warranty_vault/features/items/domain/vault.dart';
import 'package:warranty_vault/rights/rights_engine.dart';

var _n = 0;
String _sid() => 'new${_n++}';

Item _item(String id, {String? shelf, DateTime? disposed}) => Item(
      id: id,
      name: id,
      store: '',
      shelfId: shelf,
      disposedAt: disposed,
      purchase: Purchase(date: DateTime.utc(2026, 1, 1), region: 'TR', channel: SalesChannel.store),
    );

List<String> _ids(Vault v, int shelf) => [for (final i in v.on(v.shelves[shelf].id)) i.id];

void main() {
  setUp(() => _n = 0);

  test('an empty vault gets one empty shelf', () {
    final v = normalize(const Vault(), newShelfId: _sid);
    expect(v.shelves, hasLength(1));
  });

  test('a full shelf pushes its newest item down and a new empty shelf appears', () {
    final v = normalize(
      Vault(shelves: const [Shelf(id: 'a')], items: [for (var i = 0; i < 5; i++) _item('i$i', shelf: 'a')]),
      newShelfId: _sid,
    );
    expect(_ids(v, 0), ['i0', 'i1', 'i2', 'i3']);
    expect(_ids(v, 1), ['i4']);
    expect(v.shelves, hasLength(3), reason: 'always one empty shelf at the bottom');
    expect(_ids(v, 2), isEmpty);
  });

  test('empty unlabelled shelves in the middle close up; labelled ones stay', () {
    final v = normalize(
      Vault(
        shelves: const [Shelf(id: 'a'), Shelf(id: 'gap'), Shelf(id: 'kept', label: 'Kamp'), Shelf(id: 'b')],
        items: [_item('x', shelf: 'a'), _item('y', shelf: 'b')],
      ),
      newShelfId: _sid,
    );
    expect([for (final s in v.shelves) s.id], ['a', 'kept', 'b', 'new0']);
  });

  test('items without a valid shelf go to the first shelf with room', () {
    final v = normalize(
      Vault(
        shelves: const [Shelf(id: 'a'), Shelf(id: 'b')],
        items: [for (var i = 0; i < 4; i++) _item('a$i', shelf: 'a'), _item('lost', shelf: 'nope')],
      ),
      newShelfId: _sid,
    );
    expect(_ids(v, 1), ['lost']);
  });

  test('moving onto a full shelf inserts at the drop position and cascades', () {
    var v = normalize(
      Vault(
        shelves: const [Shelf(id: 'a'), Shelf(id: 'b')],
        items: [for (var i = 0; i < 4; i++) _item('a$i', shelf: 'a'), _item('m', shelf: 'b')],
      ),
      newShelfId: _sid,
    );
    v = moveItem(v, 'm', 0, 1, newShelfId: _sid);
    expect(_ids(v, 0), ['a0', 'm', 'a1', 'a2']);
    expect(_ids(v, 1), ['a3'], reason: 'the last one moved down to make room');
    expect(v.shelves.last.label, isEmpty);
    expect(v.on(v.shelves.last.id), isEmpty);
  });

  test('moving to the empty bottom shelf grows the cabinet', () {
    var v = normalize(Vault(shelves: const [Shelf(id: 'a')], items: [_item('x', shelf: 'a'), _item('y', shelf: 'a')]),
        newShelfId: _sid);
    expect(v.shelves, hasLength(2));
    v = moveItem(v, 'y', 1, 0, newShelfId: _sid);
    expect(v.shelves, hasLength(3));
    expect(_ids(v, 1), ['y']);
  });

  test('thrown-out items keep their data but leave the shelves', () {
    final v = normalize(
      Vault(shelves: const [Shelf(id: 'a')], items: [_item('x', shelf: 'a', disposed: DateTime.utc(2026, 10, 1))]),
      newShelfId: _sid,
    );
    expect(v.active, isEmpty);
    expect(v.disposed.single.id, 'x');
    expect(v.shelves, hasLength(1));
  });

  test('vault survives a JSON round trip', () {
    final v = normalize(demoVault(), newShelfId: _sid);
    final back = Vault.fromJson(jsonDecode(jsonEncode(v.toJson())) as Map<String, dynamic>);
    expect(back.items.map((i) => i.id), v.items.map((i) => i.id));
    expect(back.shelves.map((s) => s.label), v.shelves.map((s) => s.label));
    final mac = back.items.firstWhere((i) => i.id == 'macbook');
    expect(mac.price!.amount, 1299);
    expect(mac.purchase.manufacturer.months, 12);
    expect(mac.purchase.channel, SalesChannel.store);
    expect(mac.serial, 'C02FK3XJQ6L4');
  });

  test('local store writes, reads back, and keeps photo paths relative', () async {
    final dir = await Directory.systemTemp.createTemp('vault');
    addTearDown(() => dir.delete(recursive: true));
    final store = LocalVaultStore(dir);
    expect((await store.load()).items, isEmpty);

    final rel = await store.savePhoto('x.png', Uint8List.fromList([1, 2, 3]));
    expect(rel, 'photos/x.png');
    expect(File('${dir.path}/$rel').existsSync(), isTrue);

    final v = Vault(shelves: const [Shelf(id: 'a', label: 'Mutfak')], items: [_item('x', shelf: 'a').copyWith(photoPath: rel)]);
    await store.save(v);
    final back = await store.load();
    expect(back.items.single.photoPath, 'photos/x.png');
    expect(back.shelves.single.label, 'Mutfak');
    expect(File('${dir.path}/vault.json.tmp').existsSync(), isFalse);
  });
}
