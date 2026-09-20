# Music recipe — owner checklist (from docs/MUSIC_SPEC.md, 2026-09-21)

Every Suno/Udio prompt `docs/MUSIC_SPEC.md` specifies, extracted into one
ordered list to paste one-by-one. Custom mode, **Instrumental ON**. Suno will
not hit the exact duration/BPM/key — that's expected (§0 of MUSIC_SPEC.md).

**After every generation, same post-production pass (do this every time,
not just once):** trim to the target loop length at a zero crossing in a
DAW → apply 3 ms edge fades → loudnorm to the house law below → export
OGG q4 mono 44.1 kHz (WAV only where the target filename below says `.wav`)
→ save to the exact path in column 2 → log in `docs/ASSET_LICENSES.md` →
verify per `docs/CERT_AUDIO.md`. Regenerate until a take trims clean —
don't ship a take that needs the loop seam forced.

**House law:** beds/music −18 LUFS integrated, TP ≤ −1.5 dBFS. Stingers/SFX
−14 LUFS integrated, TP ≤ −1.5 dBFS.

## Ordered list — 19 tracks

| # | Target file | Loop length | Prompt |
|---|---|---|---|
| 1 | `music/music_menu_dark.ogg` (REPLACE — retire `abandoned_hallways.mp3` from MENU once this lands) | 120.000 s | `Instrumental dark ambient nocturne, 66 BPM, D minor, 4/4. A lonely felt piano plays a sparse six-note hook over a warm analog pad and a deep sub drone; soft tape hiss and distant night-city air. Melancholic, suspended, solitary, nocturnal, quietly hopeful. Cold darkness with one warm brass-lit glow. No vocals, no drums, seamless loop.` |
| 2 | `music/suburbs.ogg` (NEW) | 37.333 s (14 bars @ 90 BPM) | `Instrumental ambient theme, 90 BPM, C pentatonic, 4/4. Gentle generative pad arpeggio like a music box remembered from childhood, warm tone over a cold low drone. Wistful, homespun, muted, open, unguarded. Night suburb with one amber streetlight. No vocals, no drums, seamless loop.` |
| 3 | `music/school.ogg` (NEW) | 33.600 s (14 bars @ 100 BPM) | `Instrumental ambient theme, 100 BPM, E minor-major ambiguity, 4/4, long hall reverb. Glassy pad ostinato like a distant music classroom, cold institutional air. Fluorescent, nostalgic-broken, austere, echoey, cold. No vocals, no percussion, seamless loop.` |
| 4 | `music/hospital.ogg` (NEW) | 40.000 s (10 bars @ 60 BPM) | `Instrumental ambient theme, 60 BPM, whole-tone scale on F#, 4/4. Weightless floating pads that never resolve, clinical hum, faint monitor blip. Adrift, calm-sick, antiseptic, hollow, wrong. A hospital that must never feel like home. No vocals, no percussion, seamless loop.` |
| 5 | `music/gas_station.ogg` (NEW) | 34.909 s (16 bars @ 110 BPM) | `Instrumental ambient theme, 110 BPM, E blues, 4/4. Muted bluesy pad licks over an electrical hum, idle forecourt energy, ember-lit darkness. Roadside, restless, oily, electric, lonely. No vocals, no drums, seamless loop.` |
| 6 | `music/police.ogg` (NEW) | 28.000 s (14 bars @ 120 BPM) | `Instrumental ambient theme, 120 BPM, F minor, 4/4. Terse staccato pads and a quiet ticking pulse, indigo-cold authority, surveillance stillness. Procedural, restrained, hard, grim, airless. No vocals, no drums, seamless loop.` |
| 7 | `music/warehouses.ogg` (NEW) | 38.400 s (12 bars @ 75 BPM) | `Instrumental ambient theme, 75 BPM, C dorian, 4/4. Low drifting dorian pads with distant chain-clank ghosts in cavernous reverb, fog-softened edges. Cavernous, patient, foggy, metallic, minor-hopeful. No vocals, no drums, seamless loop.` |
| 8 | `music/substation.ogg` (NEW) | 33.600 s (14 bars @ 100 BPM) | `Instrumental ambient theme, 100 BPM, D phrygian dominant, 4/4. Nervous ostinato under a high voltage whine, arc-crackle texture, pale desaturated air. Energized, alien, crackling, cold, watchful. No vocals, no drums, seamless loop.` |
| 9 | `music/power_station.ogg` (NEW) | 32.000 s (14 bars @ 105 BPM) | `Instrumental ambient theme, 105 BPM, G mixolydian, 4/4. Broad resolute pads over a monumental generator thrum, the city's dead heart still charged. Charged, humming, finale-facing, monumental, resolute. No vocals, no drums, seamless loop.` |
| 10 | `music/layer_threat_low.ogg` (only if forced re-render — currently SHIPPED/certified) | 60.000 s | `Instrumental suspense stem, 70 BPM, D minor drone, seamless 60-second loop. Almost still: low drone, faint irregular sub throb, cold dark air. Watchful, creeping, uneasy, patient, quiet dread. Designed to layer under other stems. No vocals, no drums, no melody.` |
| 11 | `music/layer_threat_high.ogg` (only if forced re-render) | 60.000 s | `Instrumental tension stem, 100 BPM, D minor, seamless 60-second loop. Tight muted pulse like an accelerating heart, whispering noise sweeps, dissonant cluster pad. Hunted, anxious, closing-in, cold sweat, alert. Stackable stem. No vocals, no drums, no lead.` |
| 12 | `music/layer_action.ogg` (only if forced re-render) | 60.000 s | `Instrumental action stem, 140 BPM, D minor, seamless 60-second loop. Driving distorted bass, urgent metallic percussion, siren-like synth stabs. Adrenaline, panic, pursuit, violent, desperate. Stackable combat stem. No vocals, no melodic lead.` |
| 13 | `music/music_boss_dark_p1.ogg` (NEW) | 45.000 s | `Instrumental boss tension loop, 80 BPM, D minor, 4/4, seamless 45-second loop. Low sustained cello-like drone, muted heartbeat pulse, airy noise swells, no melody. Coiled, patient, predatory, subterranean, clinical. The thing in the dark has noticed you. No vocals, no drums.` |
| 14 | `music/music_boss_dark_p2.ogg` (NEW) | 45.000 s | `Instrumental boss escalation loop, 100 BPM, D phrygian dominant, 4/4, seamless 45-second loop. Pulsing distorted bass ostinato, dissonant string-like stabs, metallic industrial hits, rising filter tension. Menacing, urgent, industrial, relentless, bared teeth. No vocals, no lead melody.` |
| 15 | `music/music_boss_dark_p3.ogg` (NEW) | 45.000 s | `Instrumental final boss loop, 120 BPM, G mixolydian over a low G pedal, 4/4, seamless 45-second loop. Aggressive industrial percussion, brass-like synth swells, sustained open fifths, sirens of feedback. Desperate, colossal, final, defiant, catastrophic. No vocals.` |
| 16 | `ui/ui_district_restored_sting.ogg` (NEW) | 2.000 s, one-shot | `Instrumental two-second sting: a low electrical hum resolves upward into a warm brass perfect fifth, like a streetlight igniting, ending on a soft click of a breaker. Relief, warming, earned, quiet triumph. No vocals, no percussion.` |
| 17 | `music/cue_death.ogg` (NEW) | 8.000 s, one-shot, zero-ended | `Instrumental eight-second death cue, one-shot. A low drone sinks a fifth, a failing-streetlight flicker of sound, then everything dies to one dark soft tail. Extinguished, sinking, cold, final, merciful. Zero-ended silence. No vocals, no percussion.` |
| 18 | `sfx/ui_xp_tick.wav` (NEW) | 0.060 s, one-shot | `Instrumental 60-millisecond UI tick: one soft muted felt-piano note, low-middle register, dry, barely there. No reverb, no vocals.` |
| 19 | `sfx/ui_heal_soft.wav` (NEW) | 0.300 s, one-shot | `Instrumental 300-millisecond heal sound: two warm soft synth notes a third apart, rising, like a candle relit in a dark room. Gentle, relieved, dark-warm, quiet. Not cheerful. No vocals.` |

