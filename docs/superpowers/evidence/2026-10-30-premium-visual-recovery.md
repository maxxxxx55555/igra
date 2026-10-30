# Premium Visual Recovery Evidence

Date: 2026-10-30
Branch: `qoder/premium-visual-recovery`
Candidate commit: `caef80bed1dd09d30274904f6bcea5acb32bb488`
Spec: `docs/superpowers/specs/2026-10-30-premium-visual-recovery-design.md`
Plan: `docs/superpowers/plans/2026-10-30-premium-visual-recovery.md`

## Status

BLOCKED — the desktop candidate is visually and functionally verified, but the physical Android device pass is unavailable and the produced AAB is unsigned/unverified. The polygon budget also remains above the legacy target; see Remaining blockers.

## Implemented

### World

- Modular facade rings for all eleven districts with recessed window framing, jambs, lintels, sills, drip ledges, floor bands, base courses, cornices, parapets, downpipes and PBR masonry sampling (`scripts/world/skyline.gd`, `assets/shaders/soviet_facade.gdshader`).
- Two-metre road and sidewalk modules, separate raised curbs, deterministic damaged-asphalt patches and darker walkway values (`scripts/world/street_builder.gd`).
- Slender procedural streetlight assembly, warmer textured metal, tighter spot cone and bounded additive halos (`scripts/world/streetlight_kit.gd`, `scripts/world/street_props.gd`, `scenes/props/streetlight_3d.tscn`).
- Curated district and sidewalk dressing: wrecks, pallets, pipes, cabinets, barriers, tyres, sacks and dead shrubs, seeded and batched, kept clear of interactions (`scripts/world/urban_set_dressing.gd`, `scripts/world/district_dressing.gd`).
- Selective restored-window density, brighter weathered facades, reduced cosmetic grain/vignette and reduced persistent ash (`scripts/world/skyline.gd`, `scripts/world_env_setup.gd`, `scenes/main_3d.tscn`).

### UI

- Live inventory rebuilt as equipment left, stable four-column item grid centre, inspector right, compact sort/filter toolbar and six-slot footer. Empty capacity slots are visible without fabricated items; real indices, actions and quick-slot bindings are preserved (`scripts/ui/inventory_ui.gd`, `scripts/ui/survivor_preview.gd`).
- Phone-width layout keeps equipment and grid on the primary view and opens the inspector as a secondary overlay (`scripts/ui/inventory_ui.gd`, `scripts/ui/ui_scale.gd`).
- Shared rectangular aged-brass theme, mobile-safe margins, 48 px minimum action height, responsive map, compact one-objective HUD, notification surfaces and centred workbench composition (`scripts/ui/theme_provider.gd`, `scripts/ui/hud_3d.gd`, `scripts/ui/quest_tracker_hud.gd`, `scripts/ui/city_map.gd`, `scripts/ui/workbench.gd`, `scripts/ui/main_menu_layout.gd`).
- Added touch guidance in all six live locales (`data/i18n/*.json`).

## Visual evidence

All frames are from the candidate revision unless marked as emulated.

- `docs/stills/premium/beauty_00_main_menu.png` through `beauty_07_power_station_lit.png`: main menu plus staged dark/restored district frames.
- `docs/stills/premium/<district>_01_dark_final3_caef80be_*.jpg`: DARK street view for all eleven districts.
- `docs/stills/premium/<district>_03_street_final3_caef80be_*.jpg`: restored street view for all eleven districts.
- `docs/stills/premium/<district>_04_block_final3_caef80be_*.jpg`: restored block view for all eleven districts.
- `docs/stills/premium/<district>_07_facade_final3_caef80be_*.jpg`: close oblique facade view for all eleven districts.
- `docs/stills/premium/<district>_09_lamp_final3_caef80be_*.jpg`: streetlight and local lighting view for all eleven districts.
- `docs/stills/premium/ui_1280/`: every live UIManager overlay and codex tab at 1280×720.
- `docs/stills/premium/ui_1920/`: every live UIManager overlay and codex tab at 1920×1080.
- `docs/stills/premium/ui_phone/`: every capture at 960×540 with the narrow inspector overlay enabled. This is a desktop emulation of the phone layout, not physical-device evidence.
- `docs/stills/store/`: refreshed main menu, restored street, dark street, combat, boss, victory, skill tree and shop evidence frames, all carrying the candidate hash and UTC time.
- `docs/stills/premium/ui_1280/ui_inventory_ui_caef80be_1280_*.png`: populated 12-slot inventory with real fuse, battery, medkit, cable and alcohol items.
- `docs/stills/premium/ui_phone/ui_inventory_ui_caef80be_phone_*.png`: narrow inventory and secondary inspector.

