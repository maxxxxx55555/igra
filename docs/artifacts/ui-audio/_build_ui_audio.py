#!/usr/bin/env python3
"""
UI AUDIO PACK v2 — CC0 source -> OGG Vorbis 44.1k mono q4 conversion
Owner: ASSETS agent, NEW session UI AUDIO PACK v2
Contract: <=3s, no voices, dark brass/wood mood, no casino shine
Sources: Kenney UI Audio (CC0) + romainsimon/uisfx zen pack (CC0)
"""
import os, subprocess, json, pathlib, shutil, math, struct
import numpy as np
import soundfile as sf
import imageio_ffmpeg

FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
FFPROBE = FFMPEG.replace("ffmpeg","ffprobe")
# fallback: use ffmpeg for probe via: ffmpeg -i etc. But we can also use soundfile for decode and stdlib Ogg parse
# For header verification we will implement stdlib Ogg/Vorbis parse independent of ffmpeg.

# Define mapping: 7 ui sounds
# Each entry: target_name, source_path (local cloned), origin_url, license_url, description, contract_notes
SOURCES = [
    {
        "target": "ui_menu_click.ogg",
        "cue": "menu_click (soft mechanical)",
        "source": "/tmp/kenney_ui/addons/kenney_ui_audio/click1.wav",
        "origin": "https://github.com/Calinou/kenney-ui-audio (mirror of https://kenney.nl/assets/ui-audio)",
        "license": "CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/",
        "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
        "attribution": "none required (CC0) — Kenney (kenney.nl)",
        "notes": "Soft mechanical click, 0.103s source, dark neutral, no shine, no voice",
    },
    {
        "target": "ui_achievement_sting.ogg",
        "cue": "achievement_sting (warm 2-note)",
        "source": "/tmp/uisfx/packages/uisfx/sounds/zen/achievement.ogg",
        "origin": "https://github.com/romainsimon/uisfx — packages/uisfx/sounds/zen/achievement.ogg",
        "license": "CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/",
        "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
        "attribution": "none required (CC0) — Yuki Capital / romainsimon/uisfx (zen pack: warm wood, quiet chimes)",
        "notes": "Warm 2-note sting, 0.911s Opus source, zen pack dark wood, no casino shine, no voice",
    },
    {
        "target": "ui_secret_discovery_sting.ogg",
        "cue": "secret_discovery_sting (mysterious chime)",
        "source": "/tmp/uisfx/packages/uisfx/sounds/zen/unlock.ogg",
        "origin": "https://github.com/romainsimon/uisfx — packages/uisfx/sounds/zen/unlock.ogg",
        "license": "CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/",
        "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
        "attribution": "none required (CC0) — Yuki Capital / romainsimon/uisfx (zen: paper folds, soft brush, warm wood)",
        "notes": "Mysterious chime, 0.393s Opus, zen pack quiet chimes, dark, no shine",
    },
    {
        "target": "ui_daily_complete_sting.ogg",
        "cue": "daily_complete_sting (short uplift)",
        "source": "/tmp/uisfx/packages/uisfx/sounds/zen/complete.ogg",
        "origin": "https://github.com/romainsimon/uisfx — packages/uisfx/sounds/zen/complete.ogg",
        "license": "CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/",
        "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
        "attribution": "none required (CC0) — Yuki Capital / romainsimon/uisfx",
        "notes": "Short uplift complete, 0.637s, zen warm restraint, short <=3s",
    },
    {
        "target": "ui_streak_milestone_sting.ogg",
        "cue": "streak_milestone_sting (subdued triumphant)",
        "source": "/tmp/uisfx/packages/uisfx/sounds/zen/streak.ogg",
        "origin": "https://github.com/romainsimon/uisfx — packages/uisfx/sounds/zen/streak.ogg",
        "license": "CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/",
        "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
        "attribution": "none required (CC0) — Yuki Capital / romainsimon/uisfx",
        "notes": "Subdued triumphant streak, 0.584s, zen warm wood, not casino",
    },
    {
        "target": "ui_boss_sting.ogg",
        "cue": "boss_sting (low brass hit)",
        "source": "/tmp/uisfx/packages/uisfx/sounds/zen/error.ogg",
        "origin": "https://github.com/romainsimon/uisfx — packages/uisfx/sounds/zen/error.ogg",
        "license": "CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/",
        "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
        "attribution": "none required (CC0) — Yuki Capital / romainsimon/uisfx",
        "notes": "Low brass hit, 0.481s, cent 429Hz darkest zen cue, dark brass, no voice",
    },
    {
        "target": "ui_ending_sting.ogg",
        "cue": "ending_sting (resolved warm chord)",
        "source": "/tmp/uisfx/packages/uisfx/sounds/zen/success.ogg",
        "origin": "https://github.com/romainsimon/uisfx — packages/uisfx/sounds/zen/success.ogg",
        "license": "CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/",
        "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
        "attribution": "none required (CC0) — Yuki Capital / romainsimon/uisfx",
        "notes": "Resolved warm chord, 0.571s, cent 567Hz, warm wood zen decay, no casino shine",
    },
]

