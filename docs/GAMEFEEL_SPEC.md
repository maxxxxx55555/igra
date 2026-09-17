# Game feel spec

Per-event juice for The Last Streetlight. Caps: hit-stop ≤80ms, screen shake ≤4px-equivalent.
Every effect names the accessibility toggle that disables or reduces it. None of the three
toggles below exist yet in `SettingsManager` — this doc is the spec; wiring them is a P4
implementation task, not done here.

## Existing juice (already shipped, reused not rebuilt)

| Event (EventBus signal) | Effect | File | Toggle needed |
|---|---|---|---|
| `player_damaged` | camera trauma shake, trauma += 0.3 | [scripts/effects/screen_shake.gd](scripts/effects/screen_shake.gd) | `reduce_ui_motion` (already gated by `reduce_screen_shake`, see below) |
| `enemy_died` | camera trauma shake, trauma += 0.15 | same | same |
| death | `Engine.time_scale = 0.3` for the death beat | [scripts/player/death_sequence.gd](scripts/player/death_sequence.gd) | `reduce_time_fx` (not yet gated) |
| boss phase slow-mo | `Engine.time_scale = slow` | [scripts/systems/wow_director.gd](scripts/systems/wow_director.gd) | `reduce_time_fx` (not yet gated) |

`screen_shake.gd` already checks `SettingsManager.get_setting("reduce_screen_shake", false)`
before adding trauma — this is the existing name for what the mega-spec calls
`reduce_ui_motion`. **Decision:** keep the existing key name (`reduce_screen_shake`) rather than
rename it and touch every call site; add `reduce_flash` and `reduce_time_fx` as two *new*
keys alongside it instead of forcing all three into one generic name. Reuse over rename.

Shake amplitude today is a 3D camera-position offset in world units
(`shake_intensity = 0.5`, quadratic falloff, decay `5.0`/s), not a 2D pixel offset — there is no
existing px-based shake to compare against a 4px cap. Spec for P4: cap the effective screen-space
displacement (position offset × projected pixels-per-unit at the camera's working distance) at
4px equivalent; concretely this means dropping `shake_intensity` to a value measured in-engine at
implementation time, not guessed here.

## New events to juice (P4 scope)

| Event | Effect | Cap | Toggle |
|---|---|---|---|
| `item_picked_up` | brief icon pop + flash on HUD slot | flash ≤ 120ms, opacity ramp only (no strobe) | `reduce_flash` |
| `xp_gained` | XP bar fill tween, no camera fx | n/a (UI-only) | `reduce_ui_motion` |
| `achievement_unlocked` | toast slide-in + 1 shake pulse | shake ≤4px-equiv, hit-stop 0ms (no combat impact) | `reduce_ui_motion` for the slide, `reduce_flash` for any glow |
| `enemy_hp_updated` (crit/heavy hit only, not every tick) | hit-stop | ≤80ms `Engine.time_scale` dip, restored same frame group | `reduce_time_fx` |
| `player_healed` | soft green flash on HUD, no shake | flash ≤120ms | `reduce_flash` |
| `boss_defeated` | shake + hit-stop combo | shake ≤4px-equiv, hit-stop ≤80ms | both `reduce_ui_motion` and `reduce_time_fx`; effect plays at the *lower* of the two if only one is on |
| `district_blackout` / `light_disrupted` | screen flash to black transition | flash ≤120ms per pulse, no repeated strobe | `reduce_flash` (hard requirement — this one is a real photosensitivity risk, never skip the gate) |

## Rules for P4 implementation

- No new effect ships without checking its toggle first (`if SettingsManager.get_setting("reduce_x", false): return` before triggering, mirroring `screen_shake.gd`'s existing pattern).
- Hit-stop is a shared `Engine.time_scale` resource — two effects must never stack multiplicatively (boss + hit combo above resolves this explicitly).
- `district_blackout`/`light_disrupted` flash gating is not optional under any settings combination — this is the one photosensitivity-relevant effect in the list.
