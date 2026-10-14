import '../../../rights/rights_engine.dart';
import '../domain/item.dart';
import 'item_repository.dart';

/// In-memory data matching the design canvas (C2). Used when no backend is
/// configured: design reviews, widget tests, store screenshots.
class DemoItemRepository implements ItemRepository {
  DemoItemRepository() : _items = [..._seed];

  final List<Item> _items;

  @override
  Future<List<Item>> list() async => List.unmodifiable(_items);

  @override
  Future<Item> add(Item item) async {
    final saved = item.copyWith(id: 'demo-${_items.length + 1}');
    _items.add(saved);
    return saved;
  }

  static DateTime _d(int y, int m, int d) => DateTime.utc(y, m, d);

  static final _seed = <Item>[
    Item(
      id: 'macbook',
      name: 'MacBook Air 13"',
      store: 'Saturn Berlin',
      category: ItemCategory.laptop,
      price: const Money(1299, 'EUR'),
      serial: 'C02FK3XJQ6L4',
      invoicePath: 'demo/macbook.pdf',
      purchase: Purchase(
        date: _d(2024, 11, 10),
        region: 'DE',
        channel: SalesChannel.store,
        manufacturer: const ManufacturerWarranty.months(12),
      ),
    ),
    Item(
      id: 'sony',
      name: 'Sony WH-1000XM5',
      store: 'Amazon.de',
      category: ItemCategory.headphones,
      price: const Money(329, 'EUR'),
      purchase: Purchase(
        date: _d(2026, 10, 2),
        region: 'DE',
        channel: SalesChannel.online,
        manufacturer: const ManufacturerWarranty.months(12),
      ),
    ),
    Item(
      id: 'bosch',
      name: 'Bosch Serie 6',
      store: 'MediaMarkt',
      category: ItemCategory.appliance,
      price: const Money(749, 'EUR'),
      purchase: Purchase(
        date: _d(2025, 3, 14),
        region: 'DE',
        channel: SalesChannel.store,
        manufacturer: const ManufacturerWarranty.months(36),
      ),
    ),
    Item(
      id: 'pixel',
      name: 'Pixel 9',
      store: 'Google Store',
      category: ItemCategory.phone,
      price: const Money(899, 'EUR'),
      purchase: Purchase(
        date: _d(2025, 8, 21),
        region: 'DE',
        channel: SalesChannel.online,
        manufacturer: const ManufacturerWarranty.months(24),
      ),
    ),
    Item(
      id: 'lg',
      name: 'LG OLED C3',
      store: 'Teknosa',
      category: ItemCategory.tv,
      price: const Money(54999, 'TRY'),
      purchase: Purchase(
        date: _d(2026, 6, 1),
        region: 'TR',
        channel: SalesChannel.store,
        manufacturer: const ManufacturerWarranty.months(24),
      ),
    ),
    Item(
      id: 'dyson',
      name: 'Dyson V12',
      store: 'Dyson',
      category: ItemCategory.vacuum,
      purchase: Purchase(
        date: _d(2022, 2, 1),
        region: 'DE',
        channel: SalesChannel.online,
        manufacturer: const ManufacturerWarranty.months(24),
      ),
    ),
  ];
}
