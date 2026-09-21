# Run state — orchestrator pass (2026-09-20)

## Session 6 (2026-09-21/22, v8.0 order-pass): P1 function matrix — DONE

`docs/FUNCTION_MATRIX.md`: 110 rows (89-row spine generated straight from `project.godot`'s
`[autoload]`/`[input]` sections via `tools/qa_sim/gen_function_matrix.py` — cross-count proof
in the doc's own methodology section — plus 21 hand-curated extra rows covering every category
the directive names: save/NG+/achievement/security/economy/stealth/boss/district/audio/i18n).
11 WORKS (everything R0/G1/P0 already verified this pass), 4 BUG (the `settings_full.gd`
dead-code find + the 3 standing bugs, all carried over honestly, none newly claimed fixed), 4
CANNOT-TEST-HEADLESS, 1 BY-DESIGN-LIMIT, 1 PARTIAL (i18n), 89 UNTESTED — that UNTESTED count is
P2's actual to-do list, not a hidden claim of brokenness.

**Next**: P2, sweep the 89 UNTESTED spine rows (autoloads/input actions) toward WORKS/BUG/
CANNOT-TEST-HEADLESS/BY-DESIGN-LIMIT, prioritizing rows reachable from the same G1 GUI-ENGINE
harness (in-run pause/inventory/map/flashlight/interact, still not built — see G1's own
residual note above) before reaching for headless scripted probes for the rest.

## Session 6 (2026-09-21/22, v8.0 order-pass): P0 truth gates — DONE

**P0: all three truth gates built, wired into `tools/check.sh` as blocking, and verified real**
(not just "runs without crashing" — each one caught and helped fix a real issue this pass):

- `tools/qa_sim/visual_truth_gate.py` — hue-based magenta%/black%/HUD-presence check on windowed
  PNGs. Wired as a static check against the committed R0 evidence frames
  (`docs/stills/evidence/r0_after_*.png`) as a permanent regression lock — PASS now, will FAIL
  if the R0 fix ever regresses. No live Godot needed (reads committed files).
- `tools/qa_sim/audio_truth_gate.gd` (+ `_audio_truth_bootstrap.gd`,
  `audio_truth_gate_scene.tscn`) — RUNTIME proof the Music bus isn't silent (peak dB via
  `AudioServer.get_bus_peak_volume_left/right_db`), which `flow_check.py`'s static bus-layout
  parsing can never catch (a bus can exist by name and still never receive audio). Self-skips
  under `--headless` (no real audio device) exactly like `perf_check_scene.tscn` self-skips on
  draw calls — wired into `check.sh`'s engine-checks section, real check needs `--windowed`.
  **First real run correctly FAILED** (peak stuck at -80dB/silence) — root-caused by reading
  `music_manager.gd`, not guessed: every music/ambient layer is deliberately held muted until
  the player's first real input (`_unlock_audio()`, gated on `_input()`'s `event.is_pressed()`
  — this project's own documented "no boot-hum" measure, already gated separately by
  `audio_hum_check_scene.tscn`). The probe never sent any input, so it never unlocked. Fixed by
  injecting one synthetic `InputEventKey` via `Input.parse_input_event()` after boot, matching
  what a real player's first click does for free. Re-run: **PASS, peak=-11.9dB**.
  (Along the way, also caught and fixed a *self-inflicted* bug: R0's temporary Lossless
  reimport test on the sky panorama texture had been reverted via `git checkout` on the
  `.import` file without re-running `--import` afterward — exactly the standing lesson already
  written above in Session 5's entry, which I didn't follow the first time. Left a stale/broken
  `.godot/imported/*.ctex` reference that made `world_env.tscn` fail to parse. Fixed with one
  `--import` pass; re-affirming the lesson: reverting an `.import` file and reimporting are a
  matched pair, never do one without the other.)
