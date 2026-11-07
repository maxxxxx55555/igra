# LAST STREETLIGHT — FINAL RECOVERY AND RELEASE IMPLEMENTATION PROMPT
Revision: 7 November 2026. Remote main was rechecked and remains at the audited revision below. Repository: https://github.com/maxxxxx55555/igra

Execute this entire document as one implementation task. It replaces earlier mega-prompts and continuations. Keep the previously supplied ZIP/reference artwork as evidence and visual references, not as a competing instruction set. Continue existing work; do not restart the project, regenerate accepted assets, write another prompt, or treat a workflow-script run as completion of the game.

The requested outcome is the implemented, tested game and its source integrated into main through the repository’s normal checks. This document is not evidence that those actions have already occurred.

## Execution with the supplied PowerShell workflow

Read START_HERE.md and the adjacent Igra-Release-Workflow.ps1 before execution. The workflow prepares a separate integration worktree, preserves recoverable local changes, runs supported checks, exports an explicit candidate and can push a tested integration branch. It does not generate all production game assets, implement this brief automatically, prove device quality or merge main by itself. You, the implementing coding agent, must perform those game changes and finish the checked PR integration.

Use only the script modes and parameters actually present in its comment-based help. Preserve the run-state directory printed by Prepare. Recover valuable local changes from its backups into the candidate deliberately; patches are not applied blindly. Complete and commit game changes before verification. Resolve failing checks, inspect actual output and keep evidence tied to source. Publish is an explicit push of the tested integration branch, not a declaration of release readiness.

The supporting reference references/FPP_REPAIR_CONCEPT.png illustrates close-range electrical equipment, material depth and local night illumination. It is newly generated concept art, not a game capture, PBR texture set, mesh, gameplay evidence or replacement for the accepted menu master. Convert its relevant design intent into actual assets using available suitable tools; do not paste it over the 3D scene. Use the available image-generation tools when appropriate, without claiming an unavailable model/version or generating every asset again.

## 1. Binding owner decisions

- Fully 3D, first-person gameplay. Preserve the current first-person camera and functioning mechanics.
- Permanent night. Unpowered exploration must feel very dark; the player navigates using limited light, sound and remembered landmarks. Restoring power creates convincing warm pools of light.
- World art follows the supplied realistic narrow street: decayed masonry/plaster, recessed openings, external metalwork, wet damaged pavement, cool atmospheric depth and a warm streetlamp. This quality must exist in the playable 3D scene.
- Preserve assets and screens that already match. Keep the matching main-menu street artwork. Improve deficient geometry, materials and composition instead of indiscriminately replacing everything.
- One architectural map, no radar/minimap. Reveal only static geography personally observed under persistent world lighting restored or deliberately activated through the player’s power progression. Flashlight use, walking and waiting do not survey the map.
- Only charted streets, paths, actual building edges, observed entrances and legitimately learned place names may appear. Never show enemies, NPCs, items, loot, quests, generators/lamps, radio pings, routes, pins, safe/danger zones or a player-tracking arrow. Items are found in the world.
- Previously charted static geography remains dim memory; unknown areas remain concealed. A power outage must not add geography.
- Every actual gameplay action has a working, discoverable input route and an appropriate visible touch control. Existing gesture shortcuts may remain.
- Exactly two languages: English and Russian, internally en and ru. Every player-facing string must work in both.
- Preserve useful local and branch work. Recover interrupted changes before updating the owner’s checkout.
- Use a small coordinated agent team and relevant available skills. Work toward completion within the remaining five-hour allowance, with reserved verification time.
- READY means demonstrated release readiness. A build, generated picture, screenshot of an agent report or green source check cannot substitute for actual functionality, visual acceptance or device verification.

These latest owner requirements supersede conflicting older owner prompts and stale project canon. Apply repository contracts where they do not conflict with this explicit scope, and respect higher-priority environment/tool restrictions. Reconcile the relevant project specifications once; do not maintain contradictory versions.

## 2. Current audit: what is already on main and what remains

A read-only source and image audit on 6 November 2026 inspected remote main at **1c185dc913d16bea1a70be74c93e466763e6129d**. Refresh before editing. This audit did not run a new complete playthrough, install an Android package, listen to the soundtrack or inspect the owner’s Windows working tree.

**Stage: implemented game in visual recovery and release hardening. Current release records explicitly say NOT READY.**

