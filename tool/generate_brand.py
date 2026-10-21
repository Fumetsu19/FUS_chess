"""Генерация айдентики FUS chess: лаунчер-иконки и компактного знака."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "android" / "app" / "src" / "main" / "res"
BRAND = ROOT / "assets" / "branding"
BOLD = "C:/Windows/Fonts/segoeuib.ttf"
KNIGHT = "C:/Windows/Fonts/seguisym.ttf"
CREAM = (244, 235, 218, 255)
GOLD = (232, 164, 91, 255)
DARK = (18, 19, 21, 255)
PANEL = (27, 28, 31, 255)


def font(size: int, path: str = BOLD) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)


def board_texture(size: int, alpha: int) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cell = size // 8
    for row in range(8):
        for col in range(8):
            if (row + col) % 2 == 0:
                draw.rectangle(
                    [col * cell, row * cell, (col + 1) * cell, (row + 1) * cell],
                    fill=(232, 164, 91, alpha),
                )
    return layer


def centered(draw: ImageDraw.ImageDraw, text: str, fnt, y: int, fill, size: int) -> None:
    draw.text((size / 2, y), text, font=fnt, fill=fill, anchor="ma")


def glyph(
    draw: ImageDraw.ImageDraw, text: str, fnt, y: int, fill, size: int
) -> None:
    bbox = draw.textbbox((0, 0), text, font=fnt)
    x = (size - (bbox[2] - bbox[0])) / 2 - bbox[0]
    draw.text((x, y - bbox[1]), text, font=fnt, fill=fill)


def candidate(dark: bool) -> Image.Image:
    size = 1024
    bg = DARK if dark else GOLD
    fg = GOLD if dark else DARK
    image = Image.new("RGBA", (size, size), bg)
    if dark:
        image.alpha_composite(board_texture(size, 16))
        draw = ImageDraw.Draw(image)
        draw.rounded_rectangle(
            [54, 54, size - 54, size - 54],
            radius=205,
            outline=(232, 164, 91, 120),
            width=7,
        )
        draw.rounded_rectangle(
            [84, 84, size - 84, size - 84],
            radius=180,
            fill=(20, 21, 23, 205),
        )
    else:
        draw = ImageDraw.Draw(image)
        draw.rounded_rectangle(
            [84, 84, size - 84, size - 84],
            radius=190,
            fill=(238, 174, 105, 255),
        )
        draw.rounded_rectangle(
            [54, 54, size - 54, size - 54],
            radius=205,
            outline=(18, 19, 21, 65),
            width=5,
        )

    draw = ImageDraw.Draw(image)
    glyph(draw, "♞", font(300, KNIGHT), 210, fg, size)
    us = "FUS"
    fnt = font(225)
    # Небольшое межбуквенное расстояние вручную.
    widths = [draw.textbbox((0, 0), ch, font=fnt)[2] for ch in us]
    total = sum(widths) + 38 * (len(us) - 1)
    x = (size - total) / 2
    baseline = 560
    for ch, width in zip(us, widths):
        draw.text((x, baseline), ch, font=fnt, fill=CREAM if dark else DARK)
        x += width + 38
    slogan = "FIND UNIQUE STRATEGY"
    sf = font(35)
    centered(
        draw, slogan, sf, 862, fg if dark else (18, 19, 21, 180), size
    )
    return image


def foreground() -> Image.Image:
    size = 1024
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    glyph(draw, "♞", font(300, KNIGHT), 220, GOLD, size)
    fnt = font(225)
    us = "FUS"
    widths = [draw.textbbox((0, 0), ch, font=fnt)[2] for ch in us]
    total = sum(widths) + 38 * (len(us) - 1)
    x = (size - total) / 2
    for ch, width in zip(us, widths):
        draw.text((x, 570), ch, font=fnt, fill=CREAM)
        x += width + 38
    return image


def save_resized(master: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    master.resize((size, size), Image.Resampling.LANCZOS).save(path)


def monogram() -> Image.Image:
    size = 512
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle(
        [12, 12, size - 12, size - 12],
        radius=120,
        fill=GOLD,
        outline=(244, 235, 218, 90),
        width=4,
    )
    glyph(draw, "♞", font(250, KNIGHT), 44, (18, 19, 21, 225), size)
    fnt = font(140)
    us = "FUS"
    widths = [draw.textbbox((0, 0), ch, font=fnt)[2] for ch in us]
    total = sum(widths) + 20 * (len(us) - 1)
    x = (size - total) / 2
    for ch, width in zip(us, widths):
        draw.text((x, 300), ch, font=fnt, fill=DARK)
        x += width + 20
    return image


def main() -> None:
    BRAND.mkdir(parents=True, exist_ok=True)
    # Только брендовые ассеты для README/превью.
    # Лаунчер-иконка и splash генерируются tool/generate_icon.py.
    candidate(dark=True).save(BRAND / "fus_mark.png")
    candidate(dark=True).save(BRAND / "fus_logo.png")
    candidate(dark=True).resize((512, 512), Image.Resampling.LANCZOS).save(
        BRAND / "fus_mark_512.png"
    )
    monogram().save(BRAND / "fus_monogram.png")
    print("FUS branding generated")


if __name__ == "__main__":
    main()
