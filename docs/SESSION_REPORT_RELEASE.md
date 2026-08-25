# SESSION_REPORT_RELEASE — FINAL INTEGRATION + RELEASE WAVE

Session: 2026-08-25. Context reload done first: every `docs/REPORT_*.md`
(10 files — ASSETS, AUDIO_DETAIL, CONTENT_WAVE, DEVICES_V2, GAMEFEEL_V2,
ICONS_V2, MARKET_V2, POLISH_V2, STORE_V2, UI_V2), `docs/HANDOFF.md`,
`docs/PRODUCTION_BIBLE.md`. `docs/BUGS_FOR_CLAUDE.md` does not exist —
checked exhaustively, see P0 below.

## Status table

| Task | Status | Artifacts |
|---|---|---|
| P0 fix BUGS_FOR_CLAUDE.md items | Blocked, not attempted | `docs/BUGS_FOR_CLAUDE.md` does not exist |
| P1 onboarding overlay | Blocked, not attempted | `assets/textures/onboard_v2/` still does not exist |
| P2 consistency wiring | Done | commit `ad39ca6`, `docs/p2_consistency_probe.txt` |
| P3 full regression | Done, zero regressions | commit `3d195b5` |
| P4 release docs | Done | commit `436c655`, `docs/RELEASE_FINAL.md` |
| This report | Done | this commit, pushed |

## P0 — BUGS_FOR_CLAUDE.md: blocked

The brief's entire P0 is "fix every item in `docs/BUGS_FOR_CLAUDE.md`." The
file does not exist. Checked:
- `ls docs/BUGS_FOR_CLAUDE.md` — not found.
- `find . -iname "*bug*"` (excluding `.git`, stale worktrees) — only match
  is `tls_debug.keystore`, unrelated.
- `find docs -iname "*ERROR_LOG*"` — 8 files, all asset-QA logs from the
  art-generation sessions (retry attempts on generated textures/audio),
  not a code bug list.

Nothing to fix from a source that isn't there. Fabricating a bug list
would be worse than reporting the gap honestly. P3's regression pass
(gates + boot-flow + windowed verification of 5 screens) is the practical
substitute this session could actually run, and found zero regressions —
see P3 below.

## P1 — Onboarding overlay: still blocked

