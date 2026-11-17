# -*- coding: utf-8 -*-
"""B10 modeled-asset gate (2026-11-16): a facade, creature or hand asset is
evidence only when the binary mesh exists, the in-repo generator authored it,
and a shipped gameplay script consumes it with a real material and LOD.

usage: python tools/qa_sim/b10_asset_check.py [--root DIR] [--demo]
"""
import pathlib
import shutil
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
GEN = "scripts/tools/_gen_meshes_b10.gd"
GEN_SCENE = "scenes/tools/gen_meshes_b10_scene.tscn"
CONSUMER = "scripts/art/b10_assets.gd"
MESHES = (
    "mesh_facade_bay", "mesh_facade_bay_lod",
    "mesh_creature_shell", "mesh_creature_shell_lod",
    "mesh_hand_viewmodel", "mesh_hand_viewmodel_lod",
)
CALLERS = {
    "scripts/world/skyline.gd": "_B10.add_facade_bays",
    "scripts/enemies/monster_rig.gd": "_B10.add_creature_shell",
    "scripts/weapons/weapon_manager.gd": "_B10.add_hands",
    "scripts/world/district_dressing.gd": 'setpieces.call("build", _district_id, _clear, _grid)',
}
SETPIECES = "scripts/world/b10_setpieces.gd"
PLAYER_SCENE = "scenes/player/player_3d.tscn"
MIN_BYTES = 2048


def read(root, rel):
    p = root / rel
    return p.read_text(encoding="utf-8", errors="replace") if p.is_file() else ""


def findings(root):
    out = []
    gen = read(root, GEN)
    consumer = read(root, CONSUMER)
    for name in MESHES:
        res = root / "assets" / "mesh" / (name + ".res")
        if not res.is_file():
            out.append("A1 %s.res missing" % name)
        elif res.stat().st_size < MIN_BYTES:
            out.append("A1 %s.res is only %d byte(s): not a real mesh" % (name, res.stat().st_size))
        if '_commit("%s"' % name not in gen:
            out.append("A2 %s is not authored by %s" % (name, GEN))
        if 'preload("res://assets/mesh/%s.res")' % name not in consumer:
            out.append("A3 %s has no preload in %s" % (name, CONSUMER))
    if not read(root, GEN_SCENE) or GEN not in read(root, GEN_SCENE):
        out.append("A4 %s does not run %s" % (GEN_SCENE, GEN))
    for rel, call in CALLERS.items():
        if call not in read(root, rel):
            out.append("A5 %s is missing its live consumer in %s" % (call, rel))
    for token in ("_material(", "visibility_range_end = near", "visibility_range_begin = near",
                  "material_override", "LOD_MARGIN_M"):
        if token not in consumer:
            out.append("A6 consumer has no %s (materials/LOD missing)" % token)
    sp = read(root, SETPIECES)
    for token in ('_playground(', '_keeper_shed(', '_workshop_b(', "OmniLight3D", "SpotLight3D"):
        if token not in sp:
            out.append("A7 setpieces missing %s (zone content or its lamp)" % token)
    if "CollisionShape3D" in sp or 'add_to_group("interactable"' in sp:
        out.append("A7 setpieces must stay visual-only dressing")
    weapons = read(root, "scripts/weapons/weapon_manager.gd")
    for token in ('viewmodel_light.light_cull_mask = 2', 'mesh.layers = 2'):
        if token not in weapons:
            out.append("A8 viewmodel must stay isolated from world lighting: %s" % token)
    if 'light_cull_mask = 1' not in read(root, PLAYER_SCENE):
        out.append("A8 flashlight must exclude the viewmodel layer")
    if 'minf(LOD_MARGIN_M, near * 0.1)' not in consumer:
        out.append("A9 LOD margin must not exceed the near range")
    return out


def demo():
    """The real tree passes; each mutant must bite."""
    with tempfile.TemporaryDirectory() as tmp:
        base = pathlib.Path(tmp) / "repo"
        (base / "assets" / "mesh").mkdir(parents=True)
        for rel in (GEN, GEN_SCENE, CONSUMER, SETPIECES, PLAYER_SCENE, *CALLERS):
            p = base / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text((ROOT / rel).read_text(encoding="utf-8", errors="replace"), encoding="utf-8")
        for name in MESHES:
            shutil.copy2(ROOT / "assets" / "mesh" / (name + ".res"),
                         base / "assets" / "mesh" / (name + ".res"))
        real = findings(base)
        mutants = {}

        def mutant(key, edit):
            dst = pathlib.Path(tmp) / key
            shutil.copytree(base, dst)
            edit(dst)
            mutants[key] = findings(dst)

        def m1(d):
            (d / "assets" / "mesh" / "mesh_facade_bay.res").unlink()
        mutant("missing_mesh", m1)

        def m2(d):
            p = d / "assets" / "mesh" / "mesh_creature_shell.res"
            p.write_bytes(b"stub")
        mutant("stub_mesh", m2)

        def m3(d):
            p = d / GEN
            p.write_text(p.read_text(encoding="utf-8").replace(
                '_commit("mesh_hand_viewmodel")', '_commit("mesh_other")'), encoding="utf-8")
        mutant("no_provenance", m3)

        def m4(d):
            p = d / "scripts" / "world" / "skyline.gd"
            p.write_text(p.read_text(encoding="utf-8").replace(
                "_B10.add_facade_bays(self, district_id, _fronts, _widths)", ""), encoding="utf-8")
        mutant("no_consumer", m4)

        def m5(d):
            p = d / CONSUMER
            p.write_text(p.read_text(encoding="utf-8").replace(
                "visibility_range_end = near", "pass  # LOD removed"), encoding="utf-8")
        mutant("no_lod", m5)

        def m6(d):
            p = d / "scripts" / "world" / "district_dressing.gd"
            p.write_text(p.read_text(encoding="utf-8").replace(
                'setpieces.call("build", _district_id, _clear, _grid)', "pass"), encoding="utf-8")
        mutant("setpieces_unwired", m6)

        def m7(d):
            p = d / SETPIECES
            p.write_text(p.read_text(encoding="utf-8").replace(
                "_workshop_b(", "_unused("), encoding="utf-8")
        mutant("setpieces_zone_missing", m7)

        def m8(d):
            p = d / "scripts" / "weapons" / "weapon_manager.gd"
            p.write_text(p.read_text(encoding="utf-8").replace(
                "viewmodel_light.light_cull_mask = 2", "viewmodel_light.light_cull_mask = 1"), encoding="utf-8")
        mutant("viewmodel_lights_world", m8)

        def m9(d):
            p = d / CONSUMER
            p.write_text(p.read_text(encoding="utf-8").replace(
                "minf(LOD_MARGIN_M, near * 0.1)", "LOD_MARGIN_M"), encoding="utf-8")
        mutant("unbounded_lod_margin", m9)

        bitten = {k: len(v) for k, v in mutants.items() if v}
        ok = not real and len(bitten) == len(mutants)
        print("b10_asset_check --demo: real=%s %s -> %s" % (
            "PASS" if not real else "FAIL", bitten, "BITES" if ok else "VACUOUS"))
        return 0 if ok else 1


def main(argv):
    if "--demo" in argv:
        return demo()
    root = pathlib.Path(argv[argv.index("--root") + 1]) if "--root" in argv else ROOT
    bad = findings(root)
    for f in bad:
        print("FAIL", f)
    print("b10_asset_check: %d finding(s), %d meshes, %d live consumers" % (
        len(bad), len(MESHES), len(CALLERS)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
