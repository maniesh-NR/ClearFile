#!/usr/bin/env python3
"""Generate Nitro Nissi brand icons (MIT-style flat design, MD3 friendly)."""
from PIL import Image, ImageDraw
import os

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icons')
os.makedirs(OUT, exist_ok=True)

INDIGO = (40, 53, 147)      # #283593
INDIGO_LIGHT = (63, 81, 181)
WHITE = (255, 255, 255)


def rounded_rect_mask(size, radius):
    m = Image.new('L', (size, size), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return m


def draw_document_glyph(d, cx, cy, scale):
    """A white 'return document with check' glyph centered at (cx, cy)."""
    # Document sheet
    w, h = 420 * scale, 520 * scale
    x0, y0 = cx - w / 2, cy - h / 2
    r = 36 * scale
    d.rounded_rectangle([x0, y0, x0 + w, y0 + h], radius=r, fill=WHITE)
    # Folded corner
    fold = 96 * scale
    d.polygon([(x0 + w, y0), (x0 + w, y0 + fold), (x0 + w - fold, y0)], fill=(205, 212, 240))
    # Text lines
    line_w = 220 * scale
    for i, frac in enumerate((0.30, 0.44, 0.58)):
        ly = y0 + h * frac
        d.rounded_rectangle([x0 + 54 * scale, ly, x0 + 54 * scale + line_w, ly + 26 * scale],
                            radius=13 * scale, fill=(176, 190, 226))
    # Check circle
    ccx, ccy = x0 + w - 20 * scale, y0 + h - 20 * scale
    cr = 110 * scale
    d.ellipse([ccx - cr, ccy - cr, ccx + cr, ccy + cr], fill=(46, 125, 50))
    # Check mark
    pts = [(ccx - 48 * scale, ccy + 4 * scale), (ccx - 12 * scale, ccy + 40 * scale),
           (ccx + 52 * scale, ccy - 40 * scale)]
    d.line(pts, fill=WHITE, width=int(30 * scale), joint='curve')


def make_icon(size=1024, rounded=True, foreground=False):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if not foreground:
        # Vertical gradient background
        bg = Image.new('RGBA', (size, size))
        bd = ImageDraw.Draw(bg)
        for y in range(size):
            t = y / size
            col = tuple(int(INDIGO_LIGHT[i] + (INDIGO[i] - INDIGO_LIGHT[i]) * t) for i in range(3)) + (255,)
            bd.line([(0, y), (size, y)], fill=col)
        mask = rounded_rect_mask(size, int(size * 0.22)) if rounded else None
        if mask:
            img.paste(bg, (0, 0), mask)
        else:
            img = bg
        draw_document_glyph(d, size / 2, size / 2, size / 1024)
    else:
        # Adaptive foreground: glyph within safe zone (66%)
        draw_document_glyph(d, size / 2, size / 2, size / 1024 * 0.66)
    return img


img = make_icon(1024, rounded=False)  # square source (launchers round it)
img.save(os.path.join(OUT, 'icon.png'))
make_icon(1024, rounded=True).save(os.path.join(OUT, 'icon_rounded.png'))
make_icon(512, foreground=True).save(os.path.join(OUT, 'icon_foreground.png'))
print('icons written to', OUT)