| Area | Evidence at the audited revision | Action |
|---|---|---|
| Branch integration | fix/lit-pool-stealth, ui/screen-art-backdrops, feat/restored-light-map, feat/dark-and-controls, ui/hud-composition, art/monster-hide and docs/owner-rules-listing are ancestors of main. gh-pages remains separate. | Preserve these merged changes. Do not merge them again or repeat the old “UI branch is unmerged” claim. |
| First-person camera | The main scene uses a perspective Camera3D and first-person mode. | Preserve; no camera conversion is needed. |
| Map foundation | scripts/systems/cartography.gd and scripts/ui/district_map.gd replace the visible radar with remembered geography. Powered non-force-on streetlights, camera frustum/range and lamp-to-ground plus eye-to-ground rays gate discovery. Flashlight does not survey. | Keep this implementation and close its actual fidelity, visibility and test gaps. Do not recreate enemy radar or start an unrelated map system. |
| Map save data | Save/slots persist cartography; New Game resets it; incompatible layout revision clears map memory. | Verify actual save/reload/travel, not only injected dictionaries. Preserve all other save data during migration. |
| Map fidelity | The drawing uses 2 m cells; building-edge classification currently relies on the outer building ring. | Verify against each actual district. Extend from real layout data for entrances, interior structures and changed geometry rather than drawing fabricated detail. |
| Darkness | Unpowered windows/lamps and facade gain have real changes. The new fog-stage values appear in a grader whose Environment path is not supplied, while the live environment owner does not apply them. | Trace the live WorldEnvironment and fix the actual consumer; confirm rendered results on each tier. A constant in dead code is not a completed lighting fix. |
| Enemy visibility | Reticle/bar/auto-aim partly use is_perceptible(). Its lit-pool branch relies on a coarse radial LightGrid. Floating damage numbers do not check actual visibility. | Close instance-specific illumination/occlusion leaks, including feedback that remains visible after the target disappears. |
| Controls | Reload, melee, UV, strobe, dodge, inventory, workbench, jump and other touch actions now exist. | Preserve them. Real simultaneous touch delivery, hold/release behavior, physical sizes and layout remain unverified. |
| Visuals | New monster hide material, larger skill cards and HUD/menu changes are merged. Current recorded frames still show simple angular creatures, repetitive facades, conspicuous primitive props and large low-density panels. | Material changes do not complete model production or screen composition. Finish the visible deficiencies while retaining improvements. |
| Sound | Session 39i records interaction sounds as wired. Older rows saying every door/generator interaction is silent are stale. | Inspect current callers and exported audio, listen to actual sequences, and close remaining real gaps. Music provenance/sign-in work remains documented as blocked. |
| Languages | en.json and ru.json and the two-language policy are present. | Keep exactly these languages; verify every screen, message and fallback. |
| Builds | Latest inspected Session 39k records a version-code-17 AAB from 439e9ae2, Windows boot checks and NOT READY status. | These historical builds do not certify this new task. Export and test the final changed revision. |

Useful trace points, to re-resolve after updates:
- Map: cartography.gd:35–94,107–143; district_map.gd:105–128; save_system.gd cartography serialization.
- Live fog (single owner since the fix): scripts/world_env_setup.gd:32,127-152; scripts/world/district_grading.gd:1-52 (ground-only now); scripts/world/world_bootstrap.gd:45-50; assets/env/night_environment_desktop.tres and mobile equivalent.
- Visibility: scripts/enemies/base_monster.gd:422-440; scripts/lighting/light_grid.gd:114-139; scripts/ui/hud_3d.gd:575,1139-1142; scripts/weapons/weapon_base.gd:189-200.
- Existing map tests: scripts/tools/rc16/hud_checks.gd:114–143. These cover empty/injected data cases; they do not establish the full restored-light positive path.
- Current decisions/build records: docs/PRODUCTION_BIBLE.md opening owner-rules section, docs/KNOWN_ISSUES.md latest sessions, docs/RELEASE_ARTIFACTS.md latest section.

Eight stored frames at the inspected revision are 1920×1055 desktop/keyboard captures. The audit viewed the current DARK, boss and skill frames; these are repository-recorded captures, not a new live session. They cannot establish physical touch size, multitouch delivery or Android performance.

## 3. Recover the interrupted Claude work before doing anything destructive

The owner supplied an interrupted Claude report saying it was applying a branded splash, duplicate-grain removal, Low-tier rain removal and INTERNET-permission cleanup, followed by mobile accessibility recommendations. The screenshots show a **weekly usage limit** and a terminated background task. “Applying” does not prove files were changed, committed, pushed, merged or exported.

On the owner’s machine, inspect the actual project at C:/Users/Maxsim/Desktop/TLS_Build, or resolve its moved location. Our remote audit could not see that working tree.

1. Record repository root, current branch/HEAD, status, staged/unstaged changes, local branches, worktrees, stashes and relevant recent reflog entries. Inspect the existing continuation notes and the interrupted agents’ scoped worktrees.
2. Preserve recoverable local commits, staged/unstaged binary-safe diffs and intended untracked source/assets outside the checkout before updating it. Inspect filenames first; do not print credentials, signing files or secrets. A git bundle alone does not preserve uncommitted files.
3. Inspect unfinished file contents for syntax damage and partially applied edits. Compare local, remote and merged main behavior. Classify each reported action as PLANNED, LOCAL_MODIFIED, LOCAL_COMMITTED, PUSHED, MERGED, EXPORTED or VERIFIED.
4. Recover valuable changes into an isolated integration worktree. Do not reset, clean, blindly stash-pop, force-checkout or overwrite the owner’s dirty work. Do not commit generated caches or secret files as “backup.”
5. Record the baseline and selected recovery changes; then run appropriate parse/import and smoke checks. Distinguish pre-existing failures from introduced ones.

The following are **not present or not completed in audited remote main** and may exist only locally: branded engine splash, deduplicated grain, suppression of the active weather overlay on Low, the proposed enlarged mobile defaults, complete dynamic safe-area layout and the proposed contrast corrections. Recover them if valid; implement them if absent; do not double-apply them.

Current named feature branches are already merged. Review any newly discovered unique commits semantically before integrating. Keep gh-pages separate. Historical qoder tip 352240aa66f7667b1ebc8a36b52b16342689ef6e may contain useful composition/material intent, but it predates newer implementations; port only demonstrated useful compatible changes. No branch deletion, force push, history replacement or blanket conflict resolution is authorized.

