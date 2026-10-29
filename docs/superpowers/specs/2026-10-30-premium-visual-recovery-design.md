# Premium Visual Recovery Design

Date: 2026-10-30
Branch: `qoder/premium-visual-recovery`
Source: owner-supplied `the-last-streetlight-3d-first-person-mega-prompt-en (3).pdf`, including its fixed reference decisions and inventory blueprint.

Precedence: the owner-supplied brief supersedes earlier visual-only prompts and conflicting chamfered UI direction. The Production Bible remains authoritative for gameplay, power-stage behavior, audio, and performance unless this design explicitly states otherwise.

## Objective

Replace the rejected block-plaza and mostly empty inventory presentation with a coherent, detailed, worn-industrial visual style across the running game, designed and verified mobile-first for landscape Android phones and scalable to desktop. Deliver actual geometry, materials, lighting, UI composition, and captures—not a post-processing-only approximation. Preserve first-person gameplay, content, progression, input, saves, power stages, collisions, navigation, and existing item operations.

## Fixed visual language

- Weathered urban night with readable cool shadows and localized warm fixtures.
- Old masonry, cracked concrete, oxidized metal, damaged asphalt, worn wood, rubber, and glass with distinct material response.
- Real facade depth, credible human-scale props, restrained wetness, selective lit windows, and fog that separates depth rather than hiding geometry.
- Opaque near-black UI surfaces, thin aged-brass borders, rectangular controls, amber accents, warm bone text, subtle edge wear, and no heavy grain, neon, glassmorphism, or oversized cut-corner pills.
- References define appearance only. Their top-down cameras, annotations, non-English labels, and depicted but unsupported features are not imported.

## Implementation strategy

Use the existing shared generators and UI components. Reuse current PBR sets, `PartMesh`, `PropMeshes`, `HidingMeshes`, item icons, themes, and seeded placement systems before authoring replacements. No external asset pack is required for this pass.

A parameter-only polish is rejected because it leaves the primitive silhouettes intact. A wholesale external-asset replacement is rejected because it introduces unnecessary integration, licensing, style-consistency, and mobile-performance risk.

## Mobile-first release contract

- Android ARM64 landscape is the primary presentation target, with minimum SDK 29, target SDK 36, immersive mode, ETC2/ASTC textures, and the existing GL Compatibility renderer. Portrait gameplay is not an acceptance target; desktop remains resizable.
- Respect display cutouts and system insets for every full-screen UI and HUD control. Immersive presentation must not place essential information or touch actions under a notch, rounded corner, or gesture area.
- Design phone layouts from available logical space rather than uniformly shrinking desktop UI. The 1280×720 reference composition is the landscape hierarchy, not permission to produce microscopic text or controls.
- Minimum body text is 16sp and supporting text 14sp at default text scale; section labels are approximately 18sp and titles 24–28sp. Larger accessibility text settings must reflow without clipping or hiding required actions.
- Every touch action has at least a 48dp target after all scaling; primary gameplay controls should be larger. Hover is never required. Existing drag/drop operations retain their touch-accessible selection/action path.
- Fresh mobile settings default to the Medium visual tier; existing user settings are not overwritten. Low/Medium prioritize stable frame pacing and readability, while High/Ultra add detail without changing routes, objectives, or gameplay visibility rules.
- Do not rely on SSAO, SSR, volumetric fog, or auto-exposure for the target look. Use authored geometry, conventional PBR, restrained local lights, depth fog, limited fog cards, and controlled transparency. Mobile Medium uses conservative MSAA, particles, shadows, and dynamic resolution.
- A physical Android device is required for final READY status. Desktop captures, synthetic touch tests, static checks, and a signed AAB alone do not prove phone visual quality or performance.

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

Batch repeated geometry, share materials, use mipmapped ASTC-compatible textures, and tier decorative density by distance and quality. Higher tiers receive additional close-range detail and dressing; lower tiers reduce small props, transparent effects, shadow cost, and render scale without removing route readability, critical silhouettes, or required landmarks.

The canonical limits are fewer than 200 draw calls in D1 and 350 in D11, fewer than 50K polygons per district, fewer than eight total concurrent dynamic lights, fewer than 500 concurrent particles, RAM below 800MB, and VRAM below 400MB. Prop textures target 512²; 1024² is reserved for important first-person surfaces and 2048² is exceptional hero usage only. Avoid unnecessary transparent overdraw and full-screen screen-texture copies on mobile.

Establish a repeatable phone route covering a dense dark district, a restored district, weather, combat, inventory, and map. On the recorded reference device, Medium must sustain the project's 30 FPS target with p95 frame time at or below 33.3ms after warm-up, without repeated visible stalls or thermal collapse during a 30-minute soak. High/Ultra are optional quality tiers and do not relax the Medium release gate. Record device, SoC, OS, resolution, tier, render scale, and revision with every result.

Measure before optimizing. If a required art feature exceeds budget, replace its implementation with cheaper geometry, materials, batching, or tiered density; do not silently delete the required visual content, obstruct gameplay, or claim an unmeasured target as met.

## UI architecture

### Inventory

Refactor the live `scripts/ui/inventory_ui.gd`; do not revive the archived `inventory_panel.tscn` implementation.

