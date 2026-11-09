"""Master the verified Scott Buckley downloads with the existing music_post recipe.

Usage: python tools/qa_sim/master_licensed_music.py SOURCE_DIRECTORY REPORT_JSON
Downloads remain outside the repository; published source URLs are in ASSET_LICENSES.md.
"""
import hashlib
import json
from pathlib import Path
import sys

import numpy as np
import audio_loudness
import music_post

ROOT = Path(__file__).resolve().parents[2]
SOURCES = [
    ('hymn', 4855797, '65a0b4ee666c26d72cb6faeaaf2215f9516924a9bdbf01008cd642cbad4ba125'),
    ('moonlight', 10177523, '7feb8c703983dbdfc97018f004cfebad8f03b86f2382c58c0ad24e375d4c17f5'),
]


def master(source_dir, report):
    rows = []
    for name, size, digest in SOURCES:
        source = source_dir / (name + '.mp3')
        data = source.read_bytes()
        if len(data) != size or hashlib.sha256(data).hexdigest() != digest:
            raise ValueError('Refuse an incomplete or changed source: ' + str(source))
        raw = music_post.decode(source)
        assert np.isfinite(raw).all() and np.max(np.abs(raw)) > 0.01
        # Keep the composition except the two seconds overlapping its tail into its head.
        seconds = (len(raw) - 2 * music_post.SR) / music_post.SR
        target = ROOT / ('assets/audio/music/scott_buckley_' + name + '.ogg')
        loop = music_post.edge_fade(music_post.cut(raw, 0.0, seconds, False), 3.0)
        lufs, peak, duration = music_post.encode(loop, target, -18.0, -1.5)
        decoded = music_post.decode(target)
        step = audio_loudness.seam_step(decoded)
        assert abs(lufs + 18.0) <= 0.2 and peak <= -1.5
        assert abs(duration - seconds) < 0.01 and step <= audio_loudness.SEAM_LIMIT
        assert np.isfinite(decoded).all() and np.max(np.abs(decoded)) < 1.0
        row = dict(title=name.title(), artist='Scott Buckley', source_bytes=size,
                   source_sha256=digest, path=target.relative_to(ROOT).as_posix(),
                   bytes=target.stat().st_size, sha256=hashlib.sha256(target.read_bytes()).hexdigest(),
                   seconds=duration, lufs=lufs, true_peak_dbfs=peak, seam_step=step,
                   recipe='Mono 44.1 kHz, 2s circular overlap, 3ms edge guards, -18 LUFS, Vorbis q4; no pitch/tempo change.',
                   perceptual_audition='NOT_PERFORMED_MODEL_AUDIO_INPUT_UNAVAILABLE')
        rows.append(row)
        print(json.dumps(row), flush=True)
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps(rows, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    master(Path(sys.argv[1]), Path(sys.argv[2]))
