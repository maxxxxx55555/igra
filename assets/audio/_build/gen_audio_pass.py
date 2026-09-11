#!/usr/bin/env python3
"""TLS AUDIO PASS (2026-09-11) — deterministic lit-bed + wow-cue renderer.

Repo-canonical method per .opencode/skills/asset_pipeline.md: numpy synth of
44.1 kHz mono masters -> ffmpeg dual-pass loudnorm -> OGG q4. Seeds fixed;
re-render: python3 gen_pass.py [beds|cues|all] (needs numpy, soundfile,
imageio-ffmpeg static ffmpeg 7.0.2). Masters/OGGs -> $TLS_WORK (default
/home/user/tls_work). Contract: beds 36.000 s (G2h 1499146 smp = 33.994240 s
to match industrial_dark exactly), cues 60/90/120 s one-shots with zero
endpoints, OGG q4 mono 44.1 k, -18 LUFS integrated, TP <= -1.5 dBFS, no voices.
"""
import json, os, subprocess, sys
import numpy as np
import soundfile as sf
import imageio_ffmpeg
SR = 44100
FF = imageio_ffmpeg.get_ffmpeg_exe()
WORK = os.environ.get('TLS_WORK', '/home/user/tls_work')
M_D = os.path.join(WORK, 'master'); O_D = os.path.join(WORK, 'ogg')
os.makedirs(M_D, exist_ok=True); os.makedirs(O_D, exist_ok=True)
DB = lambda db: 10.0 ** (db / 20.0)
def qc(f, N):  # whole-cycle quantized freq (perfect loop)
    return round(f * N / SR) * SR / N
def n_arr(N): return np.arange(N, dtype=np.float64)
def tone(N, f, a=1.0, ph=0.0):
    return a * np.sin(2 * np.pi * qc(f, N) * n_arr(N) / SR + ph)
def wob(N, k, depth, ph=0.0):  # whole-cycle LFO multiplier
    return 1.0 + depth * np.sin(2 * np.pi * k * n_arr(N) / N + ph)
def lp_shape(fc, order=2):
    return lambda f: 1.0 / np.sqrt(1.0 + (np.maximum(f, 1e-6) / fc) ** (2 * order))
def hp_shape(fc, order=2):
    return lambda f: 1.0 / np.sqrt(1.0 + (fc / np.maximum(f, 1e-6)) ** (2 * order))
def bp_shape(f0, f1, order=2):
    l, h = lp_shape(f1, order), hp_shape(f0, order)
    return lambda f: l(f) * h(f)
def fft_noise(N, rng, shape, rms_db):
    # perfectly periodic noise: shaped spectrum, random phases, irfft
    nf = N // 2 + 1
    f = np.fft.rfftfreq(N, 1.0 / SR)
    mag = (shape(f) * hp_shape(55.0, 2)(f)).astype(np.float64)
    ph = rng.uniform(0, 2 * np.pi, nf)
    ph[0] = 0.0
    if N % 2 == 0: ph[-1] = 0.0
    X = mag * np.exp(1j * ph)
    x = np.fft.irfft(X, n=N)
    x -= np.mean(x)
    cur = np.sqrt(np.mean(x ** 2)) + 1e-12
    return x * (DB(rms_db) / cur)
def place_loop(y, ev, t0):
    N = len(y); i0 = int(round(t0 * SR)) % N
    idx = (i0 + np.arange(len(ev))) % N
    y[idx] += ev
    return y
def edge_zero(y, ms=3.0):
    m = int(SR * ms / 1000.0)
    w = 0.5 - 0.5 * np.cos(np.pi * np.arange(m) / m)  # 0..1 raised cosine
    y = y.copy(); y[:m] *= w; y[-m:] *= w[::-1]
    y[0] = 0.0; y[-1] = 0.0
    return y
def norm_peak(y, db=-3.0):
    p = np.max(np.abs(y)) + 1e-12
    return y * (DB(db) / p)
