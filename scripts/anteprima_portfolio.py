#!/usr/bin/env python3
"""Genera portfolio-site/anteprima.png (1200x627, formato consigliato per i link su LinkedIn)
fotografando portfolio-site/copertina.html, che si compone dai dati pubblicati.

Usato dal workflow di pubblicazione su GitHub Pages; in locale serve Playwright:
    pip install playwright && playwright install chromium
    python scripts/anteprima_portfolio.py
"""

import functools
import http.server
import sys
import threading
from pathlib import Path

from playwright.sync_api import sync_playwright

SITE = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent / "portfolio-site").resolve()


def main():
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(SITE))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    url = f"http://127.0.0.1:{server.server_port}/copertina.html"
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page(viewport={"width": 1200, "height": 627}, color_scheme="light")
            page.goto(url, wait_until="networkidle")
            page.wait_for_selector("body[data-pronto='1']")
            page.screenshot(path=str(SITE / "anteprima.png"))
            browser.close()
    finally:
        server.shutdown()
    print(f"Anteprima creata: {SITE / 'anteprima.png'}")


if __name__ == "__main__":
    main()
