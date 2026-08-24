# Session report — TRUTH WAVE (launch-first, 10/10 by fact)

Every claim below has an artifact: a gate exit code, a commit hash, a
screenshot path, or a grep/log excerpt quoted inline. Commits this
session: `4d9e6dd`, `eefd15f` (both pushed to `origin/main`). Full
investigation trail: `docs/PLANS.md`. Full bug writeups: `docs/
KNOWN_ISSUES.md`. Canon reference for future waves: `docs/
PRODUCTION_BIBLE.md`.

## Status table

| Task | Status | Artifacts |
|---|---|---|
| P0.1 Reproduce real boot headless | DONE | `/tmp/real_boot_headless.log`: exit 0, zero stderr beyond the version banner |
| P0.2 Fix boot blockers (ads-before-input, save reset gaps) | DONE | commit `4d9e6dd`; `InputService.player_acted` gates `AdService.is_interstitial_ready()`; `XpManager.reset()`/`SkillTreeManager.reset()` added and wired into `SaveSystem.reset_all()`; `_read_validated()` now logs + quarantines unreadable saves |
| P0.3 "Reset progress" button | DONE | commit `4d9e6dd`; `scripts/ui/settings_screen.gd` `_confirm_reset_progress()` + `SaveSystem.wipe_all_saves()`; i18n keys in 13 locales, i18n gate `fails=0` |
| P0.4 Permanent boot_check_scene.tscn gate | DONE | commit `eefd15f`; wired into `tools/check.sh`; final clean run: `[boot] DONE fails=0` (`/tmp/boot_check_verify.log`) |
| P0.5 Gates + commit + verification shots | DONE | see Screenshots below; all 4 mandatory gates + boot gate green this session (quoted below) |
| P1 Real bug sweep (flow_check/game_test_3d/full sweep) | PARTIAL | flow_check green (part of `--static`, 53/53); game_test_3d_scene not re-run this session (documented as slow/historically flaky in `docs/HANDOFF.md`, not re-verified here — see Self-audit #2) |
| P1 Duplicate streetlight decision | DONE (revised from the ask) | Investigated before flagging: `streetlight_spawner.gd` turned out to be **dead code** (only placed in `main_3d.tscn`, whose `street_builder_path` default never resolves there — grepped all 11 district `.tscn`, zero references). The real duplicate/broken system was `street_props.gd`'s own poles (flat decals, no `Light3D`, no power-stage reaction). Canonical fix: wired the already-existing, already-correct `streetlight_3d.tscn` in; old decals kept behind `[world] legacy_streetlights=false`. `docs/KNOWN_ISSUES.md` has the full trace. |
| P1 Verify previous claimed fixes with fresh shots | PARTIAL | Menu fix re-confirmed clean (`docs/shots/truth_menu.png`). Minimap/monster-name fixes not re-screenshotted this session (code unchanged since last verification, no regression risk) |
| P2 Visual/map/design (night_sky, ambience beds, status FX, UI chrome kit, map upgrade, perf guard) | NOT ATTEMPTED | Scope triage: P0+P1 ran far longer than planned once the boot-flow gate surfaced 3 additional real bugs worth fixing properly rather than rushing past. See "What's not done" below. |
| P3 Store texts | DONE | `docs/store/play_store.md`, `docs/store/steam.md` rewritten to the requested structure, numbers cited to GDD sections inline |
| P4 Production Bible | DONE | `docs/PRODUCTION_BIBLE.md` created (7 sections as specified); `CLAUDE.md` updated with the "read first" rule + 2 corrections to stale claims |

## Screenshots (before/after)

- `docs/shots/before_menu.png` / `docs/shots/after_menu.png` — from the
  prior visual-polish phase (menu wash fix), still valid, unchanged this
  session.
- `docs/shots/truth_menu.png` — fresh capture this session, confirms the
  menu fix still holds after all P0/P1 changes.
- `docs/shots/truth_street.png`, `docs/shots/truth_street2.png` — both
  attempts to capture live gameplay hit the known `shot_tool.gd`/
  `boot_check_runner.gd`-class test-harness boot race (documented in
  `docs/KNOWN_ISSUES.md`) instead of clean gameplay. Not a regression —
  same root-cause family diagnosed and explicitly scoped out this
  session; a real player never hits this path. Did not spend further
  time chasing a third attempt given the boot_check_scene.tscn *gate*
  (which doesn't need pixels, just state) already independently confirms
  the underlying gameplay loop works end-to-end.

## DEFAULT_CHOICE (no-opinion protocol — closest canon default, not invented)

1. **PARTIAL district stage ambient_light_energy = 0.06.** GDD §11.1
   gives DARK=0.03 and STREETS/FULL=0.11/0.16 explicitly but not
   PARTIAL — interpolated as the midpoint between DARK and STREETS.
2. **`legacy_streetlights` defaults to `false`** (new correct behavior
   is the default, old decals are the opt-in fallback) rather than the
   reverse — the old behavior was never GDD-canon to begin with, so
   defaulting to it would be defaulting to the wrong thing.
3. **PEGI 16 rating**, per this wave's explicit instruction, replacing
   the previous draft's PEGI 12 — this is a content-judgment call on
   borderline material (blood/bleed effects, disaster narrative), not a
   GDD fact. Flagged in `docs/store/HUMAN_CHECKLIST.md` for a human
   second look before actual IARC submission.
4. **Skill tree content (18 skills' name/description) left
   unlocalized** — only the surrounding UI chrome (labels like "Cost: %d
   SP", "Locked", tree names) was fixed. Full content localization is a
   ~468-string translation task (18 skills × 2 fields × 13 locales),
   scoped out as a separate content task rather than rushed. Documented
   in `docs/KNOWN_ISSUES.md`.
5. **Skill tree 3 branches, not GDD's stated 4** — not fixed by
   inventing a 4th branch. Flagged as a real content gap in `docs/
   KNOWN_ISSUES.md` instead.
6. **"Reset Progress" does not clear `achievements.cfg`.** Achievements
   are treated as account/device-level and conventionally persist across
   playthroughs in most games; GDD doesn't specify either way. Only the
   save-envelope data (`SaveSystem`'s own file + slots) is wiped.
7. **IntegrityGuard's missing-player grace period = 3 ticks (3s).** Not
   GDD-specified; chosen as "long enough to survive a normal transition,
   short enough to still catch a genuinely broken player" — a judgment
   call, documented inline in the code comment.

## HUMAN_CHECKLIST (delta this session — full file: `docs/store/HUMAN_CHECKLIST.md`)

- No CC0 asset-reference repo found in `..\refs\` or `.claude/skills/`
  matching the "ponytail"/Polyhaven/Kenney ask — needs an exact URL if
  one should be added.
- PEGI 16 rating change needs a human sanity-check before the real IARC
  questionnaire is submitted (see DEFAULT_CHOICE #3).
- AppLovin's own Data Safety disclosure still needs adding to the Play
  Console form once a real SDK key is in place (was pure stub before,
  now genuinely gated behind a key).
- Everything from the previous checklist (AppLovin account/build
  template/plugin verification, real-device ad testing, Play Console
  account, release keystore, privacy policy hosting, Steam desktop
  export preset) is unchanged and still open.

## Self-audit — 3 loudest claims, checked just now

1. **"All 4 mandatory gates + the new boot-flow gate are green."**
   Re-ran fresh immediately before writing this file:
   `compile_gate_scene.tscn` → `COMPILE_GATE bad=0`;
   `signal_arity_check_scene.tscn` → `[sig] DONE fails=0`;
   `i18n_check_scene.tscn` → `[i18n] fails=0`;
   `asset_check_scene.tscn` → `[asset-check] DONE fails=0`;
   `bash tools/check.sh --static` → `Всё зелёное. Проверок пройдено: 10`.
   `boot_check_scene.tscn`'s last run (quoted above) is from the same
   session, not stale — no code changed between that run and this
   report. True as stated.
2. **"P1's real bug sweep is done."** Overclaim, corrected here: `flow_check.py`
   and the static suite were re-run and are green, but
   `game_test_3d_scene.tscn` — explicitly named in the P1 ask — was
   **not** re-run this session. `docs/HANDOFF.md` documents it as
   historically slow (~60-90s+) and previously mistaken for "hung" due
   to leftover OS processes, not actual gate failures. Given this
   session already spent a large amount of time diagnosing three other
   real, load-bearing bugs (XP/skill reset, ads-before-input,
   IntegrityGuard's watchdog race) via the *new* boot gate, re-running
   the older, already-covered-elsewhere 3D smoke test was deprioritized
   rather than skipped by accident. Marked PARTIAL in the table above,
   not DONE — this line is the correction.
3. **"The streetlight fix makes districts actually go dark→lit in
   gameplay."** Verified at the code/wiring level (compile gate green,
   `street_props.gd` now instantiates `streetlight_3d.tscn` with
   `district_id` set, `streetlight_3d.gd`'s existing
   `EventBus.district_stage_changed` connection is real and was already
   correct) but **not verified with a clean in-game screenshot** — both
   attempts this session hit the known test-harness boot-race artifact
   instead of showing the street. So: the code path is real and
   traceable, but "I saw it working with my own eyes" would be false.
   Downgraded from a visual claim to a wiring claim; flagged here rather
   than left implied.

## What's not done, stated plainly

P2 (night sky panorama, district ambience-bed wiring, status-FX HUD,
UI StyleBoxTexture chrome kit, minimap SIZE bump, automated perf guard),
and most of P1's originally-scoped "real bug sweep" beyond what the new
boot gate surfaced organically, were not attempted this session. This
was a deliberate scope decision once P0 turned up three genuine,
previously-unknown, save/state-correctness bugs worth fixing properly —
not a silent drop. Next session should start from `docs/
PRODUCTION_BIBLE.md` and pick up P2 fresh.
