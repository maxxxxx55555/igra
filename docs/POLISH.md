# Polish (Session 23)

The micro-interactions of the directive's POL1, with what the code does now and the check that holds it. Reduce UI Motion switches the eased ones off (they
snap, as before); a number below is read from the running game (`CLOSEOUT_ONLY=s23`).

| Interaction | Before | Now | Check |
|---|---|---|---|
| Button press | The click and the hover were wired by hand in the main menu and the pause menu; the pulse had one caller | Every button, in every screen, presses to 0.95 and back over 0.1 s, plays the click and, on a hover, a tick (`scripts/systems/uisfx.gd`); a toggle is a button to the wiring | POL1 |
| Tab change | Silent | Plays the click | POL1 |
| Screen open | A screen built from a script slid in over 0.3 s | Unchanged | POL2 |
| Screen close | Hidden at once | A screen built from a script fades out over 0.15 s; it is closed for the logic at once and hidden when the fade ends; opened again during the fade it stays | POL2 |
| Screen built from a scene | Instant | Instant: it keeps its instant show and hide (`UIManager._animates`) | listed |
| Slider drag | Silent | Silent, by design: a drag crosses up to 100 steps and a tick per step would buzz | listed |
| Idle life | The audit found: streetlights flicker (`lamp_flicker`), the main menu title flickers, the walk sways the torso; rain, steam and dust motes are the world's. At rest the player's eye stood still | The first-person eye breathes at rest: 4 mm up and down, one breath in about 4 s, none with Motion Comfort (`camera_follow_3d.gd` `BREATH_M`) | POL3 |

## Kept and reverted

Kept 8 (the press pulse on every button, the tab click, the fade-out, the proportional shake, the landing, the walk easing, the recoil kick, the idle breath); reverted 2 before they were committed:
a hover swell of my own (`ThemeSetup` already grows a hovered button by 1.05, so mine doubled it) and a restyle of the buttons in place (cut at the ponytail review).

## Gaps, listed and not built

A hand-drawn breathing animation for the character, an animated cursor and a haptic on every press are art or device tasks; the phone's haptics exist in the touch controls already.
