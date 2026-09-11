# VISUAL_AUDIO_SPEC.md — reference for Arena (art/audio production)

Written 2026-09-11 (PLAYABLE IDEAL pass, STEP 6). Consolidates the visual half (new this
pass) with the audio half (already specified in full in `docs/AUDIO_COVERAGE.md` — cited,
not duplicated) into one reference for whoever next holds art/audio production tools.
Source of truth for every number below: the shipped code (`scripts/world/district_themes.gd`,
`scripts/systems/wow_director.gd`) and `docs/STYLE_GUIDE.md` — nothing here is invented.

---

## 1. Per-district post-processing / LUT moods

`DistrictThemes.THEMES` (`scripts/world/district_themes.gd`) is the canon source — accent,
sky, ambient and weather per district, already shipped and driving `WorldEnvironment` live.
The table below reads that data as **grading intent** for anyone building a LUT, a grading
overlay, or matching art to a district's mood; it is not a new system, just this pass's
translation of the existing data into art-direction language.

| District | Accent | Sky/Ambient | Weather | Mood read |
|---|---|---|---|---|
| suburbs | `#f4a35d` amber | near-black green-grey (`#0b0f0a`/`#141a12`) | clear | Domestic warmth waiting to return — the brass accent is the *only* warm note against a cold green-grey base. |
| residential | `#f4a35d` amber | same as suburbs | clear | Twin of suburbs; differentiate only through prop density/height, not grading. |
| park | `#f4e35d` yellow-green | deep green-black (`#0a110a`/`#12180f`) | clear | The one district with a warmer, more natural green base — "the city's one living thing left." |
| school | `#f4c95d` gold | cool blue-grey (`#0b0c11`/`#14151c`) | clear | Institutional cold; gold accent reads as fluorescent-memory rather than streetlight brass. |
| hospital | `#5dc8f4` **cyan** | same cool blue-grey as school | clear | The one district whose accent breaks the brass rule — clinical cyan, not warm. Deliberate: hospital light should never read as "home." |
| gas_station | `#e85d3a` ember-orange | warm-dark brown-black (`#100d0a`/`#1a140f`) | clear | Danger-adjacent warmth — closer to `ember` than `brass` in STYLE_GUIDE terms; the forecourt canopy light should feel electric, not cozy. |
| police | `#5d5dc8` **indigo** | cold blue-black (`#0a0a11`/`#12121c`) | clear | Second accent-rule break — authority-cold indigo instead of brass. Sodium court floods (per the trailer kit) should still read brass in-scene; the *ambient* stays indigo underneath. |
| warehouses | `#e85d3a` ember-orange | same warm-dark as gas_station | **fog** | First fogged district — grading should soften contrast at range; ember accent through fog reads as distant, not close danger. |
| industrial | `#e85d3a` ember-orange | same as warehouses | fog | Twin of warehouses; differentiate through machinery silhouette density. |
| substation | `#f4f45d` **pale yellow-white**, near-bone | neutral grey-black (`#0c0c0c`/`#161616`) | fog | Coldest, most desaturated accent in the game — closest to `bone`/`steel`, almost no chroma. Reads as "the grid's nervous system," not a place people lived. |
| power_station | `#f4f45d` same pale yellow-white | same neutral grey-black | fog | Twin of substation — the finale district should feel like an extension of substation, not a new palette. |

**Grading rule for any new asset:** never introduce a warm chroma outside the district's own
accent color; STYLE_GUIDE §1's "cold darkness vs. warm light" axis is enforced per-district,
not just globally — hospital and police are the two districts where "warm" is *specifically
absent* by design, don't brass-wash them to match the others.

## 2. Emotional cue specs — the three "wow" moments

Source: `scripts/systems/wow_director.gd` `_PRESETS` (shipped, live). Any new art, music
sting, or VFX timed to these beats should match the *exact* numbers below — they're already
tuned and shipped, not placeholders.

| Beat | Trigger | Screen flash | Flash duration | Camera shake (trauma) | Slow-mo | FOV punch | Emotional target |
|---|---|---|---|---|---|---|---|
| **first_light** | First streetlight in the game ignites (`EventBus.streetlight_activated`, once per run) | warm amber `(1.00, 0.82, 0.45)` @ 20% alpha | 0.5 s | 0.30 (light) | none | none | Relief + small triumph — the game's thesis statement in one frame. Keep it *quiet*: no slow-mo, so it never overstates a routine action the player will repeat 10 more times. |
| **cascade** | Last district before power_station reaches FULL (every district restored) | near-white warm `(1.00, 0.95, 0.80)` @ 28% alpha | 0.8 s | 0.55 (strong) | 0.5x ≈0.45 s | −4° | The single biggest mechanical payoff in the game — the whole map lighting at once. This is the frame every trailer cut should end its build on. |
| **ending** | `game_won` (any of the 5 endings) | warm-dim `(0.92, 0.62, 0.32)` @ 26% alpha | 1.0 s | 0.45 (moderate) | 0.4x | −3° | Bittersweet, not triumphant — dimmer flash color than cascade on purpose (0.92/0.62/0.32 vs 1.0/0.95/0.80), because the ending music/art should carry ambiguity (5 endings range from Light to Dark) that a pure-triumph flash would contradict. |

