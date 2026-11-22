#!/usr/bin/env python3
"""Genera iconos y fondos de marca a partir del logo oficial.

El original es branding/logo/logo-2-limpio.png (Peka / Pekapro, CC BY-SA 4.0).
Este script recorta el anillo con la P (emblema, fondo transparente) y el
logotipo completo, y escribe los PNG que usa el paquete de marca.

No pisa el fondo de pantalla: ese sigue saliendo de tools/generate_assets.py
(CC0). Ejecutar desde cualquier sitio:

    python3 tools/make_logo_icons.py
"""

from __future__ import annotations

import base64
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "branding" / "logo" / "logo-2-limpio.png"
SHARE = ROOT / "branding" / "pekarchos-branding" / "root" / "usr" / "share"
BRAND = SHARE / "pekarchos"
HICOLOR = SHARE / "icons" / "hicolor"
PLYMOUTH = SHARE / "plymouth" / "themes" / "pekarchos"
GRUB = SHARE / "grub" / "themes" / "pekarchos"
SDDM = SHARE / "sddm"
SKEL = ROOT / "branding" / "pekarchos-branding" / "root" / "etc" / "skel"
SIZES = (16, 22, 24, 32, 48, 64, 128, 256, 512)

# Azul marino del original, para splash y fondos opacos.
NAVY = (8, 22, 52, 255)
NAVY_DEEP = (3, 10, 28, 255)
MAGENTA = (255, 43, 214, 255)
CYAN = (0, 240, 255, 255)


def foreground_mask(image: Image.Image) -> list[list[bool]]:
    """El fondo es un degradado azul oscuro. El dibujo es claro."""
    rgb = image.convert("RGB")
    width, height = rgb.size
    pixels = rgb.load()
    mask: list[list[bool]] = []
    for y in range(height):
        row: list[bool] = []
        for x in range(width):
            red, green, blue = pixels[x, y]
            luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue
            navy = red < 48 and green < 96 and blue < 160 and luma < 78 and red + 8 < blue
            row.append(not navy)
        mask.append(row)
    return mask


def alpha_image(image: Image.Image) -> Image.Image:
    """Vuelve transparente el azul marino y deja el relieve irisado."""
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            red, green, blue, _alpha = pixels[x, y]
            luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue
            if red < 36 and green < 78 and blue < 145 and luma < 58 and red + 6 < blue:
                pixels[x, y] = (red, green, blue, 0)
            elif red < 55 and green < 100 and blue < 170 and luma < 78 and red < blue:
                fade = int(max(0, min(255, (luma - 52) * 8)))
                pixels[x, y] = (red, green, blue, fade)
            else:
                pixels[x, y] = (red, green, blue, 255)
    return rgba


def content_bounds(mask: list[list[bool]]) -> tuple[int, int, int, int] | None:
    height = len(mask)
    width = len(mask[0])
    min_x, min_y, max_x, max_y = width, height, 0, 0
    found = False
    for y, row in enumerate(mask):
        for x, on in enumerate(row):
            if not on:
                continue
            found = True
            if x < min_x:
                min_x = x
            if x > max_x:
                max_x = x
            if y < min_y:
                min_y = y
            if y > max_y:
                max_y = y
    if not found:
        return None
    return min_x, min_y, max_x, max_y


def row_spans(mask: list[list[bool]], min_pixels: int = 40) -> list[tuple[int, int]]:
    spans: list[tuple[int, int]] = []
    start: int | None = None
    for y, row in enumerate(mask):
        count = sum(1 for on in row if on)
        if count >= min_pixels and start is None:
            start = y
        elif count < min_pixels and start is not None:
            spans.append((start, y - 1))
            start = None
    if start is not None:
        spans.append((start, len(mask) - 1))
    return spans