OUT_DIR = "assets/audio/ui"
ARTIFACT_DIR = "docs/artifacts/ui-audio"

os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(ARTIFACT_DIR, exist_ok=True)
os.makedirs(os.path.join(ARTIFACT_DIR,"sources"), exist_ok=True)

def transcode_to_vorbis(src, dst):
    # Convert any input (wav or opus ogg) to OGG Vorbis q4 mono 44.1k
    # Use ffmpeg: -y -i src -ac 1 -ar 44100 -c:a libvorbis -q:a 4
    # menu_click is hot: attenuate -6dB to tame peak and keep dark
    extra = []
    if "ui_menu_click" in dst:
        extra = ["-filter:a", "volume=-6dB"]
    cmd = [FFMPEG, "-y", "-v", "error", "-i", src, "-ac", "1", "-ar", "44100"] + extra + ["-c:a", "libvorbis", "-q:a", "4", dst]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"FFMPEG FAIL {src} -> {dst}: {result.stderr}")
        raise RuntimeError(result.stderr)
    # verify output exists
    assert os.path.exists(dst), f"missing {dst}"

def ogg_header_parse(path):
    # Minimal Ogg/Vorbis header parse using stdlib only (independent verification)
    # Reads Ogg page structure and Vorbis identification header
    # Returns dict: channels, sample_rate, granule, length_seconds, codec (vorbis/opus)
    with open(path, 'rb') as f:
        data = f.read()
    # Find OggS signatures
    if data[:4] != b'OggS':
        return {"error": "not OggS"}
    pos = 0
    pages = []
    granules = []
    # Simple page walk
    idx = 0
    while idx < len(data):
        if data[idx:idx+4] != b'OggS':
            idx += 1
            continue
        if idx+27 > len(data):
            break
        version = data[idx+4]
        header_type = data[idx+5]
        granule = struct.unpack('<Q', data[idx+6:idx+14])[0]
        serial = struct.unpack('<I', data[idx+14:idx+18])[0]
        seq = struct.unpack('<I', data[idx+18:idx+22])[0]
        crc = data[idx+22:idx+26]
        segments = data[idx+26]
        if idx+27+segments > len(data):
            break
        seg_table = data[idx+27: idx+27+segments]
        header_len = 27 + segments
        body_len = sum(seg_table)
        total_len = header_len + body_len
        pages.append((idx, granule, header_type, body_len))
        granules.append(granule)
        idx += total_len
    # Identify codec from first page body
    # Vorbis identification header starts with 0x01 'vorbis'
    # Opus header starts with 'OpusHead'
    codec = "unknown"
    channels = None
    sample_rate = None
    # extract first packet
    if pages:
        first_page_idx = pages[0][0]
        segments = data[first_page_idx+26]
        header_len = 27 + segments
        body = data[first_page_idx+header_len: first_page_idx+header_len+pages[0][3]]
        if body.startswith(b'\x01vorbis'):
            codec = "vorbis"
            # Vorbis id header: 0x01 + 'vorbis' (6) + version(4) + channels(1) + sample_rate(4) + ...
            if len(body) >= 11+1+4:
                channels = body[11]
                sample_rate = struct.unpack('<I', body[12:16])[0]
        elif body.startswith(b'OpusHead'):
            codec = "opus"
            # OpusHead: 8 bytes magic + version 1 + channels 1 + pre-skip 2 + input_sample_rate 4 + output_gain 2 + mapping_family 1
            if len(body) >= 9+1:
                channels = body[9]
                # input sample rate is at offset 12 (4 bytes)
                if len(body) >= 16:
                    sample_rate = struct.unpack('<I', body[12:16])[0]
                    # For Opus, sample_rate in header is input sr (usually 48000), actual decode rate is 48000 regardless
        # Try to get granule of last page (total samples)
        last_granule = granules[-1] if granules else 0
        # For Vorbis, granule is samples decoded at nominal rate; for Opus 48000.
        if codec == "vorbis" and sample_rate:
            length = last_granule / sample_rate if sample_rate else 0
        elif codec == "opus":
            # Opus granule is at 48000, per spec
            # But if header says input 48000, still 48000
            length = last_granule / 48000.0
        else:
            length = 0
        return {"codec": codec, "channels": channels, "sample_rate": sample_rate, "granule": last_granule, "length": length, "pages": len(pages)}
    return {"error": "no pages"}

