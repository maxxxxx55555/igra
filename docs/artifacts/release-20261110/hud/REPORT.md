# HUD release evidence — 2026-11-10

The touch HUD now lays out all fourteen controls from their measured minimum sizes. The former absolute slots overlapped when the bundled font, translated captions, and theme padding made buttons wider. The measured extent also positions the one-handed cluster and ammo counter; safe-area offsets remain applied after resizing. No action handlers or theme resources were changed by this repair.

Native inspection then found two real presentation defects: changing to English left four side captions in Russian, and the bundled font lacked the sword, upward-arrow, and ring characters used by Attack, Jump, and Wheel. The existing language-change callback now refreshes six captions and all fourteen tooltips before reflow. Those three action pictograms now use existing bundled textures. System font fallback was not added.

## Recorded checks

| Evidence | Result |
| --- | --- |
| `geometry-red.out` | Four failing existing assertions: HUDP9, HUDP11, A11Y8, HUDP13. |
| `geometry-first-green.out` | The same four assertions pass after measured placement. This historical HUDP11 still covered eight controls. |
| `geometry-final.out` | Actual EN and RU verified; HUDP9, strengthened HUDP11 (all fourteen at 0.8/1.0/1.5), A11Y8, and HUDP13 pass after the final icon/localization repair. |
| `glyph-red.out` | HUDP15 fails with ten concrete findings: four stale English captions and three missing glyphs in each language. |
| `glyph-green.out` | HUDP15 checks fourteen controls in each supported language; 28 checked, zero findings. |
| `native.out`, `native-cases.json` | Sixteen real rendered cases, 224 control records, zero geometry, localization, or glyph failures; exit 0 in 36.4 seconds. |

The native matrix is EN/RU × High/Low × button size 0.8/1.5 × normal/one-handed. Each case records the requested and actual language, selected tier, every control's text, tooltip, icon, and drawn rectangle. Assertions cover viewport containment, minimum 48 logical UI units, pairwise control separation, joystick and ammo-counter separation, visible content, current captions, and bundled glyph coverage.

**Coverage correction:** only `en` and `ru` are supported by `LocalizationManager.SUPPORTED`. Earlier scratch requests for German, French, Spanish, and Portuguese could fall back to a supported language; they are not evidence of four additional supported languages. Neither this report nor the final matrix claims that coverage.

## Native setup and visual inspection

Godot 4.7.2 native Windows rendering used a fresh disposable APPDATA/LOCALAPPDATA profile, touch emulation, and an actual 1600 × 740 window. Canvas stretch produced a 2335 × 1080 logical viewport. High is tier 2; Low is tier 0. The fixture instantiates the real main scene, uses the project's QA focus guard, freezes simulation for stable captures, disables automatic quality switching and ads, and lets startup toasts expire. The HUD itself is rendered normally. These PNGs are direct viewport captures, without image edits.

Inspected `en_high_0.8_normal.png`, `en_low_1.5_normal.png`, `ru_high_0.8_onehand.png`, and `ru_low_1.5_onehand.png`: side captions follow the selected language; Attack, Jump, and Wheel have visible pictograms; rows and joystick stay separate; no missing-glyph boxes remain. `before-en-mixed-captions.png` and `before-ru-missing-glyphs.png` preserve the actual visual failures that triggered the final repair. The other twelve final captures are retained with their machine-checked records.

The 48-unit assertion concerns logical UI coordinates, not physical-device touch acceptance. Small-scale text is visibly small in this desktop phone-aspect window. Android hardware, physical touch ergonomics, and store screenshot acceptance are outside this focused evidence; this is not a whole-game release certification.

## Reproduction and source identity

`hud_touch_probe.gd`, `hud_glyph_probe.gd`, and `hud_native_frames.gd` are the retained fixtures. Run against an imported disposable project with fresh APPDATA and LOCALAPPDATA. For native capture, set `HUD_EVIDENCE_DIR` to a writable absolute output directory and use `--windowed --script <absolute-path>/hud_native_frames.gd --quit-after 1800`. The headless probes use `--headless --script <absolute-script-path> --quit-after 1200`.

`source-manifest.json` records the working-tree base commit, dirty state, and SHA-256 of the relevant source and runtime files. Each listed source dependency matched its QA copy at capture. The recorded commit alone does not identify the uncommitted fixes. `SHA256SUMS.json` hashes the final evidence files, excluding itself. Runtime edits are limited to `scripts/ui/hud_3d.gd` and `scripts/ui/hud_touch_layout.gd`; regression edits are in `scripts/tools/rc16/hud_checks.gd`. This HUD source was frozen after the final captures.
