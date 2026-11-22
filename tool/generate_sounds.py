"""Generates all Superhero Showdown sound effects and music.

Every sound is synthesised from scratch (sine, square and filtered noise),
so all audio in the game is original. Re-run after tweaking:

    python3 tool/generate_sounds.py

Requires numpy. Writes 22.05 kHz mono 16-bit WAV files to assets/audio/.
"""
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
rng = np.random.default_rng(7)


def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def env(n, attack=0.005, release=None, curve=4.0):
    """Fast attack, exponential decay envelope."""
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    dur = n / SR
    d = np.exp(-curve * t / dur) if release is None else np.exp(-t / release)
    return a * d


def sweep(f0, f1, dur, shape='sine'):
    t = t_axis(dur)
    f = f0 * (f1 / f0) ** (t / dur)
    ph = 2 * np.pi * np.cumsum(f) / SR
    if shape == 'square':
        return np.sign(np.sin(ph)) * 0.6
    if shape == 'tri':
        return 2 / np.pi * np.arcsin(np.sin(ph))
    return np.sin(ph)


def tone(freq, dur, shape='sine'):
    return sweep(freq, freq * 1.0001, dur, shape)


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def seq(*parts, gap=0.0):
    g = np.zeros(int(SR * gap))
    out = []
    for p in parts:
        out += [p, g]
    return np.concatenate(out)


def save(name, x, peak=0.6):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) or 1
    x = x / m * peak
    # 4 ms fade in/out to avoid clicks.
    f = min(int(SR * 0.004), len(x) // 2)
    x[:f] *= np.linspace(0, 1, f)
    x[-f:] *= np.linspace(1, 0, f)
    data = (x * 32767).astype('<i2').tobytes()
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)