# ---- motifs ----
def ev_creak(rng, dur=0.7, f0=300.0, f1=150.0, a=1.0):
    n = int(dur * SR); t = np.arange(n) / SR
    ph = 2 * np.pi * (f0 * t + (f1 - f0) * t ** 2 / (2 * dur))
    y = np.zeros(n)
    for h in range(1, 6):
        y += np.sin(h * ph) / (h ** 1.5)
    y += 0.15 * rng.standard_normal(n) * np.exp(-3 * t / dur)
    env = np.sin(np.pi * np.minimum(t / dur, 1.0)) ** 1.5
    return a * y * env / 3.0
def ev_clank(partials, dur=1.2, a=1.0, tick=0.0, rng=None):
    n = int(dur * SR); t = np.arange(n) / SR
    y = np.zeros(n)
    for f, d, g in partials:
        y += g * np.sin(2 * np.pi * f * t) * np.exp(-t / d)
    if tick > 0 and rng is not None:
        m = int(0.02 * SR)
        y[:m] += tick * rng.standard_normal(m) * np.exp(-np.arange(m) / (0.004 * SR))
    return a * y
def ev_bell(f0, dur=2.5, a=1.0, bright=1.0):
    n = int(dur * SR); t = np.arange(n) / SR
    y = np.zeros(n)
    for h, g, dd in [(1.0, 1.0, dur / 2.5), (2.01, 0.5 * bright, dur / 4.0),
                     (2.74, 0.3 * bright, dur / 6.0), (3.76, 0.2 * bright, dur / 8.0)]:
        y += g * np.sin(2 * np.pi * f0 * h * t) * np.exp(-t / dd)
    y *= np.minimum(t / 0.008, 1.0)  # soft attack
    return a * y / 1.6
def ev_crack_soft(rng, dur=0.28, f_hi=3200.0, f_lo=800.0, a=1.0):
    n = int(dur * SR); t = np.arange(n) / SR
    w = rng.standard_normal(n)
    # one-pole lowpass with sweeping cutoff (warm ice tick)
    fc = f_hi * np.exp(-t / (dur / 3.0)) + f_lo
    y = np.zeros(n); last = 0.0
    for i in range(n):
        k = 1.0 - np.exp(-2 * np.pi * fc[i] / SR)
        last += k * (w[i] - last); y[i] = last
    env = np.minimum(t / 0.005, 1.0) * np.exp(-t / (dur / 4.0))
    return a * y * env / 2.5
def ev_roadpass(rng, dur=4.5, a=1.0):
    n = int(dur * SR); t = np.arange(n) / SR
    w = rng.standard_normal(n)
    # bandpass sweep feel via two one-poles
    y = np.zeros(n); l1 = 0.0; l2 = 0.0
    for i in range(n):
        u = t[i] / dur
        fc = 400 + 900 * np.sin(np.pi * u)  # swell in cutoff with pass
        k = 1.0 - np.exp(-2 * np.pi * fc / SR)
        l1 += k * (w[i] - l1); l2 += 0.08 * (l1 - l2)
        y[i] = l1 - l2
    env = np.sin(np.pi * u if False else np.pi * t / dur) ** 2
    return a * y * env / 1.5
def ev_swell_hum(f, dur=6.0, a=1.0):
    n = int(dur * SR); t = np.arange(n) / SR
    env = np.sin(np.pi * t / dur) ** 1.5
    return a * np.sin(2 * np.pi * f * t) * env
def pad(N, root_midi, intervals, a=1.0, trem_k=2, trem_d=0.08):
    y = np.zeros(N)
    for iv in intervals:
        f = 440.0 * 2 ** ((root_midi + iv - 69) / 12.0)
        y += tone(N, f, 1.0) + tone(N, 2 * f, 0.25) + tone(N, 3 * f, 0.08)
    y *= wob(N, trem_k, trem_d)
    return a * y / max(1, len(intervals))