def ring_box(mask: list[list[bool]]) -> tuple[int, int, int, int]:
    """Recorte cuadrado del anillo, sin el texto «PekarchOS»."""
    spans = row_spans(mask)
    if not spans:
        raise SystemExit("El logo no tiene dibujo.")
    # El bloque alto es anillo + wordmark. La leyenda va en un bloque aparte.
    upper = max(spans, key=lambda span: span[1] - span[0])
    widths: list[tuple[int, int, int]] = []
    for y in range(upper[0], upper[1] + 1):
        xs = [x for x, on in enumerate(mask[y]) if on]
        if xs:
            widths.append((y, xs[0], xs[-1]))
    if not widths:
        raise SystemExit("No se pudo medir el anillo.")
    # El wordmark es más ancho que la base del anillo y empieza de golpe.
    ring_rows = [widths[0]]
    for item in widths[1:]:
        _y, left, right = item
        prev_left, prev_right = ring_rows[-1][1], ring_rows[-1][2]
        if left < prev_left - 80 and (right - left) > (prev_right - prev_left) + 40:
            break
        ring_rows.append(item)
    top = ring_rows[0][0]
    bottom = ring_rows[-1][0]
    left = min(item[1] for item in ring_rows)
    right = max(item[2] for item in ring_rows)
    center_x = (left + right) / 2
    # Cuadrado con un poco de aire. El texto queda justo debajo: no bajar de ahí.
    side = max(right - left, bottom - top) + 48
    max_bottom = bottom + 6
    crop_top = int(round(bottom + 6 - side))
    if crop_top > top - 8:
        crop_top = top - 24
        side = max_bottom - crop_top
    crop_bottom = crop_top + side
    crop_left = int(round(center_x - side / 2))
    crop_right = crop_left + side
    return crop_left, crop_top, crop_right, crop_bottom


def crop(image: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    return image.crop(box)


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, "PNG", optimize=True)


def emblem_svg(png_path: Path, svg_path: Path) -> None:
    encoded = base64.b64encode(png_path.read_bytes()).decode("ascii")
    svg_path.parent.mkdir(parents=True, exist_ok=True)
    svg_path.write_text(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" "
        "viewBox=\"0 0 512 512\" role=\"img\" aria-label=\"PekarchOS\">\n"
        "  <title>PekarchOS</title>\n"
        "  <image width=\"512\" height=\"512\" href=\"data:image/png;base64,"
        f"{encoded}\" xlink:href=\"data:image/png;base64,{encoded}\"/>\n"
        "</svg>\n",
        encoding="utf-8",
    )


