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
}
