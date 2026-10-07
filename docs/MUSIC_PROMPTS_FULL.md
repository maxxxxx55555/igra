# MUSIC_PROMPTS_FULL — every music prompt for The Last Streetlight

Single paste-ready list. Superset of `docs/MUSIC_RECIPE.md` (19 tracks): adds the shipped
tracks as optional re-renders, the 22 district beds, ending stingers and wow cues.
Canon: `docs/MUSIC_SPEC.md`, `docs/PRODUCTION_BIBLE.md` §3. Total: **69 prompts**.

## How to use (Suno v4.5+/v5 or Udio)

- **Custom mode, Instrumental ON.** Paste `STYLE` into the Style field, `EXCLUDE` into
  "Exclude styles" (Suno) / negative prompt (Udio). Lyrics field: leave empty, or paste the
  `STRUCTURE` line as `[bracket]` tags if the model wants them.
- Suno/Udio will not hit exact BPM, key or length. Generate 4-6 takes, pick the one that trims
  cleanly. Pure-texture beds (section 7) are better made in Stable Audio / ElevenLabs Sound
  Generation; prompts work there too, drop the BPM words.
- Post-production for every file: trim to target length at a zero crossing → 3 ms edge fades
  → loudnorm (music/beds −18 LUFS, stingers/SFX −14 LUFS, TP ≤ −1.5 dBFS) → OGG q4 mono
  44.1 kHz (`.wav` only where noted) → save to the exact path → log in
  `docs/ASSET_LICENSES.md` → verify per `docs/CERT_AUDIO.md`.
- Loops: the take must end where it began (same pad level, no reverb tail cut). If the tail
  rings out, crossfade the last 2 s under the first 2 s.

## Global rules (apply to every prompt)

World: nocturnal stealth-horror, the city is dead because the streetlights went out. Cold
darkness vs one warm light. Muted, atmospheric, **never cheerful or upbeat**. Lit = same
material as dark, re-voiced warmer, not a different song. No vocals anywhere. No constant
low-frequency hum bed (owner ruling rc14) — drones must breathe, move, or be filtered.

```
EXCLUDE (default, paste into every generation):
vocals, singing, choir, spoken word, lyrics, EDM, trap, pop, rock band, guitar solo,
cheerful, upbeat, major-key fanfare, trailer braams, orchestral epic, comedy, 8-bit
```

Add `drums, percussion` to EXCLUDE on every track whose STYLE says "no drums".

---

## 1. Main menu

### 1.1 `music/music_menu_dark.ogg` — 120.000 s loop, 66 BPM, D minor (REPLACE)

```
STYLE: Instrumental dark ambient nocturne, 66 BPM, D minor, 4/4, slow and spacious. A lonely felt piano with soft hammers plays a sparse six-note hook, repeating with small variations, long silences between phrases. Under it a warm analog pad with a faint brass tone, a deep sub drone, soft tape hiss, distant night-city air and wind. Melancholic, suspended, solitary, nocturnal, quietly hopeful. Cold darkness with one warm glow of a single streetlight. Intimate, close-miked, wide reverb. Reference mood: Darkwood, Kentucky Route Zero, Silent Hill 2 menu. Seamless loop, no drums, no vocals.
STRUCTURE: [Intro: pad and hiss only] [Theme: felt piano six-note hook] [Variation: hook an octave lower, pad opens] [Outro: piano fades, pad returns to the intro level]
```

---

## 2. District themes (music layer above the beds), one per district

Each: seamless loop, non-resolving ending, 2.2 s crossfade in.

