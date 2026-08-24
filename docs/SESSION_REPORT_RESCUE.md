# Session report — RESCUE WAVE (real-launch rescue + visual pass)

Every claim below has an artifact: a gate exit code, a commit hash, a
screenshot path, or a log excerpt quoted inline. Commits this session
(all pushed to `origin/main`): `d8637ab`, `c7bc574`, `7f9cf96`,
`80b6c5a`, `b6f9ab1`, `8b7d725`, `f368631`. Investigation trail:
`docs/PLANS.md` (RESCUE WAVE entries). Canon reference: `docs/
PRODUCTION_BIBLE.md` (updated this session with real measurements).

## The headline finding

The premise of this wave was "headless boot_check is green but the real
window doesn't work." **The real window does launch and render
correctly** — `docs/shots/rescue_boot.png` is a clean, correctly-lit
main menu from a genuine `--windowed` process, not headless. What
actually blocked the player was one specific, reproducible bug found by
getting a real click through to "Play": **`scenes/main_3d.tscn` has a
permanently-embedded `EndingScreen` node whose script built and faded in
a full-screen "All districts powered!" win overlay in `_ready()`,
unconditionally, on every single load of the gameplay scene** — nothing
ever called its actual trigger method. A brand new game was immediately
covered by a fake victory screen. Fixed in commit `d8637ab`.

## Status table

| Task | Status | Artifacts |
|---|---|---|
| P0.1 Real windowed launch, capture logs | DONE | `docs/runtime_log.txt` / `runtime_log2.txt` — clean, zero errors either run (see "Runtime log diff" below) |
| P0.2 Find + fix the real blocker | DONE | commit `d8637ab`; root cause: `scripts/ui/ending_screen.gd` auto-building on `_ready()`; fixed by making it dormant until its real (currently unused) trigger is called |
| P0.3 Manual scenario: menu -> New Game -> gameplay -> save -> load | DONE | `boot_check_scene.tscn` re-run headless (state-based, not pixel-based): `[boot] DONE fails=0`; real-window screenshot proof below |
| P0.4 ads-before-input / integrity_guard debounce / streetlight instantiation | DONE (re-verified) | boot gate log: `phase2b no ad before input — OK`; `street_props.gd` still instantiates `streetlight_3d.tscn` with `district_id` set (grepped, unchanged since TRUTH WAVE) |
| P0.5 Gates + commit + real (non-headless) screenshots | DONE | commits `d8637ab`, `7f9cf96`; screenshots below; all mandatory gates + boot gate green |
| P1 Footstep mapper (18 ox alpha files) | DONE | commit `c7bc574`; new gate `[footstep-check] DONE fails=0`, 12/12 surface/speed combos resolve to real files |
| P2.1 Night sky panorama -> WorldEnvironment | DONE | commit `80b6c5a`; `docs/shots/rescue_p2_sky2.png` — real street geometry now visible (previously flat black, nothing rendered) |
| P2.2 District ambience beds -> MusicManager | DONE | commit `b6f9ab1`; asset-check gate `fails=0` after updating 2 stale assertions to the new per-district files |
| P2.3 Status FX sprites -> StatusEffects HUD | NOT ATTEMPTED | scope cut, see below |
| P2.4 VFX sprites -> hit/death particles | NOT ATTEMPTED | scope cut, see below |
| P2.5 Boss stings (WAV>1MB -> OGG, wire to encounters) | DONE | commit `f368631`; `architect_sting.wav` 1.3MB / `tvar_sting.wav` 1.0MB -> `.ogg` 78KB/69KB, wired to Architect first-contact and Tvar first-detection |
| P2.6 UI chrome kit (StyleBoxTexture) | BLOCKED | explicitly gated on "when OpenCode B finishes chrome kit" in the original ask — nothing to integrate yet |
| P2.7 Map/minimap district crests | BLOCKED | no crest assets exist in the repo (`find assets -iname "*crest*"` — zero results); original ask was conditional ("if ready") |
| P2.8 LOW-tier perf fallbacks | PARTIAL | sky falls back to flat color on tier 0 (part of the P2.1 commit); grain/cones/particles-50% not touched this session |
| P3 Performance guard (draw calls) | DONE (measured, not fixed) | commit `8b7d725`; new `scenes/tools/perf_check_scene.tscn` measured **370 draw calls** in the suburbs spawn district — over both the D1 (<200) and D11 (<350) budgets; root cause identified (`streetlight_3d.tscn` has no MultiMesh batching) and documented in `docs/KNOWN_ISSUES.md`, not fixed — real regression risk to the TRUTH WAVE streetlight-reactivity fix if rushed |
| P4 Final report | DONE | this file |

