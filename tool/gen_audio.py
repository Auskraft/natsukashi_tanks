#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Генератор аудио-ассетов «Танчиков» (Фаза 6).

Синтезирует все клипы из манифеста docs/AUDIO.md процедурно (sfxr-стиль для
SFX + мини-трекер для чиптюн-музыки) и кладёт WAV в assets/audio/. Всё
сгенерировано здесь = CC0 / собственность владельца, без сторонних лицензий.

Запуск из корня проекта:  python tool/gen_audio.py
Зависимости: только стандартная библиотека (wave, math, random, array).
Детерминирован (random.seed) — перезапуск даёт те же файлы.
"""
import math
import os
import random
import wave
from array import array

OUT = os.path.join('assets', 'audio')
SR_SFX = 44100   # SFX: крепкие верхи
SR_MUS = 22050   # музыка: ретро-вайб + компактный вес

# ── Осцилляторы / примитивы ──────────────────────────────────────────────────

def osc(w, phase, duty=0.5):
    p = phase % 1.0
    if w == 'sine':
        return math.sin(2 * math.pi * p)
    if w == 'square':
        return 1.0 if p < duty else -1.0
    if w == 'tri':
        return 4 * abs(p - 0.5) - 1
    if w == 'saw':
        return 2 * p - 1
    if w == 'noise':
        return random.uniform(-1, 1)
    return 0.0


def sweep(dur, f0, f1, w, sr, duty=0.5, vib=0.0, vibhz=0.0):
    """Тон с экспоненциальным глайдом частоты f0->f1."""
    n = int(dur * sr)
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        t = i / n
        f = f0 * (f1 / f0) ** t
        if vib:
            f *= (1.0 + vib * math.sin(2 * math.pi * vibhz * i / sr))
        phase += f / sr
        out[i] = osc(w, phase, duty)
    return out


def noise_buf(dur, sr):
    return [random.uniform(-1, 1) for _ in range(int(dur * sr))]


def env_exp(buf, sr, a=0.003, k=5.0):
    """Атака (анти-клик) + экспоненциальный спад до конца. Мутирует buf."""
    n = len(buf)
    ai = max(1, int(a * sr))
    for i in range(n):
        e = i / ai if i < ai else math.exp(-k * (i - ai) / n)
        buf[i] *= e
    return buf


def lowpass(buf, sr, cutoff):
    rc = 1.0 / (2 * math.pi * cutoff)
    dt = 1.0 / sr
    al = dt / (rc + dt)
    y = 0.0
    out = [0.0] * len(buf)
    for i, x in enumerate(buf):
        y += al * (x - y)
        out[i] = y
    return out


def note(midi, dur, sr, w='square', vol=0.3, a=0.005, d=0.03, s=0.7, r=0.06,
         duty=0.5, detune=0.0, vib=0.0, vibhz=5.0):
    """Нота с ADSR (gate=dur, release добавляется сверху)."""
    f = 440.0 * 2 ** ((midi - 69) / 12.0)
    n = int((dur + r) * sr)
    out = [0.0] * n
    ai, di, gi, ri = max(1, int(a * sr)), max(1, int(d * sr)), int(dur * sr), max(1, int(r * sr))
    phase = 0.0
    for i in range(n):
        if i < ai:
            e = i / ai
        elif i < ai + di:
            e = 1.0 - (1.0 - s) * ((i - ai) / di)
        elif i < gi:
            e = s
        else:
            e = s * max(0.0, 1.0 - (i - gi) / ri)
        ff = f * (1.0 + detune)
        if vib:
            ff *= (1.0 + vib * math.sin(2 * math.pi * vibhz * i / sr))
        phase += ff / sr
        out[i] = osc(w, phase, duty) * e * vol
    return out


def kick(sr, vol=0.95, dur=0.16):
    n = int(dur * sr)
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        t = i / sr
        phase += (150 * math.exp(-22 * t) + 50) / sr
        out[i] = math.sin(2 * math.pi * phase) * math.exp(-15 * t) * vol
    return out


def snare(sr, vol=0.55, dur=0.14):
    n = int(dur * sr)
    out = [0.0] * n
    for i in range(n):
        t = i / sr
        e = math.exp(-30 * t)
        out[i] = (random.uniform(-1, 1) * 0.8 + math.sin(2 * math.pi * 180 * t) * 0.4) * e * vol
    return out


def hat(sr, vol=0.22, dur=0.04):
    n = int(dur * sr)
    return [random.uniform(-1, 1) * math.exp(-80 * i / sr) * vol for i in range(n)]


# ── Утилиты микса/нормализации/записи ────────────────────────────────────────

def mix(layers):
    n = max(len(l) for l in layers)
    out = [0.0] * n
    for l in layers:
        for i, v in enumerate(l):
            out[i] += v
    return out


def normalize(buf, target=0.9):
    peak = max(1e-9, max(abs(x) for x in buf))
    g = target / peak
    return [x * g for x in buf]


def write_wav(name, buf, sr):
    ints = array('h')
    for x in buf:
        if x > 1.0:
            x = 1.0
        elif x < -1.0:
            x = -1.0
        ints.append(int(x * 32767))
    path = os.path.join(OUT, name)
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(ints.tobytes())
    return path, len(buf) / sr, len(ints) * 2


# ── SFX (17) ─────────────────────────────────────────────────────────────────

def sfx_shoot_player():
    b = sweep(0.13, 900, 170, 'square', SR_SFX)
    env_exp(b, SR_SFX, a=0.002, k=6)
    click = noise_buf(0.012, SR_SFX); env_exp(click, SR_SFX, a=0.0, k=20)
    return normalize(mix([b, [0.5 * x for x in click]]), 0.9), SR_SFX


def sfx_shoot_enemy():
    b = sweep(0.16, 520, 110, 'square', SR_SFX, duty=0.35)
    env_exp(b, SR_SFX, a=0.002, k=5)
    return normalize(b, 0.9), SR_SFX


def sfx_brick():
    nz = lowpass(noise_buf(0.05, SR_SFX), SR_SFX, 3500); env_exp(nz, SR_SFX, a=0.0, k=26)
    thud = sweep(0.06, 190, 80, 'square', SR_SFX); env_exp(thud, SR_SFX, a=0.001, k=14)
    return normalize(mix([nz, [0.6 * x for x in thud]]), 0.9), SR_SFX


def sfx_steel():
    parts = []
    for f, amp in [(2100, 1.0), (3170, 0.6), (4830, 0.4)]:
        s = sweep(0.18, f, f * 0.98, 'sine', SR_SFX); env_exp(s, SR_SFX, a=0.0005, k=9)
        parts.append([amp * x for x in s])
    nz = noise_buf(0.02, SR_SFX); env_exp(nz, SR_SFX, a=0.0, k=30)
    parts.append([0.5 * x for x in nz])
    return normalize(mix(parts), 0.9), SR_SFX


def sfx_clash():
    nz = noise_buf(0.05, SR_SFX); env_exp(nz, SR_SFX, a=0.0, k=34)
    blip = sweep(0.04, 1900, 1100, 'square', SR_SFX); env_exp(blip, SR_SFX, a=0.001, k=12)
    return normalize(mix([nz, [0.7 * x for x in blip]]), 0.9), SR_SFX


def sfx_explosion():
    nz = lowpass(noise_buf(0.5, SR_SFX), SR_SFX, 2600); env_exp(nz, SR_SFX, a=0.002, k=4)
    rum = sweep(0.5, 120, 40, 'sine', SR_SFX); env_exp(rum, SR_SFX, a=0.002, k=3)
    return normalize(mix([nz, [0.7 * x for x in rum]]), 0.9), SR_SFX


def sfx_explosion_big():
    nz = lowpass(noise_buf(0.9, SR_SFX), SR_SFX, 1900); env_exp(nz, SR_SFX, a=0.003, k=2.8)
    rum = sweep(0.9, 95, 32, 'sine', SR_SFX); env_exp(rum, SR_SFX, a=0.003, k=2.4)
    crk = noise_buf(0.25, SR_SFX); env_exp(crk, SR_SFX, a=0.0, k=10)
    out = mix([nz, [0.8 * x for x in rum], [0.3 * x for x in crk]])
    out = [math.tanh(1.2 * x) for x in out]
    return normalize(out, 0.95), SR_SFX


def sfx_spawn():
    s = sweep(0.32, 180, 1050, 'square', SR_SFX, vib=0.015, vibhz=16)
    sh = sweep(0.32, 360, 2100, 'tri', SR_SFX)
    ai = int(0.03 * SR_SFX)
    for buf, amp in ((s, 1.0), (sh, 0.3)):
        n = len(buf)
        for i in range(n):
            e = (i / ai) if i < ai else math.exp(-2.2 * (i - ai) / n)
            buf[i] *= e * amp
    return normalize(mix([s, sh]), 0.9), SR_SFX


def _seq(events, total, sr, builder):
    """events: список (offset_sec, *args) -> builder(*args) кладётся в буфер."""
    n = int(total * sr)
    buf = [0.0] * n
    for ev in events:
        off = ev[0]
        nt = builder(*ev[1:])
        oi = int(off * sr)
        for i, v in enumerate(nt):
            if oi + i < n:
                buf[oi + i] += v
    return buf


def sfx_powerup_appear():
    buf = _seq([(0.0, 72), (0.1, 79)], 0.24, SR_SFX,
               lambda m: note(m, 0.08, SR_SFX, 'tri', vol=0.7, a=0.004, d=0.02, s=0.6, r=0.05))
    return normalize(buf, 0.85), SR_SFX


def _bright(m, du):
    return mix([note(m, du, SR_SFX, 'square', vol=0.6, a=0.003, d=0.02, s=0.75, r=0.06, duty=0.45),
                note(m + 12, du, SR_SFX, 'tri', vol=0.2, a=0.003, d=0.02, s=0.75, r=0.06)])


def sfx_powerup():
    buf = _seq([(0.0, 60, 0.12), (0.06, 64, 0.12), (0.12, 67, 0.12), (0.18, 72, 0.12)],
               0.4, SR_SFX, _bright)
    return normalize(buf, 0.9), SR_SFX


def sfx_upgrade():
    ev = [(0.0, 60, 0.08), (0.08, 64, 0.08), (0.16, 67, 0.08), (0.24, 72, 0.08),
          (0.32, 76, 0.08), (0.40, 79, 0.30)]
    return normalize(_seq(ev, 0.8, SR_SFX, _bright), 0.92), SR_SFX


def sfx_player_hit():
    nz = noise_buf(0.12, SR_SFX); env_exp(nz, SR_SFX, a=0.0, k=14)
    sq = sweep(0.25, 300, 80, 'square', SR_SFX); env_exp(sq, SR_SFX, a=0.002, k=6)
    out = mix([[0.7 * x for x in nz], sq])
    out = [math.tanh(1.4 * x) for x in out]
    return normalize(out, 0.9), SR_SFX


def sfx_base_alarm():
    n = int(0.6 * SR_SFX)
    buf = [0.0] * n
    for k, f in enumerate([760, 570, 760, 570]):
        s = sweep(0.11, f, f, 'square', SR_SFX); env_exp(s, SR_SFX, a=0.004, k=5)
        oi = int(k * 0.13 * SR_SFX)
        for i, v in enumerate(s):
            if oi + i < n:
                buf[oi + i] += v
    return normalize(buf, 0.9), SR_SFX


def sfx_wave_clear():
    ev = [(0.0, 60, 0.09), (0.09, 64, 0.09), (0.18, 67, 0.09), (0.27, 72, 0.30)]
    return normalize(_seq(ev, 0.7, SR_SFX, _bright), 0.9), SR_SFX


def sfx_victory():
    n = int(2.2 * SR_SFX)
    buf = [0.0] * n

    def place(o, nt):
        oi = int(o * SR_SFX)
        for i, v in enumerate(nt):
            if oi + i < n:
                buf[oi + i] += v
    for off, mid, du in [(0.0, 67, 0.16), (0.16, 72, 0.16), (0.32, 76, 0.16), (0.48, 79, 0.34)]:
        place(off, note(mid, du, SR_SFX, 'square', vol=0.55, a=0.003, d=0.02, s=0.8, r=0.06))
        place(off, note(mid - 12, du, SR_SFX, 'tri', vol=0.18, a=0.005, d=0.03, s=0.8, r=0.06))
    for mid in [72, 76, 79, 84]:
        place(0.95, note(mid, 1.1, SR_SFX, 'square', vol=0.32, a=0.005, d=0.05, s=0.85, r=0.5))
    place(0.95, note(48, 1.15, SR_SFX, 'square', vol=0.3, a=0.005, d=0.05, s=0.85, r=0.5))
    return normalize(buf, 0.93), SR_SFX


def sfx_gameover():
    n = int(1.9 * SR_SFX)
    buf = [0.0] * n

    def place(o, nt):
        oi = int(o * SR_SFX)
        for i, v in enumerate(nt):
            if oi + i < n:
                buf[oi + i] += v
    for off, mid, du in [(0.0, 69, 0.34), (0.34, 65, 0.34), (0.68, 62, 0.34), (1.02, 57, 0.7)]:
        place(off, note(mid, du, SR_SFX, 'tri', vol=0.5, a=0.006, d=0.04, s=0.8, r=0.12))
        place(off, note(mid - 12, du, SR_SFX, 'square', vol=0.16, a=0.006, d=0.05, s=0.8, r=0.12))
    for mid in [50, 53, 57]:
        place(1.02, note(mid, 0.8, SR_SFX, 'tri', vol=0.22, a=0.02, d=0.1, s=0.8, r=0.3))
    return normalize(buf, 0.85), SR_SFX


def sfx_ui_tap():
    return normalize(note(84, 0.05, SR_SFX, 'tri', vol=0.8, a=0.001, d=0.01, s=0.5, r=0.03), 0.9), SR_SFX


# ── Музыка (3 зацикленных лупа) ──────────────────────────────────────────────

class Track:
    def __init__(self, sr, beats, bpm):
        self.sr = sr
        self.beat = 60.0 / bpm
        self.loop_n = int(beats * self.beat * sr)
        self.n = self.loop_n + int(0.6 * sr)  # хвост для бесшовного лупа
        self.buf = [0.0] * self.n

    def add(self, beat, buf, g=1.0):
        o = int(beat * self.beat * self.sr)
        b = self.buf
        for i in range(len(buf)):
            j = o + i
            if 0 <= j < self.n:
                b[j] += buf[i] * g

    def finalize(self):
        for j in range(self.loop_n, self.n):       # хвост заворачиваем в начало
            self.buf[j - self.loop_n] += self.buf[j]
        self.buf = self.buf[:self.loop_n]


def music_menu():
    sr = SR_MUS
    T = Track(sr, 32, 96)
    prog = [(45, [57, 60, 64]), (48, [60, 64, 67]), (41, [53, 57, 60]), (43, [55, 59, 62]),
            (45, [57, 60, 64]), (41, [53, 57, 60]), (50, [50, 53, 57]), (40, [52, 56, 59])]
    for ci, (bass, triad) in enumerate(prog):
        b0 = ci * 4
        for k in range(2):
            T.add(b0 + k * 2, note(bass, T.beat * 1.7, sr, 'square', vol=0.26, a=0.008, d=0.06, s=0.8, r=0.25))
        for m in triad:
            T.add(b0, note(m - 12, T.beat * 3.5, sr, 'tri', vol=0.10, a=0.06, d=0.12, s=0.85, r=0.4))
        seq = [triad[0], triad[1], triad[2], triad[1]] * 2
        for j, mm in enumerate(seq):
            T.add(b0 + j * 0.5, note(mm + 12, T.beat * 0.46, sr, 'tri', vol=0.19, a=0.005, d=0.05, s=0.6, r=0.1))
    T.finalize()
    return normalize(lowpass(T.buf, sr, 7000), 0.72), sr


def music_battle():
    sr = SR_MUS
    T = Track(sr, 48, 140)
    chords = [(45, [57, 60, 64]), (41, [53, 57, 60]), (48, [60, 64, 67]), (43, [55, 59, 62])]
    for ci in range(12):
        bass, triad = chords[ci % 4]
        b0 = ci * 4
        for j in range(8):
            T.add(b0 + j * 0.5, note(bass, T.beat * 0.45, sr, 'square', vol=0.30, a=0.003, d=0.03, s=0.7, r=0.05))
        ar = [triad[0], triad[1], triad[2], triad[1]]
        for j in range(16):
            T.add(b0 + j * 0.25, note(ar[j % 4] + 12, T.beat * 0.22, sr, 'square', vol=0.13, a=0.002, d=0.02, s=0.5, r=0.03, duty=0.25))
    riff = [(0, 69, 1), (1, 72, .5), (1.5, 71, .5), (2, 69, 1), (3, 67, 1),
            (4, 64, 1), (5, 67, .5), (5.5, 69, .5), (6, 67, 1), (7, 64, 1),
            (8, 69, 1), (9, 72, .5), (9.5, 76, .5), (10, 74, 1), (11, 72, 1),
            (12, 67, 1), (13, 69, .5), (13.5, 67, .5), (14, 64, 2)]
    for rep in range(3):
        for bt, mid, du in riff:
            T.add(rep * 16 + bt, note(mid, du * T.beat * 0.95, sr, 'square', vol=0.24, a=0.004, d=0.03, s=0.7, r=0.06))
    for b in range(48):
        T.add(b, kick(sr) if b % 2 == 0 else snare(sr))
        T.add(b + 0.5, hat(sr))
        T.add(b, hat(sr, vol=0.14))
    T.finalize()
    return normalize(lowpass(T.buf, sr, 7500), 0.78), sr


def music_boss():
    sr = SR_MUS
    T = Track(sr, 48, 152)
    prog = [(40, [52, 55, 59]), (40, [52, 55, 59]), (41, [53, 57, 60]), (38, [50, 54, 57]),
            (40, [52, 55, 59]), (40, [52, 55, 59]), (48, [60, 64, 67]), (38, [50, 54, 57]),
            (40, [52, 55, 59]), (41, [53, 57, 60]), (38, [50, 54, 57]), (40, [52, 55, 59])]
    for ci, (bass, triad) in enumerate(prog):
        b0 = ci * 4
        for j in range(8):
            nt = note(bass, T.beat * 0.42, sr, 'square', vol=0.34, a=0.002, d=0.02, s=0.75, r=0.04)
            T.add(b0 + j * 0.5, [math.tanh(1.5 * x) for x in nt])
        ar = [triad[0], triad[2], triad[1], triad[2]]
        for j in range(16):
            T.add(b0 + j * 0.25, note(ar[j % 4] + 12, T.beat * 0.2, sr, 'square', vol=0.13, a=0.002, d=0.02, s=0.5, r=0.03, duty=0.25))
    riff = [(0, 64, 1), (1, 64, .5), (1.5, 63, .5), (2, 64, 1), (3, 67, 1),
            (4, 64, 1), (5, 62, 1), (6, 60, 1), (7, 59, 1),
            (8, 64, 1), (9, 64, .5), (9.5, 65, .5), (10, 67, 1), (11, 69, 1),
            (12, 67, 1), (13, 64, 1), (14, 59, 2)]
    for rep in range(3):
        for bt, mid, du in riff:
            T.add(rep * 16 + bt, note(mid, du * T.beat * 0.95, sr, 'square', vol=0.22, a=0.004, d=0.03, s=0.7, r=0.06))
    for b in range(48):
        T.add(b, kick(sr))
        if b % 2 == 0:
            T.add(b + 0.5, kick(sr, vol=0.7))   # дабл-кик драйв
        if b % 2 == 1:
            T.add(b, snare(sr))
        T.add(b + 0.5, hat(sr))
    T.finalize()
    return normalize(lowpass(T.buf, sr, 7800), 0.80), sr


# ── Реестр и запуск ──────────────────────────────────────────────────────────

REGISTRY = {
    'sfx_shoot_player': sfx_shoot_player, 'sfx_shoot_enemy': sfx_shoot_enemy,
    'sfx_brick': sfx_brick, 'sfx_steel': sfx_steel, 'sfx_clash': sfx_clash,
    'sfx_explosion': sfx_explosion, 'sfx_explosion_big': sfx_explosion_big,
    'sfx_spawn': sfx_spawn, 'sfx_powerup_appear': sfx_powerup_appear,
    'sfx_powerup': sfx_powerup, 'sfx_upgrade': sfx_upgrade,
    'sfx_player_hit': sfx_player_hit, 'sfx_base_alarm': sfx_base_alarm,
    'sfx_wave_clear': sfx_wave_clear, 'sfx_victory': sfx_victory,
    'sfx_gameover': sfx_gameover, 'sfx_ui_tap': sfx_ui_tap,
    'music_menu': music_menu, 'music_battle': music_battle, 'music_boss': music_boss,
}


def main():
    random.seed(20260613)
    os.makedirs(OUT, exist_ok=True)
    total = 0
    for name, fn in REGISTRY.items():
        buf, sr = fn()
        path, dur, size = write_wav(name + '.wav', buf, sr)
        total += size
        print(f'  {name + ".wav":26} {dur:5.2f}s  {size / 1024:7.1f} KB  @{sr}')
    print(f'  {"ИТОГО":26}            {total / 1024:7.1f} KB ({len(REGISTRY)} файлов)')


if __name__ == '__main__':
    main()
