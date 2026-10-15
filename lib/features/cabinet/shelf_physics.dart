import 'dart:math' as math;

/// Geometry of the cabinet, in logical pixels.
///
/// Each shelf is a band: a strip at the top for its Dymo label, the space
/// the products stand in, and the plank they stand on (whose front carries
/// the deadline tags).
class CabinetGeometry {
  const CabinetGeometry({required this.width, required this.shelves});
  final double width;
  final int shelves;

  static const labelRow = 34.0;
  static const itemSpace = 100.0;
  static const plank = 44.0;
  static const band = labelRow + itemSpace + plank;
  static const sidePad = 12.0;

  /// Tallest a product may stand; 8 pt of headroom under the label row.
  static const maxItemHeight = itemSpace - 8;

  double get height => shelves * band;
  double bandTop(int i) => i * band;
  double plankTop(int i) => bandTop(i) + labelRow + itemSpace;

  double get slotWidth => (width - 2 * sidePad) / 4;

  /// Which shelf a point belongs to (clamped to the existing ones).
  int bandAt(double y) => (y / band).floor().clamp(0, shelves - 1);

  /// Centre x of slot [k] on any shelf.
  double slotX(int k) => sidePad + (k + .5) * slotWidth;

  /// Display size of a product: a photo keeps its aspect ratio inside the
  /// slot; an item without a photo is a square tile.
  ({double w, double h}) sizeFor(double? aspect) {
    final maxW = slotWidth - 8;
    if (aspect == null) {
      final s = math.min(maxW, 80.0);
      return (w: s, h: s);
    }
    var h = 84.0;
    var w = h * aspect;
    if (w > maxW) {
      w = maxW;
      h = math.max(36.0, w / aspect);
    }
    if (w < 44) w = 44; // HIG: never a target under 44 pt.
    return (w: w, h: math.min(h, maxItemHeight));
  }
}

class Body {
  Body({required this.id, required this.x, required this.y, required this.w, required this.h});
  final String id;

  /// Centre.
  double x, y;
  double w, h;
  double vx = 0, vy = 0;

  /// Visual tilt only (radians); collisions stay axis-aligned. A full
  /// rigid-body engine would let things topple and wedge into states the
  /// user cannot read; a tilt that springs back keeps the shelf calm.
  double angle = 0, spin = 0;

  bool held = false;

  /// A new product falling from the top of the screen passes through the
  /// shelves above its own: planks with an index below this are ignored,
  /// and it pushes nothing aside until it lands. -1 = an ordinary body.
  int ghostShelf = -1;

  /// Vertical squash on impact (0 = none, 0.1 = 10% shorter), springing
  /// back with one small overshoot so a landing has weight. Visual only.
  double squash = 0, squashV = 0;

  /// Fades in when "reduce motion" replaces the fall (0 → 1).
  double appear = 1;

  /// Thrown out: no collisions, leaves the screen.
  bool flying = false;
  bool grounded = false;
  double targetX = 0, targetY = 0;

  double get bottom => y + h / 2;
  double get top => y - h / 2;
  double get left => x - w / 2;
  double get right => x + w / 2;
}

/// A tiny, deterministic shelf simulation: gravity, one-way planks, side
/// walls, items pushing each other sideways, a tilt that wobbles on impact.
///
/// Why not Box2D: the Dart binding (forge2d 0.15) is now native FFI, which
/// adds a C toolchain to every iOS build and test run for behaviour this
/// small. This file is ~200 lines, has no platform code and is unit-tested.
class ShelfPhysics {
  ShelfPhysics(this.geo);
  CabinetGeometry geo;
  final bodies = <String, Body>{};

  /// Ids of falling new products that landed during the last [step]
  /// (for the impact haptic).
  final landed = <String>[];

  static const gravity = 2600.0; // px/s²
  static const maxSpeed = 1400.0;

  /// A sideways release faster than this (px/s) is a throw, not a drop:
  /// 1.1 px/ms, tuned in the HTML prototype so a lazy drag never discards.
  static const flingSpeed = 1100.0;

  bool get resting => bodies.values.every(
    (b) =>
        !b.held &&
        !b.flying &&
        b.grounded &&
        b.vx.abs() < 2 &&
        b.vy.abs() < 2 &&
        b.angle.abs() < .002 &&
        b.spin.abs() < .02 &&
        b.squash.abs() < .002 &&
        b.squashV.abs() < .02 &&
        b.appear >= 1,
  );

  /// Advances the world; returns ids of thrown items that left the cabinet.
  List<String> step(double dt, {bool tilt = true}) {
    final gone = <String>[];
    landed.clear();
    for (final b in bodies.values) {
      if (b.appear < 1) b.appear = math.min(1, b.appear + dt / .2);
    }
    const sub = 4;
    final h = dt / sub;
    for (var s = 0; s < sub; s++) {
      for (final b in bodies.values) {
        _integrate(b, h, tilt);
      }
      _separate();
    }
    for (final b in bodies.values) {
      if (b.flying && (b.right < -40 || b.left > geo.width + 40 || b.top > geo.height + 200)) {
        gone.add(b.id);
      }
    }
    for (final id in gone) {
      bodies.remove(id);
    }
    return gone;
  }