- `tools/qa_sim/i18n_truth_gate.py` — static, per-key check across all 13 `data/i18n/*.json`
  against `en.json`: missing keys, mixed-script (CJK+Cyrillic+Arabic combined in one string;
  Latin is exempt, this project's own convention keeps some tokens untranslated on purpose),
  and length ratio >1.6x (only for base strings ≥12 chars — the first real run flagged ~100
  strings per locale that were all short single words like "Save"→"Sauvegarder", a completely
  normal, correct translation expansion, not a bug; hand-verified before adding the floor
  rather than shipping a gate that cries wolf on fine translations). Wired as a blocking static
  check. **Current real result: 4/12 PASS** (ja/ko/zh/zh_TW clean; ru/es/de/fr/it/pt_BR/tr/ar
  each still show a handful of length-ratio flags, e.g. `AD_REVIVE`, `Crouch Input`). Zero
  missing keys, zero mixed-script anywhere — matches the `gui_explore_runner.gd` G1 finding of
  solid i18n plumbing. **Honest residual for P3**: the remaining overflow flags are a STATIC
  PROXY (raw character count), not a confirmed visual bug — several of the flagged rows already
  render inside `autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` labels with generous width
  (`settings_screen.gd`'s `_slider`/`_toggle`/`_dropdown` rows), which would swallow the extra
  length with zero visible overflow. P3 needs to check each flagged string against its ACTUAL
  UI container (fixed-width button vs. autowrap label) before treating it as a real bug to fix,
  not just satisfy the raw ratio.

Static gate baseline with all three wired in: **13 static checks, 1 failing** (i18n_truth_gate,
honestly, per the residual above — not fudged to pass).

**R0 (render root-cause): CLOSED.** Owner confirmed with their own eyes the magenta corruption
is real (headless gates never see it — dummy driver, no GPU). Root-caused empirically, NOT
guessed: tested rendering method (gl_compatibility/forward_plus/mobile — all 3 corrupted
identically, ruling out renderer/driver), glow (disabled via temp env-var override — zero
change, ruled out), sky panorama VRAM compression (temp Lossless reimport — zero change, ruled
out), then isolated it to `scaling_3d/scale=0.8` (sub-native 3D render + FSR upscale) breaking
`SCREEN_UV` alignment for every `hint_screen_texture` read in
`scripts/post_process_overlay.gd`'s chroma-aberration shader (active by default per district
via `assets/textures/postfx/presets.json`). Fix: `scaling_3d/scale` 0.8→1.0 in `project.godot`.
Verified project-wide across all 3 rendering methods with a new hue-based measurement tool
(`tools/qa_sim/visual_truth_gate.py`, also P0's first truth gate):
  before: gl_compatibility 2.46% · forward_plus 13.82% · mobile 2.67% (all FAIL, >1%)
  after:  gl_compatibility 0.09% · forward_plus  0.11% · mobile  0.12% (all PASS)
Evidence frames: `docs/stills/evidence/r0_before_*.png`, `r0_after_*.png`. Committed `24116c4`
`fix(render): scaling_3d/scale 0.8->1.0 -- magenta 2.46%->0.09% (gl_compatibility)`, pushed,
`git ls-remote`==`git rev-parse` verified match.

**Also found this pass, record for P6**: `docs/REDTEAM_CHALLENGE.md` and
`docs/RENDERING_DIAGNOSIS.md` (the order-pass directive says these are "arena"-authored and
must be read/closed before tagging v8.0.0-rc1) **do not exist anywhere in this repo** — checked
`main`, every local branch, and every `origin/arena/*` remote ref via `git ls-tree -r` per
branch, zero matches. Do not re-search for these at P6; the directive's premise about their
existence is stale or mistaken. Treat their P0/P1-closure requirement as vacuously satisfied
(nothing to read, nothing to close) and note this explicitly in the final sign-off's RESIDUAL
line rather than silently skipping it.

**G0: OS-level SendInput/PrintWindow abandoned, real finding not a guess.** Built
`tools/gui_driver.ps1` (Add-Type user32 P/Invoke: SetForegroundWindow, SendInput/mouse_event,
keybd_event, CopyFromScreen) exactly as specified, then validated it before trusting it: a
launched, live, `Responding=True` Godot process never got a `MainWindowHandle` (polled 20s) and
`MainWindowTitle` stayed empty. Diagnosed via `[System.Diagnostics.Process]::GetCurrentProcess().SessionId`
→ this automation session runs in Windows **Session 4**, not the interactive session the owner
is physically logged into — any window this session creates exists on a desktop nobody can see,
so `SendInput` would move nothing the owner's own eyes could verify and `CopyFromScreen` would
capture whatever's on a screen that isn't this window. Continuing to build on top of that would
manufacture fake "OS-level" proof, which is exactly what "NO GUESSING" forbids. Deleted
`gui_driver.ps1` (dead in this environment, misleading to leave around) and switched to the
directive's own named fallback: real in-engine `InputEvent` injection via a debug driver
(`tools/qa_sim/gui_explore_runner.gd` + `scripts/tools/_gui_explore_bootstrap.gd` +
`scenes/tools/gui_explore_scene.tscn`, same survive-scene-swap bootstrap pattern as
`capture_stills.gd`), keeping the already-proven-real screenshot method R0 used throughout
(`get_tree().root.get_texture().get_image()` — genuine GPU pixels, not desktop-compositor
capture). Every result line this produces is labeled **GUI-ENGINE**, never GUI-OS, per the
directive's own honesty rule for a degraded fallback. **Next session: don't re-attempt
SendInput/PrintWindow in this environment — the session-isolation finding above is why, not a
transient flake.**

**G1 progress (GUI-ENGINE), verified real, committed**: `gui_explore_runner.gd` covers
main-menu button navigation (Settings/Difficulty/Credits, click via `btn.pressed.emit()` — a
geometric `push_input()` click was tried first and silently failed to register despite a valid
Button ref, not yet root-caused, dropped in favor of the reliable signal-emit method already
used for the language dropdown) and the full 13-language settings sweep (select each
`LocalizationManager.SUPPORTED` index on the real language `OptionButton`, found by its unique
13-item count, verify `LocalizationManager.current_lang` changed and the rebuilt settings title
`Label.text` is non-empty and single-script). Result: **19/19 PASS, 0 BUG** — all 3 menu
buttons navigate correctly, all 13 locales produce a distinct, non-empty, single-script title.
**Not yet built**: in-run exploration (pause/inventory/map/flashlight/interact — G1 item 3) —
needs its own slice, geometric click helper was removed as unused this pass, re-add when that
slice starts.

**Second environment limitation found and root-caused this pass (3 attempts, then stopped
per TIMEOUT RULE, same discipline as a truth gate)**: multiple `get_tree().root.get_texture()`
screenshots taken within ONE Godot process in this session are unreliable past the first call.
Attempt 1 (plain real-time wait, 0.2-0.3s): every shot after the first came back byte-identical
to frame 1 (frozen). Attempt 2 (+ `RenderingServer.force_draw()`): identical, still frozen.
Attempt 3 (+ `await RenderingServer.frame_post_draw` x5, + a 3s real-time wait): the image
finally changed, but to a state from SEVERAL SHOTS EARLIER in the run, not the current one
(directly verified: a shot logically taken right after entering Settings in English came back
showing the main menu in Portuguese, a language only selected many steps later in the same
run) — a lagging backlog against a render pipeline nothing is actually compositing/presenting,
not a simple cache, and not fixable by waiting longer from inside the script. Root cause ties
back to the G0 finding above (no real desktop consuming these frames). `capture_stills.gd` is
NOT affected the same way — its shots are minutes apart during continuous 3D gameplay (real,
constant engine activity), not seconds apart against a mostly-static 2D UI. Fix applied:
`gui_explore_runner.gd` now takes exactly ONE screenshot per process launch (the initial menu,
before any backlog can form) and relies entirely on the (unaffected, always-correct) node-state
data checks for every subsequent step. **Next session: if UI-flow screenshots are ever needed
beyond the first, spawn a fresh process per shot (like `shot_tool.gd`'s `--shot=` pattern) —
do not try to fix multi-shot-per-process capture in this environment again, it has now failed
three independently-designed ways.**

**Next**: finish this run's results → P0 (finish audio/i18n truth gates) → P1
(FUNCTION_MATRIX.md, merge G1 rows) → P2 (sweep to 0 BUG/0 UNTESTED, incl. the 3 standing bugs:
`_game_test_3d.gd` phase-7 harness, park-travel inf-position softlock, residential softlock
flakiness, PLUS the new `settings_full.gd` dead-code finding below) → P3 (real language
switching — likely already mostly built, see finding below, P3 becomes mostly verification) →
P4/P5 (visual + store shots) → P6 (regression lock + `v8.0.0-rc1` sign-off).

**Found this pass, record for P2/matrix**: `scripts/ui/settings_full.gd` (a second, older
settings-panel implementation with its own `LangOption` dropdown) is referenced by **zero**
`.tscn` files and loaded/instanced nowhere in code — only appears in
`scripts/tools/validate_list.txt`, which is a flat auto-enumerated inventory, not a usage site.
The live settings screen is `scripts/ui/settings_screen.gd` (routed via `Routes.SETTINGS` from
`main_menu.gd`'s Settings button). `settings_full.gd` looks like dead code, not a planned
feature — confirm with one more search pass before deleting (CLAUDE.md hard rule: proven dead
*and* not planned).

**Found this pass, encouraging**: runtime language switching already looks comprehensively
wired — ~30 UI scripts connect to `LocalizationManager.language_changed` and rebuild/retranslate
themselves (grepped, not guessed: `main_menu.gd`, `settings_screen.gd`, `pause_menu.gd`,
`hud_3d.gd`, `codex_ui.gd`, `achievements_ui.gd`, and ~24 more). The full chain
`settings_screen.gd` dropdown → `SettingsManager.set_language()` → `LocalizationManager.set_language()`
→ `TranslationServer` + `language_changed.emit()` → every connected screen rebuilds, live, no
restart — read end-to-end, not assumed. P3 may turn out to be mostly a verification pass over
already-real functionality rather than a build task; the i18n_truth_gate (P0, not yet built)
and a full G1 sweep will confirm or find the gaps.

## Session 5 (2026-09-21, v7.5 ceiling pass): TIMEOUT — unwrapped headless run hung 54 minutes

`godot --headless --path . res://scenes/tools/attack_sim_scene.tscn`, run manually (NOT through
`tools/check.sh`'s `run_gate`, which already wraps every gate in `timeout "$t"` — that safety net
was just bypassed by running the scene directly). Process sat alive for 54 min printing a stream
of `.godot/imported/*.ctex` load failures from `MapController` (an autoload, so it boots on
EVERY scene regardless of which one is passed on the command line) → `city_map.gd` → texture
loads, never once reaching `attack_sim.gd`'s own `_ready()` (confirmed: zero `[attack-sim]` lines
in the log). Root cause: the `.godot/imported/` cache was stale again — a `git checkout -- '*.import'`
earlier in this same session (meant only to discard harmless churn per the standing lesson) also
reverted the *fix* from an earlier `--import` pass in this session, undoing it. Killed both PIDs
by hand (`Stop-Process -Force`) after confirming via `Get-Date` the run was genuinely stuck, not
slow. **New standing rule**: never revert `.import` files mid-session without re-running
`--import` again immediately after — the two are a matched pair, not independent cleanup steps.
**Also new standing rule**: every manual (outside `run_gate`) Godot invocation this session
forward gets an explicit `timeout Ns` prefix — `run_gate` was already safe, the manual verification
command wasn't. Added a 45s in-scene watchdog to `attack_sim.gd` itself as defense-in-depth for
any future stall inside the gate's own checks (not this boot-time one, which happens before
`_ready()` runs at all and no in-scene code can catch).

## Session 4 (2026-09-21, v7.3.1 pass): Phase M0 arena backlog re-audit

Re-checked all 5 still-unmerged `origin/arena/*` refs from the 2026-09-20 "Arena branches
NOT merged" table below, plus `origin/gh-pages` (not an arena ref — GitHub Pages privacy-
policy deploy target, `fb2ca98`, unrelated to game code, out of scope). `git branch -r
--no-merged main` shows the same 5 arena refs as before; nothing new landed since. Docs(audio)/
docs(debug)/docs(ideal) branches the directive expected to check for **do not exist on
origin** (`git log --all --grep` for those subjects: zero hits) — Phase W and Phase A both
fall to their no-branch-found path below.

| ref | action | proof |
|---|---|---|
| `arena/019ffbd0-igra` | skip — real conflict | `git merge-tree --write-tree main origin/arena/019ffbd0-igra` shows 3-way conflicts starting at `.gitignore`/`README.md`, real divergence not a trivial rename; matches 2026-09-20's own finding (110 conflict lines then, still conflicting now) |
| `arena/01a07b1c-igra` | skip — real conflict | same command conflicts on `data/i18n/*.json` (all 13 locale files) and the weapon-system scripts; main already has a live `scripts/weapons/` system this branch's `WeaponBase` rework overlaps, unverifiable without a full regression pass this session doesn't have room for |
| `arena/01a09af1-igra` | skip — stale + conflicting | conflicts even on `tools/qa_sim/autoplay_bot` itself; 552-file diff with multiple merge bases (two already-merged branches merged into each other) — confirmed stale per 2026-09-20's own note, not re-litigated further |
| `arena/01a0ab24-igra` | skip — superseded | docs-only (`GAMEFEEL_SPEC.md`/`QA_MATRIX.md`/`BALANCE_MATRIX.md`), but `diff main:docs/QA_MATRIX.md` vs the branch's version shows main's is a strictly newer, extended version (40 base + 30 RC-extension cases, dated 2026-09-20, vs the branch's original 2026-09-16 base) — already transplanted and evolved past, nothing left to take |
| `arena/card-unique-rescue` | skip — rejected, not re-checked | per directive's own instruction: "REJECTED for fabricated cert — never merge, extract nothing"; not re-opened |

0 merged, 0 cherry-picked, 5 skipped (all with real evidence, not guesses). No commit needed
beyond this doc entry — nothing changed on disk. `chore(merge): arena backlog 0 refs (all 5
re-verified skip)` covers this table.

## Session 4, Phase W: residential spine-softlock — still open, two hypotheses down

No `docs(debug):`-subject branch exists on origin (checked above) — took the no-branch path:
fresh analysis avoiding the already-rejected `PICKUP_TOUCH` hypothesis, tried ONE alternative
(`NavigationAgent3D`-based bot pathing instead of straight-line `_dir_to()`, mirroring
`base_monster.gd`), verified with a real 3-seed run: **0/3, softlocks in `park`/`hospital`/
`suburbs`** (the last one new — `suburbs` had never failed before) — worse than baseline.
Reverted, never committed. Full writeup with both rejected hypotheses (the earlier
`PICKUP_TOUCH` one and this one) plus one ruled-out lead (the "locked boiler room" zone
metadata, which turned out to have zero code enforcement — `district_loot.gd` places all
fixed-spawns by seeded scatter, no real doors/zones exist in 3D) is in
`docs/KNOWN_ISSUES.md`. **More data needed, not guessing further this pass**: the residential
softlock's real mechanism is still unconfirmed. A next session should add position-level
telemetry INSIDE the 45s stall window (the current 5s heartbeat cadence is too coarse to see
what the bot is actually colliding with) before trying a third fix.


## Session 3 (2026-09-20, later): balance consumption from arena design audit
Consumed `docs/DESIGN_AUDIT_ARENA.md` from `arena/01a0bdfa-igra` (`docs(design):`
commit `0a15e5e`, 8 proposals P1-P8; a later `docs(qa):` commit `a365088` on the same
branch extends `docs/QA_MATRIX.md` + adds an owner checklist, docs-only; renamed to
`docs/RC_OWNER_CHECKLIST.md` on merge — collided case-insensitively with the pre-existing
`docs/release_checklist.md` on this Windows checkout otherwise, see RELEASE_ARTIFACTS.md).

**Critical regression found and fixed first** (`d6c86cc`): the PRIOR session's own
"player speed fix" (`data/balance/player_stats.tres` 170/300/90 → 1.7/3.0/0.9) was
wrong. It was based on comparing the player's raw speed number to monster speed
numbers and assuming proximity was correct, never checked against actual behavior.
`tools/qa_sim/autoplay_bot` proved it: with the "fixed" values, 0/3 seeds won, all
stuck within meters of spawn within 45s (district distances need the original
traversal speed). Reverted to 170/300/90; bot confirmed 3/3 wins. Corrected
`docs/GAME_AUDIT.md` in place (finding #2 + score rows) rather than deleting the
record of the mistake. **Lesson for next session: never ship a numeric balance
change without an `autoplay_bot` run first** — this one sat unverified in `main`
for an entire session before this pass caught it.

Applied from the arena audit (zone: balance/data files, gameplay scripts):
- P6 (coin-economy reporting) + P7 (duration-target scoping to DARK) — `8f48faf`,
  docs/simulator-reporting only, zero runtime delta, no bot test needed (verified the
  new `[7]` balance_sim.py section reproduces the audit's derived numbers exactly).
- P1 (repair the stealth skill investment) — `2a88503`: `silent_steps` was reducing
  a noise-radius signal with zero listeners instead of the noise scalar monsters
  actually read; `_state_investigate()` re-armed its own search timer to 5.0 every
  tick on arrival, so search never expired. Both fixed. Bot: 1/3 win, 2 softlocks —
  both after restoring 2-4/11 districts in nav-heavy districts (park/hospital)
  unrelated to noise/investigate logic, matching this repo's own documented
  historical baseline (`docs/KNOWN_ISSUES.md`: "6/10 wins... spine-navigation
  failures"). Meets the audit's own stated target (>=1 win, 1-2/3 expected, not 3/3).

**Not applied — out of zone:** P2 (new `low_profile`/`quiet_pace` skills) and P3
(NG+ menu-copy rework) both require new keys across all 13 `data/i18n/*.json` locale
files, which is `cl/a11y-i18n`'s zone per `docs/AGENT_ZONES.md`, not mine. Their
non-localization pieces (skill effect wiring, routing logic) are ready to implement
once locale keys exist — see `docs/DESIGN_AUDIT_ARENA.md` P2/P3 for the exact
proposed strings and target files.

**Not applied — deferred, not evidence-rejected:** P4 (pause `proc_audio.gd` with
gameplay), P5 (make purchased battery capacity real instead of clamped to 100), P8
(fix `MonsterTelegraph`'s mesh-lookup timing so the boss P1 warning is actually
visible). All three passed a read-through and looked implementable, but after the
speed-revert finding above this session deliberately stopped adding balance/gameplay
changes rather than rushing three more without individually-verified bot runs. Each
still has full file/line detail and acceptance criteria in the arena doc.

## Phase M (merge check): WAITING
Lane readiness: arena design branch — ready (`arena/01a0bdfa-igra`, consumed above).
Arena QA branch (`docs(qa):`) — ready (`a365088`, docs-only, same branch).
`docs/RUN_STATE_OC.md` (OpenCode) — **missing**. `docs/RUN_STATE_CL.md` (Cline) —
**missing**. Not all lanes ready; per protocol, stopping here rather than merging or
polling. No merge, no tag, no `RELEASE_READINESS_REPORT.md` v7.2 this session — those
are gated on OC+CL finishing or an owner "MERGE NOW", neither of which happened.

## This session (2026-09-20): full-game audit + gameplay fixes
- Phase 0: `gh auth status` not logged in (device-flow login needs a human at
  github.com, can't complete headlessly) — skipped per "never block on gh". Push path
  proven directly via git instead: `git ls-remote origin refs/heads/main` ==
  `git rev-parse main` after every push below, all matched.
- Phase 1: `docs/GAME_AUDIT.md` — full score table, 9 P1 fixes shipped, 6 findings
  documented but not fixed (zone boundary / needs playtest / needs design call), 5
  design improvements with acceptance criteria. Read it for detail; commits:
  `f1002d3` `7ec2e3a` `f7832c1` `ee273ee` `6bf1deb` `cab439b` `ac847af` `4c0be57`.
- **Gate baseline changed since the last orchestrator pass — verified, not a
  regression.** Full `bash tools/check.sh` (non-static) now shows 20/26, not the
  previously-recorded 25/26. The 6 failures are compile-gate, asset-check, 3D-scene
  (the already-documented pre-existing stall), save-integrity, boot-flow, and
  theme-unify. Root-caused all 6 before touching anything:
  - compile-gate / asset-check / theme-unify all fail on the *same* pre-existing
    cause — stale/missing `.godot/imported/*.ctex` cache for several PNGs
    (`city_iso_2048.png`, `btn_tex_disabled.png`, `quickslot_v2_72.png`, and 41/41
    item icons in asset-check) in this headless environment. Confirmed present
    *before* any Phase 2 edit (same error in a standalone `scene_smoke.gd` run at
    the very start of this session).
  - save-integrity / boot-flow: confirmed via `git stash` A/B test — both fail
    identically (byte-identical error messages) against pristine pre-session code.
    save-integrity fails *worse* on pristine (13 fails incl. basic save/load
    round-trip) — a `user://` filesystem behavior issue in this sandbox, not
    anything in `save_system.gd`.
  - Static gate (12/12), `scene_node_check.py` (clean), and
    `tools/qa_sim/balance_sim.py` (PASS) all stayed green throughout.
  - Not fixed this session: none of these 6 are in scope for a gameplay-fix pass
    (they're headless-environment/import-cache issues, not code bugs) — flagging
    here so the next session doesn't re-litigate the stash A/B test.
- Phase 3 (integrator): **not run.** Neither trigger condition met — no literal
  "MERGE NOW" from the owner this session, and `docs/RUN_STATE_OC.md`/
  `docs/RUN_STATE_CL.md` still don't exist (OpenCode/Cline haven't started).
  Unchanged from the stance below.

---


## Done, pushed
- `86228c6` Phase 0: CLAUDE.md economy rules block; no `.mcp.json` in repo (nothing to disable at
  repo scope); `rtk` not installed, not verified, skipped.
- `ff863c3` Phase 1: merged `arena/01a0b08a-igra` (verified real, clean, conflict-free before
  merging — not trusted from the task description). Gates re-verified after a clean `--import`:
  static 12/12, full 25/26 (only the pre-existing 3D-scene stall). 4 OTHER unmerged `arena/*`
  branches checked and deliberately NOT merged — see below, not silently dropped.
- `8704231` Phase 2: `AGENTS.md` (OpenCode zone), `.clinerules/zone.md` (Cline zone),
  `docs/AGENT_ZONES.md` (manifest). Local branches `oc/visual-w10`/`cl/a11y-i18n` created from
  current main, not pushed (both empty so far).
- `bf0f7c9` Phase 3: `docs/TOOLING_DECISIONS.md` — nothing installed (see file for why).

## Arena branches NOT merged — real evidence, not a guess
- `arena/019ffbd0-igra` (77 files, 2953+/1052- vs main, 110 conflict-marker lines in a merge-tree
  dry run) — deep early-history divergence (commits go back to hiding-spot/save-system fixes
  already shipped on main under different hashes). Real conflict, needs human resolution.
- `arena/01a07b1c-igra` (45 files, 1197+/216-, 71 conflict-marker lines) — FPS weapon-layer
  changes that likely conflict with the live weapon code on main.
- `arena/01a09af1-igra` (552 files, 20244+/343-, 6 conflict-marker lines) — its own history is
  just merges of two ALREADY-merged branches, yet diverges massively from current main. Almost
  certainly stale/abandoned, not safe to merge blind.
- `arena/01a0ab24-igra` (3 files, 517+, **direct semantic conflict**) — a more detailed,
  conflicting `docs/GAMEFEEL_SPEC.md`/new `docs/QA_MATRIX.md`/`docs/BALANCE_MATRIX.md` vs the
  version already wired into shipped code this session (`f372a5c`). Flagged in both zone
  contracts for whoever picks up visual/a11y work next.
- `arena/card-unique-rescue` — already explicitly rejected in this repo's own history
  (`docs/RELEASE_ARTIFACTS.md`: fabricated 22/22 cert, byte-identical blobs to main). Not
  re-attempted.

## Integrator stance
No dev work on `main` right now. Waiting on either owner command "MERGE NOW" or both
`docs/RUN_STATE_OC.md`/`docs/RUN_STATE_CL.md` showing done+pushed (neither exists yet — no
OpenCode/Cline session has started work).

## Owner actions
1. `/model opusplan` (Phase 0 ask).
2. Open OpenCode Desktop on this repo, checkout `oc/visual-w10` — it auto-reads `AGENTS.md`.
3. Open Cline Desktop on this repo, checkout `cl/a11y-i18n` — it auto-reads `.clinerules/zone.md`.
4. When both are done: say "MERGE NOW" (or just wait — this tool checks both RUN_STATE files).
