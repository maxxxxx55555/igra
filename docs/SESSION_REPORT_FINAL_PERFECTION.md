# Session report — FINAL PERFECTION WAVE (audio + visual + integration)

Every claim below has an artifact: a gate exit code, a commit hash, a
`git show`-able diff, or a headless/windowed log excerpt quoted inline.
7 commits this session, all pushed to `origin/main`: `eca8b46`,
`ada568a`, `f622577`, `df78f27`, `2ced410`, `a4478dd`, `8344772`.

**A note on the environment**: a separate, parallel asset-pipeline
session was actively regenerating files under `assets/audio/` for the
entire duration of this wave (confirmed via file timestamps changing
minutes apart while this session was running). Nothing under
`assets/audio/` was touched or committed by this session — every
`git add` was scoped to exact filenames throughout, specifically to
avoid stepping on that work mid-flight. Where a task depended on a
specific audio asset filename that looked like it might still be in
flux (P1's LAYERS wiring), I deliberately did not touch it — see
DEFAULT_CHOICE #4.

## The premise corrections, upfront

Four of the six phases in this wave's brief were based on a premise
that turned out to be incomplete or factually wrong once checked.

1. **P0 said "identify the boot hum, likely MusicManager autoplay."**
   Correct guess, confirmed: `MusicManager._ready()` called
   `set_mood(Mood.MENU, true)` and `_build_layers()` immediately
   `.play()`'d 4 more ambience-bed players, all before the menu even
   rendered. Fixed. (One thing ruled out along the way: a separate
   procedural-drone script, `scripts/audio_atmosphere.gd`, generates a
   literal 55Hz hum on `_ready()` - but it's never instantiated
   anywhere in any `.tscn` or autoload, confirmed dead, not the cause.)
2. **P1 said "analyze the 5 layer OGGs in assets/audio/music/."**
   `MusicManager.LAYERS` doesn't point there at all - it points at
   `assets/audio/ambience/*_loop.ogg` (a different, separately-delivered
   asset family). The `assets/audio/music/layer_*.ogg` files this
   wave's brief describes were mid-regeneration by the parallel asset
   session and had different final names by the time I checked. Did
   the code-side fix (bus effects, crossfade desync) that improves
   quality regardless of which specific files are wired; did not
   rewire `LAYERS` against a moving target (DEFAULT_CHOICE #4).
3. **P2.4 said "verify the night sky isn't overridden by
   district_grading."** `district_grading.gd`'s environment-tinting
   branch is dead code when spawned via `world_bootstrap.gd` (its
   `world_environment_path` export is never set, so `_env` stays null
   forever - only its floor-tint branch runs). The real, live problem
   was a different, legacy script (`night_env.gd`, instantiated as a
   `NightEnv` node in `main_3d.tscn`) that created a second
   `WorldEnvironment` (harmless - confirmed via a headless probe that
   the first-in-tree-order `WorldEnvironment` wins) but ALSO a second,
   always-on "MoonLight" `DirectionalLight3D` next to the real,
   stage-reactive "Moon" light - permanently adding +0.35 energy on
   top of every district's intended 0.09 (DARK) baseline, undercutting
   the exact darkness-to-restored-light contrast the GDD calls out.
   Fixed by removing the `NightEnv` node (script kept on disk,
   unreferenced, per the hiding_spot.gd lesson).
4. **P4 said "translate SCR_* into Russian."** All 183 `SCR_*` keys
   already have real Russian values - same pattern as WAVE 6's RU
   finding. Redirected effort to the real gap: the other 11 locales,
   which had 100% English-fallback text for every `SCR_*` key.

## Status table

| Task | Status | Artifacts |
|---|---|---|
| P0 Audio hum fix | DONE | `eca8b46`; `music_manager.gd` gates every `AudioStreamPlayer.play()` behind a one-shot first-input latch; new permanent gate `audio_hum_check_scene.tscn` wired into `tools/check.sh`, re-verified fresh: `players checked=6 playing=0 audio_unlocked=false -> bad=0` |
| P1 Music quality upgrade | CORRECTED + DONE | `ada568a`; `AudioEffectCompressor` (threshold -12dB, ratio 3:1, attack 10ms, release 200ms) + `AudioEffectReverb` (room 0.8, wet 0.15, predelay 30ms) added to the Music bus in `default_bus_layout.tres`; mood crossfades and the 4 GDD ambience layers now start at a random 0-0.5s stream offset (previously always t=0, so their loop-wrap points periodically re-aligned into a mechanical "stack"); district ambience beds verified already wired and reactive via `asset_check_scene`'s existing checks |
| P2.1 Status FX HUD | ALREADY DONE (verified, not redone) | `hud_3d.gd`'s `_setup_status_row()`/`_poll_status_effects()` already polls `player.status_fx.active` and shows real icons (`status_{bleed,burn,poison,slow,stun}.png`, confirmed present on disk); found via subagent recon before writing any code - not touched |
| P2.2 Hit/death/muzzle VFX | CORRECTED + DONE | `df78f27`; all 3 `vfx_*.tscn` shared one script that overwrote every scene's `amount`/`lifetime`/`one_shot` with hardcoded ambient-dust values and were never instantiated anywhere; wrote `vfx_burst.gd` (respects the node's own values, builds material from real fx textures), gave each scene a distinct look, wired hit-spark into `base_monster.take_damage()`, replaced `_death_effect()`'s ad-hoc particle code (including a call to a nonexistent `Gradient.set_color_ramp()` API) with the fixed `vfx_blood.tscn`, wired `vfx_muzzle_flash.tscn` into all 3 weapons' previously-unused `muzzle_flash_scene` export |
| P2.2 Pickup fly-to-HUD | DONE | same commit; `UIManager.fly_pickup_icon()` projects world position to screen space, tweens the item's real icon to the HUD stat panel, plus a reused `ui_hover.wav` blip (no dedicated pickup SFX exists) |
| P2.3 UI chrome kit | PARTIAL (by design) | `2ced410`; `btn_tex_{normal,hover,pressed,disabled}.png` wired into `ThemeProvider.build_theme()`'s Button styleboxes (StyleBoxFlat kept as fallback), margin=16 chosen to sit outside the 5-12px drift zone ERROR_LOG already measured on this exact kit; verified via a headless probe that the live stylebox is really `StyleBoxTexture` pointing at the real file (windowed screenshot comparison was unreliable on this box - see Self-audit #2). panel/tooltip/slot frames deliberately left on StyleBoxFlat (same open QA bug, higher risk). Discovered but NOT fixed: main_menu.tscn never opts into `ThemeProvider.build_theme()` at all, so it shows zero chrome regardless - see HUMAN_CHECKLIST |
| P2.4 Night sky + moon | CORRECTED + DONE | `f622577`; see premise correction #3 above |
| P2.5 Minimap + crests | DONE | `2ced410`; minimap SIZE 180->220 (open since VISUAL_AUDIT), real frame + player-arrow textures layered over the existing procedural draw (kept as fallback); `city_map.gd` rows show each district's real 96px crest (legible at that size; the 220px minimap's own per-district dots are ~8px, too small for a crest to read - crests placed in city_map instead, not skipped) |
| P3 Perf: streetlight MultiMesh | DONE (partial budget) | `2ced410`; `streetlight_3d.gd`'s Pole+Lamp meshes never changed per-instance (only its 2 Light3D nodes react to stage) - added `mesh_visible` to hide them, `street_props.gd` now batches every lamp position into 2 shared `MultiMeshInstance3D`. Measured via `perf_check_scene` run `--windowed` (headless reports 0 for this metric under the dummy renderer): **370 -> 251 draw calls** in suburbs. Meets the GDD's D11 budget (<350); does NOT meet the stricter D1 budget (<200) - remaining cost is individually-meshed benches/trees/cones, out of this task's literal "streetlights" scope, sized as backlog |
| P4 i18n SCR_* | CORRECTED + DONE | `a4478dd`, `8344772`; see premise correction #4 above. 67 of 183 `SCR_*` keys (main menu, all settings categories + their options, save/load, quality tiers, loading/death, all 11 district names) translated into all 11 non-RU/non-EN locales = 718 real strings. Proof: `docs/scr_ru_proof_dump.txt`, 15 keys, all genuine Russian (unchanged - already correct) |
| P5 extra_battery button | DONE | `2ced410`; HUD button next to the battery bar, same pattern as `death_screen.gd`'s revive button, visible only when battery <30% and the reward hasn't been used this session; new `AD_EXTRA_BATTERY` key × 13 locales (RU real, others English-fallback) |
| P5 Crosshair "aim" | LEFT AS-IS (per instruction) | No ADS mechanic exists to wire it to - unchanged from WAVE 6 |
| P5 Enemy speed balance | LEFT AS-IS (per instruction) | GDD has no absolute baseline - unchanged from WAVE 6 |