### 2.1 `music/suburbs.ogg` — 37.333 s, 90 BPM, C pentatonic
```
STYLE: Instrumental ambient theme, 90 BPM, C major pentatonic, 4/4. A gentle generative arpeggio, like a music box remembered from childhood, played by a soft pad with a warm round tone, over a cold low green-grey drone. Sparse, drifting, unhurried, slightly detuned. Wistful, homespun, muted, open, unguarded. A sleeping suburb at night, one amber sodium streetlight, far dogs, wind in trimmed hedges. Kentucky Route Zero, Darkwood. No vocals, no drums, seamless loop.
STRUCTURE: [Arpeggio enters alone] [Drone swells underneath] [Arpeggio thins] [Returns to start]
```
### 2.2 `music/residential.wav` — 42.000 s, 80 BPM, D major (shipped, optional re-render)
```
STYLE: Instrumental ambient theme, 80 BPM, D major, 4/4. Slow generative major pads, long attacks, soft chord changes every two bars, a faint distant TV-murmur texture and creaking-pipe overtone far in the background. Bittersweet, domestic, gentle, muted, remembered; apartments where the lights were switched off mid-evening. Amber memory over a cold hollow base. Silent Hill 2, Kentucky Route Zero. No vocals, no drums, seamless loop.
STRUCTURE: [Pad chord A] [Pad chord B, warmer] [Pad chord C, hollow] [Back to A]
```
### 2.3 `music/park.wav` — 22.400 s, 75 BPM, C lydian (shipped, optional re-render)
```
STYLE: Instrumental ambient theme, 75 BPM, C lydian, 4/4. Airy shimmering lydian pads, breath-like synth wind through bare trees, soft organic rustle, a faint glassy bell tone every few bars. Airy, half-light, drifting, fragile, green-cold. An empty night park that still breathes; the city's last living thing. INSIDE, Kentucky Route Zero. No vocals, no drums, seamless loop.
STRUCTURE: [Shimmer pad] [Wind swell] [Bell tone] [Settle to start]
```
### 2.4 `music/school.ogg` — 33.600 s, 100 BPM, E minor/major ambiguity
```
STYLE: Instrumental ambient theme, 100 BPM, E tonality wavering between minor and major, 4/4, long cold hall reverb. A glassy pad ostinato, like a distant music classroom heard through walls; flickering fluorescent-tube metallic tick, chalk-dust air. Fluorescent, nostalgic-broken, austere, echoey, cold. Vacant corridors, a faint gold institutional glow. Silent Hill 2, INSIDE. No vocals, no percussion, seamless loop.
STRUCTURE: [Ostinato alone] [Major colour appears] [Minor returns, ostinato slows slightly] [Loop]
```
### 2.5 `music/hospital.ogg` — 40.000 s, 60 BPM, F# whole-tone
```
STYLE: Instrumental ambient theme, 60 BPM, whole-tone scale on F#, 4/4. Weightless floating pads that never resolve, clinical airy hum filtered so it breathes, a very faint monitor blip every few bars, metallic trickle. Adrift, calm-sick, antiseptic, hollow, wrong. Cyan clinical coldness; a hospital that must never feel like home, zero warmth. SOMA, Alien: Isolation. No vocals, no percussion, seamless loop.
STRUCTURE: [Floating pad] [Blip enters] [Pad drifts upward, no cadence] [Dissolve to start]
```
### 2.6 `music/gas_station.ogg` — 34.909 s, 110 BPM, E blues
```
STYLE: Instrumental ambient theme, 110 BPM, E blues scale, 4/4, laid-back swing. Muted bluesy pad licks and a single dry muted twang guitar-like note, over a buzzing electrical hum filtered to pulse, wind under a metal canopy. Roadside, restless, oily, electric, lonely; ember-orange canopy lamp in darkness, idle danger, not cozy. Fallout 1997, Darkwood. No vocals, no drums, seamless loop.
STRUCTURE: [Hum and sign buzz] [Pad lick call] [Twang answer] [Hum returns]
```
### 2.7 `music/police.ogg` — 28.000 s, 120 BPM, F minor
```
STYLE: Instrumental ambient theme, 120 BPM, F minor, 4/4. Terse staccato synth pads and a quiet ticking pulse like a wall clock, a faint radio-static ghost, concrete-corridor air. Indigo-cold authority, surveillance stillness. Procedural, restrained, hard, grim, airless, no warmth. Alien: Isolation, SOMA. No vocals, no drums, seamless loop.
STRUCTURE: [Tick alone] [Staccato pad enters] [Pad tightens] [Tick alone again]
```
### 2.8 `music/warehouses.ogg` — 38.400 s, 75 BPM, C dorian
```
STYLE: Instrumental ambient theme, 75 BPM, C dorian, 4/4. Low drifting dorian pads with distant chain-clank and metal-creak ghosts in a cavernous reverb, fog-softened edges, slow breathing swells. Cavernous, patient, foggy, metallic, minor-hopeful. An ember glow that stays distant through fog. Fallout 1997, Darkwood. No vocals, no drums, seamless loop.
STRUCTURE: [Low pad] [Distant clank, reverb tail] [Pad rises one step] [Settle]
```
### 2.9 `music/industrial.wav` — 24.000 s, 85 BPM, A#/Bb minor (shipped, optional re-render)
```
STYLE: Instrumental ambient theme, 85 BPM, B-flat minor, 4/4. Heavy minor drone that slowly grinds, a soft mechanical pulse like distant pistons far in the fog, steam-hiss texture. Grinding, bleak, heavy, foggy, relentless; sleeping machinery and ember silhouettes of dead cranes. Fallout 1997, Darkwood, Alien: Isolation. No vocals, no melody lead, seamless loop.
STRUCTURE: [Grinding drone] [Mechanical pulse enters] [Steam release] [Pulse fades, loop]
```
### 2.10 `music/substation.ogg` — 33.600 s, 100 BPM, D phrygian dominant
```
STYLE: Instrumental ambient theme, 100 BPM, D phrygian dominant, 4/4. Nervous short ostinato under a high thin voltage whine, arc-crackle texture, pale desaturated air, transformer buzz modulated so it never sits still. Energized, alien, crackling, cold, watchful; the grid's nervous system, almost no colour. Fallout 1997, SOMA. No vocals, no drums, seamless loop.
STRUCTURE: [Whine and crackle] [Ostinato enters] [Ostinato shifts up a semitone] [Back]
```
### 2.11 `music/power_station.ogg` — 32.000 s, 105 BPM, G mixolydian
```
STYLE: Instrumental ambient theme, 105 BPM, G mixolydian, 4/4. Broad resolute pads and slow rising swells over a monumental generator thrum that pulses rather than holds, pale light pressure. Charged, humming, finale-facing, monumental, resolute. The city's dead heart, still charged. Fallout 1997, Dead Space. No vocals, no drums, seamless loop.
STRUCTURE: [Thrum] [Broad pad enters] [Swell to peak, no climax] [Pad sinks, loop]
```

