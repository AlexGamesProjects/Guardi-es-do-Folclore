#!/usr/bin/env python3
"""Mede o tempo de carregamento do export web numa rede "4G" emulada.

Uso: measure_load.py <pasta> [--metrics metrics.json] [--runs 3]

- Serve a pasta com http.server numa porta livre. Como o GitHub Pages, as
  respostas de texto/wasm/pck saem comprimidas com gzip (Content-Encoding).
- Abre o Chromium do Playwright com Network.emulateNetworkConditions:
  latência 60 ms, download 9000 kbit/s, upload 1500 kbit/s.
- Mede da navegação até a mensagem de console GF_READY (teto de 30 s).
- Roda 3 vezes e grava a mediana em `load_ms`.
"""

import argparse
import functools
import gzip
import http.server
import json
import statistics
import sys
import threading
import time
from pathlib import Path

from playwright.sync_api import sync_playwright

TETO_MS = 30_000
SINAL = "GF_READY"
COMPRIMIVEIS = {".html", ".js", ".wasm", ".pck", ".json", ".css", ".svg"}


class Handler(http.server.SimpleHTTPRequestHandler):
    _cache = {}

    def log_message(self, *args):
        pass

    def do_GET(self):
        caminho = Path(self.translate_path(self.path.split("?")[0]))
        if (
            caminho.is_file()
            and caminho.suffix in COMPRIMIVEIS
            and "gzip" in self.headers.get("Accept-Encoding", "")
        ):
            corpo = self._cache.get(caminho)
            if corpo is None:
                corpo = gzip.compress(caminho.read_bytes(), compresslevel=9)
                self._cache[caminho] = corpo
            self.send_response(200)
            self.send_header("Content-Type", self.guess_type(str(caminho)))
            self.send_header("Content-Encoding", "gzip")
            self.send_header("Content-Length", str(len(corpo)))
            self.end_headers()
            self.wfile.write(corpo)
            return
        super().do_GET()


def servir(pasta):
    handler = functools.partial(Handler, directory=str(pasta))
    servidor = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=servidor.serve_forever, daemon=True).start()
    return servidor


def medir_uma_vez(browser, url):
    ctx = browser.new_context()
    page = ctx.new_page()
    cdp = ctx.new_cdp_session(page)
    cdp.send("Network.enable")
    cdp.send("Network.setCacheDisabled", {"cacheDisabled": True})
    cdp.send(
        "Network.emulateNetworkConditions",
        {
            "offline": False,
            "latency": 60,
            "downloadThroughput": 9000 * 1000 // 8,
            "uploadThroughput": 1500 * 1000 // 8,
        },
    )
    pronto = threading.Event()
    page.on("console", lambda m: pronto.set() if SINAL in m.text else None)
    inicio = time.perf_counter()
    page.goto(url, wait_until="commit", timeout=TETO_MS)
    deadline = inicio + TETO_MS / 1000
    while not pronto.is_set():
        if time.perf_counter() > deadline:
            ctx.close()
            raise TimeoutError(f"{SINAL} não apareceu em {TETO_MS} ms")
        page.wait_for_timeout(20)  # deixa o Playwright processar os eventos
    ms = round((time.perf_counter() - inicio) * 1000)
    ctx.close()
    return ms


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pasta")
    ap.add_argument("--metrics", default="metrics.json")
    ap.add_argument("--runs", type=int, default=3)
    args = ap.parse_args()

    pasta = Path(args.pasta)
    if not (pasta / "index.html").is_file():
        print(f"Erro: {pasta}/index.html não existe. Rode o export web antes.", file=sys.stderr)
        return 1

    servidor = servir(pasta.resolve())
    url = f"http://127.0.0.1:{servidor.server_address[1]}/index.html"
    medidas = []
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(args=["--use-gl=swiftshader", "--enable-unsafe-swiftshader"])
            for i in range(args.runs):
                ms = medir_uma_vez(browser, url)
                print(f"execução {i + 1}: {ms} ms")
                medidas.append(ms)
            browser.close()
    finally:
        servidor.shutdown()

    mediana = round(statistics.median(medidas))
    saida = Path(args.metrics)
    dados = json.loads(saida.read_text()) if saida.is_file() else {}
    dados["load_ms"] = mediana
    saida.write_text(json.dumps(dados, indent=2) + "\n")
    print(f"load_ms = {mediana} (medidas: {medidas})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
