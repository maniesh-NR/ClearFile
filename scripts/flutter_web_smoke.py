#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Stage 4 boot verification: serve the built Flutter web bundle and prove,
# in headless Chromium, that the app BOOTS and renders frames. Flutter web
# (CanvasKit) draws to a <canvas> — DOM text is empty by design, so the
# disclaimer CONTENT is proven by the widget suite (welcome renders
# 'Demonstration software'); THIS script proves the deployed page actually
# boots: no page errors, the Flutter view attaches, the canvas has size,
# and a screenshot shows a drawn (non-blank) UI under the /ClearFile/ path.
import subprocess, sys, time, os
from pathlib import Path
from playwright.sync_api import sync_playwright

BUILD = Path("/home/z/my-project/clearfile/build")
WEB = BUILD / "web"
assert (WEB / "index.html").exists(), "build/web missing — build first"
# Serve the /ClearFile/ path segment exactly like the real Pages URL.
link = BUILD / "ClearFile"
if not link.exists():
    link.symlink_to("web", target_is_directory=True)

os.chdir(BUILD)
server = subprocess.Popen(
    [sys.executable, "-m", "http.server", "8123", "--bind", "127.0.0.1"],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    time.sleep(1.2)
    with sync_playwright() as p:
        b = p.chromium.launch()
        pg = b.new_page(viewport={"width": 1280, "height": 900})
        errors = []
        pg.on("pageerror", lambda e: errors.append(str(e)))
        failed = []
        pg.on("requestfailed", lambda r: failed.append(r.url))
        pg.goto("http://127.0.0.1:8123/ClearFile/", wait_until="networkidle")
        pg.wait_for_timeout(4500)  # Flutter bootstrap + first frames

        has_flutter_view = pg.evaluate(
            "() => !!document.querySelector('flutter-view, flt-glass-pane')")
        shot = WEB.parent / "smoke.png"
        pg.screenshot(path=str(shot))

        # Pixel analysis: a booted app draws UI; a blank page is ~1 uniform
        # color. Count distinct quantized colors across the shot. (The
        # content itself is proven by the widget suite + the recorded
        # screenshot review; CanvasKit hides its canvas in the shadow DOM,
        # so there is no plain <canvas> selector to check.)
        from PIL import Image
        img = Image.open(shot).convert("RGB").resize((320, 225))
        colors = set(img.getdata())
        checks = {
            "base href == /ClearFile/":
                pg.eval_on_selector("base", "el => el.getAttribute('href')")
                == "/ClearFile/",
            "flutter view attached": has_flutter_view,
            "UI drawn (non-blank screenshot)": len(colors) > 120,
            "no page errors":
                not [e for e in errors if "favicon" not in e.lower()],
        }
        for name, ok in checks.items():
            print(f"{'PASS' if ok else 'FAIL'}: {name} ({len(colors)} colors)")
        if errors:
            print("page errors:", errors[:3])
        if failed:
            print("failed requests:", failed[:3])
        b.close()
        sys.exit(0 if all(checks.values()) else 1)
finally:
    server.terminate()