## 4. Team, skills, scope and resource budget

Use one lead and at most three concurrent workers, each with a narrow task and minimal necessary context:
- World/art: live lighting, architecture/materials, production models, first-person assets and VFX.
- UI/mobile: theme/layout, touch routing, density/safe areas, accessibility and EN/RU.
- Gameplay/map/audio: cartography/visibility correctness, save/progression and audio integration.
- Lead: recovery, file ownership/contracts, integration, validation and packaging.

Assign shared files to exactly one writer. Agree light/visibility APIs, layout coordinates, map schema, InputMap actions, theme tokens and save contracts before parallel edits. Preserve existing active agent ownership; use separate worktrees where necessary. Reuse workers for a final independent review instead of launching a second large council.

Read current CLAUDE.md, applicable AGENTS.md, AGENT_ZONES, production canon and relevant skill instructions. Use installed game-art direction, design/accessibility review, Godot/style, asset, audio, testing and release skills where applicable. Verify availability; never claim a missing skill was invoked. Follow the existing specification workflow for feature-sized changes, proportionately. Do not enable quarantined tools or install ambiguous packages just to satisfy a skill list.

| Elapsed time in an available five-hour window | Required outcome |
|---|---|
| 0–20 min | Recover local work; refresh refs and tools; pin a safe baseline. |
| 20–40 min | Confirm blockers, trace live consumers, agree contracts and ownership, start targeted checks. |
| 40–170 min | Implement highest-impact mobile, visibility/map, lighting and production-art fixes in parallel. Capture early results. |
| 170–215 min | Propagate correct shared solutions across remaining districts/screens; close audio/progression gaps. |
| 215–270 min | Freeze scope, run integrated checks, actual visual/input/audio review and available device tests; fix failures. |
| 270–300 min | Final package, provenance/version checks, checked integration/push and precise handoff. |

Use actual remaining allowance if the window has already started; receiving this prompt does not reset it. Reserve roughly 28% for verification and delivery. Finish earlier if possible. Checkpoint completed work before starting another long operation. Never leave all source uncommitted until the final export.

A weekly limit is separate from a five-hour session limit. The screenshot’s weekly exhaustion cannot be resolved by rewriting this prompt or waiting for a session reset alone. If access is blocked, preserve recoverable state and stop launching doomed workers. Do not claim quota bypass, invent remaining tokens, change accounts, or enable paid usage without explicit authorization.

Keep one compact state record: current SHA, requirements, ownership, completed evidence, remaining failures and next action. Reports should contain changed files, outcomes and blockers, not repeated reasoning. Batch independent reads, cap logs, reuse established context and run only affected checks during development. Run the full suite on the frozen integration candidate; repeat affected gates after corrections. Two identical failures without a changed hypothesis require diagnosis, not a third blind retry. Do not run competing GPU benchmarks simultaneously.

Do not reduce mandatory scope or label unfinished art “post-release” to fit the budget. If time, quota, assets or hardware block completion, deliver the strongest tested recoverable candidate and exact blockers with NOT READY status.

## 5. Mobile implementation: treat the quoted audit as evidence to verify

### 5.1 Correct the unit model before choosing defaults

The quoted 400-ppi arithmetic is an estimate, not a measurement of the owner’s device. CSS pixels, Godot logical units, Android dp/sp and physical pixels are different units.

For Android, target at least 48×48 dp effective hit areas for ordinary controls, with larger movement/fire controls and adequate separation. Android density comes from the actual platform configuration, not an assumed physical 400 ppi. WCAG 2.5.5 uses 44×44 CSS pixels at AAA; WCAG 2.5.8 has a 24×24 CSS-pixel AA criterion with exceptions. Neither is a direct conversion rule for a Godot viewport.

Measure each interactive rectangle through the real viewport/canvas/window transform to device pixels and then the actual Android density. Account for stretch mode, content_scale_factor, UI scaling, safe areas and user text preference without applying a scale twice. Keep hit areas consistent with input coordinate conversion. Use an explicit calibrated fallback if reliable density is unavailable; do not report dp/sp or millimetres as measured when they are not.

Godot content_scale_factor is an additional stretch factor, not a guarantee that one authored pixel equals that many device pixels under every stretch configuration. Verify the actual renderer/settings. Font sizes need their own readable scaling and glyph coverage; a universal “16 Godot px” floor alone does not guarantee 16 sp.

Candidate values from the interrupted audit—touch scale around 1.5, button setting 1.25, logical touch floor 80—are starting experiments. Accept them only after measuring final rectangles, text and overlaps across supported screens. Do not blindly force a 1600×720 layout or change desktop preferences.

### 5.2 Concrete current source gaps and required fixes

