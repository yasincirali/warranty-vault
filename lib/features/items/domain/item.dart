import '../../../rights/rights_engine.dart';

/// Icon family for the product tile until the user's own photo exists.
enum ItemCategory { laptop, phone, headphones, tv, appliance, vacuum, other }

class Money {
  const Money(this.amount, this.currency);
  final num amount;

  /// ISO 4217 code (EUR, TRY, GBP…).
  final String currency;
}

/// What a stored paper is for. The counter screen shows the receipt first:
/// it is the proof of purchase a seller asks for.
enum DocKind { receipt, warrantyCard, manual, other }

/// A receipt, invoice, warranty card or manual kept with the product.
class ItemDoc {
  const ItemDoc({required this.path, required this.kind, required this.added});

  /// Relative to the vault folder (`docs/<file>`), like [Item.photoPath].
  final String path;
  final DocKind kind;
  final DateTime added;

  /// E-invoices (e-Arşiv, most online shops) arrive as PDF; everything
  /// photographed is a JPEG.
  bool get isPdf => path.toLowerCase().endsWith('.pdf');

  Map<String, Object?> toJson() => {'path': path, 'kind': kind.name, 'added': added.toIso8601String()};

  static ItemDoc fromJson(Map<String, dynamic> j) => ItemDoc(
        path: j['path'] as String,
        kind: DocKind.values.asNameMap()[j['kind']] ?? DocKind.other,
        added: DateTime.tryParse(j['added'] as String? ?? '') ?? DateTime.utc(2000),
      );
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
    this.documents = const [],
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

  /// Receipts, invoices, warranty cards, manuals; oldest first.
  final List<ItemDoc> documents;

  /// The proof of purchase the counter screen shows, if one is stored.
  ItemDoc? get receipt {
    for (final d in documents) {
      if (d.kind == DocKind.receipt) return d;
    }
    return null;
  }

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
    List<ItemDoc>? documents,
  }) =>
      Item(
        id: id ?? this.id,
        name: name,
        store: store,
        purchase: purchase,
        category: category,
        price: price,
        serial: serial,
        documents: documents ?? this.documents,
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
        if (documents.isNotEmpty) 'documents': [for (final d in documents) d.toJson()],
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
      documents: [
        for (final d in (j['documents'] as List? ?? const [])) ItemDoc.fromJson(d as Map<String, dynamic>),
        // Builds before documents existed kept one `invoicePath`; it is
        // read as the receipt so nothing a tester stored disappears.
        if (j['documents'] == null && j['invoicePath'] is String)
          ItemDoc(path: j['invoicePath'] as String, kind: DocKind.receipt, added: DateTime.utc(2000)),
      ],
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