---

## 3. Combat stack (threat layers, mixed at −12 dB, all D-centred)

### 3.1 `music/layer_threat_low.ogg` — 60.000 s, 70 BPM (shipped, optional re-render)
```
STYLE: Instrumental suspense stem, 70 BPM, D minor drone, seamless 60-second loop. Almost still: low drone that slowly breathes, faint irregular sub throb, cold dark air. Watchful, creeping, uneasy, patient, quiet dread. Designed to layer under other stems; no melody, no rhythm. Alien: Isolation, INSIDE. No vocals, no drums.
```
### 3.2 `music/layer_threat_high.ogg` — 60.000 s, 100 BPM (shipped)
```
STYLE: Instrumental tension stem, 100 BPM, D minor, seamless 60-second loop. Tight muted pulse like an accelerating heart, whispering noise sweeps, dissonant cluster pad. Hunted, anxious, closing-in, cold sweat, alert. Stackable stem over a D drone. Alien: Isolation, Dead Space. No vocals, no drums, no lead.
```
### 3.3 `music/layer_action.ogg` — 60.000 s, 140 BPM (shipped)
```
STYLE: Instrumental action stem, 140 BPM, D minor, seamless 60-second loop. Driving distorted bass, urgent metallic percussion, siren-like synth stabs. Adrenaline, panic, pursuit, violent, desperate. Stackable combat stem, no melodic lead. Alien: Isolation, Dead Space. No vocals.
```
### 3.4 `music/music_combat.ogg` — 45.000 s (shipped variant pool)
```
STYLE: Instrumental combat loop, 130 BPM, D minor, seamless 45-second loop. Pounding low synth pulse, dirty metallic hits, tense rising filter sweeps, one repeating dissonant two-note motif. Cornered, urgent, claustrophobic. Replaces the melody bed under the threat layers. No vocals, no lead melody.
```
### 3.5 `music/music_battle.wav` — 24.500 s (shipped variant pool)
```
STYLE: Instrumental battle loop, 135 BPM, D minor, seamless 24-second loop. Heavy distorted bass ostinato, clanging industrial percussion, short stabbing strings synth, constant forward motion. Violent but muted, never heroic. No vocals.
```
### 3.6 `music/music_tension.wav` — suspicious/alert bed (shipped)
```
STYLE: Instrumental tension bed, 85 BPM, D minor, seamless 40-second loop. Slow dissonant pad, faint pulsing high harmonic, distant metallic scrape, no beat. Something is near but unseen. Unease, held breath. No vocals, no drums.
```

