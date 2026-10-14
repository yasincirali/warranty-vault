import '../domain/item.dart';

abstract interface class ItemRepository {
  Future<List<Item>> list();
  Future<Item> add(Item item);
}
