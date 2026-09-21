# QA swarm findings — 2026-09-21

5 hostile personas (subagents, read-only investigation, deduped against `docs/KNOWN_ISSUES.md`
and `docs/SECURITY_THREAT_MODEL.md` before reporting — none re-litigate the already-fixed
residential softlock, boss Y-dip, or XP-reset bugs). 20 findings total. P0/P1 items get a
fix disposition below; P2 items are recorded for the record, not all fixed this pass.

## Cheater / exploiter persona

| Sev | Finding | Evidence | Disposition |
|---|---|---|---|
| P1 | Infinite loot/repair-part farming: `district_loot.gd:135-173` `populate()` re-spawns COMMON/REPAIR_PARTS/BY_DISTRICT with no "already collected" gate (only secrets have one) — leave-and-re-enter restocks medkits, batteries, cable/fuse/transistor | `scripts/world/district_loot.gd:135-173`, called every scene rebuild via `world_runtime.gd:62` | **FIXED this pass** (P3), see below |
| P1 | Daily reward repeatable via system-clock manipulation — `_today_index()` derives entirely from `Time.get_unix_time_from_system()`, only anti-replay gate compares against the same manipulable clock | `scripts/systems/daily_challenge_manager.gd:89-90,96-97` | Deferred — clock-trust is a client-side ceiling this game's threat model already accepts elsewhere (see `docs/SECURITY_THREAT_MODEL.md`); not worth a real-time server round-trip this game doesn't have |
| P1 | `user://tls_daily.json` completely unsigned (unlike the main save's HMAC envelope) — hand-editing `last_completed_day` resets the claim gate | `scripts/systems/daily_challenge_manager.gd:23,153-171` | Deferred — same root cause as above (client clock is untrustworthy regardless of file signing; signing the file stops edits but not clock rollback, so it only half-closes the hole for real effort) |
| P2 | `achievements.cfg` unsigned, can hand-set `unlocked: true` | `scripts/systems/achievements_manager.gd:167,181-194` | Deferred — local single-player trophies only, no leaderboard, lowest blast radius of all findings |
| P2 | `CoinWallet.add()` has no runtime upper clamp (only `from_dict()` on load clamps) | `scripts/economy/coin_wallet.gd:9-13` | Deferred — cosmetic; no negative-balance path exists, so not a real dupe vector |

**Confirmed already defended, not findings**: save-file tamper (HMAC + independent second signature, matches `docs/SECURITY_THREAT_MODEL.md`), secret-loot re-farming (`ProgressTracker` gate), inventory duplication (RPC path is offline-gated, single-player never round-trips).

## Speedrunner / sequence-breaker persona

| Sev | Finding | Evidence | Disposition |
|---|---|---|---|
| P2 | `DistrictManager.transition_to()` has zero prerequisite check — only the City Map UI's disabled button currently prevents out-of-order travel; a debug console or future caller could bypass it | `scripts/district_manager.gd:60-66`, `scripts/ui/city_map.gd:181-187` | Deferred — not player-reachable today (verified: no other caller besides the QA bot and the gated UI button), architecture note for future callers |
| P2 | `DistrictTrigger` has no order/prerequisite validation, currently always self-referential so harmless | `scripts/world/district_trigger.gd:14-23` | Deferred — same as above, latent not live |
| P2 | Self-referential district trigger re-fires `SaveSystem.save_all()` on every re-entry (pacing/perf nit, not correctness) | `scripts/world/world_runtime.gd:26-28` | Deferred — cosmetic |
| Needs verification | Save-mid-transition 1-frame window (`transition_to()` sync vs `call_deferred("load_district")`) could theoretically pair a new district id with stale `player_pos` if an event-driven save lands in that exact frame | `scripts/district_manager.gd:65`, `scripts/world/world_runtime.gd:50,73-88` | Deferred — not reproduced, flagged for a future session with reproduction budget |
| P2 (by design) | Repair parts explicitly farmable ahead of unlock — code comment confirms this is intentional | `scripts/world/power_switch.gd:20-22` | Not a defect, no action |

**Confirmed already defended**: boss/finale gating (double-checked via `PowerGrid.all_restored()` AND physical entry), no rapid-interaction race on district-stage advance (synchronous, no `await`).

## Low-end mobile persona

| Sev | Finding | Evidence | Disposition |
|---|---|---|---|
| P1 | D1 draw-call budget (<200) still not met — 234 after the prior MultiMesh batching pass (down from 370); D11 (<350) passes | `docs/KNOWN_ISSUES.md:966-991` (already tracked) | Not re-opened — needs a dedicated session per existing docs, out of scope for a sweep |
| P1 | Texture compression migration incomplete — `assets/textures/enemies/*.png.import` still `compress/mode=0` (RGBA8) while most other categories are `mode=2` (VRAM/ETC2); enemies are the highest-res, most-visible-on-screen assets | `assets/textures/enemies/*.png.import` | Deferred to P4's eyes-on pass — recompressing textures needs visual verification before/after, not a blind batch edit |
| P1 | Mobile environment has `glow_enabled=true` at `glow_intensity=0.4` — a relatively expensive post-effect for tile-based mobile GPUs | `assets/env/night_environment_mobile.tres:32,34` | Deferred to P4 — visual/perf tradeoff needs eyes-on judgment, not a blind toggle |
| P1 | Rain VFX ships fixed at 300 particles with no quality-tier scaling | `scenes/vfx/vfx_rain.tscn:31`, `scripts/systems/quality_manager.gd` (no particle scaling found) | Deferred — moderate effort, lower priority than security/accessibility this pass |
| P2 | Mobile renderer/shadow/MSAA/LOD defaults already sensible (`gl_compatibility`, 1024 shadow, msaa=2, FSR scale 0.8) | `project.godot:304-313` | Positive finding, no action needed |
| P2 | `etc2_astc`+`bptc`+`s3tc` all shipped together, bloats APK download size | `export_presets.cfg:38,76-77` | Deferred — install-size friction, not a runtime risk |
| P2 | Android min/target SDK fields not directly confirmed in `export_presets.cfg` | needs owner check | Deferred — quick owner double-check, not a code fix |

## Accessibility persona

| Sev | Finding | Evidence | Disposition |
|---|---|---|---|
| P0 | Player's flashlight "strobe" ability (`trigger_strobe`/`_strobe_flash`, ~10Hz light-energy cycling) is entirely outside `reduce_flash`'s reach — a photosensitive player enabling Reduce Flash would reasonably expect this covered and it isn't | `scripts/player/player_3d.gd:851-885` | **FIXED this pass** (P3), see below |
| P1 | Ambient streetlight flicker (~6Hz dip) has no accessibility toggle at all — only a per-instance scene export, not player-facing | `scripts/world/streetlight_3d.gd:41-51` | **FIXED this pass** (P3), see below |
| P2 | HUD crosshair `enemy` vs `default` state distinguished by `modulate` color alone (brass-dim vs ember — both orange/brown, real red-green risk pair) | `scripts/ui/hud_3d.gd:356-361,369-371` | Deferred — a `colorblind` correction shader exists as an opt-in mitigation, but isn't default and doesn't add shape redundancy; a real fix needs a UI pass, out of scope for a quick sweep |
| P2 | Minimap district-stage dots color-only, low cross-hue risk (same amber family) | `scripts/ui/minimap.gd:95-100` | Deferred — low severity |

**Confirmed already defended**: `reduce_screen_shake`, `reduce_time_fx`, `reduce_ui_motion`, `reduce_flash` on `WowDirector`'s one-shot story-beat flash, colorblind shader, high_contrast, arachnophobia, text_size — all 8 Accessibility tab toggles wired correctly for what they cover (verified via `tools/qa_sim/a11y_check.py` / `scripts/tools/_a11y_probe.gd`, not re-tested).

## Native-language reviewer persona (RU + JA spot-check + store listing)

| Sev | Finding | Evidence | Disposition |
|---|---|---|---|
| P1 | `ITEM_AUDIO_LOG` in `ru.json`: `"Аудиолог"` reads as "audiologist" (a doctor), not "audio recording" — a transliteration collision with an existing unrelated Russian word | `data/i18n/ru.json` key `ITEM_AUDIO_LOG` | **FIXED this pass** (P3), see below |

**Everything else sampled (~60 keys, 8 full lore entries, both new skill keys, RU+JA store listing sections) reads as genuinely well-localized** — no placeholder leakage, no case/particle errors, no machine-translation artifacts. Not manufacturing findings to hit a quota.

## Summary

20 findings, 0 duplicates of already-known issues. 3 fixed this pass (P3): the accessibility
P0 (player strobe) and P1 (streetlight flicker), the P1 loot-refarm exploit, and the P1
translation error. Everything else is recorded above with an explicit reason for deferral —
either genuinely low-value, needs a dedicated session (draw calls, texture compression),
needs eyes-on judgment (P4's job), or is architecturally latent rather than live.
