"""Generate the plugin's sounds into sounds/. Standard library only.

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
    """A soft bell-like tone: a sine with one overtone and an exponential fade."""
    return (freq, start, length, volume, decay)


def render(notes, total):
    samples = [0.0] * int(RATE * total)
    for freq, start, length, volume, decay in notes:
        first = int(RATE * start)
        for i in range(int(RATE * length)):
            t = i / RATE
            attack = min(1.0, t / 0.005)  # 5 ms fade-in avoids a click
            envelope = attack * math.exp(-decay * t)
            value = math.sin(2 * math.pi * freq * t) + 0.25 * math.sin(4 * math.pi * freq * t)
            if first + i < len(samples):
                samples[first + i] += volume * envelope * value / 1.25
    return samples


def save(name, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = min(1.0, 0.9 / peak)
    frames = b"".join(struct.pack("<h", int(s * scale * 32767)) for s in samples)
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(frames)


SOUNDS = {
    # Rising major third: "done".
    "done.wav": ([note(659.25, 0.0, 0.5), note(830.61, 0.12, 0.6)], 0.75),
    # Two quick notes at the same pitch: "your turn".
    "attention.wav": ([note(880.0, 0.0, 0.25, decay=10), note(880.0, 0.18, 0.4, decay=8)], 0.6),
    # Falling, lower notes: "something went wrong".
    "error.wav": ([note(392.0, 0.0, 0.3, decay=7), note(311.13, 0.16, 0.55, decay=5)], 0.75),
}

if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    for name, (notes, total) in SOUNDS.items():
        save(name, render(notes, total))
        print(f"sounds/{name}")
