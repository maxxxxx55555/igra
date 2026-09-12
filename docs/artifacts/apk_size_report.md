# APK size report — texture compression (updated 2026-09-12, FINAL HARDENING PASS)

**Update:** the pilot this report called for in STEP 7 (RELEASE CONVERGENCE,
same day) was executed and PSNR-verified in the same pass — see
`docs/artifacts/texture_compression_audit.md` for the full method and
per-category results. This report keeps the original baseline measurement
(§1-2) and replaces the estimate in the old §3-5 with the real, measured
outcome.

## 1. Baseline (measured, STEP 7)

- **738 texture source files** (`.png`/`.jpg`) under `assets/`, **738 matching
  `.import` files** (1:1, no orphans).
- **41.2 MiB** total on-disk source size, **100% Lossless** before this pass.
- `export_presets.cfg`'s Android preset already has `texture_format/etc2_astc=
  true` set.

## 2. Where the bytes actually are

| Category | Size | Share of `assets/textures/` |
|---|---|---|
| `tiles` + `surfaces` (compression pilot) | 9.4 MiB | ~65% |
| `environment` + `enemies` | 0.5 MiB | ~4% |
| Everything else (UI, icons, LUTs, portraits, docs, items, sky, fx — kept Lossless by category, see audit §2) | ~4.3 MiB | ~31% |

## 3. Real, measured result (not an estimate)

74 files compressed (`compress/mode=2` + `compress/high_quality=true`),
every one individually PSNR-verified ≥40dB against its Lossless original
(actual range 45.64–52.37 dB; `enemies` and one `environment` file
failed the bar even at high quality and were kept Lossless — full
breakdown in the audit doc).

| Metric | Lossless (before) | VRAM Compressed (after) | Change |
|---|---|---|---|
| **On-disk / APK-relevant size** (these 74 files) | 8.99 MiB | 9.69 MiB | **+0.70 MiB — a small net increase** |
| **VRAM / runtime memory footprint** (uncompressed RGBA8 vs. compressed, same 74 files) | 38.75 MiB | 9.69 MiB | **−29.06 MiB, ~4.0x reduction** |

**The honest conclusion the old §3's estimate anticipated turned out to be
exactly right, in the surprising direction:** this game's flat,
palette-locked art (`docs/STYLE_GUIDE.md`) compresses so well under
Lossless PNG's deflate that fixed-rate ETC2/ASTC block compression does
**not** shrink the APK for this content — it grows it slightly. The real,
substantial win is VRAM/runtime memory (~4x less GPU memory for these
textures), which is what actually protects a low-end Android device from
texture-memory pressure — that was always the more important motivation
than download size, and it is now confirmed, not assumed.

## 4. What's still not done, and why

`.import` compression settings for the other ~660 texture files were
either explicitly excluded by content category (UI, icons, LUTs,
portraits, in-world readable documents, skies — all close-viewed or
banding-sensitive by direct inspection, see audit §2) or simply not
tested this pass (everything outside `assets/textures/`, e.g.
`assets/art/`). Committing the compression choice at all required a
scoped `.gitignore` exception (`.import` is normally never committed in
this project) — documented in the audit report §1.

**Still owner-only, unchanged from the prior version of this report:** a
real windowed look at the 74 now-compressed textures in a running scene,
for banding — PSNR is an objective proxy, not a substitute for eyes on
the actual render. `docs/artifacts/known_owner_only_items.md` §4 covers
this.

## 5. Reproduce / extend

```bash
godot --headless --path . --script tools/texture_psnr_check.gd -- \
    assets/textures/tiles assets/textures/surfaces assets/textures/environment
```

To extend the pilot to a new category: set `compress/mode=2` +
`compress/high_quality=true` on its `.import` files, `godot --headless
--path . --import --quit`, run the PSNR script against that directory,
and only keep files that clear 40dB — exactly the loop this pass ran.
