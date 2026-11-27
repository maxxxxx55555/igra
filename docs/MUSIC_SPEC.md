# MUSIC_SPEC — The Last Streetlight (music direction, 2026-09-20)

Owner: audio director (this doc only). Companion audit of the shipped tree:
`docs/AUDIO_MIX_AUDIT.md`. Scope: music direction for Suno/Udio or a contracted
composer. No audio binaries here; every row is executable as-is.

Canon read: `docs/VISUAL_PASS.md` §3 (per-district light), `docs/VISUAL_AUDIO_SPEC.md` §1
(per-district mood reads), `docs/GAMEFEEL_SPEC.md` (juice events), `docs/STYLE_GUIDE.md` §1/§5
(temperature rule; audio style), `docs/STORE_KIT.md` ("5 adaptive music layers" claim),
`data/i18n/en.json` (11 district names, 5 endings). The game is nocturnal stealth-horror:
**cold darkness vs warm light — muted, atmospheric, never cheerful/upbeat. No vocals anywhere.**

## 0. House law (from shipped code/certs — do not renegotiate)

| Law | Value | Source |
|---|---|---|
| Ambience/music beds loudness | −18 LUFS int., TP ≤ −1.5 dBFS | README, AUDIO_COVERAGE |
| Stingers/SFX loudness | −14 LUFS int., TP ≤ −1.5 dBFS | AUDIO_LOUDNESS.md |
| Bed format | OGG q4, mono, 44.1 kHz, seamless loop, 3 ms zero edges | README |
| Mood crossfade | 2.2 s (FADE_TIME), work level −8 dB, mute −60 dB | music_manager.gd L118–120 |
| Layer mix | −12 dB per layer, 1.5 s lerp, eval every 0.5 s | music_manager.gd L116–121 |
| Combat state | tension < 22 m, battle < 9 m, calm hold 6 s | music_manager.gd L122–124 |
| Death/ending fade | 0.6 s slow fade (solemn, no panel motion) | VISUAL_PASS §6 |
| Wow cues | one-shots, zero-ended, never looped | music_manager.gd `_play_wow_cue` |

**Status legend:** `SHIPPED` = file on disk + wired, parameters ratified here.
`REPLACE` = new binary replaces file at same path. `NEW` = new file; name follows the
existing family convention (no invented styles).

**Suno/Udio discipline (owner workflow):** paste prompt into Custom mode, Instrumental ON.
AI will not hit exact duration/BPM/key — after generation: trim to the exact loop length in
a DAW at a zero crossing, apply 3 ms edge fades, loudnorm to house law, export OGG q4 mono
44.1 kHz, log in `docs/ASSET_LICENSES.md`, verify per `docs/CERT_AUDIO.md`. Regenerate until
a take trims clean. Loop points below are post-production targets, not model output.

---

## a) Main menu theme — nocturnal, solitary, hook

| file | scene | dur | BPM | key | sig | mood (5) | instrumentation | layers | loop-pts | refs | fade |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `music/music_menu_dark.ogg` **REPLACE** (generated 2026-09 by `_gen_music.gd` but never shipped; MENU currently falls back to `abandoned_hallways.mp3`) | main menu / credits | 120.000 s | 66 | D aeolian | 4/4 | nocturnal, solitary, wistful, suspended, quietly hopeful | felt piano hook (sparse 6-note motif), warm brass-toned analog pad, sub drone, tape hiss, night air | single bed | 0.000→120.000 | Darkwood; Kentucky Route Zero; Silent Hill 2 | 2.2 s crossfade in; 2.2 s out on menu→loading (0.35 s screen fade runs in parallel) |

Retire `music/abandoned_hallways.mp3` from MENU (stays as school/hospital `_alt` source class).

Suno prompt (≤400 chars, custom/instrumental):

```
Instrumental dark ambient nocturne, 66 BPM, D minor, 4/4. A lonely felt piano plays a sparse six-note hook over a warm analog pad and a deep sub drone; soft tape hiss and distant night-city air. Melancholic, suspended, solitary, nocturnal, quietly hopeful. Cold darkness with one warm brass-lit glow. No vocals, no drums, seamless loop.
```

---

## b) One ambient bed per district (11 districts, dark + lit twins)

