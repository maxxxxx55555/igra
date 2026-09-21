# SLOP_REPORT — neural slop & quality debt in agent-authored work

Scope: `git log v7.0.0-rc1..HEAD` (71 commits, `fe52499` back to `822642f`; agent
author `game-dev <dev@local>` plus merges of arena session branches; owner commits
in range read for context only). Diffs read in full for gameplay/visual/security/
i18n/tools: `scripts/**`, `tools/**`, `scenes/tools/**`, `data/i18n/**`,
`data/dialogs/**`, `export_presets.cfg` (127 files, +7353/−313). Conventions
re-read: `CLAUDE.md` hard rules (zero shipped debris, no debug prints, no
commented-out code), `.claude/skills/ponytail` ladder (stdlib/reuse/YAGNI),
`docs/STYLE_GUIDE.md`. Static gate claims re-measured where possible:
`i18n_truth_gate.py` and `visual_truth_gate.py` executed against the committed
fixtures this review. Every item below was verified against the diff at HEAD, not
inferred from commit messages.

Categories per charter: dead code/unreferenced exports · debug prints ·
commented-out code · magic numbers→named consts · copy-paste blocks ·
over-abstraction/speculative generics · unused params · misleading names ·
duplicate logic · TODO/FIXME left shipped · threshold-fudges.

Zero items found for: TODO/FIXME in shipped code (only prose mentions in docs and
store listings), commented-out code left shipped (the one instance,
`lan_discovery.gd:37`, was *un*-commented in range — fixed, not slop).

---

## §1 Ranked slop items

### 1. New probe scripts ship in every export build, prints included
`export_presets.cfg:3,43,67` · **debug prints + dead code/unreferenced exports**
Why: `export_filter="all_resources"` with an `exclude_filter` that covers
`scenes/tools/*` and `scripts/tools/*` but **not** `scripts/security/*` or
`tools/*`. This wave added `scripts/security/attack_sim.gd` (167 ln, `print()` at
:29,:40,:45,:48), `tools/qa_sim/audio_truth_gate.gd` (:22,:28,:60,:72) and
`tools/qa_sim/gui_explore_runner.gd` (:32,:42,:219) — all `.gd` resources get
packed (`tools/qa_sim/capture_stills.gd` was already in this hole pre-range). The
game PCK therefore ships dead probe code with debug prints, violating CLAUDE.md
"Zero shipped: … debug prints".
Fix: append `scripts/security/*,scripts/security/**,tools/*,tools/**` to the
`exclude_filter` on all three preset lines (one string per preset).
Assumption: Godot packs unreferenced `.gd` under `all_resources` — standard
behavior; the repo's own `scripts/tools/*` exclusion exists precisely for this.

### 2. Audio truth gate reports green without testing anything
`tools/check.sh:216-225,257` + `tools/qa_sim/audio_truth_gate.gd:20-23` ·
**threshold-fudges (false-green gate) + misleading names**
Why: `run_gate()` invokes Godot `--headless` always and maps exit 0 → `ok`. The
gate self-skips headless with `get_tree().quit(0)` — so the check.sh line
`аудио: Music bus не в тишине` prints `ok` on every standard run while testing
nothing. The shipped comment ("гейт сам это видит … и молча пропускает. (SKIP, не
OK/FAIL)", check.sh:253-256) describes SKIP semantics that `run_gate` does not
have — it only has `ok`/`bad` (check.sh:222-225). Same defect already existed for
the draw-call gate; this wave added a second gate on the pattern and copied the
false comment.
Fix: give skip its own exit code and status: in `run_gate`, add
`elif [[ $rc -eq 3 ]]; then echo "  ${DIM}пропуск${OFF} $name (нужен --windowed)"`;
in `audio_truth_gate.gd:_ready` (and the perf gate), `get_tree().quit(3)` on
headless self-skip.
Assumption: a permanently-green placeholder gate erodes trust in the suite —
that's the point of the charter's threshold category; the comment-vs-code
mismatch is factual either way (verified in `run_gate` body).

