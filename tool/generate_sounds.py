"""Генерирует короткие локальные WAV-звуки (без сторонних лицензий)."""
from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "assets" / "sounds"
RATE = 44100
random.seed(7)


def env(i: int, n: int, attack: float = 0.008, release: float = 0.08) -> float:
    t = i / RATE
    a = min(1.0, t / attack) if attack else 1.0
    r = min(1.0, (n - i) / (release * RATE)) if release else 1.0
    return max(0.0, min(a, r))


def tone(freq: float, dur: float, amp: float = 0.3, harmonic: float = 0.0) -> list[float]:
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        value = math.sin(2 * math.pi * freq * t)
        if harmonic:
            value += harmonic * math.sin(2 * math.pi * freq * 2.01 * t)
        out.append(amp * value * env(i, n))
    return out


def mix(a: list[float], b: list[float], offset: float = 0.0) -> list[float]:
    start = int(offset * RATE)
    size = max(len(a), start + len(b))
    out = [0.0] * size
    for i, v in enumerate(a):
        out[i] += v
    for i, v in enumerate(b):
        out[start + i] += v
    return out


def write(name: str, samples: list[float]) -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    peak = max(1e-9, max(abs(x) for x in samples))
    norm = min(1.0, 0.82 / peak)
    frames = b"".join(struct.pack("<h", int(max(-1, min(1, x * norm)) * 32767)) for x in samples)
    with wave.open(str(ROOT / name), "wb") as fh:
        fh.setnchannels(1)
        fh.setsampwidth(2)
        fh.setframerate(RATE)
        fh.writeframes(frames)


def main() -> None:
    # Тихий деревянный ход: короткий низкий щелчок + тон.
    click = [random.uniform(-1, 1) * math.exp(-i / 400) * 0.25 for i in range(700)]
    write("move.wav", mix(tone(330, 0.09, 0.32), click, 0.0)[:5000])

    # Взятие: ниже и плотнее.
    noise = [random.uniform(-1, 1) * math.exp(-i / 900) * 0.38 for i in range(2600)]
    write("capture.wav", mix(tone(150, 0.14, 0.42, 0.3), noise, 0.005)[:7000])

    # Шах: два быстрых сигнала.
    write("check.wav", mix(tone(660, 0.085, 0.33), tone(880, 0.10, 0.32), 0.09))

    # Мат: нисходящее созвучие.
    out = mix(tone(523.25, 0.22, 0.28), tone(392.0, 0.26, 0.28), 0.12)
    out = mix(out, tone(261.63, 0.34, 0.30), 0.28)
    write("mate.wav", out)

    print("sounds:", ", ".join(sorted(p.name for p in ROOT.glob("*.wav"))))


if __name__ == "__main__":
    main()
