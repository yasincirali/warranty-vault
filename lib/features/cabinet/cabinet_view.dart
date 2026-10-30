import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/cover_observer.dart';
import '../../core/ui/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../rights/rights_engine.dart';
import '../items/data/vault_store.dart';
import '../items/domain/item.dart';
import '../items/domain/vault.dart';
import '../items/providers.dart';
import '../items/ui/item_photo.dart';
import 'bend.dart';
import 'shelf_physics.dart';

/// The home of the app: the user's things standing on shelves.
///
/// Every gesture is a decision, not decoration (yasin, Tur 5):
/// - drag a product to another shelf → it now belongs to that shelf/label;
/// - flick it sideways out of the cabinet → thrown out (undo offered);
/// - tap → its rights and receipt;
/// - tap a shelf's Dymo label → name the shelf.
/// VoiceOver/TalkBack get the same decisions as custom actions on each
/// product, so nothing depends on being able to drag.
class CabinetView extends ConsumerStatefulWidget {
  const CabinetView({
    super.key,
    required this.vault,
    required this.views,
    required this.today,
    required this.width,
    required this.onOpen,
    required this.onDiscard,
  });

  final Vault vault;
  final Map<String, ItemView> views;
  final DateTime today;
  final double width;
  final void Function(String id) onOpen;
  final void Function(String id) onDiscard;

  @override
  ConsumerState<CabinetView> createState() => _CabinetViewState();
}

/// Which way a product moves follows what it is (see [Feel]).
Feel feelOf(ItemCategory c) => switch (c) {
  ItemCategory.laptop => Feel.laptop,
  ItemCategory.phone => Feel.phone,
  ItemCategory.headphones => Feel.headphones,
  ItemCategory.tv => Feel.tv,
  ItemCategory.appliance => Feel.appliance,
  ItemCategory.vacuum => Feel.vacuum,
  ItemCategory.other => Feel.other,
};

/// Gap between the cabinet's sides and the screen edge.
const _wallInset = 4.0;

/// How deep into the plank's lit top a product stands. Its base covers the
/// back of the board and leaves the front strip visible: that overlap is
/// what makes the product read as standing *on* the shelf, not in front of it.
const _standDepth = 5.0;

class _CabinetViewState extends ConsumerState<CabinetView> with SingleTickerProviderStateMixin {
  late ShelfPhysics _world;
  late final Ticker _ticker = createTicker(_tick);
  final _frame = ValueNotifier<int>(0);
  final _canvasKey = GlobalKey();
  Duration _last = Duration.zero;
  Vault? _synced;
  double _syncedWidth = 0;

  // The one product under the finger.
  String? _grabbed;
  int? _pointer;
  Offset _downAt = Offset.zero;
  Duration _downTime = Duration.zero;
  Offset _lastGlobal = Offset.zero;
  Offset _grabOffset = Offset.zero;
  bool _lifted = false;
  final _trail = <(Duration, Offset)>[];

  // New products wait here until the add screen has slid away and their
  // shelf is on screen; then they fall in from the top (yasin, 15 Oct:
  // "yeni ürün objesiyle birlikte rafına tepeden düşmeli").
  final _pending = <String, (Body, int, int)>{};
  double _dropIn = 0;

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  @override
  void initState() {
    super.initState();
    _world = ShelfPhysics(CabinetGeometry(width: widget.width, shelves: math.max(1, widget.vault.shelves.length)));
  }

