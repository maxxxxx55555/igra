# Surfaces/UI narrowing manifest

Static-only narrowing for `assets/textures/surfaces/` and
`assets/textures/ui/`. No Godot engine was started. No source image, `.import`
sidecar, or other asset was deleted, moved, renamed, or edited. Source images
are the audited unit; each same-named `.import` is a generated/import companion
and inherits the source verdict rather than becoming a second fake candidate.

## Inventory and gates

```text
$ find assets/textures/surfaces -maxdepth 1 -type f -name '*.png' | wc -l
27
$ find assets/textures/ui -maxdepth 1 -type f -name '*.png' | wc -l
49
$ python3 tools/quarantine_audit.py --check
verdict counts: {"AUTO-DELETABLE": 10, "KEEP-LIVE": 16, "KEEP-PLANNED": 24, "UNCERTAIN": 36}
check: PASS (UNCERTAIN means owner eyes, not a gate failure)
```

The combined tool inventory is 10 quarantine files + 27 surface PNGs + 49 UI
PNGs = 86 audited source files. The sidecar count was checked separately:

```text
$ find assets/textures/surfaces -maxdepth 1 -name '*.import' | wc -l
27
$ find assets/textures/ui -maxdepth 1 -name '*.import' | wc -l
49
```

## Method and dynamic-loader guard

The per-file **A** scan searches the exact `res://assets/...` path and its
repository-relative equivalent. The independent **B** scan searches the exact
basename with token boundaries. The **D** scan covers format-string paths,
concatenation, variable `load()`/`preload()`, `ResourceLoader`, directory
iteration, and district-material assignments. The scan corpus is runtime
code/resources (`scripts`, `scenes`, `components`, `data`, `addons`); docs and
tool output are not mistaken for game consumers.

```text
$ rg -n -e 'load\s*\(|preload\s*\(|ResourceLoader|DirAccess|list_dir|tex_path|assets/textures/(surfaces|ui)|district.*material|material.*district' scripts scenes components data addons --glob '*.gd' --glob '*.tscn' --glob '*.tres' --glob '*.json' | rg -e 'assets/textures|tex_path|district.*material|material.*district|DirAccess|list_dir' | sed -n '1,36p'
scripts/world/street_props.gd:34:const _TEX_STREETLIGHT := "res://assets/textures/surfaces/streetlight_metal_512.png"
scripts/world/street_props.gd:35:const _TEX_BENCH       := "res://assets/textures/surfaces/bench_wood_512.png"
scripts/world/street_props.gd:49:        var tex: Texture2D = load(tex_path)
scripts/world/district_grading.gd:87:        var tex_path := "res://assets/textures/tiles/%s_floor.png" % String(district_id)
scripts/world/district_grading.gd:89:        m.albedo_texture = load(tex_path)
scripts/ui/theme_provider.gd:102:    var btn_tex_n := _load_tex("res://assets/textures/ui/btn_tex_normal.png")
scripts/ui/minimap.gd:7:const _FRAME_TEX: Texture2D = preload("res://assets/textures/ui/minimap_frame_256.png")
scripts/ui/minimap.gd:8:const _ARROW_TEX: Texture2D = preload("res://assets/textures/ui/minimap_player_arrow_32.png")
```

This is the dynamic-loader warning pass: the `%s` district assignment is a
tiles path, not a surface/UI path; `street_props.gd`'s variable texture load
is included rather than dismissed; and the literal UI/surface consumers are
kept. No candidate is marked dead from absence of a literal path alone.


All four named review docs were checked per candidate, not only on the rows
that had a hit:

```text
$ for d in docs/VISUAL_PASS.md docs/STORE_KIT.md docs/CARD_ART_BRIEF.md docs/KNOWN_ISSUES.md; do printf '%s: ' "$d"; rg -n -i '(_QUARANTINE|assets/textures/(surfaces|ui)|surfaces/|textures/ui)' "$d" | wc -l; done
docs/VISUAL_PASS.md: 0
docs/STORE_KIT.md: 0
docs/CARD_ART_BRIEF.md: 0
docs/KNOWN_ISSUES.md: 2
```

The two `KNOWN_ISSUES.md` lines are the broad quarantine warning at
`42-43`; they are not a planned claim for any particular surface/UI file.
The table's doc anchors use the wider documentation cross-check where a
candidate has a per-file delivery or wiring note.

## Verdict classes

- **KEEP-LIVE** — A or B found a runtime consumer; retain.
- **KEEP-PLANNED** — no runtime consumer, but a delivery/spec/gap/deferred
  note says the asset belongs to a future or not-yet-wired feature; retain,
  with the cited doc line.
