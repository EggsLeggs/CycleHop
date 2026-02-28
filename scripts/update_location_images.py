#!/usr/bin/env python3
"""
Update location PNG images with new color scheme:
- Dark images: black (#000000) -> #1C1C1C
- Paris highlighted: #2D6A2B -> #00A650
- New York highlighted: #271A88 -> #00396C
"""

import os
import sys

try:
    from PIL import Image
except ImportError:
    print("Pillow is required. Install with: pip install Pillow")
    sys.exit(1)

RESOURCES = os.path.join(os.path.dirname(__file__), "..", "Resources")

# Color mappings (R, G, B)
BLACK = (0, 0, 0)
DARK_BG = (28, 28, 28)  # #1C1C1C
PARIS_GREEN_OLD = (45, 106, 43)   # #2D6A2B
PARIS_GREEN_NEW = (0, 166, 80)    # #00A650
NY_BLUE_OLD = (39, 26, 136)       # #271A88
NY_BLUE_NEW = (0, 57, 108)        # #00396C

# Tolerance for color matching (for anti-aliasing/compression)
TOLERANCE = 3


def color_distance(c1, c2):
    return sum(abs(a - b) for a, b in zip(c1[:3], c2[:3]))


def matches_color(pixel, target, tolerance=TOLERANCE):
    """Check if pixel (r,g,b) or (r,g,b,a) matches target within tolerance."""
    return color_distance(pixel[:3], target) <= tolerance * 3


def replace_colors_in_image(img, replacements):
    """Replace colors in image. replacements: list of (old_rgb, new_rgb) tuples."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            p = pixels[x, y]
            r, g, b, a = p
            for old_rgb, new_rgb in replacements:
                if matches_color((r, g, b), old_rgb):
                    pixels[x, y] = (*new_rgb, a)
                    break
    return img


def process_image(path, is_dark, is_paris_highlighted, is_ny_highlighted):
    if not os.path.isfile(path):
        print(f"  Skip (not found): {path}")
        return
    img = Image.open(path).convert("RGBA")
    replacements = []
    if is_dark:
        replacements.append((BLACK, DARK_BG))
    if is_paris_highlighted:
        replacements.append((PARIS_GREEN_OLD, PARIS_GREEN_NEW))
    if is_ny_highlighted:
        replacements.append((NY_BLUE_OLD, NY_BLUE_NEW))
    if not replacements:
        print(f"  Skip (no changes): {os.path.basename(path)}")
        return
    out = replace_colors_in_image(img, replacements)
    out.save(path, "PNG")
    print(f"  Updated: {os.path.basename(path)}")


def main():
    os.chdir(RESOURCES)
    files = [
        ("NewYorkLocationDark.png", True, False, False),
        ("NewYorkLocationDarkHighlighted.png", True, False, True),
        ("NewYorkLocationLight.png", False, False, False),
        ("NewYorkLocationLightHighlighted.png", False, False, True),
        ("ParisLocationDark.png", True, False, False),
        ("ParisLocationDarkHighlighted.png", True, True, False),
        ("ParisLocationLight.png", False, False, False),
        ("ParisLocationLightHighlighted.png", False, True, False),
    ]
    for filename, is_dark, is_paris_hl, is_ny_hl in files:
        process_image(os.path.join(RESOURCES, filename), is_dark, is_paris_hl, is_ny_hl)


if __name__ == "__main__":
    main()