NOTE = {n: 440 * 2 ** ((i - 9) / 12) for i, n in enumerate(
    ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'])}


def note(name):
    """'C4', 'G#3' ... -> Hz"""
    pitch, octave = name[:-1], int(name[-1])
    return NOTE[pitch] * 2 ** (octave - 4)


def pluck(freq, dur, shape='square', decay=6.0, vol=1.0):
    x = tone(freq, dur, shape)
    return x * env(len(x), 0.004, curve=decay) * vol


# ---- Sound effects ------------------------------------------------------

def sfx():
    # Punch: soft cartoon "boff".
    n = 0.12
    save('punch', mix(sweep(220, 90, n) * env(int(SR * n), curve=7),
                      lowpass(noise(n), 1800) * env(int(SR * n), curve=12) * 0.8))
    # Kick: deeper thump with a little whoosh in front.
    whoosh = highpass(noise(0.08), 1500) * np.linspace(0, 1, int(SR * 0.08)) * 0.4
    n = 0.16
    save('kick', seq(whoosh, mix(sweep(160, 60, n) * env(int(SR * n), curve=6),
                                 lowpass(noise(n), 1200) * env(int(SR * n), curve=10) * 0.6)))
    # Hit: friendly "bonk".
    n = 0.18
    save('hit', mix(sweep(700, 220, n, 'tri') * env(int(SR * n), curve=5),
                    tone(1400, n) * env(int(SR * n), curve=14) * 0.3))
    # Block: bright shield "tink".
    n = 0.25
    save('block', mix(tone(1650, n) * env(int(SR * n), curve=9),
                      tone(2480, n) * env(int(SR * n), curve=12) * 0.5), peak=0.45)
    # Jump: springy "boing".
    n = 0.26
    t = t_axis(n)
    x = np.sin(2 * np.pi * np.cumsum(320 * (2.2 ** (t / n)) * (1 + 0.04 * np.sin(2 * np.pi * 30 * t))) / SR)
    save('jump', x * env(len(x), curve=3), peak=0.4)
    # Land: soft thud.
    n = 0.09
    save('land', lowpass(noise(n), 500) * env(int(SR * n), curve=8), peak=0.4)
    # Power charge: rising sparkle.
    n = 0.34
    t = t_axis(n)
    x = sweep(400, 1300, n, 'tri') * (0.6 + 0.4 * np.sin(2 * np.pi * 24 * t)) * np.linspace(0.3, 1, len(t))
    save('power_charge', mix(x, sweep(800, 2600, n) * 0.25 * np.linspace(0, 1, len(t))), peak=0.45)
    # Web shot: quick "thwip".
    n = 0.2
    t = t_axis(n)
    x = highpass(noise(n), 2500) * env(len(t), curve=6) + sweep(1800, 600, n) * env(len(t), curve=9) * 0.5
    save('power_web', x, peak=0.5)
    # Night strike: big whoosh.
    n = 0.45
    t = t_axis(n)
    x = lowpass(noise(n), 2500) * np.sin(np.pi * t / n) ** 2 + sweep(200, 500, n) * 0.2 * np.sin(np.pi * t / n)
    save('power_dash', x, peak=0.55)
    # Sun beam: warm rising chord.
    n = 0.7
    t = t_axis(n)
    e = np.minimum(1, t / 0.05) * np.exp(-2.5 * t / n)
    x = (sweep(note('C5'), note('G5'), n, 'tri') + 0.7 * sweep(note('E5'), note('B5'), n, 'tri')
         + 0.5 * sweep(note('G5'), note('D6'), n)) * e
    save('power_beam', x, peak=0.5)
    # Thunder stomp: deep boom and rumble.
    n = 0.7
    t = t_axis(n)
    boom = sweep(110, 40, n) * env(len(t), curve=4)
    rumble = lowpass(noise(n), 300) * env(len(t), curve=3) * 1.5
    save('power_stomp', mix(boom, rumble), peak=0.65)
    # Plasma blast: sci-fi "pew".
    n = 0.3
    save('power_plasma', mix(sweep(1500, 300, n, 'square') * env(int(SR * n), curve=5) * 0.6,
                             sweep(3000, 600, n) * env(int(SR * n), curve=7) * 0.3), peak=0.45)
    # KO: slide whistle down + little twinkles.
    slide = sweep(1200, 300, 0.55, 'tri') * np.linspace(1, 0.6, int(SR * 0.55))
    twinkles = seq(*[pluck(note(n_), 0.14, 'sine', 8) for n_ in ['E6', 'G6', 'C7']])
    save('ko', seq(slide, twinkles), peak=0.5)
    # Victory: cheerful fanfare.
    mel = [('C5', 0.14), ('E5', 0.14), ('G5', 0.14), ('C6', 0.42), ('G5', 0.14), ('C6', 0.6)]
    lead = seq(*[pluck(note(n_), d, 'square', 3.5) for n_, d in mel])
    harm = seq(*[pluck(note(n_) / 2, d, 'tri', 3) for n_, d in mel])
    save('victory', mix(lead, harm * 0.6), peak=0.55)
    # Defeat: gentle, silly "wah-wah" (not sad or scary).
    wah = [pluck(f, 0.32, 'tri', 2.5) for f in (note('G4'), note('F#4'), note('F4'))]
    last = sweep(note('E4'), note('E4') * 0.97, 0.7, 'tri') * env(int(SR * 0.7), curve=2.5) * (1 + 0.15 * np.sin(2 * np.pi * 6 * t_axis(0.7)))
    save('defeat', seq(*wah, last, gap=0.03), peak=0.45)
    # Button tap: soft pop.
    n = 0.07
    save('tap', sweep(900, 500, n) * env(int(SR * n), curve=10), peak=0.35)
    # Ready / Fight chimes.
    save('ready', seq(pluck(note('G5'), 0.18, 'sine', 4), pluck(note('C6'), 0.35, 'sine', 4)), peak=0.45)
    save('fight', mix(seq(pluck(note('C5'), 0.1, 'square', 4), pluck(note('E5'), 0.1, 'square', 4),
                          pluck(note('G5'), 0.45, 'square', 3)),
                      seq(np.zeros(int(SR * 0.2)), pluck(note('C4'), 0.45, 'tri', 3))), peak=0.5)


# ---- Music --------------------------------------------------------------

def drum_kick():
    n = 0.12
    return sweep(150, 50, n) * env(int(SR * n), curve=6)


def drum_hat():
    n = 0.04
    return highpass(noise(n), 6000) * env(int(SR * n), curve=8) * 0.25


def drum_snare():
    n = 0.12
    return (lowpass(noise(n), 4000) * 0.5 + tone(200, n) * 0.3) * env(int(SR * n), curve=8)


def render_track(bpm, bars, melody, bass, chords, drums=True, lead_shape='square'):
    beat = 60 / bpm
    total = int(SR * beat * 4 * bars)
    out = np.zeros(total)

    def put(x, at):
        i = int(SR * at)
        j = min(total, i + len(x))
        out[i:j] += x[: j - i]

    t = 0.0
    for n_, beats in melody:
        if n_ != '-':
            put(pluck(note(n_), beats * beat * 0.95, lead_shape, 3.0, 0.35), t)
        t += beats * beat
    t = 0.0
    for n_, beats in bass:
        put(pluck(note(n_), beats * beat * 0.9, 'tri', 2.0, 0.55), t)
        t += beats * beat
    for bar, chord in enumerate(chords):
        for k in range(4):
            for j, n_ in enumerate(chord):
                put(pluck(note(n_), beat * 0.45, 'tri', 5, 0.08), (bar * 4 + k + 0.5) * beat + j * 0.01)
    if drums:
        for b in range(bars * 4):
            at = b * beat
            if b % 2 == 0:
                put(drum_kick() * 0.6, at)
            else:
                put(drum_snare() * 0.35, at)
            put(drum_hat(), at + beat / 2)
    return out


def music():
    # Battle: upbeat, original 8-bar loop in C major.
    melody = [
        ('E5', .5), ('G5', .5), ('A5', 1), ('G5', .5), ('E5', .5), ('D5', 1),
        ('C5', .5), ('D5', .5), ('E5', .5), ('G5', .5), ('E5', 2),
        ('A5', .5), ('C6', .5), ('A5', .5), ('G5', .5), ('E5', 1), ('G5', 1),
        ('F5', .5), ('E5', .5), ('D5', .5), ('E5', .5), ('C5', 2),
        ('E5', .5), ('G5', .5), ('A5', 1), ('C6', .5), ('A5', .5), ('G5', 1),
        ('A5', .5), ('G5', .5), ('E5', .5), ('D5', .5), ('E5', 2),
        ('C6', .5), ('B5', .5), ('A5', .5), ('G5', .5), ('A5', 1), ('E5', 1),
        ('D5', .5), ('E5', .5), ('G5', .5), ('D5', .5), ('C5', 2),
    ]
    roots = ['C3', 'A2', 'F2', 'G2', 'C3', 'A2', 'F2', 'G2']
    bass = []
    for r in roots:
        octave_up = r[:-1] + str(int(r[-1]) + 1)
        bass += [(r, 1), (octave_up, 1), (r, 1), (octave_up, 1)]
    chords = [['C4', 'E4', 'G4'], ['A3', 'C4', 'E4'], ['F3', 'A3', 'C4'], ['G3', 'B3', 'D4']] * 2
    save('music_battle', render_track(128, 8, melody, bass, chords), peak=0.5)

    # Menu: calmer, bouncy loop.
    melody = [
        ('G4', 1), ('C5', .5), ('E5', .5), ('D5', 1), ('C5', 1),
        ('A4', 1), ('C5', .5), ('D5', .5), ('E5', 2),
        ('F5', 1), ('E5', .5), ('D5', .5), ('C5', 1), ('A4', 1),
        ('G4', 1), ('A4', .5), ('B4', .5), ('C5', 2),
    ]
    bass = [(r, 2) for r in ['C3', 'C3', 'F2', 'C3', 'F2', 'C3', 'G2', 'C3']]
    chords = [['C4', 'E4', 'G4'], ['F3', 'A3', 'C4'], ['F3', 'A3', 'C4'], ['G3', 'B3', 'D4']]
    save('music_menu', render_track(100, 4, melody, bass, chords, drums=False, lead_shape='tri'), peak=0.45)


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    sfx()
    music()
    for f in sorted(os.listdir(OUT)):
        print(f, os.path.getsize(os.path.join(OUT, f)))
