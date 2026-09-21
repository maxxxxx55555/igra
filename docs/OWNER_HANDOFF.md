# Owner handoff — v7.3.2

Everything below is a step this session cannot do (GUI, account, real credentials, a
windowed/human-eyes step, or a design call only the owner can make). Everything else in
`docs/IDEAL_GAP_REPORT.md`'s DEV-REMAINING list is still dev work, not yours — this file is
only the owner-side punch list, condensed to one document so nothing needs cross-referencing
five others to act on it.

## 1. Music — 19 tracks, prompts ready to paste

Source: `docs/MUSIC_RECIPE.md` (full detail, post-production steps, house law). Custom mode,
**Instrumental ON** on Suno/Udio. After every generation: trim to the loop length at a zero
crossing → 3ms edge fades → loudnorm to −18 LUFS integrated / TP ≤−1.5 dBFS (beds/music) or
−14 LUFS (stingers/SFX) → export OGG q4 mono 44.1kHz (WAV only where noted) → save to the path
below → log in `docs/ASSET_LICENSES.md` → verify per `docs/CERT_AUDIO.md`.

| # | Target path | Loop | Prompt |
|---|---|---|---|
| 1 | `assets/audio/music/music_menu_dark.ogg` (**replaces** `abandoned_hallways.mp3`, see retirement note below) | 120.000s | Instrumental dark ambient nocturne, 66 BPM, D minor, 4/4. A lonely felt piano plays a sparse six-note hook over a warm analog pad and a deep sub drone; soft tape hiss and distant night-city air. Melancholic, suspended, solitary, nocturnal, quietly hopeful. Cold darkness with one warm brass-lit glow. No vocals, no drums, seamless loop. |
| 2 | `assets/audio/music/suburbs.ogg` | 37.333s | Instrumental ambient theme, 90 BPM, C pentatonic, 4/4. Gentle generative pad arpeggio like a music box remembered from childhood, warm tone over a cold low drone. Wistful, homespun, muted, open, unguarded. Night suburb with one amber streetlight. No vocals, no drums, seamless loop. |
| 3 | `assets/audio/music/school.ogg` | 33.600s | Instrumental ambient theme, 100 BPM, E minor-major ambiguity, 4/4, long hall reverb. Glassy pad ostinato like a distant music classroom, cold institutional air. Fluorescent, nostalgic-broken, austere, echoey, cold. No vocals, no percussion, seamless loop. |
| 4 | `assets/audio/music/hospital.ogg` | 40.000s | Instrumental ambient theme, 60 BPM, whole-tone scale on F#, 4/4. Weightless floating pads that never resolve, clinical hum, faint monitor blip. Adrift, calm-sick, antiseptic, hollow, wrong. A hospital that must never feel like home. No vocals, no percussion, seamless loop. |
| 5 | `assets/audio/music/gas_station.ogg` | 34.909s | Instrumental ambient theme, 110 BPM, E blues, 4/4. Muted bluesy pad licks over an electrical hum, idle forecourt energy, ember-lit darkness. Roadside, restless, oily, electric, lonely. No vocals, no drums, seamless loop. |
| 6 | `assets/audio/music/police.ogg` | 28.000s | Instrumental ambient theme, 120 BPM, F minor, 4/4. Terse staccato pads and a quiet ticking pulse, indigo-cold authority, surveillance stillness. Procedural, restrained, hard, grim, airless. No vocals, no drums, seamless loop. |
| 7 | `assets/audio/music/warehouses.ogg` | 38.400s | Instrumental ambient theme, 75 BPM, C dorian, 4/4. Low drifting dorian pads with distant chain-clank ghosts in cavernous reverb, fog-softened edges. Cavernous, patient, foggy, metallic, minor-hopeful. No vocals, no drums, seamless loop. |
| 8 | `assets/audio/music/substation.ogg` | 33.600s | Instrumental ambient theme, 100 BPM, D phrygian dominant, 4/4. Nervous ostinato under a high voltage whine, arc-crackle texture, pale desaturated air. Energized, alien, crackling, cold, watchful. No vocals, no drums, seamless loop. |
| 9 | `assets/audio/music/power_station.ogg` | 32.000s | Instrumental ambient theme, 105 BPM, G mixolydian, 4/4. Broad resolute pads over a monumental generator thrum, the city's dead heart still charged. Charged, humming, finale-facing, monumental, resolute. No vocals, no drums, seamless loop. |
| 10 | `assets/audio/music/layer_threat_low.ogg` (only if forced re-render — currently shipped/certified) | 60.000s | Instrumental suspense stem, 70 BPM, D minor drone, seamless 60s loop. Almost still: low drone, faint irregular sub throb, cold dark air. Watchful, creeping, uneasy, patient, quiet dread. Layers under other stems. No vocals, no drums, no melody. |
| 11 | `assets/audio/music/layer_threat_high.ogg` (only if forced re-render) | 60.000s | Instrumental tension stem, 100 BPM, D minor, seamless 60s loop. Tight muted pulse like an accelerating heart, whispering noise sweeps, dissonant cluster pad. Hunted, anxious, closing-in, cold sweat, alert. Stackable stem. No vocals, no drums, no lead. |
| 12 | `assets/audio/music/layer_action.ogg` (only if forced re-render) | 60.000s | Instrumental action stem, 140 BPM, D minor, seamless 60s loop. Driving distorted bass, urgent metallic percussion, siren-like synth stabs. Adrenaline, panic, pursuit, violent, desperate. Stackable combat stem. No vocals, no melodic lead. |
| 13 | `assets/audio/music/music_boss_dark_p1.ogg` | 45.000s | Instrumental boss tension loop, 80 BPM, D minor, 4/4, seamless 45s loop. Low sustained cello-like drone, muted heartbeat pulse, airy noise swells, no melody. Coiled, patient, predatory, subterranean, clinical. The thing in the dark has noticed you. No vocals, no drums. |
| 14 | `assets/audio/music/music_boss_dark_p2.ogg` | 45.000s | Instrumental boss escalation loop, 100 BPM, D phrygian dominant, 4/4, seamless 45s loop. Pulsing distorted bass ostinato, dissonant string-like stabs, metallic industrial hits, rising filter tension. Menacing, urgent, industrial, relentless, bared teeth. No vocals, no lead melody. |
| 15 | `assets/audio/music/music_boss_dark_p3.ogg` | 45.000s | Instrumental final boss loop, 120 BPM, G mixolydian over a low G pedal, 4/4, seamless 45s loop. Aggressive industrial percussion, brass-like synth swells, sustained open fifths, sirens of feedback. Desperate, colossal, final, defiant, catastrophic. No vocals. |
| 16 | `assets/audio/ui/ui_district_restored_sting.ogg` | 2.000s, one-shot | Instrumental two-second sting: a low electrical hum resolves upward into a warm brass perfect fifth, like a streetlight igniting, ending on a soft click of a breaker. Relief, warming, earned, quiet triumph. No vocals, no percussion. |
| 17 | `assets/audio/music/cue_death.ogg` | 8.000s, one-shot, zero-ended | Instrumental eight-second death cue, one-shot. A low drone sinks a fifth, a failing-streetlight flicker of sound, then everything dies to one dark soft tail. Extinguished, sinking, cold, final, merciful. Zero-ended silence. No vocals, no percussion. |
| 18 | `assets/audio/sfx/ui_xp_tick.wav` | 0.060s, one-shot | Instrumental 60ms UI tick: one soft muted felt-piano note, low-middle register, dry, barely there. No reverb, no vocals. |
| 19 | `assets/audio/sfx/ui_heal_soft.wav` | 0.300s, one-shot | Instrumental 300ms heal sound: two warm soft synth notes a third apart, rising, like a candle relit in a dark room. Gentle, relieved, dark-warm, quiet. Not cheerful. No vocals. |