# ---- bed recipes: name -> (N, seed, build_fn) ----
N36 = 1587600
def b_residential(rng):
    N = N36; y = np.zeros(N)
    y += fft_noise(N, rng, lp_shape(500), -26.0)                      # softened cold drone
    y += tone(N, 251.5, DB(-30.0)) * wob(N, 3, 0.15)                 # dark-bed motif echo, -6-ish
    y += pad(N, 50, [0, 4, 7], a=DB(-22.0))                          # D major warm pad (low)
    y += fft_noise(N, rng, bp_shape(900, 2600), -32.0) * wob(N, 12, 0.10)  # 80bpm bar breathing
    y = place_loop(y, ev_creak(rng, 0.7, 300, 150, DB(-20.0)), 6.0)  # bars 2,7 @3.0s
    y = place_loop(y, ev_creak(rng, 0.8, 260, 130, DB(-22.0)), 21.0)
    return y
def b_park(rng):
    N = N36; y = np.zeros(N)
    y += fft_noise(N, rng, bp_shape(1000, 3200), -25.0) * wob(N, 5, 0.25)  # calm leaf bed
    y += tone(N, 55, DB(-28.0)) + tone(N, 110, DB(-32.0))           # city hum tucked low
    y += pad(N, 48, [0, 4, 7, 11], a=DB(-24.0))                     # C lydian-ish warmth
    for tt, aa in [(4.0, -20.0), (16.0, -23.0), (26.4, -21.0)]:
        y = place_loop(y, ev_crack_soft(rng, 0.28, 3200, 800, DB(aa)), tt)
    return y
def b_school(rng):
    N = N36; y = np.zeros(N)
    y += fft_noise(N, rng, lp_shape(600), -25.0)                     # soft room tone
    y += (tone(N, 60, DB(-24.0)) + tone(N, 120, DB(-27.0))) * wob(N, 7, 0.20)  # ballast ~0.2Hz
    y += fft_noise(N, rng, bp_shape(200, 800), -30.0)               # breath/pipe LP800 -8
    y += pad(N, 52, [0, 4, 7], a=DB(-25.0))                         # E major warmth
    y = place_loop(y, ev_bell(659.26 * 2 ** (-40 / 1200.0), 2.8, DB(-22.0), 0.6), 12.0)  # relay bell
    return y
def b_gas(rng):
    N = N36; y = np.zeros(N)
    y += fft_noise(N, rng, bp_shape(300, 1500), -24.0) * wob(N, 4, 0.20)   # open-air wind -4
    y += (tone(N, 60, DB(-24.0)) + tone(N, 120, DB(-27.0))) * wob(N, 5, 0.18)  # canopy ballast
    y += tone(N, 50, DB(-26.0)) + tone(N, 100, DB(-30.0))           # pump thrum -26
    y += pad(N, 52, [0, 7, 10], a=DB(-25.0))                        # E blues dark-warm
    y = place_loop(y, ev_roadpass(rng, 4.5, DB(-19.0)), 18.0)       # one distant road pass
    return y
def b_police(rng):
    N = N36; y = np.zeros(N)
    y += fft_noise(N, rng, lp_shape(450), -26.0)                     # cold room tone lowered
    y += (tone(N, 60, DB(-24.0)) + tone(N, 120, DB(-28.0))) * wob(N, 5, 0.15)  # court flood
    y += fft_noise(N, rng, lp_shape(900), -31.0)                     # thin distant-city bed
    y += pad(N, 53, [0, 3, 7], a=DB(-26.0))                         # F minor, sparse
    return y
def b_ware(rng):
    N = N36; y = np.zeros(N)
    y += fft_noise(N, rng, bp_shape(100, 600), -24.0) * wob(N, 3, 0.20)    # fog drone lowered
    y += (tone(N, 60, DB(-24.0)) + tone(N, 120, DB(-28.0))) * wob(N, 5, 0.18)  # yard floods
    y += pad(N, 48, [0, 3, 7, 10], a=DB(-24.0))                     # C dorian
    y = place_loop(y, ev_clank([(220, 0.5, 1.0), (331, 0.35, 0.6), (517, 0.25, 0.4)],
                               1.4, DB(-21.0), tick=0.15, rng=rng), 10.0)
    return y
