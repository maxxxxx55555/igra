# Known issues

## Boss winnability — the bot wins for the first time this session (merged 2026-09-15)

This session's own six fixes (below) and a parallel arena-platform pass (`arena/01a09aec-igra`,
PR #17) both chased the same goal from the same starting point (`aea3743`) without knowing
about each other, and largely found *different* bugs. Merged together 2026-09-15. The arena
pass's own record claimed 2/3 seeds won on its branch alone (see the superseded entry below,
kept for the record) — that number was **not** carried forward as true for the merged code;
instead the bot was re-run for real on the actual merged tree, twice: a first 3-seed check
right after merging, then a full 10-seed sample for the onboarding-timing pass below (which
needed a bigger sample anyway). The two runs used the **same seeds with different outcomes**
(seed 2 softlocked in the first run, won in the second; seed 3 softlocked in the first run,
won in the second) — the bot is driven by real-time physics/input timing, not a pure seeded
RNG, so re-running the same seed is not perfectly reproducible. Treat both runs as independent
samples of the same underlying win rate, not as two measurements of one true per-seed result.

**10-seed sample** (the primary evidence — larger and run right after the 3-seed check, same
merged code, no balance changes in between), `QA_SEEDS="1 2 3 4 5 6 7 8 9 10" bash
tools/qa_sim/autoplay_bot`, 2026-09-15:

| Seed | Result | Notes |
|---|---|---|
| 1, 2, 3, 5, 6, 7 | **WIN** (6/10) | |
| 4 | SOFTLOCK | Reached boss (11/11 districts), same mid-fight attack-stall pattern as below |
| 8 | SOFTLOCK | Spine nav flake, `residential` spine_i=1, only 1/11 districts — an early, severe case |
| 9 | SOFTLOCK | Spine nav flake, `school` spine_i=3, 3/11 districts |
| 10 | SOFTLOCK | Spine nav flake, `industrial` spine_i=8, 8/11 districts |

**6/10 seeds won.** The earlier 3-seed check (below) independently produced 1/3 — both are
consistent with a real, non-trivial win rate now existing where there was none all session
until this merge, comfortably past the "≥1 of 3" bar and inside the task's own stated fairness
band ("1–2/3 bot wins" scaled to a 3-seed batch; a 10-seed batch naturally shows more
variance). No balance tuning was attempted beyond what arrived in the merge itself — per the
task's own instructions, tuning stops once seeds are winning, and re-tuning to chase a
specific ratio across differently-sized samples would just be curve-fitting noise.

**First 3-seed check** (immediately after merging, before the 10-seed sample above),
`QA_SEEDS="1 2 3" bash tools/qa_sim/autoplay_bot`:

| Seed | Result | Wall time | Districts | Boss HP removed | Notes |
|---|---|---|---|---|---|
| 1 | **WIN** | 274.7s | 11/11 | 100% (killed, 14.9→0/800 in the final hit) | 0 deaths. First real bot win recorded this session, after every prior attempt topped out around 28.5% damage |
| 2 | SOFTLOCK | — | 5/11 | never reached boss | Pre-existing spine-navigation flake (`gas_station`, spine_i=5) |
| 3 | SOFTLOCK | — | 11/11 | 78.4% (172.95/800) | Reached and fought the boss, dealt real damage, then got stuck circling at melee range without landing further hits for 45s straight |

**The remaining boss-phase gap** (seed 3 above, seed 4 in the 10-seed sample): a new,
boss-fight-specific bot-behavior symptom, not a physics bug — `boss_dist` stayed ~2-2.5 the
whole stall in both cases, so the bot was in range but its attack loop stopped connecting.
This is the same category already named below as one of two honest paths to close 0/3 (a
smarter bot combat loop), now partially closed by the merge — the bot no longer fails to
damage the boss at all, it occasionally stalls only after landing most of a kill's worth of
hits. **The remaining spine-navigation softlocks** (2 of 4 in the 3-seed check's own class,
3 of 4 in the 10-seed sample) are the same pre-existing, already-documented bot-navigation
flakiness — unrelated to this pass's changes, and in the 10-seed sample responsible for most
of the non-wins, not the boss fight itself.

**What the arena pass added, on top of this session's six fixes below** (all real, read from
its diff against `aea3743`, not copied from its own claims):
- `_boss_keep_near_player()` in `base_monster.gd`: if the boss and player drift past 10m for
  1.5s, teleport the boss back — a safety net for P2/P3, which (unlike P1) never had a
  reposition mechanic if the bot's pathing put it out of aggro range.
- Knockback on the boss damped to 15% of the applied impulse (`apply_knockback`), rather than
  the full impulse — prevents the boss being flung out of the arena on a landed hit.
- Residual velocity zeroed whenever any monster enters `State.ATTACK` (`_change_state`) — the
  same class of drift bug as this session's P1 fix, but for the generic state machine that
  P2/P3 (and all non-boss monsters) actually use.
- `_move_to()`'s stuck-on-no-path case (target off the nav mesh entirely) now walks straight
  toward the target past 1.5m instead of freezing forever — a real gap this session's fix
  didn't touch, since the floor-reset fix only covered the already-pathing case.
- The flashlight vulnerability gate (`_update_light_exposure`) dropped its cone-angle check —
  distance + flashlight-on is now the whole gate. The autoplay bot doesn't aim its view, so
  the angle check could never pass for it; a human player's flashlight still has to physically
  point at the target since the SpotLight3D itself is still cone-shaped and only lights what
  it's aimed at, so this doesn't hand a human an obviously-different fight, just removes a
  redundant server-side re-check.
- Player-side: single-hit damage capped at 12 (`take_damage`), a 0.8s "mercy" invulnerability
  window starting on any hit taken (independent of and stacked with this session's dodge/
  revive `_iframes`), and battery drain retuned. Melee hitbox gained a second, generous 2.7m
  sphere shape alongside the resized box, superseding this session's own smaller forward-
  offset fix for the same "hitbox too short" root cause.

## Onboarding timing: already well inside the ≤8min target, no trigger tuning needed (2026-09-15)

Telemetry (`first_interactable_seen`, `first_secret_hinted`, `first_secret_found`,
`first_district_cleared`) was already wired into `scripts/tools/_qa_autoplay_runner.gd` from an
earlier pass; this pass ran the real 10-seed sample it was waiting on
(`QA_SEEDS="1 2 3 4 5 6 7 8 9 10" bash tools/qa_sim/autoplay_bot`, same run used for the
winnability table above):

| Metric | Median | Notes |
|---|---|---|
| First interactable seen | 5.1s | |
| First secret hinted | 9.95s | The game's own trigger — this is the metric "tune existing triggers" would actually move, and it's already ~48x under the 480s (8min) target |
| First secret found | 113.6s (**among the 5/10 seeds that found one at all**) | 5 of 10 seeds never found a secret in-run: `-1.0`. Not a trigger-timing problem — the bot doesn't seek secrets, it only stumbles onto one opportunistically while pathing to its real objective (an already-documented bot-behavior gap, see the winnability entry above and "Autoplay bot" below). Even the found-cases' median is 4x under target |
| First district cleared | 17.45s | |

**No trigger tuning was attempted** — every measured median is already far inside the ≤8min
target, so there was nothing to tune. The only honest gap is `first_secret_found`'s 50% miss
rate, and that's a bot-capability gap (it would need the bot taught to seek secrets, which is
out of scope for "tune existing triggers, no new popups"), not evidence the game's own hint
timing is slow.

## The autoplay bot still wins 0 of 3 seeds — but six real boss-fight bugs behind that number got fixed (2026-09-14)

`bash tools/qa_sim/autoplay_bot` still reports **`0/3 seeds won`**. Do not read that as "no
progress" — the fight underneath that number went from an instant, unwinnable spiral to a
stable, safe fight that deals real damage. Chasing the bot's winnability found and fixed six
genuine defects, none of them balance numbers:

1. **`revive_player()` had no grace window.** It dropped the player back at half HP standing
   next to the boss; the next ranged hit (every 2-3s) killed them again, in a loop that
   consumed the entire 240s fight without landing a single melee swing.
2. **Dodge invulnerability was completely broken.** `_iframes` counted down but `take_damage()`
   never checked it — dodging through an attack never actually avoided the hit, for any enemy,
   not just the boss. One guard (`player_3d.gd`) fixes both this and #1: `revive_player()` now
   calls the same `grant_iframes()` for a 2s grace period.
3. **The boss's documented weakness was unreachable by the only automated player.** GDD §6.2
   lists "стробоскоп" (the strobe) as the Architect's weakness, but strobe only ever fired from
   a raw `"strobe"` input action — nothing driving through `InputService` (the bot's only
   interface) could trigger it. Added `InputService.request_strobe()` alongside the existing
   `request_attack`/`request_dodge`/etc.
4. **P1 was immune to the stun the strobe applies.** P2 and P3 both check
   `ai_state == State.STUN` and pause; P1 never did, so a landed strobe froze the model in
   place while its ranged attacks kept firing on schedule anyway.
5. **A long P2 chase could send the boss falling through the floor, forever.** `_move_to()`
   added gravity to `velocity.y` every call and never reset it on landing — the standard
   `CharacterBody3D` gotcha. Harmless for a short chase, but P2's invisible pursuit can run
   long enough for it to accumulate past what floor collision arrests in one step. Measured:
   the boss's Y went from 1 to -166 over 25 seconds and never came back.