  void _integrate(Body b, double dt, bool tilt) {
    if (b.held) {
      // Follows the finger with a short lag so the product feels heavy.
      final k = math.min(1.0, 28 * dt);
      final nx = b.x + (b.targetX - b.x) * k;
      final ny = b.y + (b.targetY - b.y) * k;
      b.vx = (nx - b.x) / dt;
      b.vy = (ny - b.y) / dt;
      b.x = nx;
      b.y = ny;
      b.grounded = false;
      // Hangs from the finger: leans against the direction of travel.
      final want = tilt ? (-b.vx * .0004).clamp(-.35, .35) : 0.0;
      b.angle += (want - b.angle) * math.min(1.0, 14 * dt);
      b.spin = 0;
      return;
    }

    b.vy += gravity * dt;
    if (!b.flying) {
      final sp = math.sqrt(b.vx * b.vx + b.vy * b.vy);
      if (sp > maxSpeed) {
        b.vx *= maxSpeed / sp;
        b.vy *= maxSpeed / sp;
      }
    }
    final prevBottom = b.bottom;
    b.x += b.vx * dt;
    b.y += b.vy * dt;

    if (b.flying) {
      b.angle += b.spin * dt;
      return;
    }

    if (tilt) {
      // Damped spring back to upright.
      b.spin += (-160 * b.angle - 12 * b.spin) * dt;
      b.angle += b.spin * dt;
      // Under-damped (ζ ≈ 0.64): one small stretch past upright, then still.
      b.squashV += (-300 * b.squash - 22 * b.squashV) * dt;
      b.squash += b.squashV * dt;
    } else {
      b.angle = 0;
      b.spin = 0;
      b.squash = 0;
      b.squashV = 0;
    }

    // Side walls.
    if (b.left < 0) {
      b.x = b.w / 2;
      b.vx = -b.vx * .3;
    } else if (b.right > geo.width) {
      b.x = geo.width - b.w / 2;
      b.vx = -b.vx * .3;
    }

    // One-way planks: land only when crossing a plank's top from above.
    // Checking the crossing (not overlap) means no speed can tunnel through.
    b.grounded = false;
    for (var i = 0; i < geo.shelves; i++) {
      if (i < b.ghostShelf) continue;
      final p = geo.plankTop(i);
      if (prevBottom <= p + .5 && b.bottom >= p) {
        b.y = p - b.h / 2;
        if (b.vy > 220) {
          b.spin += (b.vx.sign == 0 ? 1 : b.vx.sign) * b.vy * .004;
          if (tilt) b.squash = math.max(b.squash, (b.vy / maxSpeed * .14).clamp(0.0, .14));
        }
        if (b.ghostShelf >= 0) {
          b.ghostShelf = -1;
          landed.add(b.id);
        }
        b.vy = b.vy > 120 ? -b.vy * .18 : 0;
        b.vx *= math.max(0, 1 - 10 * dt);
        b.grounded = b.vy == 0;
        break;
      }
    }
  }

  /// Items on the same shelf push each other sideways; the one being held
  /// pushes and is never pushed.
  void _separate() {
    final list = bodies.values.where((b) => !b.flying && b.ghostShelf < 0).toList();
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        final a = list[i], c = list[j];
        final ox = math.min(a.right, c.right) - math.max(a.left, c.left);
        final oy = math.min(a.bottom, c.bottom) - math.max(a.top, c.top);
        if (ox <= 0 || oy <= 0) continue;
        if (a.held && c.held) continue;
        // Vertical overlap is resolved sideways too: stacking products on
        // top of each other would hide one of them.
        final dir = a.x <= c.x ? -1.0 : 1.0;
        if (a.held) {
          c.x -= dir * ox;
          c.vx = -dir * 120;
        } else if (c.held) {
          a.x += dir * ox;
          a.vx = dir * 120;
        } else {
          a.x += dir * ox / 2;
          c.x -= dir * ox / 2;
          a.vx *= .5;
          c.vx *= .5;
        }
      }
    }
  }

  /// Release after a drag. [vx]/[vy] are the finger's velocity in px/s.
  /// Returns true when it was a throw.
  bool release(String id, double vx, double vy, {required bool allowFling}) {
    final b = bodies[id];
    if (b == null) return false;
    b.held = false;
    if (allowFling && vx.abs() > flingSpeed && vx.abs() > vy.abs() * .8) {
      b.flying = true;
      b.vx = vx * 1.2;
      b.vy = vy * .6 - 300;
      b.spin = vx.sign * 12;
      return true;
    }
    // A drop that ends with the product inside a plank lands on it instead
    // of being stuck in the wood.
    final band = geo.bandAt(b.y);
    final p = geo.plankTop(band);
    if (b.bottom > p) b.y = p - b.h / 2 - 1;
    if (b.top < geo.bandTop(band)) b.y = geo.bandTop(band) + b.h / 2;
    b.vx = (vx * .25).clamp(-400, 400);
    b.vy = 0;
    return false;
  }

  /// Puts a body at rest on shelf [shelf], slot [slot] (or drops it there
  /// from the top of the band when [drop] is true).
  void place(Body b, int shelf, int slot, {bool drop = false}) {
    b.x = geo.slotX(slot.clamp(0, 3));
    b.y = drop ? geo.bandTop(shelf) + b.h / 2 : geo.plankTop(shelf) - b.h / 2;
    b.vx = 0;
    b.vy = 0;
    b.angle = 0;
    b.spin = drop ? .6 : 0;
    b.grounded = !drop;
    b.flying = false;
    b.held = false;
  }

  /// A new product enters from above: it starts at [fromY] (usually just
  /// above the visible screen), falls through the shelves above [shelf]
  /// and lands in [slot].
  void dropFrom(Body b, int shelf, int slot, double fromY) {
    place(b, shelf, slot);
    b
      ..y = math.min(fromY, geo.bandTop(shelf) + b.h / 2)
      ..grounded = false
      ..ghostShelf = shelf
      ..angle = -.05
      ..spin = .9;
  }
}
