"""Oyun için retro/synthwave ses efektlerini sentezler (stdlib, harici asset yok).
Çıktı: assets/audio/*.wav  (22050 Hz, 16-bit mono)
"""
import wave, math, random, os

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)


def _env(n, total, attack, release):
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    if n < a:
        return n / a
    if n > total - r:
        return max(0.0, (total - n) / r)
    return 1.0


def tone(freq, dur, kind="sine", vol=0.5, attack=0.005, release=0.05,
         sweep=None, env=True):
    n_total = int(dur * SR)
    out = [0.0] * n_total
    ph = 0.0
    for n in range(n_total):
        frac = n / n_total
        f = freq if sweep is None else freq + (sweep - freq) * frac
        ph += 2 * math.pi * f / SR
        if kind == "sine":
            s = math.sin(ph)
        elif kind == "square":
            s = 1.0 if math.sin(ph) >= 0 else -1.0
        elif kind == "saw":
            s = (ph / math.pi) % 2 - 1
        elif kind == "noise":
            s = random.uniform(-1, 1)
        else:
            s = math.sin(ph)
        e = _env(n, n_total, attack, release) if env else 1.0
        out[n] = s * vol * e
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, s in enumerate(t):
            out[i] += s
    return out


def concat(*tracks):
    out = []
    for t in tracks:
        out.extend(t)
    return out


def silence(dur):
    return [0.0] * int(dur * SR)


def write(name, samples):
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in samples:
            v = int(max(-1.0, min(1.0, s)) * 32767)
            frames += v.to_bytes(2, "little", signed=True)
        w.writeframes(bytes(frames))
    print("wrote", name, f"{len(samples)/SR:.2f}s")


# --- UI ---
write("click.wav", tone(900, 0.05, "square", 0.35, 0.002, 0.03))

# --- Toplama (yükselen iki nota) ---
write("pickup.wav", concat(
    tone(660, 0.07, "sine", 0.4, 0.003, 0.04),
    tone(990, 0.11, "sine", 0.4, 0.003, 0.06),
))

# --- Nitro (yükselen whoosh) ---
write("nitro.wav", mix(
    tone(220, 0.45, "saw", 0.35, 0.01, 0.12, sweep=1200),
    tone(110, 0.45, "noise", 0.06, 0.01, 0.2),
))

# --- Kalkan (sıcak akor) ---
write("shield.wav", mix(
    tone(440, 0.5, "sine", 0.28, 0.06, 0.22),
    tone(660, 0.5, "sine", 0.18, 0.06, 0.22),
    tone(880, 0.5, "sine", 0.10, 0.06, 0.22),
))

# --- Mermi (alçalan zap) ---
write("bolt.wav", tone(1500, 0.20, "square", 0.35, 0.002, 0.06, sweep=280))

# --- Şok dalgası (gürültü patlaması) ---
write("shock.wav", mix(
    tone(90, 0.4, "sine", 0.4, 0.004, 0.3),
    tone(140, 0.4, "noise", 0.4, 0.004, 0.32),
))

# --- Çarpma (kısa gürültü + tok ses) ---
write("crash.wav", mix(
    tone(80, 0.18, "sine", 0.5, 0.002, 0.12),
    tone(200, 0.18, "noise", 0.45, 0.002, 0.1),
))

# --- Tur tamam (kısa ding) ---
write("lap.wav", concat(
    tone(784, 0.08, "sine", 0.4, 0.003, 0.05),
    tone(1175, 0.13, "sine", 0.4, 0.003, 0.08),
))

# --- Bitiş (yükselen fanfar) ---
write("finish.wav", concat(
    tone(523, 0.12, "square", 0.32, 0.004, 0.06),
    tone(659, 0.12, "square", 0.32, 0.004, 0.06),
    tone(784, 0.14, "square", 0.32, 0.004, 0.06),
    tone(1046, 0.28, "square", 0.34, 0.004, 0.16),
))

# --- Motor (yumuşak alçak hum, sorunsuz döngü: 70/140 Hz, 0.20s = tam çevrim) ---
write("engine.wav", mix(
    tone(70, 0.20, "sine", 0.26, 0, 0, env=False),
    tone(140, 0.20, "sine", 0.09, 0, 0, env=False),
    tone(70, 0.20, "saw", 0.05, 0, 0, env=False),  # hafif doku
))


# --- Arka plan müziği (basit synthwave döngüsü, ~4 sn, sorunsuz) ---
def arp_bar(root, dur):
    # köke dayalı arpej (root, 5th, oct, 5th) + bas
    notes = [root, root * 1.5, root * 2, root * 1.5]
    step = dur / 4
    arp = []
    for f in notes:
        arp.extend(tone(f * 2, step, "square", 0.10, 0.005, step * 0.4))
    bass = tone(root, dur, "saw", 0.18, 0.02, 0.2)
    return mix(arp, bass)


# Am - F - C - G benzeri (Hz): A2=110, F2=87.31, C3=130.81, G2=98
write("bgm.wav", concat(
    arp_bar(110.0, 1.0),
    arp_bar(87.31, 1.0),
    arp_bar(130.81, 1.0),
    arp_bar(98.0, 1.0),
))

print("--- bitti ---")
for f in sorted(os.listdir(OUT)):
    print(" ", f, os.path.getsize(os.path.join(OUT, f)), "bytes")
