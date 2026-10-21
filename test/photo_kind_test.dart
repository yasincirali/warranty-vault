import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/features/capture/category_guess.dart';
import 'package:warranty_vault/features/items/domain/item.dart';

void main() {
  group('kind from the photo (Vision labels)', () {
    test('one clear label picks its kind', () {
      expect(guessCategoryFromLabels([('laptop', .62), ('computer_keyboard', .2)]), ItemCategory.laptop);
      expect(guessCategoryFromLabels([('television', .5)]), ItemCategory.tv);
      expect(guessCategoryFromLabels([('vacuum_cleaner', .41)]), ItemCategory.vacuum);
      expect(guessCategoryFromLabels([('washing_machine', .7)]), ItemCategory.appliance);
    });

    test('headphones are not phones', () {
      expect(guessCategoryFromLabels([('headphones', .55)]), ItemCategory.headphones);
      expect(guessCategoryFromLabels([('cellphone', .5)]), ItemCategory.phone);
    });

    test('labels of one kind add up', () {
      expect(guessCategoryFromLabels([('computer', .2), ('laptop', .2)]), ItemCategory.laptop);
    });

    test('weak or unrelated labels pick nothing rather than a guess', () {
      expect(guessCategoryFromLabels([('laptop', .3)]), isNull);
      expect(guessCategoryFromLabels([('cat', .9), ('sofa', .8)]), isNull);
      expect(guessCategoryFromLabels(const []), isNull);
    });

    test('short words match whole parts only', () {
      // "tv" must not hit a label that merely contains the letters.
      expect(guessCategoryFromLabels([('outvoice', .9)]), isNull);
      expect(guessCategoryFromLabels([('tv', .5)]), ItemCategory.tv);
    });
  });
}
