# SESSION_REPORT_UX — CONTENT UX (DETAIL VIEW + TOASTS + ONBOARD + CONSISTENCY)

Session: 2026-08-25. Context reload done first: PRODUCTION_BIBLE, HANDOFF,
SESSION_REPORT_FINISH, REPORT_DEVICES_V2, REPORT_GAMEFEEL_V2.
REPORT_CONSISTENCY_V2.md does not exist. UI surfaces for existing data/
signals only, zero new gameplay mechanics, zero new data fields.

## Status table

| Task | Status | Artifacts |
|---|---|---|
| P0 toast pipeline | Done | commit `3638151`, `docs/shots/toast_pipeline.png` |
| P1 encyclopedia detail view | Done | commit `a7bfb80`, `docs/enc_detail_probe.txt` |
| P2 onboarding overlay | Blocked, not built | `assets/textures/onboard_v2/` does not exist anywhere - see below |
| P3 consistency wiring | Skipped per its own stated condition | `docs/REPORT_CONSISTENCY_V2.md` does not exist |
| P4 streetlight hum pooling | Done | commit `dd0b582`, `docs/hum_pool_probe.txt` |
| P5 enemy/achievement translations | Done | commit `fa367cb` |
| P6 this report | Done | commit below, pushed |

## P0 — Toast pipeline

`EventBus.toast_requested` is emitted from 10+ call sites (`puzzle_system.gd`,
`power_switch.gd`, `finale_director.gd`, `ftue_generator.gd`/
`ftue_generator_3d.gd`, `daily_events_ui.gd`) but had zero listeners anywhere
in the project — grepped for `.toast_requested.connect(` project-wide before
starting, zero matches. Every "+5 coins", "District restored!", "Boss
appears" notification was silently dropped, every session, since whenever
those emit calls were first written.

A file already existed at exactly the path the brief asked for
(`scripts/ui/toast_manager.gd`, committed by the parallel content-generation
session, never instantiated anywhere, never connected to the signal — its
own `show_toast()` API had zero callers either) with a different shape:
top-right, one toast at a time via a `Timer` queue, text-glyph icons, and a
type vocabulary (`achievement`/`quest`/`warning`/`finding`) that doesn't
match what's actually emitted (`finding`/`achievement`/`objective`/`danger`
— `warning`/`quest` never fire in the whole codebase). This wave's brief
asks for top-left, up to 3 simultaneous, real `icons_v2` art — a different
shape, not a tweak, so replaced rather than patched. The prior version stays
fully recoverable at commit `bddbded` if any of it is wanted later.

Icon mapping (`icons_v2/event_{siren,breaker,blackout}_48.png`) is semantic,
not literal: only `danger` (→siren) and `objective` (→breaker) events have a
real match; `finding`/`achievement` (the other two types actually emitted)
render text-only by design — `blackout` stays unwired, no emitted type maps
to it. Wired as a plain `CanvasLayer` node in `main_3d.tscn`, no autoload,
no emitter-side changes.

Verified via a standalone probe (`EventBus` is a global autoload, didn't
need the full boot flow): emitted 3 toasts (danger/objective/finding),
screenshot confirms all 3 stacked top-left, 2 with icons, 1 text-only —
`docs/shots/toast_pipeline.png`.

## P1 — Encyclopedia detail view

Tap/click an unlocked bestiary card opens a detail panel in the same screen
(`encyclopedia_ui.gd`), not a new scene. Locked cards stay inert — nothing
to reveal, matching the existing "???" placeholder.

Shown, all from existing data, none invented:
- Full portrait (`portraits_v2/[id]_full_512x768.png`) if delivered for that
  monster (6 of 12 ids), else the existing thumb already used on the grid
  card, exactly matching the brief's "else keep current thumb"
- HP and move/chase speed — `MonsterData` fields, already there
- Weak spot — `EnemyRosterData` (`data/balance/enemy_stats.tres`), the same
  roster `base_monster.gd` already reads at runtime for real combat
  behavior, not new data. 11 of 12 monster ids have an entry; `shadow` is
  the one exception (not in `AI_TO_ROSTER` and no matching roster key of
  its own) — the row is simply omitted for it rather than shown blank
- A "Discovered" status line

