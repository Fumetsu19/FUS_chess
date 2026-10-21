"""Генерирует лаунчер-иконки Android без внешних ассетов."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "android" / "app" / "src" / "main" / "res"
FONT = "C:/Windows/Fonts/seguisym.ttf"
BG = (20, 21, 23, 255)
PANEL = (28, 29, 33, 255)
AMBER = (232, 164, 91, 255)
BORDER = (90, 73, 52, 255)


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT, size)


def legacy_master() -> Image.Image:
    size = 1024
    image = Image.new("RGBA", (size, size), BG)
    draw = ImageDraw.Draw(image)
    # Мягкая шахматная подложка.
    cell = size // 8
    for row in range(8):
        for col in range(8):
            if (row + col) % 2 == 0:
                draw.rectangle(
                    [col * cell, row * cell, (col + 1) * cell, (row + 1) * cell],
                    fill=(24, 25, 28, 255),
                )
    overlay = Image.new("RGBA", (size, size), (20, 21, 23, 232))
    image = Image.alpha_composite(image, overlay)
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle(
        [72, 72, size - 72, size - 72],
        radius=210,
        outline=BORDER,
        width=8,
        fill=PANEL,
    )
    glyph = "♞"
    fnt = font(520)
    bbox = draw.textbbox((0, 0), glyph, font=fnt)
    x = (size - (bbox[2] - bbox[0])) / 2 - bbox[0]
    y = (size - (bbox[3] - bbox[1])) / 2 - bbox[1] - 10
    draw.text((x, y), glyph, font=fnt, fill=AMBER)
    return image


def foreground_master() -> Image.Image:
    size = 1024
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    glyph = "♞"
    fnt = font(540)
    bbox = draw.textbbox((0, 0), glyph, font=fnt)
    x = (size - (bbox[2] - bbox[0])) / 2 - bbox[0]
    y = (size - (bbox[3] - bbox[1])) / 2 - bbox[1]
    draw.text((x, y), glyph, font=fnt, fill=AMBER)
    return image


def save_resized(master: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    master.resize((size, size), Image.Resampling.LANCZOS).save(path)


def main() -> None:
    legacy = legacy_master()
    foreground = foreground_master()
    densities = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }
    for density, size in densities.items():
        save_resized(legacy, RES / f"mipmap-{density}" / "ic_launcher.png", size)
        save_resized(
            foreground,
            RES / f"mipmap-{density}" / "ic_launcher_foreground.png",
            int(size * 2.25),
        )
    (RES / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    (RES / "mipmap-anydpi-v26" / "ic_launcher.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
""",
        encoding="utf-8",
    )
    values = RES / "values"
    values.mkdir(parents=True, exist_ok=True)
    (values / "colors.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#141517</color>
    <color name="launch_background">#121315</color>
</resources>
""",
        encoding="utf-8",
    )
    print("icons generated")


if __name__ == "__main__":
    main()