---

## 4. Boss

### 4.1 `music/music_boss_dark.wav` — 30.500 s, intro/underlay (shipped)
```
STYLE: Instrumental boss underlay, 90 BPM, D minor, seamless 30-second loop. Deep cello-like drone, slow heartbeat, metallic scrapes, rising and falling air. Ominous arrival, subterranean, clinical. Dead Space, Alien: Isolation. No vocals, no melody.
```
### 4.2 `music/music_boss_dark_p1.ogg` — 45.000 s, Phase 1 tension (NEW)
```
STYLE: Instrumental boss tension loop, 80 BPM, D minor, 4/4, seamless 45-second loop. Low sustained cello-like drone, muted heartbeat pulse, airy noise swells, no melody. Coiled, patient, predatory, subterranean, clinical. The thing in the dark has noticed you. Dead Space, Alien: Isolation. No vocals, no drums.
STRUCTURE: [Drone] [Heartbeat enters] [Swell, no release] [Drone alone]
```
### 4.3 `music/music_boss_dark_p2.ogg` — 45.000 s, Phase 2 escalation (NEW)
```
STYLE: Instrumental boss escalation loop, 100 BPM, D phrygian dominant, 4/4, seamless 45-second loop. Pulsing distorted bass ostinato, dissonant string-like stabs, metallic industrial hits, rising filter tension. Menacing, urgent, industrial, relentless, bared teeth. Dead Space, Bloodborne. No vocals, no lead melody.
STRUCTURE: [Bass ostinato] [Stabs enter] [Metal hits double] [Filter drops, loop]
```
### 4.4 `music/music_boss_dark_p3.ogg` — 45.000 s, Phase 3 final (NEW)
```
STYLE: Instrumental final boss loop, 120 BPM, G mixolydian over a low G pedal, 4/4, seamless 45-second loop. Aggressive industrial percussion battery, brass-like synth swells, sustained open fifths, sirens of feedback. Desperate, colossal, final, defiant, catastrophic. Bloodborne, Dead Space, Alien: Isolation. No vocals.
STRUCTURE: [Pedal and percussion] [Brass swell] [Open fifths, feedback siren] [Pedal alone, loop]
```
### 4.5 `sfx/architect_sting.ogg` — boss reveal, ~3 s one-shot (shipped)
```
STYLE: Instrumental three-second sting, one-shot. A huge low metallic tone swells from silence into a dissonant cluster and cuts dead. Dread, a vast mind noticing you. Zero-ended. No vocals, no percussion.
```
### 4.6 `sfx/tvar_sting.ogg` — Tvar reveal, ~2 s one-shot (shipped)
```
STYLE: Instrumental two-second sting, one-shot. A wet low growl-like synth drop with a high tearing glissando on top, abrupt cut. Predatory, wrong. Zero-ended. No vocals.
```
### 4.7 `ui/ui_boss_sting.ogg` — boss defeated, ~3 s one-shot (shipped)
```
STYLE: Instrumental three-second sting, one-shot. A dense dissonant chord collapses downward and resolves to a single quiet open fifth that rings out. Exhausted relief, not triumph. Zero-ended. No vocals, no percussion.
```