def b_industrial(rng):
    N = 1499146; y = np.zeros(N)
    for f, a in [(49, -25.0), (98, -27.0), (147, -30.0)]:            # machinery drone -6-ish
        y += tone(N, f, DB(a)) * wob(N, 2, 0.12)
    y += fft_noise(N, rng, bp_shape(400, 900), -27.0) * wob(N, 4, 0.22)    # steam gentler LP900
    y += (tone(N, 60, DB(-24.0)) + tone(N, 120, DB(-28.0))) * wob(N, 5, 0.16)  # high-bay hum
    y += pad(N, 46, [0, 3, 7], a=DB(-25.0))                         # Bb minor
    bar = 60.0 / 85.0 * 4.0
    y = place_loop(y, ev_clank([(55, 0.6, 1.0), (110, 0.5, 0.8), (165, 0.35, 0.5),
                                 (247, 0.25, 0.3)], 1.6, DB(-20.0), tick=0.1, rng=rng), 3 * bar)
    return y
def b_substation(rng):
    N = N36; y = np.zeros(N)
    y += tone(N, 50, DB(-27.0)) * wob(N, 2, 0.10)                   # busbar drone lowered
    y += tone(N, 100, DB(-24.0)) + tone(N, 200, DB(-27.0))          # transformer warmed
    y += fft_noise(N, rng, lp_shape(2200), -30.0)                   # 3k edge softened
    y += (tone(N, 60, DB(-25.0)) + tone(N, 120, DB(-29.0))) * wob(N, 5, 0.16)  # yard floods
    y += pad(N, 50, [0, 4, 7], a=DB(-25.0))                         # D phrygdom-ish warmth
    y = place_loop(y, ev_swell_hum(100.0, 6.0, DB(-22.0)), 20.0)    # cable-hum swell
    return y
# ---- cues (one-shots, zero endpoints) ----
def c_first_light(rng):
    N = 60 * SR; y = np.zeros(N); t = n_arr(N) / SR
    y += fft_noise(N, rng, lp_shape(1200), -26.0)
    y += pad(N, 45, [0, 4, 7], a=DB(-26.0))
    sw = np.exp(-((t - 30.0) / 14.0) ** 2)                          # swell @0:30
    y += pad(N, 57, [0, 4, 7, 11], a=1.0) * sw * DB(-20.0)
    y += fft_noise(N, rng, bp_shape(1500, 5000), -34.0) * (0.3 + 0.7 * sw)
    ch = ev_bell(659.26, 9.0, DB(-20.0), 0.8); y[30 * SR:30 * SR + len(ch)] += ch
    y *= np.minimum(t / 2.0, 1.0) * np.minimum((60.0 - t) / 4.0, 1.0)
    return y
def c_cascade(rng):
    N = 90 * SR; y = np.zeros(N); t = n_arr(N) / SR
    y += tone(N, 50, DB(-26.0)) + tone(N, 100, DB(-28.0))
    for k, tc in enumerate([22.0, 38.0, 54.0, 68.0]):                # four rising waves
        wv = np.exp(-((t - tc) / 9.0) ** 2) * (0.4 + 0.2 * k)
        y += tone(N, 100 + 50 * k, 1.0) * wv * DB(-22.0)
        y += fft_noise(N, rng, bp_shape(400, 3000), -40.0) * wv * 4.0
    cli = np.exp(-((t - 74.0) / 6.0) ** 2)                           # climax ~74s
    y += pad(N, 45, [0, 4, 7], a=1.0) * cli * DB(-16.0)
    res = np.clip((t - 78.0) / 12.0, 0, 1)                           # resolve to calm
    y += pad(N, 45, [0, 4, 7], a=1.0) * res * DB(-26.0) * (1 - cli)
    y *= np.minimum(t / 2.0, 1.0) * np.minimum((90.0 - t) / 5.0, 1.0)
    return y
