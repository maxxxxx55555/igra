# Audio mix report — MEGA FINAL PASS (2026-09-13)

Independent review agent, measurements taken with `ffmpeg` (`ebur128`, `volumedetect`)
against the files on disk. Nothing here is taken from a certificate; where a number could
not be measured it is marked UNVERIFIED rather than estimated.

## Bus tree (`default_bus_layout.tres`)

| Bus | Parent | volume_db | Effects |
|---|---|---|---|
| Master | — | 0.0 | none |
| Music | Master | 0.0 | Compressor (thr −12 dB, 3:1, atk 10 ms, rel 200 ms) + Reverb (predelay 30 ms, room 0.8, wet 0.15) |
| SFX | Master | 0.0 | none |
| Voice | Master | 0.0 | none |
| Ambient | Master | 0.0 | none |
| UI | Master | 0.0 | none (dry — confirmed) |

No bus carries a volume offset, so there is no systemic loudness bias between categories.

## Measurements

| File | Category | Integrated LUFS | RMS (mean_volume) | Peak dBFS |
|---|---|---|---|---|
| ui_menu_click.ogg | UI sting | UNVERIFIED (0.103 s < EBU 400 ms block) | −28.1 | −6.1 |
| ui_secret_discovery_sting.ogg | UI sting | UNVERIFIED (0.393 s) | −24.7 | −11.2 |
| ui_achievement_sting.ogg | UI sting | −22.5 | −22.4 | −11.2 |
| ui_boss_sting.ogg | UI sting | −24.2 | −24.2 | −11.2 |
| ui_daily_complete_sting.ogg | UI sting | −24.2 | −24.1 | −11.1 |
| ui_ending_sting.ogg | UI sting | −23.0 | −23.3 | −11.1 |
| ui_streak_milestone_sting.ogg | UI sting | −23.0 | −23.5 | −11.1 |
| music_ambient.wav | Music bed | −18.1 | −14.8 | −4.7 |
| music_battle.wav | Music bed | −17.8 | −13.9 | −2.0 |
| music_tension / boss_dark / victory | Music bed | −16.7…−17.9 | ≈ −14 | −1.4…−5.1 |
| suburbs_dark.ogg | Ambience bed | −16.6 | — | −5.8 |

## Findings and what was done

1. **P0 — stingers were 8–14 dB below the bed, not 6–10 dB above it.** Stinger RMS
   −22…−25 dB against bed RMS −14…−15 dB, played at unity gain: they would have been
   masked under any active music. **Fixed** — `UISFX.play_ui()` now applies +9 dB, and
   +4 dB for `menu_click` whose peak already sits at −6.1 dBFS.
   **The certificate's stated target is not reachable this way and was not claimed as
   met**: hitting 6 dB over the bed needs ≈ +15 dB against files peaking at −11 dBFS,
   which clips. Closing that gap properly needs either remastered sources or music
   ducking. Logged in `docs/KNOWN_ISSUES.md`.
2. **P1 — LUFS is meaningless for two of the files.** `ui_menu_click` and
   `ui_secret_discovery_sting` both read −70 LUFS integrated: an EBU R128 gating artifact
   for sub-400 ms material, not a real level. Use RMS/peak for those two.
3. **P1 — `game_won` stacked three cues.** `music_manager` fires `music_victory` *and*
   `cue_victory` on that signal, both on Music through the compressor and reverb, while
   the ending sting played on UI underneath. **Fixed** — the ending sting moved to
   `EndingsManager.ending_reached`, which also covers the `dark` / `survivor` death
   endings where no victory music plays and the sting is the only audio marker.
4. **P1 — a silent regression, self-inflicted.** Guarding `audio_manager`'s procedural
   click behind `_has_ui_sting("menu_click")` silenced screen navigation entirely,
   because the real click was wired only to direct button presses, never to
   `ui_screen_opened`. **Fixed** — reconnected in `UISFX._ready()`.
5. **P2 — no ducking exists anywhere in the project.** No script attenuates Music for
   dialogue or radio. `CutsceneManager.cutscene_started/ended` exist and nothing
   subscribes to them for audio. Attach point when this is wanted:
   `MusicDirector._ready()` in `scripts/systems/music_manager.gd`. Not built — a wiring
   pass is the wrong place to introduce a new mix system.
6. **P2 — the Ambient bus is cosmetic for the beds.** `music_manager` routes every
   district ambience bed to **Music**, not Ambient; Ambient carries only detail one-shots.
   So the settings screen's Ambient slider does not move the beds a player actually hears.
   Not changed: re-routing beds mid-release risks the whole mix. Logged.
7. **PASS — routing is correct.** All seven stingers, boss and ending included, play on
   the dry `UI` bus and never on Music.

## Verdict

Shippable after items 1, 3 and 4, which are fixed in commit `a406075`. Items 5 and 6 are
real but are deliberate non-goals for this pass and are recorded in `KNOWN_ISSUES.md`
rather than silently carried.
