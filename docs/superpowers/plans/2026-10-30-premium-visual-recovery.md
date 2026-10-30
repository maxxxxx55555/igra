# Premium Visual Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the active block-plaza world and empty inventory composition with a coherent, detailed, mobile-first premium visual pass across every district and reachable screen.

**Architecture:** Reconstruct the shared procedural builders (`skyline`, `street_builder`, `street_props`, `district_dressing`) so all eleven districts improve together; restyle the global theme and rebuild the live inventory composition; preserve gameplay, data, saves, navigation, power stages, and quality tiers. Prove the work with a runtime visual-contract gate, live captures, static/scene gates, performance measurements, and a phone build when a device is available.

**Tech Stack:** Godot 4.7, GDScript, GL Compatibility, MultiMesh batching, `PartMesh` procedural meshes, existing PBR texture sets, Python/GDScript repository gates.

## Global Constraints

- Work only on `qoder/premium-visual-recovery`; never merge, push to `main`, or reset another agent's worktree.
- Android ARM64 landscape is primary; minimum SDK 29, target SDK 36, immersive mode, ETC2/ASTC, no SSAO/SSR/volumetric-fog/auto-exposure dependency.
- Minimum body text 16sp, supporting 14sp, section approximately 18sp, title 24–28sp; minimum touch action 48dp after scaling; hover never required.
- Budgets: D1 draw calls `<200`, D11 `<350`, polygons `<50K`/district, total dynamic lights `<8`, particles `<500`, RAM `<800MB`, VRAM `<400MB`; prop textures target 512², 1024² only for important close surfaces, 2048² exceptional hero art.
- Preserve all gameplay, economy, progression, inventory data operations, save schema, navigation, collision surfaces, power-stage logic, localization, remapped input, touch behavior, and accessibility settings.
- No new user-facing string without all six live locales; no filler items, fabricated equipment, fake screens, TODO/FIXME/debug prints, or heavy grain masking.
- Every commit is small, English, imperative, and pushed; a claim of visual completion requires a real capture or measurement.

---

### Task 1: Runtime visual-contract gate and mobile scale utility

**Files:**
- Create: `scripts/ui/ui_scale.gd`
- Create: `scripts/tools/premium_visual_check.gd`
- Create: `scenes/tools/premium_visual_check_scene.tscn`
- Modify: `scripts/tools/_ui_frames_runner.gd:9-27`
- Test: `scenes/tools/premium_visual_check_scene.tscn`

**Interfaces:**
- Consumes: `DistrictSceneFactory.district_scene_path(id)`, `UIManager._get_screen(id)`, `SettingsManager.TEXT_SCALE`.
- Produces: `UiScale.insets(viewport: Vector2) -> Vector4`, `UiScale.narrow_layout(width: float, text_scale: float) -> bool`, `UiScale.min_touch() -> float`; node names `FacadeTrim`, `WindowSills`, `FacadePipes`, `CurbMM`, `RoadDamageMM`, `UrbanSetDressing`, `EquipmentColumn`, `ItemColumn`, `InspectorColumn`, `InventoryToolbar`, `ItemGrid`.

- [ ] **Step 1: Write the failing runtime contract**

```gdscript
# scripts/tools/premium_visual_check.gd
extends Node

var _fails: int = 0

func _ready() -> void:
	for id: StringName in DistrictSceneFactory.DISTRICTS:
		await _check_district(id)
	await _check_inventory()
	print("[premium] DONE fails=", _fails)
	get_tree().quit(1 if _fails > 0 else 0)

func _check_district(id: StringName) -> void:
	var scene := load(DistrictSceneFactory.district_scene_path(id)) as PackedScene
	var root := scene.instantiate() as Node3D
	add_child(root)
	for i in 8:
		await get_tree().process_frame
	for name in ["FacadeTrim", "WindowSills", "FacadePipes", "CurbMM", "RoadDamageMM", "UrbanSetDressing"]:
		_expect(root.find_child(name, true, false) != null, "%s missing %s" % [id, name])
	root.queue_free()
	await get_tree().process_frame

func _check_inventory() -> void:
	var root := UIManager._get_screen(&"inventory") as Control
	_expect(root != null, "inventory does not build")
	if root == null:
		return
	root.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	for name in ["EquipmentColumn", "ItemColumn", "InspectorColumn", "InventoryToolbar", "ItemGrid"]:
		_expect(root.find_child(name, true, false) != null, "inventory missing %s" % name)
	_expect(UiScale.min_touch() >= 48.0, "touch target below 48")
	_expect(UiScale.narrow_layout(960.0, 1.0), "phone width did not select narrow layout")
	_expect(not UiScale.narrow_layout(1280.0, 1.0), "desktop width selected narrow layout")
	root.visible = false

func _expect(ok: bool, message: String) -> void:
	if ok:
		return
	_fails += 1
	print("[premium] [FAIL] ", message)
```

