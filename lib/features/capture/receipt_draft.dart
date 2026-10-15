import '../../rights/rights_engine.dart';
import '../items/domain/item.dart';

/// One value read from the receipt, with how sure the reader is.
/// Below [ReceiptDraft.sureThreshold] the field is flagged for the user
/// instead of being silently trusted: a wrong date means a wrong deadline.
class Field<T> {
  const Field(this.value, this.confidence);
  final T value;
  final double confidence;
}

class ReceiptDraft {
  const ReceiptDraft({
    required this.product,
    required this.store,
    required this.date,
    required this.amount,
    required this.region,
    required this.channel,
    this.serial,
    this.category = ItemCategory.other,
  });

  static const sureThreshold = 0.85;

  final Field<String> product;
  final Field<String> store;
  final Field<DateTime> date;
  final Field<Money> amount;
  final Field<String?>? serial;
  final String region;
  final SalesChannel channel;
  final ItemCategory category;

  Item toItem() => Item(
    id: '',
    name: product.value,
    store: store.value,
    category: category,
    price: amount.value,
    serial: serial?.value,
    purchase: Purchase(date: date.value, region: region, channel: channel),
  );
}

/// Turns a photo into a draft. The real one calls the `fis-oku` edge
/// function (Claude vision); the demo one lets the flow run offline.
abstract interface class ReceiptReader {
  Future<ReceiptDraft> read(List<int> imageBytes);
}

class DemoReceiptReader implements ReceiptReader {
  @override
  Future<ReceiptDraft> read(List<int> imageBytes) async => ReceiptDraft(
    product: const Field('Sony WH-1000XM5', 0.97),
    store: const Field('MediaMarkt Online', 0.95),
    date: Field(DateTime.utc(2026, 10, 2), 0.93),
    amount: const Field(Money(349, 'EUR'), 0.98),
    // Thermal-paper serials are often half faded: shown, but flagged.
    serial: const Field('S01-4417***', 0.52),
    region: 'DE',
    channel: SalesChannel.online,
    category: ItemCategory.headphones,
  );
}
