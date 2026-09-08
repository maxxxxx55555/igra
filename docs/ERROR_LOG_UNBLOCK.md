# ERROR_LOG_UNBLOCK — UNBLOCK WAVE session

Format: file/item | attempt | check failed | root cause | fix applied | final status

| File/item | Attempt | Check failed | Root cause | Fix applied | Final status |
|---|---|---|---|---|---|
| craft icon count | 0 (plan) | brief pinned ×13; no grep yields 13 (workbench.gd components=10 incl. tool, recipes.json needs=12, brief-named=7, union=19) | brief count inconsistent with its own grep instruction | protocol "grep-locked wins": delivered FULL union of both recipe sources (19 ids, 'tool' excluded as a tool) — zero gaps for craft rows | RESOLVED 19 (deviation logged) |
| portrait distinctness metric | 1 | alpha-sig IoU 1.000 (false FAIL) | RGB portraits → alpha mask all-ones → fallback IoU 1.0; threshold-accent sig left masks near-empty (2–26 px at 32×48) | luminance-correlation metric (no thresholding): worst 0.721 < 0.98 | PASS (metric fix) |
| weapon distinctness metric | 1 | same false 1.000 | same as above on dark renders | luminance-correlation: worst 0.649 | PASS (metric fix) |
| craft bottle/case/scrap | 1 | tonal spread 0.0 at native 64px | accent lines 1px wide = <10% of visible pixels → second tone statistically invisible | accents chunked: filled teal label, olive band, 3px outline + 2px facet lines | PASS |
| craft gunpowder/scrap/transistor | 1 | coverage 0.044–0.05 < 0.05 | glyphs too sparse on 64px canvas | boldened: 3px outlines, larger pile/body, filled core | PASS |
| craft cable | 1 | coverage 0.05 marginal | thin 2px coil + small plug | 3px coil, larger plug, brass pins | PASS |
| ending_dark_full.ogg | 1 | seam −2.76dB > 0.8 | step attack ramps inside head window vs full-sustain tail window | fast 0.15s attacks, overlapping crossfaded steps, ALL layers sustain to wrap (descent via crossfade) | PASS seam +0.61dB |
| wind_loop re-verify (QA) | 1 | false FAIL seam −1.08 vs 0.8 | QA applied the ending-music threshold to an item whose own contract is ±1.5dB (ERROR_LOG_GAMEFEELV2/polish precedent) | QA uses per-item contract; fresh numbers I=−18.19 TP=−10.55 seam −1.08dB | PASS |
| heartbeat decode during QA | 1 | ffmpeg Vorbis "Invalid packet", decoded 0.09s | transient: concurrent file access during external Godot import scan (file itself valid: ffprobe 20.00s / 64170B) | re-ran decode clean: 20.00s I=−17.99 TP=−9.49 | PASS (transient) |

## DEFAULT_CHOICE marks

- Portrait designs for the 6 roster gaps (brute/burner/hound/rotter/sharpshooter/tvar): GDD names
  them but gives no visual canon beyond §9.2 roles — silhouettes/rim colors derived from roles,
  matched to existing 6 portraits' mood (near-black bg, rim light, glowing eyes).
- Branch header motifs: brief's examples mapped fighter→combat (fist+bolt), survivor→survival
  (boot+eye), engineer→utility (wrench+gear); branch tints per skill-tree canon
  (combat=brass, survival=teal, utility=ember).
- Ending music keys/structure: light=A-major pentatonic build (bell period 12s×5), dark=whole-tone
  descent D2→G1 + 82Hz pulse every 2s — canon gives mood adjectives only.
- Onboard strip camera/geometry (alley walls, pole at x=206) — brief pins content beats, not layout.
