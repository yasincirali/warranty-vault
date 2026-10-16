import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/features/cabinet/shelf_physics.dart';

ShelfPhysics _world({int shelves = 3}) => ShelfPhysics(CabinetGeometry(width: 390, shelves: shelves));

void _run(ShelfPhysics w, double seconds) {
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    w.step(1 / 60);
  }
}

void main() {
  test('a dropped product lands on its plank and comes to rest', () {
    final w = _world();
    final b = Body(id: 'a', x: 0, y: 0, w: 60, h: 80);
    w.bodies['a'] = b;
    w.place(b, 1, 0, drop: true);
    _run(w, 2);
    expect(b.bottom, closeTo(w.geo.plankTop(1), .6));
    expect(w.resting, isTrue);
    expect(b.angle.abs(), lessThan(.01));
  });

  test('no speed tunnels through a plank', () {
    final w = _world();
    final b = Body(id: 'a', x: 100, y: 40, w: 60, h: 60)..vy = 5000;
    w.bodies['a'] = b;
    _run(w, 1);
    expect(w.geo.bandAt(b.y), 0);
  });

  test('a fast sideways release is a throw and leaves the cabinet', () {
    final w = _world();
    final b = Body(id: 'a', x: 0, y: 0, w: 60, h: 60);
    w.bodies['a'] = b;
    w.place(b, 0, 3);
    b.held = true;
    expect(w.release('a', 1600, -100, allowFling: true), isTrue);
    final gone = <String>[];
    for (var i = 0; i < 120 && gone.isEmpty; i++) {
      gone.addAll(w.step(1 / 60));
    }
    expect(gone, ['a']);
    expect(w.bodies, isEmpty);
  });

  test('a lazy drag or a vertical flick is never a throw', () {
    final w = _world();
    final b = Body(id: 'a', x: 0, y: 0, w: 60, h: 60);
    w.bodies['a'] = b;
    w.place(b, 0, 0);
    expect(w.release('a', 800, 0, allowFling: true), isFalse);
    expect(w.release('a', 1300, 2400, allowFling: true), isFalse);
  });

  test('a release inside a plank lands on top of it instead of sticking', () {
    final w = _world();
    final b = Body(id: 'a', x: 100, y: 0, w: 60, h: 60);
    w.bodies['a'] = b;
    b.y = w.geo.plankTop(1) + 10; // centre inside the wood
    b.held = true;
    w.release('a', 0, 0, allowFling: false);
    expect(b.bottom, lessThanOrEqualTo(w.geo.plankTop(1)));
    _run(w, 1);
    expect(w.geo.bandAt(b.y), 1);
    expect(b.bottom, closeTo(w.geo.plankTop(1), .6));
  });

  test('products on a shelf push each other apart instead of overlapping', () {
    final w = _world();
    final a = Body(id: 'a', x: 0, y: 0, w: 70, h: 70);
    final c = Body(id: 'c', x: 0, y: 0, w: 70, h: 70);
    w.bodies
      ..['a'] = a
      ..['c'] = c;
    w.place(a, 0, 1);
    w.place(c, 0, 1);
    c.x += 10;
    _run(w, 1);
    expect((a.x - c.x).abs(), greaterThanOrEqualTo(69.9));
  });

  test('photo sizes keep their aspect and never drop under 44 pt', () {
    const g = CabinetGeometry(width: 320, shelves: 1);
    final tall = g.sizeFor(.3);
    expect(tall.h, 84);
    expect(tall.w, 44);
    final wide = g.sizeFor(4);
    expect(wide.w, g.slotWidth - 8);
    expect(wide.h, greaterThanOrEqualTo(36));
    expect(g.sizeFor(null).w, g.sizeFor(null).h);
  });

  test('a new product dropped from above the screen passes the upper shelves and lands on its own', () {
    final w = _world(shelves: 4);
    final top = Body(id: 'top', x: 0, y: 0, w: 60, h: 60);
    w.bodies['top'] = top;
    w.place(top, 0, 2);
    final b = Body(id: 'new', x: 0, y: 0, w: 60, h: 80);
    w.bodies['new'] = b;
    w.dropFrom(b, 2, 2, -300);
    expect(b.top, lessThan(0), reason: 'starts above the cabinet');
    final landed = <String>[];
    for (var i = 0; i < 180; i++) {
      w.step(1 / 60);
      landed.addAll(w.landed);
    }
    expect(b.bottom, closeTo(w.geo.plankTop(2), .6));
    expect(landed, ['new'], reason: 'one landing, reported once (for the haptic)');
    expect(top.bottom, closeTo(w.geo.plankTop(0), .6), reason: 'the product it fell past was not pushed');
    expect(top.x, w.geo.slotX(2));
    expect(w.resting, isTrue);
    expect(b.squash.abs(), lessThan(.002));
  });

  test('a hard landing squashes the product, then it springs back to its own shape', () {
    final w = _world();
    final b = Body(id: 'a', x: 0, y: 0, w: 60, h: 80);
    w.bodies['a'] = b;
    w.dropFrom(b, 1, 0, -400);
    var most = 0.0;
    for (var i = 0; i < 120; i++) {
      w.step(1 / 60);
      if (b.squash > most) most = b.squash;
    }
    expect(most, greaterThan(.05));
    expect(most, lessThanOrEqualTo(.14));
    expect(b.squash.abs(), lessThan(.002));
  });

  test('without tilt (reduce motion) nothing squashes', () {
    final w = _world();
    final b = Body(id: 'a', x: 0, y: 0, w: 60, h: 80);
    w.bodies['a'] = b;
    w.dropFrom(b, 1, 0, -400);
    for (var i = 0; i < 120; i++) {
      w.step(1 / 60, tilt: false);
      expect(b.squash, 0);
    }
  });

  group('each kind of product moves like itself', () {
    // Drags a product sideways for a moment, lets go, and records how far its
    // upper part bends each frame until it settles.
    List<double> dragAndLetGo(Feel feel) {
      final w = _world();
      final b = Body(id: 'a', x: 0, y: 0, w: 70, h: 84, feel: feel);
      w.bodies['a'] = b;
      w.place(b, 1, 1);
      b.held = true;
      b.targetY = b.y - 20;
      final bends = <double>[];
      for (var i = 0; i < 20; i++) {
        b.targetX = b.x + 18; // a quick drag to the right
        w.step(1 / 60);
        bends.add(b.bend);
      }
      w.release('a', 0, 0, allowFling: false);
      for (var i = 0; i < 240; i++) {
        w.step(1 / 60);
        bends.add(b.bend);
      }
      return bends;
    }

    test('a laptop lid lags behind a drag, swings past upright and settles', () {
      final bends = dragAndLetGo(Feel.laptop);
      expect(bends.take(20).reduce((a, c) => a < c ? a : c), lessThan(-.01)); // leans back
      expect(bends.skip(20).reduce((a, c) => a > c ? a : c), greaterThan(0)); // swings over
      expect(bends.last.abs(), lessThan(.002)); // and comes to rest
    });

    test('headphones give far more than a washing machine', () {
      double peak(List<double> xs) => xs.map((x) => x.abs()).reduce((a, c) => a > c ? a : c);
      expect(peak(dragAndLetGo(Feel.headphones)), greaterThan(peak(dragAndLetGo(Feel.appliance)) * 3));
    });

    test('a washing machine lands without bouncing, headphones bounce', () {
      double rebound(Feel feel) {
        final w = _world();
        final b = Body(id: 'a', x: 0, y: 0, w: 70, h: 70, feel: feel);
        w.bodies['a'] = b;
        w.place(b, 1, 1, drop: true);
        b.y -= 60;
        var lowest = double.infinity;
        var landed = false;
        for (var i = 0; i < 120; i++) {
          w.step(1 / 60);
          if (b.bottom >= w.geo.plankTop(1) - .5) landed = true;
          if (landed) lowest = lowest < b.bottom ? lowest : b.bottom;
        }
        return w.geo.plankTop(1) - lowest; // how high it rose after touching
      }

      expect(rebound(Feel.appliance), lessThan(.5));
      expect(rebound(Feel.headphones), greaterThan(rebound(Feel.appliance)));
    });

    test('a heavy product pushes a light one aside, not the other way', () {
      final w = _world();
      final heavy = Body(id: 'h', x: 0, y: 0, w: 70, h: 70, feel: Feel.appliance);
      final light = Body(id: 'l', x: 0, y: 0, w: 50, h: 50, feel: Feel.phone);
      w.bodies['h'] = heavy;
      w.bodies['l'] = light;
      w.place(heavy, 1, 1);
      w.place(light, 1, 1);
      final hx = heavy.x, lx = light.x;
      _run(w, .5);
      expect((light.x - lx).abs(), greaterThan((heavy.x - hx).abs() * 3));
    });

    test('reduce motion: nothing bends', () {
      final w = _world();
      final b = Body(id: 'a', x: 0, y: 0, w: 70, h: 84, feel: Feel.vacuum);
      w.bodies['a'] = b;
      w.place(b, 1, 1, drop: true);
      for (var i = 0; i < 60; i++) {
        w.step(1 / 60, tilt: false);
        expect(b.bend, 0);
      }
    });
  });
}
