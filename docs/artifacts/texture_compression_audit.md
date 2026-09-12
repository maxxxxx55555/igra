# Texture compression audit (BLOCKER 2, FINAL HARDENING PASS, 2026-09-12)

Real, measured, headless-verified — not an estimate. Method: set
`compress/mode=2` (VRAM Compressed) + `compress/high_quality=true` on a
candidate `.import` file, `godot --headless --path . --import`, then
`tools/texture_psnr_check.gd` decodes the reimported texture and compares
it pixel-for-pixel against the original PNG loaded straight off disk
(bypassing the `.import` cache entirely — a true before/after).

## 1. Method note: `.import` files aren't normally committed here

`.gitignore` excludes `*.import` project-wide — a fresh `--import` on a
clean checkout regenerates it from engine defaults (Lossless for a plain
2D texture). That's fine for files nobody's tuned, but it means a
compression choice silently reverts to Lossless the next time anyone
reimports, unless the `.import` file itself is committed. Added a scoped
`.gitignore` exception for exactly the files below (see the comment
there) — nothing else under `assets/textures/` is exempted.

## 2. Candidates tested, and why the categorization changed from the prior pass

The 2026-09-12 `apk_size_report.md` (STEP 7, RELEASE CONVERGENCE) grouped
`items`, `items_legacy`, `renders_v2`, `portraits_v2`, `screens_v2`,
`stages_v2`, `docs_v2`, `fx`, `sky` under "3D/environment" by directory
name alone. Checked each category's actual content this pass before
touching anything: `items`/`items_legacy` are 128×128 inventory-slot
icons; `renders_v2` are UI equipment-screen renders; `portraits_v2` are
512×768 character/boss portraits shown in the Codex; `screens_v2`
includes a full 1920×1080 UI screen background; `stages_v2` are small
loading-stage thumbnails; `docs_v2` are in-world **readable document**
textures (text legibility is the whole point); `fx` are small effect
overlays (often soft gradients). All of these are close-viewed 2D/UI
content by actual inspection, not distance-viewed 3D world geometry —
reclassified as "keep Lossless" alongside `ui`/`ui_v2`/`touch`/`luts`,
regardless of what a PSNR run might say, matching the task's own hard
rule for UI-adjacent content. `sky` (2 files) is excluded outright per
the same rule (skies are the classic banding-risk case) — not even
PSNR-tested.

Only `tiles`, `surfaces` (the pre-identified 65%-of-budget pilot) and
`environment`, `enemies` (genuine distance-viewed 3D world/character
textures) were tested.

## 3. Results

| Category | Tested | Passed (≥40dB) | Compressed | min / mean PSNR (passed set) |
|---|---|---|---|---|
| `tiles` | 44 | 44 | ✅ all | 45.64 / — dB (with `high_quality=true`; default quality measured 34.01/36.69 dB, all fail) |
| `surfaces` | 27 | 27 | ✅ all | 45.64 / 50.46 dB (combined with tiles, n=71) |
| `environment` | 4 | 3 (`asphalt`, `brick`, `concrete`) | ✅ 3, ❌ `rusty_metal` (35.63 dB) | 49.25–52.37 dB |
| `enemies` | 7 | 0 | ❌ all — kept Lossless | 28.06–35.94 dB, well under 40 even with `high_quality=true` |
| `items`, `items_legacy`, `renders_v2`, `portraits_v2`, `screens_v2`, `stages_v2`, `docs_v2`, `fx`, `sky`, `ui`, `ui_v2`, `touch`, `luts`, `icons`, `icons_v2`, `onboard_v2`, `maps`, `maps_v2` | 0 (not tested — see §2) | — | ❌ kept Lossless by category, not by PSNR | — |

**Key finding: `compress/high_quality=true` is required.** Default
quality (`false`) failed the 40dB bar entirely on the first pilot batch
(min 34.01, mean 36.69 across 71 files); enabling it alone raised the
same 71 files to min 45.64, mean 50.46 — every one cleared 40dB with room
to spare. `enemies` textures failed the bar even with `high_quality=true`
(28–36 dB) — character/monster skins have more high-frequency detail
(fabric, skin tone variance) than flat environment surfaces and were
kept Lossless, no exception.

**74 files compressed total** (44 `tiles` + 27 `surfaces` + 3
`environment`), all individually PSNR-verified ≥40dB (actual range
45.64–52.37 dB). Full per-file numbers are reproducible:

```bash
godot --headless --path . --script tools/texture_psnr_check.gd -- \
    assets/textures/tiles assets/textures/surfaces assets/textures/environment
```

## 4. Real size impact — measured, not estimated

For the 74 compressed files:

- **On-disk (APK-relevant) size: 8.99 MiB → 9.69 MiB (+0.70 MiB, a small
  net INCREASE).** This game's flat, palette-locked art (`docs/
  STYLE_GUIDE.md`) already compresses very well under Lossless PNG's
  deflate; ETC2/ASTC block compression is fixed-rate regardless of how
  simple the image is, so it does not shrink — and can grow — content
  this flat. Confirms the caution flagged in the prior pass's estimate
  (§3 there): the APK-download-size win was never guaranteed for this
  specific art style, and for this batch it did not materialize.
- **VRAM/runtime memory footprint: 38.75 MiB → 9.69 MiB, a real ~4.0x
  reduction.** This is the actual, reliable, measured benefit — an
  uncompressed RGBA8 texture costs width×height×4 bytes in GPU memory no
  matter what its on-disk format is; a VRAM-compressed texture stays
  compressed in memory. This is what actually protects a low-end Android
  device from texture-memory pressure/thrashing, which was the real
  motivation, not APK download size.

## 5. Verification

`bash tools/check.sh --static` and `tools/qa_sim/headless_suite`: green,
unaffected (neither exercises pixel content). `--headless --import`
confirmed to not error on any of the 74 files. No visual/windowed
banding check was performed — per standing NO-GODOT-windowed policy this
session cannot render a frame; that remains the one owner-only step
(`docs/artifacts/known_owner_only_items.md`) before shipping this
specific change, same as the general texture-compression caution already
on record.

## 6. What's NOT done, honestly

660+ textures remain untested/Lossless: everything correctly excluded by
category in §2, plus the 4 remaining `assets/textures/` subdirectories
(`fx`, `sky`, and the icon/portrait/render families) and the ~500 texture
files living outside `assets/textures/` entirely (`assets/art/`, store
assets, etc. — not audited this pass). This was a real, verified,
74-file pilot proving the method works and is worth doing, not a claim
that the whole texture budget has been addressed.
