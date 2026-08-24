# Production Bible — THE LAST STREETLIGHT

Single reference for pillars, visual/audio canon, budgets, and the
launch checklist. `docs/GDD.md` is still the design source of truth for
mechanics/numbers — this file exists so a new wave doesn't have to
re-derive canon from scratch or from screenshots. **Every future wave
reads this file first**, per the rule added to `CLAUDE.md`.

## 1. Pillars

1. **Light vs. dark is the whole game.** No day/night cycle — it's
   permanent night, and the only axis that changes is how much of the
   city you've personally lit. Cold ambient darkness against warm
   point-light sources is the primary visual and navigational contrast
   (GDD §11.1).
2. **Noise and visibility, not a detection meter.** Stealth is a
   simulation (noise radius by action, visibility multiplied by
   flashlight cone/darkness/walls), not a stat bar creeping up (GDD §7).
3. **Power restoration is the reward, not a checkbox.** Restoring a
   district's grid isn't just quest progress — it visibly and
   permanently changes that district's lighting, ambient level, and
   danger level. "Darkness → streetlights turn on" is GDD's own words
   for the main visual reward (GDD §11.1), and it's also the game's
   title. If a system doesn't respect district power stage (ambient
   light, streetlights, enemy density), it's off-canon by definition —
   this was true for the game's own streetlight props at the start of
   the TRUTH WAVE pass (fixed; see `docs/KNOWN_ISSUES.md`).

## 2. Visual canon

**Palette** (GDD §11.2 — the only colors UI chrome may use):

| Token | Hex | Use |
|---|---|---|
| bg-deep | `#0c1016` | Screen backgrounds |
| panel | `#141b24` | UI panels |
| panel-edge | `#2a3340` | Borders |
| brass | `#c9a24a` | Accents, flashlight |
| brass-dim | `#8a7338` | Inactive accents |
| ember | `#b4452f` | Danger, HP |
| steel-text | `#aeb6bf` | Body text |
| bone-text | `#d8d2c4` | Headings |
| stamina | `#5f8a4e` | Stamina |
| teal | `#4a9ab5` | Info |

Banned: pure `#000`/`#fff`, neon, high-saturation colors.

**Night lighting values** (GDD §11.1, verified live via
`district_grading.gd` as of the visual-polish pass — these are the
actual `ambient_light_energy` values wired to `DistrictData.Stage`, not
just design targets):

| Stage | ambient_light_energy |
|---|---|
| DARK | 0.03 |
| PARTIAL | 0.06 (interpolated — GDD doesn't give this one explicitly) |
| STREETS | 0.11 |
| FULL | 0.16 |

Depth fog: single canon color `#1a2133`, density 0.012–0.015 scaled by
graphics tier (GDD §11.6, `district_grading.gd::_fog_multiplier`).

**Fonts** (GDD §11.3, canon since the 2026-08-10 summit): **Bebas Neue
Bold** for headings, **Roboto Condensed** for body, **Share Tech Mono**
for numbers/stats. The old Chakra/Saira/Rajdhani set is stored but must
never be wired to a Theme — `theme_provider.gd` was found still doing
exactly that (via broken `SystemFont` OS-lookups) and fixed this pass.

**UI chrome**: chamfered corners only, `corner_radius` must be `0`
everywhere except genuinely circular controls (e.g. the mobile joystick
base). Grain 8–12% + edge vignette + light dropshadow on panels. No
glassmorphism, no rounded corners, no gradients on icons.

## 3. Audio canon

- Loudness targets (GDD §13, applied via `ffmpeg loudnorm`, see
  `docs/AUDIO_LOUDNESS.md`): **SFX -14 LUFS, ambience -18 LUFS**, true
  peak ≤ -1.5 dBFS.
- 5-layer adaptive music (GDD §13, crossfade 2s): `Ambient_Dark` (120s,
  cold drone) → `Ambient_Lit` (warm) → `Threat_Low` (INVESTIGATE) →
  `Threat_High` (CHASE, 60bpm heartbeat) → `Action_Sting` (combat).
- District ambience beds: `assets/audio/ambience/districts/
  [district]_dark.ogg` × 11 (36s seamless loops, -18 dBFS) plus
  `{suburbs,hospital,power_station}_lit.ogg` variants for restored
  districts — delivered, not yet wired to `MusicManager`'s district-
  switch crossfade (see Known Issues / next-wave backlog).
- Buses: `Master → Music | SFX (Footsteps, Combat, UI, Environment) |
  Voice`.

## 4. Asset budgets

Per GDD §15 (mobile performance) and the art pipeline conventions
observed in delivered assets:

| Asset class | Budget |
|---|---|
| Hero textures | ≤2048² |
| Prop textures | ≤512², target ~500KB on disk |
| Audio (single SFX) | target ~1MB or less (delivered files run 25-324KB) |
| Music/ambience total | <100MB |
| SFX total | <50MB |
| Draw calls | <200 (D1) / <350 (D11) |
| Polygons | <50K per district |
| Dynamic lights | <8 concurrent (rest baked) |
| Particles | <500 concurrent |
| RAM / VRAM | <800MB / <400MB |

## 5. Gameplay canon

Full authoritative stats live in `docs/GDD.md` — this section is a
pointer, not a duplicate (numbers drift; one source of truth):
- Enemy roster + stats table: GDD §6.2 (12 types incl. mini-boss + boss)
- Damage types / status effects: GDD §6.4 / §6.5
- Stealth/noise formulas: GDD §7
- Economy/progression: GDD §8
- Workbench recipes: GDD §9
- Save format/cadence: GDD §10
- Endings (5): GDD §12.4

## 6. Store positioning

Hook: *"Blackout city. You are the grid engineer."* Full copy in
`docs/store/play_store.md` and `docs/store/steam.md` — both now use the
same structure (hook → GDD-sourced bullets → stealth paragraph →
controls → requirements → free-updates line → keywords → rating).
Rating: **PEGI 16** (sustained horror tension, stylized violence with
blood/bleed status effects, a deliberate-mass-casualty narrative
thread).

## 7. 10/10 checklist

- [ ] `bash tools/check.sh` clean (all mandatory gates + boot-flow gate)
- [ ] `bash tools/check.sh --static` clean
- [ ] Before/after screenshots for any visual change land in `docs/shots/`
- [ ] `docs/VISUAL_AUDIT.md` / `docs/KNOWN_ISSUES.md` updated for any new
      finding, fixed or deliberately deferred
- [ ] Perf: draw calls <200 printed/verified headless (not yet automated
      as a gate — see backlog)
- [ ] i18n: every new user-facing string goes through
      `LocalizationManager.t()/tf()` (never Godot's native `tr()` on a
      raw sentence — that bug shipped in 5 files this session, see
      `docs/KNOWN_ISSUES.md`), key added to all 13 locales, i18n gate green
- [ ] Store copy (`docs/store/*.md`) numbers still trace to a live GDD
      section, not stale/invented
- [ ] `docs/HANDOFF.md` updated with real state, not aspirational state