| Finding at audited main | Required implementation |
|---|---|
| settings_manager defaults button_size=1.0 and text scales [0.9,1.0,1.15]; the largest touch default applies to the whole window. | Separate or coordinate control/text scaling deliberately. Design responsive layouts before increasing scale. Migrate old defaults without repeatedly overwriting explicit user choices. |
| UiScale.MIN_TOUCH=48; side buttons are 64×64; authored Pause is 36×36. Scaling affects only two lower clusters and its floor assumes 72 while some controls are 64. | Establish one effective-target sizing policy covering all controls. Apply it to dynamically created buttons, map actions, pause, quick slots, LOG, dialogs and menus. Correct denominator/transform assumptions. |
| quest_tracker_hud PANEL_TOP=252 and MAX_ROWS=1. | Reflow the one-objective panel into safe available space. Top=100 is a candidate now that radar is gone, not a universal hardcoded answer. |
| LOG and Map have independent positions near (16,290)/(96,290); log panel uses fixed minimum heights. | Place them in a shared responsive group. Size/cap scrolling content to usable space so it cannot cover joystick or important text. |
| AmmoCounter and Attack authored rectangles overlap. | Relocate ammo and reserve action-cluster space before scaling; test empty/full ammo and every weapon/UI scale. |
| Insets exist for some HUD corners but omit dynamic Map, LOG and objective overlays. | Use one safe-area layout calculation. Recompute idempotently on viewport/inset/scale changes; never add the same inset repeatedly. |
| HUD control rest opacity=.55; LOG=.45; some disabled text is faded further. | Provide stable readable backing and contrast. Candidate rest opacity=.8 must be judged after compositing over actual bright/dark scenes. |
| Locked skill cards modulate the entire card to .85; small labels remain 11–15 logical px in several paths. | Keep explanatory/requirement text readable; separate disabled decoration from text. Increase/reflow meaningful text using measured final size and EN/RU tests. |
| Dark-red text and quiet brass edges lose contrast in several surfaces. | Add semantic readable text/focus tokens rather than globally recoloring every red fill or decorative border. |

Candidate readable colors: danger text #E8695A, primary text #D8D5CC, essential control/focus edge #9E8645. Preserve #C0392B for suitable danger fills and #5A4A2A for nonessential decoration. Measure final composited text, not token pairs in isolation; parent modulate, opacity, outlines, background images and world content all affect it.

Use 4.5:1 as the normal-text design target, 3:1 only for genuinely large text under the applicable sizing definition, and 3:1 for essential control/focus information against adjacent colors. Do not claim full WCAG conformance from a few ratios. Locked-card explanations must remain readable even where an inactive-control exemption could apply. Prefer an opaque local text backing to excessive outlines; a 2 px outline is only a candidate and must survive scaling.

Review both languages on a compact phone, tall phone and tablet-like landscape viewport, at default and maximum supported text/control scales. Check menus, inventory, shop, skill cards, map controls, dialogue, subtitles, errors, confirmations and loading, not just the gameplay corner buttons.

### 5.3 Actual multitouch, not button-signal simulation

A major outstanding issue is that a normal HUD Button may not receive the intended second finger while the first holds the joystick. The current touch probe’s direct signal/headless injection cannot establish real platform input routing.

Use actual InputEventScreenTouch/ScreenDrag or a suitable native Godot touch-control path with explicit pointer ownership. If adapting controls, preserve keyboard/controller focus and normal mouse behavior. Avoid double events from simultaneous native touch and emulated mouse handling.

Test:
- Move + look + continuous fire, then release each finger in a different order.
- Reload/use while moving; melee, dodge, jump, crouch and sprint hold/toggle behavior.
- Flashlight, UV and strobe switching; quick wheel and supported quick-item use.
- Opening/closing inventory, map, workbench and pause while fingers are down.
- Finger leaving its control, canceled events, app background/resume, lost focus and viewport changes.
- No stuck actions, missed release, duplicate activation, camera drag through menus or firing after modal closure.

Build the action matrix from actual InputMap/controllers/UI callbacks. Current code has no established separate ADS action in the inspected paths; preserve aiming through camera/look and do not invent a nonfunctional Aim button. If a real aiming/zoom mechanic exists elsewhere, expose it correctly. Every genuine action needs a working route, but decorative controls must not imply nonexistent mechanics.

### 5.4 Android splash, effects and permission cleanup

**Boot:** configure the actual supported engine boot-splash settings with branded licensed art, appropriate background/aspect handling, and a coherent following loading scene. An in-game loading title does not fix a blank engine/system launch interval. Verify cold start, resume, first import/load and failed-load behavior on Android. Do not guess setting names from an older engine version or add autoplay audio before the allowed first interaction.

**Grain:** both HUD and PostProcessOverlay currently instantiate grain layers. Consolidate ownership and remove duplicate runtime work/dependencies, keeping an intentionally restrained optional presentation and accessibility behavior. Both currently disable on Low; preserve that. Update a gate that wrongly requires two passes to assert the correct single-owner behavior; do not remove meaningful rendering checks.

**Rain:** RainLens is already Ultra-only, but UIManager’s active weather_overlay lacks a Low-tier guard. Fix the active path, including live tier changes. Low must have no rain screen overlay or invisible ticking/drawing cost from that overlay. Preserve the intended weather/gameplay state and appropriate audio; do not break weather globally.

**INTERNET:** export_presets.cfg still enables it. The release configuration has no enabled ad provider/key, Play Integrity is a stub and the LAN lobby is archived; however, networking code/autoloads exist. Inspect actual owner-side plugins, templates and release consumers before calling it unused. If the shipped offline product has no network dependency, remove the permission at its real source and inspect the generated manifest to confirm it is absent. Do not disable a working supported feature or assume a source flag overrides merged plugin permissions.

The JDK-17/Gradle-stop problem is already recorded fixed in Session 39k using the configured bundled JDK. Preserve the working toolchain, verify actual paths and stop using obsolete instructions. Do not reinstall or downgrade Java merely because an old log mentions 17.

## 6. Darkness and hidden-enemy information: finish the real implementation