**Rule for new ending art** (`store/trailer/` stills, ending-screen backgrounds): match the
flash color's *warmth level*, not its literal RGB — Light/Hope endings can run warmer than
this base value, Dark/Survivor should run cooler, Truth sits at or near this exact value.

## 3. Audio — the 8 remaining lit-bed gaps (exact contract)

**Full per-district specs already live in `docs/AUDIO_COVERAGE.md`** (§G1, G2b, G2c, G2e,
G2f, G2g, G2h, G2i) — this section is the *universal contract* extracted from all eight so a
new session doesn't have to re-derive it, plus the one finding that isn't a gap.

**Universal contract, every lit bed:**
- 36.000 s seamless loop (industrial_lit is the one exception: 33.994 s, matching its
  shipped dark twin exactly — see `docs/AUDIO_COVERAGE.md` G2h).
- OGG q4, mono, 44.1 kHz.
- −18 LUFS integrated, true peak ≤ −1.5 dBFS.
- Matched zero-crossing loop points (0.000–[duration]).
- Mood: the district's own `_dark.ogg` bed **re-voiced warmer**, never replaced — same
  material, harsh elements softened/removed, a warm pad raised, tempo/pulse aligned to that
  district's canon bpm (`tools/gen_audio.py` `DISTRICTS`) so `MusicManager`'s 2 s crossfade
  lands on a downbeat.
- No voices, ever (forbidden in every spec — this is an ambience bed, not a stinger).
- On delivery: add the district's row to `AMBIENCE_LIT_BY_DISTRICT` (code-owned wiring,
  already has the 3 existing lit beds — suburbs/hospital/power_station — as the pattern).

| Gap | District | Target bpm/tonality (canon) | Special constraint |
|---|---|---|---|
| G1 | residential | 80 bpm | none beyond the universal contract |
| G2b | park | 75 bpm, lydian | ice-crack transients kept, slowed+warmed, not removed |
| G2c | school | 100 bpm | no locker slams, no children's sounds |
| G2e | gas_station | 110 bpm, blues | no fault buzz, no fire crackle |
| G2f | police | 120 bpm, minor | no radio static, no boot steps, no sirens |
| G2g | warehouses | 75 bpm, dorian | no forklift, no machinery start |
| G2h | industrial | 85 bpm, minor | **33.994 s, not 36.000 s** — must match its dark twin |
| G2i | substation | 100 bpm, phrygian-dominant | no arc crackle |

**F1 (finding, not a gap):** `power_station`'s two audio one-shots sit at 28.749/28.948 s,
off the general 30.000 s detail-bed class by ~1.2 s. Not blocking, not re-recorded — see
`docs/AUDIO_COVERAGE.md` §F1 for the full reasoning; listed here only so a new session
doesn't mistake it for an unlisted ninth gap.

**Status as of this pass:** all 8 remain spec-only. Music-generation capability was searched
for and found absent from this session/sandbox (`docs/ASSET_LICENSES.md` "final audio pass:
lit-bed generation attempt") — **no binary has been fabricated**, and none should be until a
session with a real generation tool can meet every constraint above exactly.

## 4. AAA screenshot composition rules

Generalized from `store/screenshot-plan-detailed.md` (which has the *specific* 11 shots
already planned) into rules for **any future capture**, store or marketing:

1. **One warm light source reads instantly, every frame** (STYLE_GUIDE §1's rule extended to
   photography) — if a screenshot has two+ equally warm sources, it's fighting itself; pick
   the one that sells the moment and let everything else stay cold.
2. **Center-band safety.** Play/App Store crop screenshots unpredictably on some devices —
   keep the subject inside the middle 80% of the frame, never right at an edge.
3. **No UI unless the UI *is* the subject.** Trailer Mode (HUD off) is the default for
   environment/character shots; touch-HUD shots are their own deliberate category (see
   `store/screenshot-plan-detailed.md` §7) and should never mix with a Trailer-Mode shot in
   the same gallery position.
4. **Never the death screen, never mid-attack-animation, never an ad/popup in frame.**
5. **Spoiler ceiling: Act I districts + the half-lit-city ending still only.** No ending
   text, no Architect reveal, no full-lit-city frame before launch marketing explicitly
   wants to spoil the finale (`store/press-kit.md`'s existing rule, restated here so a new
   session inherits it without re-reading that file).
6. **Palette discipline applies to captured frames too.** A screenshot with a pure `#000000`
   crush or a blown `#ffffff` highlight fails the same purity bar as a texture asset — grade
   before export, same `[16,216]`-class clamp used everywhere else in this repo's generators
   (`tools/gen_adaptive_icon.py`, `tools/gen_mobile_art_pass.py`) is a reasonable target for
   any post-capture correction pass.
7. **1920×1080 canonical; pad, never crop, portrait/ultrawide captures** to that canvas in
   `#0c1016` (STYLE_GUIDE bg-deep) — see `store/screenshot-plan-detailed.md` §7 for the
   worked example on touch-HUD shots.