```gdscript
# scripts/ui/ui_scale.gd
class_name UiScale
extends RefCounted

const NARROW_WIDTH: float = 1120.0
const MIN_TOUCH: float = 48.0

static func narrow_layout(width: float, text_scale: float) -> bool:
	return width < NARROW_WIDTH or text_scale > 1.16

static func min_touch() -> float:
	return MIN_TOUCH

static func insets(viewport: Vector2) -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var screen: Vector2 = Vector2(DisplayServer.screen_get_size())
	var safe: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	if screen.x <= 1.0 or screen.y <= 1.0 or safe.size.x <= 1.0:
		return Vector4.ZERO
	var sx: float = viewport.x / screen.x
	var sy: float = viewport.y / screen.y
	return Vector4(safe.position.x * sx, safe.position.y * sy,
		(screen.x - safe.end.x) * sx, (screen.y - safe.end.y) * sy)
```

The scene is `Node` with script `premium_visual_check.gd`.

- [ ] **Step 2: Run the gate and confirm it fails on missing visual nodes**

Run:

```bash
"C:/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe" --headless --path . scenes/tools/premium_visual_check_scene.tscn
```

Expected: `fails > 0`, with missing facade/road/urban/inventory node messages.

- [ ] **Step 3: Make UI captures resolution-configurable**

In `_ui_frames_runner.gd`, replace the fixed window line with:

```gdscript
var frame_width: int = int(OS.get_environment("TLS_FRAME_WIDTH")) if not OS.get_environment("TLS_FRAME_WIDTH").is_empty() else 1280
var frame_height: int = int(OS.get_environment("TLS_FRAME_HEIGHT")) if not OS.get_environment("TLS_FRAME_HEIGHT").is_empty() else 720
get_window().size = Vector2i(frame_width, frame_height)
```

- [ ] **Step 4: Run static gates**

Run:

```bash
bash tools/check.sh --static
python tools/flow_check.py
python tools/scene_node_check.py
```

Expected: all exit `0`.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/ui_scale.gd scripts/tools/premium_visual_check.gd scenes/tools/premium_visual_check_scene.tscn scripts/tools/_ui_frames_runner.gd
git commit -m "Add the premium visual contract gate"
```

---

### Task 2: Reconstruct facades with real depth and material variation

**Files:**
- Modify: `scripts/world/skyline.gd:92-168`, `scripts/world/skyline.gd:170-200`
- Test: `scenes/tools/premium_visual_check_scene.tscn`

**Interfaces:**
- Consumes: `PbrSets.apply`, existing `_add_multimesh`, district palette and `panes` loop.
- Produces: `FacadeTrim`, `WindowSills`, `FacadePipes` MultiMesh nodes; unchanged `Windows`, `Blocks`, `Signs`, collision and stage behavior.

- [ ] **Step 1: Extend `build()` with batched facade-detail arrays**

Add before the side loop:

```gdscript
var trim: Array[Transform3D] = []
var sills: Array[Transform3D] = []
var pipes: Array[Transform3D] = []
```

Inside the pane loop, after appending the pane, append its frame parts with a local frame transform:

```gdscript
var win_frame := Transform3D(turn, turn * Vector3(x, y, -edge))
for offset in [
	Transform3D(Basis.from_scale(Vector3(0.08, 1.52, 0.20)), Vector3(-0.55, 0.0, 0.10)),
	Transform3D(Basis.from_scale(Vector3(0.08, 1.52, 0.20)), Vector3(0.55, 0.0, 0.10)),
	Transform3D(Basis.from_scale(Vector3(1.28, 0.09, 0.20)), Vector3(0.0, 0.74, 0.10)),
]:
	trim.append(win_frame * offset)