## Gates

| Gate | Command | Result |
|---|---|---|
| Visual contract | `premium_visual_check_scene.tscn` | `fails=0` |
| UI layout | `ui_layout_check_scene.tscn` | `fails=0` |
| Game flow | `python tools/flow_check.py` | 56/56 |
| Scene nodes | `python tools/scene_node_check.py` | clean |
| GDScript compile | `compile_gate_scene.tscn` | `bad=0` |
| Signal arity | `signal_arity_check_scene.tscn` | `fails=0` |
| Autoload API | `autoload_api_check_scene.tscn` | `fails=0` |
| Localization | `i18n_check_scene.tscn` | `fails=0` |
| Assets | `asset_check_scene.tscn` | `fails=0` |
| Save integrity | `save_integrity_check_scene.tscn` | `fails=0` |
| Boot flow | `boot_check_scene.tscn --windowed` | `fails=0` |
| Static suite | `bash tools/check.sh --static` | 69 pass, 2 fail |
| Store frames | `python tools/qa_sim/store_frames_check.py` | 10 frames, 0 faults |
| Frame provenance | `python tools/qa_sim/af3_frame_check.py` | 8 frames, 0 fail |
| Performance | `scenes/tools/perf_check_scene.tscn` | `fails=0` |

Static-suite exceptions are pre-existing evidence/administration findings outside this visual change: `branch_absorb_sim` has no row for the remote branch `origin/chore/wb-access-check`, and `proofs_audit_sim` reports 308 stale historical closure rows. Neither names a file changed on this branch.

## Performance

Windowed desktop run on the recorded AMD Radeon integrated GPU:

- Suburbs: 121 draw calls; power station: 118 draw calls.
- Median p95 frame time: 15.15 ms and 17.99 ms at the 33 ms gate.
- Video memory: 209.7 MiB; texture memory: 125.4 MiB; 94 emitting particles.
- Gate verdict: `[perf] DONE fails=0`.

Density runner measurements show 147k–217k rendered primitives per district and 181 draw calls in police and 229 in warehouses at the captured viewpoints. The latter is inside the D11 350-call budget but above D1 200; both districts exceed the legacy 50K polygon target. This is recorded, not hidden.

## Android candidate

- Artifact: `build/TLS-premium.aab` (91,903,320 bytes).
- SHA-256: `247347b8aa8fe18bf94863418730940eb275154e4ce44252999843ee372c7fe9`.
- Export reached `[ DONE ] export`; the editor process did not exit and was stopped after a 330-second guard.
- `python tools/qa_sim/aab_check.py build/TLS-premium.aab`: FAIL (3) — bundletool absent, jar not verified, no signer certificate.
- `jarsigner -verify`: `jar is unsigned`.
- No `adb` executable and no attached ARM64 device were available, so install, boot, logcat, touch, cutout, thermal, memory and 30-minute soak evidence are missing.

## Remaining blockers

1. Physical Android render/performance, touch, cutout, thermal and soak verification is BLOCKED by the missing device and `adb`.
2. READY is blocked by the unsigned, unverifiable AAB and missing bundletool/signing environment.
3. The legacy 50K-primitive-per-district budget is exceeded; the measured desktop frame gate still passes, but no phone measurement exists to justify accepting the difference.
4. Two pre-existing static evidence-administration checks remain red and are unrelated to the visual runtime.

The branch is pushed and ready for review; it is not marked release-ready.