All 22 files below are **SHIPPED** and certified (36.000 s, −18 LUFS, TP ≤ −1.5, OGG q4 mono;
`industrial` twins are 33.994 s — deliberate byte-matched pair, see `docs/AUDIO_COVERAGE.md`
G2h). Loop 0.000→36.000 (industrial 0.000→33.994). Fade: dark↔lit swap = 2.2 s crossfade on
`district_stage_changed`; lit twin = same bed "re-voiced warmer" (STYLE_GUIDE §5 — same
material, warmer light). Refs rotate per row. Prompts are **re-render briefs — use only if a
bed fails re-cert**; the mood words are the district character contract from
VISUAL_AUDIO_SPEC §1 / VISUAL_PASS §3.

**Shared contract — applies to all 22 rows below** (one batch contract; per-row deltas in table):
duration 36.000 s (industrial pair 33.994 s); loop-pts 0.000→dur; BPM n/a / time-sig n/a
(non-metric seamless texture, no beat grid — this is what makes it a bed, not a theme);
key = district family root (frozen canon `tools/gen_audio.py`): suburbs C, residential D,
park C, school E, hospital F#, gas_station E, police F, warehouses C, industrial B♭,
substation D, power_station G; instrumentation = pure synth textures only (house rule: no
voices, no samples — `assets/audio/README.md`); dynamic layers = exactly two states (dark ↔
lit twin), no threat stacking inside a bed; fade = 2.2 s crossfade on dark→lit swap.

| district (i18n name) | dark bed | lit twin | character (canon) | mood (5) | refs |
|---|---|---|---|---|---|
| suburbs (Suburbs) | `ambience/districts/suburbs_dark.ogg` | `suburbs_lit.ogg` | amber `#f4a35d`; domestic warmth waiting to return | domestic, patient, lonely, amber-tinged, held-breath | Silent Hill 2; INSIDE; Darkwood |
| residential (Residential blocks) | `residential_dark.ogg` | `residential_lit.ogg` | twin of suburbs | domestic, hollow, remembered, amber-tinged, dormant | Silent Hill 2; INSIDE; Darkwood |
| park (Park) | `park_dark.ogg` | `park_lit.ogg` | `#f4e35d`; "the city's one living thing left" | organic, breathing, windswept, fragile, green-cold | INSIDE; Darkwood; Kentucky Route Zero |
| school (School) | `school_dark.ogg` | `school_lit.ogg` | gold `#f4c95d` = fluorescent-memory, institutional cold | institutional, fluorescent, vacant, chalk-dust, austere | Silent Hill 2; INSIDE; Darkwood |
| hospital (Hospital) | `hospital_dark.ogg` | `hospital_lit.ogg` | cyan `#5dc8f4`; clinical — must NEVER read as "home", no warmth | clinical, cyan-cold, antiseptic, hollow, watchful | SOMA; INSIDE; Alien: Isolation |
| gas_station (Gas station) | `gas_station_dark.ogg` | `gas_station_lit.ogg` | ember `#e85d3a`; electric, danger-adjacent, not cozy | electric, ember-lit, buzzing, roadside, ominous | Fallout (1997); Darkwood; INSIDE |
| police (Police station) | `police_dark.ogg` | `police_lit.ogg` | indigo `#5d5dc8`; authority-cold, restrained | indigo, authority-cold, procedural, airless, grim | Alien: Isolation; INSIDE; SOMA |
| warehouses (Warehouse complex) | `warehouses_dark.ogg` | `warehouses_lit.ogg` | ember + FOG; danger reads distant through fog | foggy, cavernous, distant-ominous, metallic, muted | Fallout (1997); Darkwood; INSIDE |
| industrial (Industrial zone) | `industrial_dark.ogg` (33.994 s) | `industrial_lit.ogg` | twin of warehouses + machinery silhouettes | mechanized, foggy, grinding, ember-lit, bleak | Fallout (1997); Darkwood; Alien: Isolation |
| substation (Substation) | `substation_dark.ogg` | `substation_lit.ogg` | pale `#f4f45d`; "the grid's nervous system", coldest | desaturated, nervous, humming, clinical, otherwhere | Fallout (1997); SOMA; INSIDE |
| power_station (Power station) | `power_station_dark.ogg` | `power_station_lit.ogg` | pale; finale presence through fog | monumental, charged, expectant, humming, final | Fallout (1997); SOMA; Alien: Isolation |

District-character prompt template (swap the bracketed fields per row above):

