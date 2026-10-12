# Effects budget (Session 23)

Canon (`docs/PRODUCTION_BIBLE.md` section 4): particles under 500 at once, lights under 8, draw calls under 200 (suburbs) and 350. The directive's own
bound is 1000 particles. The probe is `CLOSEOUT_ONLY=s23` check VFX6 (`scripts/tools/rc16/fx_checks.gd`): it counts every emitting `GPUParticles3D` of
the running game (amount times the tier's ratio) with every pooled burst in flight.

| Effect | Where | Particles / cost | Gate |
|---|---|---|---|
| Muzzle flash | `vfx_muzzle_flash.tscn`, pooled by `vfx_pool.gd` | 8 for 0.12 s | none (a flash of a shot) |
| Shell ejection | `scripts/effects/shell_eject.gd`: a pool of 10 `RigidBody3D` cases (bounce 0.45) thrown to the right of the aim, back in the pool after 2 s | 10 bodies at most | Effects Low throws none; a pump gun throws none |
| Hit sparks | `vfx_hit_spark.tscn`, pooled | 10 for 0.4 s | |
| Blood of a hit | `vfx_blood_hit.tscn`, pooled: flies away from where the shot came from (`VFXBurst.aim`) | 12 for 0.45 s | |
| Blood of a death | `vfx_blood.tscn`, pooled | 28 for 0.6 s | |
| Dust motes in the beams | `scripts/effects/dust_motes.gd` (a child of the district's StreetProps): 4 emitters of 14 under the lit lamps nearest to the player, within 28 m | 56 | Effects Low draws none; a dark district has no lit lamp |
| Manhole steam | `scripts/world/manhole.gd`: a loop of 14 particles above the cover | 14 per manhole | |
| Rain on the lens | `scripts/effects/rain_lens.gd` (a screen shader, a copy of the frame) | 0 particles | Ultra tier only, rain 0.5 or more, never with Motion Comfort |

The pool keeps at most 6 bursts of one scene (`MAX_PER_SCENE`): 6 x (28 + 12 + 10 + 8) = 348 particles, and the world's own emitters add about 140 in the
closeout world. The first cap was 24 per scene (24 x 58 = 1,392 at the worst), over both bounds.

Not built (and why): god-rays through windows and volumetric fog need the Forward+ renderer; the game runs `gl_compatibility` (project.godot), and a fake
shaft of additive quads in front of every lit window would be a garish draw-call cost for a phone (`docs/DISTRICT_SIGNATURES.md` lists it as an owner decision).
