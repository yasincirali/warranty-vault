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

/// Parts of Apple Vision's classification labels ("headphones",
/// "computer_laptop", "washing_machine"…) that give a kind away. Matched as
/// parts of the label, so the taxonomy's spelling variants all land. Order
/// matters: "headphones" holds "phone", so headphones are checked first.
const _visionWords = <ItemCategory, List<String>>{
  ItemCategory.headphones: ['headphone', 'earphone', 'earbud', 'headset'],
  ItemCategory.laptop: ['laptop', 'notebook', 'computer'],
  ItemCategory.phone: ['phone', 'smartphone', 'cellphone', 'mobile'],
  ItemCategory.tv: ['television', 'tv', 'monitor', 'screen', 'display'],
  ItemCategory.vacuum: ['vacuum'],
  ItemCategory.appliance: [
    'appliance',
    'washing',
    'washer',
    'dryer',
    'dishwasher',
    'refrigerator',
    'fridge',
    'oven',
    'microwave',
    'coffee',
    'espresso',
    'kettle',
    'toaster',
    'blender',
    'air_conditioner',
    'stove',
  ],
};

/// Below this summed confidence the photo says nothing: no kind is picked
/// rather than a made-up one (a wrong preselection reads as the app being
/// sure). Tuned so one clear label (laptop .6) wins and noise (.1–.2 spread
/// over unrelated labels) does not.
const visionKindThreshold = .35;

/// The kind the photo most likely shows, from Vision's (label, confidence)
/// pairs, or null when no kind gathers [visionKindThreshold]. Each label
/// counts once, for the first kind it matches.
ItemCategory? guessCategoryFromLabels(List<(String, double)> labels) {
  final score = <ItemCategory, double>{};
  for (final (label, confidence) in labels) {
    final parts = label.toLowerCase().split(RegExp('[^a-z]+'));
    kinds:
    for (final MapEntry(key: kind, value: words) in _visionWords.entries) {
      for (final w in words) {
        final hit = w.length <= 3 ? parts.contains(w) : parts.any((p) => p.contains(w));
        if (hit) {
          score[kind] = (score[kind] ?? 0) + confidence;
          break kinds;
        }
      }
    }
  }
  if (score.isEmpty) return null;
  final best = score.entries.reduce((a, b) => a.value >= b.value ? a : b);
  return best.value >= visionKindThreshold ? best.key : null;
}
