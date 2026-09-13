# docs/artifacts/ui-audio — UI Audio Pack v2 artifacts (2026-09-13)

This folder contains the build + verification trail for the 7 CC0 UI stings.

## Files

| Artifact | Purpose |
|---|---|
| `_build_ui_audio.py` | Deterministic ffmpeg pipeline: source → OGG Vorbis q4 mono 44.1k (menu_click -6dB tame) |
| `header_report.json` | Machine-readable header facts (frames, rate, ch, codec, granule, size, peak, RMS) |
| `peak_table.csv` | Contact/peak table (file, duration, ch, rate, codec, granule, size, peak_dBFS, rms_dBFS) — attachment |
| `contact_sheet.png` | Visual contact sheet: 7 waveform thumbnails + labels (brass #c9a24a on #0c1016) — attachment |
| `sources/*_src.*` | Original CC0 binaries before re-encode (provenance): Kenney click1.wav + 6× zen OGG Opus |
| `verify.py` | Independent stdlib Ogg/Vorbis re-parse (second agent) — no ffmpeg, no soundfile, pure struct |
| `verify.log` | Verify run output: 7× header PASS + license URL re-check PASS |
| `search_log.md` | Web search queries, hits, dispositions, TLS probe, mood centroid audit |
| `license_check.md` | CC0 deed fetch + local LICENSE-AUDIO excerpts |

## Re-generate

```bash
python3 docs/artifacts/ui-audio/_build_ui_audio.py   # transcode + header_report + peak_table + contact_sheet
python3 docs/artifacts/ui-audio/verify.py            # independent re-parse
```

## Source licenses (re-check)

- Kenney: CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/ (fetched)
- uisfx: CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/ (LICENSE-AUDIO, fetched)

All 7 deliverables are CC0, no attribution required.