  @override
  void dispose() {
    if (_listening) coverObserver.removeListener(_onCoverChange);
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _wake() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  /// Brings the bodies in line with the saved vault. Called from build when
  /// the vault or the width changed.
  void _sync() {
    final v = widget.vault;
    final first = _synced == null;
    final geo = CabinetGeometry(width: widget.width, shelves: math.max(1, v.shelves.length));
    _world.geo = geo;
    final keep = <String>{};
    for (final (s, shelf) in v.shelves.indexed) {
      for (final (k, item) in v.on(shelf.id).indexed) {
        keep.add(item.id);
        final size = geo.sizeFor(item.photoPath == null ? CategoryArt.aspect(item.category) : item.photoAspect ?? 1);
        var b = _world.bodies[item.id];
        if (b == null) {
          b = Body(id: item.id, x: 0, y: 0, w: size.w, h: size.h, feel: feelOf(item.category));
          if (first) {
            // On first open everything is already standing there.
            _world.bodies[item.id] = b;
            _world.place(b, s, k);
          } else if (_reduceMotion) {
            // Reduce motion: no fall, the product fades in where it belongs.
            _world.bodies[item.id] = b;
            _world.place(b, s, k);
            b.appear = 0;
            HapticFeedback.lightImpact();
          } else {
            keep.add(item.id);
            _pending[item.id] = (b, s, k);
            continue;
          }
        } else {
          b
            ..w = size.w
            ..h = size.h
            ..feel = feelOf(item.category);
          final widthChanged = _syncedWidth != widget.width;
          if (!b.held && !b.flying && (geo.bandAt(b.y) != s || widthChanged)) {
            _world.place(b, s, k, drop: !_reduceMotion && !widthChanged);
          }
        }
      }
    }
    _world.bodies.removeWhere((id, b) => !keep.contains(id) && !b.flying);
    _pending.removeWhere((id, _) => !keep.contains(id));
    _synced = v;
    _syncedWidth = widget.width;
    if (_pending.isNotEmpty) _waitForCover();
    _wake();
  }

  /// The add screen is still covering the cabinet when the vault changes;
  /// a fall nobody sees is wasted. Wait until nothing is above this screen
  /// and the closing one has finished sliding away.
  void _waitForCover() {
    if (_covered) {
      if (!_listening) {
        _listening = true;
        coverObserver.addListener(_onCoverChange);
      }
      return;
    }
    _bringShelfIntoView();
  }

  bool get _covered => !(ModalRoute.of(context)?.isCurrent ?? true) || coverObserver.busy;
  bool _listening = false;

  void _onCoverChange() {
    if (!mounted || _covered) return;
    coverObserver.removeListener(_onCoverChange);
    _listening = false;
    _bringShelfIntoView();
  }

  /// Scrolls the new product's shelf into view, then drops it in once the
  /// scroll has settled ([_tick] counts [_dropIn] down).
  void _bringShelfIntoView() {
    final box = _canvas;
    if (box == null || _pending.isEmpty) return;
    final shelf = _pending.values.map((p) => p.$2).reduce(math.max);
    final geo = _world.geo;
    box.showOnScreen(
      rect: Rect.fromLTWH(0, geo.bandTop(shelf), widget.width, CabinetGeometry.band),
      duration: _scrollIn,
      curve: Curves.easeOutCubic,
    );
    _dropIn = _scrollIn.inMicroseconds / 1e6;
    _wake();
  }

  static const _scrollIn = Duration(milliseconds: 280);

  void _dropPending() {
    final box = _canvas;
    final scrollable = Scrollable.maybeOf(context);
    final vp = scrollable?.context.findRenderObject() as RenderBox?;
    // The visible top edge, in cabinet coordinates.
    var screenTop = 0.0;
    if (box != null && vp != null && vp.hasSize) {
      screenTop = box.globalToLocal(vp.localToGlobal(Offset.zero)).dy;
    }
    var stagger = 0.0;
    for (final (b, s, k) in _pending.values) {
      _world.bodies[b.id] = b;
      // Several at once (sample cabinet) fall one after another, 60 px apart.
      _world.dropFrom(b, s, k, screenTop - b.h / 2 - 8 - stagger);
      stagger += 60;
    }
    _pending.clear();
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 30);
    _last = elapsed;
    if (_pending.isNotEmpty && !_listening && _dropIn > 0) {
      _dropIn -= dt;
      if (_dropIn <= 0) _dropPending();
    }
    if (_grabbed != null && _lifted) {
      _autoScroll();
      _aim();
    }
    final gone = _world.step(dt, tilt: !_reduceMotion);
    for (final id in gone) {
      widget.onDiscard(id);
    }
    if (_world.landed.isNotEmpty) HapticFeedback.lightImpact();
    _frame.value++;
    if (_world.resting && _grabbed == null && (_pending.isEmpty || _dropIn <= 0)) _ticker.stop();
  }