- **AUTO-DELETABLE** — both scans are empty and an explicit dead/superseded
  record exists. No surface/UI source currently meets that bar.
- **UNCERTAIN** — no runtime consumer and no decisive per-file disposition;
  owner eyes. This is deliberately safer than turning “delivered but unwired”
  into a deletion.

## `assets/textures/surfaces/` — 27/27 source files

| File | A — full path | B — basename | D — dynamic pass | Doc anchor | Verdict |
|---|---|---|---|---|---|
| `assets/textures/surfaces/asphalt_512.png` | — | — | reviewed | `docs/TRAILER_STORYBOARD.md:8` | **UNCERTAIN** |
| `assets/textures/surfaces/bench_wood_512.png` | `scripts/world/street_props.gd:35` | `scripts/world/street_props.gd:35` | reviewed | `docs/VISUAL_AUDIT.md:68` | **KEEP-LIVE** |
| `assets/textures/surfaces/brick_512.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/surfaces/cabinet_wood_512.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/surfaces/cell_bars_512.png` | — | — | reviewed | `content/districts/police/prop_manifest.md:132` | **KEEP-PLANNED** |
| `assets/textures/surfaces/chalkboard_512.png` | — | — | reviewed | `content/districts/school/prop_manifest.md:136` | **KEEP-PLANNED** |
| `assets/textures/surfaces/concrete_512.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/surfaces/concrete_wall_512.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/surfaces/door_metal_512.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/surfaces/door_wood_512.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/surfaces/dumpster_metal_512.png` | `scripts/gameplay/hiding_spot.gd:48` | `scripts/gameplay/hiding_spot.gd:48` | reviewed | `docs/VISUAL_AUDIT.md:70` | **KEEP-LIVE** |
| `assets/textures/surfaces/fuel_pump_512.png` | — | — | reviewed | `content/districts/gas_station/prop_manifest.md:122` | **KEEP-PLANNED** |
| `assets/textures/surfaces/fusebox_512.png` | — | — | reviewed | `content/districts/gas_station/prop_manifest.md:99` | **KEEP-PLANNED** |
| `assets/textures/surfaces/generator_metal_512.png` | — | — | reviewed | `content/districts/gas_station/prop_manifest.md:99` | **KEEP-PLANNED** |
| `assets/textures/surfaces/gravel_512.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/surfaces/hospital_curtain_512.png` | — | — | reviewed | `content/districts/hospital/prop_manifest.md:135` | **KEEP-PLANNED** |
| `assets/textures/surfaces/hospital_tile_dirty_512.png` | — | — | reviewed | `docs/ASSET_LICENSES.md:66` | **KEEP-PLANNED** |
| `assets/textures/surfaces/metal_rust_512.png` | — | — | reviewed | `content/districts/industrial/prop_manifest.md:196` | **KEEP-PLANNED** |
| `assets/textures/surfaces/morgue_drawers_512.png` | — | — | reviewed | `content/districts/hospital/prop_manifest.md:137` | **KEEP-PLANNED** |
| `assets/textures/surfaces/pond_ice_512.png` | — | — | reviewed | `content/districts/park/prop_manifest.md:79` | **KEEP-PLANNED** |
| `assets/textures/surfaces/powerbox_metal_512.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/surfaces/school_floor_512.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/surfaces/school_lockers_512.png` | — | — | reviewed | `content/districts/school/prop_manifest.md:134` | **KEEP-PLANNED** |
| `assets/textures/surfaces/streetlight_metal_512.png` | `scripts/world/street_props.gd:34` | `scripts/world/street_props.gd:34` | reviewed | `docs/VISUAL_AUDIT.md:68` | **KEEP-LIVE** |
| `assets/textures/surfaces/tile_white_512.png` | — | — | reviewed | `docs/PROP_SPECS.md:68` | **UNCERTAIN** |
| `assets/textures/surfaces/wood_512.png` | — | — | reviewed | `docs/PROP_SPECS.md:20` | **UNCERTAIN** |
| `assets/textures/surfaces/xray_lightbox_512.png` | — | — | reviewed | `content/districts/hospital/prop_manifest.md:74` | **KEEP-PLANNED** |

The three live surface hits are independently visible in
`scripts/world/street_props.gd` / `scripts/world/streetlight_spawner.gd` and
`scripts/gameplay/hiding_spot.gd`; the table retains the exact line returned
by A and B. The planned rows cite delivered prop/gap/spec records, not mere
PNG existence. The twelve uncertain rows are not deletion recommendations.

Category proof from the same JSON manifest:

