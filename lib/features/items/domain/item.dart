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
    this.photoPath,
    this.photoAspect,
    this.photoCutout = false,
    this.shelfId,
    this.disposedAt,
  });

  final String id;
  final String name;
  final String store;
  final Purchase purchase;
  final ItemCategory category;
  final Money? price;
  final String? serial;
  final String? invoicePath;

  /// Relative to the vault folder (`photos/<id>.png`). Never absolute: iOS
  /// moves the app container on every update, so an absolute path would
  /// point nowhere after the first App Store update.
  final String? photoPath;

  /// Width / height of the photo, stored so the cabinet can size the body
  /// without decoding the image first.
  final double? photoAspect;

  /// True when the background was lifted away (transparent PNG); false means
  /// the original photo, shown with rounded corners.
  final bool photoCutout;

  /// Which shelf the item stands on. Null = "first shelf with room".
  final String? shelfId;

  /// Set when the user throws the item out of the cabinet. Kept, not
  /// deleted: undo, the "thrown out" list and later the spending mirror
  /// ("what did I buy that I no longer have") all read it.
  final DateTime? disposedAt;

  bool get active => disposedAt == null;

  Item copyWith({
    String? id,
    String? shelfId,
    String? photoPath,
    double? photoAspect,
    bool? photoCutout,
    DateTime? disposedAt,
    bool clearDisposed = false,
  }) =>
      Item(
        id: id ?? this.id,
        name: name,
        store: store,
        purchase: purchase,
        category: category,
        price: price,
        serial: serial,
        invoicePath: invoicePath,
        photoPath: photoPath ?? this.photoPath,
        photoAspect: photoAspect ?? this.photoAspect,
        photoCutout: photoCutout ?? this.photoCutout,
        shelfId: shelfId ?? this.shelfId,
        disposedAt: clearDisposed ? null : (disposedAt ?? this.disposedAt),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'store': store,
        'category': category.name,
        if (price != null) 'price': {'amount': price!.amount, 'currency': price!.currency},
        'serial': ?serial,
        'invoicePath': ?invoicePath,
        'photoPath': ?photoPath,
        'photoAspect': ?photoAspect,
        'photoCutout': photoCutout,
        'shelfId': ?shelfId,
        if (disposedAt != null) 'disposedAt': disposedAt!.toIso8601String(),
        'purchase': _purchaseToJson(purchase),
      };

  static Item fromJson(Map<String, dynamic> j) {
    final price = j['price'] as Map<String, dynamic>?;
    return Item(
      id: j['id'] as String,
      name: j['name'] as String,
      store: j['store'] as String? ?? '',
      category: ItemCategory.values.asNameMap()[j['category']] ?? ItemCategory.other,
      price: price == null ? null : Money(price['amount'] as num, price['currency'] as String),
      serial: j['serial'] as String?,
      invoicePath: j['invoicePath'] as String?,
      photoPath: j['photoPath'] as String?,
      photoAspect: (j['photoAspect'] as num?)?.toDouble(),
      photoCutout: j['photoCutout'] as bool? ?? false,
      shelfId: j['shelfId'] as String?,
      disposedAt: j['disposedAt'] == null ? null : DateTime.parse(j['disposedAt'] as String),
      purchase: _purchaseFromJson(j['purchase'] as Map<String, dynamic>),
    );
  }
}

Map<String, Object?> _purchaseToJson(Purchase p) => {
      'date': p.date.toIso8601String(),
      'region': p.region,
      'channel': p.channel.name,
      'manufacturerMonths': p.manufacturer.months,
      'manufacturerLifetime': p.manufacturer.lifetime,
      if (p.extendedUntil != null) 'extendedUntil': p.extendedUntil!.toIso8601String(),
      'storeReturnDays': ?p.storeReturnDays,
      'repairs': [for (final r in p.repairs) r.toIso8601String()],
    };

Purchase _purchaseFromJson(Map<String, dynamic> j) {
  final lifetime = j['manufacturerLifetime'] as bool? ?? false;
  final months = j['manufacturerMonths'] as int?;
  return Purchase(
    date: DateTime.parse(j['date'] as String),
    region: j['region'] as String,
    channel: SalesChannel.values.asNameMap()[j['channel']] ?? SalesChannel.store,
    manufacturer: lifetime
        ? const ManufacturerWarranty.lifetime()
        : (months == null || months == 0
            ? const ManufacturerWarranty.none()
            : ManufacturerWarranty.months(months)),
    extendedUntil: j['extendedUntil'] == null ? null : DateTime.parse(j['extendedUntil'] as String),
    storeReturnDays: j['storeReturnDays'] as int?,
    repairs: [for (final r in (j['repairs'] as List? ?? const [])) DateTime.parse(r as String)],
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
