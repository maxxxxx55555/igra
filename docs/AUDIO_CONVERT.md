# AUDIO_CONVERT.md — ambience pipeline note

Phase-2 status: `ffmpeg` WAS present → the 5 long loops were converted in place.

- `assets/audio/ambience/*_loop.ogg` — OGG Vorbis, mono, q4 (ambient_lit fell back to nothing; all ≤ 1 MB: 103 KB – 951 KB). Stream these.
- Original full-length WAV masters moved to `assets/audio/ambience/wav_src/` (1.3–10.6 MB). Do not ship on export; exclude via export presets or keep for re-mastering only.

Commands used (reproducible):

    ffmpeg -y -i wav_src/ambient_dark_loop.wav  -c:a libvorbis -q:a 4 -ac 1 ambient_dark_loop.ogg
    ffmpeg -y -i wav_src/ambient_lit_loop.wav   -c:a libvorbis -q:a 4 -ac 1 ambient_lit_loop.ogg
    ffmpeg -y -i wav_src/threat_low_loop.wav    -c:a libvorbis -q:a 4 -ac 1 threat_low_loop.ogg
    ffmpeg -y -i wav_src/threat_high_loop.wav   -c:a libvorbis -q:a 4 -ac 1 threat_high_loop.ogg
    ffmpeg -y -i wav_src/action_sting_loop.wav  -c:a libvorbis -q:a 4 -ac 1 action_sting_loop.ogg

If any result ≥ 1 MB, re-encode at fixed rate:

    ffmpeg -y -i <src>.wav -c:a libvorbis -b:a 56k -ac 1 <out>.ogg

## Import recommendations (Godot)

| File | Loader | Loop | Notes |
|---|---|---|---|
| ambience/*_loop.ogg | OggVorbisStream (STREAM) | loop=true in import | seamless crossfade baked; do not gapless-restart |
| sfx/*.wav ≤ 0.5 s (ui_*, footsteps) | WAV (sample, in-memory) | off | low latency |
| sfx/*.wav > 0.5 s (shots, monster_*) | WAV sample ok; switch to OGG q6 if RAM budget tight | off | |
| ambience/wav_src/*.wav | never import | — | master archive |
