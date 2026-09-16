# GAMEFEEL_SPEC — per-event juice, caps, accessibility overrides

Date: 2026-09-16 · Owner: game-feel & QA pass (docs-only) · Skill: `ponytail` (full)
Scope: **spec only — no code, no assets.** This file owns the juice caps and the
per-event budget table. Implementation belongs to a later CODE pass and MUST land
with the gates in §6.

Canon precedence (unchanged): `docs/GDD.md` > `docs/PRODUCTION_BIBLE.md` >
`docs/STYLE_GUIDE.md` > this file. Cross-checked against `docs/VISUAL_PASS.md`,
`docs/KNOWN_ISSUES.md` (§ "Accessibility toggles — 5 of 7 were non-functional",
2026-09-10) and the accessibility canon in `docs/GDD_SUPPLEMENT_v3.md` §S12.2.
There is no standalone `docs/ACCESSIBILITY.md` in this repo; the a11y tab
(`scripts/ui/settings_screen.gd` → `_build_accessibility_tab`) + the
KNOWN_ISSUES section + `tools/qa_sim/a11y_check.py` are the live accessibility
record, and this spec defers to them.

## 1. Why caps exist here

The game is a stealth-narrative night sim (PRODUCTION_BIBLE §1): juice must
*punctuate*, never *shout*. Two of the three cap numbers are safety, not taste:

- **Hit-stop ≤ 80 ms.** Long enough to read as "connect", short enough to never
  feel like a frame hitch. Godot caveat: `Engine.time_scale` is global;
  `PROCESS_MODE_ALWAYS` nodes (pause layer, WowDirector's flash layer) ignore
  scaling, and `WowDirector._cinematic` already owns time-scale for trailer
  mode — hit-stop must refuse to nest (one time-scale writer at a time).
- **Shake ≤ 4 px peak.** At 1080p this is ~1/270th of screen height — felt, not
  seen. Motion must stay under the vestibular-comfort threshold so the
  existing `reduce_screen_shake` toggle is a *safety escape*, not a luxury.
- **Flash ≤ 2 frames (~33 ms @60 fps) at high alpha.** Beyond that it must be a
  **fade** (ramp ≥ 0.4 s, α ≤ 0.30) — which is exactly what `WowDirector`
  already ships, and why nothing in this repo is in violation today. Plus the
  WCAG 2.3.1 rule we adopt project-wide: **≤ 3 full-screen flashes/second**,
  and no pure `#fff`/`#000` (already a palette ban, STYLE_GUIDE /
  VISUAL_PASS §1 — flashes inherit it).

| Cap | Value | Applies to | Does NOT apply to |
|---|---|---|---|
| Hit-stop | ≤ 80 ms per pulse, ≤ 1 pulse / 0.5 s | proposed boss-hit freeze, ending slow-mo | death slow-mo (own rule §5.6), trailer cinematic (already opt-in via `trailer_mode`) |
| Shake | ≤ 4 px peak displacement @1080p, measured (see §6) | every `ScreenShake.add_trauma()` caller | camera *position paths* (none allowed; WowDirector header bans them) |
| Flash | ≤ 2 frames at α > 0.30; ramps ≥ 0.4 s exempt at α ≤ 0.30; ≤ 3 Hz | full-screen layers (CanvasLayer ≥ 0.25 of viewport) | local model flashes (hit-flash, telegraph) — exempt only while the lit region stays < 25 % viewport (§4) |

Trauma ↔ px: `ScreenShake` works in trauma units (quadratic curve,
`shake_intensity = 0.5` world-unit max offset). The spec budgets **trauma per
event** below; the CODE pass converts once, measures with
`scripts/tools/shot_tool.gd` (method: §6.4, case: `docs/QA_MATRIX.md`
QA-AC-05), and *shrinks `shake_intensity`* if 4 px fails — never the other
way. Note: 0.5 world units at close range is already plausibly > 4 px; that
is an audit item (§6.4), not a license to spec larger.

## 2. Override keys

Existing keys (live in `scripts/systems/settings_manager.gd`, surfaced in the
Settings UI; consumed per KNOWN_ISSUES 2026-09-10 fix — `set_setting()` now
dispatches to real appliers):

| Key | Covers | Consumer today |
|---|---|---|
| `reduce_screen_shake` (bool, default **off**) | every camera trauma add | `screen_shake.gd::add_trauma` early-returns |
| `haptics` (bool, default on) | vibration cues | `scripts/systems/vibration.gd` via `SettingsManager.haptics_enabled()` |
| `trailer_mode` (bool, default **off**, **opt-in**) | cinematic layer: slow-mo, FOV punch, HUD hide | `wow_director.gd::_trailer_on` |
| `high_contrast` (bool) | UI/legibility pass-through | `settings_manager.gd::_apply_high_contrast` |
| `sfx` / `music` / `ambient` / `voice` volume sliders | all audio layers below | audio buses (`default_bus_layout.tres`, incl. `Hum` from VISUAL_PASS L4) |
| `hud_opacity` slider | HUD-layer juice (crosshair, banners) | HUD |

**Proposed new keys** (this spec defines name + default + what each must
suppress; implementation is a CODE task; each MUST also pass
`tools/qa_sim/a11y_check.py`, which fails toggles that don't trace to a real
effect path — the exact 5-of-7 failure mode KNOWN_ISSUES recorded):

| Proposed key | Default | Must suppress |
|---|---|---|
| `reduce_flash` (bool) | off | full-screen flash ColorRect beats (`WowDirector._flash_screen`, proposed stinger vignette pulse, hit-flash white-emissive hold → downgrade to ≤ 1 frame dim tint) |
| `reduce_time_fx` (bool) | off | every `Engine.time_scale` deviation: proposed boss-hit hit-stop, death slow-mo (keeps ≥ 0.7 s real hold), trailer slow-mo (FOV punch may remain; it is opt-in) |
| `reduce_ui_motion` (bool) | off | non-essential UI tweens: wallet pulse, banner ease, panel rise from VISUAL_PASS §6 (fades themselves may remain — fades are not motion; if owner wants total stillness that is a *separate* future key, not this one) |

Defaults rationale: conservative = juice ships **on** (it is the game's feel)
but each layer has a named escape; all three proposed keys default to keeping
current behavior *when on*, i.e. they strictly subtract. No effect in §3 may
lack a key from this table or §2's existing list.

## 3. Per-event juice table

Legend — **status**: ✅ implemented today (this spec only *fixes the budget*
and names the override) · 🟨 partially implemented (row names the delta) ·
🔍 proposed (CODE pass; nothing may ship before its gate in §6) ·
**dur**: real-world duration (not game-time; see death row).

| # | Event — live hook | Layer | Effect & magnitude | Dur | Cap check | Override key | Status |
|---|---|---|---|---|---|---|---|
| 3.1 | **Boss hit** — `base_monster.take_damage()` → `_hit_flash()` + `vfx_hit_spark` + `sfx_hit.wav @ −6 dB` + `crosshair_state_changed("hit")` | model flash | white emissive **hold ≤ 2 frames**, then material decay to base over ≤ 0.10 s (today: white persists full 0.10 s before restore — 🟨 fix budget) | 2 fr + 0.10 s | local, < 25 % viewport → flash cap exempt; ≤ 3 Hz trivially | `reduce_flash` (→ 1-frame 15 % dim tint instead) | 🟨 |
| 3.2 | ↑ same event | VFX | spark burst via `_spawn_vfx(_VFX_HIT)` — within VISUAL_PASS §4 particle budget (< 500 concurrent; worst case already 490) | ~0.4 s | n/a | none needed (geometry, not flash/motion) | ✅ |
| 3.3 | ↑ same event | audio | `sfx_hit.wav` @ −6 dB on SFX bus (PRODUCTION_BIBLE §3 mix target −14 LUFS applies to the *file*, playback trim −6 dB) | file | n/a | `sfx` slider | ✅ |
| 3.4 | ↑ same event (boss/tvar only, `is_in_group("boss")` or `mini_boss` roster flag) | time | **hit-stop**: `Engine.time_scale = 0.05` for **60 ms real** (≤ 80 ms cap), max 1 per 0.5 s, refuse when trailer cinematic owns time-scale; skip on Web export (timer-precision floor) | 60 ms | ≤ 80 ms ✅ | `reduce_time_fx` | 🔍 |
| 3.5 | ↑ same event | haptics | light pulse 20 ms (pad/phone) | 20 ms | n/a | `haptics` | 🔍 |
| 3.6 | **Secret found** — `EventBus.secret_found(secret_id)` → `UISFX play_ui("secret_discovery_sting")` (procedural chime fallback −8 dB if `ui_secret_discovery_sting.ogg` absent — guard `_has_ui_sting`) | audio | discovery sting, one-shot, SFX-bus-side; *requirement on landing:* do not re-trigger while a menu overlay is open (today it plays regardless — 🟨) | file | n/a | `sfx` slider | 🟨 |
| 3.7 | ↑ | UI | journal entry + `REWARD_SECRET` line via `inventory_notice` (implemented, `rewards_manager.gd` — +50 coins ×`rewards` knob); toast-manager presentation of the localized `SECRET_..._TITLE` is the 🟨 delta; brass underline sweep on journal button ≤ 1 frame glow | 2.5 s / 2 fr | ≤ 2 fr ✅ | `reduce_flash`; sweep motion `reduce_ui_motion` | 🟨 |
| 3.8 | ↑ | world | **no** camera shake, **no** full-screen flash — discovery is a quiet beat (pillar: light-vs-dark is the reward, not spectacle); optional 24-particle `vfx_strobe` reuse at the secret node only (VISUAL_PASS V3, one-shot, auto-free) | 0.5 s | local < 25 % ✅ | `reduce_flash` | 🔍 |
| 3.9 | ↑ | haptics | double light pulse 15+15 ms | 30 ms | n/a | `haptics` | 🔍 |
| 3.10 | **Stinger** (encounter start) — `BossMonster._ready` first contact → `_play_intro_sting("architect_sting.ogg", −2 dB)`; `tvar_3d` once per encounter (`_sting_played` guard); `UISFX` plays `ui_boss_sting.ogg` on `boss_spawned` *and* `boss_defeated` | audio | intro sting −2 dB (loudest scripted non-impact audio; keep ≤ −2 dB, never above player gunfire peak); Music/SFX already duck via `MusicManager.enter_boss()` | file | n/a | `music` + `sfx` sliders | ✅ |
| 3.11 | ↑ | screen | vignette crush: edges darken 18 % over 0.35 s in / 0.6 s out — **not** a flash (α ≤ 0.30 ramp ⇒ exempt) | 0.95 s | ✅ | `reduce_flash` (skip vignette entirely) | 🔍 |
| 3.12 | ↑ | shake | single trauma add **≤ 0.30** through `ScreenShake` (never raw camera math) | 0.4 s | ≤ 4 px via §1 conversion audit | `reduce_screen_shake` | 🔍 |
| 3.13 | **District enter** — `EventBus.district_entered` → banner (`district_banner.gd`, uppercase id, brass #c9a24a, 3.5 s), `music_manager` crossfade, `audio_atmosphere` LUT/ambience shift (VISUAL_PASS §3) | UI | banner holds 3.5 s as today; optional 0.15 s alpha ease-in/out only — **no movement, no HUD fade-transition** (VISUAL_PASS §6: "never fade gameplay HUD") | 3.5 s | n/a | `reduce_ui_motion` (drops the ease, not the banner) | 🟨 |
| 3.14 | ↑ | audio | music crossfade ≤ 1.2 s + ambience bed at −18 LUFS (PRODUCTION_BIBLE §3); no sting on entry (stingers are for bosses only — 3.10) | 1.2 s | n/a | `music`/`ambient` sliders | ✅ |
| 3.15 | ↑ | world | fog density / grade per district (VISUAL_PASS E5/E12/LUT) — behavior locked, not in this spec's remit | — | n/a | (graphics tier) | ✅ |
| 3.16 | **Daily complete** — `daily_challenge_manager.completed(reward)` → `UISFX play_ui("daily_complete_sting")`; streak `streak_milestone` → `ui_streak_milestone_sting.ogg` | audio | sting + `coins` wallet credit; streak rows (7/30/100 → 150/750/3000 coins) reuse the **same** sting, no separate fanfare | file | n/a | `sfx` slider | ✅ |
| 3.17 | ↑ | UI | toast `+N coins`; wallet number pulse 1.0 → 1.06 → 1.0 in 0.20 s, TRANS_CUBIC OUT — UI scale tween, ≤ 6 % so no layout reflow | 0.20 s | n/a | `reduce_ui_motion` | 🔍 |
| 3.18 | ↑ | screen | **no shake, no flash, no hit-stop** — dailies are chores, not beats of the main loop; escalating here cannibalizes the boss/finale budget | — | n/a | (none needed — nothing to override) | ✅ |
| 3.19 | ↑ | haptics | single medium 40 ms | 40 ms | n/a | `haptics` | 🔍 |
| 3.20 | **Death** — `HealthComponent.died` → `death_sequence.gd`: `Engine.time_scale = 0.3`, red fade to α 0.8 over 0.8 s, then `player_died` → `game_over` 0.6 s slow fade (VISUAL_PASS §6 "solemn" row); heartbeat one-shot bed available (`audio/one_shots/heartbeat_low_loop.ogg`) | time | slow-mo **0.3× for 0.8 s real** — 🟨 audit: today `create_timer(1.0)` runs under the scaled clock ⇒ ≈ 3.33 s real, far beyond feel budget; spec pins *real* time (use engine-side timer semantics or scale the value) | 0.8 s real | hit-stop cap does not apply (different beat); ≤ 1 s hard ceiling | `reduce_time_fx` (keeps a static ≥ 0.7 s hold, no scaling) | 🟨 |
| 3.21 | ↑ | screen | red desaturation fade (not a flash: 0.8 s ramp); vignette at 40 % edges | 0.8 s | fade ✅ | `reduce_flash` (fade stays — it is legibility, not spectacle; HIGH-CONTRAST keeps the HUD readable: `high_contrast`) | ✅ |
| 3.22 | ↑ | audio | low thud + heartbeat loop at −18 LUFS ambient level; music duck to −∞ over 0.6 s | loop | n/a | `music`/`sfx`/`ambient` sliders | 🟨 (loop exists, wiring is CODE scope) |
| 3.23 | ↑ | haptics | heavy 80 ms + 120 ms pattern (last allowed pulse in this table) | 200 ms | n/a | `haptics` | 🔍 |
| 3.24 | **Win** — `EventBus.game_won` → `WowDirector._wow("ending")` preset {trauma 0.45, flash ember α 0.26 over 1.0 s, slow-mo 0.4 + FOV −3° only in `trailer_mode`}; `endings_manager.ending_reached` → `ui_ending_sting.ogg` via UISFX | screen | ember fade 1.0 s α 0.26 (within ≤ 0.30 fade budget); trauma 0.45 peak | 1.0 s | fade ✅; trauma = current shipped value, §1 px audit pending | `reduce_flash` (skip rect), `reduce_screen_shake`, `reduce_time_fx` (skips slow-mo; FOV punch is `trailer_mode`-gated) | ✅ |
| 3.25 | ↑ (grid cascade — all 11 districts restored) — `district_restored` → `WowDirector._wow("cascade")` {trauma 0.55, flash 0.28, slow-mo 0.5, FOV −4° zoom-punch (trailer only)} | screen | highest shipped budget in the game; keep 0.55 as the **global trauma ceiling** (1.0 reserved by curve) | 0.8 s | fade ✅ / px audit | same as 3.24 | ✅ |
| 3.26 | ↑ | audio | ending sting + music resolve via `MusicManager`; `ui_achievement_sting.ogg` may cascade *behind* it (streak of unlocks) — cap concurrent sting layers at 2 | file | n/a | sliders | ✅ |

Budget ledger (per event, shipped + proposed): trauma ≤ 0.55 (cascade ceiling,
3.25), hit-stop 60 ms (3.4), full-screen high-alpha flash 2 fr (3.7's underline
glow is the only one in the table), haptics ≤ 200 ms (3.23). **Concurrent
caps**: at most 1 hit-stop + 1 flash + 1 shake active; overlapping trauma
follows `ScreenShake`'s `minf(1.0, trauma+amount)` and the 4 px *peak* cap, not
the per-add cap — i.e. the CODE pass clamps the summed result.

## 4. Accessibility notes (everything above, in one place)

1. `reduce_screen_shake` zeroes trauma (existing, works — KNOWN_ISSUES
   2026-09-10). It must keep being the *only* shake path; any new code that
   touches `Camera3D.position` directly for juice is out of spec.
2. Proposed `reduce_flash` / `reduce_time_fx` / `reduce_ui_motion` follow the
   same pattern: `SettingsManager.set_setting` → real applier → readable by the
   consumer per-frame (like `screen_shake.gd` reads). a11y_check.py enforces
   the trail; a key without a consumer is a KNOWN_ISSUES repeat, not a toggle.
3. Local (on-model) flashes — 3.1 hit flash, enemy telegraph
   (`monster_telegraph.gd`, 2 red pulses / 0.4 s) — are exempt from the
   full-screen flash cap **only** while the flashing area < 25 % of viewport
   (WCAG general-flash threshold). At FOV 75°, an enemy silhouette occupies
   that budget out to ≈ 3 m; the telegraph's ≤ 5 Hz pattern therefore stays
   local-behavior by contract: never promote a telegraph flash to a
   `CanvasLayer`.
4. Photosensitivity: ≤ 3 full-screen luminance flashes per second, enforced
   centrally (a 0.35 s refractory on the flash layer), not per caller.
5. Captions (`captions_manager.gd` + `content/captions.json`) cover dialogue;
   juice beats are *additionally* carried by toasts (3.7, 3.16) so nothing
   important is audio-only. The death sting is redundant with the red fade —
   neither channel is required to understand "you died".
6. Audio escapes exist for every audio row via the four sliders (no "muffle"
   key needed; PRODUCTION_BIBLE buses are the mechanism).
7. High contrast: all HUD juice rows (3.7, 3.13, 3.17) must render legibly with
   `high_contrast` on — brass-on-panel stays ≥ 4.5:1 against `#141b24` per
   existing palette; no new color tokens introduced by this spec.
8. Trailer mode remains the sole opt-in **enhancement** path (slow-mo + FOV +
   HUD-hide): comfort keys only ever subtract, `trailer_mode` never defaults on.

## 5. Anti-goals (what must NOT be built)

- No camera *position paths* or cutscene lock during juice (WowDirector header
  already refuses; keep).
- No shake/flash on: puzzle solve, shop purchase, menu navigation, district
  enter (3.13), daily complete (3.18) — these stay audio + text only.
- No per-hit shake for trash mobs (only bosses, 3.12-style, gated to boss tag).
- No hit-stop outside boss/tvar group; no hit-stop while `trailer_mode`
  cinematic is active (single time-scale writer).
- No new audio bus (bus layout frozen by `default_bus_layout.tres` +
  VISUAL_PASS L4 `Hum`).
- No `#fff`/`#000` flashes, no neon (palette ban).
- Do not revive `auto_aim` / dyslexia font UI as "game-feel accessibility" —
  both were removed for cause (KNOWN_ISSUES 2026-09-10); adding juice toggles
  must not imply re-adding those.

## 6. Gate & verification plan (for the CODE wave that implements 🔍/🟨 rows)

1. `bash tools/check.sh --static` green (currently 12/12; any new i18n label
   for the three proposed toggles must keep it green — 13-locale parity is a
   hard gate).
2. `python3 tools/qa_sim/a11y_check.py` — new keys must pass the trail check.
3. Four headless gates + boot gate: `compile_gate_scene.tscn`,
   `signal_arity_check_scene.tscn`, `i18n_check_scene.tscn`,
   `asset_check_scene.tscn` (AGENTS.md; boot-flow gate built into
   `tools/check.sh`).
4. **Px audit (owner-eyes + shot_tool)**: capture base frame vs peak-shake frame
   at 1080p for trauma {0.15, 0.30, 0.55} at 6 m and at 1 m; max absolute pixel
   delta ≤ 4 px, else clamp `shake_intensity` (single exported const edit;
   values recorded in `docs/QA_MATRIX.md` QA-AC-05).
5. **Ms audit**: frame-step recording of 3.4 and 3.20; hit-stop ≤ 80 ms real,
   death hold ≤ 1.0 s real.
6. QA regressions: rows QA-AU-0x, QA-AC-0x in `docs/QA_MATRIX.md` are the
   manual companion; a 🔍 row ships only when its QA row passes for
   default + toggle-on.

## 7. Consistency ledger (what this doc does NOT contradict)

- VISUAL_PASS: no UI transitions on `settings_screen` (§6) — no juice row adds
  any. Strobe/particle budgets reused, not re-tuned (§4 of that doc). Banner
  stays transition-free for HUD (§6). `Hum` bus untouched (3.3 uses SFX).
- KNOWN_ISSUES: accessibility dispatch chain fixed 2026-09-10 is the model for
  §2's new keys; the P1 boss-velocity-drift fix (WAVE 6) means hit-stop must
  not reintroduce per-frame velocity writes — freeze only `time_scale`, never
  camera/`velocity` state.
- GDD §11 (visual canon), PRODUCTION_BIBLE §3 (loudness): every audio row cites
  them; no row overrides them.
- `docs/BALANCE_MATRIX.md` owns the numbers for NG+/district/boss *data*; this
  doc owns feel. The death-timer finding (3.20) and Tvar/boss HP inversion are
  recorded there as data observations; the *feel* remedy is here.