```text
$ python3 tools/quarantine_audit.py --json | python3 -c 'import json,sys,collections; p=json.load(sys.stdin); k="surfaces"; c=collections.Counter(x["verdict"] for x in p["results"] if x["kind"]==k); print(k+": "+", ".join(f"{v}={c[v]}" for v in ("KEEP-LIVE","KEEP-PLANNED","UNCERTAIN","AUTO-DELETABLE")))'
surfaces: KEEP-LIVE=3, KEEP-PLANNED=12, UNCERTAIN=12, AUTO-DELETABLE=0
```

## `assets/textures/ui/` — 49/49 source files

| File | A — full path | B — basename | D — dynamic pass | Doc anchor | Verdict |
|---|---|---|---|---|---|
| `assets/textures/ui/bar_battery.png` | — | — | reviewed | `docs/ASSET_MANIFEST.md:27-31` | **KEEP-PLANNED** |
| `assets/textures/ui/bar_fill_brass_256x24.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/bar_fill_ember_256x24.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/bar_fill_green_256x24.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/bar_frame_256x24.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/bar_health.png` | — | — | reviewed | `docs/ASSET_MANIFEST.md:27-31` | **KEEP-PLANNED** |
| `assets/textures/ui/bar_stamina.png` | — | — | reviewed | `docs/ASSET_MANIFEST.md:27-31` | **KEEP-PLANNED** |
| `assets/textures/ui/btn_action_128.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/btn_action_pressed_128.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/btn_crouch_128.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/btn_crouch_pressed_128.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/btn_disabled.png` | — | — | reviewed | `docs/ASSET_MANIFEST.md:27-31` | **KEEP-PLANNED** |
| `assets/textures/ui/btn_dodge_128.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/btn_dodge_pressed_128.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/btn_flashlight_128.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/btn_flashlight_pressed_128.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/btn_hover.png` | — | — | reviewed | `docs/ASSET_MANIFEST.md:27-31` | **KEEP-PLANNED** |
| `assets/textures/ui/btn_jump_128.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/btn_jump_pressed_128.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/btn_normal.png` | — | — | reviewed | `docs/ASSET_MANIFEST.md:27-31` | **KEEP-PLANNED** |
| `assets/textures/ui/btn_pressed.png` | — | — | reviewed | `docs/ASSET_MANIFEST.md:27-31` | **KEEP-PLANNED** |
| `assets/textures/ui/btn_special_hold_128.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/btn_tex_disabled.png` | `scripts/ui/theme_provider.gd:105` | `scripts/ui/theme_provider.gd:105` | reviewed | — | **KEEP-LIVE** |
| `assets/textures/ui/btn_tex_hover.png` | `scripts/ui/theme_provider.gd:103` | `scripts/ui/theme_provider.gd:103` | reviewed | — | **KEEP-LIVE** |
| `assets/textures/ui/btn_tex_normal.png` | `scripts/ui/theme_provider.gd:102` | `scripts/ui/theme_provider.gd:102` | reviewed | — | **KEEP-LIVE** |
| `assets/textures/ui/btn_tex_pressed.png` | `scripts/ui/theme_provider.gd:104` | `scripts/ui/theme_provider.gd:104` | reviewed | — | **KEEP-LIVE** |
| `assets/textures/ui/crosshair_64.png` | `scenes/ui/hud_3d.tscn:6` | `scenes/ui/hud_3d.tscn:6` | reviewed | `docs/BURST_REPORT.md:122` | **KEEP-LIVE** |
| `assets/textures/ui/crosshair_dot.png` | — | — | reviewed | `docs/BURST_REPORT.md:123` | **UNCERTAIN** |
| `assets/textures/ui/hitmarker_64.png` | `scenes/ui/hud_3d.tscn:7` | `scenes/ui/hud_3d.tscn:7` | reviewed | `docs/PLANS.md:789` | **KEEP-LIVE** |
| `assets/textures/ui/interact_icon_64.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/inventory_slot.png` | — | — | reviewed | `docs/ASSET_MANIFEST.md:27-31` | **KEEP-PLANNED** |
| `assets/textures/ui/minimap_enemy_blip_16.png` | — | — | reviewed | `docs/SESSION_REPORT_SHIP.md:74` | **KEEP-PLANNED** |
| `assets/textures/ui/minimap_frame_256.png` | `scripts/ui/minimap.gd:7` | `scripts/ui/minimap.gd:7` | reviewed | — | **KEEP-LIVE** |
| `assets/textures/ui/minimap_player_arrow_32.png` | `scripts/ui/minimap.gd:8` | `scripts/ui/minimap.gd:8` | reviewed | — | **KEEP-LIVE** |
| `assets/textures/ui/progress_fill.png` | — | — | reviewed | `docs/ASSET_MANIFEST.md:27-31` | **KEEP-PLANNED** |
| `assets/textures/ui/progress_frame.png` | — | — | reviewed | `docs/ASSET_MANIFEST.md:27-31` | **KEEP-PLANNED** |
| `assets/textures/ui/rarity_common.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/rarity_epic.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/rarity_rare.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/save_icon_brass_64.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/slot_frame_96.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/status_bleed.png` | `scripts/ui/hud_3d.gd:135` | `scripts/ui/hud_3d.gd:135` | reviewed | — | **KEEP-LIVE** |
| `assets/textures/ui/status_burn.png` | `scripts/ui/hud_3d.gd:136` | `scripts/ui/hud_3d.gd:136` | reviewed | — | **KEEP-LIVE** |
| `assets/textures/ui/status_poison.png` | `scripts/ui/hud_3d.gd:137` | `scripts/ui/hud_3d.gd:137` | reviewed | — | **KEEP-LIVE** |
| `assets/textures/ui/status_slow.png` | `scripts/ui/hud_3d.gd:138` | `scripts/ui/hud_3d.gd:138` | reviewed | — | **KEEP-LIVE** |
| `assets/textures/ui/status_stun.png` | `scripts/ui/hud_3d.gd:139` | `scripts/ui/hud_3d.gd:139` | reviewed | — | **KEEP-LIVE** |
| `assets/textures/ui/tooltip_panel.png` | — | — | reviewed | `docs/ASSET_MANIFEST.md:27-31` | **KEEP-PLANNED** |
| `assets/textures/ui/ui_corner_accent.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |
| `assets/textures/ui/ui_divider_brass.png` | — | — | reviewed | — owner eyes | **UNCERTAIN** |

For the grouped old UI chrome rows, the per-file citation is the wildcard
entry `docs/ASSET_MANIFEST.md:27-31`: the UI chrome exists, current UI draws
procedurally, and swapping it is a future visual-polish pass. For
`minimap_enemy_blip_16.png`, the owner-decision/deferred note is
`docs/SESSION_REPORT_SHIP.md:74`; it is retained rather than auto-deleted.
Live UI rows are backed by the exact source lines in the A/B columns.

```text
$ python3 tools/quarantine_audit.py --json | python3 -c 'import json,sys,collections; p=json.load(sys.stdin); k="ui"; c=collections.Counter(x["verdict"] for x in p["results"] if x["kind"]==k); print(k+": "+", ".join(f"{v}={c[v]}" for v in ("KEEP-LIVE","KEEP-PLANNED","UNCERTAIN","AUTO-DELETABLE")))'
ui: KEEP-LIVE=13, KEEP-PLANNED=12, UNCERTAIN=24, AUTO-DELETABLE=0
```

## Five spot-checks, live greps

```text
$ rg -n --fixed-strings 'res://assets/textures/surfaces/streetlight_metal_512.png' scripts scenes components data addons
scripts/world/streetlight_spawner.gd:39: var pole_tex: Texture2D = load("res://assets/textures/surfaces/streetlight_metal_512.png")
scripts/world/street_props.gd:34: const _TEX_STREETLIGHT := "res://assets/textures/surfaces/streetlight_metal_512.png"

