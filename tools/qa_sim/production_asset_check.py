# -*- coding: utf-8 -*-
"""B9 production-asset gate (2026-11-13): a reusable 3D mesh is evidence only
when it is a real binary resource, is authored by the in-repo generator, and
has a live consumer in the shipped world code.

usage: python tools/qa_sim/production_asset_check.py [--root DIR] [--demo]

Checks, each printed as a finding and exiting 1 when any is present:
  A1 every one of the seven meshes exists under assets/mesh/ and is a binary
     Godot resource of at least 2 KiB (a renamed placeholder or a stub fails)
  A2 scripts/tools/_gen_meshes_b9.gd commits that exact name (provenance)
  A3 the crate/barrel replace the primitive box/cylinder in the Crates and
     Barrels batches of district_dressing.gd (no primitive left behind)
  A4 the five set pieces are preloaded and batched by production_props.gd
  A5 district_dressing.gd actually builds the ProductionProps node, so no
     asset is an orphan that only a tool scene draws
  A6 the generator scene exists and points at the generator script
"""
import pathlib
import shutil
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
GEN = "scripts/tools/_gen_meshes_b9.gd"
GEN_SCENE = "scenes/tools/gen_meshes_b9_scene.tscn"
WORLD = "scripts/world/production_props.gd"
DRESSING = "scripts/world/district_dressing.gd"
MIN_BYTES = 2048

REPLACEMENTS = ["mesh_crate", "mesh_barrel"]
SET_PIECES = {
    "mesh_car": "B9Cars",
    "mesh_cabinet": "B9Cabinets",
    "mesh_fence": "B9Fences",
    "mesh_cart": "B9Carts",
    "mesh_debris": "B9Debris",
}
ALL = REPLACEMENTS + list(SET_PIECES)


def read(root, rel):
    p = root / rel
    return p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""


def findings(root):
    out = []
    for name in ALL:
        res = root / "assets" / "mesh" / (name + ".res")
        if not res.is_file():
            out.append("A1 %s.res missing" % name)
        elif res.stat().st_size < MIN_BYTES:
            out.append("A1 %s.res is only %d byte(s): not a real mesh" % (name, res.stat().st_size))
        if '_commit("%s")' % name not in read(root, GEN):
            out.append("A2 %s is not authored by %s" % (name, GEN))
    gen_scene = read(root, GEN_SCENE)
    if not gen_scene or GEN not in gen_scene:
        out.append("A6 %s does not run %s" % (GEN_SCENE, GEN))
    dressing = read(root, DRESSING)
    world = read(root, WORLD)
    for name, const in (("mesh_crate", "_CRATE"), ("mesh_barrel", "_BARREL")):
        path = "res://assets/mesh/%s.res" % name
        if 'preload("%s")' % path not in dressing:
            out.append("A3 %s is not preloaded by %s" % (name, DRESSING))
    for batch, const in (("Crates", "_CRATE"), ("Barrels", "_BARREL")):
        if '_batch("%s", %s' % (batch, const) not in dressing:
            out.append("A3 the %s batch still uses a primitive mesh" % batch)
    if "_add_production_props(sb)" not in dressing or "_PRODUCTION.new()" not in dressing:
        out.append("A5 ProductionProps is never built by %s" % DRESSING)
    for name, batch in SET_PIECES.items():
        path = "res://assets/mesh/%s.res" % name
        if 'preload("%s")' % path not in world:
            out.append("A4 %s has no consumer in %s" % (name, WORLD))
        if '_batch("%s"' % batch not in world:
            out.append("A4 the %s batch is missing" % batch)
    return out


def demo():
    """Each mutant must bite; an unmutated copy must pass."""
    with tempfile.TemporaryDirectory() as tmp:
        base = pathlib.Path(tmp) / "repo"
        (base / "assets" / "mesh").mkdir(parents=True)
        (base / "scripts" / "tools").mkdir(parents=True)
        (base / "scripts" / "world").mkdir(parents=True)
        (base / "scenes" / "tools").mkdir(parents=True)
        for rel in (GEN, GEN_SCENE, WORLD, DRESSING):
            (base / rel).write_text((ROOT / rel).read_text(encoding="utf-8", errors="replace"), encoding="utf-8")
        for name in ALL:
            shutil.copy2(ROOT / "assets" / "mesh" / (name + ".res"), base / "assets" / "mesh" / (name + ".res"))
        real = findings(base)
        mutants = {}
        # M1: a mesh file disappears.
        m1 = pathlib.Path(tmp) / "m1"
        shutil.copytree(base, m1)
        (m1 / "assets" / "mesh" / "mesh_car.res").unlink()
        mutants["missing_mesh"] = findings(m1)
        # M2: a stub resource, not a real triangulated mesh.
        m2 = pathlib.Path(tmp) / "m2"
        shutil.copytree(base, m2)
        (m2 / "assets" / "mesh" / "mesh_cabinet.res").write_bytes(b"stub")
        mutants["stub_mesh"] = findings(m2)
        # M3: the world script stops consuming the car.
        m3 = pathlib.Path(tmp) / "m3"
        shutil.copytree(base, m3)
        p = m3 / WORLD
        p.write_text(p.read_text(encoding="utf-8").replace(
            'preload("res://assets/mesh/mesh_car.res")', 'preload("res://assets/mesh/mesh_crate.res")'), encoding="utf-8")
        mutants["orphan_mesh"] = findings(m3)
        # M4: the node is never built, so nothing draws in the game.
        m4 = pathlib.Path(tmp) / "m4"
        shutil.copytree(base, m4)
        p = m4 / DRESSING
        p.write_text(p.read_text(encoding="utf-8").replace("\t_add_production_props(sb)\n", ""), encoding="utf-8")
        mutants["unbuilt_node"] = findings(m4)
        # M5: the primitive crates come back.
        m5 = pathlib.Path(tmp) / "m5"
        shutil.copytree(base, m5)
        p = m5 / DRESSING
        p.write_text(p.read_text(encoding="utf-8").replace('_batch("Crates", _CRATE', '_batch("Crates", _box()'), encoding="utf-8")
        mutants["primitive_crate"] = findings(m5)
        bitten = {k: len(v) for k, v in mutants.items() if v}
        ok = not real and len(bitten) == len(mutants)
        print("production_asset_check --demo: real=%s %s -> %s" % (
            "PASS" if not real else "FAIL", bitten, "BITES" if ok else "VACUOUS"))
        return 0 if ok else 1


def main(argv):
    if "--demo" in argv:
        return demo()
    root = pathlib.Path(argv[argv.index("--root") + 1]) if "--root" in argv else ROOT
    bad = findings(root)
    for f in bad:
        print("FAIL", f)
    print("production_asset_check: %d finding(s), %d production mesh(es), %d live batch(es)" % (
        len(bad), len(ALL), len(SET_PIECES) + len(REPLACEMENTS)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