sills.append(win_frame * Transform3D(Basis.from_scale(Vector3(1.34, 0.10, 0.36)), Vector3(0.0, -0.76, 0.16)))
sills.append(win_frame * Transform3D(Basis.from_scale(Vector3(1.16, 0.06, 0.52)), Vector3(0.0, -0.84, 0.23)))
```

At each row boundary append one full-width ledge; at block completion append plinth, cornice and a downpipe:

```gdscript
trim.append(frame * Transform3D(Basis.from_scale(Vector3(size.x, 0.10, 0.24)), Vector3(0.0, y - 1.30, 0.12)))
trim.append(frame * Transform3D(Basis.from_scale(Vector3(size.x + 0.24, 0.26, 0.34)), Vector3(0.0, size.y - 0.14, 0.12)))
trim.append(frame * Transform3D(Basis.from_scale(Vector3(size.x, 0.82, 0.18)), Vector3(0.0, 0.41, 0.09)))
pipes.append(frame * Transform3D(Basis(), Vector3(size.x * 0.5 - 0.28, 0.0, 0.20)))
```

Use a radius `0.055 x (size.y - 0.5) x 0.055` cylinder batch for the pipes.

- [ ] **Step 2: Add detail batches without breaking stage glow**

Add:

```gdscript
func _add_detail_batch(node_name: String, mesh: Mesh, xforms: Array[Transform3D], material: Material) -> void:
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