**Retirement note**: `assets/audio/music/abandoned_hallways.mp3` (current MENU theme) and
`abandoned_hallways_alt.mp3` (current school/hospital theme) are the same two files that were
already loudness-fixed this pass (`perf(audio): measured loudness normalization`, both were
clipping above 0 dBTP, now at house-law −18 LUFS) — they're safe to keep shipping as-is if #1,
#3, #4 above aren't generated soon. Once #1 lands, retire `abandoned_hallways.mp3` from the
MENU slot in `scripts/systems/music_manager.gd`'s `TRACKS` dict; once #3/#4 land, retire
`abandoned_hallways_alt.mp3` from the `school`/`hospital` entries in the same file's district
map. Don't delete the files outright — `docs/MUSIC_RECIPE.md` notes they may still be reused
as a school/hospital ambience *source class* per `docs/MUSIC_SPEC.md` §a.

## 2. Screenshots

**Correction to earlier gap reports first**: `docs/IDEAL_GAP_REPORT.md`'s standing "8 before/
after, 8 store shots" line conflates two different, separately-tracked deliverables — checked
both on disk this pass:
- `assets/store/screenshot_01.png` … `_05.png` (5 files) — **already done and shipped**,
  wired into `export_presets.cfg`, confirmed present on disk. Nothing to do here.
- `docs/stills/` (8 canonical before/after shots, feeds `docs/STORE_KIT.md` and the
  GAMEFEEL_SPEC before/after pair) — **genuinely empty, 0 files**, and genuinely owner-only:
  headless Godot has no compositor, so this needs a real windowed run.

