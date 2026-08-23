# PROP_SPECS.md — THE LAST STREETLIGHT
Canonical prop dimensions for modeling (external Meshy/manual per art-pipeline). All props: GL Compatibility target, static meshes, no skinning. Pivot = origin placed as noted; Z-up in DCC → Y-up on Godot import. Poly budgets are hard caps at LOD0.

Shared material slots convention: `M_base` (albedo from assets/textures/surfaces/*_512.png, roughness high), `M_metal` (steel #aeb6bf tinted, metallic 0.7–0.9), `M_accent` (brass #c9a24a / ember #b4452f details). Max 2 slots per prop on mobile.

## streetlight
- Dimensions: pole h 4.0 m r 0.05 m; arm 0.8 m horizontal reach; lamp head cone 45° half-angle; base plate 0.3 x 0.3 x 0.2 m.
- Pivot: base center, y=0 (sits on floor).
- Polys: LOD0 ≤ 480 (pole 12-seg cylinder, arm 8-seg tube, head box+cone trim), LOD1 ≤ 160 (6-seg pole, merged head).
- Collision: capsule (r 0.08, h 4.0) offset to pole axis; base ignored (below knee height).
- Materials: M_metal (pole/arm), M_accent (head rim); emissive lamp disc separate mesh slot `M_lamp` (emission #c9a24a energy 2.0).
- Light: OmniPixel? No — SpotLight3D, color #c9a24a, energy 2.0, range 14 m, angle 45°, softness default; attach at head, aim -Y with 10° forward tilt.
- Mobile: single mesh, no alpha, light itself is scene node not baked; disable shadow-casting on cone helper mesh (uses shaders/flashlight_cone.gdshader).

## bench
- Dimensions: 1.8 x 0.55 x 0.85 m (h), seat h 0.45 m.
- Pivot: floor center under seat.
- Polys: LOD0 ≤ 300, LOD1 ≤ 110.
- Collision: box 1.8 x 0.55 x 0.9 (blocks walk, allows stand-on via one-way? no — solid box).
- Materials: M_base (wood_512 slats), M_metal (frame).
- Mobile: merge slats into one board strip geometry, skip underside faces.

## dumpster
- Dimensions: 1.6 x 0.9 x 1.25 m; lid adds 0.1 m open arc 60°.
- Pivot: floor center-bottom of body.
- Polys: LOD0 ≤ 420 (body chamfered box + lid + 4 wheels low), LOD1 ≤ 140.
- Collision: box 1.6 x 0.9 x 1.25 + thin box lid (dynamic when searched) or static closed.
- Materials: M_base (metal_rust_512), M_accent (lid edge stripe ember).
- Mobile: lid as separate 40-tri mesh only if search interaction needs animation.

## power_box
- Dimensions: 0.8 x 0.4 x 1.2 m wall-mounted cabinet (or pad-mounted 0.9 x 0.6 x 1.3).
- Pivot: back-center (wall) / floor-center (pad variant).
- Polys: LOD0 ≤ 260, LOD1 ≤ 90.
- Collision: box matching dims.
- Materials: M_metal, M_accent (hazard chevrons decal-free, use gas_station hazard band style), small teal status LED emissive quad.
- Mobile: LED is unshaded 4-tri quad, pulse via material param not script.

## generator
- Dimensions: 1.1 x 0.7 x 0.9 m incl. exhaust pipe h +0.35 m.
- Pivot: floor center.
- Polys: LOD0 ≤ 460 (skid frame, alternator cylinder, radiator grille slats merged), LOD1 ≤ 150.
- Collision: box 1.1 x 0.7 x 0.9.
- Materials: M_metal, M_accent (fuel cap brass), M_base (rubber feet dark).
- Mobile: grille slats = normal-mapped flat plane, not geometry.

## fuse_box
- Dimensions: 0.35 x 0.18 x 0.5 m interior wall unit, door swing 100°.
- Pivot: hinge edge center-left (door separate pivot same rule).
- Polys: LOD0 ≤ 180, LOD1 ≤ 70.
- Collision: none when closed (wall flush); interact raycast only.
- Materials: M_metal interior bone-colored panel `M_base` with breaker switches accent.
- Mobile: door animation = single rotation tween, no physics.

## door
- Dimensions: leaf 0.95 x 0.05 x 2.1 m; frame add 0.06 m jambs, 0.05 head.
- Pivot: hinge edge (x=0 at hinge face), y=0 floor; opens ±100°.
- Polys: LOD0 ≤ 240 (leaf + inset panels), LOD1 ≤ 80; frame ≤ 120 static separate mesh.
- Collision: leaf box rotated by door node; frame two side boxes + head box.
- Materials: M_base (wood_512 interiors / metal_rust industrial), M_accent (handle brass, kicker plate steel).
- Mobile: bake frame+leaf into one scene; occluder hint on leaf.

## cabinet
- Dimensions: 0.9 x 0.5 x 1.8 m (medical/storage tall), counter variant 1.2 x 0.6 x 0.9.
- Pivot: floor center-back.
- Polys: LOD0 ≤ 380 (carcass + 2 doors + handles), LOD1 ≤ 130.
- Collision: box carcass; doors no collision (interior loot access).
- Materials: M_base (tile_white_512 hospital variant), M_accent (cross medkit ember decal quad, brass handles).
- Mobile: doors share leaf geometry mirrored; contents shown as UI, not physical props.