print("=== UI Audio Build v2 ===")
print(f"FFMPEG: {FFMPEG}")
# Test ffmpeg version
subprocess.run([FFMPEG, "-version"], check=False)
# Transcode each
for src in SOURCES:
    dst = os.path.join(OUT_DIR, src["target"])
    print(f"Transcode {src['source']} -> {dst} ({src['cue']})")
    transcode_to_vorbis(src["source"], dst)
    # also copy original source to artifacts/sources for provenance
    artifact_src = os.path.join(ARTIFACT_DIR,"sources", src["target"].replace(".ogg","_src")+os.path.splitext(src["source"])[1])
    shutil.copy(src["source"], artifact_src)
    print(f"  copied source artifact {artifact_src}")

# After transcode, verify headers via soundfile and ogg parse
print("\n=== Header Verify (soundfile + ogg parse) ===")
rows = []
for src in SOURCES:
    path = os.path.join(OUT_DIR, src["target"])
    info = sf.info(path)
    dur = info.frames / info.samplerate
    size = os.path.getsize(path)
    # ogg parse
    ogg = ogg_header_parse(path)
    # decode for peak/rms
    data, sr = sf.read(path, dtype='float32')
    if data.ndim > 1:
        data = data.mean(axis=1)
    peak = float(np.max(np.abs(data))) if len(data)>0 else 0
    peak_db = 20*np.log10(peak+1e-12)
    rms = float(np.sqrt(np.mean(data**2))) if len(data)>0 else 0
    rms_db = 20*np.log10(rms+1e-12)
    rows.append({
        "target": src["target"],
        "cue": src["cue"],
        "path": path,
        "frames": info.frames,
        "samplerate": info.samplerate,
        "channels": info.channels,
        "duration": dur,
        "size": size,
        "codec": ogg.get("codec"),
        "ogg_rate": ogg.get("sample_rate"),
        "ogg_ch": ogg.get("channels"),
        "ogg_granule": ogg.get("granule"),
        "peak": peak,
        "peak_db": peak_db,
        "rms_db": rms_db
    })
    print(f"{src['target']:30} {dur:.3f}s {info.channels}ch {info.samplerate}Hz codec={ogg.get('codec')} ogg_ch={ogg.get('channels')} ogg_rate={ogg.get('sample_rate')} peak={peak_db:.1f}dB rms={rms_db:.1f}dB size={size} granule={ogg.get('granule')}")