## Runtime log diff (before/after real-window launch)

`docs/runtime_log.txt` (before the fix, from the run that reproduced the
win-overlay bug) and `docs/runtime_log2.txt` (after the fix) are
**byte-identical** — both just the engine version banner, zero errors,
zero warnings. This is worth stating plainly: **the P0 bug was never
visible in stderr/stdout at all.** It was a silent scene-composition
bug, only detectable by actually looking at a screenshot after a real
click reached "Play" — which is exactly why it survived the previous
TRUTH WAVE session's headless-only verification. The lesson carried
into this session's tooling: `scripts/tools/_gameplay_shot.gd` /
`_perf_check.gd` now exist specifically to get a real rendered frame out
of a real windowed run without depending on flaky GUI-click automation.

## Screenshots (before/after)

- **Menu**: `docs/shots/rescue_boot.png` — real windowed boot, clean
  menu, no regression from any previous session's work.
- **Gameplay, before fix**: `docs/shots/rescue_after_postmessage.png` —
  New Game immediately shows "All districts powered!" instead of the
  game world. This is the bug.
- **Gameplay, after fix**: `docs/shots/rescue_gameplay_after_p0_fix.png`
  — real HUD (health/stamina/battery, ШУМ/ЗАМЕТ, radar, ammo), no
  overlay, but the spawn view itself was almost entirely black — fed
  directly into P2.1.
- **Gameplay, after P2.1 (sky)**: `docs/shots/rescue_p2_sky2.png` — same
  spawn point, now shows real street geometry (trees, streetlight pole,
  sidewalk, road markings) that was invisible before.

## GUI-automation note (read before trusting any future "clicked X and
## saw Y" claim from a similar sandbox)

Significant time this session went into trying to drive the real Godot
window via simulated mouse input (`SetCursorPos`/`mouse_event`/
`SendInput`/`PostMessage` through Win32 APIs from PowerShell). A click
landed successfully **exactly once**, out of roughly ten attempts with
various coordinate/timing corrections — and that one success is what
originally reproduced the P0 bug. Every other attempt, including several
with confirmed-correct client-area coordinates and a confirmed-real
cursor position, silently did nothing. This was not chased further as a
game bug — it reads as a property of this specific sandboxed desktop
session (no confirmed root cause found; cursor position readback was
itself unreliable at times). **Practical consequence**: this session's
gameplay verification after the first bug repro relies on `scripts/
tools/_gameplay_shot.gd` and `_perf_check_runner.gd`, which drive the
game through its own `Routes`/`GameManager` API calls (the same approach
`boot_check_scene.tscn` already used successfully), not simulated
clicks. Future sessions in this environment should default to that
approach rather than re-attempting GUI automation.

## DEFAULT_CHOICE (no-opinion protocol)

1. **`moon_glow_256.png` not wired as a permanent sky fixture.**
   `docs/ASSET_HANDOFF.md`'s own delivery note says "design says no
   permanent moon" — it's for a future moon *event*. Wiring it always-on
   would invent a visual the design doc explicitly disclaims.
2. **LOW graphics tier keeps the flat-color sky fallback** (tier 0 only)
   rather than showing the panorama at reduced quality — matches the
   original P2 ask's own wording ("LOW tier: ... sky fallback to solid
   color") literally.
3. **8 of 11 districts keep their `_dark` ambience bed even once
   restored to FULL power.** Only suburbs/hospital/power_station got a
   `_lit.ogg` from the asset delivery; not inventing `_lit` variants for
   the other 8.