```
Instrumental dark ambient bed, seamless 36-second loop, no percussion. [CHARACTER SENTENCE]. Base is cold and [COLD COLOR WORD]; the only warmth is one distant [ACCENT]-colored glow. Textures only, no melody, no vocals. Muted, atmospheric, nocturnal.
```

Per-district character sentences:

- suburbs/residential: `A sleeping apartment district at night: low warm pad like remembered domestic life over a cold green-grey drone, faint sodium-lamp shimmer, far dogs and wind.`
- park: `An empty night park that still breathes: airy synth wind through bare trees, soft organic rustle, a faint yellow-green glow, the city's last living hum far away.`
- school: `A vacant school at night: cold blue-grey air, distant metallic flicker like dying fluorescent tubes, hollow corridors, a faint gold institutional glow.`
- hospital: `An abandoned hospital ward: clinical cyan air, empty echoing hum, metallic trickle, a monitor-like blip far away; deliberately un-homey, cold, antiseptic.`
- gas_station: `A dark highway forecourt: electrical buzz, low ember-orange glow of a canopy lamp, wind under a metal roof, idle danger in the air.`
- police: `A cold indigo authorities' building: restrained sodium flood hum, radio-static ghost, concrete corridor air, Watched feeling, no warmth.`
- warehouses: `Vast fog-bound warehouses: cavernous reverb tail, far metal creaks and chain clinks, an ember glow that stays distant through the fog.`
- industrial: `Sleeping machinery district: slow metallic grinding pad, steam-hiss texture, dense fog, ember silhouettes of dead cranes.`
- substation: `The grid's nervous system: pale desaturated transformer hum, high thin whine, arc-crackle ghosts, almost no chroma, airless.`
- power_station: `The city's dead heart, still charged: monumental low hum, huge transformer thrum through fog, pale light pressure, expectant and final.`

### b2) District music themes (music layer above the beds)

Canon scale/BPM/root per district are frozen in `tools/gen_audio.py` DISTRICTS — reuse them.
Today 4 files are shared across 8 districts (`music_manager.gd` AMBIENT_BY_DISTRICT); spec
below dedupes to **one theme per district**. Bar math: dur = bars×4×60/BPM. Format OGG q4
mono, loop whole file, −18 LUFS. Fade 2.2 s crossfade on `district_entered`.

| file | scene | dur | BPM | key (root/scale) | sig | mood (5) | instrumentation | layers | loop-pts | refs | fade | status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `music/suburbs.ogg` | Suburbs theme | 37.333 s (14 bars) | 90 | C4 pentatonic | 4/4 | wistful, homespun, muted, open, unguarded | generative pad arpeggio + soft drone | 1 | 0→37.333 | Kentucky Route Zero; Darkwood | 2.2 s x-fade | NEW |
| `music/school.ogg` | School theme | 33.600 s (14) | 100 | E4 major | 4/4 | fluorescent, nostalgic-broken, austere, echoey, cold | glassy pad ostinato, hall reverb | 1 | 0→33.600 | Silent Hill 2; INSIDE | 2.2 s | NEW |
| `music/hospital.ogg` | Hospital theme | 40.000 s (10) | 60 | F#3 whole-tone | 4/4 | clinical, adrift, weightless, wrong, calm-sick | floating whole-tone pads, no resolution | 1 | 0→40.000 | SOMA; Alien: Isolation | 2.2 s | NEW |
| `music/gas_station.ogg` | Gas station theme | 34.909 s (16) | 110 | E3 blues | 4/4 | roadside, restless, oily, electric, lonely | bluesy pad licks over hum, muted twang | 1 | 0→34.909 | Fallout (1997); Darkwood | 2.2 s | NEW |
| `music/police.ogg` | Police station theme | 28.000 s (14) | 120 | F3 minor | 4/4 | procedural, martial-restrained, surveillance, hard, grim | terse staccato pads, ticking pulse | 1 | 0→28.000 | Alien: Isolation; SOMA | 2.2 s | NEW |
| `music/warehouses.ogg` | Warehouse theme | 38.400 s (12) | 75 | C3 dorian | 4/4 | cavernous, foggy, patient, minor-hopeful, metallic | low dorian pad drift + distant clank ghosts | 1 | 0→38.400 | Fallout (1997); Darkwood | 2.2 s | NEW |
| `music/substation.ogg` | Substation theme | 33.600 s (14) | 100 | D3 phrygian dominant | 4/4 | nervous, energized, alien, crackling, cold | phrygian-dominant ostinato under HV whine | 1 | 0→33.600 | Fallout (1997); SOMA | 2.2 s | NEW |
| `music/power_station.ogg` | Power station theme | 32.000 s (14) | 105 | G3 mixolydian | 4/4 | monumental, charged, finale-facing, humming, resolute | broad mixolydian pads over generator thrum | 1 | 0→32.000 | Fallout (1997); Dead Space | 2.2 s | NEW |
| `music/residential.wav` | Residential theme | 42.000 s (14) | 80 | D4 major | 4/4 | bittersweet, domestic, gentle, muted, remembered | slow generative major pads | 1 | 0→42.000 | Silent Hill 2; Kentucky Route Zero | 2.2 s | SHIPPED (ratify) |
| `music/park.wav` | Park theme | 22.400 s | 75 | C4 lydian | 4/4 | airy, half-light, drifting, fragile, green | lydian shimmer pads | 1 | 0→22.400 | INSIDE; Kentucky Route Zero | 2.2 s | SHIPPED (ratify) |
| `music/industrial.wav` | Industrial theme | 24.000 s (12) | 85 | A#2 minor | 4/4 | grinding, bleak, heavy, foggy, relentless | minor drone + mechanical pulse | 1 | 0→24.000 | Fallout (1997); Darkwood | 2.2 s | SHIPPED (ratify) |
| `music/music_ambient_dark.wav` | substation+power_station fallback | 44.000 s | — | — | — | — | — | — | 0→44.000 | — | — | RETIRE after 2 NEW themes land (fallback stays until then) |