### 3. i18n gate: a to-pass exemption, then a permanently red blocking gate
`tools/qa_sim/i18n_truth_gate.py:28,37` · **threshold-fudges + misleading names**
Why: `SHORT_STRING_FLOOR = 12` was added *after* the first real run flagged ~100
strings/locale (docs/RUN_STATE.md:51-55) — a constant tuned against the data it
gates. The hand-verified rationale (short l10n strings legitimately expand more
than 1.6×) is sound l10n practice, but the exemption is **uncapped**: any
`en` string <12 chars may translate to any length with zero signal. Second, the
gate is wired blocking (check.sh:194-197) yet fails at HEAD on 8/12 locales —
194 `overflow` flags total (ru 22, es 34, de 22, fr 49, it 30, pt_BR 25, tr 6,
ar 6; measured this review) — while RUN_STATE.md:56 calls this "a handful of
length-ratio flags", a misread of the tool's own per-locale counts (`fr
overflow=49`). CLAUDE.md mandates `check.sh --static` after every change; a suite
that is red by construction trains red-ignoring. The docstring's own escape hatch
(`[:3]` sample truncation at :109-113) also hides the scale in logs.
Fix (minimal, no new fudge): keep `SHORT_STRING_FLOOR` but cap the exempt band —
flag short strings above a looser hard ratio (e.g. `len(val)/base_len > 3.0`) so
the exemption is bounded; print the full flag lists (drop `[:3]` or add
`… +%d more`); fix RUN_STATE.md:56's "handful" to the measured counts. Resolving
the red state is a separate content decision (fix the 194 strings — the P3
per-container calibration RUN_STATE already prescribes — or consciously demote
`overflow` to warn-only and say so in the gate docstring; do not silently loosen
`LENGTH_RATIO_MAX`).
Assumption: most overflow flags are false positives (RUN_STATE's claim about
autowrap containers) — asserted, not yet verified per string.

### 4. `silent_steps` applied twice; comment says "instead … only"
`scripts/player/player_3d.gd:517-524 vs :534` · **duplicate logic + misleading
names**
Why: the new comment says the skill is now applied "here instead, to speed_noise
**only**", but the old second application `noise_radius *= 1.0 - 0.15 *
stealth_lvl` (:534) remains — the same formula applied a second time nine lines
later in the same function. The
`noise_radius` path only feeds `EventBus.noise_emitted`, which has **zero
listeners** repo-wide (verified: signal at `event_bus.gd:72`, emitters at
`hound_3d.gd:35`, `watcher_3d.gd:63`, dead `player.gd:86`, `player_3d.gd` — no
`.connect()` anywhere). The comment itself admits the signal is listener-less,
then the code keeps feeding and discounting the dead path.
Fix: delete `player_3d.gd:534` (one line); if `noise_emitted` is a planned
monster-hearing feature, say so in the signal doc and drop the word "instead/only"
from :518-524.
Assumption: `noise_emitted` is not a planned feature — its own in-range comment
declares it unwired; CLAUDE.md's "lesson: hiding_spot.gd" protects planned
features, hence the comment fix as the alternative branch.

### 5. NUDGE_SEC doc comment contradicts its own arithmetic
`scripts/tools/_qa_autoplay_runner.gd:33-44` · **misleading names**
Why: "0.25s bounds the worst case to ~43m, comfortably inside a district's ~40m
nav-mesh half-size even from a max-radius (22m …) starting scatter point" — 22m
start radius + 43m displacement is 65m from center against a claimed 40m
half-size. The numbers in the comment refute the sentence built on them.
Fix: reword to match the math (0.25s cuts the fling from 204m to ~43m; worst-case
egress is still possible from a max-radius start) — or set `NUDGE_SEC := 0.1`
(17m; 22+17=39 ≤ 40) if in-bounds is the actual requirement. Comment-only change
either way; empirically the 0.25 value bot-verified 3/3 (see §3 for its limits).
Assumption: the "~40m half-size" figure is the author's own (comment-local); the
contradiction stands regardless of which of the two numbers is wrong.

### 6. Two "mixed-script" checkers that disagree
`tools/qa_sim/gui_explore_runner.gd:107-119` vs
`tools/qa_sim/i18n_truth_gate.py:40-64` · **duplicate logic**
Why: `_has_mixed_script()` re-implements the Python gate's rule but counts Latin
as a script (`0x41..0x7A` — which also swallows `[\]^_\`` punctuation), while the
Python gate **exempts** Latin per this project's documented convention
(i18n_truth_gate.py:8-10, RUN_STATE.md:53-54: brand names/tech tokens stay
Latin on purpose). A Settings title containing a Latin token + CJK/Cyrillic is
PASS in the Python gate and BUG in the GDScript driver.
Fix: align the GDScript rule with the Python one (drop `has_latin` from the
script count and fix the range to `0x41..0x5A, 0x61..0x7A` if Latin stays), or
delete `_has_mixed_script` and let the Python gate own the rule.
Assumption: runtime titles can legitimately mix Latin with the target script —
that is exactly the convention the Python gate encodes.