## Not on this list, and why

- **The 22 district ambience beds** (`ambience/districts/*_dark.ogg` /
  `*_lit.ogg`) are already shipped and certified — MUSIC_SPEC.md only
  gives a re-render template for them ("use only if a bed fails re-cert"),
  not a ready prompt. If one ever needs regenerating, the template and the
  11 per-district character sentences are in MUSIC_SPEC.md §b — swap the
  bracketed fields for the failing district's row.
- **`music/residential.wav`, `music/park.wav`, `music/industrial.wav`,
  `music/music_boss_dark.wav`** are already shipped and just need
  ratification (no new render).
- **`music/music_combat.ogg` / `music/music_battle.wav`** stay as-is (a
  documented variant pool, not a gap).

## After all 19 land

1. Retire `music/abandoned_hallways.mp3` and `_alt.mp3` from the shipped
   tree (keep only if reused as a school/hospital ambience source class per
   MUSIC_SPEC.md §a).
2. Retire `music/music_ambient_dark.wav` (substation/power_station
   fallback) once #8 and #9 land.
3. Re-run `docs/CERT_AUDIO.md`'s certification pass and
   `docs/AUDIO_MIX_AUDIT.md`'s loudness normalization on the whole
   `music/` class (that pass still needs real ears — not part of this
   list, see AUDIO_MIX_AUDIT.md §a).
