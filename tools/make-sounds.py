"""Generate the plugin's sound packs into sounds/<pack>/. Standard library only.

Run from the repository root: python tools/make-sounds.py
Every sound is synthesized here, so the WAV files carry no third-party rights.
"""

import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "sounds"


def note(freq, start, length, volume=0.5, decay=6.0):
    return (freq, start, length, volume, decay)


def bell(freq, t):
    """A sine with one overtone: a soft bell."""
    return (math.sin(2 * math.pi * freq * t) + 0.25 * math.sin(4 * math.pi * freq * t)) / 1.25


def sine(freq, t):
    return math.sin(2 * math.pi * freq * t)


def square(freq, t):
    """A softened square wave (first three odd harmonics): an 8-bit blip."""
    w = 2 * math.pi * freq * t
    return (math.sin(w) + math.sin(3 * w) / 3 + math.sin(5 * w) / 5) / 1.53


def render(notes, total, wave_fn):
    samples = [0.0] * int(RATE * total)
    for freq, start, length, volume, decay in notes:
        first = int(RATE * start)
        for i in range(int(RATE * length)):
            if first + i >= len(samples):
                break
            t = i / RATE
            attack = min(1.0, t / 0.005)  # 5 ms fade-in avoids a click
            samples[first + i] += volume * attack * math.exp(-decay * t) * wave_fn(freq, t)
    return samples


def save(path, samples, loudness):
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = loudness / peak
    frames = b"".join(struct.pack("<h", int(s * scale * 32767)) for s in samples)
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(frames)


# Each sound: done = rising, attention = two quick notes, error = falling.
PACKS = {
    "chime": (bell, 0.9, {
        "done": ([note(659.25, 0.0, 0.5), note(830.61, 0.12, 0.6)], 0.75),
        "attention": ([note(880.0, 0.0, 0.25, decay=10), note(880.0, 0.18, 0.4, decay=8)], 0.6),
        "error": ([note(392.0, 0.0, 0.3, decay=7), note(311.13, 0.16, 0.55, decay=5)], 0.75),
    }),
    "soft": (sine, 0.6, {
        "done": ([note(523.25, 0.0, 0.9, decay=3.5), note(659.25, 0.2, 1.0, decay=3)], 1.2),
        "attention": ([note(587.33, 0.0, 0.5, decay=6), note(587.33, 0.3, 0.7, decay=5)], 1.0),
        "error": ([note(349.23, 0.0, 0.6, decay=4), note(293.66, 0.25, 0.9, decay=3)], 1.2),
    }),
    "arcade": (square, 0.55, {
        "done": ([note(523.25, 0.0, 0.08, decay=4), note(659.25, 0.08, 0.08, decay=4),
                  note(783.99, 0.16, 0.08, decay=4), note(1046.5, 0.24, 0.25, decay=8)], 0.5),
        "attention": ([note(987.77, 0.0, 0.07, decay=4), note(987.77, 0.12, 0.07, decay=4)], 0.25),
        "error": ([note(392.0, 0.0, 0.12, decay=4), note(277.18, 0.12, 0.12, decay=4),
                   note(196.0, 0.24, 0.3, decay=6)], 0.55),
    }),
}

if __name__ == "__main__":
    for pack, (wave_fn, loudness, sounds) in PACKS.items():
        for name, (notes, total) in sounds.items():
            save(OUT / pack / f"{name}.wav", render(notes, total, wave_fn), loudness)
            print(f"sounds/{pack}/{name}.wav")
