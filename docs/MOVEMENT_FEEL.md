# Movement feel (Session 23)

What the player's body and the first-person camera do. Checks MOVE1, JUICE1 to JUICE4 and POL3 (`CLOSEOUT_ONLY=s23`) read each number below from the running game.

| Quantity | Value | Where |
|---|---|---|
| Walk speed, run speed, stealth speed | from `PlayerStats` (3.0, 4.8, 1.6 m/s) | `player_stats.gd` |
| Acceleration to speed | 0.12 s (0.42 m/s after the first physics step of 2.93) | `player_3d.gd` `ACCEL_SEC` |
| Deceleration to rest | 0.08 s (1.68 m/s after the first step of letting go, 0 after ten) | `player_3d.gd` `DECEL_SEC` |
| Jump | `jump_velocity` 4.5 m/s, coyote time 0.1 s, jump buffer 0.1 s | `player_3d.gd` |
| Camera follow | the eye lerps to the body at 15 per second | `camera_follow_3d.gd` `fps_follow_speed` |
| Sprint | head bob 0.1 m at 8 rad/s, view opened 5 degrees | `camera_follow_3d.gd` |
| Idle breath | the eye moves 4 mm up and down, one breath in about 4 s; none with Motion Comfort | `camera_follow_3d.gd` `BREATH_M` |
| Landing after 0.25 s or more in the air | the eye dips 0.08 m and the view opens 2 degrees, both gone in 0.2 s | `camera_follow_3d.gd` `LAND_*` |
| Shot | kick 0.04 rad per unit of recoil, settles at 9 per second | `camera_follow_3d.gd` `RECOIL_*` |
| Hit-stop | melee hit 50 ms, the last hit of a combo 80 ms, the boss's hits 80 ms; time at a quarter speed; gives back the scale it found | `wow_director.gd`, `player_3d.gd` |
| Screen shake | 0.016 m at full trauma, in proportion to the trauma: 3.9 px of a 1080p frame at 5 m with the interior's 48 degree view (3.3 px at the 55 degrees of the street, 2.1 px at the 80 degrees of the check's camera); a damage hit (0.3) 1.2 px at 48 degrees | `screen_shake.gd` |

Motion Comfort, Reduce Screen Shake, Reduce UI Motion and Reduce Time Effects switch the head bob, the view punches, the landing dip, the recoil kick, the shake
and the hit-stop off (`docs/A11Y_PLAN.md`).

## What changed and why

- **The walk eased.** An idle player had its horizontal velocity set to zero by a line of its own, before the code that moves it; and the walk set the velocity to
  the full speed at once. The stop line is gone and the walk takes 0.12 s to reach its speed and 0.08 s to stop (the air and a dodge keep their own rules). The
  rate is taken from the faster of the current speed and the walking speed: in the idle state the speed of the state is 0, which would have given a stop that never ends.
- **Hit-stop gave back 1.0.** It ended with `Engine.time_scale = 1.0`: a run at 4x (the QA runs) lost its speed at the first boss hit. It gives back the value it found.
- **The shake was 0.5 m and squared.** At full trauma the camera moved half a metre (64 px at 5 m in an 80 degree view); a damage hit (0.3 trauma) moved it 5.8 px and the cascade (0.55) 19 px.
  The first fix, 0.019 m with the same squared curve, put the full trauma under 4 px and left a damage hit at 0.2 px, a feedback that was gone. It is 0.016 m in proportion to the
  trauma now: 3.9 px at full trauma in the narrowest view the camera uses, 1.2 px for a damage hit, 1.4 px for an explosion (0.35), 2.1 px for the cascade (CORRECTION_LOG 214).
- **A landing had no feedback.** It does now (above), with the same gates.