  RenderBox? get _canvas => _canvasKey.currentContext?.findRenderObject() as RenderBox?;

  void _aim() {
    final b = _world.bodies[_grabbed];
    final box = _canvas;
    if (b == null || box == null) return;
    final p = box.globalToLocal(_lastGlobal) - _grabOffset;
    b.targetX = p.dx.clamp(-b.w, widget.width + b.w);
    b.targetY = p.dy.clamp(b.h / 2, _world.geo.height - b.h / 2);
  }

  /// Dragging near the top or bottom edge scrolls, so a product can be
  /// carried to a shelf that is off screen.
  void _autoScroll() {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;
    final pos = scrollable.position;
    final vp = scrollable.context.findRenderObject() as RenderBox?;
    if (vp == null || !vp.hasSize) return;
    final top = vp.localToGlobal(Offset.zero).dy;
    final bottom = top + vp.size.height;
    const edge = 72.0;
    double delta = 0;
    if (_lastGlobal.dy < top + edge) delta = -14 * (1 - (_lastGlobal.dy - top) / edge);
    if (_lastGlobal.dy > bottom - edge) delta = 14 * (1 - (bottom - _lastGlobal.dy) / edge);
    if (delta == 0) return;
    final to = (pos.pixels + delta).clamp(pos.minScrollExtent, pos.maxScrollExtent);
    if (to != pos.pixels) pos.jumpTo(to);
  }