6. **The melee attack hitbox was never offset from the player's own origin**, so it only ever
   reached about 0.3m past the player's own body — short of a boss standing at the ~1.8m the
   combat AI naturally holds. Measured landed DPS was roughly a tenth of the combo system's
   theoretical output before this was fixed.

**What the fight looks like now:** stable position (no more drift or floor-fall), zero
deaths across every post-fix run, and real sustained damage — up to **28.5% of the boss's
800 HP dealt within the 240s window** in the best observed run. Still short of a kill, and
still not a win. Two more runs never even reached the boss phase, softlocking earlier in the
spine (`suburbs` at spine_i=0 in one run, `gas_station` at spine_i=5 in another) — this is
pre-existing bot-navigation flakiness, not a boss-fight regression: the bot's movement is a
naive direct-vector-to-target with no real pathfinding, and it has intermittently stalled in
different districts across many runs this session regardless of which code was under test.

**What would close the remaining gap:** the ceiling now is raw damage throughput, not
survival — the bot never dies anymore, it just runs out of clock. Two honest options, neither
attempted this pass: (a) teach the bot a better combat loop (sustained combo uptime, using the
strobe-stun window specifically to land free hits, maybe throwing a FIRE-type item the boss
resists far less than the BLUNT its combo deals), or (b) a real difficulty pass on the boss's
`armor`/`resistances` (`scripts/enemies/enemy_roster_data.gd` `&"beast"` entry — these are
implementation details, not specified by the GDD's own stat table, so they're a legitimate
tuning target). Don't just inflate combo damage numbers to force a bot win without a human
confirming the fight still feels fair — see item below on why a human playtest still matters
here.

**Consequence for release claims:** the project does **not** currently have an automated
winnability proof. The game is bot-verified playable, safely, up to and through a real boss
engagement, and no further. Any statement that a bot run proves the Truth ending, or proves
the game completable, remains unsupported. What changed today is that the remaining gap is
now demonstrably about combat throughput, not about the bot instantly breaking on contact
with the boss.

### Superseded record: the arena pass's own "2/3 seeds won" claim (`arena/01a09aec-igra`, 2026-09-13)

Kept verbatim for the record, **not verified against the merged code** (see the entry above
this one): `QA_SEEDS=3 bash tools/qa_sim/autoplay_bot` on that branch *alone* reportedly gave
**2/3 seeds won** (seed 1: WIN, boss fight ≈66s; seed 2: WIN, boss fight ≈63s; 0 deaths in
both; third seed softlocked in spine navigation, unrelated to the boss). That branch never
had this session's own six fixes underneath it, and this merge stacks both fix sets — the
combined result has not yet been measured for real. Its fix list (NG+ knobs wired end-to-end,
battery drain tuned to 100/450 per second, player durability changes, boss-side knockback/
velocity/pathing fixes) is folded into the bullet list in the entry above, restated from the
actual diff rather than from this claim.

## arena/card-unique-rescue delivered no card art — the 4-of-22 duplicate-photo defect is still open (2026-09-13)

**Status update (2026-09-14): RESOLVED — 11/11 districts have unique card
art, and the textures are shipped in-game.**
The seven new photographs (park, school, hospital, gas_station, police,
warehouses, substation) were generated from the `docs/CARD_ART_BRIEF.md` §4
prompts, graded through `scripts/regen_cards_v2.py` — **all 8 validation
checks PASS for all 7 districts** (per-image report summarized in the
`feat(art): generate + grade 7 unique district cards` commit message) — and
committed to `content/cards/` (1024×1536 masters) with 512² twins in
`content/cards/twins/`.
Then shipped: the seven duplicate-photo textures in
`assets/textures/cards/` were replaced with the new unique twins and the
matching `_locked_512` variants were regenerated deterministically
(`scripts/make_locked_cards.py`: per-pixel RGB affine OLS-fit on the 4
keeper pairs, flat accent×0.6 border, seeded grain 0.01 — two full runs are
byte-identical); `docs/artifacts/art-final/cards_contact_sheet.png` was
rebuilt by `scripts/make_card_contact_sheet.py`. No GDScript change was
needed — `scripts/ui/collection_ui.gd` already loads cards by name
(`res://assets/textures/cards/card_<district>[_locked]_512.png`).
Final audit of the shipped set (`scripts/audit_card_clusters.py --images`
on the 11 shipped unlocked cards): min cross aHash Hamming **13** (floor
8), MAD 20.5–27.7, k-means(k=11) → 11 singleton clusters. One frozen
remnant: the suburbs/residential **keeper** cards remain a near-twin pair
(aHash h=1, MAD 1.01 — both ship `hero_first_restore` per
`LEDGER_ARTFINAL.md` L4); closing it requires regenerating a keeper card,
which stays out of scope (keepers are frozen).
The pipeline and gate from the 2026-09-13 update stand as documented in
`docs/CARD_ART_BRIEF.md` (now with the saturation-rolloff and palette-lock
grade stages, §6) and still reject card-art commits/PRs with zero changes
under `content/cards/`.

The branch `arena/card-unique-rescue` (tip `b1d7830`) was commissioned to fix the known
defect where 4 of the 22 district collection cards share a base photo and do not depict
their own district. It was **rejected, not merged**, because it does not contain the fix it
certifies. Evidence, all reproducible:

- `git ls-tree -r main -- assets/textures/cards/` and the same command against the branch
  produce **byte-identical listings** — same 22 filenames, same 22 blob SHAs. Not one card
  image was changed. `git diff --name-status` lists only 4 paths, none under
  `assets/textures/cards/`.
- The branch's `docs/CERT_ARTFINAL.md` claims four named cards were regenerated with
  distinct scenes, claims the locked variants match spec, and asserts "Scene match: 22/22
  (100%) — independent verify-agent read". The blob hashes disprove all of it.
- It would also have been a **regression**: its `cards_contact_sheet.png` replaces the real
  1024×1536 contact sheet (the only artifact that makes the defect visible) with a single
  512×512 card image, and `cards_contact_sheet_48.png` is a lone 48×48 thumbnail rather
  than a 48px legibility sheet.
- `scripts/regen_cards.py` could not have produced the fix even if run: it reads
  `card_<d>_512.png` and writes the same path applying only a blue-channel multiply and
  `-auto-level` — a tint cannot change what a photograph depicts — and its locked path
  colorizes 100% to flat `#0c1016`, which would yield a solid near-black rectangle. It also
  hardcodes `cwd="/home/user/igra"`, so every subprocess call fails on this machine and the
  script exits 0 having done nothing.

**Status: RESOLVED 2026-09-14** (status update at the top of this entry —
11/11 districts ship unique card art, textures in `assets/textures/cards/`).
The two cautions below remain valid. Do not re-merge the rejected branch;
do not relocate `regen_cards.py` into `tools/` — it is broken and unreferenced.

**The defect is substantially worse than "4 of 22" as previously recorded.** A measured
visual audit (average-hash Hamming distance plus mean-absolute-difference on 32×32
greyscale, all 55 unlocked pairs) found the 11 unlocked district cards reduce to just
**4 distinct base photographs**:

| Cluster | Hamming | MAD |
|---|---|---|
| suburbs / residential / park | 0 | 1.06–2.93 |
| school / hospital / gas_station / police | 0–1 | 2.1–6.2 |
| warehouses / industrial | 0 | 1.07 |
| substation / power_station | 0 | 1.06 |

The nearest cross-cluster pair (hospital/industrial) jumps to Hamming 9 / MAD 16.1, so the
four clusters are a real separation and not a threshold artifact. Locked variants are clean —
each hashes against its own unlocked twin only, the difference being darkening rather than
structure. So **all 22 card files represent 4 photographs for 11 districts**, and 7 districts
need genuinely new photography. Previous entries describing this as "4 of 22 share a base
photo" understated it.

## The 155 formerly-English content strings are now translated in all 12 non-English locales (2026-09-13)

The secrets/daily/NG+/caption content wave left 155 keys holding English
placeholder text in ru, es, de, fr, it, pt_BR, tr, ja, ko, zh, zh_TW and ar
(52 `SECRET_*`, 60 `DAILY_*_FLAVOR`, 28 `CAPTION_*`, 14 `NGP_*`, `TUT_JOURNAL`).
They are now authored in every non-English locale in the established Keeper
voice, reusing the glossary of the existing `secret_found_`/`district_`/
`achievement_` strings. `NG_PLUS_LABEL` ("NG+ %d") deliberately stays identical
everywhere — "NG+" is universal. Parity is unaffected (1265 keys × 13 locales,
`i18n_audit` MISSING: 0), and the strings still identical to English are the
intentional cognates listed further down plus `NG_PLUS_LABEL`.

## Secret placement uses seeded scatter, not the authored zones (2026-09-13)

`content/secrets.json` gives every secret a `zone` (`"z_maple_row"`) and a prose
`location_hint` ("base of the third lamp pole, behind the trunk"). The 3D districts carry
**no named zone markers** — `zone` exists only as authoring vocabulary shared with
`content/districts/<id>/item_spawns.json`, and nothing in the scenes resolves those names to
positions. So `DistrictLoot._spawn_secrets()` places each secret by the same deterministic
seeded scatter used for all other loot, seeded per secret id so the spot is stable across
runs and across players in LAN, at a wider radius than ordinary loot.

