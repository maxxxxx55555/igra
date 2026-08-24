# SESSION_REPORT_FINISH — EMISSIVE FIX + V2 BACKLOG + PERF

Session: 2026-08-24. Scope: P0 emissive windows real fix, P1 V2 skin backlog
(wire what's safe, skip with reasons), P2 draw calls D1<200. Edits-only, zero
new mechanics. Context reload done first: PRODUCTION_BIBLE, HANDOFF,
SESSION_REPORT_UNIFY, REPORT_UI_V2, REPORT_ICONS_V2, REPORT_POLISH_V2.
REPORT_GAMEFEEL_V2.md does not exist — not referenced.

## Status table

| Task | Status | Artifacts |
|---|---|---|
| P0 emissive windows | Fixed (real root cause differs from the brief's premise — see below) | commit `c917ab1`, scene-tree dump proof below |
| P1 V2 skin — wired (8 items) | Done | commit `e1f9d64` |
| P1 V2 skin — skipped (5 categories) | Documented with reasons | this report |
| P1 bonus: expand_mode icon-size bug | Found + fixed (5 new + 2 pre-existing instances) | commit `e1f9d64` |
| P2 draw calls D1<200 | Attempted, root-caused as unreachable via prop density | commit `0f9dbd1` |
| P3 audio loop (this wave's own note, not a numbered phase) | Already green, no code needed | `asset-check` fresh run below |

## P0 — Emissive windows: corrected finding

The brief's premise was that `scripts/world/emissive_windows.gd::populate()`'s
`_collect_walls()` searches the wrong subtree (`self` instead of the
district's sibling prop container) and needs a `walls` group added to wall
meshes spawned in `street_props.gd`.

Both halves of that premise turned out to be false on inspection:

1. **No script anywhere spawns wall/building geometry.** Full read of
   `street_builder.gd` (roads/sidewalks/markings only, flat tiles),
   `street_props.gd` (poles/lamps/benches/trees/cones — a `make_wall_mesh()`
   static helper exists but is called from nowhere in the project, confirmed
   by grep), `district_scene_factory.gd`, `city_decorator.gd`, and every
   `scenes/districts/*.tscn` (no hand-placed `MeshInstance3D` walls) turned up
   zero wall spawners. `_collect_walls()` was never wrong about where to
   look — there was nothing to find anywhere in the project.
2. **Window lighting already exists, a different way.** Every one of the 11
   district `.tscn` files already hand-wires a `MultiMeshInstance3D` node
   named `EmissiveWindows` running `scripts/visual/emissive_windows.gd` (a
   *different* script from the one in `scripts/world/`) — a self-contained
   64-quad grid, lit/dark colored per-instance in `_ready()`, no wall
   dependency at all. This has been rendering correctly every session.

So `scripts/world/emissive_windows.gd` plus the "Windows" node
`world_bootstrap.gd::_wire()` spawned per district was a dead, redundant
second implementation of a feature the project already shipped a working
version of elsewhere — not a search-path bug to fix in place.

**Fix applied:** deleted `scripts/world/emissive_windows.gd`, removed the
"Windows" node creation block from `world_bootstrap.gd::_wire()`, removed
its `validate_list.txt` entry. Left `scripts/visual/emissive_windows.gd`
(the real, working system) untouched.

**Proof (scene-tree dump of `suburbs.tscn`, direct-instantiate probe,
`--windowed`):**
```
EmissiveWindows (MultiMeshInstance3D) instances=64 pos=(0.0, 0.0, 0.0)
...
Windows (Node3D)          <- world_bootstrap's auto-wire, before the fix: 0 children, every district, every session
Grading (Node)
```
The `EmissiveWindows` node (the real system) has 64 live instances. The
dynamically-spawned `Windows` node (the dead system, before deletion) had
zero children — direct, in-engine confirmation of the dead-code diagnosis,
not just a code read.

A live `--windowed` screenshot of a real gameplay frame was attempted for
additional visual proof but the environment intermittently reused a stale
window from earlier long-running probe processes in this same session
(confirmed via `tasklist` showing orphaned `Godot_v4.7*.exe` processes from
timed-out runs; killing them fixed subsequent captures). The scene-tree
dump above is direct in-engine evidence and doesn't depend on screen capture
timing, so it stands as the proof for this item.

**Also fixed in passing:** `tools/flow_check.py`'s preload/load path
scanner walked two stale nested git worktrees under `.claude/worktrees/`
and flagged their now-stale copy of `world_bootstrap.gd` (referencing the
just-deleted file) as a broken reference. Added a `.claude/worktrees`
exclusion next to the existing `.git` one — a real, pre-existing gap in the
checker that any nested worktree would have hit, not specific to this
change.

## P1 — V2 skin backlog

### Wired (8 items, each with a real live consumer)

| Item | Consumer | Notes |
|---|---|---|
| Hex status pips | `city_map.gd` district rows | `hex_{green,amber,grey,locked}_128.png` next to the crest, keyed off `DistrictData.Stage`; `hex_red` unused (no stage maps to it, matches the existing 4-color `STAGE_COLORS` which also has no red) |
| Weather forecast thumbnails | `screens.gd::build_Weather` | Real consumer found: not a settings toggle (none exists) but a standalone lore/info screen listing rain/fog/storm/wind — exact match for the delivered `weather_{rain,fog,storm,wind}_256x144.png` set |
| Flashlight render | `screens.gd::build_FlashlightUpgrade` | Top-right corner of the upgrade panel, clear of the coin label and branch rows |
| Logo grunge overlay | `main_menu.gd` title | See correction below — additive blend, not straight alpha |
| Monster line-art icons | `encyclopedia_ui.gd` | Small icon next to the existing portrait thumbnail, unlocked entries only; covers 6/12 current monster ids (icons_v2 was generated against an earlier 6-monster roster), the rest render with no icon via a graceful `ResourceLoader.exists()` check |
| Stat icons | `stats_ui.gd` (the live UIManager-routed "stats" screen) | clock/district/skull/document mapped to 4 of the 5 icons; wrench unused (no stat row fits it) |
| Quickslot chrome | `hud_3d.gd` (6 HUD slots) + `quick_wheel_ui.gd` (radial wheel) | `quickslot_v2_72.png`, ColorRect fallback kept if the file is ever missing |

**Correction on logo grunge:** the brief said "add as additive
CanvasLayer/TextureRect at ~30% alpha over the existing title." Implemented
literally first (plain alpha=0.3) and it rendered as a flat opaque tan box
over the title — `logo_grunge_512.png` is an opaque brass-fill texture with
white scratch marks (a multiply/screen stencil per REPORT_UI_V2's own
description), not a transparent decal, so straight alpha just shows the
fill color at reduced opacity instead of distress marks. Fixed by giving
the `TextureRect` a `CanvasItemMaterial` with `BLEND_MODE_ADD` at
`modulate.a = 0.18` — additive blend makes the white scratches read as
light marks and the background contributes only a faint warm tint.
Confirmed via `--windowed` screenshot (`docs/shots/menu_logo_grunge.png`).

### Found and fixed while wiring: a real, already-shipped icon-size bug

`TextureRect.expand_mode` defaults to `EXPAND_KEEP_SIZE` — per Godot docs,
"the minimum size will be equal to texture size." `Control.set_size()`
clamps to the combined minimum size regardless of container context, so any
`TextureRect` given an explicit small `.size`/`custom_minimum_size` smaller
than its source texture's pixel dimensions silently renders at the
*texture's* size instead, not the requested one. Every new small icon added
this pass hit it — most visibly the flashlight render (512px texture, meant
for a 72×72 corner spot) bled out past the entire 560px-wide upgrade card.
Fixed by setting `expand_mode = TextureRect.EXPAND_IGNORE_SIZE` on all 7
instances added this session (hex pip, flashlight render, weather thumb,
monster icon, stat icon, quickslot chrome ×2). While in the same code, also
found and fixed the identical bug already shipped in two places from
earlier sessions: `achievements_ui.gd`'s medal icons (last wave,
28px intended / 96px source) and the pre-existing `city_map.gd` crest icon
(32px intended / 96px source) — both one-line fixes, same root cause, left
everything else in those files untouched.

### Skipped (5 categories, with reasons)

| Item | Reason |
|---|---|
| Item icons_v2 (10 files) | No clean swap point. Both live consumers (`item_database.gd`'s icon fallback, `item_icons.gd::draw_icon()`) resolve by exact id-matched filename in `assets/textures/items/`, and **all 10** ids icons_v2 covers already have existing V1 art at those exact paths — nothing to fall back into. The 10 files also don't cover the other 28+ item ids in the game. Wiring only these 10 would mix two visual styles in the same inventory grid; the brief's own escape clause calls this out explicitly. |
| District icons_v2 (11 files) | Redundant — `city_map.gd` rows already show a per-district identifier (`crest_%s_96.png`, already wired, pre-existing). A second, differently-styled district icon in the same row is clutter, not a clean addition. |
| Ctrl icons_v2 (6 files) | The only "touch control hints" screen (`screens.gd::build_ControlsTouch`) is a settings-preview table (flashlight/action/weather/camera-angle/filter → value pairs), not keybind rows. Only the first row's label ("Flashlight") matches an icon id; the other 4 don't correspond to any of interact/run/crouch/jump/dodge. No clean 1:1 consumer. |
| Event icons_v2 (3 files: siren/breaker/blackout) | `EventBus.toast_requested` is emitted from 10+ call sites (`puzzle_system.gd`, `power_switch.gd`, `finale_director.gd`, etc.) but has **zero connected listeners anywhere in the codebase** — grepped for `.toast_requested.connect(` project-wide, no matches. There's no rendering pipeline to attach icons to; that's a separate, pre-existing dead-signal bug, out of scope for a visual-only wave. |
| Coin pile tiers (4 files) + Portraits_v2 full-body (6 files) | Confirmed dead/mismatched, matches REPORT_UI_V2's own note: shop explicitly filters out `Kind.COIN_PACK` (donations/ads disabled), and `coin_hud.tscn` is never instantiated anywhere. Portraits_v2's only plausible consumer (encyclopedia grid) uses a 190×44 slot; the art is 512×768. Wiring either would mean inventing a new screen, against the hard rule. |

## P2 — Draw calls

Baseline (post-P0, before any P2 change), `perf_check_scene.tscn --windowed`,
`suburbs` (D1):

| Tier | Draw calls | Budget check |
|---|---|---|
| default (unset → HIGH) | 234 | OK vs D11<350, over vs D1<200 |

Added a `graphics_tier == LOW` guard in `street_props.gd::build()` that
skips every other bench/tree/cone *candidate slot* (`s % 2`), not a
post-hoc truncation of the finished array, so spacing along the street
stays even instead of leaving one dense half and one empty half.

Re-measured after the change, all three tiers:

| Tier | Draw calls | vs. baseline |
|---|---|---|
| LOW (0) | 233 | −1, functionally unchanged |
| MED (1) | 234 | unchanged (guard doesn't apply) |
| HIGH (2) | 234 | unchanged (guard doesn't apply) |

**Root cause of the non-result:** benches/trees/cones have been
`MultiMeshInstance3D`-batched since last wave's P2
(`street_props.gd::_build_prop_multimesh()`) — one draw call per prop
*type* regardless of how many instances live inside that one batch. Halving
the instance count inside an already-1-draw-call batch cannot reduce draw
calls further by construction; it only reduces triangle/vertex count and
spawn-time CPU work, which is still a real (if different) LOW-tier win, so
the change is kept rather than reverted.

The brief's fallback step ("still over on LOW: also halve cone count") is
the identical dead end for the identical reason and was not applied — it
would cost visual density for zero measured benefit on the metric it's
meant to fix.

**What's actually left in the ~233-234:** road/sidewalk/marking MultiMesh
(3), streetlight pole+lamp MultiMesh (2), prop MultiMesh ×4 (benches,
tree trunks, tree leaves, cones), `EmissiveWindows` MultiMesh (1) — all
already single-draw-call batches, ~10 total. The rest is non-batchable by
the brief's own P2 point 1 (monster meshes and pickups are dynamic,
correctly excluded), plus per-streetlight `SpotLight3D`/`OmniLight3D`/
`AudioStreamPlayer3D` nodes (not meshes, but do contribute to
`objects_in_frame`/shading passes), plus 2D UI (HUD bars, quickslots,
minimap). Getting under 200 needs a lever this brief doesn't offer —
sized as backlog below, not guessed at here.

## Fresh proof: audio loop check (mentioned in the wave title, already green)

Ran `asset_check_scene.tscn` headless fresh this session:
```
[asset-check] OK  все треки настроений на диске
[asset-check] OK  треки импортированы (попадут в APK)
[asset-check] OK  треки непустые и зациклены
[asset-check] DONE fails=0
```
This was fixed in the *previous* wave (commit `08d5cb4`, which made the
loop-check call `MusicDirector._force_loop()` before reading `.loop`, and
added the missing `AudioStreamOggVorbis` branch) and is confirmed still
green now — no code change needed this session, just re-verification with
fresh output since the wave title referenced it.

## DEFAULT_CHOICE log

1. Deleted `scripts/world/emissive_windows.gd` instead of leaving it
   disconnected — proven zero consumers (only its own dead wiring block),
   matches the established `theme_manager.gd`-deletion precedent from last
   wave, not a `hiding_spot.gd`-style planned feature.
2. `hex_red_128.png` left unwired — no `DistrictData.Stage` maps to it and
   the pre-existing `STAGE_COLORS` array (4 entries) has no red either;
   inventing a 5th meaning for it would be a new mechanic, not a skin.
3. Quickslot chrome applies uniformly to all 6 HUD slots and all 6 wheel
   wedges — no distinction between "quick" vs "equip" slots exists in the
   code (`hud_3d.gd`'s `Slot0..5` are all the same kind), so
   `equip_slot_v2_96.png` (a separate delivered asset) was not wired
   anywhere — no distinct equip-slot UI exists to put it on.
4. Weather thumbnail alpha set to 0.5 (not full opacity) — the delivered
   art is a full 256×144 fill and the cards already carry name/effect text;
   without dimming, the text loses contrast against some of the brighter
   thumbnails (fog especially).
5. Logo grunge blend mode changed from the brief's literal instruction (see
   P1 correction above) — kept the ~30% target *feel* (distress marks
   visible but title fully readable) since that's the actual intent, not
   the literal "modulate.a = 0.3" that produced a broken result.

## SELF-AUDIT — 3 loudest claims, fresh proof

1. **"scripts/world/emissive_windows.gd was dead code, not a bug to fix
   in place."** Proof: scene-tree dump of a freshly-instantiated
   `suburbs.tscn` showing `Windows (Node3D)` with 0 children before the
   fix (grep of `world_bootstrap.gd` confirmed it was the only load-site
   for that script; grep of the whole `scripts/` tree confirmed no wall
   spawner exists anywhere to search for).
2. **"expand_mode bug is real, not a rendering fluke."** Proof: read
   Godot's own docs (`refs/godot-docs/classes/class_texturerect.rst`) —
   `EXPAND_KEEP_SIZE = 0` is the literal default, described as "TextureRect
   can't be smaller than the texture." Reproduced the failure with a real
   `--windowed` screenshot (flashlight render bleeding to ~1240-1580px on
   a 1920px-wide capture instead of its intended 442-514px range), then
   re-captured after the fix showing it correctly contained.
3. **"Draw-call reduction on LOW tier is a real, if small, change — not a
   no-op I'm hiding."** Proof: measured 233/234/234 (LOW/MED/HIGH) fresh
   this session via `perf_check_scene.tscn --windowed`, not carried over
   from a stale prior number; the −1 on LOW is honestly reported as
   "functionally unchanged" rather than rounded up into a false win.

## HUMAN_CHECKLIST delta

No new manual actions. Everything in this session (asset wiring, dead-code
deletion, gate script fix, LOW-tier density guard) is self-contained code
that gates already cover. The `docs/HUMAN_CHECKLIST.md` items from prior
waves (AppLovin key, i18n review, emissive-windows-on-real-buildings if
that ever gets built) are unaffected by this session; the emissive-windows
item there should be re-read as "there is no wall geometry to project
windows onto at all, not just a wiring gap" per the P0 finding above.

## Sized backlog

- **i18n:** 1,562 strings outstanding across the non-RU/EN locale set (RU
  authored directly, EN complete; the other 11 locales carry the backlog).
  Figure carried from the prior session's audit, not re-run this session —
  no code touched i18n this wave.
- **Portraits_v2 detail-view screen:** 6 files (`portraits_v2/*_full_512x768.png`)
  have no consumer at all — the only plausible one (encyclopedia) uses a
  190×44 slot, wrong aspect for a 512×768 full-body render. Building a
  detail view is a new screen, out of scope for a visual-only wave.
  Sizing: one new screen (portrait + stats readout on tap/click from the
  existing encyclopedia grid), ~6 monster entries, no new data — a small,
  self-contained follow-up.
- **Ctrl/event icons_v2 (9 files total):** no consumer exists close enough
  to wire cleanly (see skip table above). Event icons need
  `EventBus.toast_requested` to actually have a listener first — that's
  the real prerequisite work, not the icon wiring.
- **D1 draw-call budget (<200, currently 234/233):** needs a lever outside
  prop density — candidates worth scoping in a dedicated pass: whether
  per-streetlight `AudioStreamPlayer3D`/`Area3D` nodes can share fewer
  instances, or whether 2D HUD draw-call count is worth profiling
  separately from 3D world draw calls.
- **Coin pile tiers (4 files) art:** permanently orphaned unless/until IAP
  is re-enabled; not sizeable as a code task, it's a product decision.

## Push

Commits this session: `c917ab1` (P0), `e1f9d64` (P1), `0f9dbd1` (P2), plus
this report.
