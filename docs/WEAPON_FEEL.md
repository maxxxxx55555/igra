# Weapon feel (Session 23)

The three firearms of `scripts/weapons/` and what a shot does. The numbers are the constants of the weapon scripts; DPS is damage times pellets over the fire
interval, with every pellet hitting. Check WEAPON1 (`CLOSEOUT_ONLY=s23`) holds the recoil values, the kick and the reload.

| Weapon | Damage | Pellets | Fire interval | Magazine | Reload from empty | Spread (rad) | Recoil | DPS |
|---|---|---|---|---|---|---|---|---|
| Pistol | 25 | 1 | 0.30 s | 12 | 1.2 s | 0.015 | 0.45 | 83.3 |
| Rifle | 14 | 1 | 0.12 s | 30 | 2.2 s | 0.012 | 0.35 | 116.7 |
| Shotgun | 8 | 5 | 0.90 s | 6 | 2.4 s | 0.09 | 1.00 | 44.4 |

## What a shot does now

- **Recoil.** Every weapon had the same untouched default of 0.5, and the player had no `apply_recoil`, so a shot never moved the view. Each weapon has its own value
  now and the first-person camera kicks up 0.04 rad per unit of it (pistol 1.0 degree, rifle 0.8, shotgun 2.3) with a small random yaw of a third of that, and it
  settles at 9 per second (half a second later the kick is gone: 0.040 rad to 0.000 measured). The kick is on the camera only: the shot has gone along the aim
  before it, so accuracy is what it was. Motion Comfort turns it off.
- **Shell.** A single-shot weapon throws a case to the right (`docs/VFX_BUDGET.md`); the shotgun keeps its cases.
- **Reload.** A reload with rounds left takes 0.8 of the time of a reload from empty (`WeaponBase.TACTICAL_RELOAD`), measured 0.80.
- **Muzzle flash, sound, noise.** The flash scene, the shot sound and the noise of a shot (the monsters hear it) were there already.

## Ammo economy (read from the code)

One reserve feeds all three weapons (`ProgressTracker.ammo`). A pickup is 12 rounds; no ammo lies in the first district, one pickup in each of the next five and two from the police district on
(`DistrictLoot`: `AMMO_PER_PICKUP` and `AMMO_DOUBLE_FROM`); the Sharpshooter drops a box of rounds (`base_monster.gd`). Gunpowder and a case make a noise bomb at the workbench.

## Gaps, listed and not built

- No aim down sights exists, so there is no aimed spread to compare with the hip spread, and the spread does not grow with movement. Adding either changes the
  accuracy of the bot and needs a design decision and the IRON RULE.
- A reload has no animation of its own, tactical or from empty: a weapon scene is a node with a muzzle marker and a script (no mesh, no animation player), so no weapon is drawn in the view.
