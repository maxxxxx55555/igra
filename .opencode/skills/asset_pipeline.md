---
name: asset-pipeline
description: Learned facts for asset agents on THE LAST STREETLIGHT (palette, naming, tools, hazards).
---
Palette lock: brass #c9a24a, panel #141b24, edge #2a3340, ember #b4452f, steel #aeb6bf, bone #d8d2c4, teal #4a9ab5. No pure #000/#fff, no neon.
Enemy portraits: assets/textures/enemies/<name>_512.png (suffix _512 mandatory).
Tiles: textures/tiles/<district>_floor.png / _wall.png (256x256 seamless). Surfaces: <prop>_512.png (512 seamless). FX sprites 64x64 RGBA soft alpha <=235.
Item icons: bare name .png in textures/items (128x128, 2px brass outline via MaxFilter(5) ring trick).
Audio: 44.1kHz mono 16-bit WAV via stdlib wave + numpy; ffmpeg 8.1.2 AVAILABLE at session time (verify with ffmpeg -version). Loops: OGG q4 mono <1MB; WAV masters parked in ambience/wav_src/ (exclude from import).
PNG size bloat cause = per-pixel grain on big canvases; skip grain on store art; quantize(256, Dither.NONE) fallback only if >500KB.
Pruner hazard: an external actor intermittently deletes files in assets/textures/grading (targeted night_grade.png once; later transient). On disappearance: regenerate + keep alias lut_night.png; verify with 60s sentinel watch before declaring BLOCKED (3 retries rule).
Parallel actors may delete/rename your outputs between sessions (7 sfx vanished once). Always re-verify manifest rows against disk before claiming done.
Generators live outside repo: %TEMP%/opencode/tls_gen/*.py (gen_textures, gen_audio, gen_phase2_art, gen_final_store, gen_vfx, fix_icons, write_report). Reuse via importlib; deterministic seeds.
UI chrome is drawn via StyleBoxFlat in code (per SESSION_REPORT) - PNG UI set exists but unwired; do not expect scenes to reference it.
Godot headless: C:\Users\Maxsim\Desktop\TLS_Build\godot_extracted\Godot_v4.7-stable_win64_console.exe (gates are code-side, not asset-side).

Mega-wave A facts: ffmpeg loudnorm in-place works but temp output MUST keep audio extension (.tmp breaks muxer). numpy Generator has no .randint -> use .integers. Per-pixel dither/grain kills PNG compression on big canvases (2048x1024 sky: 1686KB -> 45KB by removing pixel noise, using low-freq nebula blobs instead); quantize-to-P only helps when colors are truly limited. District bed contract: ambience/districts/<district>_dark.ogg (+_lit for day), 36s seamless RMS -18 dBFS. Legacy wired WAVs may be 22050Hz stereo-era files; loudnorm pass upgraded 10 of them to 44.1k mono - check _pre_norm before assuming original format.

Mega-wave A facts: ffmpeg loudnorm in-place needs temp output WITH audio extension (.tmp breaks muxer detection). numpy Generator has no randint -> use integers. Per-pixel dither/grain kills PNG compression on big canvases (2048x1024 sky: 1686KB -> 45KB by replacing pixel noise with low-freq nebula blobs); palette quantize only pays off without per-pixel noise. District bed contract: ambience/districts/<district>_dark.ogg (+_lit for day modes), 36s seamless, RMS -18 dBFS, OGG q4 mono. Legacy wired WAVs may be 22050Hz; the loudnorm pass upgraded 10 to 44.1k mono - check _pre_norm before assuming original format.

Truth-wave facts: footstep_system.gd consumes FLAT sfx/<sample>.wav via MATERIALS dict (asphalt_dry/wet, concrete, wood, metal, puddle, glass -> step_* or footstep_* singles); speed = volume+pitch mult, no per-speed files. Music layer contract (new): music/layer_{dark,lit,threat_low,threat_high,action}.ogg, downbeat-aligned bar lengths for clean stacking; action bpm was DEFAULT_CHOICE 120. loudnorm RMS-mean vs LUFS: dense noise reads hot (-13 RMS at -18 LUFS) - trust integrated target.