### 7. Disabled-button StyleBox re-typed instead of duplicated
`scripts/ui/theme_provider.gd:103-108` · **copy-paste blocks**
Why: `btn_d` hand-rebuilds the `(border 1, corner 0, margin 10)` triple already
defined on `btn_n` at :85-89, while `btn_focus` on the line above correctly uses
`btn_n.duplicate()`. If the button metrics at :85-89 change, `btn_d` silently
drifts.
Fix: `var btn_d := btn_n.duplicate() as StyleBoxFlat` then only
`btn_d.bg_color = COLOR_BG_DARK.lerp(COLOR_BG_PANEL, 0.35)` and
`btn_d.border_color = COLOR_BORDER` (6 lines → 3, one source of metrics).
Assumption: none — the duplicated triple was verified line-by-line.

### 8. Threat-reactive audio tunables are unnamed literals, enum values read as raw ints
`scripts/audio/proc_audio.gd:231,87,253-258,267` · **magic numbers→named consts**
Why: `int(ai_state) != 3 and int(ai_state) != 4` hard-codes `base_monster.gd`'s
enum order at an autoload boundary (a reorder silently breaks threat audio), and
the P5 feel tunables (`+6.0` Hz, `×0.35`, `+0.5`, `×0.5`, `h % 800 / 100.0 - 4.0`)
are raw literals two lines below the correctly-named `_THREAT_CHECK_SEC`/
`_THREAT_RADIUS`.
Fix: `const _AI_CHASE := 3` / `const _AI_ATTACK := 4` (the existing comment
becomes their doc), `const _THREAT_HZ := 6.0`, `_THREAT_VOL := 0.35`,
`_THREAT_LFO := 0.5`, `_THREAT_MOAN := 0.5`, `_HUM_SPREAD_HZ := 4.0`, used at the
cited sites.
Assumption: these are re-tunable feel values (the commit itself calls the area
"procedural variation depth") — if frozen forever the ints still deserve names.

### 9. Dead `else` fallback + the per-rank `25` living in two files
`scripts/systems/skill_tree_manager.gd:254-255` vs `scripts/player/player_3d.gd:1128`
· **dead code + duplicate logic**
Why: `else: player.battery_max += 25` is unreachable — the only node with
`battery_max` is `player_3d.gd`, which gained `refresh_battery_max()` in this very
wave (the fallback also keeps the old order-dependent write the wave just
removed). The `25` now exists both here and in `player_3d.gd:1128`
(`25.0 * skill_lvl`); changing the skill value in one place diverges the other.
Fix: delete the `else` branch (skill_tree_manager.gd:254-255); add
`const BATTERY_PER_SKILL_LVL := 25.0` in `player_3d.gd` and reference that single
definition from :1128's formula (the tree's `effect_per_level` is documentation
only for this skill).
Assumption: `scripts/player/player.gd` (the 2D player) stays dead — every
in-repo comment this wave writes says so.

### 10. Dead ternary in badge refresh
`scripts/ui/hud_3d.gd:904` · **dead code**
Why: `str(inv.count_of(item_id)) if item_id != &"" else "0"` — `_SLOT_ITEMS`
(:7) is a six-literal array with no `&""` member; the false branch can never
fire.
Fix: `badge.text = str(inv.count_of(item_id))`.
Assumption: none — array literal verified at :7.

### 11. Scratch-slot comment contradicts the code it documents
`scripts/security/attack_sim.gd:13 vs :148` · **misleading names**
Why: `_SLOT: int = 96  # a different scratch slot than _save_integrity_check.gd's
97` — then `_check_cross_save_swap_no_corruption` uses `_SLOT + 1` = **97**, the
exact slot the comment claims to avoid (that file's `_SLOT` is `97`, verified at
`_save_integrity_check.gd:5`). Cleanup runs after, so this is comment rot, not
save corruption.
Fix: `const _SLOT: int = 95` (pair 95/96) and say so in the comment — or keep 96
and reword: `# scratch pair 96/97, removed in _cleanup below`.
Assumption: none — both constants verified.

### 12. `BTN_ONE_MORE_RUN` orphaned in all 13 locales
`data/i18n/en.json:1087` (and the same key in all 13 locale files) · **dead
code/unreferenced exports**
Why: `win_screen.gd:91` switched the button to `NGP_SETUP_ACTION` in this wave;
`BTN_ONE_MORE_RUN` now has zero references in `scripts/`, `scenes/`, `components/`
(verified by grep, including dynamic `LABELS` maps). Dead keys ship in every
build's locale JSON ×13.
Fix: delete the `BTN_ONE_MORE_RUN` entry from all 13 `data/i18n/*.json`.
Assumption: no runtime key is assembled from fragments (grep for the literal
across all `t(`/`tf(` call sites found none).

