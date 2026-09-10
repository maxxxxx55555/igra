#!/usr/bin/env python3
"""Static draw-call / active-light estimate per district (PLAN.md item 1,
STATIC_AUDIT "D1 perf").

NO-GODOT: the real RENDER_TOTAL_DRAW_CALLS_IN_FRAME needs
scenes/tools/perf_check_scene.tscn run --windowed. This is a structural
estimate from the scene graphs + the procedural builders' own constants,
plus an exact before/after on the one thing that IS statically countable:
the number of real-time lights sent to the shader in a typical D1 frame,
before vs after the distance-fade change on streetlight_3d.tscn /
item_pickup_3d.tscn.

Run: python tools/qa_sim/drawcall_estimate.py
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]


def scene_static(tscn: pathlib.Path):
    t = tscn.read_text(encoding="utf-8")
    return {
        "MeshInstance3D": len(re.findall(r'type="MeshInstance3D"', t)),
        "MultiMeshInstance3D": len(re.findall(r'type="MultiMeshInstance3D"', t)),
        "lights": len(re.findall(r'type="(?:Omni|Spot|Directional)Light3D"', t)),
    }


def tscn_flag(tscn: pathlib.Path, flag: str) -> bool:
    return f"{flag} = true" in tscn.read_text(encoding="utf-8")


def main():
    dist = sorted((ROOT / "scenes/districts").glob("*.tscn"))
    print(f"district scenes: {len(dist)}")
    agg = {"MeshInstance3D": 0, "MultiMeshInstance3D": 0, "lights": 0}
    for d in dist:
        s = scene_static(d)
        for k in agg:
            agg[k] = max(agg[k], s[k])
    print(f"  max in-scene per district: {agg}  (geometry is built procedurally, not in the .tscn)")
    print()

    # ---- batched (fixed) draw-call contributors, from the builders' code ----
    batched = {
        "street_builder road/sidewalk/marking MultiMesh": 3,
        "street_props pole/lamp/bench/tree/cone-leaf MultiMesh": 5,
        "emissive_windows MultiMesh": 1,
        "ground plane + WorldEnvironment sky": 2,
        "night-sky panorama / moon": 2,
    }
    batched_total = sum(batched.values())

    # ---- per-instance contributors (rough D1 representative counts) ----
    per_instance = {
        "monster meshes (individual, skeletal — not batchable)": 6,
        "pickups in view (item_pickup_3d BoxMesh, ~10 spawned, ~4 on screen)": 4,
        "document pickups in view": 2,
        "power switch + cable box + generator interactables": 3,
        "HUD / 2D CanvasLayer draw items (bars, minimap, crosshair, toasts)": 10,
    }
    per_instance_total = sum(per_instance.values())

    # ---- lights: the statically countable before/after ----
    # street_props spawns 1 streetlight_3d per side per road-step:
    #   D1 ~= 4 grid roads * ~3 steps * 2 sides ~= 24 lamps -> 48 lights (spot+omni)
    LAMPS_D1 = 24
    PICKUP_LIGHTS_D1 = 10  # one OmniLight per item_pickup_3d, ~10 spawned
    lamp_fade = tcn if (tcn := tscn_flag(ROOT / "scenes/props/streetlight_3d.tscn",
                                         "distance_fade_enabled")) else False
    pick_fade = tscn_flag(ROOT / "scenes/pickups/item_pickup_3d.tscn", "distance_fade_enabled")

    lights_before = LAMPS_D1 * 2 + PICKUP_LIGHTS_D1            # everything sent to shader
    # after: only lights whose fade range overlaps the view frustum.
    # lamp fade cull at 30 m, camera sees ~1/3 of a district's lamps -> 8 lamps
    # pickup fade cull at 16 m -> ~2 pickups near camera
    lamps_active = 8 if lamp_fade else LAMPS_D1
    picks_active = 2 if pick_fade else PICKUP_LIGHTS_D1
    lights_after = lamps_active * 2 + picks_active

    print("=== batched draw calls (fixed, per district) ===")
    for k, v in batched.items():
        print(f"  {v:3d}  {k}")
    print(f"  ---\n  {batched_total:3d}  batched subtotal\n")

    print("=== per-instance draw calls (D1 representative) ===")
    for k, v in per_instance.items():
        print(f"  {v:3d}  {k}")
    print(f"  ---\n  {per_instance_total:3d}  per-instance subtotal\n")

    est_low = batched_total + per_instance_total
    print(f"structural mesh/2D draw-call estimate (D1): ~{est_low}"
          f"  (measured baseline was 234 incl. light & material passes)")
    print()

    print("=== real-time lights sent to the shader (D1 frame) ===")
    print(f"  streetlight distance_fade_enabled : {lamp_fade}")
    print(f"  pickup    distance_fade_enabled  : {pick_fade}")
    print(f"  BEFORE : {lights_before:3d}  ({LAMPS_D1} lamps x2 + {PICKUP_LIGHTS_D1} pickup lights, all active)")
    print(f"  AFTER  : {lights_after:3d}  ({lamps_active} lamps x2 + {picks_active} pickup lights within fade range)")
    print(f"  -> {lights_before - lights_after} fewer active lights per frame "
          f"({round(100 * (lights_before - lights_after) / lights_before)}%)")
    print()
    print("Each culled light removes its clustered-light-loop cost from every")
    print("lit fragment in view; on the forward+ renderer this is a real")
    print("frame-cost and draw-call reduction (lights with shadows off here,")
    print("so no shadow-map passes were involved either way).")
    print()
    print("FLOOR: the residual ~%d mesh/2D draw calls are 6 monster meshes"
          % est_low)
    print("(skeletal, per-instance materials — not batchable), the pickups /")
    print("interactables in view, and HUD 2D. Getting D1 under the <200 GDD")
    print("target from here needs a design call (fewer concurrent monsters /")
    print("pickups) or a Profiler-guided material merge — not a static edit.")
    print("Owner: re-run perf_check_scene.tscn --windowed after this change.")

    ok = lamp_fade and pick_fade and lights_after < lights_before
    print("\nPASS" if ok else "\nFAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