Keep the actual DARK/PARTIAL/STREETS/FULL progression and permanent night. A restored street is a chain of warm pools and shadows, not daylight. The latest master image defines quality and local lighting; it does not justify globally bright unpowered streets.

Trace the live WorldEnvironment owner. The audited district_grading fog assignment appears inert because its environment path is not supplied; both active environment presets retain fog light energy .6. Fix the actual stage/tier update route, avoid competing environment writers, and verify runtime property values and rendered off/on comparisons.

In DARK, broad facades, distant roads and monsters recede into near-black with restrained silhouettes. No unexplained window emission, blue fog wall, player halo or global brightness lift. The flashlight exposes a limited coherent cone. Restored lamps add plausible warm light, surface response and subtle local haze. Tune material albedo, ambient/sky, fog, energy/falloff, exposure and tone mapping together. Do not conceal unfinished assets with a black overlay, heavy grain or crushed blacks.

Preserve range/cone/collision checks already added for flashlight exposure. Keep illumination, AI perception of the player and player visibility of an enemy distinct. LightGrid’s approximate 2D radial sum is insufficient by itself to prove a monster is visibly lit through walls.

Create or repair a shared instance-specific visibility predicate where needed: actual illumination, relevant occlusion, camera/frustum and eye line of sight. Use it consistently for reticle tint, enemy names/bars, auto-aim, damage numbers, hit feedback and other telemetry. Track the particular monster, not just its species label. Re-evaluate ongoing feedback when it moves behind cover or into darkness.

Damage numbers currently receive every enemy-damaged event and reject only behind-camera placement. Blind fire, damage-over-time and obscured targets must not expose hidden positions. Gate both creation and remaining display. Preserve legitimate audible events and non-locating player feedback.

Monsters remain physical and dangerous in darkness; do not hide them by disabling meshes/collision. Actual illumination must reveal them. Maintain fair sound cues, attack anticipation and collision. Accessibility settings may improve usability without revealing hidden geography or enemy locations.

## 7. Complete the existing architectural map without undoing it

Preserve Cartography and the new map entry point. The required reveal policy is already substantially implemented; repair fidelity and demonstrated defects rather than rewriting from scratch.

- Eligible discovery comes from player-restored persistent lighting and personal observation of illuminated surfaces. Always-on authored lights, flashlight/UV/strobe, enemies, muzzle flashes, walking, time, ambient sky and proximity do not survey.
- Powering a circuit triggers evaluation, not remote district reveal. A lit corner does not expose an entire footprint, hidden alley or floor plan.
- Charted static geography persists; unknown is opaque at every zoom. Keep saved map revision, district and any necessary seed/floor identity coherent with actual layout. New saves stay isolated.
- Map data and drawing never subscribe to live enemies, items, quests or player tracking. Prohibitions apply within revealed areas too. No settings, tooltips, filters, accessibility labels or alternative screen may restore forbidden tracking.
- Use the real street/building/entrance layout or a verified bake of it. Current ring classification must not invent buildings or omit actual interior structures after environment improvements. Architectural labels require genuinely learned identities and remain within discovered geography.
- Test full coordinate conversion, including actual scale/rotation/negative coordinates where used. Separate district-local coordinates from atlas indices. Preserve map pan/zoom/reset/close and block gameplay input beneath it.
- Verify light-limiter behavior: Cartography currently uses an on lamp’s glow extent even if a renderer budget hides that glow. Do not chart visibly unlit space outside the remaining spotlight. Keep the performance optimization while matching meaningful rendered illumination.
- Ensure bounded sampling eventually reaches every eligible cell. The current cell loop restarts for each pass; test that repeatedly blocked prefix cells cannot consume the whole budget forever and starve later visible cells. Add fair cursors/scheduling only if needed.
- Use spatially bounded queries, cached static geometry and dirty regions. Avoid per-frame whole-world scans. Revalidate source removal, stage/tier changes, unloading and save migration.

Preserve separate district travel and finale gates. Current travel eligibility follows power prerequisites, not necessarily physical visitation. Keep it a non-spatial progression list of legitimately unlocked/announced destinations; its availability must not reveal their architecture. Do not remove the route to another district when replacing map UI. No-return and all-district restoration rules remain functional.

Required runtime scenario: start uncharted; walk/wait/sweep flashlight; restore a lamp; observe a visible street; look away; test a wall and a second floor if supported; disable/re-enable the lamp; leave/save/reload/return; open another slot and New Game. Verify the expected limited reveal and persistence, with no forbidden markers. Existing tests of injected cells do not replace this positive path.

## 8. Production art: finish the world the player actually sees

### 8.1 Reference choices

WORLD_MASTER is the supplied narrow decaying city street with a warm lamp, cool mist and believable surfaces. The old primitive gameplay/empty-inventory screenshots are negative examples. The new screenshots of Claude’s limit/audit are workflow evidence, not art references.

Choose the original dense equipment/grid/details inventory board for inventory hierarchy; the physical-object icon sheet for items; the narrow menu list over the atmospheric street for menus; the compact status/interaction board for HUD; and the coherent journal/skills/settings family for system screens. Map boards supply palette/typography/frame treatment only—their marker legends and top-down gameplay camera are rejected.

Do not copy design-sheet numbers, engine/platform labels or every depicted feature. Keep current canonical branding and the matching menu artwork. If an essential image cannot be opened, work from the written brief but do not claim its visual comparison passed.

