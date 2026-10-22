import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/items/domain/item.dart';
import '../theme/tokens.dart';

/// White card with a hairline border; the only container style in the app.
class VCard extends StatelessWidget {
  const VCard({super.key, required this.child, this.padding, this.color, this.borderColor, this.borderWidth = 1});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? context.c.surface,
      border: Border.all(color: borderColor ?? context.c.border, width: borderWidth),
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

/// The picture a product without a photo gets, one per category: modelled
/// and lit in Blender (`tool/3d/urunler.py`) so it sits on the shelf like
/// the cut-out photos around it; flat drawings read as another world next
/// to a photo (17 Oct). Cut out, no shadow: the shelf draws its own. A
/// product you didn't photograph still stands on the shelf as a thing, not
/// as a grey box with an icon (yasin, 16 Oct).
abstract final class CategoryArt {
  static String asset(ItemCategory c) => 'assets/kategori/${c.name}.png';

  /// Width / height of each drawing, so the cabinet sizes the product before
  /// the image has loaded and nothing jumps.
  static double aspect(ItemCategory c) => switch (c) {
    ItemCategory.laptop => 1.009,
    ItemCategory.phone => 0.463,
    ItemCategory.headphones => 1.365,
    ItemCategory.tv => 1.376,
    ItemCategory.appliance => 0.659,
    ItemCategory.vacuum => 0.456,
    ItemCategory.other => 1.336,
  };
}

/// Placeholder until the user's product photo exists: the category drawing
/// on the neutral tile. Neutral on purpose: a coloured tile would suggest a
/// status it does not have.
class ItemThumb extends StatelessWidget {
  const ItemThumb(this.category, {super.key, this.size = 44});
  final ItemCategory category;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .14),
      decoration: BoxDecoration(
        color: context.c.tile,
        borderRadius: BorderRadius.circular(size > 60 ? VRadius.md : VRadius.sm),
      ),
      child: Image.asset(CategoryArt.asset(category), fit: BoxFit.contain, filterQuality: FilterQuality.medium),
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

/// Lifts a field off the page while it (or anything inside it) has focus,
/// with the same shadow a product gets when it is picked up from its shelf.
/// The theme draws the 2-pt ink edge; this adds the depth.
class VFieldLift extends StatefulWidget {
  const VFieldLift({super.key, required this.child});
  final Widget child;

  @override
  State<VFieldLift> createState() => _VFieldLiftState();
}

class _VFieldLiftState extends State<VFieldLift> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onFocusChange: (f) => setState(() => _focused = f),
    child: AnimatedContainer(
      duration: VMotion.of(context, VMotion.quick),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(VRadius.md),
        // Same blur and offset in both states, only the colour moves, so
        // the shadow grows in instead of jumping.
        boxShadow: [
          BoxShadow(
            color: _focused ? context.c.lift : context.c.lift.withValues(alpha: 0),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: widget.child,
    ),
  );
}

/// A small ink check that pops in when a field holds a usable value.
/// State, not decoration: it answers "is this one done?" at a glance.
class VDoneTick extends StatelessWidget {
  const VDoneTick({super.key, required this.visible});
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final d = VMotion.of(context, VMotion.quick);
    return ExcludeSemantics(
      child: AnimatedScale(
        scale: visible ? 1 : .6,
        duration: d,
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: d,
          curve: Curves.easeOutCubic,
          child: Icon(Icons.check_circle_rounded, size: 22, color: context.c.accent),
        ),
      ),
    );
  }
}

/// Two or three choices with a thumb that slides to the chosen one (the
/// iOS segmented control). Replaces Material's SegmentedButton, whose
/// selection jumps; here the eye follows the thumb, so the change is seen.
/// Labels may wrap at large text sizes; the control grows with them.
class VSegment<T> extends StatelessWidget {
  const VSegment({super.key, required this.options, required this.selected, required this.onChanged});
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final n = options.length;
    final at = options.indexWhere((o) => o.$1 == selected);
    final d = VMotion.of(context, VMotion.slide);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: context.c.tile, borderRadius: BorderRadius.circular(VRadius.md)),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: d,
              // Moving on screen: ease in and out, so it neither lurches off
              // nor slams into place.
              curve: Curves.easeInOutCubic,
              alignment: Alignment(n == 1 ? 0 : -1 + 2 * at / (n - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.c.surface,
                    borderRadius: BorderRadius.circular(VRadius.md - 3),
                    border: Border.all(color: context.c.border),
                    boxShadow: [BoxShadow(color: context.c.lift, blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                ),
              ),
            ),
          ),
          // Equal heights when one label wraps at large text sizes.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, (value, label)) in options.indexed)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == at,
                      inMutuallyExclusiveGroup: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (i == at) return;
                          HapticFeedback.selectionClick();
                          onChanged(value);
                        },
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: VSize.minTap),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: VSpace.sm, vertical: VSpace.sm),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: d,
                                curve: Curves.easeInOutCubic,
                                // Merged onto the inherited style: a bare token
                                // style replaces it and loses the font family.
                                style: DefaultTextStyle.of(context).style.merge(context.t.label.copyWith(
                                  color: i == at ? context.c.text : context.c.textSecondary,
                                  fontWeight: i == at ? FontWeight.w600 : FontWeight.w500,
                                )),
                                textAlign: TextAlign.center,
                                child: Text(label),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fields of one form share this tap region, so moving from one field to the
/// next is not an "outside" tap and the keyboard doesn't drop and come back.
const formFieldsGroup = #formFields;

/// Touch phones keep the keyboard up after a tap elsewhere unless a field
/// says otherwise; every field in the app closes it this way (yasin, 16 Oct:
/// "klavye kapatılabilir olmalı").
void dismissKeyboard([PointerDownEvent? _]) => FocusManager.instance.primaryFocus?.unfocus();
