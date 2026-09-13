# Game quality dossier — The Last Streetlight

Index of every evidence artifact, newest pass first. Each row says what the artifact is and
what it actually proves. The artifact itself always stays the source of truth; this file
only points at it.

Compiled 2026-09-13 at the end of the MEGA FINAL PASS.

---

## What this pass changed, in one paragraph

Three of four candidate content branches were merged after independent scope-checks; the
fourth was rejected for certifying work it had not done. The headline engineering result is
that **secrets became reachable at all** — the secret object was written for the 2D build
and the 3D interactor skips non-`Node3D` nodes, so `EventBus.secret_found` had never fired
once in the shipped game, taking its quest, achievement, XP, rewards and counter down with
it. Six review agents then went over the result; they found nine defects, including two P0s
in the same day's work, and all of them were fixed or explicitly recorded.

## Review agents run this pass

| Agent | What it checked | Outcome |
|---|---|---|
| Scope-check ×4 (one per branch) | diff vs declared zone, JSON/schema validity, ledger rows, asset integrity | 3 GREEN, **1 RED** — the RED caught a fabricated certificate |
| A-audio-mix | bus tree, LUFS/RMS/peak of every bed and sting, ducking, routing | 7 findings: 3 fixed, 3 recorded as deliberate non-goals, 1 pass |
| A-retention-fun | paper playtest of the first three sessions, return loop | score 5/10, top-3 friction all fixed |
| A-edgecases | autoload order, save round-trip, double-spawn, null/type safety | **2 P0**, 2 P1, 2 P2 — all actioned |
| A-visual-consistency | LUT coverage, post-fx ranges, palette family, card duplicates, badge legibility | 1 real defect (cards), everything else measured clean |

## Artifacts — MEGA FINAL PASS (2026-09-13)

| Artifact | Path | Proves |
|---|---|---|
| Audio mix report | `docs/artifacts/audio-mix/audio_mix_report.md` | ffmpeg-measured bus tree and per-file LUFS/RMS/peak; stingers were 8–14 dB *under* the bed, not above it |
| Retention & fun review | `docs/artifacts/retention-fun/retention_fun_review.md` | only 1 of 26 secrets was reachable at game start; return loop 5/10 with the reason |
| Edge-case audit | `docs/artifacts/edge-cases/audit_edge_cases.md` | secret respawn on re-entry; New Game not resetting two systems; 27/31 achievements silent |
| Visual consistency | `docs/artifacts/visual-consistency/visual_consistency_report.md` | LUT 11/11, presets 0 out-of-range, palette 0 outliers, **cards only 4 distinct of 22** |
| Content-depth validator | `docs/artifacts/content-depth/audit_content_depth.py` | 26 secrets + world canon; gate-enforced, 0 ERROR |
| Retention validator | `docs/artifacts/retention/validate_retention.py` | 60 dailies / 6 modifiers / 28 captions; 270 checks ALL PASS; gate-enforced |
| Known issues | `docs/KNOWN_ISSUES.md` | the five gaps left open, each with reproducible evidence |
| Player-visible Batch 18 | `docs/PLAYER_VISIBLE_CHANGES.md` | what the owner should verify by hand |

## Artifacts — earlier passes

| Artifact | Path | Proves |
|---|---|---|
| Owner release packet | `docs/OWNER_RELEASE_PACKET.md` | the copy-paste path from here to a Play Console upload |
| Owner-only items | `docs/artifacts/known_owner_only_items.md` | what cannot be automated and why |
| Final gate report | `docs/artifacts/final_gate_report.md` | gate history |
| APK size | `docs/artifacts/apk_size_report.md` | build size budget |
| Texture compression | `docs/artifacts/texture_compression_audit.md` | VRAM budget, PSNR-gated |
| Security report | `docs/artifacts/security_report.md` | dependency and permission review |
| Content pipeline audit | `docs/CONTENT_PIPELINE_AUDIT.md` | per-pass content verdicts §1–§19 |
| Asset licences | `docs/ASSET_LICENSES.md` | provenance for every shipped asset |

## Autoplay bot — the regression no static gate could see

`bash tools/qa_sim/autoplay_bot` plays the game headless with simulated input only. It
caught a defect that passed static 12/12, engine 24/25 *and* the whole headless suite:

`scripts/tools/_qa_autoplay_runner.gd::_switch_node()` locates a district's power switch by
duck-typing over the `interactable` group — the first node carrying a `district_id` and an
`interact()` method. The newly-wired `secret.gd` had both. The bot therefore walked to a
secret instead of the switch, collected it, the district never advanced, and the run died on
the 45-second no-progress timeout.

| Run | Districts restored | Outcome |
|---|---|---|
| With the collision | 5 / 11 | softlock at `gas_station` stage 2 |
| After renaming the field to `home_district` | **11 / 11** | reaches the final night, then stalls in the boss phase |

The remaining boss-phase stall is the **pre-existing, already-recorded gap**, not new: the
prior `RELEASE_ARTIFACTS` row states "11/11 districts in the clear majority of runs … and
the remaining boss-fight gap", and `_qa_autoplay_runner.gd` carries a note dated 2026-09-12
explaining that the bot cannot keep its flashlight battery alive through the boss fight.
None of this pass's changes touch boss combat or battery drain at default modifier values.

The lesson worth keeping: a feature can be wired correctly, pass every gate, and still break
the game through a name collision with an existing convention. The bot is the only thing
that found it.

## Standing gates

`bash tools/check.sh` — 12 static gates (now including both content validators) plus 13
engine gates. `bash tools/qa_sim/headless_suite` — 12 engine gates plus the extended
scenario driver. `python tools/i18n_audit.py` — key parity across 13 locales.

Current state: **static 12/12, engine 24/25, headless suite green, i18n MISSING 0 at 1265
keys.** The single engine failure is the pre-existing 3D-scene 90s stall, documented and
unchanged from the baseline before this pass.

## The honest list — what is NOT done

1. **Seven districts share another district's card photograph.** Measured, not estimated.
   Needs art, not code.
2. **The 154 new content strings are English in all 12 non-English locales.** Parity is
   exact and `MISSING: 0`, but that is a key-presence result, not a translation. Russian
   matters most here.
3. **Seven of eleven NG+ modifier knobs are stored but not consumed**, so some modifier
   descriptions promise more than they deliver today.
4. **Secrets are placed by seeded scatter, not by their authored zone**, because the 3D
   districts have no zone markers — so `location_hint` prose describes fiction.
5. **No music ducking anywhere**, and the Ambient bus does not carry the district beds, so
   its settings slider does not move what the player hears.
6. **No out-of-app notification**, which is the largest single lever left on the return
   loop.
