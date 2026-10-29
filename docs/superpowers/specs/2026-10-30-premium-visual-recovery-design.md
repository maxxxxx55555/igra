# Premium Visual Recovery Design

Date: 2026-10-30
Branch: `qoder/premium-visual-recovery`
Source: owner-supplied `the-last-streetlight-3d-first-person-mega-prompt-en (3).pdf`, including its fixed reference decisions and inventory blueprint.

## Objective

Replace the rejected block-plaza and mostly empty inventory presentation with a coherent, detailed, worn-industrial visual style across the running game. Deliver actual geometry, materials, lighting, UI composition, and captures—not a post-processing-only approximation. Preserve first-person gameplay, content, progression, input, saves, power stages, collisions, navigation, and existing item operations.

## Fixed visual language

- Weathered urban night with readable cool shadows and localized warm fixtures.
- Old masonry, cracked concrete, oxidized metal, damaged asphalt, worn wood, rubber, and glass with distinct material response.
- Real facade depth, credible human-scale props, restrained wetness, selective lit windows, and fog that separates depth rather than hiding geometry.
- Opaque near-black UI surfaces, thin aged-brass borders, rectangular controls, amber accents, warm bone text, subtle edge wear, and no heavy grain, neon, glassmorphism, or oversized cut-corner pills.
- References define appearance only. Their top-down cameras, annotations, non-English labels, and depicted but unsupported features are not imported.

## Implementation strategy

Use the existing shared generators and UI components. Reuse current PBR sets, `PartMesh`, `PropMeshes`, `HidingMeshes`, item icons, themes, and seeded placement systems before authoring replacements. No external asset pack is required for this pass.

A parameter-only polish is rejected because it leaves the primitive silhouettes intact. A wholesale external-asset replacement is rejected because it introduces unnecessary integration, licensing, style-consistency, and mobile-performance risk.

## World architecture

### Shared construction surfaces

- `scripts/world/skyline.gd`: retain block envelopes, district palettes, signs, window power behavior, and perimeter collision. Replace box-only facades with batched modular shells containing recessed openings, jambs, sills, lintels, base courses, cornices, downpipes, and controlled roofline variation. Use a small coherent module family per district rather than randomizing every element.
- `scripts/world/street_builder.gd`: retain road transforms, ground heights, footstep metadata, and collision strips. Replace the clean oversized visual grid with finer damaged road and sidewalk modules, separate curbs, irregular joints, broken edges, and localized wet patches.
- `scripts/world/street_props.gd` and the shared streetlight mesh: replace the angular pole, arm, housing, and untextured batch material with a slender weathered fixture while preserving light origins, batching, stage response, and flicker behavior.
- `scripts/world/district_dressing.gd`: extend deterministic curated kits with rubble, damaged vehicles, furniture, railings, boards, service equipment, cables, and restrained vegetation. Reuse existing solid/scatter placement metadata and route-clearance rules. Fill foreground, middle distance, and skyline deliberately; do not scatter props onto navigation or interaction points.
- `scripts/world_env_setup.gd`, existing lamp lights, and existing light-pool cards: reduce broad pale illumination, retain cool navigable fill, and localize warm light around credible fixtures. Do not add constant emissive decoration that ignores district power.

### District identity

All eleven districts receive the shared reconstruction. Existing themes and landmarks determine the module mix: domestic facades and small gardens for suburbs/residential; paths and vegetation for park; institutional details for school/hospital/police; forecourt/service props for gas_station; loading and metal systems for warehouses/industrial; electrical infrastructure for substation/power_station. Gameplay layouts and progression remain unchanged.

### Performance and fallback

Batch repeated geometry, reuse materials, and preserve existing quality tiers. Higher tiers receive additional close-range detail and dressing; lower tiers reduce decorative density without removing route readability or required landmarks. Stay within the project budgets: fewer than 200 draw calls in D1 and 350 in D11, fewer than 50K polygons per district, no more than eight concurrent dynamic lights, and existing VRAM limits. Measure before optimizing; do not meet budgets by removing required visual content silently.