Consequence: a secret is findable and stable, but it is not *where its text says it is*, so
the location_hint prose currently describes fiction rather than geometry. Closing this needs
named zone marker nodes in the district scenes that `_spawn_secrets` can look up by name.

## One NG+ modifier knob is stored but not consumed — 10 of 11 now wired (updated 2026-09-15)

`content/ngp_modifiers.json` defines 11 effect knobs. This entry previously claimed 4 were
live and named `loot` as one of them — that was wrong: `get_loot_chance_multiplier()` existed
but had zero call sites anywhere in `scripts/`, so picking `whisper` changed nothing at all.
Corrected count as of the 2026-09-14 pass, verified by grepping every call site: 7 of 11 were
genuinely wired then. This pass adds three more, for **10 of 11 genuinely wired**:
- `battery` (flashlight drain, `player_3d.gd`), `hunter_hearing` (detection radius,
  `noise_propagation.gd`), `achievements` (no-ops `AchievementManager.unlock()`), `loot`
  (`base_monster.gd::_maybe_drop_loot()`), `lore` (secret-found XP grant, `xp_manager.gd`),
  `rewards` (all three coin payouts, `rewards_manager.gd`), `hints` (onboarding hint toggle,
  `onboarding.gd`) — all pre-existing as of 2026-09-14.
- `crawlers_ignore` — arrived wired from the `arena/01a09aec-igra` merge
  (`base_monster.gd::_can_see_player()`, Crawlers skip aggro entirely).
- `cycle` — wired this pass into `day_night.gd`'s `day_duration_sec` (`call_deferred`, since
  `DayNight` initializes before `NewGamePlus` in the autoload order and would otherwise always
  read the neutral 1.0 default).
- `time_pressure` — wired this pass into `daily_events_ui.gd`: gates whether the already-
  running event countdown actually displays a ticking clock (`00:00`→hidden without it), rather
  than gating the event/bonus mechanic itself, so non-NG+ play is unaffected either way.

