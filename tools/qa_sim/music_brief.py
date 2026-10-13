# -*- coding: utf-8 -*-
"""Music brief (Session 23, S1): one row per district bed of scripts/systems/music_manager.gd AMBIENCE_LIT_BY_DISTRICT, with the file on disk (or not), its measured length and loudness,
and a brief for a composed replacement: a prompt for a generator (Suno, Udio) and a royalty-free fallback to search. The shipped beds are synthesized loops (docs/CERT_AUDIO.md); a composed
bed is the owner's choice, never a gap in the game. No audio is made or fetched here.

usage: python tools/qa_sim/music_brief.py [--write docs/MUSIC_BRIEF.md] [--check]
"""
import pathlib
import re
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "qa_sim"))
import audio_loudness  # noqa: E402

# district -> (what the dark bed is, what the lit twin should feel like, fallback search)
BRIEFS = {
    "suburbs": ("a quiet lawn at night, a distant dog, wind in leaves", "the porch lights come back; a warm hum under soft felt piano, one slow pulse",
                "CC0 ambient pad, 'suburban night' or 'warm drone' on freesound and OpenGameArt"),
    "residential": ("pipes creaking in a sleeping block, a television murmur through a wall", "a lived-in warmth: a low string pad, a faint music-box figure, the block waking",
                    "CC0 'apartment room tone' with a warm pad laid over it"),
    "park": ("bare trees, skittering leaves, the city humming far off", "a clearing opening: sparse glass tones and a breathing drone, no melody that resolves",
             "CC0 'forest night' ambience plus a slow bowed pad"),
    "school": ("empty hallways, a bell's echo, a locker far away", "the hall lights flicker on: a chalk-dry piano, two notes at a time, a long room reverb",
               "CC0 'empty corridor' reverb tails and a soft upright piano loop"),
    "hospital": ("monitor beeps, gurney wheels, a mumble from a speaker", "clean and cold-warm: sine pulses at the monitor's tempo under a thin string bed",
                 "CC0 'medical ambience' without voices, plus a slow sine pad"),
    "gas_station": ("a buzzing sign, a pump's hum, gravel under a car that passes", "the canopy burns on: a sodium-lamp hum, a lone clean guitar swell, far road noise",
                    "CC0 'neon buzz' and 'highway night' layered under a reverbed guitar loop"),
    "police": ("radio static, boots on concrete, a siren's tail", "the desk lamp is on: a muted brass pad, a slow heartbeat kick far back, radio hiss at -40 dB",
               "CC0 'police radio static' (no speech) under a low brass pad"),
    "warehouses": ("metal creaking, a chain, a forklift far away", "a loading bay lit orange: a deep drone with a slow metallic bell every 12 bars, no rhythm",
                   "CC0 'warehouse ambience' with a low drone and a single struck-metal sample"),
    "industrial": ("machinery drone, pipe hiss, a steam vent", "machines running again: a resonant drone that breathes with the steam, a faint mechanical pulse at 60 bpm",
                   "CC0 'factory drone' and 'steam vent' layers, filtered warm"),
    "substation": ("a transformer's buzz, an arc's crackle, cable hum", "the current flows: a clean 50 Hz-based hum with harmonics, glassy overtones, a distant crackle",
                   "CC0 'transformer hum' with a sparse glass-harmonic pad"),
    "power_station": ("generator thrum, high-voltage whine, a breaker's clunk", "the generator spools up: a warm thrum, rising harmonics that never peak, the lights of the whole city implied",
                      "CC0 'generator room' with a slow rising pad, loop-matched"),
}
COMMON = "instrumental only, no vocals, no drums, seamless 36 s loop, mono, about -18 LUFS, nocturnal palette (brass and bone, never neon), dark twin of the same district for contrast"


def lit_table():
    text = (ROOT / "scripts/systems/music_manager.gd").read_text(encoding="utf-8").replace("\r\n", "\n")
    block = text[text.index("const AMBIENCE_LIT_BY_DISTRICT"):]
    block = block[:block.index("}")]
    return re.findall(r'&"(\w+)":\s*"res://([^"]+)"', block)


