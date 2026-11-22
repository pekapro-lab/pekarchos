#!/usr/bin/env python3
"""Genera el fondo y la vista previa de SDDM (licencia CC0-1.0).

No incrusta fuentes: el wordmark del fondo se dibuja con un alfabeto de
píxeles propio. El logotipo oficial no sale de aquí: lo genera
tools/make_logo_icons.py a partir de branding/logo/logo-2-limpio.png
(CC BY-SA 4.0) y este script no lo pisa.

Ejecutar desde la raíz del repositorio:

    python3 tools/generate_assets.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SHARE = ROOT / "branding" / "pekarchos-branding" / "root" / "usr" / "share"
WALL = SHARE / "pekarchos"
THEME = SHARE / "sddm" / "themes" / "pekarchos"
KDE_WALL = SHARE / "wallpapers" / "PekarchOS" / "contents" / "images"

# Alfabeto 5x7 original. Cada fila es una cadena de '.' y '#'.
GLYPHS = {
    "P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
    "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
    "K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
    "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
    "C": [".####", "#....", "#....", "#....", "#....", "#....", ".####"],
    "H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
}

CYAN = (0, 240, 255)
MAGENTA = (255, 43, 214)
AMBER = (255, 176, 0)


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def background(width: int, height: int) -> Image.Image:
    img = Image.new("RGBA", (width, height))
    px = img.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        top = (5, 6, 22)
        mid = (18, 6, 36)
        bot = (4, 8, 16)
        if t < 0.55:
            u = t / 0.55
            col = tuple(lerp(top[i], mid[i], u) for i in range(3))
        else:
            u = (t - 0.55) / 0.45
            col = tuple(lerp(mid[i], bot[i], u) for i in range(3))
        for x in range(width):
            px[x, y] = (*col, 255)
    return img


def draw_sun(img: Image.Image, cx: int, cy: int, radius: int) -> None:
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for i in range(radius, 0, -1):
        t = i / radius
        col = (
            lerp(255, 120, 1 - t),
            lerp(43, 10, 1 - t),
            lerp(214, 80, 1 - t),
            int(210 * (1 - (1 - t) ** 2)),
        )
        draw.ellipse((cx - i, cy - i, cx + i, cy + i), fill=col)
    # Rebanadas de glitch, estilo neón, hechas con rectángulos.
    for y in range(cy - radius, cy + radius, max(4, radius // 28)):
        if ((y // max(4, radius // 28)) % 3) != 0:
            continue
        shift = 18 if (y // 8) % 2 == 0 else -26
        draw.rectangle(
            (cx - radius + shift, y, cx + radius + shift + 12, y + 2),
            fill=(*CYAN, 170),
        )
    img.alpha_composite(overlay)


def draw_grid(img: Image.Image, horizon: int) -> None:
    draw = ImageDraw.Draw(img, "RGBA")
    width, height = img.size
    vanish_x = width // 2
    for i in range(16):
        t = (i / 15) ** 1.7
        y = int(horizon + t * (height - horizon - 1))
        alpha = int(40 + 90 * (i / 15))
        draw.line([(0, y), (width, y)], fill=(*CYAN, alpha), width=1)
    for i in range(-16, 17):
        x = vanish_x + i * (width // 14)
        draw.line([(vanish_x, horizon), (x, height)], fill=(*CYAN, 70), width=1)


def draw_skyline(img: Image.Image, horizon: int) -> None:
    draw = ImageDraw.Draw(img, "RGBA")
    width, height = img.size
    rng = 17
    x = 0
    seed = 7
    while x < width:
        seed = (seed * 37 + 11) % 97
        w = 28 + (seed % 48)
        h = 40 + (seed * 3) % max(80, (height - horizon) // 2)
        y0 = horizon + 8
        draw.rectangle((x, y0 - h, x + w - 4, height), fill=(6, 8, 18, 255))
        if seed % 4 == 0:
            draw.rectangle((x, y0 - h, x + w - 4, y0 - h + 3), fill=(*MAGENTA, 220))
        elif seed % 4 == 1:
            draw.rectangle((x, y0 - h, x + 3, height), fill=(*CYAN, 160))
        # Ventanas.
        for wy in range(y0 - h + 10, height - 16, 14):
            for wx in range(x + 6, x + w - 10, 12):
                if (wx + wy + seed) % 5 == 0:
                    draw.rectangle((wx, wy, wx + 4, wy + 6), fill=(*AMBER, 180))
                elif (wx * wy) % 7 == 0:
                    draw.rectangle((wx, wy, wx + 4, wy + 6), fill=(*CYAN, 120))
        x += w


def draw_monogram(img: Image.Image, ox: int, oy: int, scale: int) -> None:
    draw = ImageDraw.Draw(img, "RGBA")
    # P geométrica: asta + cuenco.
    draw.rounded_rectangle(
        (ox, oy, ox + 3 * scale, oy + 16 * scale),
        radius=scale,
        fill=(*CYAN, 255),
    )
    draw.rounded_rectangle(
        (ox, oy, ox + 10 * scale, oy + 8 * scale),
        radius=2 * scale,
        outline=(*MAGENTA, 255),
        width=max(2, scale),
    )
    draw.rectangle(
        (ox + 4 * scale, oy + 3 * scale, ox + 7 * scale, oy + 5 * scale),
        fill=(7, 7, 18, 255),
    )


def draw_text(img: Image.Image, text: str, ox: int, oy: int, scale: int, color: tuple[int, int, int]) -> None:
    draw = ImageDraw.Draw(img, "RGBA")
    cursor = ox
    for ch in text:
        glyph = GLYPHS[ch]
        for row, bits in enumerate(glyph):
            for col, bit in enumerate(bits):
                if bit == "#":
                    x0 = cursor + col * scale
                    y0 = oy + row * scale
                    draw.rectangle((x0, y0, x0 + scale - 1, y0 + scale - 1), fill=(*color, 255))
        cursor += 6 * scale


def scanlines(img: Image.Image) -> None:
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for y in range(0, img.size[1], 3):
        draw.line([(0, y), (img.size[0], y)], fill=(0, 0, 0, 48))
    img.alpha_composite(overlay)


def make_wallpaper(width: int, height: int) -> Image.Image:
    img = background(width, height)
    horizon = int(height * 0.62)
    draw_sun(img, int(width * 0.72), int(height * 0.36), int(height * 0.16))
    draw_grid(img, horizon)
    draw_skyline(img, horizon)
    scale = max(2, height // 140)
    draw_monogram(img, int(width * 0.06), int(height * 0.08), scale * 2)
    draw_text(img, "PEKARCHOS", int(width * 0.06), int(height * 0.84), scale * 2, CYAN)
    scanlines(img)
    return img


def main() -> None:
    for path in (WALL, THEME, KDE_WALL):
        path.mkdir(parents=True, exist_ok=True)

    wall = make_wallpaper(1920, 1080)
    wall.save(WALL / "wallpaper.png", optimize=True)
    wall.save(KDE_WALL / "1920x1080.png", optimize=True)
    wall.save(THEME / "background.png", optimize=True)
    print("fondo escrito en", SHARE)
    print("El logotipo, los iconos y el splash los escribe tools/make_logo_icons.py.")


if __name__ == "__main__":
    main()
