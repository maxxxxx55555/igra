# Handoff

Full detail in `docs/SESSION_REPORT.md`. This file is the short version for
picking the project back up.

## State right now
- All 4 mandatory gates green, `tools/check.sh` (static) green, all work
  pushed to `origin/main` at commit `22c97b1`.
- 19/19 requested tasks landed with real, tested code — not stubs. Several
  turned out to be "backend already existed, UI never called it"
  (equipment slots) or "the system already runs, it just doesn't run *on
  the player*" (status effects) rather than net-new features.

## Do this first in the next session
Run the gates before touching anything, to confirm the baseline is still
what this report says it is:
```bash
bash tools/check.sh
```
(The engine-check portion, including the new `save_integrity_check_scene`,
takes a few minutes — it loads a full 3D test scene.)

## Open threads (none are blockers, all are deliberate scope cuts)

1. **Oversized ambience loops.** `assets/audio/ambience/*.wav` (5 files,
   ~30MB) exist on disk but aren't committed — they're ~10x over the 1MB
   audio budget. Either transcode to OGG and wire as new/replacement
   `MusicDirector.LAYERS` entries, or decide the existing `Ambient_*.ogg`/
   `Threat_*.ogg`/`Action_Sting.ogg` already cover this and discard them.

2. **Parallel SFX naming.** New `monster_<name>_<cue>.wav` files sit
   alongside the wired `mon_<name>_<cue>.wav` convention that
   `base_monster._set_cues()` actually uses. Needs a human call on
   replace-vs-supplement before touching any monster script's `_set_cues`.

3. **District tilesets + UI chrome PNGs** are generated and imported but
   unused — current district materials and UI are procedural. Not a gap
   (nothing looks broken), just an available upgrade if visual polish is
   next on the roadmap.

4. **Orphaned touch-control duplicate.** `scripts/touch_controls.gd`,
   `scripts/ui/touch_controls.gd`, `scenes/ui/touch_controls.tscn` are
   never instantiated by any live scene — the real mobile input lives in
   `hud_3d.gd` + `virtual_joystick.gd`. Left in place (not proven
   dead-and-not-planned per the project's hard rule), but worth a
   deliberate look before the next mobile-input task touches this area,
   so work doesn't accidentally land in the wrong file.

5. **Ranged weapons are dormant.** `WeaponManager`/`WeaponBase`/
   `weapon_pistol.gd` etc. are complete but never instantiated under the
   player — `weapon_pickup.gd` even calls a `WeaponManager.unlock_weapon()`
   method that doesn't exist. The live combat model is melee-only. This is
   a design decision (does this game want ranged weapons at all, or is
   this legacy from an earlier design pass?), not something to silently
   wire in.

## Things NOT to redo
Everything in CLAUDE.md's "Already done" list, plus (from this session):
T1-T4, T11 were verified against the GDD and found already correct —
don't rebuild them from the top-level task list without checking current
state first, the way this session did.