## UI architecture

### Inventory

Refactor the live `scripts/ui/inventory_ui.gd`; do not revive the archived `inventory_panel.tscn` implementation.

- Use a responsive three-column composition: equipment left, item area center, persistent inspector right.
- Keep real weight, capacity, equipment, items, selection, quick slots, filters, and actions. Never add filler items or fabricate gear.
- At the twelve-slot reference capacity, show a stable four-column by three-row grid with large cells and intentional empty states. Expanded inventories use bounded scrolling or paging without losing original inventory indices.
- Move sorting and supported filtering into one compact toolbar. Remove the active full-width pill/cut-corner toolbar family.
- Preserve use, equip, drop, sorting, quick-slot assignment, drag/drop, disabled reasons, and selection restoration.
- On narrow layouts, move the inspector into a deliberate secondary view before reducing readable text sizes or touch targets.

### Shared screens and HUD

- Update `ThemeProvider` and shared layouts first so reachable screens inherit the same tokens, typography, borders, spacing, states, and readable opaque backing.
- Recompose the HUD into compact status, quick-slot, one-objective, reticle, and contextual-prompt groups. Restyle existing notification queues so tutorial, reward, level, and interaction messages do not compete for one location.
- Apply the same component language to the live main menu, wide map, settings, crafting, quests, trade, skills, saves where reachable, documents, bestiary, achievements, progression, death, pause, loading, tutorial, dialogue, and credits.
- Retain real data, localization, remapped controls, safe areas, accessibility settings, touch behavior, and reduced-motion paths. Do not wire archived or unreachable screens merely to increase the changed-file count.

## Data flow and compatibility

Visual builders consume existing district IDs, deterministic seeds, themes, weather, and power stages. UI components continue to consume `InventoryManager`, `ItemDatabase`, quest, player, and settings state through their current APIs. No save-format, economy, balance, navigation, enemy, or progression schema changes are included. New decoration remains visual-only unless an existing interactive prop already supplies collision and state.

## Failure handling

Missing optional textures or decorative meshes use the project's existing material/fallback path and must not prevent district loading. Required gameplay resources are not replaced by silent placeholders. A capture or runtime check that exposes stale imports, missing bindings, blocked routes, unreadable UI, or regression returns the work to the relevant implementation phase; it is not waived by passing static checks.

## Delivery order

1. Capture the current inventory and representative street from the exact candidate revision; record viewport, scene/seed, camera, quality, and save fixture.
2. Replace the inventory composition and one representative street's facades, surfaces, lamp, dressing, and lighting.
3. Inspect live captures beside the selected plates and correct visible mismatches, including oblique geometry and movement.
4. Propagate shared world modules and UI components to every reachable district and screen.
5. Run interaction, traversal, inventory, power, save/reload, responsive-layout, performance, static, scene, and packaged-build checks supported by the environment.
6. Commit and push only to `qoder/premium-visual-recovery`; leave `main` untouched.

## Acceptance evidence

- Running inventory at 1280×720 with the real sparse item count, plus empty, filtered-empty, near-capacity, and disabled-action states.
- The supplied street/lamp viewpoint plus close and oblique facade, road, curb, lamp, and electrical-equipment views.
- Representative captures of every district and every changed screen at 1280×720 and 1920×1080; actual mobile/touch checks remain required where supported.
- A live traversal with one real power interaction and verification of objective, sound, indicator, and environmental light response.
- Functional journey covering menu, new/continue, movement, pickup/use, inventory, map/journal, settings, pause/resume, save, reload, and affected combat/death paths.
- Relevant repository gates, measured frame behavior, and a packaged launch when the local toolchain permits it.
- Evidence identifies revision, viewport, scene/seed, camera, graphics profile, fixture, and output paths. Untested targets are reported as unverified, never as ready.