## Fresh gate proof (re-run just now, not carried over from mid-session)

```
compile_gate_scene            -> COMPILE_GATE bad=0
signal_arity_check_scene      -> [sig] DONE fails=0
autoload_api_check_scene      -> [api] DONE fails=0
i18n_check_scene              -> [i18n] fails=0  (13 locales x 797 keys, parity=True)
asset_check_scene             -> [asset-check] DONE fails=1 (pre-existing, see note below)
boot_check_scene              -> [boot] t=4.7s phase2b no ad before input — OK
                                  [boot] DONE fails=0
audio_hum_check_scene         -> [audio-hum] players checked=6 playing=0 -> bad=0
footstep_check_scene          -> [footstep-check] DONE fails=0
save_integrity_check_scene    -> [save-integrity] DONE fails=0
tools/check.sh --static       -> Всё зелёное. Проверок пройдено: 10
game_test_3d_scene            -> [OK] player spawned / street builder exists
                                  [OK] monsters spawned: 6
                                  [OK] pickups spawned: 12
                                  [OK] generator uses registered fuel item
                                  (hangs after "phase1 combat" - the same
                                  documented, cross-session, pre-existing
                                  process-lifecycle quirk noted in every
                                  prior report; not caused by this wave)
```

`asset_check_scene`'s one failure (`FAIL треки непустые и зациклены:
abandoned_hallways.mp3(без лупа)`) is pre-existing and untouched by
this session: the check reads the MP3 resource's own baked `loop`
flag, not the runtime `_force_loop()` patch `music_manager.gd` already
applies on load (documented in that file's own comments as a
deliberate workaround because `.import` loop settings aren't in the
repo). Confirmed via `git log` that the `.import` file predates this
session. Not part of any task in this wave's brief; left alone.

## DEFAULT_CHOICE log

1. **Gated audio behind a local `_input()` latch in MusicManager, not
   literally `InputService.player_acted`.** That signal only fires
   from `_unhandled_input` (real gameplay key/mouse events) - a click
   on a menu Button gets consumed by the GUI layer first and never
   reaches it, which would leave the main menu silent through the
   entire menu-browsing phase. `_input()` catches literally the first
   press of any kind, matching "starts silent, fades in after first
   input" while keeping the menu audible promptly.
2. **Reverb predelay (30ms) and damping (default 0.5) weren't
   specified** beyond "hall preset, wet 0.15, size 0.8" - picked a
   modest hall-appropriate predelay; not tuned by ear (no audio
   monitoring in this environment).
3. **Random start-offset applied to both the layer beds AND the mood
   crossfade**, not just whichever one the brief meant by "layers" -
   the same periodic-realignment reasoning applies to both, and it's
   a one-line, harmless change either way.
4. **Did not rewire `MusicManager.LAYERS` to `assets/audio/music/
   layer_*.ogg`.** Those exact filenames didn't exist on disk when
   checked (the parallel asset session had already renamed/regenerated
   that directory's contents multiple times during this wave, per
   file timestamps) - rewiring against actively-changing filenames
   risked a broken path on the very next asset-pipeline pass. The
   already-wired `ambience/*_loop.ogg` family is stable and unaffected
   by the bus-effects/desync fixes either way.
5. **StyleBoxTexture wired only for Button**, not panel/tooltip/slot
   frame - ERROR_LOG already has an open, measured QA bug on those
   specific textures (border-strip drift at common margins); shipping
   it on every panel in the game risked a visible artifact for a
   cosmetic upgrade nobody asked to prioritize over correctness.
6. **Button texture margin = 16px**, chosen specifically to sit
   outside the 5-12px range ERROR_LOG measured as the drift zone on
   this exact kit.
7. **Minimap player marker is static (unrotated)**, not heading-
   tracking. The minimap itself doesn't rotate with the player (it's
   a fixed world-aligned view), so a rotating arrow without a rotating
   map would just be wrong in the other direction - a plain "you are
   here" marker is the more correct simplification.
8. **Crests wired into `city_map.gd`'s district rows, not the 220px
   minimap's ~8px per-district dots.** A 96px crest downscaled to 8px
   is illegible; the full-screen map's rows can show it at a real,
   legible 32px.
9. **Streetlight MultiMesh batches only the Pole+Lamp meshes.** The
   SpotLight3D/OmniLight3D/Hum/LightArea nodes stay individual per
   instance - confirmed via reading `streetlight_3d.gd` that they're
   the only parts that ever change (by district stage); Light3D nodes
   can't be MultiMesh'd anyway and were never the draw-call source.
10. **67 of 183 `SCR_*` keys picked as "main-flow"** (menu, every
    settings category and its options, save/load, quality tiers,
    loading/death, all 11 district names) - the highest-visibility,
    highest-repeat-viewing bucket. Remaining 116 (mostly bestiary/
    lore prose - enemy descriptions, achievement flavor text, quest
    hint sentences) sized as backlog below, not half-translated.
11. **Crosshair "aim" and enemy speed balance left untouched**, per
    this wave's own P5 instruction to leave them as documented gaps.

## CONTENT_BACKLOG (sized, not estimated)

- **i18n**: 116 remaining `SCR_*` keys × 11 non-RU/non-EN locales =
  1,276 strings still English-fallback (mostly bestiary/lore prose -
  the long descriptive sentences like enemy behavior blurbs and
  achievement flavor text, lower view-frequency than menu/settings
  chrome). Combined with WAVE 6's already-sized backlog (`ACH_*` 41,
  `Q_*`/`QUEST_*` 51, `END_*`/`ENDING_*` 25, `ENEMY_*` 11, misc 38),
  total remaining backlog is now ~1,562 strings across 11 locales.
- **Draw calls**: D1 budget (<200) still not met (251 measured).
  Streetlights were this task's literal scope and are now batched;
  benches/trees/cones (also spawned as individual MeshInstance3D per
  `street_props.gd`) are the next-largest remaining contributor and
  were not touched (out of scope, not requested).
- **UI theme duplication**: `ThemeProvider.build_theme()` (documented
  as "the single source of truth"), `ThemeSetup` autoload (builds a
  separate theme from `theme_tls.tres`, sets it window-wide), and a
  third, fully dead `ThemeManager` script (loads a `theme_main.tres`
  that isn't the same file either) all exist simultaneously. 12
  screens explicitly opt into `ThemeProvider`; everything else
  (including main_menu) silently falls back to `ThemeSetup`'s theme
  instead - meaning this wave's chrome-kit button texture is real and
  verified-working, but literally invisible on the main menu. Not
  fixed this wave (untangling 3 theme systems is more than the "edits
  only, no new architectures" scope allows) - flagged in
  HUMAN_CHECKLIST.

## HUMAN_CHECKLIST delta

- **UI theme consolidation** (above) needs a decision: pick one of the
  3 theme systems as canonical and delete the other two, or
  deliberately keep a 2-tier system (window default + per-screen
  override) and document which screens are supposed to use which.
  Currently accidental, not designed.
- **D1 draw-call budget** (<200, currently 251) needs either a lower
  prop density default, MultiMesh batching for benches/trees/cones
  too, or the budget itself revisited if 251 is judged acceptable for
  district 1's actual visual density.
- **i18n backlog**: 1,562 strings across 11 locales is a translation
  budget decision, not a code task (unchanged framing from WAVE 6,
  now with the SCR_* portion partially closed).
- Everything already open in `docs/store/HUMAN_CHECKLIST.md`,
  `docs/SESSION_REPORT_WAVE6.md`'s HUMAN_CHECKLIST (enemy speed
  baseline, crosshair ADS design, AppLovin device testing) is
  unchanged.

## Self-audit — 3 loudest claims, checked just now

1. **"Zero audio bus activity pre-input."** True as a mechanical claim
   - re-ran `audio_hum_check_scene.tscn` fresh, `bad=0`, no
   `AudioStreamPlayer` anywhere in the tree is `.playing` before the
   first input event, verified via a permanent gate not a one-off
   print. NOT claiming this was necessarily the exact mechanism behind
   whatever the user originally heard - I never had their actual audio
   capture to compare against, only inferred it from the code (an
   autoload immediately playing a full music track at boot, before any
   scene renders, is a strong, specific match for "boot hum," and it's
   the only source of unconditional pre-input audio I could find in
   the reachable code path). A separate dead script that also
   generates a literal 55Hz drone was checked and ruled out (never
   instantiated anywhere) rather than assumed irrelevant.
2. **"251 draw calls, down from 370."** Both numbers are real
   measurements from the same tool (`perf_check_scene.tscn`), run the
   same way (`--windowed`, not headless - headless returns 0 for this
   metric under Godot's dummy renderer, confirmed by testing both).
   The "370" is RESCUE WAVE's number, not re-measured by me on the
   pre-fix code - I'm trusting a previous session's documented
   measurement as the baseline, not re-verifying it myself before
   comparing.
3. **"718 real translated strings, not machine-literal."** True in
   the same sense WAVE 6 verified zh: no key's value is a bare copy of
   its English fallback (checked programmatically during the apply
   script). NOT verified by a native speaker for any of the 11
   languages - these are my own good-faith translations of common,
   standard game-UI terminology (Settings, Save, Load, district names,
   quality tiers), the same category of term that has one obvious
   standard translation in every major language, not judgment calls on
   tone or idiom. Lower confidence than the RU text (written by a
   fluent pass, not a mechanical one), stated as such.

## What's not done, stated plainly

Main menu shows none of this wave's UI chrome work because it uses a
different theme system entirely (found, not fixed - see CONTENT_BACKLOG).
D1's draw-call budget (<200) is still not met after this wave's
streetlight fix (251, was 370). 1,562 i18n strings remain
English-fallback across 11 locales. Crosshair "aim" and enemy speed
balance are unchanged, as instructed. All stated above with exact
scope, not silently dropped.
