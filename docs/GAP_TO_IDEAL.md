# GAP_TO_IDEAL — what stands between GOLD MASTER v2 and a 5★ viral-ready release

Honest inventory, 2026-09-10. **P0** = blocks a confident public launch.
**P1** = clearly worth doing before or right after launch, in reach of an
autonomous headless pass. **P2 / OWNER** = needs a human, a device, an
account, real art/audio production, or a design call — cannot be done
from an agent session.

Status of the CLAUDE-owned P0/P1 list: **all closed this pass** (see the
table). What remains is P2/OWNER.

---

## Closed this pass (CLAUDE-owned P0/P1)

| # | Area | Was | Fix | Verify |
|---|---|---|---|---|
| G1 | code | `WowDirector` autoload failed to load (`_flash` var/func collision) — viral juice dead | renamed func | `f3bd1e3`, headless_suite P0 |
| G2 | code | `LOOT_SCRIPT.populate` didn't dispatch → **0 loot in any district**, grid unwinnable | call via `class_name DistrictLoot` | `f3bd1e3`, P2 + `game_test_3d` (`pickups: 12`) |
| G3 | code | 2 `:=` inference errors cascading cold-parse compile failures | explicit types | `f3bd1e3`, compile gate |
| G4 | tech-debt | `_game_test_3d.gd` swallowed failures (`quit()`==0), could hang forever | hard-timeout-as-FAIL + real exit code | `f3bd1e3` |
| G5 | code | district rebuild ran **inside** `DistrictTrigger.body_entered` → every pickup `_ready()` hit "Function blocked during in/out signal" (~140/load); tree surgery mid-physics-signal | `call_deferred("load_district", …)` in `world_runtime._on_district_entered` | this pass, headless_suite (0 occurrences) |
| G6 | code | `document_pickup._collect()` set `collect_area.monitoring` directly inside `body_entered` | `set_deferred("monitoring", false)` (matches `item_pickup_3d.gd`) | this pass |
| G7 | store | listing was EN+RU only | 13-locale sections (title/tagline from shipped i18n; short≤80/full/8 bullets/tags transcreated) | `3babbff`, `gen_store_listing_locales.py --check` |
| G8 | store | no Android adaptive icon of record; export pointed at ad-hoc `assets/ui/` 432s | `store/icon-adaptive/` 1080 layers from the 512 master, safe-zone + extrema verified; export_presets repointed | `3babbff`, `gen_adaptive_icon.py --check`, asset gate |
| G9 | store/ops | no review-response process | `store/review-responses.md` — 5 classes × EN+RU, escalation wired to KNOWN_ISSUES | `3babbff` |

---

## P1 — reviewed, deliberately not changed (would need a Godot-enabled or design pass)

- **Contextual hint system (`scripts/ui/onboarding.gd`)** — fully authored
  and i18n'd, not instanced anywhere; superseded by `tutorial_system.gd`
  + `onboarding_overlay.gd`. Wiring a third hint system in blind is a
  feature-integration risk, not polish. Owner decision: wire it or
  archive it. (`KNOWN_ISSUES.md` dead-code section.)
- **Operational `print()` in `save_system.gd` / `lan_network.gd` /
  `footstep_system.gd` / `stub_crazy_games.gd`** (12 total) — reviewed:
  all are save-recovery / LAN-peer / stub / self-check logging, not
  scratch debug. Left as-is; converting the save-recovery three to
  `push_warning` is a minor future nicety, not a defect.
- **Live language switch on always-open screens** — a couple of screens
  don't retranslate mid-play on a language change (`KNOWN_ISSUES.md`).
  Negligible in practice (you change language from a menu, not mid-fight);
  a broader retranslate-broadcast refactor is P2.

---

## P2 / OWNER — needs a human, a device, an account, or real production