Suno prompts (one per NEW row; ≤400 chars, custom/instrumental):

```
suburbs.ogg — Instrumental ambient theme, 90 BPM, C pentatonic, 4/4. Gentle generative pad arpeggio like a music box remembered from childhood, warm tone over a cold low drone. Wistful, homespun, muted, open, unguarded. Night suburb with one amber streetlight. No vocals, no drums, seamless loop.
```

```
school.ogg — Instrumental ambient theme, 100 BPM, E minor-major ambiguity, 4/4, long hall reverb. Glassy pad ostinato like a distant music classroom, cold institutional air. Fluorescent, nostalgic-broken, austere, echoey, cold. No vocals, no percussion, seamless loop.
```

```
hospital.ogg — Instrumental ambient theme, 60 BPM, whole-tone scale on F#, 4/4. Weightless floating pads that never resolve, clinical hum, faint monitor blip. Adrift, calm-sick, antiseptic, hollow, wrong. A hospital that must never feel like home. No vocals, no percussion, seamless loop.
```

```
gas_station.ogg — Instrumental ambient theme, 110 BPM, E blues, 4/4. Muted bluesy pad licks over an electrical hum, idle forecourt energy, ember-lit darkness. Roadside, restless, oily, electric, lonely. No vocals, no drums, seamless loop.
```

```
police.ogg — Instrumental ambient theme, 120 BPM, F minor, 4/4. Terse staccato pads and a quiet ticking pulse, indigo-cold authority, surveillance stillness. Procedural, restrained, hard, grim, airless. No vocals, no drums, seamless loop.
```

```
warehouses.ogg — Instrumental ambient theme, 75 BPM, C dorian, 4/4. Low drifting dorian pads with distant chain-clank ghosts in cavernous reverb, fog-softened edges. Cavernous, patient, foggy, metallic, minor-hopeful. No vocals, no drums, seamless loop.
```

```
substation.ogg — Instrumental ambient theme, 100 BPM, D phrygian dominant, 4/4. Nervous ostinato under a high voltage whine, arc-crackle texture, pale desaturated air. Energized, alien, crackling, cold, watchful. No vocals, no drums, seamless loop.
```

```
power_station.ogg — Instrumental ambient theme, 105 BPM, G mixolydian, 4/4. Broad resolute pads over a monumental generator thrum, the city's dead heart still charged. Charged, humming, finale-facing, monumental, resolute. No vocals, no drums, seamless loop.
```

---

## c) Combat stinger layers (stackable low / medium / high)

