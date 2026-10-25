import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/ui/widgets.dart';
import '../domain/item.dart';
import '../providers.dart';

/// The product's photo flies between its shelf and its page under this
/// tag (Rafım Ar-Ge 25 Oct, yasin "yap"): the cabinet is physical, and a
/// product that vanished on tap broke that. Only the cabinet and the
/// product page carry it; lists on the same page as the cabinet must not,
/// a tag may appear once per screen.
String itemHeroTag(String id) => 'item-photo-$id';

/// Flies the product page's photo both ways, fitted so it keeps its shape
/// between the shelf's box and the page's square.
Widget itemHeroShuttle(BuildContext _, Animation<double> _, HeroFlightDirection dir, BuildContext from, BuildContext to) {
  final page = (dir == HeroFlightDirection.push ? to : from).widget as Hero;
  return FittedBox(child: page.child);
}

/// The user's own photo of the product when there is one, otherwise the
/// category drawing on the neutral tile. Same box size either way so lists don't jump.
class ItemPhoto extends ConsumerWidget {
  const ItemPhoto({super.key, required this.item, this.size = 44});
  final Item item;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = item.photoPath;
    if (path == null) return ItemThumb(item.category, size: size);
    final radius = BorderRadius.circular(size > 60 ? VRadius.md : VRadius.sm);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: context.c.tile, borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        padding: item.photoCutout ? EdgeInsets.all(size * .08) : null,
        child: Image(
          image: decodedAt(ref.watch(vaultStoreProvider).photo(path), Size.square(size), MediaQuery.devicePixelRatioOf(context)),
          fit: item.photoCutout ? BoxFit.contain : BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => ItemThumb(item.category, size: size),
        ),
      ),
    );
  }
}
