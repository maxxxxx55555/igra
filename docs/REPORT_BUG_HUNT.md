# REPORT_BUG_HUNT — asset pipeline QA (2026-08-25)

Scope: full `assets/**` audit (A1–A7), fixes within ownership only. Active-session
folders untouched: renders_v2/**, icons_v2/branches/**, icons_v2/craft/**,
onboard_v2/**, audio/ending_music/**, store/v2/devices/**, store/v2/coming_soon/**.
Context absorbed (not re-reported): all docs/REPORT_*.md, ERROR_LOG*.md,
ASSET_MANIFEST.md, KNOWN_ISSUES.md.

Totals: **found 96 | fixed 71 | deferred 12 | code-bugs routed 8** (details below).

## A1 CODE→DISK — 151 distinct `res://assets|audio` refs verified — **0 missing**

All preload/load paths in scripts/, scenes/, data/, components/, templates/ resolve
to files on disk. Dynamic `%s` contracts resolved in A6. Initial "127 missing"
was an audit-tool bug (extension stripped before existence test) — corrected; 1
residual hit (`icon_adaptive_fg.png\`) was a regex artifact; file exists.

## A2 DISK→CODE classification — 915 media files

| Class | Count | Items |
|---|---|---|
| WIRED (literal or dynamic-contract) | 318 + ~180 via %s contracts | see A6 |
| KNOWN-UNWIRED (report-documented) | ~500 | tiles dark set + walls (ASSET_MANIFEST), ui/ chrome set (StyleBoxFlat convention), maps/* (CONTENT_WAVE "procedural today"), loading/*_loading ×11 (consumer hint only), V2 additive sets (icons_v2, ui_v2, screens_v2 partial, overlays_v2, thumbs_v2, picto_v2, stages_v2, docs_v2, portraits_v2, maps_v2, cycle, skills_v2, jingles ×8, one_shots ×5, weather rain/wind loops), old music ogg layer set ×8 (ASSET_MANIFEST "nothing references them yet"), monster_/footsteps parallel SFX naming, store/** marketing |
| ORPHAN-UNKNOWN | 5 | music_combat.ogg (no consumer anywhere); textures/environment/{floor_concrete,wall_brick,wall_concrete}.png (siblings asphalt/brick/concrete/rusty_metal ARE wired via street_builder/street_props); ui/minimap_enemy_blip_16.png; sky/moon_glow_256.png |

ORPHAN rows are logged, NOT deleted (parallel-actor hazard; ASSET_MANIFEST rule:
delete only when proven dead AND not planned).

## A3 IMPORT SIDECARS

| Direction | Found | Action |
|---|---|---|
| Stale `.import` with missing source (inside assets/) | 9 (assets/audio/music/*.wav.import) | FIXED: removed (22939+ min old). Editor import errors prevented. |
| Stale `.uid` for missing shader | post_process.gdshader.uid | absent at write time (external actor already removed) |
| Media missing `.import` (editor-only fix) | 60 → BUGS_FOR_CLAUDE #2 | one_shots 5, docs_v2 6, picto_v2 13, stages_v4 4, renders_v2 1, store/v2 subfolders 31 |
| Orphan sidecars OUTSIDE assets/ | 17 (top-level audio/) → BUGS_FOR_CLAUDE #1 | not my scope |

## A4 AUDIO RE-AUDIT — 229 files

- Formats: sfx 44.1kHz mono = 100% clean. Music deviations (downtown/harbor/
  industrial/park/residential @22050, music_ambient* /tension/victory @32000,
  layer_*.ogg + old set stereo) = documented legacy-era/regenerated-by-parallel-
  session files; GDD §13 pins no channel/LUFS spec for music layers.
- Loudness vs canon (-14 sfx / -18 amb): every >3dB outlier matches the accepted
  ledger bit-for-bit (monitor_beep -22.6, radio_static -22.9, machinery_drone -22.0,
  vent_rattle -22.5, arc_crackle -23.8, window_rattle -21.6, breaker_clunk -21.0;
  reload floor trio -18.8/-18.2/-20.9). Zero NEW outliers. Post-repair
  industrial_dark.ogg re-measures I=-16.5 (within 1.5dB of -18).
- True peak: none hotter than -1.0 dBFS anywhere.
- Loops: naive head/tail seam proxy reproduced its documented false positives
  (envelope variance, e.g. park_dark proxy 66.9dB but sample-wrap jump ≈ noise).
  Honest boundary-jump detector (wrap sample-step vs internal p9999 transient
  distribution) found **8 real wrap-clicks → all FIXED**:

| File | wired? | wrap jump before → after (int16) | method |
|---|---|---|---|
| music/layer_dark.ogg | YES (MusicManager.LAYERS) | 15600 → 278 (body p9999=242) | cut-and-join −2.0s |
| music/layer_lit.ogg | YES | 2300 → 128 (body 438) | −1.5s |
| ambience/districts/industrial_dark.ogg | YES (DISTRICT_BEDS) | 2470 → 289 (body 283) | −2.0s (dur 36.0→34.0s) |
| ambience/threat_high_loop.ogg | no | 1545 → 39 (body 12115) | −2.0s |
| district_details/power_station_cooling_fan.ogg | no | 4640 → 18 | −1.1s |
| district_details/power_station_generator_thrum.ogg | no | 5330 → 291 | −1.3s |
| sfx/interact/generator_run_loop.ogg | no | 1690 → 245 | −1.0s |
| one_shots/heartbeat_low_loop.ogg | no | 2010 → 33 | −1.0s (one tile) |

Backups: `_BACKUPS/2026-08-25_bughunt/assets/audio/**` +
`assets/audio/_pre_norm/seam_fixes/**`. Duration deviations from documented
lengths (36s contract etc.) are a deliberate trade of the repair method — logged
in ERROR_LOG_BUGHUNT.md attempt history.

## A5 TEXTURE RE-AUDIT — 669 PNGs

- Dimensions per family: **0 violations** (icons 48/64/96/128, enemies/portraits
  512(/x768), tiles 256, surfaces 512, screens 1920×1080, sky 2048×1024, chrome kits).
- Required transparency: 0 violations.
- 9-slice gutters: 19 legacy ui/ chrome files had zero transparent margin
  ([0,0,0,0]) incl. the ERROR_LOG open-failure quartet → **FIXED**: btn_tex_quad
  regenerated opaque slice-safe-at-16px (wired contract theme_provider.gd:42);
  other 15 rebuilt with 10px gutter + inset-12 shapes (ui_v2 recipe);
  progress_frame (200×20 thin bar) uses class-correct 3px vertical inset.
- Palette flags triage:
  - FIXED: items/{icon_ammo,icon_battery,icon_health,icon_stamina} neon 273–888 px
    → muted-brass remap, 0 remaining; wrench/fabric/paper white px clamped ≤240;
    ui_v2/flashlight_render_512 (WIRED via screens.gd:465) 11028 pure-black px →
    lifted to floor 8, 0 remaining.
  - ACCEPTED/documented: art/shot_* (dev screenshots, listed in REPORT_ASSETS),
    screenshot_05 (stable-hash verified FINAL P3), ab_icon_B/C neon accents
    (marketing, alpha-aware QA passed at delivery), items_legacy/* (intentional),
    photos/dark_alley 1px.
- Crests (WIRED city_map.gd:133): open failures repaired — coverage 0.97–0.98 →
  0.44 (Ø72 disc on transparent field, cap 0.70); police-vs-suburbs glyph-region
  IoU 0.0076-distinctness fail → **0.1931**; worst pair overall school/hospital
  IoU 0.525 « 0.90 cap. All 11 redesigned series-consistent (panel disc, brass
  ring, bone+brass two-tone glyphs).

## A6 NAMING CONTRACTS — all resolve

mon_<name>_<cue> (11 monsters × cues vs disk 100%), step_<surface> MATERIALS dict,
crest_%s_96 ×11, ach_medal_v2_%s_96 ×20, monster_%s_64 ×6, stat_%s_64 ⊇ used ids,
portraits %s_full_512x768 ×6, tiles %s_floor/%s_wall(±_lit) ×11, weather_%s_256x144
×4, items/%s ×41/41 data/items ids, photos/%s fallback ×10/10. No renames needed.

## A7 GDD GAP SCAN

- Enemy roster §6.2 (11+boss): portrait union 12/12 ✓; cue sfx wired ✓.
- Achievements §21 (ach_01…20): medals v2 20/20 ✓ (legacy icons/ach_* ×12 =
  superseded unwired).
- Endings §12.4 (5): art ×5 ✓ stings ×5 ✓ warmth order verified at delivery ✓.
- Weather set: rain/wind loops + thunder near/far + 4 ui thumbs + 4 overlays ✓.
- Districts §4.1 (11): dark tiles 11/11 ✓; **lit variants were 3/11 → GAP-FILLED
  to 11/11** (16 new tiles, measured grade match gain=(1.300,1.161,0.862)
  offset=(13.6,15.4,19.4); all shifted warmer R−B, max channel ≤246).

## DEFERRED (never touched)

| Item | Reason |
|---|---|
| audio/ending_music/** (incl. real wrap-click on ending_dark_full.ogg, jump 0.236 vs body 0.0059) | folder appeared mid-session — parallel writer active (timestamp guard) |
| store/v2/devices/** + coming_soon/** missing .import (14) | active-session folders; covered by BUGS_FOR_CLAUDE #2 editor pass anyway |
| marketing palette flags (art/shot_*, ab_icon B/C accents, screenshot_05) | documented delivered/accepted artifacts outside runtime art |
| legacy music WAV formats (22050/32000 Hz) | documented era formats, wired and functioning |
| layer_*.ogg stereo/-14 LUFS | replaced by parallel session after delivery report; GDD has no music-layer loudness/channel canon |
| music_combat.ogg + 4 texture orphans | deletion needs owner decision (BUGS_FOR_CLAUDE #3) |