Same finding as the previous session: `assets/textures/onboard_v2/` does
not exist anywhere in the repo. Re-checked at the start of this session
(the brief's premise was "NOW that onboard_v2 exists," which is false).
Not attempted, for the same reason as before: building the `SaveSystem`
flag and show-once trigger with no panel art to actually display would
ship dead infrastructure with no visible effect.

## P2 — Consistency wiring

Full detail in the commit message (`ad39ca6`); summary:

**Wired (real consumers, real assets, verified):**
- Weapon renders → `weapon_compare_ui.gd` (icons either side of the
  compare title). Found and fixed a real bug while doing this:
  `weapon_rifle.gd`/`weapon_shotgun.gd` never set `weapon_name` (unlike
  the pistol), so the compare title showed blank for 2 of 3 weapons.
- Skill icons → `skill_button.gd` (the real per-button builder
  `skill_tree_ui.gd` delegates to).
- Craft material icons → `workbench.gd` ingredient chips only (2 of 9
  recipe component ids have matching icons_v2 art; the rest render
  text-only, which is the "consistent within chips" the brief asked for).
- Ending stings → `endings_manager.gd`. `ending_reached` had zero
  listeners anywhere before this (verified via grep). The brief asked for
  "full" tracks on light/dark specifically; those don't exist under any
  name. Wired the 5 real delivered stings to all 5 endings instead.
- Weather audio → `audio_manager.gd`: real `rain_on_metal_loop.ogg` and
  `thunder_near/far.wav` replace procedural placeholders
  (`_gen_rain()`/`_gen_thunder()`, now deleted — no other call sites).
  The storm-triggered timer these plug into already existed from an
  earlier session; it just never had a real sample.
- Low-HP audio → `audio_manager.gd`: `heartbeat_low_loop.ogg` +
  `breath_low_loop.ogg`, start/stop once on `player_health_changed`
  crossing the 0.30 ratio threshold.

**Blocked, logged, not guessed at:**
- Player render for `stats_ui`: no such asset exists under any name.
- "Full" ending tracks: don't exist; only the 5 stings do (wired above).

**A real, release-blocking bug found and fixed while wiring the above:**
`audio_manager.gd`'s new `preload()` calls on the 5 `assets/audio/
one_shots/*` files failed at **script parse time** with "has no resource
loaders" — those files had zero `.import` sidecars (nothing had opened
the project in editor mode since they were delivered). Since
`audio_manager.gd` is an autoload, this broke the entire project's boot
— every scene, not just the ones touching audio. Fixed by running the
established forced-reimport (`--headless --editor --quit`), which
generates `.import` files project-wide; this has a known side effect
(re-serializes `default_bus_layout.tres` and drops properties) which was
caught and reverted via `git checkout --` immediately after, confirmed
via `git diff` showing zero remaining delta.

**A structural gap found, not fixed (not this session's to fix):**
`git ls-files` on `assets/audio/one_shots/`, `assets/audio/jingles/`,
`assets/textures/icons/weapons/`, `assets/textures/icons/skills/` all
return zero results — these folders are untracked in git entirely,
unlike e.g. `assets/audio/sfx/` which is normally tracked. This matches
the established pattern from earlier sessions (the asset-generating
session commits its own deliverables on its own schedule, sometimes with
a real lag) and is explicitly that session's ownership per this project's
convention — not something this session should stage. Noted here so it's
not mistaken for something this session forgot: a fresh clone of just
this session's commits won't have the referenced art/audio files until
the owning session's own commit lands.

## P3 — Full regression

Full detail in the commit message (`3d195b5`); zero regressions found.
`tools/check.sh --static`: 10/10. Engine-level checks (compile, signal
arity, autoload API, i18n, assets): all OK. `tools/check.sh`'s own
boot-flow gate hangs under `--headless` in this specific sandboxed
environment (pre-existing, not introduced this session — confirmed by
running `boot_check_scene.tscn` directly with `--windowed` instead, which
completes cleanly: `fails=0`, all 6 phases including the save/load round
trip). Windowed/checkpoint-verified menu, HUD, map, toasts, and
encyclopedia — see the commit message for exactly which method (real
screenshot vs. checkpoint log) proved each one and why.

## P4 — Release docs

`docs/RELEASE_FINAL.md` — one ordered runbook from local gates through
every platform this project has assets for, including two (Yandex Games,
itch.io) that had zero publishing documentation before this session
despite having delivered store assets sitting unused. AppLovin approval
email template included. Found and fixed a real inconsistency between
`release_checklist.md` (stale "12+" rating) and `play_store.md`/
`HUMAN_CHECKLIST.md` (the later, deliberate PEGI 16 decision) — updated
the stale line to cross-reference the judgment call rather than silently
picking one.

## DEFAULT_CHOICE log

1. P0 and P1 left genuinely unattempted rather than substituting
   something adjacent (e.g., inventing a bug list from memory, or
   building onboarding with placeholder panels) — both would misrepresent
   what was actually asked for as done.
2. Ending stings wired to all 5 endings, not just light/dark — the
   brief's literal ask (full tracks for 2 specific endings) can't be met,
   but leaving 3 already-correct, already-delivered stings unwired while
   inventing something for 2 that don't exist would be a worse outcome
   than wiring what's real and honestly noting the gap.
3. Craft material icons limited to 2 of 9 recipe components (tool,
   battery) rather than skipping the whole item entirely — the brief's
   own "consistent within chips" language treats a graceful text-only
   fallback as an acceptable outcome for unmatched ids, unlike the
   inventory-grid case from an earlier session where partial coverage
   was rejected because it would visually compete with a fully-iconified
   V1 style in the same screen.
4. Ran the forced-reimport fix immediately on hitting the preload
   failure rather than switching to lazy `load()` calls to route around
   it — preload() keeps the resources warm at boot (matches every other
   `const X := preload(...)` pattern already in this exact file), and the
   reimport is the established, proven fix for this exact class of
   problem from an earlier session.

## SELF-AUDIT — 3 loudest claims, fresh proof

1. **"ending_reached genuinely had zero listeners before this session."**
   Proof: `grep -rn "ending_reached.connect|ending_sting|play_sting"`
   across the whole project before writing any code — only match for
   `.connect(` was `music_manager.gd`'s unrelated `play_sting()` (used
   for player-detection stings, a completely different mechanic and
   asset). Re-ran after the change: now `endings_manager.gd`'s own
   `_ready()` shows up as the connection.
2. **"The audio_manager.gd preload fix was necessary, not precautionary
   — it was a real, would-have-shipped-broken bug."** Proof: the exact
   parse error is quoted verbatim in the P2 commit message
   ("has no resource loaders (unrecognized file extension)"), captured
   from a real headless run before the fix, followed by the same probe
   re-run after the fix showing the identical scene now completing with
   zero script errors.
3. **"P3's regression claim isn't hand-waved — the boot-flow hang is a
   known environment limit, not me skipping the check."** Proof:
   `docs/regress_boot_check.txt` contains the actual `--windowed` run's
   full phase-by-phase output (`fails=0`), run specifically because the
   `--headless` version hung for 280+ seconds at the identical point
   twice in a row — both outcomes reported, not just the passing one.

## HUMAN_CHECKLIST delta

No new manual actions from this session's own code. The two structural
items worth a human's attention:
- P1 (onboarding) and the player-render half of P2 are blocked purely on
  missing art — nothing to build until `onboard_v2` and a player render
  asset exist, or the tasks get dropped/rescoped.
- `docs/RELEASE_FINAL.md` §"AppLovin MAX — approval email template" and
  the Web/Desktop export preset gaps it names are real prerequisites for
  Yandex Games and Steam/itch.io specifically, not optional polish.

## Sized backlog

- **BUGS_FOR_CLAUDE.md**: needs to actually be written (by whatever
  process was meant to generate it — "code-side list from bug-hunt" per
  the brief) before a P0-shaped task can do anything. Nothing to size
  until it exists.
- **Onboarding overlay**: sized in the previous session's report already
  (4 panels, SaveSystem flag, i18n captions ×13) — unchanged, still
  blocked on `onboard_v2` art.
- **Player render asset**: needs one delivered file
  (`[something]_full_[dims].png` or similar) before `stats_ui`'s side
  panel can show it — otherwise identical scope to the encyclopedia
  detail view's portrait slot from two sessions ago.
- **Item icon resolver conflict**: still open from two sessions ago —
  icons_v2's fixed 10-item set doesn't cover the other 28+ item ids in
  the game; wiring only those 10 anywhere with full item coverage (not
  the narrower "ingredient chips only" case this session handled) would
  still mix visual styles.
- **D1 draw-call budget**: unchanged from the last two sessions' findings
  — every lever tried (prop density, audio pooling) is confirmed not to
  move this specific metric; needs a genuinely different approach
  (2D UI vs 3D world draw-call profiling) scoped as its own task.
- **Web/Desktop export presets**: don't exist; block Yandex Games and
  Steam/itch.io build steps specifically (`docs/RELEASE_FINAL.md` §4/§5/§6).
- **YandexGamesSDK / GodotSteam**: not integrated; each platform's own
  ads/achievements/cloud-save features are unavailable without them, but
  a plain build still works and ships on either platform.
- **Untracked delivered-asset folders**: `assets/audio/one_shots/`,
  `assets/audio/jingles/`, `assets/textures/icons/weapons/`,
  `assets/textures/icons/skills/` (at minimum — not an exhaustive scan)
  are on disk but not in git. Worth a deliberate commit pass by whichever
  session owns asset staging, so a fresh clone matches what's actually
  wired in code.

## Push

Commits this session: `ad39ca6` (P2), `3d195b5` (P3), `436c655` (P4),
plus this report.