### 13. Hand-rolled HSV converter next to the PIL dependency that provides it
`tools/qa_sim/visual_truth_gate.py:31-52` · **duplicate logic (over-abstraction)**
Why: 22 lines of per-pixel HSV math, while `PIL` — already imported on :19-20 for
exactly this tool — provides `Image.convert("HSV")`. Ponytail ladder rung 3
(stdlib/platform first); the custom converter is also more code to keep correct
than the band test it serves.
Fix: `hsv = np.asarray(img.convert("HSV"), dtype=np.float32); hue, sat, val =
hsv[...,0] * 360.0 / 255.0, hsv[...,1] / 255.0, hsv[...,2] / 255.0` in
`measure()`; delete `_rgb_to_hsv`.
Assumption: 8-bit hue quantization (~1.4°/step) is fine for an 85°-wide band —
trivially true; the `_demo()` self-check covers the regression.

### 14. Two stray magic values with self-documenting fixes
`scripts/enemies/base_monster.gd:244` (`> 3.0` Y-dip rescue threshold) and
`scripts/core/save_system.gd:358` (`current_district = "suburbs"`) · **magic
numbers→named consts**
Why: the 3.0 is a measured rescue threshold whose rationale lives in a 6-line
comment but not in a name (re-tuning means re-parsing prose); "suburbs" is the
start-district literal already encoded once as `district_manager.gd:57`'s
fallback — two unnamed copies of one game-rule constant.
Fix: `const _Y_DIP_TELEPORT := 3.0` next to the timer consts in `base_monster.gd`;
`const START_DISTRICT := &"suburbs"` in `district_manager.gd` used by :57 and by
`save_system.gd:358`.
Assumption: 3.0 is a tuning knob (comment cites the −33 measurement, so yes) and
`suburbs` is policy, not a per-save value (save_system's own comment says "start
district").

### 15. Unused signal param; handler re-derives the data the signal carries
`scripts/audio/proc_audio.gd:80-87` · **unused params**
Why: `_on_district_entered(_district_id)` ignores the event's own district id and
re-reads `DistrictManager.current_district` — duplicate source of truth that
happens to be safe today (`district_manager.gd:65-66` updates state before
emitting) but silently misbehaves if any other emitter
(`city_map.gd:208`, `district_scene_factory.gd:22,52`) fires before the manager
updates. The `_` prefix hides the smell instead of fixing it.
Fix: use the param with the manager as fallback:
`var id := String(_district_id); if id.is_empty(): ...current read...`.
Assumption: the `&""` call from `_ready` is the only legitimate empty-id case —
verified in the diff (the one in-range caller).

---

## §2 Gate/threshold changes: fudge vs tune

**Loosened to make a check pass (integrity risk):**
- `SHORT_STRING_FLOOR = 12` (`i18n_truth_gate.py:37`) — added after the first
  real run it gates (item 3). Mitigating: hand-verified sample is documented
  (RUN_STATE.md:51-55) and `LENGTH_RATIO_MAX` itself was **not** loosened even
  though the gate stayed red — RUN_STATE.md:64-66 says so ("not fudged to pass")
  and measurement agrees (8/12 locales still FAIL). Residual risk: the exemption
  band is uncapped. Verdict: acceptable l10n tuning **if** bounded (fix in item 3);
  as shipped it is a bare to-pass fudge.

**Legitimately tuned (rationale verified):**
- 3D-scene gate shell timeout 90→170s (`check.sh:238`) — the scene's own
  `HARD_TIMEOUT_SEC = 150.0` (`_game_test_3d.gd:24`) was being SIGKILL'd by the
  shorter shell timeout before its diagnostic handler ran. Constant verified; the
  fix is ordering, not threshold-relaxing (commit `4f4cfdb`'s claim holds).
- `flow_check.py:136-146` Master-bus check — the old literal
  `name = &"Master"` check failed on every *valid* default AudioBusLayout (Godot
  writes `bus/0/name` only when bus 0 is renamed). The new check encodes the real
  invariant. Verified against the file format. (Residual: an empty/missing layout
  file passes this one check via `read()`'s `""` fallback, but the sibling bus
  checks on the next lines fail first — acceptable.)
- `NUDGE_SEC` 1.2→0.25 (`_qa_autoplay_runner.gd:44`) — measured motivation
  (204m fling at walk 170), a QA-tool parameter, not a gate; see §3 for why the
  fix is rate-reduction only.
- `balance_sim.py:226-240` — the PARTIAL battery check got **stricter** (the
  "shortfall covered by shop" excuse referencing the dead `shop.gd` was replaced
  with an honest `fails.append`). Positive counter-example of the category.

**Under-tight, not dishonest (recommend tightening):**
- `MAGENTA_FAIL_PCT = 1.0` / `BLACK_FAIL_PCT = 85.0`
  (`visual_truth_gate.py:22-23`) — the broken reference frame (2.46%) still
  fails, so this is not a pass-forcing fudge, but re-running the gate on the
  committed fixtures this review: healthy frames measure 0.09-0.12% magenta and
  7.6-9.8% black. The magenta bar is 8-11× over healthy (mild corruption passes);
  the black bar is nearly vacuous (a half-black corrupted frame passes). Tighten
  to 0.5% / 40% citing these measurements.

**Historical threshold blunder, reverted in range (net-zero, lesson on record):**
- `7ec2e3a` re-scaled player speeds 170/300/90 → 1.7/3.0/0.9 on a static
  "15× faster than monsters" reading; `d6c86cc` reverted it the same day after
  bot proof (0/3 softlocks with the "fix"). The revert is correct and the
  correction was made in place in `docs/GAME_AUDIT.md`. Residual design debt is
  honestly recorded there ("scale mismatch … real and still unexplained"). No
  current file:line — flagged here so the pattern (numeric change justified by
  static comparison, no behavior check) is on the record.

---

## §3 Symptom-masking fixes (cross-ref KNOWN_ISSUES)

1. **`b7213ac` "fix(gameplay): residential softlock (nudge duration)" is a
   QA-tool change that reduces, not fixes** — the commit touches only
   `scripts/tools/_qa_autoplay_runner.gd` (+13/−1) yet is labeled `fix(gameplay)`.
   `docs/KNOWN_ISSUES.md:93-108` (the later CORRECTION) downgrades it: the fix
   "reduced the failure rate … did not eliminate the underlying mechanism" —
   the item pickup's 1.0m contact radius vs nav positions that end 1.4-1.5m out
   (`tdist` oscillation) is still un-fixed, and `4fe197d`'s "RESOLVED" marking had
   to be retracted for it. Root-cause direction (per the doc's own trail):
   interact/pickup tolerance at the item, not the bot's blast radius. Also item 5
   above: the fix's own justification comment misstates its geometry.
2. **`acddc80` boss Y-dip "fix" is a rescue, not prevention** —
   `base_monster.gd:237-246` teleports the boss back when
   `|Δy| > 3.0`, but the dip itself (P2/P3 chase pathing sinking the boss under
   the arena floor, measured Y −1→−33) continues; every occurrence now costs a
   teleport instead of a softlock. `docs/KNOWN_ISSUES.md:141-152` calls this
   "RESOLVED … root cause was the Y-dip" on 2/3 bot wins — the Y-dip's own root
   cause (floor handling in `_move_to`/nav-agent for boss phases) is untouched.
   Acceptable as a recovery layer if the prevention pass is actually planned;
   otherwise it is the category. Root-cause candidates to try first: clamp boss
   `y` to floor in `_boss_keep_near_player`'s sibling path, or exclude the boss
   from the phase-moves that dip.
3. **Open, not masked — recorded so it isn't lost:**
   `docs/KNOWN_ISSUES.md:69-90` — City Map "Travel" to `park` produced
   `player.global_position = (inf, inf, inf)` + permanent softlock; explicitly
   "NOT root-caused this pass", unfixed at HEAD, with two named leads
   (`consume_pending_player_pos()`'s `Vector3.INF` sentinel path; windowed-only
   camera dependency in the bot). Nothing in range pretends otherwise.

Verified **not** masked (checked, root-cause fixes — listed only so §3's absence
is meaningful): Ghost NG+ gate moved to `_unlock()` (`e0458af`), district-loot
re-farm flag in `ProgressTracker` (`4739d73`), HUD badge refresh on
`inventory_changed` (`6bf1deb`), `battery_max` recomposition (`24ceb68`),
investigate-timer re-arm removal (`2a88503`), telegraph mesh resolution
(`24ceb68`/P8), `reset_all()` gap fixes (`f1002d3`).

---

## Gates

- Criteria re-read before sign-off: CLAUDE.md hard rules, ponytail ladder,
  STYLE_GUIDE.md, charter category list — every §1 item maps to a listed
  category; no style-only notes.
- `git diff --stat` scope: `docs/SLOP_REPORT.md` only (this file is the sole
  owned file).
- Self-review (≤3 lines): 15 items, each cited file:line verified at HEAD; every
  gate/threshold change classified with measured or on-diff rationale; the three
  masking candidates cross-referenced to KNOWN_ISSUES line ranges. No dead hunts
  reported as hits (noise_emitted/`BTN_ONE_MORE_RUN` were greps, not guesses).