Deliberately **not** shown: a per-monster encounter or kill count. The brief
asked for "encounter + record counters from existing tracking, no new data
fields, no new tracking" — audited what tracking actually exists
(`Encyclopedia.is_unlocked()`, a boolean; `ProgressTracker`'s `kills` stat,
a single aggregate across every monster type) and found no per-species
counter anywhere. Fabricating one, or mislabeling the global kill count as
if it belonged to one species, would have been the exact kind of invented
data this wave explicitly rules out — so the panel shows what's real
(discovered: yes) and nothing else.

ESC closes the detail panel specifically, not the whole encyclopedia/codex
screen behind it — confirmed against Godot's own docs (not guessed) that
GUI input dispatch (`_gui_input` on a focused Control) runs before
`_unhandled_input`, which is what `ui_manager.gd`'s global ESC handler uses;
the detail panel grabs focus and calls `accept_event()` on `ui_cancel`.

i18n: 13 new keys (`ENC_STAT_HP/SPEED/WEAKNESS/STATUS`, `ENC_DISCOVERED`,
8× `WEAKSPOT_*`) via the established `i18n_new_keys.json` →
`i18n_merge.py` workflow — RU real, other 11 EN-fallback. Weak-spot lookup
keys are spelled out explicitly in a dict rather than built as
`"WEAKSPOT_" + value.to_upper()` — the i18n audit greps literal `t("...")`
string arguments and can't see through concatenation (same fix
`city_map.gd`'s `STAGE_KEYS` array already uses for the identical reason).

**Found and fixed a real regression while running the merge tool**:
`tools/i18n_ru_cyrillic.json` had a stale `INV_WEIGHT` entry (`"Вес"`, no
placeholders) left over from before that string was reformatted to include
the actual weight numbers. Re-running `i18n_merge.py` — the documented,
intended workflow for adding keys — silently overwrote the current correct
`ru.json` value with the stale one, which tripped `check.sh`'s ru/en
placeholder-parity gate. Fixed the stale source entry (one line) and
audited every other `i18n_ru_cyrillic.json` entry against current `en.json`
for the same class of drift — none found.

Verified via a standalone probe with file-based checkpoint logging —
screenshot capture was unreliable for this specific scene in this sandbox
(confirmed the scene itself was correct: 2 children after the grid builds,
3 after `_open_detail()` runs, zero script errors across three separate
runs; the screenshot kept showing an unrelated stale window regardless —
same class of environment flakiness noted in the previous session's report
for a different probe, not a code defect). Log: `docs/enc_detail_probe.txt`.

## P2 — Onboarding overlay: blocked, not built

`assets/textures/onboard_v2/` does not exist anywhere in the repo — checked
the exact path, searched the whole `assets/` tree for anything matching
`*onboard*`, and re-read `REPORT_GAMEFEEL_V2.md` (the most recent art
delivery, which lists `picto_v2/`, `stages_v2/`, `docs_v2/`, `renders_v2`,
`audio/one_shots/` — no `onboard_v2` folder mentioned at all).

The brief asks for "4 panels from assets/textures/onboard_v2/ in order" —
without the art, there is nothing to build the 4 specific panels from.
Building the `SaveSystem` envelope flag (`onboard_done`) and the
show-once-on-first-New-Game trigger without any panel content to actually
display would ship dead infrastructure with no visible effect — the exact
class of bug this whole engagement has been finding and fixing (dead
signals, dead nodes, orphaned scripts), not something worth adding
deliberately. Not attempted. Logged here instead of guessed at.

## P3 — Consistency wiring: skipped per its own condition

The brief states P3 is "conditional: only if REPORT_CONSISTENCY_V2.md
exists." It does not exist (confirmed at the start of this session,
`docs/REPORT_DEVICES_V2.md` and `docs/REPORT_GAMEFEEL_V2.md` both do exist
and were read, `REPORT_CONSISTENCY_V2.md` does not). Skipped as instructed,
not attempted.

## P4 — Streetlight hum pooling