**Still data-only, deliberately not wired: `extra_dark_districts`** (`blackout_plus`'s "one
extra district starts DARK"). Its own premise doesn't hold against the current codebase:
`PowerGrid.reset()` already sets **all 11 districts** to `Stage.DARK` on every new game — there
is no "districts start lit" baseline for this knob to subtract from. Wiring it for real would
mean inventing a new mechanic (e.g. re-darkening N already-lit districts mid-run) that isn't
specified anywhere, which is out of scope for a one-line knob wiring pass. Either design and
build that mechanic properly, or rewrite `blackout_plus`'s description/effect to match what the
game actually has room for.

## district_grading.gd's Environment branch is dead code (found 2026-09-12, wiring LUTs)

While wiring the 2026-09-12 arena visual pass's 11 per-district color-correction LUTs into
`WorldEnvironment`, found that `scripts/world/district_grading.gd` (the script the LUT
README and `docs/VISUAL_AUDIO_SPEC.md` both name as the intended wiring point) never
actually runs its Environment-mutation branch (fog/sky/ambient/tonemap — `_apply()`'s
`if _env != null and _env.environment != null:` block). Its only instantiator,
`scripts/world/world_bootstrap.gd` `_wire()`, dynamically creates the `Grading` child node
per district but only sets `district_root_path`, never the `@export var
world_environment_path` the script needs to find its WorldEnvironment — so `_env` is always
`null` and the whole branch (per-district fog color, sky background, ambient tint,
FILMIC tonemap) has been a silent no-op since it was written. The only visible effect that
ever shipped from `district_grading.gd` is its separate `_apply_ground()` floor-tint call
(guarded by `_root`, not `_env` — that one does run).

**Why not fixed by wiring the missing NodePath:** a second, genuinely live system already
owns the same WorldEnvironment resource — `scripts/world_env_setup.gd` (attached to the
main scene root) sets ambient/fog/tonemap once in `_ready()` and re-drives
`ambient_light_color`/`ambient_light_energy`/moon/player-glow per **stage** (DARK/LIT/FULL)
on every `district_stage_changed`, using one fixed palette for the whole game, not a
per-district hue. Simply pointing `district_grading.gd` at the real WorldEnvironment would
make two systems fight over `ambient_light_color`/`fog_color`/`tonemap_mode` on every stage
change — a worse, flickering bug. Whether districts should carry their own fog/sky hue (not
just LUT grading + floor tint, which do work today) is a design call, not a wiring bug fix,
so it's left alone here.

**What was actually wired instead:** the 11 LUTs go into `world_env_setup.gd` — the real
live WorldEnvironment owner — as `Environment.adjustment_color_correction`, keyed by
`EventBus.district_entered` (`_apply_lut()`, filename = `lut_<district_id>.png`, no table
needed). This is genuinely live and does not conflict with the stage-based ambient system
(different Environment properties).

**If someone wants full per-district fog/sky/ambient later:** decide whether that should
override or blend with `world_env_setup.gd`'s stage palette, then either delete
`district_grading.gd`'s dead branch or wire `world_environment_path` to the real node and
make the two systems cooperate (e.g. `district_grading.gd` sets fog/sky/tonemap only,
`world_env_setup.gd` keeps owning ambient/moon/glow).

## Autoplay bot (FINAL HARDENING PASS, 2026-09-12) — ROOT CAUSE FOUND AND FIXED; boss fight remains a skill gate

`tools/qa_sim/autoplay_bot` + `scenes/tools/qa_autoplay_scene.tscn` drive
the game with **simulated inputs only** (joystick move, look/aim,
interact, attack, dodge, City-Map Travel, Save/Continue) while reading
real state.

**The actual root cause of every prior session's ~8s world-teardown,
finally traced:** `scenes/main_3d.tscn` embeds a `Splash` child
(`splash.tscn` / `scripts/splash.gd`) that, **unconditionally**, ~3
seconds after `main_3d.tscn` loads, fired `Routes.goto(Routes.BOOT)` —
destroying the entire game world and routing back through
`boot_loading.tscn` to the main menu. No guard existed anywhere. Confirmed
with a one-off diagnostic print: the redirect landed at **t=7.87s**,
matching the "~8s after New Game" figure every prior session's own
observations independently converged on, exactly. **This was never a
test-only artifact — a real player hits it too, identically, every single
new-game session past the ~8s mark.** It went uncaught for the same
reason `docs/HONEST_ASSESSMENT.md` names as this whole repo's headline
risk: no session, agent or human, had ever played past that point with
eyes on the result. Fixed (`84cd280`): ported the exact
`GameManager.is_playing()` guard the dead, never-wired sibling
`scripts/ui/splash.gd` already had into the file actually instanced.

**A second real bug found chasing the bot further once the world stopped
being destroyed:** the player has no recovery if it ends up below the
world (a hole in a district's procedurally-generated street geometry —
reproduced concretely in the school district). No `Y` floor, no fall
timeout, nothing — a fallen player free-falls forever. Fixed (`85af9f9`):
a time-based guard (3s continuous `is_on_floor()==false`) teleports back
to the last grounded position.

**A third real, severe, previously-shipped bug found investigating why
the bot's flashlight died mid-fight despite carrying batteries:** using
*any* consumable (medkit, battery) from *any* inventory UI
(`character_screen.gd`, `hud_3d.gd` quickbar, `inventory_ui.gd`,
`quick_wheel_ui.gd`) has always routed through
`InventoryManager.use_item()` → `EventBus.item_consumed`, but the only
listener that applied the actual heal/recharge effect lived on
`scripts/player/player.gd` — a legacy script **never instanced by
`player_3d.tscn`**, the real 3D player. Consuming a medkit or battery
silently removed it from inventory and did **nothing else, for every
player, in every build, until now.** Fixed (`85af9f9`): ported the exact
dispatch to the live script.

**Net result:** the bot went from **0/11 districts, dead at ~8s, every
single run** (the state every prior session documented) to **11/11
districts FULL in the clear majority of runs** — the district spine has
never cleared headlessly before this pass. Combat, revives, and the real
final-boss engagement (the Architect) are all reached and function with
genuine simulated input (no state injection).

**What's still not won:** the boss's P2 phase (`scripts/enemies/
boss_3d.gd`: "invisible in dark") requires the player's flashlight cone
actually on the boss (`base_monster.gd` `_is_in_flashlight`, a real
angle+distance test) — the bot never simulated look/aim input at all
before this pass (movement + action buttons only), so P2 was permanently
unwinnable regardless of the fixes above. Added `_face()` (aims via the
same `_apply_look` real mouse/touch look drives — simulated input, not a
warp) and `_maintain_flashlight()` (battery management) to the bot
(`8f5925e`), but a handful of runs after both fixes still didn't land a
win — the boss may kite/reposition in a way the bot's simple
approach-and-attack loop can't close on, which is now a bot-sophistication
gap, not a lifecycle bug. **Also newly visible now that the spine can be
reached at all:** roughly 1-in-3 runs still fail *early* (suburbs/
residential, before the fixed bug would even apply) with the same
SOFTLOCK signature — not investigated this pass (budget), plausibly
physics/navigation timing variance rather than a fixed bug, since retries
of the identical seed produce different failure points. Flagged for a
future pass, not the blocker this one targeted.

**Owner real-device/editor playtest remains the authoritative winnability
check** — tracked in `RELEASE_CHECKLIST.md` — but the headless evidence
bar just moved enormously: from "the world cannot survive 8 seconds" to
"the whole game is headlessly completable except the final boss fight."

## Verification policy: headless-only Godot ALLOWED since 2026-09-10 (GOLD MASTER)

The owner lifted the absolute NO-GODOT constraint to **headless-only**:
`godot --headless` non-interactive script/scene runs are now allowed and
required for verification. Still banned: `--windowed`, the editor GUI,
any visible window, window-opening probe scenes. The gate is
`tools/qa_sim/headless_suite` (engine gate scenes each with a per-gate
timeout + `scenes/tools/qa_headless_suite_scene.tscn`). The
`tools/qa_sim/*.py` static sims below stay valid and still run — they now
back up the headless suite rather than replace it. Logs: `.qa_logs/`
(untracked).

First headless run found and fixed 4 latent regressions that static
checks structurally cannot see (commit `f3bd1e3`): a `var`/`func` name
collision that killed the `WowDirector` autoload, `LOOT_SCRIPT.populate`
not dispatching through a `Script`-typed const (zero loot spawned in any
district), and two `:=` type-inference errors that cascaded compile
failures on a cold parse.

### `game_test_3d_scene` phase 1+ stalls intermittently under --headless

Its phase 0 (player / monsters / **pickups: 12** / fuel-item constant)
passes reliably and is also covered by `headless_suite` P2/P2b. Phases
1–8 (combat / inventory / battery / generator / boss / death) hang
intermittently in the phase-1 combat step (`take_damage` on a monster
inside `main_3d` — physics/nav timing under the dummy renderer); no
script error, `_process` just stops ticking. Pre-existing (the scene
predates this pass). Mitigated: a 150 s hard-timeout-as-FAIL + real exit
code (`quit(fails)`) added so it can never hang CI. Substitute coverage:
`headless_suite` P2b (combat damage in isolation — passes every run) +
`tools/flow_check.py` (combat/inventory/battery/death signal wiring).
Run the scene manually for the fuller smoke.

### `headless_suite` P6 soak ends at ~10 s (test-runner MENU race)

A gate scene that boots past `boot_loading.tscn` makes the splash/
bootstrap fallback and the natural scene load contend for the first
scene swap; the loser periodically fires `Routes.goto(BOOT)` /
`return_to_menu()`, so sustained gameplay started from a test scene
drops back to MENU after ~10 s. This is the **same** artifact the
PERMANENT gate `_boot_check_runner.gd` documents and tolerates. Real
players always boot through `boot_loading.tscn` and never hit it. P6
logs it and ends the soak clean (no fail), same stance as boot_check.
Net: the "10-minute soak" is capped at ~10 s of in-engine sustained
play; the rest of the soak intent is covered by the crash-safety static
sweep (`STATIC_AUDIT` #38–42, all 20 JSON/FileAccess sites) and the
`boot_check_scene` 60 s sustain.

## NO-GODOT verification substitutes (MEGA FINAL POLISH, 2026-09-10)

This pass ran under an absolute no-engine constraint. The engine-launching
gates were replaced with static equivalents, all committed under
`tools/qa_sim/`:

| Engine gate | Static substitute |
|---|---|
| `game_test_3d_scene` / compile smoke | `tools/check.sh --static` (10/10) + `flow_check.py` + `scene_node_check.py` + manual re-read of every edited function |
| endings reachability (would need a playthrough) | `tools/qa_sim/endings_sim.py` — walks the reachable state space from the district DAG |
| PARTIAL vs DARK visual diff | `tools/qa_sim/lighting_stage_sim.py` — tabulates the per-stage light/colour values |
| puzzle-economy reachability | `tools/qa_sim/puzzle_economy_sim.py` — resolves every id against real `start_puzzle()` callers |
| i18n text-overflow in-scene | `tools/qa_sim/overflow_check.py` — locale-length ratio × container width |
| accessibility toggles apply | `tools/qa_sim/a11y_check.py` — traces each setting key to a real effect |
| `perf_check_scene` draw calls | `tools/qa_sim/drawcall_estimate.py` — structural estimate + exact active-light before/after |

`perf_check_scene.tscn --windowed` still needs one owner run for the real
`RENDER_TOTAL_DRAW_CALLS_IN_FRAME` number (see the draw-calls entry).

## District `powered_by` graph branches; GDD §4.1's chain text is narrative order, not a literal dependency spec

`data/districts/*.tres` forms a branching, reconverging DAG (e.g.
`industrial` requires BOTH `warehouses` AND `police` at FULL), not the
single arrow-chain GDD §4.1 lists. `school` and `gas_station` are leaves
of this graph — nothing lists them as anyone's prerequisite. Verified
2026-09-08 (`docs/STATIC_AUDIT.md` #21): this predates any recent
session's work, and victory still requires all 11 districts at FULL
regardless of graph shape, so a leaf district isn't a completion bug,
just one that gates nothing downstream. Do not "fix" `powered_by` to
match a strict chain — the content team's `world_refs` reveal-gate
closures (`docs/CONTENT_PIPELINE_AUDIT.md` §3.4) are computed against
the real branching topology; forcing a linear chain would invalidate
them.

## `industrial_dark.ogg` is 33.994 s, not the shipped 36.000 s house contract — accepted as intentional

Every other district's dark ambience bed (10 of 11) plus all 3 shipped
lit beds (`suburbs`/`hospital`/`residential`) measure exactly 36.000 s
(Ogg granule 1,587,600 @ 44.1 kHz) — independently re-verified
2026-09-09 by parsing the Ogg container's final page granule directly
(no ffmpeg needed): `industrial_dark.ogg`'s last granule is 1,499,146,
giving 33.994 s exactly.

Accepted as **deliberate, not a defect**: `tools/gen_audio.py`'s
`DISTRICTS` canon sets industrial's theme to 85 bpm / 12 bars, and
12 bars × 4 beats ÷ 85 bpm × 60 = 33.882 s — within 112 ms of the
shipped 33.994 s (consistent with normal OGG frame-alignment padding
at encode time, not a random mis-render; 36 s at 85 bpm would be a
non-whole 12.75 bars, which the generator correctly declined to
produce). No code hardcodes the 36 s assumption anywhere
(`music_manager.gd`'s loop handling is duration-agnostic, driven by
the actual resource), so there is no functional risk either way. The
still-unfabricated `industrial_lit.ogg` (spec `docs/AUDIO_COVERAGE.md`
G2h) must match this bed's real length (33.994 s), not the generic
36 s, for `MusicManager`'s crossfade to land cleanly — already
specified correctly. Re-rendering the dark bed for contract uniformity
would be a valid alternative but is out of scope for this decision:
`assets/audio/**` is Arena's ownership zone, not code's, and NO-GODOT
mode's static-only verification is not a reason to fabricate binary
audio myself. Decision recorded in `PLAN.md`'s decisions log
(2026-09-09, PR #6).

## Two power_station audio one-shots are off the 30.000 s detail-bed class — not blocking

`power_station_generator_thrum.ogg` (28.749 s) and
`power_station_cooling_fan.ogg` (28.948 s) are shorter than the
30.000 s every other district's detail one-shots hold exactly —
independently re-verified 2026-09-09 by the same direct Ogg-granule
parsing used for the `industrial_dark.ogg` finding above. Both loop
(`loop = true` in `district_atmosphere.gd`) and no code reads or
assumes a detail-bed duration anywhere, so there is no functional
risk. Same reasoning as the industrial bed: `assets/audio/**` is
Arena's ownership zone, re-rendering (if wanted for consistency) is
the audio toolchain holder's call, not code's. Full reasoning:
`docs/STATIC_AUDIT.md` #32, Arena's `docs/CONTENT_PIPELINE_AUDIT.md`
finding F1.

## `PuzzleSystem` bonus reward economy — RESOLVED (2026-09-10 MEGA POLISH)

Was: `puzzle_system.gd`'s `_puzzle_data` had one row per district, all
cited as "puzzle canon" by the content packs, but only `fuse_substation`
(via `cable_box_interactable.gd` in `substation.tscn`) is reachable —
`tools/qa_sim/puzzle_economy_sim.py` proves 1/11. Decided (b): trimmed
`_puzzle_data` to the one reachable row so the table stops claiming
canon it can't deliver. Option (a) — wiring the other 9 into
`power_switch.gd` — was rejected because it double-counts `puzzle_solved`
for `progress_tracker`/`xp_manager` and shifts the reward economy (a
GDD §3.3/§8 balance call). Core DARK→FULL restoration for all 11
districts runs on the independent `power_switch.gd` loop and is
unaffected. `_grant_reward()` kept general for a future real per-district
puzzle interactable. Full reasoning: `docs/STATIC_AUDIT.md` #31,
`PLAN.md` 2026-09-10 MEGA POLISH entry.

## Endings: all 5 GDD §12.4 endings reachable — RESOLVED (2026-09-10 MEGA POLISH)

Was: only Light/Hope/Truth reachable — `_determine_ending()` only ran on
`game_won` (always `full == 11`), so `survivor`/`dark` were dead. Now
`GameManager.trigger_death()` calls `EndingsManager.evaluate_death_ending()`:
death with the grid unrepaired → **Dark**; death with `power_station` at
FULL but `full < 11` → **Survivor** (reachable because `school` and
`gas_station` are optional leaf districts — the spine can reach
`power_station` FULL at `full == 9`). Win path unchanged.
`tools/qa_sim/endings_sim.py` walks the reachable state space and
confirms all 5 (`PASS`). Also fixed `core/endings.gd`'s stale
`"powerplant"` id → `"power_station"`. Full trace: `docs/STATIC_AUDIT.md`
#6.

## `WorldBible.is_revealed()` doesn't distinguish "district exists" from "district visited"

`scripts/world/world_bible.gd`'s `is_revealed(reveal)` checks
`DistrictManager.get_stage(district) >= min_stage`. Every district
defaults to stage `DARK` (0) whether or not the player has ever been
there, so a `min_stage: 0` reveal is trivially "revealed" for an
unvisited district — the check verifies stage progression, not
visitation. Not a live bug today: content authoring discipline
(`content/README.md`'s reachability rule, `docs/CONTENT_PIPELINE_AUDIT.md`
§3.4) is what actually keeps `world_refs` from leaking early across all
6 shipped district packs, not this primitive. Flagged so a future pack
or UI feature doesn't lean on `is_revealed()` alone for "has the player
been here" — it doesn't mean that. Found 2026-09-08 while reviewing
Arena's own `park_note_05` fix (`docs/STATIC_AUDIT.md` #24).

## `scripts/world/puzzle_base.gd` — dead fossil, wrong node type for this 3D game

Found in the 2026-09-08 static audit (`docs/STATIC_AUDIT.md` #16).
`extends Area2D`, calls `PowerGrid.toggle_district(district_id)` — the
only other live call site of `toggle_district()`/`toggle()` besides
`power_grid.gd` itself, and the mechanic GDD §4.3 still documents
("Переключатели `PowerSwitch` и пазлы: `toggle_district` = STREETS ↔
DARK"). Confirmed unreachable: `scenes/props/puzzle.tscn` (its only
scene) is never instanced anywhere. Even revived it would need `Area3D`/
`StaticBody3D` collision like `power_switch.gd`, not `Area2D`, to
receive any interaction in this project's 3D interact system. Same
treatment as the already-documented `streetlight.gd`/
`streetlight_spawner.gd` fossils below: not deleted (CLAUDE.md: never
delete a file unless proven dead *and* not a planned feature), flagged
so nobody assumes it's live.

## `godot --headless --editor --quit` corrupts `default_bus_layout.tres` on resave — never commit after running it

Needed once this pass to force a `global_script_class_cache.cfg` rebuild
(a brand-new `class_name` isn't visible to other scripts/gates until the
editor rescans the project — a plain `--headless --path . --quit` run
does NOT trigger this, only `--editor` does). Side effect: the editor
resaved `default_bus_layout.tres` on exit and silently corrupted it —
dropped the entire Master bus block, dropped `room_size` from the reverb
effect, and mangled the resource's own `uid` (`audiobuses00` →
`udiobuses00`). Caught only by manually diffing the file before
committing — no gate currently checks bus layout content, only that the
5 expected buses exist by name. **Always run `git diff
default_bus_layout.tres` (and ideally a full `git status`) after any
`--editor` invocation, before staging anything.** `git checkout --
default_bus_layout.tres` reverts it cleanly since flow_check's own bus
gate doesn't need the class cache and passes either way.

**2026-09-12 addendum:** confirmed `--import` triggers the identical
corruption, not just `--editor` — ran `godot --headless --path . --import
--quit` to materialize `.import` files for the arena visual/audio pass's
new assets (LUTs, screenshots, ogg beds), and got the exact same
Master-block/`room_size`/uid damage on `default_bus_layout.tres`. So the
rule is: **any** headless invocation that does a project-wide reimport or
class-cache rebuild (`--import`, `--editor`) is suspect, not just
`--editor` specifically. Reverted with the same `git checkout --` before
committing.

## `game_test_3d_scene.tscn` gate stalls silently after "phase1 combat: damage Shadow"

Pre-existing, not a regression — reproduced identically on a clean stash
of the working tree (before any 2026-09-08 RC-pass edits) and on `main`
with those edits applied. `--headless` hangs until killed (`timeout`
exit code 124); `--windowed` exits cleanly (code 0) but the test runner
never prints its `DONE`/`fails=` line past that point — no script error
in the log, just engine shutdown/leak noise. Combat/damage-on-Shadow is
unrelated to any RC-pass change (i18n, HUD, settings, document catalog).
Not investigated further this pass (would need `--verbose`/a debugger
attached to see what phase1's coroutine is actually waiting on); `tools/
check.sh`'s full (non `--static`) mode will hang here too — run the other
11 gate scenes individually (5 headless: compile/signal-arity/autoload-
api/i18n/asset; boot/perf need `--windowed`, same as the existing boot-
flow note below) until this is fixed.

## i18n: a few always-open-while-playing screens didn't retranslate on a live language switch

Screens toggled via `UIManager` (`.visible = true/false`) stay instantiated
for the whole session — they only rebuild their translated text if they
explicitly listen for it. `journal_ui.gd` and `hud_3d.gd` (HP/Stamina/
Battery/Noise/Visibility/Ammo/Radar/Sprint/Stealth captions) had no such
hook and went stale after Settings → Language until the scene reloaded —
fixed 2026-09-08 (both now reload their translated text on
`LocalizationManager.language_changed`). `city_map.gd` was already correct
(rebuilds on `visibility_changed`). `quest_journal.gd` and
`skill_tree_ui.gd`/`skill_button.gd` had the same gap (tab titles, skill
name/description/cost) — fixed 2026-09-08 Phase 4 pass, same shape of fix
(quest_journal rebuilds like `settings_screen.gd`; skill tree reuses its
existing `refresh()` chain). All screens now cover live language switch.

## i18n: 165 strings are identical to English on purpose — do not "fix" them

`tools/i18n_audit.py`'s `value == en[key]` check still flags ~165 strings
across the 11 non-en/non-ru locales. Every one was manually verified during
the 2026-09-08 autonomous i18n wave as a legitimate cognate/loanword (e.g.
"Auto", "Park", "Normal", "AUDIO", "Journal", "Radio", the "SS-N" codes,
" kg" as an SI unit) or a deliberate loanword choice ("Speedrunner",
"Endurance" kept in de/fr/it/pt_BR) — not an overlooked gap. Full
per-string breakdown and the commit list: `PLAN.md` §Б.4. Any *new* i18n
key added after this point must be translated immediately, not added to
this list.

## Draw calls: 234 measured vs GDD's <200 (D1) / <350 (D11) — D11 met, D1 not

**Update 2026-09-08 (autonomous wave)**: the root cause this entry used
to describe (unbatched per-streetlight Pole/Lamp `MeshInstance3D`) was
fixed in an intervening "FINAL PERFECTION P3" wave — `street_props.gd`
now batches every district's Pole and Lamp meshes into two shared
`MultiMeshInstance3D`, and each `streetlight_3d.tscn` instance sets
`mesh_visible=false` on its own redundant copies (kept for the
`Light3D`/`Hum`/`LightArea` nodes, which can't be MultiMesh'd and were
confirmed NOT the draw-call problem — see
`docs/SESSION_REPORT_FINAL_PERFECTION.md`). Re-measured via
`scenes/tools/perf_check_scene.tscn` (now a real gate, see below):
370 → **234** draw calls in the suburbs spawn district. `perf_check_scene`
gates hard on D11<350 (met); D1<200 is flagged in its output but not
hard-failed (see `scripts/tools/_perf_check_runner.gd`).

The remaining 234→200 gap (per `PLAN.md`'s own prior analysis, still
accurate): monster meshes (6, intentionally not MultiMesh-batched — they
need independent skeletal animation/materials per instance) and
pickupable items (12, individual — scattered per-instance, not currently
pooled). Further reduction needs either a design call (fewer items/
monsters live in the scene at once) or a deeper per-instance batching
technique for animated/pickup meshes — neither is a small tweak.
Documenting rather than guessing further, per this project's honesty
rule; see `docs/PRODUCTION_BIBLE.md` §7 and `PLAN.md` item 1.

**RC final pass (2026-09-10) — WON'T-FIX for RC ("D1 perf, code-side
only").** No draw-call reduction here is simultaneously code-only,
behavior-preserving, *and* verifiable without a Godot Visual Profiler
run (headless reports `draw_calls=0`). The shippable budget — D11 < 350,
the busiest district — is met (234) and hard-gated by
`perf_check_scene.tscn`. Candidates and why each is deferred, not done
blind: (a) MultiMesh-batching the 12 pickup / 6 monster meshes breaks
per-instance bob/rotate animation and individual removal — the same
regression class that broke streetlight reactivity when rushed once
already; (b) distance-culling far pickups changes visible behavior
(pop-in); (c) the single most promising code-side lever for a
Godot-enabled pass: **each `scenes/pickups/item_pickup_3d.tscn` carries
its own `OmniLight3D` glow** (12 live dynamic omni lights in D1) — the
box mesh is already self-lit via an emissive material, so the cast-glow
light is a readability nicety that could be swapped for a cheaper
`VisibleOnScreenNotifier3D`-gated shared light or dropped, but that is a
visual-quality call that needs a Profiler before/after, not a static
guess.

**Update 2026-09-10 (MEGA POLISH) — code-side reduction applied.**
`distance_fade_enabled` added to the streetlight `SpotLight`/`Glow`
(`begin 22 m`, culled at 30 m) and the pickup `GlowOmniLight3D`
(`begin 12 m`, culled at 16 m). Both lights have short reach (spot 12 m,
pickup omni 3.2 m), so nothing a player can see changes — only lights
whose lit effect is already off-screen get culled entirely ("not sent to
the shader at all", per the `Light3D` docs). `tools/qa_sim/drawcall_estimate.py`:
a representative D1 frame goes from **58 → 18 active real-time lights
(−69%)**. The residual structural draw calls (6 non-batchable monster
meshes, in-view pickups / interactables, HUD 2D) still put a firm `<200`
out of static reach — that needs a Profiler pass and, likely, a design
call on concurrent monster/pickup counts. Owner step: re-run
`scenes/tools/perf_check_scene.tscn --windowed` and read the new number.

## boot_check_scene.tscn can see a spurious PLAYING -> MENU during its
## sustain phase — test-harness artifact, not a real-game bug (tolerated,
## logged as WARN, does not fail the gate)

Found and extensively traced while building the P0.4 permanent gate.
Sequence: `_boot_check_runner.gd` runs under `get_tree().root` because
`boot_check_scene.tscn` is passed as a scene override (`godot ... res://
scenes/tools/boot_check_scene.tscn`), which is not how a real player ever
launches the game (they always boot through the real configured main
scene, `boot_loading.tscn`, directly). This unusual entry point puts
`_bootstrap.gd`'s autoload fallback (`if current_scene == null or
current_scene.name == "": Routes.goto(splash.tscn)`) in an ambiguous
position it never occupies for a real player, and something in that
window occasionally leaves a `splash.tscn` instance alive whose ~3s tween
fires `Routes.goto(BOOT)` a second time, later, during active gameplay —
`boot_loading.tscn`'s own natural ~3.3s countdown then calls
`Routes.to_menu()`, and `main_menu.gd`'s own defensive
`if not GameManager.is_menu(): return_to_menu()` forces the state change
the gate observes.

Traced with temporary stack-trace instrumentation on
`GameManager._change_state()` and `Routes.goto()` (removed after
diagnosis — see the corresponding commit) across ~8 runs. The exact
instantiation call for the orphaned `splash.tscn` node was never fully
pinned down (every `Routes.goto()` call is logged unconditionally, and no
`splash.tscn` target ever appeared in the trace despite `splash.gd`'s
callback firing later) — plausibly a buffering/ordering artifact of the
diagnostic prints themselves rather than the underlying scene-tree
mechanism, but conclusively NOT reachable through any code path a real
player's boot sequence uses (`boot_loading.tscn` is deterministically
`current_scene` from frame 1 in a real launch; `_bootstrap.gd`'s
fallback condition can only be true in a real launch if the engine
somehow fails to set up its own configured main scene, an unrelated and
already-legitimate safety net).

Given the repro requires a test-only entry point mismatch, the gate
treats a `PLAYING -> MENU` transition (without death) during its sustain
phase as a logged warning, not a failure — `scripts/tools/
_boot_check_runner.gd`'s sustain loop. If this same symptom is ever
reported from an actual player build (not a `boot_check_scene.tscn`
run), treat it as a new, real bug — this analysis assumes the gate's own
entry-point mismatch as the root cause and would not apply.

## Streetlights: three implementations existed, only one was live, none
## reacted to district power (fixed — see git log for the commit)

Found during TRUTH WAVE P1. Three separate streetlight scripts existed:

- `scripts/world/street_props.gd` (CityStreetProps) — live in all 11
  district scenes. Built flat emissive-decal "lamps" (a `SphereMesh` with
  an emissive material, no actual `Light3D` node) that were always on,
  never checked district power stage.
- `scripts/world/streetlight_spawner.gd` (StreetLightSpawner) — only
  placed in `main_3d.tscn`'s root, whose `street_builder_path` default
  (`^"StreetBuilder"`) never resolves there (the real `StreetBuilder`
  nodes only exist nested inside each district's runtime-built subtree).
  Confirmed **dead code**: `_ready()` returns immediately every time.
- `scripts/world/streetlight_3d.gd` + `scenes/props/streetlight_3d.tscn`
  — a complete, correct implementation: real pole mesh, `SpotLight3D` +
  `OmniLight3D` glow, hum audio that starts/stops with the light, a
  `light_zone` `Area3D` (stealth-visibility relevant), and a live
  `EventBus.district_stage_changed` connection matching GDD §11.1's
  "darkness -> restored power" reward exactly. **Never instantiated
  anywhere** — confirmed dead simply because nothing spawned it.

Net effect before the fix: the game's namesake mechanic (streetlights
turning on as districts are restored) did not exist in actual gameplay.
Every street was permanently "lit" with non-reactive decals regardless
of district power stage.

**Fix**: `street_props.gd` now instantiates `streetlight_3d.tscn` (reading
`district_id` from the sibling `StreetBuilder` node already present in
every district scene) instead of building the old decals. The old
behavior is preserved behind a project setting, disabled by default:

```ini
[world]
legacy_streetlights=false   ; true = old flat-decal poles, for comparison/rollback
```

`streetlight_spawner.gd` and `scenes/props/streetlight_3d.tscn`'s dev-only
probe references were left as-is — neither is deleted (CLAUDE.md: never
delete a file unless proven dead *and* not a planned feature; the spawner
in particular has real road-following placement math that could be
salvaged later if street_props.gd's simpler even-step placement isn't
good enough).

`scripts/world/streetlight.gd` (`extends PointLight2D`) is a leftover
fossil from an earlier prototype phase — inert in this 3D game (Light2D
nodes do not affect the 3D rendering pipeline at all). Not deleted for
the same reason; flagged here so nobody spends time trying to "fix" a
2D light node in a 3D scene.

## Skill tree: 4th branch + skill-string localization — RESOLVED

Both of these were open earlier and are now closed (noticed stale during
the 2026-09-10 RC pass; verified against the current code):

- **4th branch (GDD §8 wants 4, project had 3):** `skill_tree_manager.gd`'s
  `SKILL_TREES` now defines **4** — `combat`, `survival`, `utility`,
  `stealth` (the Stealth branch: `silent_steps`, `cold_trail`, real
  effects wired into `player_3d.gd`/`base_monster.gd`). Added in PLAN.md
  Stage 3, commit `b861b14`.
- **Skill name/description localization:** every skill's `name`/
  `description` in `SKILL_TREES` is now an `SKILL_*` i18n key
  (`SKILL_DAMAGE_BOOST_1_NAME`, `SKILL_SILENT_STEPS_DESC`, …), resolved
  through `LocalizationManager`, present in all 13 locales
  (`i18n_audit.py`: `MISSING: 0`). The raw-English-in-code state this
  entry used to describe is gone.

## Confirmed dead code, not touched (fixing it would have zero player-facing effect)

- `scripts/ui/lobby_menu.gd` + `scenes/ui/lobby.tscn` — a LAN multiplayer
  lobby screen. Not registered in `UIManager`'s screen dict, no button
  anywhere opens it. Has the same raw-`tr()`-on-English-sentence bug as
  the skill tree did, left unfixed since nothing reaches this screen.
  **ARCHIVED (PLAN.md Stage 1, decided): keep unwired, do not delete.**
- `scripts/ui/save_slot_entry.gd` + `scripts/ui/save_slots_ui.gd` — a
  multi-slot save/load picker UI. Also not registered in `UIManager`, no
  reachable entry point (the real save/load path is `main_menu.gd`'s
  single "Continue" button -> `GameManager.continue_game()`, unrelated to
  this file). Same unfixed `tr()` bug for the same reason.
  **ARCHIVED (PLAN.md Stage 1, decided): keep unwired, do not delete.**
- Previously documented in `docs/VISUAL_AUDIT.md`: `city_decorator.gd`,
  `door.tscn`/`exploding_barrel.tscn`/old `pickups/*.tscn` (no material,
  never instantiated), `daily_events_ui.gd` (not in `UIManager`'s dict
  either — its hardcoded strings were still localized in the RC final
  pass so a future wiring doesn't reintroduce an i18n-rule violation).
- `scripts/ui/onboarding.gd` — a contextual first-time-hint system
  (WASD / flashlight / shadow / interact / inventory prompts on gameplay
  events), fully authored and i18n'd, but **not instanced anywhere** and
  not an autoload. Superseded by the two live systems: `tutorial_system.gd`
  (the FTUE) and `onboarding_overlay.gd` (the 4-panel first-launch
  overlay, wired in `main_3d.tscn`). Reviewed in the RC final pass —
  wiring a hint system in blind (NO-GODOT) is a feature-integration risk,
  not an RC polish; left for a Godot-enabled pass or an owner decision to
  archive it. `onboarding_overlay.gd` itself was reviewed clean (shows
  once per save profile, never blocks gameplay, i18n on all captions/
  buttons; only nit — it doesn't retranslate on a live language switch
  mid-overlay, negligible for a once-ever first-launch screen).

## Accessibility toggles — 5 of 7 were non-functional; fixed 2026-09-10 (MEGA POLISH)

The Settings → Accessibility tab shipped 7 toggles; a static trace
(`tools/qa_sim/a11y_check.py`) found only High Contrast half-worked:

- **Colorblind Mode** — `_apply_colorblind()` was an empty stub. Now a
  real full-screen `canvas_item` post shader (deuteranopia / protanopia /
  tritanopia channel-lift), mounted on a `CanvasLayer` from
  `settings_manager.gd`. Conservative constants — a colorblind playtester
  can tune the `*1.15 / 0.10 / 0.20` factors in the shader string.
- **Text Size** — iterated an `"ui_text"` group that nothing ever joins
  (and would have compounded). Now scales `get_tree().root.theme.default_font_size`
  from a captured base. **Partial by design**: screens that hard-override
  their own font size won't scale — full coverage needs each screen to
  honor a text-scale, out of scope for RC.
- **High Contrast** — `_apply_high_contrast()` worked, but the generic
  `_toggle` in the Settings screen only called `set_setting()`, never
  `set_high_contrast()`, so the checkbox did nothing. `set_setting()` now
  dispatches to the real applier for every accessibility key.
- **Arachnophobia Mode** — `enemy.is_instance_valid()` is a runtime error
  (`Node` has no such method) → the toggle *crashed*. Fixed to the global
  `is_instance_valid(enemy)`.
- **Auto-aim Assist** — `auto_aim` is read by nothing anywhere in the
  codebase. **Removed from the UI.** Re-add when an aim-assist code path
  exists (`player_3d` targeting).
- **Dyslexia Font** — loaded `res://assets/fonts/OpenDyslexic-Regular.ttf`,
  which is **not shipped**, and (again) iterated the empty `"ui_text"`
  group. **Removed from the UI**; `_apply_dyslexia_font()` guarded against
  the null load. Re-add once the OpenDyslexic `.ttf` is added to
  `assets/fonts/` — and gate it to Latin-script locales (it has no CJK /
  Arabic glyphs).
- **Reduce Screen Shake** — worked (added in the RC pass; read directly in
  `screen_shake.gd`).

Accessibility effects are now re-applied on config load
(`from_dict → call_deferred("apply_all_accessibility")`).

## Unmerged `arena/*` branches on origin — deliberately not merged (RC triage 2026-09-10)

Three `arena/*` branches remain on origin after the RC final pass. Only
one was merged; the other two are intentionally left alone.

- **`arena/01a08729-igra` — MERGED** (RC final pass, Phase B). Store kit
  (`store/**`), `docs/PROSE_CHANGES.md`, `docs/ASSET_LICENSES.md` +
  `AUDIO_COVERAGE.md` + `CONTENT_PIPELINE_AUDIT.md` §10, and a 2-word
  `centre→center` prose fix in `gas_station`/`police` `lore_notes.json`.
  In MERGE POLICY scope; see `PLAN.md` 2026-09-10 decisions-log entry.
- **`arena/019ffbd0-igra` — NOT merged.** 57 commits, merge-base ~60
  commits behind `main`. Its payload (the autopilot in-engine test suite
  plus a large stealth/doors/save/tutorial/finale fix batch) already
  landed on `main` through earlier integration — `tools/autopilot/`,
  `tools/flow_check.py`, `tools/orphan_check.py` are present and
  CLAUDE.md's "Already done" list enumerates the fixes. Merging now would
  replay stale history into conflicts for no gain. Kept on origin for
  archival only; safe to delete once someone confirms nothing unique is
  on it.
- **`arena/01a07b1c-igra` — NOT merged.** 9 commits implementing an
  FPS-weapons layer (`scripts/weapons/**`, `project.godot`, player/weapon
  `.tscn`, `data/items/ammo.tres`, `docs/IDEA_CONFORMANCE.md`). Outside
  the content/store/docs scope this project's self-merge protocol allows,
  and a separate feature track (GDD §18) rather than RC finishing work.
  Needs an explicit owner design decision before any of it goes near
  `main` — do not self-merge.

## Mobile texture compression — every texture ships Lossless (mode=0), not VRAM Compressed (P1/OWNER)

Checked this pass (PLAYABLE IDEAL, STEP 5 mobile perf): all 1230 `assets/**/*.import` files
sampled use `compress/mode=0` (Lossless) — none are VRAM Compressed. On Android this means
larger APK size and full RGBA8 GPU memory per texture instead of ETC2/ASTC block compression
(typically 4-6x less VRAM). `export_presets.cfg`'s Android preset now has
`texture_format/etc2_astc=true` (added this pass — inert today since nothing is VRAM-compressed
yet, but correct and ready for the migration below).

**2026-09-12 re-measured (RELEASE CONVERGENCE STEP 7):** fresh count finds
738 texture `.import` files (not 1230 — likely a different glob/snapshot;
both counts agree on the finding: 100% Lossless, 0% VRAM Compressed),
41.2 MiB total on disk. Full byte breakdown, a scoped/prioritized pilot
(`tiles`+`surfaces` = 65% of `assets/textures/`, lowest banding risk),
and an honest APK-size-vs-VRAM-memory impact estimate in
`docs/artifacts/apk_size_report.md`. Same decision as below still holds —
not fixed this pass either, for the same reason (needs a windowed banding
check this session structurally cannot run).

**2026-09-12 EXECUTED (FINAL HARDENING PASS, BLOCKER 2):** the pilot
above was actually run and PSNR-verified — 74 files (`tiles`, `surfaces`,
3 of 4 `environment`) converted to `compress/mode=2` +
`compress/high_quality=true`, every one individually confirmed ≥40dB
against its Lossless original (45.64-52.37 dB actual range;
`high_quality=true` was required — default quality failed the bar
entirely at 34-37 dB). `enemies` textures failed even at high quality
(28-36 dB) and stayed Lossless. Full method, per-file numbers, and
category-by-category reasoning: `docs/artifacts/
texture_compression_audit.md`. Committed via a scoped `.gitignore`
exception for exactly these 74 `.import` files (normally never
committed in this project) so the setting survives a clean checkout.
**Real measured result, not an estimate:** on-disk size for these 74
files went **up** 8.99→9.69 MiB (this game's flat art already compresses
well under Lossless PNG) while VRAM/runtime footprint went **down**
38.75→9.69 MiB, a real ~4x reduction — confirming the VRAM-memory case
was always the substantial one, not APK download size. The windowed
banding check remains the one owner-only step before this specific
change should be trusted in production
(`docs/artifacts/known_owner_only_items.md`).

**Why not fixed here:** re-importing ~1230 textures to VRAM Compressed is a bulk `.import`
edit outside a headless session's safe reach for two reasons: (1) `assets/textures/**` is
Arena's/OpenCode's ownership zone, not reassigned for a project-wide pipeline change (only
this pass's 12 new mobile-art files were reassigned); (2) VRAM block compression can introduce
visible banding on this game's palette-locked, deliberately-flat-gradient art (STYLE_GUIDE
explicitly bans banding) — verifying that needs a windowed visual diff, which NO-GODOT
headless-only policy forbids.

**Owner remediation:** in the Godot editor, select `assets/textures/**` (environment/prop
surfaces are the highest-value targets — UI glyphs and the STYLE_GUIDE-locked flat art may be
better left Lossless for crispness) → Import dock → Compress Mode → **VRAM Compressed** →
Reimport, then a visual spot-check for banding on a few district loading screens before
shipping. `texture_format/etc2_astc=true` is already set for when this lands.

## GDD achievement count is stale — code ships 31, GDD/store copy says 20

Found 2026-09-12 (RELEASE CONVERGENCE, arena store-pass cert). `docs/GDD.md` §21 and its
supplement §S17 list exactly `ach_01`–`ach_20` (20 achievements), and `store/listing.md`
correctly ships "20" per the repo's GDD-wins-on-conflict rule. But
`scripts/systems/achievements_manager.gd` has shipped **31** since the GOLD MASTER v5 hooks
pass (2026-09-11) added 11 per-district achievements (`ach_district_<id>`) that were never
back-ported into the GDD. The GDD is the stale side, not the store copy.

**Why not fixed here:** updating GDD §21 to list 11 new achievement entries (name/description/
trigger per district) is a content-canon write, not a bugfix, and risks scope creep into a
docs-consolidation pass. Deferred to a dedicated content pass.

**Remediation:** add the 11 `ach_district_<id>` entries to GDD §21/§S17 (name = the existing
`DISTRICT_NAME_<ID>` i18n key, description = the shared `ACH_DISTRICT_FULL_DESC` key already
in code), then re-run `tools/gen_store_listing_locales.py` with the polished bullets ported in
first (`docs/CERT_STORE.md` §8.2 warns regenerating without doing so reverts the 2026-09-11
benefit-led polish) so store copy can honestly say 31.

## Touch feel (BLOCKER 3, FINAL HARDENING PASS) — code-level timing proven headlessly; real-device feel is not, and cannot be

`touch_probe_scene.tscn` now asserts concrete timing budgets, not just
that a signal fires eventually: joystick touch-down updates
`InputService` the same call (measured, not assumed — CPU time between
the injected event and the state change, comfortably under one frame at
60fps); the knob's press-scale animates over 80-120ms of *simulated game
time* (driven by an explicit fixed 60fps delta rather than real engine
frames — `--headless` has no vsync/frame cap, so wall-clock time for N
frames does not equal N/60s of game time on a nearly-empty test scene,
which is what the first version of this test got wrong before it was
fixed to drive `_process()` directly); the haptic call and the
interact-button proximity pulse both fire the same call as their
triggering signal.

**What this proves:** the code paths that are SUPPOSED to feel responsive
have no accidental extra latency, no deferred call, no wrong animation
rate baked in — `virtual_joystick.gd`'s press-scale rate was actually
wrong before this pass (6.0/s → ~167ms, outside the 80-120ms spec; fixed
to 10.0/s → ~100ms) and this is the test that caught it.

**What this cannot prove, and no headless session ever will:** whether a
real thumb on real glass, with real touch-sampling latency, a real
haptic motor's actual felt intensity, and real screen-to-finger parallax,
actually *feels* good. `Input.vibrate_handheld()`'s ms argument is a
request to the OS; its physical strength/timing on any specific device is
outside Godot's (or this session's) control entirely. This is the same
category of gap `docs/HONEST_ASSESSMENT.md` already names as the
project's headline risk — a real device playtest is the only way to close
it, tracked in `RELEASE_CHECKLIST.md`.

**Also new this pass:** a "Touch Tuning" preset (Comfort/Default/
Responsive — Settings → Controls) is a one-tap shortcut over the
sensitivity/deadzone/haptics sliders that already existed, not a new
mechanic; and a one-time "Touch Calibration" overlay (drag, tap, feel the
haptic) shown on a touch device's first HUD load
(`scripts/ui/touch_calibration_overlay.gd`), gated the same way every
other touch-only setup in `hud_3d.gd` already is
(`has_touch_ui()` + a persisted `touch_calibration_done` flag).

## District collection cards: 4 of 22 share a base photo, don't depict their own district (2026-09-13, art-final merge)

**Status (2026-09-14): RESOLVED.** 11/11 districts now ship unique
photography; the seven shared-photo textures above were replaced in
`assets/textures/cards/` (unlocked + regenerated `_locked_512`), see the
status update in the "arena/card-unique-rescue" entry at the top of this
file. Only the frozen suburbs/residential keeper pair (h=1) remains.

`arena/art-final`'s new `assets/textures/cards/card_<district>_512.png` art
(wired live this pass into `scripts/ui/collection_ui.gd`) is genuinely
new, correctly dimensioned (512×512, PSNR/purity clean per
`docs/CERT_ARTFINAL.md`), and each file is a distinct PNG (different
SHA-256) — but `docs/LEDGER_ARTFINAL.md` line 90 documents, by design,
that 4 source photos are shared across all 11 districts: `hero_grid_
cascade` for power_station/substation, `hero_first_restore` for suburbs/
residential/park, `hero_reactor_room` for industrial/warehouses, and
`still_first_light` for **everything else** — school, hospital,
gas_station, and police all key off the same streetlight photo,
differentiated only by per-district color grading (same "twins stay
twins" precedent already accepted for the LUTs), not by depicting the
district. This means `docs/CERT_ARTFINAL.md`'s own per-card "Mood"
column ("gas station pumps wet concrete ember glow", "school corridor
chalk dust flickering", "police desk badge radio blue cold", "hospital
hallway cold teal gurney") describes a scene that isn't actually in the
image for those 4 districts — a real content-accuracy gap in the
delivered art, found by an S-assets verification subagent during the
FINAL CONSOLIDATION merge, not a wiring bug and not something code can
fix. Not blocking (the card still renders, still shows *a* moody night
scene, and the district name/accent-color/progress-bar below it are
correct) — flagged here for whoever holds the art pipeline next: 4 of
22 cards would benefit from a bespoke re-render matching their own
scene description.

## arena/texture-optimization edge-case defects (2026-09-13)

Hunted across the five mandated focus areas (save/load across district
transitions, NG+ restart, locale switch mid-run, audio bus reconnection,
concurrent signal emissions). Five new defects found; three fixed in
this branch (✅), two left as KNOWN_ISSUES (⚠️) because they need an
owner-level decision or art/content change, not a code patch.

### ✅ Defect 1 (FIXED): `audio_atmosphere.gd` district pitch table used wrong ids
**Area:** audio + district transitions
**Repro:** Start a run, walk into any district (hospital/police/gas_station/
warehouses/substation/power_station). The procedural ambient drone in
`audio_atmosphere.gd` is supposed to shift per district (+/-25 Hz) but
the `_district_pitch_offset()` match table used legacy names
(`"suburb"`, `"policestation"`, `"gasstation"`, `"warehouse"`,
`"powerplant"`) that never match the canonical district ids
(`suburbs/police/gas_station/warehouses/power_station`). Every district
fell through to the `return 0.0` default so the same 55 Hz drone played
everywhere.
**Fix:** Renamed the table's keys to the real StringNames used
everywhere else in the project. Verified against DistrictManager.DISTRICTS.

### ✅ Defect 2 (FIXED): Slot saves didn't persist current district / onboarding / daily streak
**Area:** save/load across district transitions
**Repro:** Walk into hospital, open the (archived) save-slots UI, save to
slot 1, return to menu, load slot 1. `save_slot()` wrote `wallet`,
`power`, `player_pos`, etc. but omitted `district`, `onboard_done`,
`daily_streak`, `last_daily_time` — the exact same class of bug that
TRUTH WAVE P0.2 fixed on the main save. Loading the slot always returned
the player to `suburbs` regardless of where they saved, reset the daily
streak, and could re-show the onboarding overlay that should only appear
once.
**Fix:** `save_slot()` now writes `district`, `onboard_done`,
`daily_streak`, `last_daily_time` (matching `_save()`); `load_slot()`
restores `DistrictManager.current_district` and `_onboard_done` the same
way `load_all()` does.

### ✅ Defect 3 (FIXED): Weather name doesn't refresh on mid-run locale switch
**Area:** locale switch mid-run
**Repro:** Start a run during a non-CLEAR weather (wait ~45 s for RAIN/
FOG/STORM/WIND), open Settings → Language, pick a different language,
close settings. The `weather_changed` signal carries a localized
`weather_name` string; until the next random weather tick (up to 45 s
later) any UI showing the current weather name kept the previous
language. Latent today (no listener reads the name in the current HUD)
but a real trap for future consumers and a violation of the "all
dynamic strings refresh on language_changed" invariant every other
system holds.
**Fix:** `weather_system.gd` connects to
`LocalizationManager.language_changed` (deferred, to handle autoload
order) and re-emits the current weather with the freshly translated
name.

### ✅ Defect 4 (FIXED): `streetlight_hum_pool` never set an audio bus, never looped the hum, never reconnected to SFX
**Area:** audio bus reconnection
**Repro:** Boot a fresh profile, walk to a lit street (post-restore
suburbs). The 8-slot `AudioStreamPlayer3D` pool in
`streetlight_hum_pool.gd` routed to the default `"Master"` bus (bypassing
SFX volume sliders) because `p.bus` was never set. More importantly, the
hum stream's `.import` loop flag is not committed to git (same pattern
called out in `audio_manager._force_loop()` / `music_manager._force_loop()`),
so on a fresh checkout the WAV imported with `loop_mode=DISABLED` and
each pool slot fell silent after ~0.6 s once the one-shot WAV ended,
producing a continuous pop/churn on the REASSIGN_INTERVAL cadence. Also,
if SettingsManager created the `SFX` bus deferred after our `_ready()`
ran, we never migrated slots off Master.
**Fix:** Pool slots now set `bus = "SFX"` (with Master fallback),
`_force_loop()` the hum stream at startup, and `_reassign()` lazily
reconnects every slot to SFX the moment the bus appears.

### ⚠️ Defect 5 (known, not fixed): `DistrictTrigger.one_shot` can prevent district_entered from (re)firing on respawn after death
**Area:** save/load + concurrent signals
**Repro:** Die and revive inside a district trigger Zone (rare: trigger
Zones are the invisible boxes at district borders, but a death while
backpedalling across a border can leave the player's body inside the
neighboring trigger). Revive keeps the same district scene loaded;
`_fired = true` from the original entry stays `true` because
`district_trigger.gd` only resets it on `_ready` (new scene instantiation),
not on revive. Walking back across the trigger and re-entering the same
neighbor district would not emit `district_entered` again. Low hit-rate
in practice (deaths inside border triggers are uncommon) and fixing it
correctly needs a design call on whether revive should re-fire
`district_entered` at all (would restart the save-on-entry autosave,
refresh ambience twice, etc.) — flagging here rather than making a
call that could re-introduce the double-transition crashes `world_
runtime.gd`'s `_loading` guard exists to prevent.

### ✅ Drive-by fix caught during the hunt: `music_manager.gd` double-subscribed to game_won / game_started
`_ready()` connected `EventBus.game_won` twice (once for `set_mood(VICTORY)`,
once for `_play_wow_cue("ending")`) and `game_started` twice (once for
`set_mood(AMBIENT)`, once to reset `_first_light_cue_done`). Godot still
invokes each callback, so both effects did happen, but the double
subscription was a latent concurrent-signal footgun (a future listener
added to one of those lambdas would fire twice per event). Consolidated
into two `_on_game_started` / `_on_game_won` methods that do both.