func _detail_material(set_name: String, tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.88
	return preload("res://scripts/world/pbr_sets.gd").apply(mat, set_name)
```

After the blocks/windows batches, add a `BoxMesh` batch named `FacadeTrim` with `_detail_material("panel_facade", Color(0.58, 0.58, 0.55))`, a `BoxMesh` batch named `WindowSills` with `_detail_material("cracked_concrete", Color(0.62, 0.61, 0.57))`, and a `CylinderMesh` batch named `FacadePipes` with `_detail_material("rusted_metal", Color(0.34, 0.31, 0.27))`. In `_set_detail`, hide these nodes below tier 1 using `visible = detail >= 1.0`.

- [ ] **Step 3: Run the contract gate and static checks**

Run:

```bash
"C:/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe" --headless --path . scenes/tools/premium_visual_check_scene.tscn
bash tools/check.sh --static
python tools/flow_check.py
python tools/scene_node_check.py
```

Expected: facade node failures disappear; remaining failures are curbs, road damage, urban dressing and inventory.

- [ ] **Step 4: Capture representative facade frames**

Run the existing density runner on the dark street and inspect front, close and oblique views:

```bash
TLS_FRAMES_HASH=facades "C:/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe" --path . scenes/tools/density_frames_scene.tscn
```

Expected: silhouettes show frames, sills, ledges, pipes and varied rooflines rather than a flat box with painted panes.

- [ ] **Step 5: Commit**

```bash
git add scripts/world/skyline.gd
git commit -m "Give district facades real trim and depth"
```

---

### Task 3: Replace streets and streetlights with damaged, credible modules

**Files:**
- Modify: `scripts/world/street_builder.gd:46-243`
- Create: `scripts/world/streetlight_kit.gd`
- Modify: `scripts/world/street_props.gd:189-232`
- Modify: `scripts/world/streetlight_3d.gd:33-40`
- Modify: `scenes/props/streetlight_3d.tscn:25-51`
- Test: `scenes/tools/premium_visual_check_scene.tscn`

**Interfaces:**
- Consumes: `PbrSets.apply`, `PartMesh.part/build`, existing road tile transforms and light offsets.
- Produces: `StreetlightKit.mesh() -> ArrayMesh`, `CurbMM`, `RoadDamageMM`; unchanged `StreetCollision`, `roads`, pole positions, lights and stage reactivity.

- [ ] **Step 1: Add curb and damage batches**

Add `_curb_mm` and `_damage_mm` children named `CurbMM` and `RoadDamageMM` in `_ensure_mm()`. Give both one `MultiMesh` each. Build curbs along both road edges for non-intersection tiles at `road_width * 0.5 + 0.11`, with a `BoxMesh` size `Vector3(tile_size, 0.17, 0.22)` and a cracked-concrete material. Build a deterministic damage batch from `RandomNumberGenerator` seeded by `hash(str(district_id) + "_road_damage")`; place 1–2 thin `BoxMesh` patches (`2.2 x 0.012 x 0.9`) per tile at road top `0.071`, rotated by multiples of `PI / 2` plus a small jitter, with the asphalt material darkened to `Color(0.06, 0.065, 0.07)`.

- [ ] **Step 2: Create the slender streetlight mesh**

```gdscript
# scripts/world/streetlight_kit.gd
extends RefCounted

const _Parts := preload("res://scripts/art/part_mesh.gd")
static var _mesh: ArrayMesh = null

static func mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var p: Array = [
		_Parts.part(&"cyl", Vector3(0.34, 0.10, 0.40), Vector3(0, 0.05, 0)),
		_Parts.part(&"cyl", Vector3(0.16, 0.28, 0.22), Vector3(0, 0.24, 0)),
		_Parts.part(&"cyl", Vector3(0.085, 4.0, 0.11), Vector3(0, 2.18, 0)),
		_Parts.part(&"cyl", Vector3(0.075, 0.52, 0.075), Vector3(0.17, 4.24, 0), Vector3(0, 0, 58)),
		_Parts.part(&"cyl", Vector3(0.065, 0.58, 0.065), Vector3(0.66, 4.40, 0), Vector3(0, 0, 78)),
		_Parts.part(&"box", Vector3(0.32, 0.10, 0.22), Vector3(1.12, 4.31, 0)),
		_Parts.part(&"box", Vector3(0.14, 0.16, 0.15), Vector3(0.0, 1.10, 0.08)),
	]
	_mesh = _Parts.build(p)
	return _mesh
```

In `_build_streetlight_multimesh()`, set `pole_mm.mesh = streetlight_kit.mesh()`; choose the batch mesh by offset. In `streetlight_3d.gd:_ready`, set `pole.mesh = preload("res://scripts/world/streetlight_kit.gd").mesh()` and leave lamp visibility/state behavior intact. In `street_props.gd`, replace the blue-grey pole material with `_prop_material(_TEX_STREETLIGHT, Color(0.22, 0.22, 0.20), 0.72, 0.45)`.

- [ ] **Step 3: Narrow the light origin**

In `streetlight_3d.tscn`, set the spot `spot_angle = 32.0`, `spot_range = 10.0`, `spot_attenuation = 0.8`; keep positions and all runtime energy assignments. Reduce `district_dressing.gd` `POOL_M` from `9.0` to `6.5` and `POOL_TOWARD_BLOCK_M` from `2.2` to `1.6`.

- [ ] **Step 4: Run contract and regression gates**

```bash
"C:/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe" --headless --path . scenes/tools/premium_visual_check_scene.tscn
bash tools/check.sh --static
python tools/flow_check.py
python tools/scene_node_check.py
```

Expected: curb/damage failures disappear; power-stage and density checks stay green.

- [ ] **Step 5: Commit**

```bash
git add scripts/world/street_builder.gd scripts/world/streetlight_kit.gd scripts/world/street_props.gd scripts/world/streetlight_3d.gd scripts/world/district_dressing.gd scenes/props/streetlight_3d.tscn
git commit -m "Rebuild streets and streetlights at human scale"
```

---

### Task 4: Add curated district set dressing

**Files:**
- Create: `scripts/world/urban_set_dressing.gd`
- Modify: `scripts/world/district_dressing.gd:134-151`
- Test: `scenes/tools/premium_visual_check_scene.tscn`

**Interfaces:**
- Consumes: `PartMesh`, `HidingMeshes`, `_clear` keep-clear points, `_grid`, `_inner`, `_walk`.
- Produces: `UrbanSetDressing` node owning batched wrecks, pallets, pipes, cabinets, barriers, tyres, sacks and dead shrubs; no collision or navigation.

- [ ] **Step 1: Build the mesh family**

Create `urban_set_dressing.gd` with these static mesh builders from `PartMesh`: `wreck` (body, cabin, four wheels), `pallets` (three stacked plank boxes), `pipes` (four cylinders), `cabinet` (box, recessed door, vents, cable conduit), `barrier` (two legs and three horizontal planks), `tyres` (three toruses), `sacks` (three squashed spheres) and `shrub` (three dark branch cylinders). Each is cached in a dictionary and built once.

Use this district count table:

```gdscript
const KIT := {
	&"suburbs": {"wreck": 1, "pallets": 2, "pipes": 1, "cabinet": 1, "barrier": 2, "tyres": 1, "sacks": 1, "shrub": 4},
	&"residential": {"wreck": 2, "pallets": 2, "pipes": 2, "cabinet": 1, "barrier": 2, "tyres": 2, "sacks": 1, "shrub": 3},
	&"park": {"wreck": 0, "pallets": 1, "pipes": 0, "cabinet": 1, "barrier": 3, "tyres": 0, "sacks": 1, "shrub": 8},
	&"school": {"wreck": 1, "pallets": 2, "pipes": 1, "cabinet": 2, "barrier": 2, "tyres": 1, "sacks": 1, "shrub": 3},
	&"hospital": {"wreck": 1, "pallets": 1, "pipes": 1, "cabinet": 2, "barrier": 3, "tyres": 1, "sacks": 1, "shrub": 2},
	&"gas_station": {"wreck": 2, "pallets": 2, "pipes": 2, "cabinet": 2, "barrier": 2, "tyres": 3, "sacks": 2, "shrub": 1},
	&"police": {"wreck": 2, "pallets": 1, "pipes": 1, "cabinet": 2, "barrier": 3, "tyres": 1, "sacks": 1, "shrub": 2},
	&"warehouses": {"wreck": 2, "pallets": 4, "pipes": 3, "cabinet": 2, "barrier": 2, "tyres": 3, "sacks": 2, "shrub": 0},
	&"industrial": {"wreck": 3, "pallets": 3, "pipes": 5, "cabinet": 3, "barrier": 2, "tyres": 4, "sacks": 2, "shrub": 0},
	&"substation": {"wreck": 1, "pallets": 1, "pipes": 4, "cabinet": 3, "barrier": 3, "tyres": 1, "sacks": 1, "shrub": 0},
	&"power_station": {"wreck": 1, "pallets": 2, "pipes": 4, "cabinet": 3, "barrier": 3, "tyres": 2, "sacks": 1, "shrub": 0},
}
```

**Step 2: Place and batch deterministically**

Seed with `hash("urban_set_" + district_id)`. For each of the nine blocks, choose a seeded edge point and skip it when `_clear` is within `1.8` metres. Rotate every piece to face the nearest road. Use one `MultiMesh` per kind with `material_override` built from `PbrSets.apply` (`plywood` for pallets/barrier, `rusted_metal` for pipes/cabinet/tyres, `cracked_concrete` for sacks, dark bark for shrub, dark metal for wreck). On tiers below `1`, halve counts. Stamp contact shadows through the existing `ContactShadows` batch when enabled. Parent all batches under one `UrbanSetDressing` node.

In `district_dressing.gd`, instantiate `urban_set_dressing.gd` before `_apply_stage`, call `build(self, district_id, sb, _clear, _grid, _inner)`, and set `name = "UrbanSetDressing"`.

- [ ] **Step 3: Run contract, density and performance gates**

```bash
"C:/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe" --headless --path . scenes/tools/premium_visual_check_scene.tscn
python tools/qa_sim/drawcall_estimate.py
python tools/scene_node_check.py
```

Expected: all missing-node failures are gone except inventory; draw calls remain within the active tier budget or the task is not complete.

- [ ] **Step 4: Capture dense and open districts for visual review**

Run the density frame runner for suburbs, industrial and park. Expected: route remains clear; wrecks, barriers, pipes and vegetation produce foreground/midground depth without blocking pickups, hiding places or paths.

- [ ] **Step 5: Commit**

```bash
git add scripts/world/urban_set_dressing.gd scripts/world/district_dressing.gd
git commit -m "Dress every district with curated urban props"
```

---

### Task 5: Apply the mobile-first theme, exposure and shared UI scale

**Files:**
- Modify: `scripts/ui/theme_provider.gd`
- Modify: `scripts/systems/settings_manager.gd:72-121`, `:381-408`
- Modify: `scripts/ui/main_menu_layout.gd:22-56`
- Modify: `scripts/world_env_setup.gd:270-305`
- Test: `scripts/tools/_ui_layout_check.gd`

**Interfaces:**
- Consumes: `UiScale.insets`, `UiScale.min_touch`, `SettingsManager.TEXT_SCALE`, existing `build_theme()` consumers.
- Produces: new palette tokens, rectangular brass controls, raised panel/slot styleboxes, mobile-safe margins; no API rename.

- [ ] **Step 1: Update theme tokens and remove chamfered texture chrome**

Change colors to:

```gdscript
const COLOR_BG_DARK := Color("#080E10")
const COLOR_BG_PANEL := Color("#121A1B")
const COLOR_BG_PANEL2 := Color("#1C2423")
const COLOR_BORDER := Color("#655332")
const COLOR_AMBER := Color("#C58A2D")
const COLOR_AMBER_DIM := Color("#8A7338")
const COLOR_AMBER_HI := Color("#D7CCB6")
const COLOR_TEXT := Color("#D7CCB6")
const COLOR_TEXT_DIM := Color("#A89F8D")
const COLOR_DANGER := Color("#A43C2B")
```

Keep old constant names for compatibility. Do not apply `btn_tex_*` textures; the flat rectangular StyleBoxFlat family is the active chrome. Add `SlotPanel` and `RaisedPanel` type variations with 1 px borders, panel/raised fills and content margins 8/12. Set `FONT_SIZE_BODY = 16`, `FONT_SIZE_TITLE = 24`, `FONT_SIZE_DISPLAY = 44`, `FONT_SIZE_HUGE = 30`, `FONT_SIZE_SMALL = 14`.

- [ ] **Step 2: Make fresh mobile defaults and minimum controls explicit**

In `_load_defaults()`:

```gdscript
_settings["graphics_tier"] = 1 if OS.has_feature("mobile") else 2
```

Keep saved settings untouched. In `_apply_text_size()`, use `TEXT_SCALE = [1.0, 1.1, 1.25]` so default body remains at least 16 px after scaling. Clamp effective HUD button scaling to `maxf(UiScale.min_touch() / 72.0, button_size)`.

- [ ] **Step 3: Apply cutout-safe margins to the main menu and shared screens**

In `main_menu_layout.gd`, read `UiScale.insets(viewport)` and add left/top/right/bottom insets to the existing margin and available width/height calculations. Preserve the current scale clamp and fit behavior.

- [ ] **Step 4: Remove grain as a masking device**

In `world_env_setup.gd:_apply_postfx`, change the grain fallback from `0.1` to `0.035`, clamp it to `0.05`, and change the vignette fallback from `0.55` to `0.32`, clamped to `0.4`. Keep the actual tier visibility behavior; the frame must remain readable and premium with grain disabled.

- [ ] **Step 5: Run layout and static gates**

```bash
"C:/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe" --headless --path . res://scenes/tools/ui_layout_check_scene.tscn
bash tools/check.sh --static
python tools/flow_check.py
```

Expected: `[uilay] DONE fails=0`; layout/scene checks remain green.

- [ ] **Step 6: Commit**

```bash
git add scripts/ui/theme_provider.gd scripts/systems/settings_manager.gd scripts/ui/main_menu_layout.gd scripts/ui/ui_scale.gd scripts/world_env_setup.gd
git commit -m "Apply the mobile-first premium theme foundation"
```

---

### Task 6: Recompose the inventory into the three-column blueprint

**Files:**
- Create: `scripts/ui/survivor_preview.gd`
- Modify: `scripts/ui/inventory_ui.gd` (replace the current `_ready`, `_refresh`, `_cell`, `_refresh_detail`, `_refresh_side` composition while keeping every handler)
- Test: `scenes/tools/premium_visual_check_scene.tscn`, `scenes/tools/ui_layout_check_scene.tscn`

**Interfaces:**
- Consumes: `InventoryManager.slots`, `InventoryManager.get_equipped`, `InventoryManager.sort_slots`, `ItemDatabase.get_item`, `ITEM_ICONS.draw_icon`, `QuickSlots`, `UIManager.close`, `UiScale.narrow_layout`.
- Produces: `InventoryHeader`, `EquipmentColumn`, `ItemColumn`, `InspectorColumn`, `InventoryToolbar`, `ItemGrid`, `QuickAccess`; selection, use, equip, drop, sort, filter, quick-slot binding preserved.

- [ ] **Step 1: Extend the contract for layout behavior**

Add to `premium_visual_check.gd`:

```gdscript
var grid := root.find_child("ItemGrid", true, false) as GridContainer
_expect(grid != null and grid.columns == 4, "inventory grid is not four columns")
_expect(grid.get_child_count() == InventoryManager.slots.size(), "grid does not show every real slot")
_expect(root.find_child("InventoryToolbar", true, false) is HBoxContainer, "toolbar is not compact")
```

Run the gate. Expected: new assertions fail against the old two-column inventory.

- [ ] **Step 2: Implement the composition**

Build a 24 px inset frame (`UiScale.insets(get_viewport_rect().size)` added to margins). Header contains title, real weight/capacity, and close. Body uses three columns: equipment (216 px), center item area (expand), inspector (368 px). The center column contains a compact toolbar with three sort buttons and an `ItemDatabase` rarity filter option; the `ItemGrid` is 4 columns with 112 px cells and 8 px gaps. Footer holds the six quick slots and a status line.

In `_refresh()`, iterate every `InventoryManager.slots` index. Add an active cell for real matching items and a disabled styled empty cell otherwise, so base capacity is always 12 cells and expanded capacity pages/scrolls. Preserve original indices.

Create a `SurvivorPreview` Control that draws a bone-on-dark human silhouette plus five real equipment labels from `InventoryManager.get_equipped`; do not draw fabricated clothes.

`_refresh_detail()` uses a 240x176 preview box (`ITEM_ICONS.draw_icon(..., 176.0)`), name, rarity, weight and effect, then Use/Equip/Drop buttons. Keep the two-press drop confirmation. Disabled actions explain availability through the existing button disabled state.

- [ ] **Step 3: Implement the phone secondary inspector**

On `resized`, compute `UiScale.narrow_layout(size.x, SettingsManager.TEXT_SCALE[text_size])`. In wide mode, `InspectorColumn` sits in the body. In narrow mode, hide the inline inspector and show a full-height `InventoryInspectorOverlay` with a Back button when a real item is selected. Keep equipment and the grid on the primary view. Input selection and all actions work through the overlay.

- [ ] **Step 4: Run contract and layout gates**

```bash
"C:/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe" --headless --path . scenes/tools/premium_visual_check_scene.tscn
"C:/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe" --headless --path . res://scenes/tools/ui_layout_check_scene.tscn
```

Expected: `fails=0` in both; inventory shows stable cells and no off-frame controls.

- [ ] **Step 5: Capture inventory states**

Run `ui_frames_scene` at 1280x720 and inspect inventory with the real sparse fixture, empty, filtered-empty, near-capacity and disabled actions.

- [ ] **Step 6: Commit**

```bash
git add scripts/ui/survivor_preview.gd scripts/ui/inventory_ui.gd scripts/tools/premium_visual_check.gd
git commit -m "Rebuild inventory around the three-column blueprint"
```

---

### Task 7: Restyle HUD, map and reachable screens

**Files:**
- Modify: `scripts/ui/hud_3d.gd` (status group, objective card, interaction prompt, notice area, touch-button minimum sizing)
- Modify: `scripts/ui/city_map.gd:43-112`
- Modify: `scripts/ui/main_menu.gd` only if the active hero composition needs safe-area/contrast correction
- Modify: `scripts/ui/toast_manager.gd:189-202`, `:270-314`
- Test: `scenes/tools/premium_visual_check_scene.tscn`, `scenes/tools/ui_layout_check_scene.tscn`, UI captures

**Interfaces:**
- Consumes: shared theme tokens and `UiScale`; unchanged player, quest, map, notification and input APIs.
- Produces: compact HUD clusters, responsive safe-area map, unified notification surfaces; no gameplay changes.

- [ ] **Step 1: Make the map responsive**

Replace the fixed 720x560 root size with a `PanelContainer` anchored to the viewport with insets from `UiScale.insets`. Width is `min(viewport.x - insets - 32, 1100)`, height is `min(viewport.y - insets - 32, 720)`. Action rows use at least 48 px height; legend wraps below the map on narrow layouts instead of shrinking text. Keep real markers and filters.

- [ ] **Step 2: Recompose HUD groups and notifications**

Apply raised dark panels with 1 px aged-brass borders to the top-left status stack, objective card and interaction prompt. Keep the central reticle clear. Put tutorial, reward, level and interaction notices through the existing priority queue with one visible surface plus the existing compact fallback. Ensure the joystick and action cluster use at least 48 px effective targets and are offset by safe-area insets.

- [ ] **Step 3: Propagate themed surfaces**

Verify the main menu, settings, pause, death, win, NG+, workbench, skill tree, codex tabs, help, stats, achievements and credits use the shared theme. Remove active per-screen overrides that contradict the rectangular aged-brass family; keep real content, localization, input and states.

- [ ] **Step 4: Run checks and capture every screen**

```bash
"C:/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe" --headless --path . res://scenes/tools/ui_layout_check_scene.tscn
TLS_FRAME_WIDTH=1280 TLS_FRAME_HEIGHT=720 TLS_FRAMES_HASH=premium "C:/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe" --path . scenes/tools/ui_frames_scene.tscn
```

Expected: layout gate green; all reachable screens show the same visual language and readable touch controls.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/hud_3d.gd scripts/ui/city_map.gd scripts/ui/toast_manager.gd scripts/ui/main_menu.gd
git commit -m "Unify HUD, map and screen presentation"
```

---

### Task 8: Final evidence, performance and release audit

**Files:**
- Create: `docs/superpowers/evidence/2026-10-30-premium-visual-recovery.md`
- Modify: `docs/RUN_STATE.md` only with actual gate results and next action
- Test: all existing gates, live captures, Android build

**Interfaces:**
- Consumes: all previous tasks and the repository's release workflows.
- Produces: one candidate revision with truthful READY/BLOCKED/INCOMPLETE evidence.

- [ ] **Step 1: Run the complete static and scene gate set**

```bash
bash tools/check.sh --static
python tools/flow_check.py
python tools/scene_node_check.py
python tools/lint_changed.py
"C:/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe" --headless --path . scenes/tools/premium_visual_check_scene.tscn
"C:/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe" --headless --path . res://scenes/tools/ui_layout_check_scene.tscn
```

Expected: every command exits `0`; any failure returns to its owning task.

- [ ] **Step 2: Capture the final visual matrix**

Capture at 1280x720 and 1920x1080: the supplied street/lamp viewpoint; close and oblique facade, road/curb, lamp and electrical equipment; inventory states; all 11 districts in applicable power states; every changed screen. Record revision, seed, camera, quality tier and UTC time in filenames and the evidence document.

- [ ] **Step 3: Verify live behavior and performance**

Run a traversal with power restoration, pickup/use, inventory, map, settings, pause/resume, save/reload and an affected combat/death path. Measure the repeatable route: draw calls, p99 frame time, VRAM, particles and dynamic lights. Record the measured profile; do not reuse a result from another revision.

- [ ] **Step 4: Build the Android candidate**

```bash
mkdir -p build
"C:/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe" --headless --export-debug "Android" build/TLS-premium.aab
```

If the export template or signing environment is unavailable, record the exact blocker. If `adb` and a physical ARM64 device are available, install, launch, capture, measure and logcat the build; otherwise mark phone verification BLOCKED, not READY.

- [ ] **Step 5: Write evidence and close the pass truthfully**

The evidence record lists each acceptance item, file path, command/result and remaining defect. Mark READY only when the final candidate has all applicable evidence and no release-blocking visual or functional defect. Otherwise mark BLOCKED or INCOMPLETE with the exact missing item.

- [ ] **Step 6: Commit and push**

```bash
git add docs/superpowers/evidence/2026-10-30-premium-visual-recovery.md docs/RUN_STATE.md
git commit -m "Record premium visual recovery evidence"
git push origin qoder/premium-visual-recovery
```

---

## Self-Review

**Spec coverage:** mobile contract → Tasks 1, 5, 7, 8; facades → Task 2; street surfaces/streetlights → Task 3; district dressing/lighting → Tasks 3–4; theme/inventory/HUD/map/all screens → Tasks 5–7; preservation and failure handling → global constraints and Task 8; acceptance evidence → Task 8.

**Placeholder scan:** no TBD, TODO, “implement later”, or unnamed tests remain. Optional Android hardware is handled as an explicit blocker, not an invented result.

**Type consistency:** `UiScale.narrow_layout(float, float) -> bool`, `UiScale.min_touch() -> float` and `UiScale.insets(Vector2) -> Vector4` are defined once and reused. `StreetlightKit.mesh() -> ArrayMesh`, `PartMesh.part/build`, `PbrSets.apply`, `UIManager._get_screen` and `DistrictSceneFactory.district_scene_path` match the live APIs.
