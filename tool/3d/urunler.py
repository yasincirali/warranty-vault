"""Shelf art for products without a photo, rendered in Blender (bpy 5.2).

Why 3D: the shelf mixes these with real photos cut out of their background
(subject_lift). Flat vector drawings next to photos read as two different
worlds; the same objects modelled and lit like a product shot sit next to a
photo as one more thing on the shelf.

Rules the renders keep (yasin's cabinet design, docs/03-tasarim-yonleri.md):
- transparent background, cropped tight, NO ground shadow: the shelf draws
  its own contact and wall shadows (cabinet_view.dart);
- the same palette and silhouettes as the drawings they replace, so a user
  who knows the old shelf finds the same things;
- one light set-up for all, from the upper left like the shelf's shadows.

Run:  python urunler.py <out_dir> [--samples 64] [--only laptop,tv]
Setup: python3 -m venv bvenv && bvenv/bin/pip install bpy  (Python 3.13)
"""

import argparse
import math
import os
import sys

import bpy
from mathutils import Vector

# Long side of the delivered PNG. The shelf shows a product at <= 120 pt and
# the detail header at <= 240 pt; 2x the old drawings covers 3x screens.
LONG_SIDE = 640


# ── scene ────────────────────────────────────────────────────────────────

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = bpy.context.scene
    s.render.engine = 'CYCLES'
    s.cycles.device = 'CPU'
    s.cycles.use_denoising = True
    s.render.film_transparent = True
    s.render.image_settings.file_format = 'PNG'
    s.render.image_settings.color_mode = 'RGBA'
    # Standard, not AgX: AgX washes the palette out towards grey, and these
    # colours must stay the drawings' colours.
    s.view_settings.view_transform = 'Standard'
    s.view_settings.exposure = -0.35
    w = bpy.data.worlds.new('w')
    w.use_nodes = True
    bg = w.node_tree.nodes['Background']
    bg.inputs[0].default_value = (0.85, 0.84, 0.82, 1)
    bg.inputs[1].default_value = 0.22
    s.world = w
    return s


