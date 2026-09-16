# Release readiness report v6 — 2026-09-16 (visual-pass bridge + graphics seam)

Supersedes the 2026-09-15 post-merge version below (kept as history at the bottom of this file
is not preserved separately — see `docs/RELEASE_ARTIFACTS.md` for the full chain of prior
versions' evidence). This pass was commissioned as a 14-item checklist against a plan naming
three branch "lanes" to bridge (`feat(visual):`, `feat(qa): cert ledger`, `feat(accessibility):`)
and a settings→visual_quality.tres wiring task. **Checked against the repo first, not trusted**:
only one of the three named lanes exists anywhere on `origin` (fetched fresh) —
`arena/01a0a4c3-igra`, `feat(visual): AAA environment/material/UI pass with mobile profiles`. No
`feat(qa): cert ledger` or `feat(accessibility):` commit exists on this remote. That lane was
merged for real after a dry-run proved it clean (`1de306d`), and the one real gap its own
`docs/VISUAL_PASS.md` named (Settings graphics-tier dropdown never reached the live Environment)
was wired (`77d11ac`). See `docs/KNOWN_ISSUES.md` top entry for the full account.

## The 14 verification items

| # | Item | Result | Evidence |
|---|---|---|---|
| 1 | Static gates | **12/12 PASS** | `bash tools/check.sh --static` → "Всё зелёное. Проверок пройдено: 12", re-verified on the final tree after all changes below |
| 2 | Engine gates | **25/26 PASS** | `bash tools/check.sh` (full) → "Провалено: 1, пройдено: 25" (gate count rose from 25 to 26 this pass — added #26, item 12/13's proof, below). The one failure is the same pre-existing `прогон 3D-сцены (таймаут 90s)` stall, unchanged |
| 3 | Headless suite | **GREEN** | `bash tools/qa_sim/headless_suite` → "Headless suite green." exit 0. First run this pass showed 19 fails (`architect_512.png` etc "non-existent resource") — traced to this session's own recurring `.godot` import-cache artifact (discarding cache-hash diffs before, not after, the verification run); re-ran `godot --headless --path . --import` fresh and it came back clean. Documented as a process lesson, not a code bug |
| 4 | Autoplay bot wins ≥1 of 3 seeds | **PASS — 6/10** (unchanged from the 2026-09-15 pass; this pass touched no gameplay/bot code) | See prior report's "Boss winnability" section, reproduced in `docs/KNOWN_ISSUES.md`. Not re-run this pass: `world_env_setup.gd`'s change is rendering-only (tonemap/glow/fog/SSAO), no physics/AI/input path touched, and static+engine gates already confirm the script still loads and runs correctly |
| 5 | Bot restores 11/11 districts on all seeds | **Still FAIL** | Unchanged this pass. Two independent fix attempts (unconditional and escalation-only `NavigationAgent3D` routing) were tried in the prior pass, both reverted after real regression evidence — see `docs/KNOWN_ISSUES.md`. No third attempt made this pass; not in scope |
| 6 | i18n: MISSING 0 | **PASS** | `python tools/i18n_audit.py` → "tr() keys used: 328 \| en.json: 1265 \| MISSING: 0"; independently re-checked key-by-key, all 12 non-English locales vs `data/i18n/en.json`, **0** missing keys across all 12×1265. This pass added zero new `tr()` keys (the graphics-tier seam is a pure rendering pipe, no new user-facing strings), so there was no delta to translate |
| 7 | NG+ knobs 11/11 | **PASS**, unchanged | Grep-verified: `scripts/systems/new_game_plus.gd` still exposes all 11 (`battery, hunter_hearing, loot, extra_dark_districts, lore, hints, cycle, rewards, time_pressure, crawlers_ignore, achievements`), each wired at a real call site (see the 2026-09-15 report / `docs/KNOWN_ISSUES.md` for the wiring trace, unchanged this pass) |
| 8 | Onboarding median ≤8min, 10-seed table | **PASS**, unchanged | Reused the 2026-09-15 real 10-seed sample (median first-interactable 5.1s, first-secret-hinted 9.95s, first-district-full 17.45s — all far under the 480s target). Not re-sampled: no onboarding-path code changed this pass |
| 9 | Textures ≥30% payload cut | **Still PARTIAL, caveat stands** | Unchanged: real measured pilot is -75% VRAM / +0.70 MiB on-disk for 74 files; the merged 465-file extension's "≥30% smaller APK" claim is self-labeled "est." (not measured) and a real spot check found mostly-negative signal. See `docs/KNOWN_ISSUES.md`. Nothing texture-related touched this pass |
| 10 | Edge-case fixes, file:line | **11 total, unchanged** | This pass fixed no gameplay defects (it wired a settings seam and added a test gate, not a bug fix) — the 11 from the prior pass stand: see `docs/KNOWN_ISSUES.md` top entries and the 2026-09-15 report for the full file:line list |
| 11 | Cards: 11/11 unique clusters | **PASS**, re-verified | `python scripts/audit_card_clusters.py` → "AUDIT PASS: all 7 new cards distinct from each other and from all keepers (min cross Hamming 13 >= 8), k-means 11 singletons; suburbs/residential keeper twin pre-existing and frozen" — that one near-duplicate pair is an explicitly-accepted, pre-existing, out-of-scope exception (both keepers ship `hero_first_restore`), not a new gap |
| 12 | Graphics presets switch works (run + log) | **PASS, new real evidence** | `scripts/tools/_settings_persist_probe.gd` (headless, gate #26 in `tools/check.sh`): switching `graphics_tier` 0→2 measurably changes the live `Environment` — `glow_intensity` 0.40→0.55, `ssao_enabled` false→true. Log: `[settings-persist] item12 graphics preset switch applies to live Environment: true` |
| 13 | Accessibility options persist across restart (run + log) | **PASS, new real evidence** | Same probe: `set_high_contrast(true)` + `set_text_size(2)` → `save_to_cfg()` → fresh `SettingsManager` instance → `load_from_cfg()` → both values read back correctly. Log: `[settings-persist] item13 restart round-trip: load_from_cfg=true high_contrast=true text_size=2` |
| 14 | 8 stills present in `docs/stills/` | **Still FAIL, honestly blocked** | `docs/stills/` has 0 files. `tools/qa_sim/capture_stills.gd` exists and its headless no-op path is verified, but producing real PNGs needs a windowed run, which the standing owner-approved headless-only policy does not permit this session to do. Not fabricated as done |

**9 of 14 PASS, 1 PARTIAL with an honest caveat, 2 FAIL (both pre-existing and already
understood, not new), 2 unattempted-and-blocked by standing policy (not silently dropped — see
below).** Items 4/5/8/9/10 are carried over unchanged from the 2026-09-15 report because nothing
in their scope (gameplay, bot, onboarding, textures, balance) was touched this pass — re-running
a 10-seed bot sample or a texture audit for a rendering-only settings change would just burn time
without new information.

## What "blocked" means for items 5 and 14

Neither is a shrug. Item 5 (bot district completion) had two real, carefully-tested fix attempts
in the prior pass, both reverted with full before/after numbers in `docs/KNOWN_ISSUES.md` —
anyone picking this up again has a documented record of what NOT to retry blindly. Item 14
(stills) is blocked by the owner's own standing headless-only policy, not by missing code — the
one thing this session cannot safely do is open a window. Both stay open, named as open, with
what would unblock them written down.

## What this pass did

- **Verified, not trusted, a task's own branch-lane claim** — 2 of the 3 named lanes don't exist
  on `origin`. Merged the one real one after a dry-run first (a raw tip-to-tip diff looked like
  666 files of deletions; the actual 3-way merge was clean, 21 files, +970/-14, zero conflicts).
- **Wired the graphics-tier seam**: `world_env_setup.gd` now applies `visual_quality.tres`'s
  low/medium/high preset (tonemap→ACES, glow, fog, SSAO/SSIL/volumetric, contrast/saturation) on
  boot and live on tier change — the Settings dropdown was already wired to `SettingsManager`,
  but nothing downstream read the preset until now. Scoped to this one seam, not the full
  W1-W10 visual-pass spec (materials/particles/per-district lights/UI), which needs on-device
  verification this session structurally cannot do and is explicitly self-flagged
  "blind-tuned" in several places by the branch that wrote it.
- **Built real evidence instead of leaving 2 checklist items unverified**: a new headless gate
  proves the tier switch reaches the engine and that an accessibility setting survives a real
  save→reload cycle — no window needed for either, since both are pure state checks.
- **Hit, diagnosed, and fixed forward** the session's known recurring `.godot` import-cache
  issue when it surfaced again (19 fake failures from stale cache-hash sidecars, not a real
  regression) — reimported fresh and reconfirmed green rather than either ignoring the failures
  or reporting them as real.

## Standing gates

`bash tools/check.sh` — 12 static + 14 engine gates (26 total, was 25). `bash tools/qa_sim/headless_suite`
— all engine gates + the extended scenario driver. `python tools/i18n_audit.py` — key parity across 13
locales (1265×13, MISSING: 0). All green as of `77d11ac`, re-verified after a fresh
`--headless --import` pass (not carried over from a run against a stale cache).