### 8.2 Architecture and assets

Build or finish a reusable urban kit with several compatible facade families: real recessed doors/windows, sills, cornices, foundation courses, gutters, drainpipes, fire escapes, cables and roof silhouettes. Preserve coherent real scale. Compose varied street widths, corners, alleys, courtyards and service approaches; replace repetitive pale block rings where they visibly fail the target.

Close-range geometry must hold up from first-person eye/hand distance. Add physical contact, sensible bevels and variation where the player sees it; reserve cheaper silhouettes for distance. Update collision, navigation, lighting, spawns, quests and map geometry with any layout change.

Replace conspicuous primitive props and creature/boss placeholders with technically suitable finished models. New hide texture on the same crude geometry is not completion. Preserve recognizable good assets, mechanical hitboxes and animation contracts. Finish supported first-person hands, held tools/weapons, grips, idle/equip/use/aim where present, fire/recoil, reload, swap and interruption. Prevent wall/body/camera clipping.

Use cause-based detail: damp under drains, wear near doors, rubble beside actual damage, cables connected to devices. Avoid random clutter, repeated stains, floating objects, giant paving seams, excessive shiny roughness or uniform yellow windows.

| Material family | Required response |
|---|---|
| Asphalt/roads | Human-scale aggregate, cracks, repairs, selective puddles and worn markings; controlled roughness and normal depth. |
| Pavement/curbs | Correct slab/joint scale, raised chipped curb geometry, drainage and localized dirt. |
| Brick/plaster/stone | Credible mortar, layered damage and material changes; several variants without identical stamped stains. |
| Concrete/industrial metal | Distinct surface response, seams, bolts, paint, restrained corrosion and electrical equipment detail. |
| Wood/glass | Grain direction and break edges; recessed dirty glass with justified interior light and cheap tier fallback where required. |
| Cloth/leather/rubber | Distinct roughness/scale on clothing, gloves, packs, hoses and tools; no universal plastic gloss. |
| Foliage/soil/debris | Rooted believable placement, varied silhouettes, restrained movement, optimized alpha and contact with ground. |
| Water/wetness | Local puddles/drainage and stable reflections, not a uniform mirror or excessive shimmer. |
| Creatures/hands/weapons | Close-view surface detail, appropriate skin/clothing response and readable silhouettes under real light. |

Deliver actual meshes, materials, animations, alpha-clean icons and imported resources with real runtime consumers and packaged presence. Use albedo/normal/roughness and other PBR channels only where appropriate, correct color spaces, UVs/mips/normal orientation and tier budgets. Do not bake a directional lamp highlight into reusable albedo or substitute a rendered photograph for geometry.

Keep effect scale and feedback restrained: source-local sparks, smoke/steam, impacts, dust and restoration events. Avoid full-screen noise/bloom/shake that obscures gameplay. Maintain flash/motion comfort options.

### 8.3 All eleven districts

Audit and finish the existing districts as a connected campaign:

| District | Identity to express within existing scope |
|---|---|
| Suburbs | First blackout, small homes/service alleys, close navigational landmarks and a clear first restoration. |
| Residential | Dense masonry fronts, entrances, courtyards and layered external metalwork. |
| Park | Tree masses, paths, benches, service/pavilion structures and deliberate isolated lighting. |
| School | Recognizable institutional entrance, yard/fencing and required routes/interiors. |
| Hospital | Emergency/service access, institutional materials and legible required interactions. |
| Gas station | Pumps, canopy, forecourt and service building with unobstructed gameplay routes. |
| Police | Secure frontage, barriers and gated entry/service spaces. |
| Warehouses | Loading bays, doors, pallets/racks and occluded approaches. |
| Industrial | Pipes, machinery, service structures and functional electrical connections. |
| Substation | Transformers, insulators, fences and believable repair equipment. |
| Power station | A distinct final destination, power infrastructure and coherent boss/ending staging. |

Do not add unrelated missions or make every decorative building enterable. For each district prove arrival, dark exploration, required resources/interactions, threat handling, restoration, exit and saved revisit. Use real environmental guidance, signage, sounds and journal descriptions instead of item/quest icons on the map.

Recheck the difficulty ramp, rifle availability, early shop usefulness, battery/ammunition/repair economy, blocked routes and recovery after mistakes. No required item may sit behind its own gate. Resource files and store pictures alone do not establish a playable city.

## 9. One finished UI family and complete EN/RU

Use a coherent charcoal/brass industrial family, with clear readable content and restrained wear.

| Token | Starting value and intent |
|---|---|
| Deep background / panel | #060F13 / #0F1314 |
| Decorative edge | #5A4A2A; not sufficient alone for essential focus/control boundaries |
| Brass / readable edge candidate | #C9A24A / #9E8645 |
| Primary / secondary text | #D8D5CC / #8A8A85 when final contrast passes |
| Danger fill / readable danger-text candidate | #C0392B / #E8695A |
| Existing stamina / information | #5F8A4E / #4A9AB5 |

Use licensed Bebas Neue for short headings, Roboto Condensed for body and Share Tech Mono for concise numbers, with actual Cyrillic coverage and sensible fallback. Preserve agreed semantics; do not scatter literal colors or invent a competing theme.

