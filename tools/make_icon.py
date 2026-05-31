"""Neon Rush uygulama ikonu (synthwave: neon güneş + yol). 2x render -> 1024."""
from PIL import Image, ImageDraw
import os, math

SS = 2048  # supersample
img = Image.new("RGB", (SS, SS), (8, 4, 26))
d = ImageDraw.Draw(img, "RGBA")

# Arka plan gradyanı
top, bot = (10, 5, 30), (46, 20, 78)
for y in range(SS):
    t = y / SS
    c = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3))
    d.line([(0, y), (SS, y)], fill=c + (255,))

horizon = int(SS * 0.54)

# Neon güneş (magenta -> sarı), ufkun üstünde
sr = int(SS * 0.23)
scx, scy = SS // 2, int(SS * 0.40)
s_top, s_bot = (255, 95, 180), (255, 224, 92)
for yy in range(scy - sr, scy + sr):
    dxx = sr * sr - (yy - scy) ** 2
    if dxx > 0:
        half = int(math.sqrt(dxx))
        t = (yy - (scy - sr)) / (2 * sr)
        c = tuple(int(s_top[i] + (s_bot[i] - s_top[i]) * t) for i in range(3))
        d.line([(scx - half, yy), (scx + half, yy)], fill=c + (255,))
# Güneşte yatay kesikler (alt yarı)
for i in range(5):
    yy = scy + int(sr * 0.25) + i * int(sr * 0.17)
    d.rectangle([scx - sr, yy, scx + sr, yy + int(sr * 0.07)], fill=(10, 5, 30, 255))

# Yol (ufuktan aşağı genişleyen yamuk) — güneşin altını kapatır
d.polygon(
    [(scx - 34, horizon), (scx + 34, horizon), (int(SS * 0.93), SS), (int(SS * 0.07), SS)],
    fill=(28, 26, 44, 255),
)
# Ufuk ışıması
d.rectangle([0, horizon - 6, SS, horizon + 6], fill=(73, 242, 255, 200))
# Neon yol kenarları (cyan) + orta çizgi (magenta)
d.line([(scx - 34, horizon), (int(SS * 0.07), SS)], fill=(73, 242, 255, 255), width=26)
d.line([(scx + 34, horizon), (int(SS * 0.93), SS)], fill=(73, 242, 255, 255), width=26)
d.line([(scx, horizon), (scx, SS)], fill=(255, 61, 174, 230), width=14)

# 1024'e indir (antialias)
img = img.resize((1024, 1024), Image.LANCZOS)
os.makedirs("assets/icon", exist_ok=True)
img.save("assets/icon/icon.png")
print("wrote assets/icon/icon.png", os.path.getsize("assets/icon/icon.png"), "bytes")
