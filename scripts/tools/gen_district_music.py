#!/usr/bin/env python3
import argparse, math, os, random, struct, wave
DISTRICTS = [
    ("downtown", 110.0, [0,2,4,5,7,9,11], 90, 3, "warm_major"),
    ("industrial", 73.4, [0,1,4,5,7,8,10], 70, 4, "dark_drone"),
    ("residential", 98.0, [0,2,4,7,9], 85, 2, "soft_pad"),
    ("park", 65.4, [0,2,4,7,9,11], 75, 3, "natural"),
    ("harbor", 82.4, [0,2,3,5,7,8,10], 80, 3, "breezy"),
    ("default", 87.3, [0,3,5,7,10], 80, 2, "neutral"),
]
SR = 22050
def note_hz(root, scale, degree):
    semis = scale[degree % len(scale)] + 12 * (degree // len(scale))
    return root * (2.0 ** (semis / 12.0))
def synth_sample(t, f, mood, rng):
    base = math.sin(2 * math.pi * f * t)
    if mood == "dark_drone": return base * 0.6 + math.sin(2 * math.pi * f * 1.5 * t) * 0.3 + (rng.random() * 2 - 1) * 0.05
    if mood == "warm_major": return base * 0.7 + math.sin(2 * math.pi * f * 2 * t) * 0.2
    if mood == "soft_pad": return base * 0.5 + math.sin(2 * math.pi * f * 0.5 * t) * 0.4
    if mood == "natural": return base * 0.6 + math.sin(2 * math.pi * (f + rng.uniform(-0.5, 0.5)) * t) * 0.3
    if mood == "breezy": return base * 0.5 + math.sin(2 * math.pi * f * 1.25 * t) * 0.2 + (rng.random() * 2 - 1) * 0.04
    return base * 0.6
def synth_track(d, seconds):
    district_id, root, scale, bpm, drone_count, mood = d
    beat = 60.0 / bpm
    bar = beat * 4
    n_bars = max(1, int(seconds / bar))
    total = n_bars * bar
    n = int(total * SR)
    freqs = [note_hz(root, scale, i * 7 % 24) for i in range(drone_count)]
    melody = [note_hz(root * 2, scale, (b * 2 + 1) % len(scale)) for b in range(n_bars)]
    rng = random.Random(int(root * 1000) & 0xFFFFFFFF)
    out = [0.0] * n
    for f in freqs:
        amp = 0.18 / max(1, len(freqs))
        for i in range(n):
            t = i / SR
            env = min(1.0, t * 2.0) * min(1.0, (total - t) * 2.0)
            out[i] += synth_sample(t, f, mood, rng) * amp * env
    for bi, f in enumerate(melody):
        amp = 0.12
        start = int(bi * bar * SR)
        end = min(n, start + int(bar * SR))
        for i in range(start, end):
            t = (i - start) / SR
            env = min(1.0, t * 4.0) * min(1.0, (bar - t) * 4.0)
            out[i] += synth_sample(t, f, mood, rng) * amp * env
    peak = max(1e-6, max(abs(x) for x in out))
    return [max(-1.0, min(1.0, x / peak * 0.85)) for x in out]
def write_wav(path, samples):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32767)) for s in samples))
def main():
    p = argparse.ArgumentParser()
    p.add_argument("--out", default="assets/audio/music")
    p.add_argument("--seconds", type=float, default=24.0)
    args = p.parse_args()
    os.makedirs(args.out, exist_ok=True)
    for d in DISTRICTS:
        samples = synth_track(d, args.seconds)
        path = os.path.join(args.out, d[0] + ".wav")
        write_wav(path, samples)
        print("WROTE " + path)
    print("Done.")
if __name__ == "__main__": main()