Each lit `streetlight_3d.gd` instance owned its own always-playing
`AudioStreamPlayer3D` — up to 24 simultaneous 3D audio streams per
fully-powered district (suburbs has 24 poles), most beyond
`max_distance=14.0` and inaudible but still mixed every frame. New autoload
`StreetlightHumPool` owns 8 real `AudioStreamPlayer3D` voices; lit
streetlights register/unregister with the pool instead of playing their own
`Hum` node, and every 0.3s the pool re-sorts registered streetlights by
distance to the player and repositions its 8 voices onto the nearest lit
ones. The now-unused per-instance `Hum` node was removed from
`streetlight_3d.tscn` — replaced by the pool, not left as inert dead
weight (48 unused audio nodes doing nothing).

Verified headless (audio/distance logic doesn't need rendering): forced
`suburbs` to stage 3, 48 streetlights registered, `active_count()` = 8
(correctly capped). Moved a fake player 200m away and re-checked —
`active_count()` stayed 8, confirming the pool re-targets to whichever 8
streetlights are nearest rather than holding a fixed assignment (proof of
the "nearest-lit priority" requirement, not just "a pool exists"). Log:
`docs/hum_pool_probe.txt`.

**Draw-call re-measurement (as the brief asked):**

| Run | draw_calls | primitives | objects_in_frame |
|---|---|---|---|
| Before this change (last session's baseline) | 234 | 1,664,125 | 433 |
| After, run 1 | 136 | 1,052,581 | 348 |
| After, run 2 | 234 | 1,664,125 | 433 |
| After, run 3 | 234 | 1,664,125 | 433 |
| After, run 4 | 234 | 1,664,125 | 433 |

4 of 5 post-change runs read identically to the pre-change baseline; the
single 136 reading did not reproduce on retry and is reported as a likely
cold-start sampling artifact, not a real effect — not claimed as a win.
This matches the technical expectation going in: `AudioStreamPlayer3D`
isn't a `VisualInstance3D` and doesn't touch
`RENDER_TOTAL_DRAW_CALLS_IN_FRAME`; `streetlight_3d.gd`'s own pre-existing
comment already said Hum "wasn't the draw-call problem." This is a real
CPU/audio-mixing lever (24 simultaneous positional streams down to 8), a
different metric than `perf_check_scene` measures — not a second guess at
the same one, and not reported as closing the D1<200 gap because it
doesn't. Per the brief's own instruction not to guess further:
D1<200 stays out of reach through any lever available this session; sized
as backlog below rather than forced.

## P5 — Enemy + achievement name translations

11 `ENEMY_*` monster names and 20 `ACH_*_NAME` achievement titles were
verbatim EN copies in all 11 non-RU/EN locales (confirmed before touching
anything: `es.json` matched `en.json` exactly on all 31 keys). Descriptions
(`ACH_*_DESC`) stay backlog, per the brief's own scope — names only.

Translated into es/de/fr/it/pt_BR/tr/ja/ko/zh/zh_TW/ar via the same
established workflow as P1. RU and EN values were pulled verbatim from the
current locale files (not retranslated), confirmed via `git diff` showing
zero changes to `ru.json` — the already-correct Russian wasn't touched.
`ACH_16_NAME` ("Speedrunner") was kept as the loanword in es/de/fr/it/
pt_BR rather than translated — that's genuinely how the term is used in
gaming communities in those languages.

## DEFAULT_CHOICE log

1. Replaced the existing `toast_manager.gd` rather than extending it — its
   design (top-right, sequential, text-glyph icons, mismatched type
   vocabulary) doesn't share enough with this wave's spec (top-left,
   stacked, real icon art) for a patch to make sense; a rewrite was more
   honest than pretending to "extend" something structurally different.
2. `event_blackout_48.png` left unwired in the toast pipeline — no emitted
   `toast_requested` type string maps to it; inventing a use would mean
   guessing at a meaning the data doesn't support.
3. Encyclopedia detail view shows no per-monster encounter/kill counter —
   audited existing tracking and found none exists per-species; showing the
   global kill total on a per-monster panel would misrepresent it.
4. P2 (onboarding) not attempted rather than built with placeholder/
   procedural panels — the brief named a specific art folder that doesn't
   exist; building the save-flag plumbing with nothing to show would ship
   dead infrastructure, the same failure class this whole engagement keeps
   finding and removing.
5. Streetlight hum pool set to exactly `MAX_POOL=8` and `REASSIGN_INTERVAL
   =0.3s` per the brief's literal numbers, not tuned further — the brief
   specified 8 explicitly ("max 8, nearest-lit priority").

## SELF-AUDIT — 3 loudest claims, fresh proof

1. **"toast_requested truly had zero listeners before this session."**
   Proof: `grep -rn ".toast_requested.connect(" .` across the whole
   project (excluding stale worktrees) before writing any code — zero
   matches. Re-ran the same grep after the change — now exactly one match,
   `toast_manager.gd`'s own `_ready()`.
2. **"The encyclopedia detail view actually builds correctly, even though
   its screenshot didn't capture."** Proof: file-based checkpoint log
   (`docs/enc_detail_probe.txt`) showing the exact child count at each
   stage (`ui added, children=1` → `frame1 done, ui children=2` →
   `detail opened, ui children=3`), captured across 3 separate process
   launches with zero script errors each time — not asserted from a single
   run, and not asserted from a screenshot that could itself be showing
   stale content.
3. **"Hum pooling genuinely doesn't move draw calls — the 136 reading
   wasn't cherry-picked as a win."** Proof: ran `perf_check_scene.tscn
   --windowed` 5 times total after the change, reported all 5 numbers in
   the table above including the one outlier, and explicitly did not claim
   the outlier as the result.

## HUMAN_CHECKLIST delta

No new manual actions from this session's own work — the toast pipeline,
encyclopedia detail view, and hum pool are all self-contained code the
gates already cover.

P2's blocker is worth a human decision, not a checklist action: either
`assets/textures/onboard_v2/` gets delivered by the art-generation session,
or the onboarding overlay task gets dropped/rescoped. Nothing to build
until one of those happens.

## Sized backlog

- **i18n remainder**: with this session's 31 keys now real in the 11
  backlog locales, the outstanding count drops from the last report's
  1,562 figure by roughly 31×11=341 strings (not re-audited exactly this
  session — the figure needs a fresh `i18n_audit.py`-style full recount
  next time i18n work resumes, not an arithmetic guess presented as
  measured). `SCR_*` remains the largest single bucket per the last full
  audit.
- **Coin pile tiers** (4 `ui_v2` files): still permanently orphaned unless/
  until IAP is re-enabled (shop explicitly filters out `Kind.COIN_PACK`,
  confirmed again this session was unaffected by anything touched) — a
  product decision, not a code task.
- **ADS (aim-down-sights) design**: carried forward from earlier waves
  (`docs/HANDOFF.md`) — no ADS mechanic exists in the game at all, so the
  delivered crosshair-aim art has nothing to wire to. Needs a design
  decision (should ADS exist?) before any code task can be scoped.
- **Enemy speed baseline**: also carried forward — the GDD's speed
  "×multiplier" language has no documented absolute baseline value
  anywhere in the project. Needs a design decision, not a code fix.
- **D1 draw-call budget (<200, currently 234)**: this session tried the one
  remaining lever the brief offered (audio pooling) and confirmed,
  honestly, that it doesn't move this specific metric. Every lever
  attempted across the last two sessions (prop density, audio pooling) has
  now been ruled out for this metric specifically. What's left of the 234
  is dynamic content the brief itself excludes from batching (monsters,
  pickups) plus lighting/2D-UI overhead not yet profiled separately from
  3D world draw calls. Recommend either accepting the current number as
  the practical floor without a light-node architecture change, or scoping
  a dedicated session to profile 2D UI vs 3D world draw calls separately
  before attempting anything further — guessing again isn't warranted.
- **Portraits_v2 detail-view aspect gap**: no longer fully open — this
  session's P1 wired the 6 delivered `portraits_v2` full-body renders into
  the new encyclopedia detail view exactly where last session's backlog
  note said a detail view would go. The other 6 monster ids (not in the
  original 6-monster icons_v2/portraits_v2 roster) still show no full
  portrait, gracefully falling back to the existing thumb — sizing a
  follow-up: 6 more `[id]_full_512x768.png` renders if full coverage is
  wanted.

## Push

Commits this session: `3638151` (P0), `a7bfb80` (P1), `dd0b582` (P4),
`fa367cb` (P5), plus this report.