  void _down(String id, PointerDownEvent e) {
    if (_grabbed != null) return;
    final b = _world.bodies[id];
    final box = _canvas;
    if (b == null || box == null || b.flying) return;
    _grabbed = id;
    _pointer = e.pointer;
    _downAt = e.position;
    _downTime = e.timeStamp;
    _lastGlobal = e.position;
    _lifted = false;
    _grabOffset = box.globalToLocal(e.position) - Offset(b.x, b.y);
    _trail
      ..clear()
      ..add((e.timeStamp, e.position));
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    _lastGlobal = e.position;
    _trail.add((e.timeStamp, e.position));
    while (_trail.length > 2 && e.timeStamp - _trail.first.$1 > const Duration(milliseconds: 90)) {
      _trail.removeAt(0);
    }
    if (!_lifted && (e.position - _downAt).distance > 6) {
      _lifted = true;
      _world.bodies[_grabbed]?.held = true;
      HapticFeedback.selectionClick();
    }
    if (_lifted) {
      _aim();
      _wake();
    }
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    final id = _grabbed!;
    _grabbed = null;
    _pointer = null;
    if (!_lifted) {
      if (e.timeStamp - _downTime < const Duration(milliseconds: 450)) widget.onOpen(id);
      return;
    }
    var v = Offset.zero;
    if (_trail.length >= 2) {
      final dt = (_trail.last.$1 - _trail.first.$1).inMicroseconds / 1e6;
      if (dt > 0) v = (_trail.last.$2 - _trail.first.$2) / dt;
    }
    _settle(id, v);
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer != _pointer) return;
    final id = _grabbed!;
    _grabbed = null;
    _pointer = null;
    if (_lifted) _settle(id, Offset.zero);
  }

  void _settle(String id, Offset v) {
    final thrown = _world.release(id, v.dx, v.dy, allowFling: true);
    _wake();
    if (thrown) {
      HapticFeedback.mediumImpact();
      if (_reduceMotion) {
        _world.bodies.remove(id);
        widget.onDiscard(id);
      }
      return;
    }
    final b = _world.bodies[id]!;
    final to = _world.geo.bandAt(b.y);
    if (to != widget.vault.shelfIndexOf(id)) {
      HapticFeedback.lightImpact();
      _moveTo(id, to, b.x);
    }
  }

  void _moveTo(String id, int shelf, double x) {
    final others = widget.vault.on(widget.vault.shelves[shelf].id).where((i) => i.id != id);
    final at = others.where((i) => (_world.bodies[i.id]?.x ?? 0) < x).length;
    ref.read(vaultProvider.notifier).move(id, shelf, at);
  }

  /// Screen-reader path for the same decisions.
  void _step(String id, int delta) {
    final from = widget.vault.shelfIndexOf(id);
    final to = (from + delta).clamp(0, widget.vault.shelves.length - 1);
    if (to == from) return;
    ref.read(vaultProvider.notifier).move(id, to, shelfCapacity);
  }

  @override
  Widget build(BuildContext context) {
    if (!identical(_synced, widget.vault) || _syncedWidth != widget.width) _sync();
    final geo = _world.geo;
    final l = AppLocalizations.of(context);
    final store = ref.watch(vaultStoreProvider);

    return SizedBox(
      key: _canvasKey,
      width: widget.width,
      height: geo.height,
      // Not clipped: a new product falls in from the top of the screen, above
      // the cabinet; the scroll view clips at the screen edges.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // One cabinet, not stripes across the page: a back wall a step
          // darker than the page, rounded like a piece of furniture.
          Positioned.fill(
            left: _wallInset,
            right: _wallInset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.c.wall,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(VRadius.md)),
              ),
            ),
          ),
          // Inner sides of the cabinet in soft shade: reads as a box with
          // depth, not a coloured band.
          for (final left in [true, false])
            Positioned(
              top: 0,
              bottom: 0,
              left: left ? _wallInset : null,
              right: left ? null : _wallInset,
              width: 16,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: left ? Alignment.centerLeft : Alignment.centerRight,
                      end: left ? Alignment.centerRight : Alignment.centerLeft,
                      colors: [context.c.shade.withValues(alpha: .06), context.c.shade.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
          for (var s = 0; s < geo.shelves; s++) ...[
            // Light down the wall from the top of the bay (dark theme only;
            // transparent in light), under the shade line below.
            Positioned(
              left: _wallInset,
              right: _wallInset,
              top: geo.bandTop(s),
              height: geo.plankTop(s) - geo.bandTop(s),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: s == 0 ? const BorderRadius.vertical(top: Radius.circular(VRadius.md)) : null,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [context.c.wallLight, context.c.wallLight.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
            // Shade cast on the wall by the cabinet top or the plank above.
            Positioned(
              left: _wallInset,
              right: _wallInset,
              top: geo.bandTop(s),
              height: 28,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: s == 0 ? const BorderRadius.vertical(top: Radius.circular(VRadius.md)) : null,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [context.c.shade.withValues(alpha: .07), context.c.shade.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: _wallInset,
              right: _wallInset,
              top: geo.plankTop(s),
              height: CabinetGeometry.plank,
              child: const _Plank(),
            ),
            if (s < widget.vault.shelves.length)
              Positioned(
                left: CabinetGeometry.sidePad,
                top: geo.bandTop(s),
                child: _DymoLabel(
                  key: ValueKey('label-${widget.vault.shelves[s].id}'),
                  index: s,
                  shelf: widget.vault.shelves[s],
                  onChanged: (t) => ref.read(vaultProvider.notifier).relabel(widget.vault.shelves[s].id, t),
                ),
              ),
          ],
          Positioned.fill(
            child: ValueListenableBuilder<int>(
              valueListenable: _frame,
              builder: (context, _, _) => Stack(
                clipBehavior: Clip.none,
                children: [for (final b in _world.bodies.values) ..._bodyWidgets(context, l, b, store)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _bodyWidgets(BuildContext context, AppLocalizations l, Body b, VaultStore store) {
    final view = widget.views[b.id];
    if (view == null) return const [];
    final shelfIndex = widget.vault.shelves.indexWhere((s) => s.id == view.item.shelfId);
    final shelf = shelfIndex < 0 ? null : widget.vault.shelves[shelfIndex];
    final shelfText = shelf == null ? '' : (shelf.label.isEmpty ? l.shelfName(shelfIndex + 1) : shelf.label);
    final days = view.next?.daysLeft(widget.today);
    final p = view.primary;
    final status = p == null || p.status != ProtectionStatus.active
        ? l.protectionEnded
        : l.statusLine(kindLabel(l, p.kind), p.end == null ? l.noFixedEnd : remainingLabel(l, widget.today, p.end!));

    final plankTop = _world.geo.plankTop(_world.geo.bandAt(b.y));
    // Contact shadow: full when standing, fading as the product is lifted,
    // so "picked up" reads without any extra chrome.
    final lift = ((plankTop - b.bottom) / 80).clamp(0.0, 1.0);
    final sink = _standDepth * (1 - lift);
    final product = _Product(item: view.item, store: store, lifted: b.held);
    // Every protection over: the product greys and fades on its shelf, so
    // the cabinet answers "what is still covered" at a glance (Rafım Ar-Ge
    // 25 Oct). Muted = ended is the design language's rule; the label
    // already says "protection ended" in words.
    final spent = view.protections.isNotEmpty && view.protections.every((p) => p.status == ProtectionStatus.ended);

    return [
      // Cast shadow on the back wall: the product's own silhouette, up and
      // to the right of it (light from the top left). Lifting the product
      // pulls it off the wall, so the shadow drifts further and softens.
      if (!b.flying)
        Positioned(
          left: b.left + 4 + 10 * lift,
          top: b.top - 3 - 6 * lift + sink,
          width: b.w,
          height: b.h,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Opacity(
                opacity: b.appear,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 5 + 6 * lift, sigmaY: 5 + 6 * lift),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(context.c.shade.withValues(alpha: .16), BlendMode.srcIn),
                    child: _Silhouette(item: view.item, store: store),
                  ),
                ),
              ),
            ),
          ),
        ),
      // Contact shadow where the base meets the board: tight and dark while
      // standing, fading as the product is lifted.
      if (!b.flying)
        Positioned(
          left: b.x - b.w * .4,
          top: plankTop + sink - 4,
          width: b.w * .8,
          height: 8,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: const OvalBorder(),
                shadows: [
                  BoxShadow(
                    color: context.c.shade.withValues(alpha: .28 * (1 - lift)),
                    blurRadius: 5 + 12 * lift,
                  ),
                ],
              ),
            ),
          ),
        ),
      // Deadline tag hangs on the plank under the product: amber and a
      // number, so it reads without colour too. Only for < 30 days.
      if (days != null && !b.flying && !b.held && b.grounded)
        Positioned(
          left: (b.x - 34).clamp(2.0, widget.width - 70),
          top: plankTop + _Plank.top + 1,
          width: 68,
          child: ExcludeSemantics(child: _DeadlineTag(text: l.durDays(days))),
        ),
      Positioned(
        left: b.left,
        top: b.top + sink,
        width: b.w,
        height: b.h,
        child: Transform(
          alignment: Alignment.bottomCenter,
          // Squash keeps the volume roughly: shorter and a little wider.
          transform: Matrix4.diagonal3Values(1 + b.squash * .6, 1 - b.squash, 1),
          child: Transform.rotate(
            angle: b.angle,
            child: Opacity(
              opacity: b.appear * (spent ? .55 : 1),
              child: Semantics(
                button: true,
                label: l.itemA11y(
                  view.item.name,
                  days != null ? l.endsIn(kindLabel(l, view.next!.kind), days) : status,
                  shelfText,
                ),
                onTap: () => widget.onOpen(b.id),
                customSemanticsActions: {
                  CustomSemanticsAction(label: l.moveUp): () => _step(b.id, -1),
                  CustomSemanticsAction(label: l.moveDown): () => _step(b.id, 1),
                  CustomSemanticsAction(label: l.throwOut): () => widget.onDiscard(b.id),
                },
                child: _Grip(
                  key: ValueKey('item-${b.id}'),
                  onDown: (e) => _down(b.id, e),
                  onMove: _move,
                  onUp: _up,
                  onCancel: _cancel,
                  child: ExcludeSemantics(
                    // Lifts off the shelf into the product page (itemHeroTag);
                    // with reduce motion the page just opens.
                    child: HeroMode(
                      enabled: !MediaQuery.disableAnimationsOf(context),
                      child: Hero(
                        tag: itemHeroTag(b.id),
                        flightShuttleBuilder: itemHeroShuttle,
                        // Light outside the bend: Bend paints its child once per band, which
                        // only works for a child that draws without its own layers.
                        child: _Faded(
                          on: spent,
                          child: _Lit(
                            child: Bend(bend: b.bend, feel: b.feel, child: product),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

/// Claims the pointer the moment a product is touched, so the page does not
/// scroll under a drag. Touching anywhere else still scrolls.
class _Grip extends StatelessWidget {
  const _Grip({
    super.key,
    required this.child,
    required this.onDown,
    required this.onMove,
    required this.onUp,
    required this.onCancel,
  });
  final Widget child;
  final void Function(PointerDownEvent) onDown;
  final void Function(PointerMoveEvent) onMove;
  final void Function(PointerUpEvent) onUp;
  final void Function(PointerCancelEvent) onCancel;

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    gestures: {
      EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
        EagerGestureRecognizer.new,
        (_) {},
      ),
    },
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: onDown,
      onPointerMove: onMove,
      onPointerUp: onUp,
      onPointerCancel: onCancel,
      child: child,
    ),
  );
}

class _Product extends StatelessWidget {
  const _Product({required this.item, required this.store, required this.lifted});
  final Item item;
  final VaultStore store;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final path = item.photoPath;
    if (path != null) {
      final image = LayoutBuilder(
        builder: (context, box) => Image(
          image: decodedAt(store.photo(path), box.biggest, MediaQuery.devicePixelRatioOf(context)),
          fit: item.photoCutout ? BoxFit.contain : BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => _Drawn(item: item),
        ),
      );
      return item.photoCutout ? image : ClipRRect(borderRadius: BorderRadius.circular(VRadius.sm), child: image);
    }
    return _Drawn(item: item);
  }
}

/// A product without a photo: its category's drawing standing on the shelf
/// like a cut-out photo, with its name on a small paper tag, because two
/// laptops drawn alike are told apart by name.
class _Drawn extends StatelessWidget {
  const _Drawn({required this.item});
  final Item item;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.bottomCenter,
    children: [
      Positioned.fill(
        child: Image.asset(
          CategoryArt.asset(item.category),
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          filterQuality: FilterQuality.medium,
        ),
      ),
      // Hangs over the product's foot, inside its box so it moves, bends
      // and is thrown out together with it.
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 76),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: context.c.surface,
            border: Border.all(color: context.c.border),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // The product is a fixed-size physical object; its tag is a
            // hint, the full name is in the accessibility label and detail.
            textScaler: TextScaler.noScaling,
            style: context.t.micro,
          ),
        ),
      ),
    ],
  );
}

/// A board seen slightly from above: its lit top (the depth a product stands
/// in), its front edge in shade where deadline tags hang, and the soft shadow
/// it throws on the wall below.
class _Plank extends StatelessWidget {
  const _Plank();

  /// Visible depth of the board's top surface.
  static const top = 10.0;

  /// Front edge, tall enough for a deadline tag.
  static const front = 22.0;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: top,
          decoration: BoxDecoration(
            // Back of the board meets the wall in shade, front catches light.
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.alphaBlend(c.shade.withValues(alpha: .06), c.plankTop), c.plankTop],
            ),
          ),
        ),
        Container(
          height: front,
          decoration: BoxDecoration(
            color: c.plankFront,
            border: Border(
              top: BorderSide(color: c.plankTop.withValues(alpha: .9)),
              bottom: BorderSide(color: c.shade.withValues(alpha: .12)),
            ),
          ),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.shade.withValues(alpha: .12), c.shade.withValues(alpha: .04)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The outline a product casts: a cut-out photo's own alpha, otherwise its
/// rounded box. No text inside, so a shadow never doubles a product's name.
class _Silhouette extends StatelessWidget {
  const _Silhouette({required this.item, required this.store});
  final Item item;
  final VaultStore store;

  @override
  Widget build(BuildContext context) {
    final path = item.photoPath;
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: context.c.shade,
        borderRadius: BorderRadius.circular(path == null ? VRadius.md : VRadius.sm),
      ),
    );
    if (path == null || !item.photoCutout) return box;
    return LayoutBuilder(
      builder: (context, size) => Image(
        image: decodedAt(store.photo(path), size.biggest, MediaQuery.devicePixelRatioOf(context)),
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => box,
      ),
    );
  }
}

/// Light from the top left on a product: a faint sheen on top, a little
/// shade towards the base. Drawn only on the product's own pixels (srcATop),
/// so a cut-out photo keeps its outline. Gives a flat photo some volume
/// without pretending to be a 3D model.
/// Greyscale for a product whose protections are all over. Outside the
/// Bend, like the light: a colour filter is a layer of its own.
class _Faded extends StatelessWidget {
  const _Faded({required this.on, required this.child});
  final bool on;
  final Widget child;

  static const _grey = ColorFilter.matrix([
    .2126, .7152, .0722, 0, 0, //
    .2126, .7152, .0722, 0, 0,
    .2126, .7152, .0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) => on ? ColorFiltered(colorFilter: _grey, child: child) : child;
}

class _Lit extends StatelessWidget {
  const _Lit({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shade = context.c.shade;
    final sheen = context.c.plankTop;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (r) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0, .45, 1],
        colors: [sheen.withValues(alpha: .18), sheen.withValues(alpha: 0), shade.withValues(alpha: .18)],
      ).createShader(r),
      child: child,
    );
  }
}

class _DeadlineTag extends StatelessWidget {
  const _DeadlineTag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.c.deadlineSurface,
        border: Border.all(color: context.c.deadline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        maxLines: 1,
        textScaler: TextScaler.noScaling,
        style: context.t.tag.copyWith(color: context.c.deadline),
      ),
    ),
  );
}

