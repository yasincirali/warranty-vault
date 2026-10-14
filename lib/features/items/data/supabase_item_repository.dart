import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../rights/rights_engine.dart';
import '../domain/item.dart';
import 'item_repository.dart';

/// Reads and writes `public.items` (see supabase/migrations/0001_base.sql).
/// RLS limits every row to its owner, so no user filter is needed here.
class SupabaseItemRepository implements ItemRepository {
  SupabaseItemRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<List<Item>> list() async {
    final rows = await _db
        .from('items')
        .select()
        .order('purchased_on', ascending: false);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Item> add(Item item) async {
    final row = await _db.from('items').insert(_toRow(item)).select().single();
    return _fromRow(row);
  }

  static Item _fromRow(Map<String, dynamic> r) {
    final months = r['manufacturer_months'] as int?;
    final lifetime = r['manufacturer_lifetime'] as bool? ?? false;
    return Item(
      id: r['id'] as String,
      name: r['name'] as String,
      store: r['store'] as String? ?? '',
      serial: r['serial'] as String?,
      category: ItemCategory.values.asNameMap()[r['category']] ?? ItemCategory.other,
      price: r['price'] == null
          ? null
          : Money(r['price'] as num, r['currency'] as String),
      purchase: Purchase(
        date: DateTime.parse(r['purchased_on'] as String),
        region: r['region'] as String,
        channel: r['channel'] == 'online' ? SalesChannel.online : SalesChannel.store,
        manufacturer: lifetime
            ? const ManufacturerWarranty.lifetime()
            : ManufacturerWarranty.months(months ?? 0),
        extendedUntil: r['extended_until'] == null
            ? null
            : DateTime.parse(r['extended_until'] as String),
      ),
    );
  }

  static Map<String, dynamic> _toRow(Item i) => {
        'name': i.name,
        'store': i.store,
        'serial': i.serial,
        'category': i.category.name,
        'price': i.price?.amount,
        'currency': i.price?.currency,
        'purchased_on': i.purchase.date.toIso8601String().substring(0, 10),
        'region': i.purchase.region,
        'channel': i.purchase.channel.name,
        'manufacturer_months': i.purchase.manufacturer.months,
        'manufacturer_lifetime': i.purchase.manufacturer.lifetime,
        'extended_until': i.purchase.extendedUntil?.toIso8601String().substring(0, 10),
      };
}