Use a consistent 4/8/12/16/24 spacing rhythm, modest chamfers, thin frames and clear hierarchy. No generic rounded app cards, shiny sci-fi panels, heavy grain behind text or mixed engine-default widgets. Default/hover/focus/pressed/selected/disabled/loading/error states belong to the same family.

**Inventory:** deliberately composed equipment region, real-capacity item grid, selected-item inspector and integrated quick-access/action footer. Around a 1280×720 design canvas, a bounded approximately 1120×640 panel and 20%/48%/32% content proportions are starting points, not fixed mobile coordinates. Adapt item cells/columns to actual capacity and screen. No fake items/capacity, tiny grid in one corner or giant unexplained empty overlay.

**HUD:** compact actual status, one concise objective, readable interaction/weapon/ammo feedback and uncluttered first-person sightline. Preserve the merged warmth/status composition while correcting readability and layout. Map access is a button, not radar. No hidden-enemy telemetry.

**Menu:** keep matching street artwork; improve text-list rhythm, contrast, focus and clear primary action without replacing it with a huge flat button stack. Existing daily content must fit the composition.

**Other screens:** inventory/equipment, map/travel, pause, settings, journal/notes, supported crafting/upgrades, skills, shop, bestiary, achievements/statistics, tutorials, dialogue/subtitles, notifications, save/load, confirmations/errors, loading, death and every actual ending. Include script-created and rare states. Improve large empty skill/shop layouts through real hierarchy and information density, not just a background image.

**Icons:** preserve strong existing item renders; complete all actual item/tool/weapon/ammo/equipment/status/control/menu categories. Consistent silhouette, framing, scale, lighting and alpha for item art; a clean unified symbol family for actions. No emoji, missing glyphs, generic placeholder squares, arbitrary mixed packs or baked-in counts/keys. Inspect at real UI sizes, including disabled/selected states.

**Two-language completion:** exactly EN/RU in selectors, initialization, persistence, export and first launch. Migrate an old unsupported language to the existing safe fallback without erasing other settings. Audit dynamic formats, plurals/numbers, binding hints, error strings, item descriptions, quests, endings and store text where applicable. Match translation placeholders and glyphs. Test long Russian strings and enlarged text; do not shrink text to conceal overflow or add back removed locales.

## 10. Audio, music and gameplay integrity

Keep the newly wired interaction cues, then verify real callers and export dependencies for footsteps by surface, flashlight/modes, weapons/equip/reload/empty, impacts, enemy movement/anticipation/attack/death, doors/cabinets, fuses/generator/workbench, pickup/repair/restoration, UI, dialogue/radio, ambience and endings.

Place sounds at actual successful/failed action moments. Spatialize world events correctly; UI cues should not sound like distant objects. Test overlap, loop seams, crossfades, voice limits, ducking ownership, pause/resume, scene changes and combat/boss/death exits. Measure the repository’s loudness/true-peak policy and listen to actual mixtures. Prevent stale combat music and missing exported recordings.

Music should support dark exploration, tension, pursuit, local relief and finale without constant dramatic noise or an unpleasant continuous hum. Preserve appropriate tracks after listening. If current owner canon requires Gemini-origin replacement, use available authorized access and record actual provenance. Do not rename old recordings or invent generation/rights evidence. Unavailable account/tool/rights inputs are specific blockers, not reasons to stop independent work.

Validate actual supported gameplay as an integrated loop: movement/look, stealth/hiding, flashlight modes, combat/weapon/ammo, interaction/doors, loot/inventory/equipment, consumables/quick access, supported crafting/skills/trade, quests/repair, district travel, death/checkpoints, endings and New Game Plus where present.

For each affected mechanic test normal, rejected, repeated, interrupted, paused, death and save/reload behavior as relevant. Transactions must be atomic: one cost and one reward, no duplicate ownership, free repeat repair reward, negative counts or consumed items after rejection. UI and audio must follow the same state result.

Preserve verified lifecycle, hidden-player combat, autosave, fresh-game reset and hardcore-death fixes. Test actual save-slot isolation, corruption/migration handling, denied/full storage reporting and recoverable progress. Use isolated test profiles; never erase owner saves.

Use one valid end-to-end campaign on the frozen candidate plus focused valid-state fixtures for additional ending branches. Bots must obey real aiming/navigation rules; do not weaken mechanics to make bots pass. Human playability and device ergonomics still require their own evidence.

## 11. Acceptance: actual evidence, targeted first, integrated last

Maintain one compact requirement/finding ledger using current repository equivalents. Each entry records source/consumer, expected behavior, implementation commit, status and evidence. Use NOT_STARTED, IN_PROGRESS, IMPLEMENTED, VERIFIED or BLOCKED. A stale OPEN row is a lead to check; an old PASS cannot certify changed source.

Required proof:

