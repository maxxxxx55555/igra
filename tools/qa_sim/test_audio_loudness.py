"""Real-decoder regressions for the release audio gate."""
import math
import pathlib
import shutil
import struct
import tempfile
import unittest
import wave
from unittest.mock import patch

import audio_loudness


def write_short_wav(path):
    with wave.open(str(path), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(44100)
        samples = (int(3000 * math.sin(2 * math.pi * 440 * i / 44100)) for i in range(4410))
        stream.writeframes(b"".join(struct.pack("<h", sample) for sample in samples))


@unittest.skipUnless(shutil.which("ffmpeg"), "ffmpeg is required")
class DecoderTests(unittest.TestCase):
    def test_corrupt_audio_cannot_be_reported_as_a_gated_short_sound(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "corrupt-ui.ogg"
            path.write_bytes(b"not an audio stream")
            with self.assertRaisesRegex(RuntimeError, "corrupt-ui.ogg"):
                audio_loudness.measure(audio_loudness.ffmpeg(), path)

    def test_short_valid_sound_keeps_peak_and_mean_measurements(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "short-ui.wav"
            write_short_wav(path)
            loudness, peak, mean = audio_loudness.measure(audio_loudness.ffmpeg(), path)
            self.assertIsNone(loudness)
            self.assertIsNotNone(peak)
            self.assertIsNotNone(mean)
            self.assertLess(peak, -15.0)
            self.assertLess(mean, peak)

    def test_audio_outside_named_categories_is_still_measured(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            path = root / "assets/audio/ending_music/ending.wav"
            path.parent.mkdir(parents=True)
            write_short_wav(path)
            with patch.object(audio_loudness, "ROOT", root):
                rows = audio_loudness.collect(audio_loudness.ffmpeg())
            measured = [row for category in rows.values() for row in category]
            self.assertEqual(len(measured), 1)
            self.assertEqual(measured[0][0], "assets/audio/ending_music/ending.wav")
            self.assertIsNotNone(measured[0][2])


if __name__ == "__main__":
    unittest.main()
