import '../../../rights/rights_engine.dart';
import '../domain/item.dart';
import '../domain/vault.dart';

/// The sample cabinet from the design canvas (C2 / Tur5). Used by widget
/// tests and store screenshots, and offered to TestFlight testers on first
/// run ("Load a sample cabinet") so they can try the shelves before
/// photographing their own things.
///
/// Product pictures are the prototype's illustrations, bundled as assets
/// (`asset:` paths), so the sample looks like a real cabinet.
///
/// Shelf labels are passed in so the sample speaks the user's language.
Vault demoVault({String desk = 'Desk', String living = 'Living room', String kitchen = 'Kitchen'}) =>
    Vault(
      shelves: [
        Shelf(id: 'desk', label: desk),
        Shelf(id: 'living', label: living),
        Shelf(id: 'kitchen', label: kitchen),
      ],
      items: _items(),
    );

DateTime _d(int y, int m, int d) => DateTime.utc(y, m, d);

List<Item> _items() => [

  Item(
    id: 'macbook',
    photoPath: 'asset:kategori/laptop.png',
    photoAspect: 1.009,
    photoCutout: true,
    shelfId: 'desk',
    name: 'MacBook Air 13"',
    store: 'Saturn Berlin',
    category: ItemCategory.laptop,
    price: const Money(1299, 'EUR'),
    serial: 'C02FK3XJQ6L4',
    documents: [ItemDoc(path: 'asset:demo/fis_macbook.jpg', kind: DocKind.receipt, added: _d(2024, 11, 10))],
    purchase: Purchase(
      date: _d(2024, 11, 10),
      region: 'DE',
      channel: SalesChannel.store,
      manufacturer: const ManufacturerWarranty.months(12),
    ),
  ),
  Item(
    id: 'sony',
    photoPath: 'asset:kategori/headphones.png',
    photoAspect: 1.365,
    photoCutout: true,
    shelfId: 'desk',
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
    photoPath: 'asset:kategori/appliance.png',
    photoAspect: 0.659,
    photoCutout: true,
    shelfId: 'kitchen',
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
    photoPath: 'asset:kategori/phone.png',
    photoAspect: 0.463,
    photoCutout: true,
    shelfId: 'desk',
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
    photoPath: 'asset:kategori/tv.png',
    photoAspect: 1.376,
    photoCutout: true,
    shelfId: 'living',
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
    photoPath: 'asset:kategori/vacuum.png',
    photoAspect: 0.456,
    photoCutout: true,
    shelfId: 'living',
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
