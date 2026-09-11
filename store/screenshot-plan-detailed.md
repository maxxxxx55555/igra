# Play Console screenshots — detailed capture plan (8 shots, one <60 min session)

Owner: executes in a real build. Every fact below is statically verified against the repo
(Gold Master v2). Companion docs: `store/screenshots-plan.md` (selling-point table, same
shot numbering), `docs/STYLE_GUIDE.md` (palette), `docs/TRAILER_STORYBOARD.md` (wow beats).

Play Console constraints used throughout: 16:9, **min 1080p** → capture **1920×1080**
native; JPEG or 24-bit PNG, ≤ 8 MB each; keep key action in the central band (Play crops);
no overlay text/arrows. Min 2 shots required, max 8 per type — we deliver exactly 8 EN (+2 RU).

## 0. Verified controls, systems, and honest limits

**Boot chain:** `boot_loading.tscn` → main menu (≈3.3 s boot counter) → *Continue/New Game*
→ game scene `res://scenes/main_3d.tscn`. Start district: **suburbs**
(`DistrictManager.current_district` default).

**Window/quality:** viewport default = **1920×1080** (`project.godot` display/window/size).
Settings → set *Shadow Quality*, *Texture Quality*, *Effects Quality* dropdowns to **High**
(tiers are 0=Low…3=Ultra; High = tier 2). On Android hold **landscape**.

**Keys (verified bindings):** WASD move · Shift run · **E** interact · **F** flashlight ·
**K** city map (`city_map_toggle`) · **P** photo mode · Esc pause · Tab inventory.

**HUD off — two verified ways, use #1:**
1. **Trailer Mode** — Settings → "Trailer Mode" toggle (`trailer_mode`, off by default).
   Turning it ON immediately hides the HUD (emits `hud_visibility_changed(false)`), and at
   the three wow moments adds a slow-mo + FOV punch. Leave ON for the whole session.
2. Photo Mode (**P**) also hides the HUD and adds corner-frame overlay + filter cycle
   (**TAB**: none/noir/faded/vivid/bright/moody/bloom — keep **"none"**).
   **Honest limit:** photo mode's **Enter** key only shows a `PHOTO_SAVED` toast + counter —
   it writes **no PNG** (static audit of `scripts/ui/photo_mode.gd`). The
   `user://screenshots/` saver in `scripts/systems/photo_mode.gd` is not wired to a key.

**Capture method (primary):** OS-level, since no in-game save binding exists:
Windows — **Win+Alt+PrtScr** (Xbox Game Bar → `Videos\Captures`, PNG at window res) or
**Win+PrtScr**; Android — hardware combo (power + vol-down); then verify every file reads
1920×1080 before upload.

