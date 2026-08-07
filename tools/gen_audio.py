#!/usr/bin/env python3
import wave, struct, math, random, os, sys
SR = 22050
PEAK = 0.85
def write_wav(path, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    norm = PEAK / peak
    frames = bytearray()
    for s in samples:
        v = int(max(-32767, min(32767, s * norm * 32767)))
        frames += struct.pack('<h', v)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(bytes(frames))
    print("  -> {0} ({1:.1f}s)".format(path, len(samples)/SR))
def midi_to_freq(m): return 440.0 * 2**((m-69)/12.0)
def env(i,total,a=0.04,r=0.20):
    if total<=0: return 0.0
    t=i/total
    if t<a: return t/max(1e-3,a)
    if t>1.0-r: return max(0.0,(1.0-t)/max(1e-3,r))
    return 1.0
SCALES={'major':[0,2,4,5,7,9,11],'minor':[0,2,3,5,7,8,10],'pentatonic':[0,2,4,7,9],
'mixolydian':[0,2,4,5,7,9,10],'phrygdom':[0,1,4,5,7,8,11],'lydian':[0,2,4,6,7,9,11],
'blues':[0,3,5,6,7,10],'wholetone':[0,2,4,6,8,10],'dorian':[0,2,3,5,7,9,10]}
DISTRICTS=[('suburbs','pentatonic',90,60,14,0.22,0.16,0.10),('residential','major',80,62,14,0.22,0.14,0.12),
('park','lydian',75,60,14,0.20,0.12,0.12),('school','major',100,64,14,0.22,0.18,0.10),
('hospital','wholetone',60,54,10,0.14,0.12,0.10),('gas_station','blues',110,52,16,0.22,0.18,0.08),
('police','minor',120,53,14,0.18,0.22,0.08),('warehouses','dorian',75,48,12,0.14,0.22,0.10),
('industrial','minor',85,46,12,0.16,0.24,0.10),('substation','phrygdom',100,50,14,0.20,0.20,0.10),
('power_station','mixolydian',105,55,14,0.24,0.20,0.12)]
def synth(freq,dur_s,lt='sine'):
    n=int(SR*dur_s); out=[0.0]*n
    for i in range(n):
        t=i/SR; e=env(i,n); p=2*math.pi*freq*t
        if lt=='sine': s=math.sin(p)
        elif lt=='tri': s=2.0/math.pi*math.asin(max(-1.0,min(1.0,math.sin(p))))
        elif lt=='square': s=1.0 if math.sin(p)>=0 else -1.0
        else: s=math.sin(p)+0.3*math.sin(2*p)
        out[i]=e*s
    return out
def synth_bass(f,d):
    n=int(SR*d); out=[0.0]*n
    for i in range(n):
        t=i/SR; e=env(i,n,a=0.01,r=0.30); p=2*math.pi*f*t
        s=math.sin(p); out[i]=e*(1.0 if s>0 else -1.0)
    return out
def synth_pad(f,d):
    n=int(SR*d); out=[0.0]*n
    for i in range(n):
        t=i/SR; e=env(i,n,a=0.20,r=0.40); p=2*math.pi*f*t
        out[i]=e*(0.6*math.sin(p)+0.3*math.sin(2*p)+0.1*math.sin(3*p))
    return out
def mix(base,add,off=0,amp=1.0):
    if off<0: off=0
    end=min(len(base),off+len(add))
    for i in range(off,end): base[i]+=amp*add[i-off]
def gen_district(prof):
    name,sc,bpm,rm,bars,la,ba,pa=prof
    scale=SCALES[sc]; beat=60.0/bpm; ts=beat*4*bars; tn=int(SR*ts)
    base=[0.0]*tn; rng=random.Random(hash((name,sc))&0xFFFFFFFF)
    for bar in range(bars):
        deg=rng.choice([0,0,4,5,3])
        for bi in [0,2]:
            t=(bar*4+bi)*beat; midi=(rm-12)+scale[deg%len(scale)]
            if rng.random()<0.25: midi-=12
            mix(base,synth_bass(midi_to_freq(midi),beat*1.8),int(t*SR),ba)
    lt='saw' if sc in ('blues','phrygdom') else 'tri' if sc in ('wholetone','minor') else 'sine'
    for bar in range(bars):
        for bi in range(4):
            if rng.random()<0.30: continue
            deg=rng.randint(0,len(scale)*2); t=(bar*4+bi)*beat
            midi=rm+scale[deg%len(scale)]+12*(deg//len(scale))
            dur=beat*rng.choice([0.5,1.0,1.5,2.0])
            mix(base,synth(midi_to_freq(midi),dur,lt),int(t*SR),la)
    for bar in range(0,bars,2):
        cd=rng.choice([0,3,4]); t=bar*4*beat; dur=4*beat*2
        for v in [0,4,7]:
            midi=rm+scale[cd%len(scale)]+v
            mix(base,synth_pad(midi_to_freq(midi),dur),int(t*SR),pa/3.0)
    return base
def gen_ambient():
    n=int(SR*45); out=[0.0]*n; rng=random.Random(2024)
    for L in range(3):
        f=55+L*33
        for i in range(n):
            t=i/SR; e=0.5+0.5*math.sin(2*math.pi*0.07*t+L); p=2*math.pi*f*t
            out[i]+=0.06*e*(math.sin(p)+0.3*math.sin(2*p))
    last=0.0
    for i in range(n): w=rng.uniform(-0.02,0.02); last=0.98*last+w; out[i]+=last
    return out
def gen_ui(kind):
    if kind=='click': dur,freqs=0.08,[(880,0.0,0.04),(1320,0.04,0.04)]
    elif kind=='hover': dur,freqs=0.06,[(660,0.0,0.06)]
    elif kind=='pickup': freqs=[(523,0.0,0.05),(784,0.06,0.08),(1046,0.13,0.10)]; dur=0.24
    elif kind=='deny': freqs=[(220,0.0,0.05),(165,0.07,0.10)]; dur=0.18
    elif kind=='stinger': dur=1.20; freqs=[(110,0.0,0.20),(110,0.25,0.20),(87,0.50,0.30),(65,0.80,0.40)]
    else: dur,freqs=0.10,[(440,0.0,0.10)]
    n=int(SR*dur); out=[0.0]*n
    for f,t0,td in freqs:
        for i in range(int(t0*SR),min(int((t0+td)*SR),n)):
            t=(i-int(t0*SR))/SR; e=math.exp(-4*t/max(0.05,td)); p=2*math.pi*f*t
            out[i]+=0.5*e*(math.sin(p)+0.2*math.sin(2*p))
    return out
def main(root):
    music=os.path.join(root,'audio','music'); amb=os.path.join(root,'audio','ambient'); sfx=os.path.join(root,'audio','sfx')
    for d in [music,amb,sfx]: os.makedirs(d,exist_ok=True)
    for p in DISTRICTS: write_wav(os.path.join(music,p[0]+'.wav'),gen_district(p))
    write_wav(os.path.join(amb,'ambient.wav'),gen_ambient())
    for k in ['click','hover','pickup','deny']: write_wav(os.path.join(sfx,k+'.wav'),gen_ui(k))
    write_wav(os.path.join(sfx,'stinger.wav'),gen_ui('stinger'))
    print("[gen_audio] done: 11 music + ambient + 5 sfx = 17 files")
if __name__=='__main__': main(sys.argv[1] if len(sys.argv)>1 else '.')