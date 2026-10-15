import 'item.dart';

/// A shelf in the cabinet. The label is the user's own word for it
/// ("Mutfak", "Kamp", "Çocuk odası"); empty until they stick one on.
class Shelf {
  const Shelf({required this.id, this.label = ''});
  final String id;
  final String label;

  Shelf withLabel(String label) => Shelf(id: id, label: label);

  Map<String, Object?> toJson() => {'id': id, 'label': label};
  static Shelf fromJson(Map<String, dynamic> j) =>
      Shelf(id: j['id'] as String, label: j['label'] as String? ?? '');
}

/// Everything the user keeps: items in shelf order, then the shelves.
///
/// Item order matters: within a shelf, items stand left to right in list
/// order, and when a shelf overflows the last one moves down.
class Vault {
  const Vault({this.items = const [], this.shelves = const []});
  final List<Item> items;
  final List<Shelf> shelves;

  List<Item> get active => [for (final i in items) if (i.active) i];
  List<Item> get disposed => [for (final i in items) if (!i.active) i];

  List<Item> on(String shelfId) =>
      [for (final i in items) if (i.active && i.shelfId == shelfId) i];

  int shelfIndexOf(String itemId) {
    final item = items.firstWhere((i) => i.id == itemId);
    return shelves.indexWhere((s) => s.id == item.shelfId);
  }

  Map<String, Object?> toJson() => {
        'version': 1,
        'items': [for (final i in items) i.toJson()],
        'shelves': [for (final s in shelves) s.toJson()],
      };

  static Vault fromJson(Map<String, dynamic> j) => Vault(
        items: [for (final i in (j['items'] as List? ?? const [])) Item.fromJson(i as Map<String, dynamic>)],
        shelves: [for (final s in (j['shelves'] as List? ?? const [])) Shelf.fromJson(s as Map<String, dynamic>)],
      );
}

/// How many items stand on one shelf. A count, not a width: the same vault
/// must look the same on a 320-pt phone and on an iPad, or items would
/// silently change shelves when the user switches devices. 4 fits the
/// narrowest supported phone with ≥ 66-pt products.
const shelfCapacity = 4;

/// The cabinet's rules, in one pure function so they can be tested without
/// physics or widgets:
/// 1. A shelf holds at most [shelfCapacity] items; the overflow moves down,
///    shelf by shelf, creating new shelves ("more things, more shelves").
/// 2. There is always one empty, unlabelled shelf at the bottom, so there
///    is always a place to drag something to and a label left to write.
/// 3. An empty shelf in the middle disappears, unless the user labelled it
///    (a labelled shelf is a decision, an unlabelled empty one is a gap).
/// 4. Items without a valid shelf go to the first shelf with room.
Vault normalize(Vault v, {required String Function() newShelfId}) {
  final shelves = [...v.shelves];
  if (shelves.isEmpty) shelves.add(Shelf(id: newShelfId()));

  final groups = <List<Item>>[for (final _ in shelves) []];
  final homeless = <Item>[];
  for (final item in v.items.where((i) => i.active)) {
    final at = shelves.indexWhere((s) => s.id == item.shelfId);
    (at < 0 ? homeless : groups[at]).add(item);
  }
  for (final item in homeless) {
    var at = groups.indexWhere((g) => g.length < shelfCapacity);
    if (at < 0) {
      shelves.add(Shelf(id: newShelfId()));
      groups.add([]);
      at = groups.length - 1;
    }
    groups[at].add(item);
  }

  for (var s = 0; s < groups.length; s++) {
    while (groups[s].length > shelfCapacity) {
      if (s + 1 == groups.length) {
        shelves.add(Shelf(id: newShelfId()));
        groups.add([]);
      }
      // The newest arrival on a full shelf is the one that moves on, and it
      // goes to the front of the next shelf so it stays near where it was put.
      groups[s + 1].insert(0, groups[s].removeLast());
    }
  }

  for (var s = shelves.length - 2; s >= 0; s--) {
    if (groups[s].isEmpty && shelves[s].label.trim().isEmpty) {
      shelves.removeAt(s);
      groups.removeAt(s);
    }
  }
  // A labelled empty shelf is the user's; the free one below it is ours.
  if (groups.last.isNotEmpty || shelves.last.label.trim().isNotEmpty) {
    shelves.add(Shelf(id: newShelfId()));
    groups.add([]);
  }

  return Vault(
    shelves: shelves,
    items: [
      for (var s = 0; s < shelves.length; s++)
        for (final item in groups[s]) item.copyWith(shelfId: shelves[s].id),
      ...v.items.where((i) => !i.active),
    ],
  );
}

/// Puts [itemId] on shelf [shelfIndex] at position [insertAt] (0 = leftmost),
/// then lets [normalize] push any overflow down.
Vault moveItem(Vault v, String itemId, int shelfIndex, int insertAt,
    {required String Function() newShelfId}) {
  final shelf = v.shelves[shelfIndex];
  final moving = v.items.firstWhere((i) => i.id == itemId).copyWith(shelfId: shelf.id);
  final rest = [for (final i in v.items) if (i.id != itemId) i];
  final onShelf = [for (final (n, i) in rest.indexed) if (i.active && i.shelfId == shelf.id) n];
  final int at;
  if (onShelf.isEmpty) {
    // Empty shelf: after the last active item of any shelf above it, which
    // keeps list order equal to shelf order.
    final above = {for (final s in v.shelves.take(shelfIndex)) s.id};
    final lastAbove = rest.lastIndexWhere((i) => i.active && above.contains(i.shelfId));
    at = lastAbove + 1;
  } else if (insertAt >= onShelf.length) {
    at = onShelf.last + 1;
  } else {
    at = onShelf[insertAt < 0 ? 0 : insertAt];
  }
  rest.insert(at, moving);
  return normalize(Vault(items: rest, shelves: v.shelves), newShelfId: newShelfId);
}