# Write JSON artifact
with open(os.path.join(ARTIFACT_DIR,"header_report.json"), "w") as f:
    json.dump(rows, f, indent=2)

# Write peak table CSV
import csv
with open(os.path.join(ARTIFACT_DIR,"peak_table.csv"), "w", newline="") as f:
    w=csv.writer(f)
    w.writerow(["file","cue","duration_s","channels","samplerate","codec","granule","size_bytes","peak_dBFS","rms_dBFS"])
    for r in rows:
        w.writerow([r["target"], r["cue"], f"{r['duration']:.3f}", r["channels"], r["samplerate"], r["codec"], r["ogg_granule"], r["size"], f"{r['peak_db']:.2f}", f"{r['rms_db']:.2f}"])

# Generate contact sheet image (simple PIL)
try:
    from PIL import Image, ImageDraw, ImageFont
    W, H = 1200, 800
    img = Image.new("RGB", (W, H), color="#0c1016")
    draw = ImageDraw.Draw(img)
    # try load font
    try:
        font = ImageFont.load_default()
    except:
        font = None
    draw.text((20,10), "UI AUDIO PACK v2 — Contact Sheet (7 waveforms, peak table)", fill="#d8d2c4", font=font)
    draw.text((20,30), f"Generated {len(rows)} files • OGG Vorbis q4 mono 44.1k • Contract <=3s no voices dark brass/wood", fill="#6a6a7a", font=font)
    # draw waveform thumbnails
    y0 = 60
    thumb_w, thumb_h = 340, 80
    x_gap, y_gap = 20, 20
    cols=3
    for idx, r in enumerate(rows):
        col = idx % cols
        row = idx // cols
        x = 20 + col*(thumb_w + x_gap)
        y = y0 + row*(thumb_h + 40)
        # background
        draw.rectangle([x, y, x+thumb_w, y+thumb_h], outline="#2a3340", fill="#141b24")
        # waveform
        path = r["path"]
        data, sr = sf.read(path, dtype='float32')
        if data.ndim>1:
            data=data.mean(axis=1)
        # downsample to thumb_w
        step = max(1, len(data)//thumb_w)
        pts = []
        for i in range(thumb_w):
            s = int(i*len(data)/thumb_w)
            e = int((i+1)*len(data)/thumb_w)
            chunk = data[s:e] if e> s else data[s:s+1]
            if len(chunk)==0:
                v=0
            else:
                v = float(np.max(np.abs(chunk)))
            # y mapping: center +/- v*height
            py_top = y + thumb_h//2 - int(v * thumb_h//2)
            py_bot = y + thumb_h//2 + int(v * thumb_h//2)
            pts.append((x+i, py_top, py_bot, v))
        for i, (px, py1, py2, v) in enumerate(pts):
            # color brass #c9a24a with opacity by v
            draw.line([px, py1, px, py2], fill="#c9a24a")
        # label
        label = f"{r['target']}  {r['duration']:.3f}s  peak {r['peak_db']:.1f}dB"
        draw.text((x, y+thumb_h+2), label, fill="#d8d2c4", font=font)
        # cue
        draw.text((x, y+thumb_h+14), r["cue"], fill="#6a6a7a", font=font)
    # footer
    draw.text((20, H-20), "dark brass/wood mood • no casino shine • CC0 sources: Kenney + uisfx (zen pack)", fill="#6a6a7a", font=font)
    img.save(os.path.join(ARTIFACT_DIR,"contact_sheet.png"))
    print("contact_sheet.png generated")
except Exception as e:
    print(f"PIL contact sheet failed: {e}")
    import traceback
    traceback.print_exc()

print("\n=== Done ===")
