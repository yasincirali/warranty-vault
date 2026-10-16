import '../items/domain/item.dart';

/// Words that give a product's kind away, in the languages the app speaks
/// plus the brand and model names people actually type ("Dyson V12",
/// "AirPods"). Only a suggestion: the add form preselects it until the
/// user picks a kind themselves, so a wrong guess costs one tap.
const _words = <ItemCategory, List<String>>{
  // Earbuds first: "Pixel Buds" and "Galaxy Buds" carry a phone's name.
  ItemCategory.headphones: [
    'kulaklık',
    'kulaklik',
    'headphone',
    'earbud',
    'airpods',
    'buds',
    'wh-1000',
    'qc45',
    'beats',
  ],
  ItemCategory.laptop: [
    'laptop',
    'notebook',
    'macbook',
    'dizüstü',
    'dizustu',
    'thinkpad',
    'chromebook',
    'zenbook',
    'vivobook',
  ],
  ItemCategory.phone: [
    'phone',
    'telefon',
    'iphone',
    'pixel',
    'galaxy s',
    'galaxy a',
    'galaxy z',
    'xiaomi',
    'redmi',
    'oneplus',
  ],
  ItemCategory.tv: ['televizyon', 'tv', 'oled', 'qled', 'bravia', 'monitor', 'monitör'],
  ItemCategory.vacuum: ['süpürge', 'supurge', 'vacuum', 'dyson v', 'roomba', 'roborock', 'staubsauger'],
  ItemCategory.appliance: [
    'çamaşır',
    'camasir',
    'bulaşık',
    'bulasik',
    'buzdolabı',
    'buzdolabi',
    'fırın',
    'firin',
    'kurutma',
    'washing',
    'washer',
    'dryer',
    'dishwasher',
    'fridge',
    'refrigerator',
    'oven',
    'microwave',
    'mikrodalga',
    'kahve makinesi',
    'coffee machine',
    'espresso',
    'klima',
    'kettle',
    'su ısıtıcı',
    'airfryer',
    'air fryer',
  ],
};

/// The kind [name] most likely is, or null when nothing in it says so.
/// Whole words only for short ones ("tv" must not match "Etvos").
ItemCategory? guessCategory(String name) {
  final n = name.toLowerCase();
  if (n.trim().isEmpty) return null;
  for (final MapEntry(key: kind, value: words) in _words.entries) {
    for (final w in words) {
      final hit = w.length <= 3
          ? RegExp('(^|[^a-zçğıöşü])${RegExp.escape(w)}([^a-zçğıöşü]|\$)').hasMatch(n)
          : n.contains(w);
      if (hit) return kind;
    }
  }
  return null;
}