4. **Perf-guard tool is diagnostic-only, not a hard gate.** No
   per-district draw-call budget is wired anywhere to know which of the
   GDD's two numbers (<200 D1 / <350 D11) applies at a given spawn
   point, so a hard pass/fail would be arbitrary. It prints and reports;
   `docs/PRODUCTION_BIBLE.md`'s checklist already scoped this item as
   "not yet an automated gate" before this session started.
5. **Draw-call over-budget (370 measured) not fixed.** Root cause
   (`streetlight_3d.tscn` lacking MultiMesh batching) is identified and
   documented, not patched — a MultiMesh conversion has to preserve each
   pole's individual reactivity to `district_stage_changed`, the exact
   mechanic the TRUTH WAVE session fixed after finding it broken.
   Rushing a batching refactor in the same session as everything else
   above risked silently breaking that fix again.

## HUMAN_CHECKLIST (delta this session)

- **Ponytail/CC0 reference repo still not found.** Same result as the
  TRUTH WAVE pass: `..\refs\` and `.claude/skills/` have no matching
  asset-pack repo. If one should be added, paste the exact URL.
- **P2.6 (UI chrome kit) needs OpenCode B's delivery** before it can be
  integrated — nothing to do on this side until that lands.
- **P2.7 (map/minimap district crests) needs the actual crest assets**
  — none exist in the repo yet.
- **Draw-call budget (370 vs <200/<350) needs a dedicated session** for
  the MultiMesh streetlight conversion — flagged as a real, scoped task
  in `docs/KNOWN_ISSUES.md`, not a quick fix.
- Everything already open in `docs/store/HUMAN_CHECKLIST.md` from prior
  sessions (AppLovin real-device testing, Play Console account, release
  keystore, privacy policy hosting, Steam desktop export preset, PEGI-16
  sanity check) is unchanged and still open.

## Self-audit — 3 loudest claims, checked just now

1. **"Real windowed launch works and the player can now get into the
   game."** Verified twice more since the fix: a fresh `--windowed`
   process → menu renders clean → `Routes.start_game()` (driven via the
   `_gameplay_shot_runner.gd` tool, not a simulated click, for
   reliability) → real gameplay HUD visible, no win-overlay, in both
   `docs/shots/rescue_gameplay_after_p0_fix.png` and `rescue_p2_sky2.png`
   (captured after later commits, proving the fix wasn't undone by
   subsequent P2 work). True as stated.
2. **"The night sky is wired in."** True at the code level
   (`background_mode` is `BG_SKY` with a real `PanoramaSkyMaterial`,
   confirmed via `git show` of the committed `.tscn`) and true visually
   in the sense that the previously-flat-black scene now shows a
   textured, gradient sky region — but individual stars are barely
   visible in the captured screenshot at DARK-stage exposure/fog levels.
   Downgraded from "you can see a starry sky" to "the sky is real
   geometry/texture now, not a solid color, though it reads very
   subtly under the game's intentional darkness" — checked against the
   actual screenshot just now, not assumed.
3. **"Performance guard is done."** Overclaim if read as "perf is fixed"
   — corrected here: the *tool* is done and gives a real, trustworthy
   number (370 draw calls, measured this session, not estimated), but
   the number itself is over budget and **nothing was changed to bring
   it down**. Table above marks this "DONE (measured, not fixed)", not
   "DONE" — this line is the explicit correction.

## What's not done, stated plainly

P2.3 (status FX sprites → StatusEffects HUD) and P2.4 (VFX sprites →
hit/death particles) were not attempted this session. P2.6 and P2.7 are
blocked on inputs from outside this session (chrome kit delivery, crest
assets) rather than being incomplete work. The draw-call budget is
measured and root-caused but not fixed — deliberately, given the size of
this session and the regression risk of rushing a rendering-batching
change to a mechanic (streetlight reactivity) that was itself a hard-won
fix from the previous session. Next session should start from `docs/
PRODUCTION_BIBLE.md`, check whether OpenCode B's chrome kit has landed,
and treat the MultiMesh streetlight conversion as its own focused task
rather than folding it into a larger wave.