**Capture method (scripted fallback — ShotTool autoload):** from the project dir:
`godot --path . --shot=<out>.png --shot-delay=<s>` (one shot) or
`--shot-series=2,6,12,20,30` (timed series in one run), with optional
`--shot-scenario=street|lit|inventory|combat` (`lit` forces the CURRENT district to
`Stage.FULL` via `DistrictManager.set_stage`; fresh run's current district = suburbs only).
Budget ≈8 s for splash+boot and another ≈6 s after `start_game` before the world streams.
ShotTool self-disables ads and clears popups.

**Camera presets — verified none.** Trailer mode offers **no camera angle/position preset**
(`wow_director.gd`: "Camera *position* paths are deliberately not done here"). Its three
*effect* presets are: `first_light` (0.5 s flash, peak alpha 0.20, shake 0.30, no slow-mo),
`cascade` (0.8 s flash, 0.5× slow-mo ≈0.45 s, FOV −4), `ending` (1.0 s flash, 0.4× slow-mo,
FOV −3). **All framing below is by player position** — stand where told, face where told.

**Wow timing (the "exact moment" math):** first-light flash peaks at ≈0.125 s and is fully
gone by **0.5 s**; capture at **1.0–1.5 s** after the streetlight ignites = "flash settled,
lamp burning, shake decayed". The HUD stays hidden while Trailer Mode is ON, so no race.

**District stages:** `DARK=0 · PARTIAL=1 · STREETS=2 · FULL=3` (`DistrictData.Stage`).
Advancing = interact (E) with the district's power switch once per stage; each flip costs an
item — **cable** (→PARTIAL), **fuse** (→STREETS), **transistor** (→FULL) — and requires the
prerequisite district at FULL (`PowerGrid.is_unlocked`). Suburbs' FTUE generator takes
suburbs straight to STREETS.

**Travel:** City Map (**K**) = 11 rows in canon order (suburbs … power_station), stage dot +
hex + localized stage label, and a **Travel** button per row, enabled only when that district
is unlocked (its prerequisite is FULL) and you're not standing in it. Locked rows show
"MAP_LOCKED_BY".

**Hygiene:** interstitial ads can trigger on district entry in real builds — if anything
pops up or pauses, dismiss and unpause (Esc) **before** framing. Never capture the death
screen or a mid-attack pose (store rule).

## 1. One-time prep (do once, NOT inside the 60 minutes)

The 60-minute session is only possible with two saves ready (save slots exist in-game):

- **SAVE-B "city lit"** — endgame save, **all 11 districts FULL**. Reuse your own
  playthrough save if it exists. If you must build it by playing: capture the four
  dark/mid-state shots **en route** (their states occur exactly once in a natural campaign —
  recipes in §3, marked ⏳en-route): shot **2** the moment residential hits FULL (park still
  DARK — this state can never be re-created from an all-FULL save), shot **3** while
  residential is still DARK, shot **4** on first arrival in park, shot **6** on first arrival
  in industrial. Keep those four files; the 60-minute session then delivers only 1/5/7/8(+RU).
- **SAVE-A "early dark"** — fresh game, suburbs at STREETS (finish the FTUE generator,
  ≈10 min). Needed only if prep didn't yield the dark shots, and only shot 3 is reachable on
  foot from it (residential via suburbs' `z_exit_north`); park/industrial travel rows stay
  locked, so prefer the en-route capture for 4 and 6.

If SAVE-B exists and no en-route captures were made, a same-day fallback for shots 2/3/4/6 is
documented per-shot below, but it costs campaign time — the en-route rule is the fast path.

## 2. The 60-minute session (clock)

| t (min) | Step |
|---|---|
| 0–5 | Launch → Continue **SAVE-B** → Settings: High/High/High, Language **English**, **Trailer Mode ON** (HUD vanishes). Verify frame is clean. Dismiss any ad popup. |
| 5–12 | **Shot 1** (suburbs). Then K → row *gas_station* → Travel. |
| 12–19 | **Shot 5** (gas_station). Then K → Travel to *power_station*. |
| 19–26 | **Shot 7** (power_station). |
| 26–30 | **Shot 8 EN** — stand anywhere safe, press **K**, capture the City Map. |
| 30–36 | Settings → Language **Русский**. Re-open K → **Shot 8 RU**. Optional: back to suburbs for **Shot 1 RU** (`#1-ru`). Language back to English. |
| 36–37 | Save game. Exit to menu → Continue **SAVE-A** (or your en-route file set). |
| 37–44 | **Shot 3** (residential courtyard, flashlight on). |
| 44–51 | **Shot 4** (park keeper shed) — en-route file from prep, else see per-shot fallback. |
| 51–58 | **Shot 6** (industrial workshop b) — en-route file from prep, else see per-shot fallback. |
| 58–60 | QA pass against §4 checklist; rename files per §5. |

If shots 2/3/4/6 were captured during prep (recommended), the 60-minute session covers
steps 0–36 only (~35 min, slack for retakes) and shot 2's file simply joins the set.

## 3. Per-shot recipes

Zone ids are real anchors from `content/districts/*/prop_manifest.md`. "Face" = point the
camera; there are no camera presets (see §0).

### Shot 1 — the hook: light vs. the dark ⭐ money shot
- **Scene to open:** main menu → Continue **SAVE-B** → loads `res://scenes/main_3d.tscn`,
  district **suburbs**.
- **District + stage:** suburbs **FULL**.
- **Reach:** walk to the **north exit** (`z_exit_north`), then turn around to face back down
  **Maple Row** (`z_maple_row`, the W→E main street).
- **UI state:** Trailer Mode ON → HUD hidden; map **closed**; inventory/dialogs **closed**;
  flashlight **off**.
- **Framing:** wide reverse down the street axis: warm streetlight cones recede toward
  camera; behind camera (out of frame) the exit road is pitch black. Player model out of
  frame or far-side; no enemies.
- **Exact moment:** any steady frame ≥3 s after arriving (no wow fires on SAVE-B — all
  lights already burn; that's correct for this shot).
- **Camera/preset:** none available — eye-level player camera, look slightly downward
  (~10–15°) so 3–4 light cones fit; center the nearest cone in the lower third.
- **Resolution/aspect:** 1920×1080 (16:9). **Language:** EN (+ optional RU variant `#1-ru`
  for the RU listing — same frame, Русский in Settings).
- **File:** `shot01_light_vs_dark_1920x1080_en.png` (+ `_ru.png`).

### Shot 2 — one city: a district boundary ⏳en-route (prep)
- **Scene:** `res://scenes/main_3d.tscn`, district **residential**.
- **District + stage:** residential **FULL**, park still **DARK** (natural mid-campaign
  state — capture it the minute residential's last switch flips).
- **Reach:** `z_exit_east` (barricade toward park).
- **UI state:** Trailer Mode ON; all panels closed; flashlight off.
- **Framing/moment:** stand at the barricade facing the park: lit residential block behind
  you, black trees/pond ahead, one brass lamp marking the edge. Steady frame, 2–3 s after
  stopping. Eye-level, looking level.
- **Resolution/aspect:** 1920×1080. **Language:** EN.
- **File:** `shot02_district_boundary_1920x1080_en.png`.
- **Fallback if prep missed it:** none within 60 min (state is unreachable from an all-FULL
  save — no player-facing down-stage exists; verified). Rebuild a mid-game save and capture
  en route, or substitute the nearest lit-streetlight edge frame with the same composition.

### Shot 3 — stealth horror ⏳en-route (prep) / SAVE-A
- **Scene:** `res://scenes/main_3d.tscn`, district **residential** — on SAVE-A walk north
  through suburbs' `z_exit_north`; en-route it is residential's state on first arrival.
- **District + stage:** residential **DARK or PARTIAL**.
- **Reach:** `z_courtyard_play` (playground with the yard swing, sandbox + chalk decal,
  T cell).
- **UI state:** Trailer Mode ON hides the HUD; flashlight **ON (F)** — its pool IS the
  subject. Everything else closed.
- **Framing:** player lower-right corner of frame; flashlight pool throws the chalk-sun
  bright; a tall shadow just outside the light at the far edge. Tension, not action — do not
  capture mid-attack.
- **Exact moment:** 1–2 s after the monster's silhouette resolves at the light edge (hold
  still; shoot before it charges). If none patrols near, 60 s of quiet at the swing with
  beam on the chalk decal is still on-brief.
- **Resolution/aspect:** 1920×1080. **Language:** EN.
- **File:** `shot03_stealth_horror_1920x1080_en.png`.

### Shot 4 — the voice / keeper lore ⏳en-route (prep)
- **Scene:** `res://scenes/main_3d.tscn`, district **park** (first arrival in the campaign).
- **District + stage:** park **DARK** (any stage onward is acceptable; DARK reads best).
- **Reach:** `z_keeper_shed` (Keeper's workshop, K cell). **Verified locked:** the door is
  keyed to `park_fix_key_01` (its pad is wired to the district PowerSwitch) — either loot the
  key first, or frame **through the doorway/window** at the work bench from outside.
- **UI state:** Trailer Mode ON; panels closed; flashlight off (the brass work lamp is the
  single warm source).
- **Framing/moment:** tight on the work bench: one brass work lamp, the shortwave radio,
  scattered papers. No enemies. Steady frame after 2–3 s; slight crouch-height look-down.
- **Resolution/aspect:** 1920×1080. **Language:** EN.
- **File:** `shot04_keeper_lore_1920x1080_en.png`.
- **Fallback:** the Keeper's context reads equally at the shed door with the lamp inside;
  never substitute another district.

### Shot 5 — restored world, nobody home
- **Scene:** `res://scenes/main_3d.tscn`, district **gas_station** — from SAVE-B suburbs:
  **K** → *gas_station* row → **Travel** (unlocked on SAVE-B).
- **District + stage:** gas_station **FULL**.
- **Reach:** `z_pump_island` / `z_forecourt` (the two pump rows under the canopy).
- **UI state:** Trailer Mode ON; panels closed; flashlight off.
- **Framing:** canopy sodium pools on the empty wet forecourt, dead pump displays, thin fog;
  queue road dark beyond. Composition: one pump island dead-center, canopy lights reflecting.
- **Exact moment:** steady frame 3 s after travel-in (after the world streams; dismiss any
  entry interstitial first). No wow moment fires — correct.
- **Camera:** none available — eye-level, looking level down the pump row axis.
- **Resolution/aspect:** 1920×1080. **Language:** EN.
- **File:** `shot05_restored_forecourt_1920x1080_en.png`.

### Shot 6 — the mystery inside ⏳en-route (prep)
- **Scene:** `res://scenes/main_3d.tscn`, district **industrial** (first arrival in the
  campaign).
- **District + stage:** industrial **DARK** (any stage onward acceptable).
- **Reach:** `z_workshop_b` — the workbench by the sorting line.
- **UI state:** Trailer Mode ON; panels closed; flashlight off.
- **Framing/moment:** a single overhead lamp burning full and warm over an empty bench; dark
  plant around it. Unsettling and silent — no operator, no enemies in frame. Steady 2–3 s;
  frame the bench dead-center lower third.
- **Resolution/aspect:** 1920×1080. **Language:** EN.
- **File:** `shot06_mystery_inside_1920x1080_en.png`.
- **Fallback:** if prep missed it and no mid-save exists, substitute the same composition at
  any unpowered district's single-overhead prop (keep "one warm lamp in a dark interior")
  and flag it at upload — do not fake the zone.

### Shot 7 — the ending: the last streetlight ⭐ money shot
- **Scene:** `res://scenes/main_3d.tscn`, district **power_station** — SAVE-B: **K** →
  *power_station* row → **Travel**.
- **District + stage:** power_station **FULL** (final district).
- **Reach:** `z_cooling_towers` gantry, then angle down toward `z_station_gate` (the gate
  lamp, hand truck and bowl of food from note 08 live at `z_station_gate`, D cell; the
  photo vantage with the poplar row is documented in the power_station manifest).
- **UI state:** Trailer Mode ON; panels closed; flashlight off.
- **Framing:** wide from the gantry: towers lit from below, the gate lamp burning at the
  foot. Hopeful close. No enemies in frame.
- **Exact moment:** steady frame 3 s after arriving. (On a fresh final-FULL flip this is the
  `cascade` wow: flash 0.8 s, slow-mo 0.5× ≈0.45 s, FOV −4 — capture **after** FOV returns,
  ≈1.5–2 s post-flip, if you happen to stage it live.)
- **Resolution/aspect:** 1920×1080. **Language:** EN.
- **File:** `shot07_last_streetlight_1920x1080_en.png`.

### Shot 8 — scope & localization (city map)
- **Scene:** `res://scenes/main_3d.tscn` + **City Map overlay** (`scripts/ui/city_map.gd`,
  opened with **K**) — from SAVE-B, any safe spot.
- **District + stage:** all 11 districts **FULL** reads strongest (all hexes green, every
  stage label "MAP_STAGE_3"); a deliberately one-dark variant (power_station DARK) also
  works to imply the goal. Pick ONE state and use it for both languages.
- **UI state:** City Map **open** (this shot *is* UI); everything else closed. Trailer Mode
  stays ON (it does not hide full-screen UI screens like the map).
- **Framing/moment:** the whole 11-row column visible, canon order suburbs → power_station
  legible; steady 1–2 s after open (allow refresh on `district_stage_changed`).
- **Resolution/aspect:** 1920×1080. **Language:** **EN first**, then Settings → **Русский**
  and re-capture the identical frame — the RU listing ships its own-language shot.
- **File:** `shot08_city_map_1920x1080_en.png` + `shot08_city_map_1920x1080_ru.png`.
- **Optional companion crop:** Settings → Language list (13 locales visible: ru, en, es, de,
  fr, it, pt_BR, tr, ja, ko, zh, zh_TW, ar) — `shot09_language_list_1920x1080_en.png`,
  only if time remains; not one of the 8.

## 4. Post-capture QA checklist (2 min)

- Every file is **1920×1080**, 16:9, JPEG or 24-bit PNG, ≤ 8 MB.
- HUD gone on shots 1–7 (Trailer Mode), map legible on shot 8; no death screen, no
  mid-attack, no popup/ads, no player-model clutter (shot 3 excepted: player + flashlight
  are the subject).
- Palette: permanent night, ONE warm light reads instantly in every shot (STYLE_GUIDE §2);
  no pure-white clipped glow.
- Shot 1 is the strongest frame you have — re-shoot it before any other retake.
- No text/arrows drawn over images (Play applies its own UI).

## 5. Upload mapping

- **EN phone set (16:9, 1080p):** shots 1–8 EN files, in order 1,2,3,4,5,6,7,8.
- **RU phone set:** `shot08_city_map_1920x1080_ru.png` + `shot01_light_vs_dark_1920x1080_ru.png`
  (if captured); other locales fall back to store listing translations (`store/listing.md`,
  `tools/gen_store_listing_locales.py`).
- **7″/10″ tablet sets:** reuse the same 16:9 frames (Play accepts them); if a distinct
  tablet crop is wanted later, crop from these PNGs — never upscale.
- Feature graphic + icons already exist in `store/` (feature-graphic.png, icon-512.png,
  icon-adaptive) — out of this plan's scope.

## 6. Scripted fallback matrix (if the live session slips)

Per §0 ShotTool: useful only for what it can stage — suburbs-FULL vistas (`lit` scenario) and
generic street/combat/inventory frames at spawn; it cannot stage non-current districts or
walk to zone anchors. Example: `godot --path . --shot=shot01_lit.png --shot-scenario=lit
--shot-delay=20`. Treat its output as **backup** for shot 1 only; shots 2–8 require the live
session above. (No Godot was run to produce this plan — all facts static.)

## 7. PHONE — touch-HUD recipes (GOLD MASTER v4 mobile-art pass)

Three shots that put the **real touch HUD on screen** (the EN/RU set in §1-3 deliberately
hides it via Trailer Mode — these are the counter-set that proves the game is playable by
thumb, for the store's phone-specific gallery slot). Same district-stage prerequisites as
§1-3; capture on an actual touchscreen device or the editor's mobile remote-debug view (not
possible headless — this plan is static-verified, capture itself is OWNER work like the rest
of this file).

**Shared rules for all three:**
- **Trailer Mode OFF** (the opposite of §1-3 — the touch HUD must be visible: joystick,
  BottomRight action cluster, HP/stamina/battery bars).
- **Aspect:** most phones are taller than 16:9 (e.g. 20:9). **Pad, never crop**, to the
  1920×1080 canvas Play expects: center the live 20:9 capture and letterbox the remainder in
  `#0c1016` (STYLE_GUIDE bg-deep) — never stretch, never crop content off the sides.
  Recompress at 24-bit PNG or JPEG, ≤ 8 MB, same as §4's checklist.
- **Language:** EN (RU optional companion, same pattern as shot08).

### P1 — first-light, touch HUD visible

- **Setup:** identical trigger moment to shot 1 (§3 "Shot 1 — the hook"): stand at the
  suburbs power switch 1.0-1.5 s after it flips to STREETS, Trailer Mode **OFF** this time.
- **Frame:** streetlights igniting behind the player, joystick (`BottomLeft`) and the
  BottomRight action cluster (attack/sprint/stealth/interact) both fully visible and legible.
- **File:** `shot_p1_touch_first_light_1920x1080_en.png`.

### P2 — crouch, stealth read

- **Setup:** any district with a visible hunter at mid-range, player crouched (stealth
  toggled via `BtnStealth` or the Crouch Input binding) in cover/shadow.
- **Frame:** crouched player silhouette low in frame, hunter visible but not adjacent (reads
  as "avoiding," not "caught"); touch HUD visible, `HUD_STEALTH` label legible.
- **File:** `shot_p2_touch_crouch_1920x1080_en.png`.

### P3 — one-tap fix (interact glyph read)

- **Setup:** player standing at a power switch or cable-box puzzle, **not yet interacted**,
  `BtnInteract` glowing (the new interact-availability pulse, `hud_3d.gd
  _pulse_interact_button`) — captured mid-pulse (brass tint, not white).
- **Frame:** the interactable object + the pulsing `BtnInteract` both in frame — sells "one
  tap fixes this" at a glance.
- **File:** `shot_p3_touch_interact_1920x1080_en.png`.

### QA (same as §4, plus)

- Touch HUD elements (joystick ring/knob, BottomRight cluster) fully inside the letterboxed
  frame, not clipped by the pad.
- Letterbox bars are flat `#0c1016`, no gradient/vignette bleeding into them.