---

## 5. Event cues and stingers

### 5.1 `music/cue_death.ogg` — 8.000 s one-shot, zero-ended (NEW)
```
STYLE: Instrumental eight-second death cue, one-shot. A low D drone sinks a fifth, a failing-streetlight flicker of sound, then everything dies to one dark soft tail. Extinguished, sinking, cold, final, merciful. Darkwood, Silent Hill 2. Ends in silence. No vocals, no percussion.
```
### 5.2 `music/cue_first_light.ogg` — 60.000 s one-shot, first streetlight of the run (shipped)
```
STYLE: Instrumental 60-second one-shot cue, slow. A single warm pad tone ignites from silence like a lamp warming up, a soft felt-piano motif joins, hope that is still afraid of itself. Dark-to-warm, tender, tentative. Ends fading to near-silence. INSIDE, Kentucky Route Zero. No vocals, no drums.
STRUCTURE: [Silence → one tone] [Piano motif] [Pad opens warm] [Fade to near silence]
```
### 5.3 `music/cue_grid_cascade.ogg` — 90 s one-shot, all districts restored (shipped)
```
STYLE: Instrumental 90-second one-shot cue. The city's power returns in a slow cascade: a low hum climbs by fifths, layer after layer of warm brass pads stack, a distant bell tone marks each district, building to a luminous but exhausted chord, then settling. Awe, relief, earned. Never bombastic. Silent Hill 2 "Promise", Disco Elysium. No vocals, no drums.
STRUCTURE: [Hum rising] [Layers stacking at 20/40/60 s] [Peak chord] [Settle to quiet]
```
### 5.4 `music/cue_victory.ogg` — 120 s one-shot, all endings (shipped)
```
STYLE: Instrumental 120-second one-shot. Bittersweet, swelling, ambiguous, resolving, tired peace. Slow felt piano and warm strings-pad, three gentle swells at 30, 60 and 90 seconds, final resolution to a quiet sustained chord that fades out. Silent Hill 2 "Promise", Disco Elysium. No vocals, no drums.
```
### 5.5 `music/music_victory.wav` — victory screen bed, 60+ s loop (REPLACE; current 14.5 s re-triggers audibly)
```
STYLE: Instrumental victory-screen bed, 70 BPM, D major with minor colour, seamless 64-second loop. Modest warm-dim pad, a short held piano figure every four bars, no cadence that sounds like an ending so the loop is not noticeable. Bittersweet, held, quiet. No vocals, no drums.
```
### 5.6 `ui/ui_district_restored_sting.ogg` — 2.000 s one-shot (NEW)
```
STYLE: Instrumental two-second sting: a low electrical hum resolves upward into a warm brass perfect fifth, like a streetlight igniting, ending on a soft click of a breaker. Relief, warming, earned, quiet triumph. No vocals, no percussion.
```
### 5.7 `ui/ui_secret_discovery_sting.ogg` — 0.4 s (shipped)
```
STYLE: Instrumental 0.4-second sting: two soft brass-warm chime notes rising a fourth, through small reverb, zero-ended. Hushed, secretive, brightening. No vocals.
```
### 5.8 `ui/ui_daily_complete_sting.ogg` — 0.65 s (shipped)
```
STYLE: Instrumental 0.6-second sting: short dry three-note resolve on soft felt piano, settled and neat, warm. No vocals, no reverb tail.
```
### 5.9 `jingles/quest_complete.ogg` — 3 s (shipped)
```
STYLE: Instrumental three-second jingle: four-note pad cadence, gentle, tidy, warm, closed, ends on a resolved chord. Modest, not triumphant. No vocals, no percussion.
```
### 5.10 `ui/ui_achievement_sting.ogg` / `jingles/ach_unlock.ogg` — ~1.5 s (shipped)
```
STYLE: Instrumental 1.5-second achievement sting: a warm bell tone and a soft rising pad swell, quiet pride, understated. No vocals, no percussion.
```