### code / gameplay
- **`game_test_3d_scene` phase 1+ stalls intermittently under `--headless`**
  (`KNOWN_ISSUES.md`). Phase 0 passes and is covered by `headless_suite`
  P2/P2b; phases 1–8 have static coverage in `flow_check.py`. Needs a
  `--windowed` session (or a deeper physics-timing dig) to make the full
  scene reliable. Effort: M. Priority: low (substitutes exist).
- **`headless_suite` P6 soak ends ~10 s** on the pre-existing test-runner
  MENU race (`_boot_check_runner.gd` documents the same). Real players
  boot via `boot_loading.tscn` and never hit it. A true 10-min in-engine
  soak needs the harness bootstrap reworked or a `--windowed` run.
  Effort: M. Priority: low.

### art / VFX / perf
- **Real draw-call number.** Headless renderer is the dummy
  (`draw_calls=0`). `drawcall_estimate.py` models ~38 mesh/2D draw calls +
  ~18 active lights/frame D1 after distance-fade; last real measurement
  was 234 (D11<350 met, D1<200 GDD aspiration not). OWNER: one
  `godot --windowed --path . scenes/tools/perf_check_scene.tscn` run on a
  target device tier. If a low-end tier is bad → P1 design call (fewer
  concurrent monsters/pickups, or a Profiler-guided material merge).
- **Screenshots for the store.** `store/screenshots-plan.md` names the 8
  exact setups (district + camera + power stage). Needs a real playthrough
  with Trailer Mode; can't be captured headless. OWNER.
- **The trailer itself.** `store/trailer.md` + `docs/TRAILER_STORYBOARD.md`
  have the 68–75 s cut and the 5 key-art masters. Needs a human editor
  with capture + an NLE. OWNER.
- **Camera-path polish in `WowDirector`.** The preset table has slots for
  camera moves at first-light / cascade / ending; only shake + flash +
  FOV punch are wired (deliberately — framing needs a Godot pass). P2.

### audio
- **Lit-district ambience beds.** `AUDIO_COVERAGE.md` lists the gaps with
  exact specs; only 3 of 11 lit beds exist. All others are honestly
  spec-only — **no binary was ever fabricated**. Needs real audio
  production (or a licensed CC0 track that satisfies the lit-twin
  contract; web searches per gap class found none). OWNER / audio pass.
- **`industrial_dark.ogg` is 33.994 s vs the 36.000 s house contract** —
  accepted as intentional (85 bpm × 12 bars). Re-rendering for uniformity
  is optional and out of scope. P2.

### store / marketing / release
- **Windowed draw-call run** (above), **real AppLovin MAX SDK key**
  (`RELEASE_CHECKLIST.md` §2 — ships fine on the no-ad debug stub without
  it), **release keystore + signed AAB build**, **Play Console first
  upload + IARC answers + localized listing paste**, **privacy-policy URL
  hosting**, **optional eyes-on playtest** (`docs/HANDOFF.md` "HUMAN
  PLAYTEST SCRIPT v2"). All OWNER, all in `RELEASE_CHECKLIST.md` §0 TL;DR.
- **Native QA pass on the 11 transcreated listing locales.** Title +
  tagline are shipped in-game strings (safe); short/full/bullets/tags
  were transcreated from vetted in-game vocabulary but not reviewed by a
  native speaker. OWNER, pre-submission.

### i18n / a11y
- **Dyslexia-friendly font toggle** was removed from the a11y screen (no
  font asset shipped). Adding one needs a licensed OpenDyslexic-style
  face + wiring. P2 (small, but needs the asset).
- **Auto-aim / aim-assist toggle** was removed (no code path). A touch
  aim-assist is a real mobile-feel improvement but needs design + tuning
  on device. P2.

---

## One-line summary

Every CLAUDE-owned P0/P1 is closed and headless-verified. The residue is
strictly OWNER work (keystore/AAB/Play Console, one windowed perf run,
real audio production, screenshots/trailer capture, native listing QA)
plus two low-priority, well-documented test-harness limitations.
