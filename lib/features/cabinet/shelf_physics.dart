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

  /// Display size of a product: its photo, or its category drawing when it
  /// has none, keeps its aspect ratio inside the slot.
  ({double w, double h}) sizeFor(double aspect) {
    final maxW = slotWidth - 8;
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

/// Where a product gives when it moves: the shape of its flex along its
/// height (t = 0 at the base, 1 at the top).
enum FlexShape {
  /// Bends along its whole length, the top most (a stick vacuum, a cable).
  whip,

  /// Rigid above a joint: the part above [Feel.joint] rocks as one piece
  /// (a laptop lid on its hinge, a TV panel on its neck).
  hinge,

  /// Barely gives; the whole body only shivers a little (a washing machine).
  stiff,
}

/// How a kind of product moves (round 6, 2026-10-16: "mechanics should be
/// flexible and realistic, parts swaying according to the object"). One
/// photo has no separate parts, so the "part" is a band of the image above a
/// joint or along a whip; it is driven by a damped spring excited by the
/// body's sideways acceleration and by landings. Numbers were tuned by eye in
/// the web preview: a heavy appliance lands with a thud and does not bounce,
/// headphones bounce and their band wobbles, a vacuum whips.
class Feel {
  const Feel({
    required this.mass,
    required this.shape,
    this.joint = 0,
    required this.stiffness,
    required this.damping,
    required this.give,
    required this.bounce,
    required this.squash,
  });

  /// Relative mass (1 = a laptop). Heavier: follows the finger with more lag,
  /// pushes lighter products aside, is pushed less.
  final double mass;
  final FlexShape shape;

  /// For [FlexShape.hinge]: height fraction of the joint.
  final double joint;

  /// Spring constant and damping of the flex (per second², per second).
  final double stiffness, damping;

  /// How much sideways acceleration bends it (fraction of width per px/s²).
  final double give;

  /// Fraction of the landing speed it bounces back with.
  final double bounce;

  /// How much a landing squashes it (relative to the default).
  final double squash;

  static const laptop = Feel(
    mass: 1,
    shape: FlexShape.hinge,
    joint: .16,
    stiffness: 260,
    damping: 9,
    give: .000045,
    bounce: .12,
    squash: .6,
  );
  static const phone = Feel(
    mass: .35,
    shape: FlexShape.stiff,
    stiffness: 420,
    damping: 16,
    give: .00002,
    bounce: .22,
    squash: .5,
  );
  static const headphones = Feel(
    mass: .3,
    shape: FlexShape.whip,
    stiffness: 150,
    damping: 5,
    give: .00008,
    bounce: .3,
    squash: 1.4,
  );
  static const tv = Feel(
    mass: 1.6,
    shape: FlexShape.hinge,
    joint: .22,
    stiffness: 170,
    damping: 6,
    give: .00006,
    bounce: .08,
    squash: .5,
  );
  static const appliance = Feel(
    mass: 4,
    shape: FlexShape.stiff,
    stiffness: 520,
    damping: 22,
    give: .000012,
    bounce: 0,
    squash: .35,
  );
  static const vacuum = Feel(
    mass: .8,
    shape: FlexShape.whip,
    stiffness: 110,
    damping: 4,
    give: .0001,
    bounce: .15,
    squash: .8,
  );
  static const other = Feel(
    mass: 1,
    shape: FlexShape.whip,
    stiffness: 240,
    damping: 10,
    give: .00004,
    bounce: .18,
    squash: 1,
  );

  /// Horizontal displacement of height fraction [t] for a unit bend.
  double profile(double t) => switch (shape) {
    FlexShape.whip => t * t,
    FlexShape.hinge => t <= joint ? 0 : (t - joint) / (1 - joint),
    FlexShape.stiff => t,
  };
}

class Body {
  Body({required this.id, required this.x, required this.y, required this.w, required this.h, this.feel = Feel.other});
  final String id;

  Feel feel;

  /// Flex of the product's upper part, as a fraction of its width (+ = to the
  /// right). Visual only, like [angle].
  double bend = 0, bendV = 0;
  double _lastVx = 0;

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
        b.bend.abs() < .002 &&
        b.bendV.abs() < .02 &&
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
    final vx0 = b._lastVx;
    _integrateBody(b, dt, tilt);
    // The upper part lags behind sideways acceleration: start a drag to the
    // right and a lid or a band leans left, stop and it swings over.
    if (tilt && !b.flying) {
      final ax = (b.vx - vx0) / dt;
      final f = b.feel;
      b.bendV += (-f.stiffness * b.bend - f.damping * b.bendV) * dt - ax * f.give * 60 * dt;
      b.bend = (b.bend + b.bendV * dt).clamp(-.45, .45);
    } else if (!tilt) {
      b.bend = 0;
      b.bendV = 0;
    }
    b._lastVx = b.vx;
  }

  void _integrateBody(Body b, double dt, bool tilt) {
    if (b.held) {
      // Follows the finger with a lag that grows with mass: a washing
      // machine trails the finger, a phone sticks to it.
      final k = math.min(1.0, 28 / math.sqrt(b.feel.mass) * dt);
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
          final side = b.vx.sign == 0 ? (b.angle >= 0 ? 1.0 : -1.0) : b.vx.sign;
          b.spin += side * b.vy * .004 / math.sqrt(b.feel.mass);
          if (tilt) {
            b.squash = math.max(b.squash, (b.vy / maxSpeed * .14 * b.feel.squash).clamp(0.0, .2));
            // The impact runs up the product: a lid nods, a band wobbles.
            b.bendV += side * b.vy * b.feel.give * 25;
          }
        }
        if (b.ghostShelf >= 0) {
          b.ghostShelf = -1;
          landed.add(b.id);
        }
        b.vy = b.vy > 120 && b.feel.bounce > 0 ? -b.vy * b.feel.bounce : 0;
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
          // Shared by mass: a phone gives way to a washing machine.
          final share = c.feel.mass / (a.feel.mass + c.feel.mass);
          a.x += dir * ox * share;
          c.x -= dir * ox * (1 - share);
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
    b.bend = 0;
    b.bendV = 0;
    b._lastVx = 0;
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