| Gate | Passing result |
|---|---|
| Recovery | Local changes/commits preserved and classified; clean integration baseline; no owner work overwritten. |
| Darkness | Paired DARK flashlight-off/on and restored-lamp captures plus live environment values show correct active fog/light behavior on supported tiers. |
| Visibility | Hidden monsters do not leak via map, reticle/bar, spotted names, auto-aim or continuing damage numbers; visible combat remains correct. |
| Map positive/negative | Actual restored light reveals only observed geometry; flashlight/walking/time do not; walls/FOV/light-budget changes behave correctly; sampling makes progress. |
| Persistence/travel | Real save/reload/revisit, slot separation, layout migration and New Game; all required district/return/finale routes remain reachable. |
| Physical controls | Actual pointer events and device testing demonstrate move/look/fire and cancellation. Per-control measured sizes, safe-area coverage and overlap results exist. |
| UI/EN-RU | All reachable screens and sparse/full/locked/error/long-text states are coherent and readable in both languages. |
| World/art | First-person close/far DARK/restored captures across all eleven districts; no release-visible primitive placeholders or obviously deficient repeated facades. |
| Audio | Required events and transitions heard in the exported build; loops/mix/provenance/export presence verified. |
| Android startup/effects | Branded cold start; one grain owner; no Low rain overlay; live tier changes and generated manifest verified. |
| Gameplay | Relevant regressions plus complete campaign and ending-condition coverage, transactions/saves and no progression softlocks. |
| Performance | Measured supported configuration, sustained play, stable memory/load/input; source estimates do not substitute for phone data. |
| Package/source | Final export opens outside editor, contains intended assets/locales, passes signing/version/reference checks, and corresponds to the delivered commit. |

Use current gate wrappers and commands only after inspecting their invocation contracts. Relevant existing tools include proof_run, tools/check.sh, flow/scene/input checks, headless suites, guarded_windowed, autoplay/playthrough, save migration, audio/visual and export checks. Headless skips do not become passes for windowed performance/audio. Record actual command, exit status, source revision, device/renderer, profile and evidence path.

Never remove assertions, suppress errors, lower budgets, mark mandatory features “not applicable,” or delete a failing mechanic to manufacture readiness. Update obsolete tests only when the requirement actually changed, and retain meaningful regression coverage. A button signal test is not a hardware event test; a filename lookup is not visual approval.

Take genuine after-captures from the implemented game: source/build identity, resolution, quality tier, district/seed, camera pose, power state and timestamp. Compare the same scene/settings before and after; do not brighten only the “after.” Keep generated concepts separate from runtime proof.

Review normal movement/combat, not only staged hero shots. Visual rejection conditions include crude close-range creature/building geometry, flattened photographs pretending to be 3D, repetitive stains, unexplained bright blobs, blue glowing darkness, huge empty panels, illegible text, mismatched icons, hidden map leaks, or a broken supported lower tier.

Measure frame time, draw calls, primitives, memory, loading and sustained behavior against actual agreed project budgets. Optimize LOD, culling, mesh/material batching, texture residency and light/shadow counts without destroying the target. No repeated whole-world map/visibility scans. Avoid changing user-facing resolution merely to hide a performance problem.

Use the actual signed Android package on supported hardware for cold install, update preserving saves, fresh launch, touch, EN/RU, safe areas, audio, pause/resume and sustained performance/thermal behavior. Emulator/synthetic results may supplement but must be labeled. No device access means DEVICE_VERIFICATION remains blocked; do not invent a phone run or reuse desktop store frames as proof.

## 12. Final integration, package and stop condition

Finish the current product scope; do not add cloud saves, multiplayer, seasons or new monetization merely because old concepts or dormant code mention them. Equally, do not defer mandatory art, controls, map, audio or progression while claiming completion.

Commit tested source/assets/configuration and concise evidence in coherent changes. Keep secrets, owner saves and signing material out of git. Keep large build files in the established artifact mechanism. Update required source imports, licenses/provenance and export references. Check that a fresh checkout can reproduce the candidate with documented tools.

Verify actual publishing/version state before choosing a version code; the repeated historical code 17 is not a promise it remains unused. Use the working current engine/templates/JDK and the established release wrapper; do not introduce a new untested build pipeline.

Review the integrated diff for lost work, stale alternate UIs, unintended file deletions, import/audio-bus rewrites, secret exposure, disabled gates and source/build mismatches. Run an independent review of the whole candidate. Re-fetch before integrating if others are working.

Merge into main through required checks/PR protection when authorized access permits. Verify the remote SHA. Do not force push or bypass protection. If push/merge is blocked, preserve the exact tested branch/PR and report main unchanged. Keep branches/history until separate cleanup authorization; this task does not authorize deletion.

READY requires all mandatory gates verified, no crash/data-loss/progression/input blocker, no major reference mismatch, tested distributables and valid asset/export state. Distinguish code complete, verified, merged, packaged, installed and publicly published. Store submission requires its real account actions; do not claim it occurred from a successful build.

If remaining quota, asset production, rights, account access or test hardware prevents that outcome, deliver the implemented candidate, exact tested commit/artifacts and a concise list of failed or unrun mandatory checks with next actions. Do not promise permanent perfection, simulate acceptance or produce another “final prompt.”

Final owner response: English, concise. State READY or NOT READY, main/integration commit or PR, artifact locations, relevant test summary and only concrete remaining blockers. No long narrative of the work.

## 13. Technical references for disputed audit assumptions

These sources clarify implementation rules; they do not certify this game:
- Android touch targets: https://developer.android.com/guide/topics/ui/accessibility/apps
- Android density conversion: https://developer.android.com/training/multiscreen/screendensities
- Android dp/sp and text scaling: https://developer.android.com/design/ui/mobile/guides/layout-and-content/grids-and-units
- WCAG 2.5.5, enhanced target size: https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced
- WCAG 2.5.8, minimum target size: https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum
- Godot stretch/scaling: https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html
- Claude session versus weekly usage limits: https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work

**Start by recovering interrupted local work and refreshing main. Preserve what is already correct, implement the remaining failures, verify the actual game and deliver the real result.**

