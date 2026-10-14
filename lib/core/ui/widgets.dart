import 'package:flutter/material.dart';

import '../../features/items/domain/item.dart';
import '../theme/tokens.dart';

/// White card with a hairline border; the only container style in the app.
class VCard extends StatelessWidget {
  const VCard({super.key, required this.child, this.padding, this.color, this.borderColor});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? context.c.surface,
          border: Border.all(color: borderColor ?? context.c.border),
          borderRadius: BorderRadius.circular(VRadius.lg),
        ),
        child: child,
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: VSpace.sm),
          child: Text(text, style: context.t.section.copyWith(color: context.c.textSecondary)),
        ),
      );
}

/// Placeholder until the user's product photo exists. Neutral on purpose:
/// a coloured tile would suggest a status it does not have.
class ItemThumb extends StatelessWidget {
  const ItemThumb(this.category, {super.key, this.size = 44, this.iconSize = 24});
  final ItemCategory category;
  final double size;
  final double iconSize;

  static IconData iconFor(ItemCategory c) => switch (c) {
        ItemCategory.laptop => Icons.laptop_mac_outlined,
        ItemCategory.phone => Icons.smartphone_outlined,
        ItemCategory.headphones => Icons.headphones_outlined,
        ItemCategory.tv => Icons.tv_outlined,
        ItemCategory.appliance => Icons.local_laundry_service_outlined,
        ItemCategory.vacuum => Icons.cleaning_services_outlined,
        ItemCategory.other => Icons.inventory_2_outlined,
      };

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: context.c.tile,
            borderRadius: BorderRadius.circular(size > 60 ? VRadius.md : VRadius.sm),
          ),
          child: Icon(iconFor(category), size: iconSize, color: context.c.text),
        ),
      );
}

/// 44-pt circular icon button with a mandatory accessibility label.
class VIconButton extends StatelessWidget {
  const VIconButton({super.key, required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          minimumSize: const Size(VSize.minTap, VSize.minTap),
          backgroundColor: context.c.surface,
          foregroundColor: context.c.text,
          side: BorderSide(color: context.c.border),
        ),
      );
}