All three SHIPPED, 60.000 s each, loop 0.000→60.000, mixed at −12 dB with 1.5 s lerp; layers
stack (mix, not crossfade); targets re-evaluated every 0.5 s; calm hold 6 s after last threat.
All D-centered so any stack stays consonant. Random start offset per layer is deliberate
(anti-LCM, music_manager P1.3) — keep on re-render.

| file | scene | dur | BPM | key | sig | mood (5) | instrumentation | layers | loop-pts | refs | fade | status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `music/layer_threat_low.ogg` | threat LOW (monster 9–22 m) | 60.000 s | 70 | D drone (min) | 4/4 | watchful, creeping, uneasy, quiet-dread, patient | near-still drone, irregular sub throb, dark air | stack L1 | 0→60.000 | Alien: Isolation; INSIDE | 1.5 s lerp in/out | SHIPPED |
| `music/layer_threat_high.ogg` | threat MEDIUM (monster < 9 m, no contact) | 60.000 s | 100 | D minor | 4/4 | hunted, anxious, closing-in, cold-sweat, alert | muted heart-pulse, whisper noise sweeps, cluster pad | stack L2 | 0→60.000 | Alien: Isolation; Dead Space | 1.5 s lerp | SHIPPED |
| `music/layer_action.ogg` | threat HIGH (combat contact) | 60.000 s | 140 | D minor | 4/4 | adrenal, panicked, pursued, violent, desperate | distorted bass drive, metallic percussion, siren stabs | stack L3 | 0→60.000 | Alien: Isolation; Dead Space | 1.5 s lerp | SHIPPED |
| `music/music_battle.wav` + `music/music_combat.ogg` | combat mood switch (BATTLE_VARIANTS, random pick) | 24.500 / 45.000 s | — | — | — | — | — | replaces melody bed under layers | looped by `_force_loop` | — | 2.2 s x-fade | SHIPPED (variant pool — keep, documented `BUGS_FOR_CLAUDE` #3) |

Prompts (use only on forced re-render; keep lengths exact):

```
layer_threat_low — Instrumental suspense stem, 70 BPM, D minor drone, seamless 60-second loop. Almost still: low drone, faint irregular sub throb, cold dark air. Watchful, creeping, uneasy, patient, quiet dread. Designed to layer under other stems. No vocals, no drums, no melody.
```

```
layer_threat_high — Instrumental tension stem, 100 BPM, D minor, seamless 60-second loop. Tight muted pulse like an accelerating heart, whispering noise sweeps, dissonant cluster pad. Hunted, anxious, closing-in, cold sweat, alert. Stackable stem. No vocals, no drums, no lead.
```

```
layer_action — Instrumental action stem, 140 BPM, D minor, seamless 60-second loop. Driving distorted bass, urgent metallic percussion, siren-like synth stabs. Adrenaline, panic, pursuit, violent, desperate. Stackable combat stem. No vocals, no melodic lead.
```

---

## d) Boss phase themes (P1 tension, P2 escalation, P3 final)

Today one loop (`music/music_boss_dark.wav`, 30.500 s, SHIPPED — ratify as intro/underlay)
covers all three phases; `boss_3d.gd` has a real `Phase {P1, P2, P3}` state machine. Spec
three phase loops in the `music_boss_dark_*` family. Boss canon: finale at power_station →
P3 keys to the district's G mixolydian (root MIDI 55); P2 echoes substation's D phrygian
dominant. Intro stings SHIPPED: `sfx/architect_sting.ogg` (boss reveal), `sfx/tvar_sting.ogg`
(Tvar reveal). Phase change = 2.2 s crossfade; `boss_defeated` → `ui/ui_boss_sting.ogg` then
VICTORY mood.

| file | scene | dur | BPM | key | sig | mood (5) | instrumentation | layers | loop-pts | refs | fade | status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `music/music_boss_dark_p1.ogg` | boss Phase 1 (tension) | 45.000 s | 80 | D minor | 4/4 | coiled, patient, predatory, subterranean, clinical | low cello-like drone, heartbeat pulse, air swells, no melody | 1 (+existing layers keep running) | 0→45.000 | Dead Space; Alien: Isolation | 2.2 s x-fade on phase | NEW |
| `music/music_boss_dark_p2.ogg` | boss Phase 2 (escalation) | 45.000 s | 100 | D phrygian dominant | 4/4 | menacing, urgent, industrial, relentless, bared-teeth | pulsing distorted bass ostinato, dissonant string stabs, metallic hits | 1 | 0→45.000 | Dead Space; Bloodborne | 2.2 s x-fade | NEW |
| `music/music_boss_dark_p3.ogg` | boss Phase 3 (final) | 45.000 s | 120 | G mixolydian over G pedal | 4/4 | desperate, colossal, final, defiant, catastrophic | industrial percussion battery, brass-like swells, sustained open fifths, feedback siren | 1 | 0→45.000 | Bloodborne; Dead Space; Alien: Isolation | 2.2 s x-fade | NEW |
| `music/music_boss_dark.wav` | boss mood underlay/intro | 30.500 s | — | — | — | — | — | — | looped | — | 2.2 s | SHIPPED (ratify; superseded per-phase once p1–p3 land) |

```
p1 — Instrumental boss tension loop, 80 BPM, D minor, 4/4, seamless 45-second loop. Low sustained cello-like drone, muted heartbeat pulse, airy noise swells, no melody. Coiled, patient, predatory, subterranean, clinical. The thing in the dark has noticed you. No vocals, no drums.
```

```
p2 — Instrumental boss escalation loop, 100 BPM, D phrygian dominant, 4/4, seamless 45-second loop. Pulsing distorted bass ostinato, dissonant string-like stabs, metallic industrial hits, rising filter tension. Menacing, urgent, industrial, relentless, bared teeth. No vocals, no lead melody.
```

```
p3 — Instrumental final boss loop, 120 BPM, G mixolydian over a low G pedal, 4/4, seamless 45-second loop. Aggressive industrial percussion, brass-like synth swells, sustained open fifths, sirens of feedback. Desperate, colossal, final, defiant, catastrophic. No vocals.
```

---

## e) Event stingers

| file | scene | dur | BPM | key | sig | mood (5) | instrumentation | layers | loop-pts | refs | fade | status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `ui/ui_secret_discovery_sting.ogg` | secret found | 0.393 s | — | — | — | hushed, brightening, secretive, warm, brief | two-note brass-warm chime through reverb | 1-shot | no loop | INSIDE; Kentucky Route Zero | none (zero-ended) | SHIPPED, wired via `uisfx.gd:39` |
| `ui/ui_district_restored_sting.ogg` | district restored (1 SHARED variant — full-stage event, all 11 districts) | 2.000 s | — | — | — | relief, warming, earned, resolving, quiet-triumph | hum resolves upward to a warm brass fifth, light-switch click tail | 1-shot | no loop | Silent Hill 2; INSIDE | none; pairs with dark→lit bed crossfade | NEW (today `quest_completed` reuses `daily_complete_sting` — no restored-specific sound; fix via `uisfx.gd` wiring advisory) |
| `ui/ui_daily_complete_sting.ogg` | daily/quest complete (toast) | 0.637 s | — | — | — | settled, neat, modest, warm, capped | short three-note resolve, dry | 1-shot | no loop | Kentucky Route Zero; Disco Elysium | none | SHIPPED, wired `uisfx.gd:40–41,65` |
| `jingles/quest_complete.ogg` | quest banner (long form) | 3.000 s | — | — | — | completed, tidy, gentle, warm, closed | four-note pad cadence | 1-shot | no loop | Disco Elysium; Kentucky Route Zero | none | SHIPPED |
| `music/cue_death.ogg` | player death (slow-mo beat, time_scale 0.3) | 8.000 s | — | D pedal | — | extinguished, sinking, cold, final, merciful | drone drops a fifth and dies to a single dark tail, like a streetlight failing | 1-shot, zero-ended | no loop | Darkwood; Silent Hill 2 | none (dies to silence); death screen fade 0.6 s | NEW (death beat is silent today — `death_sequence.gd` has 0 audio refs) |
| `music/cue_victory.ogg` | victory run-out (all endings) | 120.000 s | — | — | — | bittersweet, swelling, ambiguous, resolving, tired-peace | swells @30/60/90 s, resolve to quiet | 1-shot | no loop | Silent Hill 2 "Promise"; Disco Elysium | none; plays over VICTORY mood | SHIPPED, wired (wow cue "ending") |
| `music/music_victory.wav` | victory screen bed | 14.500 s | — | — | — | bittersweet, looping, modest, warm-dim, held | short victory figure + pad | looped by `_force_loop` | 0→14.500 (audible re-trigger every 14.5 s — see audit B1) | — | 2.2 s | REPLACE with ≥60 s bed (see audit B1) |
| `jingles/ending_{light,hope,truth,survivor,dark}_sting.ogg` | 5 endings stingers | 10–12 s | — | — | — | per-ending: radiant / cautious / stark / weary / abyssal | pad cadence per ending tone (VISUAL_AUDIO_SPEC §2: match warmth level, not literal color) | 1-shot | no loop | Disco Elysium; Silent Hill 2 | none | SHIPPED, wired via `endings_manager.gd` |
| `ui/ui_ending_sting.ogg` | ending toast (unused) | 0.571 s | — | — | — | — | — | — | — | — | — | ORPHAN — wire or delete (audit D4) |

```
ui_district_restored_sting — Instrumental two-second sting: a low electrical hum resolves upward into a warm brass perfect fifth, like a streetlight igniting, ending on a soft click of a breaker. Relief, warming, earned, quiet triumph. No vocals, no percussion.
```

```
cue_death — Instrumental eight-second death cue, one-shot. A low drone sinks a fifth, a failing-streetlight flicker of sound, then everything dies to one dark soft tail. Extinguished, sinking, cold, final, merciful. Zero-ended silence. No vocals, no percussion.
```

---

## f) UI feedback

All SHIPPED and wired via `scripts/systems/uisfx.gd`. UI bus. Stinger class −14 LUFS.
Precedence rule already in code: `click()` prefers `ui/ui_menu_click.ogg`, falls back to
`sfx/ui_click.wav`. Keep both; do not re-record.

| file | event | dur | loudness class | mood (3) | refs | fade | status |
|---|---|---|---|---|---|---|---|
| `sfx/ui_hover.wav` | menu hover | ~0.1 s | −14 (normalized −13.7) | dry, neutral, tiny | Kentucky Route Zero | none | SHIPPED (`uisfx.gd:89`) |
| `ui/ui_menu_click.ogg` → fallback `sfx/ui_click.wav` | confirm / press | 0.103 s / ~0.1 s | −14 | dry, soft-thock, decisive | INSIDE | none | SHIPPED (`uisfx.gd:81–85`) |
| `sfx/ui_error.wav` | error / deny | ~0.2 s | −14 (normalized −10.4) | muted buzz, denied, low | Alien: Isolation | none | SHIPPED (`uisfx.gd:106`) |
| `sfx/ui_save.wav` | save | ~0.1 s | −14 (−12.1) | two-tick, reassured, small | Kentucky Route Zero | none | SHIPPED (`uisfx.gd:109`) |
| `sfx/ui_back.wav`, `sfx/ui_tab.wav` | back / tab (optional wiring) | — | −14 | — | — | none | SHIPPED, unwired (audit D5) |
| `sfx/ui_xp_tick.wav` | `xp_gained` juice tick | 0.060 s | −14 | single soft tick, felt, minor-warm | INSIDE | none | NEW (follows `sfx/ui_*` family; pairs GAMEFEEL XP fill tween) |
| `sfx/ui_heal_soft.wav` | `player_healed` juice | 0.300 s | −14 | warm two-note sigh, dark-warm not cheerful | Silent Hill 2 | none | NEW (follows `sfx/ui_*` family) |

```
ui_xp_tick — Instrumental 60-millisecond UI tick: one soft muted felt-piano note, low-middle register, dry, barely there. No reverb, no vocals.
```

```
ui_heal_soft — Instrumental 300-millisecond heal sound: two warm soft synth notes a third apart, rising, like a candle relit in a dark room. Gentle, relieved, dark-warm, quiet. Not cheerful. No vocals.
```

---

## g) Cross-reference — every GAMEFEEL_SPEC juice event ↔ audio

Source: `docs/GAMEFEEL_SPEC.md` (shipped table + P4 scope). "wired" = verified consumer in
`scripts/` this pass. New rows get files from §§a–f above; no event left silent.

| Juice event (EventBus) | Effect (GAMEFEEL) | Audio spec | Status |
|---|---|---|---|
| `player_damaged` | trauma shake +0.3 | `sfx/sfx_hurt.wav` one-shot at −8 dB + `one_shots/heartbeat_low_loop.ogg` at low HP | wired (`audio_manager.gd:88,131`) |
| `enemy_died` | trauma shake +0.15 | per-monster `sfx/mon_<type>_death.wav` (rotter/hound/brute/burner/sniper/tvar) | wired per enemy script |
| `enemy_hp_updated` (crit/heavy) | hit-stop ≤80 ms | `sfx/sfx_hit.wav` pairs with the stop; keep one-shot, never with `player_damaged` in same frame group | file shipped; pair at implementation |
| death | `time_scale = 0.3` beat | `music/cue_death.ogg` NEW (§e) + existing heartbeat/breath beds duck out over 1.5 s | GAP → spec'd |
| boss phase slow-mo (P1→P2→P3) | `time_scale` dip | `music/music_boss_dark_p{1,2,3}.ogg` NEW (§d), 2.2 s x-fade per phase | GAP → spec'd |
| `boss_defeated` | shake + hit-stop combo | `ui/ui_boss_sting.ogg` (wired `uisfx.gd:43`) → VICTORY mood + `cue_victory` | wired |
| `item_picked_up` | HUD icon pop + flash | procedural `_gen_pickup()` (wired `audio_manager.gd:71`); optional rare variant `sfx/interact/loot_pickup_rare.wav` unwired (audit D5) | wired (procedural) |
| `xp_gained` | XP bar fill tween | `sfx/ui_xp_tick.wav` NEW (§f), max 1 tick per 0.5 s eval window | GAP → spec'd |
| `achievement_unlocked` | toast slide + 1 shake pulse | `ui/ui_achievement_sting.ogg` (wired `uisfx.gd:112`); `jingles/ach_unlock.ogg` orphan (audit D4) | wired |
| `player_healed` | soft green HUD flash | `sfx/ui_heal_soft.wav` NEW (§f) | GAP → spec'd |
| `district_blackout` / `light_disrupted` | flash-to-black (photosensitivity-gated) | procedural `_gen_glitch()` one-shot at −8 dB (wired `audio_manager.gd:67`) — keep procedural, hum bus drops via `hum_level` | wired |
| `streetlight_activated` (first of run) | first_light wow (trauma 0.30, no slow-mo) | `music/cue_first_light.ogg` 60 s one-shot (wired `music_manager.gd:177,414`) | wired |
| all districts restored (`PowerGrid.all_restored`) | cascade wow (trauma 0.55, slow-mo 0.5×) | `music/cue_grid_cascade.ogg` 90 s one-shot (wired `music_manager.gd:422`) | wired |
| district stage → FULL (single district) | dark→lit bed swap | dark→lit twin crossfade 2.2 s + `ui/ui_district_restored_sting.ogg` NEW (§e) | GAP → spec'd |
| `secret_found` | secret toast | `ui/ui_secret_discovery_sting.ogg` (wired `uisfx.gd:39`) | wired |
| `quest_completed` / `level_completed` / daily.completed | toast / banner | `ui/ui_daily_complete_sting.ogg` + `jingles/quest_complete.ogg` (wired `uisfx.gd:40–41,65`) | wired |
| `game_won` | ending wow (bittersweet flash) | `music/cue_victory.ogg` + `music/music_victory.wav` (REPLACE per B1) + ending stingers | wired |
| boss intro (reveal) | intro sting | `sfx/architect_sting.ogg` (boss_3d.gd:45), `sfx/tvar_sting.ogg` (tvar_3d.gd:37) | wired |
| low HP / exertion | heartbeat & breath beds | `one_shots/heartbeat_low_loop.ogg`, `one_shots/breath_low_loop.ogg` force-looped | wired (`audio_manager.gd:57,61`) |

## h) Riskiest assumptions (one line each, verified same turn)

- **Menu hook:** assumed a dedicated menu track exists to replace — verified FALSE
  (`Mood.MENU → abandoned_hallways.mp3`; `music_menu_dark` generated but unshipped) → §a is a REPLACE, not a polish.
- **Boss phases:** assumed one loop for a multi-phase fight — verified TRUE
  (`boss_3d.gd` Phase P1/P2/P3 vs single `music_boss_dark.wav`) → §d justified.
- **District beds:** assumed gaps — verified FALSE, all 22 shipped/certified → §b is ratification + re-render briefs only.
- **Stackable combat:** assumed layers exist — verified TRUE (threat_low/high + action, 60 s each) → §c ratifies, adds no new stems.
- **Suno fidelity:** exact BPM/key/loop length will NOT survive generation; loop points are post-production targets (§0 workflow) — risk carried by the DAW pass, not the prompt.
