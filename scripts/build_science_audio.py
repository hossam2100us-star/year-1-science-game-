"""Deterministic original illustrative sounds. No voice recordings or third-party audio."""
import argparse
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
NAMES = ['triangle', 'maracas', 'trumpet', 'sitar', 'drum', 'stone', 'feather',
         'sticks', 'cat_steps', 'whisper', 'door', 'thunder']
parser = argparse.ArgumentParser()
parser.add_argument('--only', choices=NAMES)
args = parser.parse_args()


def drum_samples():
    noise = random.Random(26)
    samples = []
    for i in range(int(RATE * 1.2)):
        t = i / RATE
        value = 0.0
        for onset in (0.0, .48):
            age = t - onset
            if age < 0:
                continue
            attack = min(1.0, age / .003)
            body = (math.sin(2 * math.pi * (155 * age - 18 * age * age))
                    + .48 * math.sin(2 * math.pi * 310 * age)
                    + .22 * math.sin(2 * math.pi * 465 * age))
            value += attack * (body * math.exp(-8 * age)
                              + .22 * noise.uniform(-1, 1) * math.exp(-65 * age))
        samples.append(value)
    return samples


def samples_for(name):
    if name == 'drum':
        return drum_samples(), .8
    if name == 'feather':
        # The soft feather does not make an audible impact in this box trial.
        # Keep a valid silent asset so playback also stops any previous effect.
        return [0.0] * int(RATE * 1.2), 0.0
    duration = 1.6 if name == 'thunder' else 1.2
    rng = random.Random(70 + NAMES.index(name))
    output = []
    filtered = 0.0
    frequency = {'triangle': 1200, 'trumpet': 440, 'sitar': 220}.get(name, 0)
    for i in range(int(RATE * duration)):
        t = i / RATE
        fade = min(1, t / .008) * min(1, (duration - t) / .08)
        noise = rng.uniform(-1, 1)
        if name in ['maracas', 'stone']:
            pulse = max(0, math.sin(t * math.pi * 14)) ** 6
            value = noise * pulse
            if name == 'stone':
                value = .7 * value + .3 * math.sin(2 * math.pi * 540 * t) * pulse
        elif name == 'sticks':
            value = sum((math.sin(2 * math.pi * 640 * (t - onset))
                         + .3 * math.sin(2 * math.pi * 1100 * (t - onset)))
                        * math.exp(-18 * (t - onset))
                        for onset in (0, .45) if t >= onset)
        elif name == 'triangle':
            value = (math.sin(2 * math.pi * frequency * t)
                     + .3 * math.sin(2 * math.pi * frequency * 2.7 * t)) * math.exp(-3 * t)
        elif name in ['trumpet', 'sitar']:
            value = sum(math.sin(2 * math.pi * frequency * n * t) / n ** 1.6
                        for n in range(1, 6)) * math.exp(-t * (4 if name == 'sitar' else 1))
        elif name == 'cat_steps':
            value = sum((noise * .6 + math.sin(2 * math.pi * 250 * (t - onset)) * .4)
                        * math.exp(-55 * (t - onset))
                        for onset in (.06, .32, .58, .84) if t >= onset)
        elif name == 'whisper':
            filtered = .7 * filtered + .3 * noise
            value = filtered * (math.sin(math.pi * t / duration) ** 2)
        elif name == 'door':
            value = (noise * math.exp(-40 * t)
                     + .6 * math.sin(2 * math.pi * 95 * t) * math.exp(-8 * t))
        else:
            filtered = .98 * filtered + .02 * noise
            value = (filtered * 5 + .12 * math.sin(2 * math.pi * 60 * t)) * math.exp(-1.4 * t)
        output.append(value * fade)
    peak = {'whisper': .22, 'cat_steps': .10,
            'door': .60, 'thunder': .78}.get(name, .65)
    return output, peak


for name in NAMES:
    if args.only and name != args.only:
        continue
    samples, peak = samples_for(name)
    maximum = max(abs(value) for value in samples)
    gain = peak / maximum if maximum else 0.0
    pcm = b''.join(struct.pack('<h', round(value * gain * 32767)) for value in samples)
    with wave.open(str(Path('assets/audio') / (name + '.wav')), 'wb') as out:
        out.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        out.writeframes(pcm)
