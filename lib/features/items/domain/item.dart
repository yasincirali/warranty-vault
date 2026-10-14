import '../../../rights/rights_engine.dart';

/// Icon family for the product tile until the user's own photo exists.
enum ItemCategory { laptop, phone, headphones, tv, appliance, vacuum, other }

class Money {
  const Money(this.amount, this.currency);
  final num amount;

  /// ISO 4217 code (EUR, TRY, GBP…).
  final String currency;
}

class Item {
  const Item({
    required this.id,
    required this.name,
    required this.store,
    required this.purchase,
    this.category = ItemCategory.other,
    this.price,
    this.serial,
    this.invoicePath,
  });

  final String id;
  final String name;
  final String store;
  final Purchase purchase;
  final ItemCategory category;
  final Money? price;
  final String? serial;
  final String? invoicePath;

  Item copyWith({String? id}) => Item(
        id: id ?? this.id,
        name: name,
        store: store,
        purchase: purchase,
        category: category,
        price: price,
        serial: serial,
        invoicePath: invoicePath,
      );
}

/// An item with its protections already calculated for "today".
/// Screens only read this; no rights logic runs inside build().
class ItemView {
  const ItemView(this.item, this.protections, this.next);
  final Item item;
  final List<Protection> protections;

  /// Soonest deadline within 30 days, or null.
  final Protection? next;

  Protection? get primary =>
      protections.isEmpty ? null : protections.first;
}