---

## 6. Ending stingers (5), `jingles/ending_*_sting.ogg`, 10–12 s one-shots (shipped)

Match the warmth level, not literal colour (VISUAL_AUDIO_SPEC §2).

### 6.1 `ending_light_sting.ogg` — radiant
```
STYLE: Instrumental 12-second ending sting, one-shot, D major. Warm pad and soft felt piano rise into a luminous open chord, gentle bell overtones, full resolution, long soft tail. Radiant, grateful, tender, still serious. Disco Elysium, Silent Hill 2. No vocals, no drums.
```
### 6.2 `ending_hope_sting.ogg` — cautious
```
STYLE: Instrumental 11-second ending sting, one-shot, A major/minor ambiguity. Quiet pad, a lone piano line climbing hesitantly, final chord left slightly open. Cautious hope, dawn after a long night. No vocals, no drums.
```
### 6.3 `ending_truth_sting.ogg` — stark
```
STYLE: Instrumental 10-second ending sting, one-shot, D minor. Bare cold pad, a single sustained piano note, a thin high drone, no vibrato, final chord is an empty fifth. Stark, honest, unadorned. No vocals, no drums.
```
### 6.4 `ending_survivor_sting.ogg` — weary
```
STYLE: Instrumental 11-second ending sting, one-shot, G minor. Slow tired pad, low muted strings-like tone dragging downward then settling, a faint warm note at the very end. Weary, alive, battered. No vocals, no drums.
```
### 6.5 `ending_dark_sting.ogg` — abyssal
```
STYLE: Instrumental 12-second ending sting, one-shot, D minor, very low. A sub drone sinks, dissonant cluster pad fades in and out, a distant metal tone rings once and decays into silence. Abyssal, cold, no resolution, no warmth. Ends in silence. No vocals, no percussion.
```

---

## 7. District ambience beds: 11 districts × (dark + lit) = 22 files

Shipped and certified (`assets/audio/ambience/districts/<district>_dark.ogg` / `_lit.ogg`).
Re-render only if a bed fails re-cert. 36.000 s (industrial pair: 33.994 s). Non-metric texture:
no beat, no melody, no vocals, seamless, −18 LUFS. Best tool: Stable Audio / ElevenLabs.
In Suno, drop BPM and add "ambient soundscape, field-recording feel".

**Template:**
`Instrumental dark ambient bed, seamless 36-second loop, no percussion. [CHARACTER]. Base is cold and [COLD COLOUR]; the only warmth is one distant [ACCENT]-coloured glow. Textures only, no melody, no vocals. Muted, atmospheric, nocturnal.`

**Lit twin rule:** same prompt + `Re-voiced warmer: the accent glow is now close and steady, the cold base thins, one soft warm pad is added, same textures and same length so it crossfades 2.2 s with the dark file.`