def probe(path):
    ffprobe = shutil.which("ffprobe")
    r = subprocess.run([ffprobe, "-v", "error", "-show_entries", "format=duration:stream=channels,sample_rate", "-of", "default=nw=1", str(path)], capture_output=True, text=True)
    values = dict(line.split("=", 1) for line in r.stdout.split() if "=" in line)
    return float(values.get("duration", 0.0)), values.get("channels", "?"), values.get("sample_rate", "?")


def rows():
    out = []
    tool = audio_loudness.ffmpeg()
    for district, rel in lit_table():
        path = ROOT / rel
        if path.exists():
            seconds, channels, rate = probe(path)
            lufs, peak, _ = audio_loudness.measure(tool, path)
            out.append((district, rel, True, seconds, channels, rate, lufs, peak))
        else:
            out.append((district, rel, False, 0.0, "-", "-", None, None))
    return out


def write(path, data):
    lines = ["# Music brief for the lit beds (Session 23)", "",
             "Generated by `python tools/qa_sim/music_brief.py --write docs/MUSIC_BRIEF.md` from `AMBIENCE_LIT_BY_DISTRICT` in `scripts/systems/music_manager.gd`. A lit bed plays when a district is restored (`docs/AUDIO_COVERAGE.md`).",
             "All %d beds are on disk (the eight added on 2026-09-11 and the three before); they are synthesized loops (`docs/CERT_AUDIO.md`), so a composed replacement is an upgrade the owner may choose, not a hole in the game. "
             "Nothing here is audio and nothing was fetched: the prompts and search phrases are briefs." % sum(1 for d in data if d[2]), "",
             "| District | File | On disk | Length (s) | Channels, rate | LUFS | True peak (dBFS) |", "|---|---|---|---|---|---|---|"]
    for district, rel, present, seconds, channels, rate, lufs, peak in data:
        lines.append("| %s | `%s` | %s | %.1f | %s, %s | %s | %s |" % (district, rel, "yes" if present else "NO", seconds, channels, rate, "%.1f" % lufs if lufs is not None else "-", "%.1f" % peak if peak is not None else "-"))
    lines += ["", "## Briefs", "", "Common to every brief: " + COMMON + ".", "",
              "| District | The dark bed | The lit twin should | Generator prompt | Royalty-free fallback (search, check the licence of what you pick) |", "|---|---|---|---|---|"]
    for district, (dark, lit, fallback) in BRIEFS.items():
        prompt = "Ambient bed for the %s of a ruined city at night, restored power: %s. %s." % (district.replace("_", " "), lit, COMMON)
        lines.append("| %s | %s | %s | %s | %s |" % (district, dark, lit, prompt, fallback))
    lines += ["", "UNVERIFIABLE-HERE: how a composed bed sounds on a phone speaker, and the licence of any generated or downloaded track; owner action: listen on the target phone, keep the generator's licence text or the track's source page with the file, and add a row to `docs/ASSET_LICENSES.md`."]
    pathlib.Path(path).write_text("\n".join(lines) + "\n", encoding="utf-8")


def main(argv):
    if "--write" in argv:
        data = rows()
        write(argv[argv.index("--write") + 1], data)
        missing = [d[0] for d in data if not d[2]]
        for d in missing:
            print("NOTE %s has no lit bed on disk" % d)
    else:
        data = [(district, rel, (ROOT / rel).exists()) for district, rel in lit_table()]
    unbriefed = [d[0] for d in data if d[0] not in BRIEFS]
    stale = [d for d in BRIEFS if d not in {x[0] for x in data}]
    for d in unbriefed:
        print("FAIL %s has a lit bed and no brief" % d)
    for d in stale:
        print("FAIL the brief of %s has no row in AMBIENCE_LIT_BY_DISTRICT" % d)
    print("music_brief: %d bed(s), %d on disk, %d without a brief, %d stale brief(s)" % (len(data), sum(1 for d in data if d[2]), len(unbriefed), len(stale)))
    return 1 if unbriefed or stale else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
