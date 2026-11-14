#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Stage-1 web smoke test (ADR-010's gate; also verifies the standalone
build end to end).

What it does:
  1. Builds the Next.js standalone bundle (`npm run build`).
  2. Serves it (`node .next/standalone/server.js`) on a localhost port.
  3. Drives it in headless Chromium via Playwright:
       - the welcome screen renders with the demo disclaimer,
       - "Load sample return" drops the MFJ/two-W-2 sample onto the steps,
       - the income step shows the sample W-2s,
       - the results step computes a projected refund,
       - a mid-flow RELOAD rehydrates state from localStorage — the
         persist/migrate path ADR-010 worried about — and the W-2s survive,
       - the store is then reset to leave a clean browser profile.
  4. Exits non-zero on the first failed assertion (prints every check).

Usage:  python3 scripts/web_smoke.py            (build + serve + drive)
        python3 scripts/web_smoke.py --no-build (reuse an existing build)

Requires: node, npm, and Python Playwright with its Chromium already
installed (`pip install playwright && playwright install chromium`).
"""

from __future__ import annotations

import os
import signal
import subprocess
import sys
import time
import urllib.error
import urllib.request

from playwright.sync_api import expect, sync_playwright

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PORT = 3211
BASE = f"http://127.0.0.1:{PORT}"


def build() -> None:
    print("[web-smoke] npm run build ...", flush=True)
    subprocess.run(["npm", "run", "build"], cwd=ROOT, check=True)


def serve() -> subprocess.Popen:
    print(f"[web-smoke] serving standalone bundle on {BASE} ...", flush=True)
    env = dict(os.environ, PORT=str(PORT), HOSTNAME="127.0.0.1")
    proc = subprocess.Popen(
        ["node", ".next/standalone/server.js"], cwd=ROOT, env=env,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    deadline = time.time() + 90
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(BASE, timeout=2) as resp:
                if resp.status == 200:
                    return proc
        except urllib.error.HTTPError as exc:
            raise SystemExit(f"[web-smoke] server answered {exc.code}")
        except OSError:
            time.sleep(0.5)
    proc.terminate()
    raise SystemExit("[web-smoke] standalone server never became ready")


def drive() -> None:
    checks = 0

    def ok(label: str) -> None:
        nonlocal checks
        checks += 1
        print(f"[web-smoke] ok: {label}", flush=True)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(BASE)

        # Welcome screen: title, demo disclaimer, sample affordance.
        expect(page.get_by_role("heading", level=1)).to_contain_text(
            "figure out your taxes")
        ok("welcome heading renders")
        disclaimer = page.get_by_text("Prototype software.")
        expect(disclaimer).to_be_visible()
        expect(page.get_by_role("note")).to_contain_text(
            "Do not use it to file a real return")
        ok("demo disclaimer is visible")

        # Load the sample filing and land on the status step.
        page.get_by_role("button", name="Load sample return").click()
        expect(page.get_by_text("How were you set up at the end of the year?")
               ).to_be_visible()
        ok("sample return loaded; interview started")

        # Rail-scoped navigation: the desktop <nav> rail (the mobile stepper
        # carries the same buttons but is hidden at this viewport).
        rail = page.locator("nav[aria-label='Interview sections']")

        # Income step renders the sample W-2s (employer names are input
        # VALUES, not text nodes).
        rail.get_by_role("button", name="Income").click()
        expect(page.get_by_text("W-2 forms")).to_be_visible()
        employers = page.get_by_label("Employer name")
        expect(employers.first).to_have_value("Acme Corp")
        expect(employers.nth(1)).to_have_value("Star Labs")
        ok("income step shows both sample W-2s")

        # Results step computes a projected refund.
        rail.get_by_role("button", name="Review & results").click()
        expect(page.get_by_text("Projected refund")).to_be_visible()
        expect(page.get_by_text("Refund").first).to_be_visible()
        ok("results step projects a refund")

        # RELOAD mid-flow: the persisted store must rehydrate (the
        # localStorage persist/migrate path), keeping the W-2s. The income
        # step's input values are the read-back proof.
        page.reload()
        rail.get_by_role("button", name="Income").click()
        employers = page.get_by_label("Employer name")
        expect(employers.first).to_have_value("Acme Corp")
        expect(employers.nth(1)).to_have_value("Star Labs")
        ok("state survives a page reload (localStorage persist/rehydrate)")

        # Clean the profile for reruns: reset the filing via the UI store.
        page.evaluate(
            "localStorage.setItem('clearfile-store-v1', "
            "'{}')")
        browser.close()
    print(f"[web-smoke] ALL CHECKS PASSED ({checks} assertions)", flush=True)


def main() -> None:
    if "--no-build" not in sys.argv:
        build()
    proc = serve()
    try:
        drive()
    finally:
        os.killpg(os.getpgid(proc.pid), signal.SIGTERM)


if __name__ == "__main__":
    main()
