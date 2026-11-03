#!/usr/bin/env python3
"""Merge cover.pdf + body.pdf into the final ClearFile blueprint PDF."""
from pypdf import PdfReader, PdfWriter

A4_W, A4_H = 595.28, 841.89

COVER = '/home/z/my-project/blueprint-assets/cover.pdf'
BODY = '/home/z/my-project/blueprint-assets/body.pdf'
OUT = '/home/z/my-project/download/ClearFile_Engineering_Blueprint.pdf'


def normalize_page_to_a4(page):
    box = page.mediabox
    w, h = float(box.width), float(box.height)
    if abs(w - A4_W) > 0.1 or abs(h - A4_H) > 0.1:
        page.scale_to(A4_W, A4_H)
    return page


writer = PdfWriter()
cover_page = PdfReader(COVER).pages[0]
writer.add_page(normalize_page_to_a4(cover_page))
for page in PdfReader(BODY).pages:
    writer.add_page(normalize_page_to_a4(page))
writer.add_metadata({
    '/Title': 'ClearFile - Clean-Room Tax Filing Assistant Engineering Blueprint',
    '/Author': 'Z.ai',
    '/Creator': 'Z.ai',
    '/Subject': 'Engineering blueprint and prototype report for a clean-room tax filing assistant',
})
with open(OUT, 'wb') as f:
    writer.write(f)
print('merged:', OUT, 'pages:', len(writer.pages))
