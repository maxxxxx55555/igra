# Asset Manifest

Tracks what art/audio assets exist on disk, where they're actually wired into
the game, and what's still pending. Source report from the asset-generation
pass: `docs/REPORT_ASSETS.md`. This file is the lead-dev-owned follow-up —
update it whenever new assets land or get wired into code.

## Integrated (referenced by code, verified via gates)

| Asset | Path pattern | Wired via |
|---|---|---|
| Enemy portraits (6 new + Architect) | `assets/textures/enemies/{sniper,brute,burner,rotter,hound,tvar,architect}_512.png` | `data/monsters/monster_*.tres` `portrait` field (new `MonsterData.portrait` export) → `scripts/ui/encyclopedia_ui.gd` card art |
| Status effect icons | `assets/textures/ui/status_{bleed,burn,poison,slow,stun}.png` | `scripts/ui/hud_3d.gd` `_STATUS_ICONS`, replaces the emoji-glyph fallback |
| Item icons (26 regenerated) | `assets/textures/items/*.png` | Already referenced by path in `data/items/*.tres` — regenerated in place, no code change needed |

## Present on disk, not yet wired

These exist and pass import/size checks but nothing in scripts/scenes
references them yet. Not blocking anything (no `ASSET_PENDING` placeholders
found in the codebase) — listed here so a future pass can pick them up
deliberately instead of rediscovering them.

- **District tilesets** (`assets/textures/tiles/*_floor.png`, `*_wall.png`,
  22 files, 11 districts × floor/wall) — district scenes currently use
  procedural/flat materials; wiring these in means touching each
  `scenes/districts/*.tscn`'s materials, out of scope for this pass.
- **UI chrome** (`btn_*.png`, `bar_*.png`, `progress_*.png`,
  `tooltip_panel.png`, `inventory_slot.png`) — current UI draws these
  procedurally via `StyleBoxFlat`/`ColorRect` (established project
  convention, see `character_screen.gd`, `hud_3d.gd`). Swapping to textures
  is a visual-polish pass, not a functional gap.
- **New SFX** (`ui_*.wav`, `footstep_*.wav`, `shot_*.wav`,
  `monster_*_{click,scrape,breath,step,hum}.wav`, 15 files) — the existing
  footstep system (`footstep_system.gd`) and monster cue system
  (`base_monster._set_cues`) already reference a *different* naming
  convention (`step_<surface>.wav`, `mon_<name>_<cue>.wav`) that's fully
  wired and covered by `asset_check_scene.tscn`. These new files use a
  parallel `monster_<name>_<cue>.wav` naming and were not mapped onto the
  existing cue calls — doing so needs a deliberate decision on whether they
  *replace* or *supplement* the current cues, not a silent swap.
- **`ammo.png`** — no `ammo` `ItemData` exists in `data/items/` (ammo pickups
  go through `scripts/gameplay/ammo_pickup.gd` → `player.add_ammo()`
  directly, bypassing the inventory item system entirely). The icon has no
  current consumer.

## Known issue — not committed

`assets/audio/ambience/*.wav` (5 files, ~30 MB total: `ambient_dark_loop`,
`ambient_lit_loop`, `threat_low_loop`, `threat_high_loop`,
`action_sting_loop`) were generated at their full spec'd durations
(16-120s) as 44.1kHz/16-bit mono PCM WAV, which puts every file well over
CLAUDE.md's 1MB audio budget (largest is ~10.3MB). `REPORT_ASSETS.md`
flagged this itself and suggested an OGG transcode
(`ffmpeg -i in.wav -c:a libvorbis -q:a 4 out.ogg`, ~90% smaller).

These files are **left on disk but not committed** — nothing in the
codebase references them yet (see `MusicDirector.LAYERS` in
`scripts/systems/music_manager.gd`, which already has *different* files —
`Ambient_Dark.ogg` etc. — filling this exact role), so committing 30MB of
unused, spec-violating WAVs into the repo isn't worth it. Next step: either
transcode to OGG and wire them in as an alternative/replacement for the
existing `Ambient_*`/`Threat_*`/`Action_Sting` layers, or discard if the
existing `.ogg` layers already cover this need.

## Size/format compliance
All *committed* textures are ≤ 60KB (well under the 500KB cap) and all
committed audio is under the 1MB cap except as noted above. Verified via
`res://scenes/tools/asset_check_scene.tscn` (part of the mandatory gate
set) — passes clean.