$ rg -n --fixed-strings 'res://assets/textures/ui/btn_tex_normal.png' scripts scenes components data addons
scripts/ui/theme_provider.gd:102: var btn_tex_n := _load_tex("res://assets/textures/ui/btn_tex_normal.png")

$ rg -n --fixed-strings 'res://assets/textures/ui/minimap_frame_256.png' scripts scenes components data addons
scripts/ui/minimap.gd:7: const _FRAME_TEX: Texture2D = preload("res://assets/textures/ui/minimap_frame_256.png")

$ rg -n --fixed-strings 'res://assets/textures/ui/status_bleed.png' scripts scenes components data addons
scripts/ui/hud_3d.gd:135: EnemyRosterData.Status.BLEED: [..., "res://assets/textures/ui/status_bleed.png"]

$ rg -n --fixed-strings 'res://assets/textures/surfaces/bench_wood_512.png' scripts scenes components data addons
scripts/world/street_props.gd:35: const _TEX_BENCH       := "res://assets/textures/surfaces/bench_wood_512.png"
```

These are spot checks only; the complete per-file evidence is the table and
the machine-readable output of `tools/quarantine_audit.py --json`.

## Scope review

```text
$ git diff --stat -- docs/QUARANTINE_AUDIT.md docs/SURFACES_UI_NARROWING.md tools/quarantine_audit.py
# expected changed paths: these three files only; no source or .import asset path appears
```

Self-review: all 27 surfaces and 49 UI PNGs are present; dynamic loaders are
listed; uncertain assets remain for owner eyes; no deletions and no
`docs/SIZE_BUDGET.md` edit.