Run this once, on this machine, with the window visible:
```bash
"C:\Users\Maxsim\Desktop\TLS_Build\godot_extracted\Godot_v4.7-stable_win64_console.exe" --path . --windowed res://scenes/tools/capture_stills_scene.tscn
```
Outputs the 8 shots to `docs/stills/`. ~2 minutes, no further input needed once the window
opens (the scene automates the capture sequence itself).

## 3. Release ops (Android / Play Store)

Condensed from `docs/RELEASE_CHECKLIST.md` + `docs/store/HUMAN_CHECKLIST.md` — see those for
the full detail.

1. **AppLovin MAX ads**: create an account + app entries at https://dash.applovin.com, get an
   SDK key + rewarded/interstitial unit IDs, paste into `project.godot`'s `[monetization]`
   section. Leaving these empty is safe — `ad_service.gd` falls back to a debug stub
   automatically, nothing breaks.
2. **Install the Android Build Template** (Godot editor → Project → Install Android Build
   Template) — required before the Gradle build (`export_presets.cfg` already has
   `use_gradle_build=true`) will work at all.
3. **Verify the AppLovin MAX plugin is checked** in Export dialog → Android preset → Plugins
   tab (it's set by hand in `export_presets.cfg`; the editor GUI is the source of truth).
4. **Release keystore** — ⚠️ `docs/RELEASE_CHECKLIST.md` and `docs/store/HUMAN_CHECKLIST.md`
   give two DIFFERENT commands (different filename/alias each) — pick ONE, don't run both:
   ```bash
   # RELEASE_CHECKLIST.md's version:
   keytool -genkey -v -keystore tls_keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tls_key
   # HUMAN_CHECKLIST.md's version:
   keytool -genkey -v -keystore release.keystore -alias tlsrelease -keyalg RSA -keysize 2048 -validity 10000
   ```
   Store the resulting file and its password outside the repo. Paste the path into
   `export_presets.cfg`'s `keystore/release`/`keystore/release_user`/`keystore/release_password`
   before the final signed build. (This is separate from the debug keystore already committed
   at `res://tls_debug.keystore` — don't reuse that one for release.)
5. **Google Play Console**: create the account + app listing, fill the Data Safety form (no
   personal data collected, no analytics SDK — until a real AppLovin key goes in, then its own
   ad-ID/device-info disclosure is needed too), complete the IARC questionnaire (expected
   **PEGI 16** per the blood/bleed status effects and mass-casualty narrative — flagged in
   `docs/store/HUMAN_CHECKLIST.md` as a judgment call worth a second look before submitting,
   not a settled fact), upload to internal/closed testing before production.
6. **Privacy policy**: needs an actual hosted URL. A short "no data collected" policy is
   accurate for the current build — just needs publishing and linking (a gh-pages-ready
   EN/RU page already exists on `origin/gh-pages`, per this pass's arena-backlog audit — that
   branch was never merged into main because it's a static-hosting artifact, not game code;
   point Play Console at whatever URL that branch ends up published at).

## 4. Economy decision — pick one (or explicitly "none")

Full detail and scoring in `docs/ECONOMY_OPTIONS.md`. The gap: a repeat-profile player with no
secrets banks 2,200 coins against 3,500 for the two priciest shop items — a 1,300-coin
shortfall, by design (0 repeatable-grind income), though daily challenges already provide a
slow real-time-gated path (~216.5 avg coins/day) the design audit's single-playthrough trace
never sees.

**NEEDS-OWNER-DECISION — three options, each fully reversible except where noted:**

- **A. Wire the existing (cosmetic-only) kill-coin number into real currency.** Smallest code
  change, but the design-audit itself warns against it (risks turning a stealth game into a
  combat-optional grind) unless capped — and a cap needs new persistent state, not a one-liner.
  *Pick this if*: you're fine with players who fight their way to funding, and want the
  cheapest implementation.
- **B. Cut the two target catalog prices** (data-only, `data/shop/*.tres`). Zero code risk, but
  permanently changes the game's economy pacing for every player, not just repeat-profile ones
  — worth knowing if the current prices were a deliberate "takes two playthroughs" choice.
  *Pick this if*: you're not sure the current prices were ever a deliberate balance target, or
  you'd rather players reach the full catalog in one run.
- **C. Add a bounded quest/puzzle faucet**, reusing the existing wallet-crediting quest/puzzle
  pattern. Keeps every playstyle funded (not just combat), closest fit to the game's stealth-
  narrative pillar, but needs real content authoring (+ i18n across 13 locales) per district,
  the highest-effort option of the three.
  *Pick this if*: you want the "right" long-term answer and have room for a content pass, not
  just a numbers edit.
- **D. Do nothing — the gap is intentional friction.** A legitimate answer the design audit
  itself allows for. *Pick this if*: you're fine with the current catalog being effectively a
  two-playthrough (or all-secrets) reward, not a same-run purchase.

No recommendation given here on purpose — this is a design-feel call, not a correctness one.