/// Label-maker tape stuck to the back wall of a shelf. Empty shelves show a
/// faint "+ Label" so the feature is discoverable without a tutorial.
class _DymoLabel extends StatefulWidget {
  const _DymoLabel({super.key, required this.index, required this.shelf, required this.onChanged});
  final int index;
  final Shelf shelf;
  final void Function(String) onChanged;

  @override
  State<_DymoLabel> createState() => _DymoLabelState();
}

class _DymoLabelState extends State<_DymoLabel> {
  bool _editing = false;
  late final _text = TextEditingController(text: widget.shelf.label);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _finish();
    });
  }

  @override
  void didUpdateWidget(_DymoLabel old) {
    super.didUpdateWidget(old);
    if (!_editing && old.shelf.label != widget.shelf.label) _text.text = widget.shelf.label;
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _finish() {
    setState(() => _editing = false);
    if (_text.text.trim() != widget.shelf.label) widget.onChanged(_text.text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final empty = widget.shelf.label.isEmpty;
    // Round 6: smaller tape. At 13 pt bold the three black labels were the
    // loudest thing on the cabinet and the products came second.
    // Rafım Ar-Ge 25 Oct (yasin "yap"): white tape with ink letters. Ink
    // black is the primary action's colour ("Add a product"); three black
    // strips competed with it. Still a label-maker strip, the white kind.
    final tape = context.t.tag.copyWith(
      letterSpacing: 1.4,
      color: empty && !_editing ? context.c.muted : context.c.text,
    );
    final decoration = BoxDecoration(
      color: empty && !_editing ? null : context.c.surface,
      border: Border.all(color: context.c.border),
      borderRadius: BorderRadius.circular(3),
    );

    if (_editing) {
      return Container(
        width: 200,
        height: VSize.minTap - 12,
        margin: const EdgeInsets.only(top: 4),
        decoration: decoration,
        alignment: Alignment.centerLeft,
        child: TextField(
          controller: _text,
          focusNode: _focus,
          autofocus: true,
          maxLength: 24,
          maxLines: 1,
          cursorColor: context.c.text,
          style: tape,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _finish(),
          // A tap anywhere else, or scrolling the cabinet, ends the edit and
          // keeps what was typed (the focus listener saves).
          onTapOutside: (_) => _focus.unfocus(),
          // The keyboard lifts the shelf into view with some of the shelf
          // under its tape, not just the tape on the keyboard's edge.
          scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          decoration: const InputDecoration(
            isDense: true,
            filled: false,
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: empty ? l.shelfNoLabelA11y(widget.index + 1) : l.shelfLabelA11y(widget.index + 1, widget.shelf.label),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _editing = true),
        // 44-pt target around a 24-pt tape.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: VSize.minTap, minWidth: VSize.minTap * 1.6),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            heightFactor: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: decoration,
              child: Text(
                empty ? l.shelfLabelHint : widget.shelf.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.6),
                style: tape,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The cabinet before anything stands in it (UX defteri 26 Ekim): the same
/// wall and planks as a full one, so the first screen already shows what
/// the app is, and one dashed place on the top shelf where the first product
/// goes. Tapping that place does what the "Add product" button does; there
/// is no second way in to choose between.
class EmptyCabinet extends StatelessWidget {
  const EmptyCabinet({super.key, required this.width, required this.onAdd});
  final double width;
  final VoidCallback onAdd;

  static const shelves = 2;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final geo = CabinetGeometry(width: width, shelves: shelves);
    final slotW = geo.slotWidth - 8;
    return SizedBox(
      width: width,
      height: geo.height,
      child: Stack(children: [
        Positioned.fill(
          left: _wallInset,
          right: _wallInset,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.c.wall,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(VRadius.md)),
            ),
          ),
        ),
        for (var s = 0; s < shelves; s++)
          Positioned(
            left: _wallInset,
            right: _wallInset,
            top: geo.plankTop(s),
            height: CabinetGeometry.plank,
            child: const _Plank(),
          ),
        Positioned(
          left: geo.slotX(0) - slotW / 2,
          top: geo.plankTop(0) + _standDepth - CabinetGeometry.maxItemHeight + 8,
          width: slotW,
          height: CabinetGeometry.maxItemHeight - 8,
          child: Semantics(
            button: true,
            label: l.addItem,
            excludeSemantics: true,
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(VRadius.sm),
              child: CustomPaint(
                painter: _DashedBox(color: context.c.textSecondary, radius: VRadius.sm),
                child: Center(child: Icon(Icons.add, size: 28, color: context.c.textSecondary)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// A rounded outline drawn in dashes: "something goes here", the way a
/// placeholder is marked on paper.
class _DashedBox extends CustomPainter {
  const _DashedBox({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(.75));
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 6, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBox old) => old.color != color || old.radius != radius;
}