def c_victory(rng):
    N = 120 * SR; y = np.zeros(N); t = n_arr(N) / SR
    y += pad(N, 44, [0, 3, 7], a=DB(-27.0))                          # cool minor base
    for tc, iv, aa in [(30.0, [0, 4, 7], -22.0), (60.0, [0, 4, 7, 11], -20.0),
                       (90.0, [0, 4, 7], -23.0)]:                    # warm answers
        sw = np.exp(-((t - tc) / 12.0) ** 2)
        y += pad(N, 53, iv, a=1.0) * sw * DB(aa)
    y += fft_noise(N, rng, lp_shape(900), -30.0)
    ch = ev_bell(523.25, 10.0, DB(-24.0), 0.5); y[60 * SR:60 * SR + len(ch)] += ch
    y *= np.minimum(t / 3.0, 1.0) * np.minimum((120.0 - t) / 6.0, 1.0)
    return y
BEDS = [('residential_lit', N36, 1101, b_residential), ('park_lit', N36, 1102, b_park),
        ('school_lit', N36, 1103, b_school), ('gas_station_lit', N36, 1104, b_gas),
        ('police_lit', N36, 1105, b_police), ('warehouses_lit', N36, 1106, b_ware),
        ('industrial_lit', 1499146, 1107, b_industrial), ('substation_lit', N36, 1108, b_substation)]
CUES = [('cue_first_light', 60 * SR, 1201, c_first_light), ('cue_grid_cascade', 90 * SR, 1202, c_cascade),
        ('cue_victory', 120 * SR, 1203, c_victory)]
def loud_json(path):
    p = subprocess.run([FF, '-hide_banner', '-nostats', '-i', path, '-af',
                        'loudnorm=I=-18:TP=-1.8:LRA=11:print_format=json', '-f', 'null', '-'],
                       capture_output=True, text=True)
    txt = p.stderr
    js = txt[txt.rindex('{'):txt.rindex('}') + 1]
    return json.loads(js)
def render_one(name, N, seed, fn):
    rng = np.random.default_rng(seed)
    y = fn(rng)
    assert len(y) == N, (name, len(y), N)
    y = edge_zero(norm_peak(y, -3.0))
    wav = os.path.join(M_D, name + '.wav')
    sf.write(wav, (y * 32767).astype(np.int16), SR)
    m = loud_json(wav)
    af = ('loudnorm=I=-18:TP=-1.8:LRA=11:measured_I=%s:measured_TP=%s:measured_LRA=%s'
          ':measured_thresh=%s:offset=%s:linear=true' % (m['input_i'], m['input_tp'],
           m['input_lra'], m['input_thresh'], m['target_offset']))
    ogg = os.path.join(O_D, name + '.ogg')
    subprocess.run([FF, '-hide_banner', '-loglevel', 'error', '-y', '-i', wav,
                    '-af', af, '-c:a', 'libvorbis', '-q:a', '4', ogg], check=True)
    # verify on decode
    dec = os.path.join(M_D, name + '.dec.wav')
    subprocess.run([FF, '-hide_banner', '-loglevel', 'error', '-y', '-i', ogg,
                    '-ac', '1', '-ar', '44100', '-c:a', 'pcm_s16le', dec], check=True)
    x, _ = sf.read(dec, dtype='float64'); x = x - np.mean(x)
    v = loud_json(dec)
    rep = {'name': name, 'N': N, 'dur': N / SR,
           'm1': {k: m[k] for k in ('input_i', 'input_tp', 'input_lra', 'target_offset')},
           'post': {k: v[k] for k in ('input_i', 'input_tp', 'input_lra')},
           'peak_db': float(20 * np.log10(np.max(np.abs(x)) + 1e-12)),
           'rms_db': float(10 * np.log10(np.mean(x ** 2) + 1e-12)),
           'x0': float(x[0]), 'xN': float(x[-1]),
           'ogg_bytes': os.path.getsize(ogg)}
    print(json.dumps(rep))
    return rep
def main(which):
    items = BEDS if which == 'beds' else CUES if which == 'cues' else BEDS + CUES
    reps = [render_one(n, N, s, f) for n, N, s, f in items]
    with open(os.path.join(WORK, 'report_%s.json' % which), 'w') as f:
        json.dump(reps, f, indent=1)
if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'all')