def lights():
    def area(name, loc, size, power, color=(1, 1, 1)):
        d = bpy.data.lights.new(name, 'AREA')
        d.size = size
        d.energy = power
        d.color = color
        o = bpy.data.objects.new(name, d)
        bpy.context.collection.objects.link(o)
        o.location = loc
        # Aim at the origin.
        o.rotation_euler = (Vector((0, 0, 0.4)) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
        return o

    area('key', (-2.6, -3.2, 3.4), 3.0, 900, (1.0, 0.985, 0.96))  # slightly warm, upper left
    area('fill', (3.0, -2.6, 1.2), 4.0, 260, (0.92, 0.95, 1.0))   # cool, low right
    area('rim', (1.6, 2.8, 2.6), 1.5, 520)                        # edge from behind


def camera(pitch_deg=12):
    d = bpy.data.cameras.new('cam')
    d.type = 'ORTHO'
    o = bpy.data.objects.new('cam', d)
    bpy.context.collection.objects.link(o)
    p = math.radians(pitch_deg)
    o.location = (0, -10 * math.cos(p), 10 * math.sin(p) + 0.4)
    o.rotation_euler = (math.pi / 2 - p, 0, 0)
    bpy.context.scene.camera = o
    return o


def frame(cam, objs, margin=1.06):
    """Ortho scale and centre so every mesh fits; the PNG is cropped later."""
    s = bpy.context.scene
    bpy.context.view_layer.update()
    m = cam.matrix_world.inverted()
    xs, ys = [], []
    for o in objs:
        for c in o.bound_box:
            v = m @ (o.matrix_world @ Vector(c))
            xs.append(v.x)
            ys.append(v.y)
    w, h = max(xs) - min(xs), max(ys) - min(ys)
    cam.data.ortho_scale = max(w, h) * margin
    cam.data.shift_x = (max(xs) + min(xs)) / 2 / cam.data.ortho_scale
    cam.data.shift_y = (max(ys) + min(ys)) / 2 / cam.data.ortho_scale
    s.render.resolution_x = s.render.resolution_y = 1400


# ── materials ────────────────────────────────────────────────────────────

_mats = {}


def mat(name, rgb, rough=0.45, metal=0.0, coat=0.0):
    if name in _mats:
        return _mats[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*rgb, 1)
    b.inputs['Roughness'].default_value = rough
    b.inputs['Metallic'].default_value = metal
    b.inputs['Coat Weight'].default_value = coat
    _mats[name] = m
    return m


def srgb(hexs):
    """Palette is written in sRGB hex like the old drawings; Blender wants linear."""
    def lin(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return tuple(lin(int(hexs[i:i + 2], 16)) for i in (1, 3, 5))


# ── primitives ───────────────────────────────────────────────────────────

def _finish(o, m, bevel, segs=6):
    o.data.materials.append(m)
    if bevel:
        b = o.modifiers.new('bevel', 'BEVEL')
        b.width = bevel
        b.segments = segs
        b.limit_method = 'ANGLE'
        b.harden_normals = True
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def box(size, loc, m, bevel=0.02, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    o = bpy.context.object
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    return _finish(o, m, bevel)


def cyl(r, depth, loc, m, rot=(0, 0, 0), bevel=0.01, verts=64):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, rotation=rot, vertices=verts)
    return _finish(bpy.context.object, m, bevel, 4)


def torus(R, r, loc, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, location=loc, rotation=rot,
                                     major_segments=96, minor_segments=24)
    return _finish(bpy.context.object, m, 0)


def arc(R, thick, depth, loc, m, start=0, end=180):
    """Headband: a curve arc with a rectangular bevel."""
    c = bpy.data.curves.new('arc', 'CURVE')
    c.dimensions = '3D'
    sp = c.splines.new('POLY')
    n = 48
    sp.points.add(n)
    for i in range(n + 1):
        a = math.radians(start + (end - start) * i / n)
        sp.points[i].co = (R * math.cos(a), 0, R * math.sin(a), 1)
    c.bevel_mode = 'OBJECT'
    prof = bpy.data.curves.new('prof', 'CURVE')
    ps = prof.splines.new('POLY')
    ps.points.add(3)
    for i, (x, y) in enumerate([(-thick, -depth), (thick, -depth), (thick, depth), (-thick, depth)]):
        ps.points[i].co = (x / 2, y / 2, 0, 1)
    ps.use_cyclic_u = True
    po = bpy.data.objects.new('prof', prof)
    c.bevel_object = po
    o = bpy.data.objects.new('arc', c)
    bpy.context.collection.objects.link(o)
    o.location = loc
    c.materials.append(m)
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    bpy.ops.object.convert(target='MESH')
    o = bpy.context.object
    return _finish(o, m, 0.006, 3)


# ── the seven kinds ──────────────────────────────────────────────────────

WHITE = srgb('#f2f3f4')
INK = srgb('#1f2024')
DARK = srgb('#2e2f34')
SILVER = srgb('#c9ccd1')
SCREEN = srgb('#1c2230')
GLASS = srgb('#5b6f7e')
KRAFT = srgb('#9c7c5a')
TAPE = srgb('#d9bf95')
PURPLE = srgb('#7a4d96')


def appliance():
    body = mat('white', WHITE, 0.32, coat=0.4)
    box((0.60, 0.58, 0.82), (0, 0, 0.41), body, 0.035)
    panel = mat('panel', srgb('#e4e6e8'), 0.4)
    box((0.56, 0.02, 0.13), (0, -0.29, 0.73), panel, 0.008)
    box((0.15, 0.01, 0.035), (-0.14, -0.302, 0.735), mat('display', INK, 0.2))
    cyl(0.032, 0.03, (0.20, -0.302, 0.735), mat('knob', SILVER, 0.25, 0.8), rot=(math.pi / 2, 0, 0))
    torus(0.17, 0.028, (0, -0.296, 0.36), mat('ring', srgb('#c3c7cc'), 0.25, 0.85), rot=(math.pi / 2, 0, 0))
    cyl(0.155, 0.02, (0, -0.292, 0.36), mat('glass', GLASS, 0.06, coat=1.0), rot=(math.pi / 2, 0, 0))


def headphones():
    shell = mat('shell', DARK, 0.38, coat=0.3)
    pad = mat('pad', INK, 0.7)
    # Over-ear: a heavy band and tall oval cups. Thin parts vanished at
    # shelf size (44 pt in lists), so everything is a little chunkier
    # than the real thing.
    arc(0.40, 0.07, 0.09, (0, 0, 0.42), shell, -14, 194)
    arc(0.355, 0.03, 0.07, (0, 0, 0.42), pad, 12, 168)
    for s in (-1, 1):
        cup = cyl(0.13, 0.14, (s * 0.41, 0, 0.25), shell, rot=(0, math.pi / 2, 0), bevel=0.04)
        cup.scale = (1, 1, 1.35)
        pad_ = cyl(0.11, 0.06, (s * 0.32, 0, 0.25), pad, rot=(0, math.pi / 2, 0), bevel=0.025)
        pad_.scale = (1, 1, 1.35)


def laptop():
    alu = mat('alu', SILVER, 0.33, 0.85)
    box((1.0, 0.68, 0.026), (0, 0.0, 0.013), alu, 0.012)
    box((0.86, 0.30, 0.004), (0, 0.12, 0.027), mat('keys', DARK, 0.6), 0.002)
    box((0.32, 0.20, 0.003), (0, -0.20, 0.0265), mat('pad', srgb('#bfc2c7'), 0.3, 0.8), 0.004)
    # Lid leaning back from the hinge. Built in place, not parented: a
    # parent's rotation would also carry the bevel's hardened normals off.
    t = math.radians(-14)
    up = Vector((0, -math.sin(t), math.cos(t)))
    front = Vector((0, -math.cos(t), -math.sin(t)))
    hinge = Vector((0, 0.335, 0.026))
    rot = (t, 0, 0)
    box((1.0, 0.012, 0.66), hinge + up * 0.33, alu, 0.012, rot)
    # Black glass edge to edge with the panel inset, as on current laptops;
    # a silver bezel read as an old monitor. Rough enough not to mirror the
    # keyboard (it looked like a second screen).
    box((0.98, 0.004, 0.64), hinge + up * 0.33 + front * 0.007, mat('bezel', srgb('#141518'), 0.32), 0.008, rot)
    box((0.92, 0.003, 0.57), hinge + up * 0.345 + front * 0.009, mat('screen', SCREEN, 0.35), 0.003, rot)


def other():
    kraft = mat('kraft', KRAFT, 0.85)
    rot = (0, 0, math.radians(-32))
    box((0.62, 0.48, 0.44), (0, 0, 0.22), kraft, 0.01, rot)
    tape = mat('tape', TAPE, 0.35, coat=0.6)
    box((0.10, 0.49, 0.004), (0, 0, 0.441), tape, 0.001, rot)
    lbl = mat('label', srgb('#f6f2ea'), 0.6)
    a = math.radians(-32)
    nx, ny = math.sin(a), -math.cos(a)  # front face normal
    c = Vector((0, 0, 0.13)) + Vector((nx, ny, 0)) * 0.242 + Vector((math.cos(a), math.sin(a), 0)) * -0.12
    box((0.20, 0.004, 0.10), c, lbl, 0.004, rot)
    for i, wd in enumerate((0.13, 0.09)):
        off = Vector((math.cos(a), math.sin(a), 0)) * (-(0.20 - wd) / 2 + 0.02)
        box((wd, 0.003, 0.012), c + off + Vector((nx, ny, 0)) * 0.003 + Vector((0, 0, 0.02 - i * 0.03)),
            mat('ink', srgb('#9a958c'), 0.6), 0.002, rot)


def phone():
    rot = (0, 0, math.radians(-18))
    body = mat('phone', srgb('#2b2c30'), 0.28, coat=0.6)
    box((0.34, 0.035, 0.72), (0, 0, 0.36), body, 0.03, rot)
    bar = mat('bar', srgb('#3c3d42'), 0.3, 0.6)
    a = math.radians(-18)
    fwd = Vector((math.sin(a), -math.cos(a), 0))
    box((0.345, 0.03, 0.09), Vector((0, 0, 0.58)) + fwd * 0.022, bar, 0.02, rot)
    lens = mat('lens', srgb('#101114'), 0.05, coat=1.0)
    side = Vector((math.cos(a), math.sin(a), 0))
    for dx in (-0.08, -0.02):
        cyl(0.022, 0.012, Vector((0, 0, 0.58)) + fwd * 0.04 + side * dx, lens, rot=(math.pi / 2, 0, a))
    cyl(0.012, 0.01, Vector((0, 0, 0.58)) + fwd * 0.04 + side * 0.09, mat('flash', srgb('#d9d4c4'), 0.3),
        rot=(math.pi / 2, 0, a))


def tv():
    frame_m = mat('frame', INK, 0.35, 0.3)
    box((1.24, 0.035, 0.74), (0, 0, 0.53), frame_m, 0.01)
    box((1.20, 0.004, 0.70), (0, -0.018, 0.53), mat('screen', SCREEN, 0.08, coat=1.0), 0.003)
    stand = mat('stand', DARK, 0.3, 0.6)
    box((0.12, 0.05, 0.17), (0, 0.02, 0.10), stand, 0.01)
    box((0.48, 0.20, 0.025), (0, 0.0, 0.0125), stand, 0.012)


def vacuum():
    head = mat('head', srgb('#33343a'), 0.45)
    purple = mat('purple', PURPLE, 0.3, coat=0.6)
    tube = mat('tube', srgb('#a9adb4'), 0.25, 0.9)
    box((0.46, 0.24, 0.09), (0, 0, 0.045), head, 0.038)
    cyl(0.045, 0.10, (0, 0.0, 0.13), purple, bevel=0.012)
    cyl(0.034, 0.60, (0, 0.0, 0.47), tube, bevel=0.006)
    # Motor and bin across the top, the way the old drawing had it: a purple
    # body with the light bin cap facing right.
    cyl(0.13, 0.28, (0.0, 0, 0.88), purple, rot=(0, math.pi / 2, 0), bevel=0.04)
    cyl(0.10, 0.03, (0.15, 0, 0.88), mat('cap', srgb('#e6e7ea'), 0.3), rot=(0, math.pi / 2, 0), bevel=0.012)


# A laptop seen almost level is a monitor; from higher up its keyboard
# deck says what it is.
PITCH = {'laptop': 30}

KINDS = {
    'appliance': appliance,
    'headphones': headphones,
    'laptop': laptop,
    'other': other,
    'phone': phone,
    'tv': tv,
    'vacuum': vacuum,
}


def crop(path):
    """Tight crop to the visible pixels, then scale the long side to LONG_SIDE."""
    from PIL import Image
    im = Image.open(path)
    bb = im.getchannel('A').point(lambda a: 255 if a > 6 else 0).getbbox()
    im = im.crop(bb)
    k = LONG_SIDE / max(im.size)
    im = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
    im.save(path, optimize=True)
    return im.size


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--samples', type=int, default=64)
    ap.add_argument('--only', default='')
    a = ap.parse_args(argv)
    os.makedirs(a.out, exist_ok=True)
    names = [n for n in KINDS if not a.only or n in a.only.split(',')]
    for n in names:
        s = reset()
        s.cycles.samples = a.samples
        _mats.clear()
        lights()
        cam = camera(PITCH.get(n, 12))
        KINDS[n]()
        frame(cam, [o for o in s.objects if o.type == 'MESH'])
        p = os.path.join(a.out, f'{n}.png')
        s.render.filepath = p
        bpy.ops.render.render(write_still=True)
        w, h = crop(p)
        print(f'{n}: {w}x{h} aspect {w / h:.3f}', flush=True)


if __name__ == '__main__':
    main(sys.argv[1:])