- On wide layouts, use a responsive three-column composition: equipment left, item area center, persistent inspector right. Phone reflow follows the rule below.
- Keep real weight, capacity, equipment, items, selection, quick slots, filters, and actions. Never add filler items or fabricate gear.
- At the twelve-slot reference capacity, show a stable four-column by three-row grid with large cells and intentional empty states. Expanded inventories use bounded scrolling or paging without losing original inventory indices.
- Move sorting and supported filtering into one compact toolbar. Remove the active full-width pill/cut-corner toolbar family.
- Preserve use, equip, drop, sorting, quick-slot assignment, drag/drop, disabled reasons, and selection restoration.
- On phone-width or enlarged-text layouts, keep equipment and the real item grid on the primary view and open the inspector as a deliberate full-height secondary view with a clear Back action. Never shrink text or touch targets below the mobile contract to preserve three simultaneous columns.

### Shared screens and HUD

- Update `ThemeProvider` and shared layouts first so reachable screens inherit the same tokens, typography, borders, spacing, states, and readable opaque backing.
- Recompose the HUD into compact status, quick-slot, one-objective, reticle, and contextual-prompt groups. Preserve the existing joystick, action cluster, one-handed option, and button scaling while adding cutout-safe placement and uncluttered notification priority.
- Apply the same component language to the live main menu, wide map, settings, crafting, quests, trade, skills, saves where reachable, documents, bestiary, achievements, progression, death, pause, loading, tutorial, dialogue, and credits. The map becomes a wide safe-area-fitted view with legible markers and touch-sized actions, not a scaled-down fixed 720×560 panel.
- Retain real data, localization, remapped controls, accessibility settings, touch behavior, and reduced-motion paths. Do not wire archived or unreachable screens merely to increase the changed-file count.

## Data flow and compatibility

Visual builders consume existing district IDs, deterministic seeds, themes, weather, and power stages. UI components continue to consume `InventoryManager`, `ItemDatabase`, quest, player, and settings state through their current APIs. No save-format, economy, balance, navigation, enemy, or progression schema changes are included. New decoration remains visual-only unless an existing interactive prop already supplies collision and state.

## Failure handling

Missing optional textures or decorative meshes use the project's existing material/fallback path and must not prevent district loading. Required gameplay resources are not replaced by silent placeholders. A capture or runtime check that exposes stale imports, missing bindings, blocked routes, unreadable UI, or regression returns the work to the relevant implementation phase; it is not waived by passing static checks.

## Delivery order

1. Capture the current inventory and representative street from the exact candidate revision; record viewport, scene/seed, camera, quality, and isolated save fixture. Establish the phone reference device and baseline Medium performance route.
2. Replace the inventory composition and one representative street's facades, surfaces, lamp, dressing, and lighting. Preserve all real operations and interactions.
3. Inspect live desktop and phone captures beside the selected plates. Correct visible mismatches, including oblique geometry, movement, cutouts, touch targets, text scaling, and phone frame pacing before propagation.
4. Propagate shared world modules and UI components to every reachable district and screen. Maintain a keep/adapt/replace inventory so no active legacy prototype style remains hidden behind the first two polished views.
5. Run the complete visual and functional matrix, phone performance and thermal route, static/scene gates, and packaged Android build/install/launch on the same candidate revision.
6. Commit and push only to `qoder/premium-visual-recovery`; leave `main` untouched. Do not merge, claim release readiness, or substitute a numerical self-rating for visual evidence.

## Acceptance evidence

- Running inventory at 1280×720 with the real sparse item count, plus empty, filtered-empty, near-capacity, and disabled-action states. Repeat on the phone at default and largest supported text scale, including inspector navigation and touch actions.
- The supplied street/lamp viewpoint plus close and oblique facade, road, curb, lamp, and electrical-equipment views. The angular lamp, smooth block facades, flat painted windows, oversized clean paving, broad pale light pool, and heavy grain must no longer define the active frame.
- Representative captures of all eleven districts in applicable dark/restored states and every changed reachable screen at 1280×720 and 1920×1080, plus actual landscape phone screenshots at the device-native resolution and render scale.
- Phone cutout/safe-area, touch-target, one-handed HUD, text-scale, localization, map, inventory, and menu checks with no clipped required content, unreadable text, hover-only action, or gesture-zone conflict.
- A live traversal with one real power interaction and verification of objective, sound, indicator, and environmental light response. Check clipping, pop-in, shimmer, light transitions, animation, HUD overlap, and stable frame pacing in motion.
- Functional journey covering menu, new/continue, movement, pickup/use, inventory, map/journal, settings, pause/resume, save, reload, and affected combat/death paths on desktop and the reference phone.
- Relevant repository gates and a packaged Android AAB installed and launched on the physical reference device, with logcat checked for missing resources and runtime errors.
- Phone Medium performance evidence for the repeatable route and 30-minute soak: frame-time percentiles, stalls, thermal behavior, memory, draw calls, geometry, lights, particles, and visual settings against the stated budgets.
- Evidence identifies revision, viewport, scene/seed, camera, graphics profile, fixture, device, and output paths. Every claim links to an actual capture, log, or measurement.

READY requires every applicable gate above on one final candidate with no known release-blocking visual or functional defect. Missing physical-device evidence, missing required art, any unreviewed active district/screen, or an unmet mobile budget produces BLOCKED or INCOMPLETE with the exact remaining item; it never produces a readiness claim.
