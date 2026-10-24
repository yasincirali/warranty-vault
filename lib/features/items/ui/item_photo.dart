import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/ui/widgets.dart';
import '../domain/item.dart';
import '../providers.dart';

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