| # | district | key | CHARACTER | COLD COLOUR | ACCENT |
|---|---|---|---|---|---|
| 7.1 | suburbs | C | A sleeping suburb at night: low warm pad like remembered domestic life over a cold green-grey drone, faint sodium-lamp shimmer, far dogs and wind. | green-grey | amber |
| 7.2 | residential | D | A sleeping apartment district at night: low warm pad like remembered domestic life, creaking pipes, window rattle, faint TV murmur through walls. | green-grey | amber |
| 7.3 | park | C | An empty night park that still breathes: airy synth wind through bare trees, soft organic rustle, distant city hum. | blue-green | yellow-green |
| 7.4 | school | E | A vacant school at night: cold blue-grey air, distant metallic flicker like dying fluorescent tubes, hollow corridors, faint desk scrape and far bell echo. | blue-grey | gold |
| 7.5 | hospital | F# | An abandoned hospital ward: clinical air, empty echoing hum, metallic trickle, a monitor-like blip far away; deliberately un-homey, antiseptic. | cyan | cyan (no warmth, even in the lit twin) |
| 7.6 | gas_station | E | A dark highway forecourt: electrical sign buzz, wind under a metal canopy, gravel crunch, idle danger in the air. | black-blue | ember-orange |
| 7.7 | police | F | A cold authorities' building: restrained flood-light hum, radio-static ghost, concrete corridor air, boots far away, a watched feeling. | indigo | sodium |
| 7.8 | warehouses | C | Vast fog-bound warehouses: cavernous reverb tail, far metal creaks and chain clinks, distant forklift. | fog-grey | ember |
| 7.9 | industrial (33.994 s) | B♭ | Sleeping machinery district: slow metallic grinding pad, steam-hiss, vent rattle, dense fog. | steel-grey | ember |
| 7.10 | substation | D | The grid's nervous system: pale transformer buzz, high thin whine, arc-crackle ghosts, almost no chroma, airless. | desaturated pale | pale yellow |
| 7.11 | power_station | G | The city's dead heart, still charged: monumental low thrum, huge transformer pulse through fog, breaker clunk far away. | pale grey | pale white |

Per district, generate the dark file first, then the lit twin from the same character line.

---

## 8. UI feedback tones

Shipped, wired via `scripts/systems/uisfx.gd`; prompts only for XP/heal (NEW) and optional re-renders.

### 8.1 `sfx/ui_xp_tick.wav` — 0.060 s (NEW)
`Instrumental 60-millisecond UI tick: one soft muted felt-piano note, low-middle register, dry, barely there. No reverb, no vocals.`
### 8.2 `sfx/ui_heal_soft.wav` — 0.300 s (NEW)
`Instrumental 300-millisecond heal sound: two warm soft synth notes a third apart, rising, like a candle relit in a dark room. Gentle, relieved, dark-warm, quiet. Not cheerful. No vocals.`
### 8.3 `sfx/ui_hover.wav` — 0.1 s
`Instrumental 100-millisecond UI hover tick: one tiny dry neutral click-tone, very quiet.`
### 8.4 `ui/ui_menu_click.ogg` — 0.1 s
`Instrumental 100-millisecond UI confirm: a dry soft wooden thock with a faint low tone, decisive.`
### 8.5 `sfx/ui_error.wav` — 0.2 s
`Instrumental 200-millisecond UI deny: a muted low buzz, two quick pulses, denied but not harsh.`
### 8.6 `sfx/ui_save.wav` — 0.1 s
`Instrumental 100-millisecond save confirmation: two tiny soft ticks a tone apart, reassured, small.`
### 8.7 `sfx/ui_back.wav`, `sfx/ui_tab.wav` — 0.1 s
`Instrumental 100-millisecond UI back: one soft dry tick lower than the confirm click. Tab variant: same tick, slightly higher and shorter.`

---

## Coverage check

1 menu · 11 district themes · 6 combat/tension · 7 boss (3 phases + underlay + 3 stings) ·
10 cues/stingers · 5 endings · 22 beds · 7 UI tones = **69 prompts**.
Not included on purpose: SFX (steps, monsters, doors), weather loops, district detail
one-shots (gas_station_car_pass etc.): these are sound effects, not music.
