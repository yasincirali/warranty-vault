import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/features/items/domain/item.dart';
import 'package:warranty_vault/features/search/search.dart';
import 'package:warranty_vault/rights/rights_engine.dart';

SearchEntry _e(String name, {String store = '', String serial = '', String shelf = ''}) {
  final item = Item(
    id: name,
    name: name,
    store: store,
    serial: serial.isEmpty ? null : serial,
    purchase: Purchase(date: DateTime.utc(2026, 1, 1), region: 'TR', channel: SalesChannel.store),
  );
  return SearchEntry(ItemView(item, const [], null), foldForSearch(name), foldForSearch('$name $store $serial $shelf'));
}

List<String> _names(List<ItemView> v) => [for (final x in v) x.item.name];

void main() {
  final index = [
    _e('Sony WH-1000XM5 kulaklık', store: 'MediaMarkt'),
    _e('Şarj aleti', store: 'Teknosa', shelf: 'Çalışma masası'),
    _e('Çaydanlık', store: 'Karaca', serial: 'KR-88123'),
    _e('Kulaklık kılıfı', store: 'Sony Store'),
  ];

  test('Turkish letters and case fold both ways', () {
    expect(_names(searchItems(index, 'sarj')), ['Şarj aleti']);
    expect(_names(searchItems(index, 'ÇAYDANLIK')), ['Çaydanlık']);
    expect(foldForSearch('İSTANBUL'), 'istanbul');
    expect(foldForSearch('Istanbul'), 'istanbul');
  });

  test('every word must match, in any order, across name, store, serial and shelf', () {
    expect(_names(searchItems(index, 'kulak sony')), ['Kulaklık kılıfı', 'Sony WH-1000XM5 kulaklık']);
    expect(_names(searchItems(index, 'kr-88')), ['Çaydanlık']);
    expect(_names(searchItems(index, 'masa')), ['Şarj aleti']);
    expect(searchItems(index, '   '), isEmpty);
  });

  test('a hit in the name ranks above a hit in the store', () {
    expect(_names(searchItems(index, 'sony')).first, 'Sony WH-1000XM5 kulaklık');
  });

  test('performance: one keystroke over 5 000 products is well under a frame', () {
    final big = [for (var i = 0; i < 5000; i++) _e('Ürün $i model ${i * 7}', store: 'Mağaza ${i % 40}')];
    searchItems(big, 'model 7');
    final sw = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      searchItems(big, 'mağaza 3 model');
    }
    final perRun = sw.elapsedMicroseconds / 20;
    // ignore: avoid_print
    print('searchItems(5000 items): ${(perRun / 1000).toStringAsFixed(2)} ms');
    expect(perRun, lessThan(16000));
  });
}