def navy_canvas(width: int, height: int) -> Image.Image:
    image = Image.new("RGBA", (width, height))
    pixels = image.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        color = tuple(int(NAVY[i] + (NAVY_DEEP[i] - NAVY[i]) * t) for i in range(3))
        for x in range(width):
            dx = (x - width / 2) / (width / 2)
            dy = (y - height * 0.42) / (height / 2)
            glow = max(0.0, 1.0 - (dx * dx + dy * dy) * 1.15)
            magenta = int(28 * glow)
            cyan = int(18 * glow)
            pixels[x, y] = (
                min(255, color[0] + magenta),
                min(255, color[1] + cyan // 3),
                min(255, color[2] + cyan),
                255,
            )
    return image


def paste_center(canvas: Image.Image, sprite: Image.Image, cx: int, cy: int) -> None:
    x = cx - sprite.width // 2
    y = cy - sprite.height // 2
    canvas.alpha_composite(sprite, (x, y))


def progress_images() -> tuple[Image.Image, Image.Image]:
    track = Image.new("RGBA", (420, 14), (0, 0, 0, 0))
    draw = ImageDraw.Draw(track)
    draw.rounded_rectangle((0, 0, 419, 13), radius=7, fill=(10, 24, 56, 255), outline=CYAN[:3] + (180,), width=1)
    bar = Image.new("RGBA", (420, 14), (0, 0, 0, 0))
    draw = ImageDraw.Draw(bar)
    draw.rounded_rectangle((0, 0, 419, 13), radius=7, fill=MAGENTA)
    return track, bar


def select_slices() -> dict[str, Image.Image]:
    """Nueve piezas para la fila seleccionada del menú de GRUB."""
    width, height = 48, 40
    bar = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(bar)
    # Margen arriba y abajo para que la fila siguiente no pise el resalte.
    draw.rounded_rectangle((1, 8, width - 2, height - 8), radius=8, fill=(255, 43, 214, 230))
    draw.rounded_rectangle((3, 10, width - 4, height - 10), radius=6, outline=(190, 255, 255, 220), width=1)
    tiles = {
        "nw": bar.crop((0, 0, 12, 14)),
        "n": bar.crop((12, 0, 36, 14)),
        "ne": bar.crop((36, 0, 48, 14)),
        "w": bar.crop((0, 14, 12, 26)),
        "c": bar.crop((12, 14, 36, 26)),
        "e": bar.crop((36, 14, 48, 26)),
        "sw": bar.crop((0, 26, 12, 40)),
        "s": bar.crop((12, 26, 36, 40)),
        "se": bar.crop((36, 26, 48, 40)),
    }
    return tiles


def main() -> None:
    if not SOURCE.is_file():
        raise SystemExit(f"No está el logo de origen: {SOURCE}")
    original = Image.open(SOURCE).convert("RGBA")
    mask = foreground_mask(original)
    full_box = content_bounds(mask)
    if full_box is None:
        raise SystemExit("El logo de origen está vacío.")
    pad = 36
    full = alpha_image(
        original.crop(
            (
                max(0, full_box[0] - pad),
                max(0, full_box[1] - pad),
                min(original.width, full_box[2] + pad),
                min(original.height, full_box[3] + pad),
            )
        )
    )
    ring = alpha_image(original.crop(ring_box(mask)))
    emblem = ring.resize((512, 512), Image.Resampling.LANCZOS)
    full_out = full.copy()
    full_out.thumbnail((1024, 1024), Image.Resampling.LANCZOS)

    save_png(emblem, BRAND / "logo.png")
    save_png(full_out, BRAND / "logo-full.png")
    emblem_svg(BRAND / "logo.png", BRAND / "logo.svg")

    for size in SIZES:
        icon = emblem.resize((size, size), Image.Resampling.LANCZOS)
        save_png(icon, HICOLOR / f"{size}x{size}" / "apps" / "pekarchos.png")
    emblem_svg(BRAND / "logo.png", HICOLOR / "scalable" / "apps" / "pekarchos.svg")

    face = emblem.resize((256, 256), Image.Resampling.LANCZOS)
    save_png(face, SDDM / "faces" / ".face.icon")
    save_png(face, SKEL / ".face.icon")

    splash = navy_canvas(640, 480)
    splash_logo = full.copy()
    splash_logo.thumbnail((460, 360), Image.Resampling.LANCZOS)
    paste_center(splash, splash_logo, 320, 210)
    save_png(splash, BRAND / "splash.png")

    plymouth_logo = full.copy()
    plymouth_logo.thumbnail((640, 640), Image.Resampling.LANCZOS)
    save_png(plymouth_logo, PLYMOUTH / "logo.png")
    track, bar = progress_images()
    save_png(track, PLYMOUTH / "progress_box.png")
    save_png(bar, PLYMOUTH / "progress_bar.png")

    grub_bg = navy_canvas(1920, 1080)
    grub_logo = emblem.resize((220, 220), Image.Resampling.LANCZOS)
    paste_center(grub_bg, grub_logo, 960, 150)
    save_png(grub_bg.convert("RGB"), GRUB / "background.png")
    save_png(emblem.resize((64, 64), Image.Resampling.LANCZOS), GRUB / "logo.png")
    for name, tile in select_slices().items():
        flat = Image.new("RGB", tile.size, NAVY[:3])
        flat.paste(tile, mask=tile.split()[-1])
        save_png(flat, GRUB / f"select_{name}.png")

    wallpaper = BRAND / "wallpaper.png"
    preview = SDDM / "themes" / "pekarchos" / "preview.png"
    if wallpaper.is_file():
        wall = Image.open(wallpaper).convert("RGBA")
        wall.thumbnail((640, 360), Image.Resampling.LANCZOS)
        mark = emblem.resize((72, 72), Image.Resampling.LANCZOS)
        wall.alpha_composite(mark, (28, 24))
        save_png(wall, preview)

    print("Iconos y fondos escritos a partir de", SOURCE)


if __name__ == "__main__":
    main()
