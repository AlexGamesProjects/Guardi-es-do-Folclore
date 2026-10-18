#!/usr/bin/env python3
"""Soma o tamanho de cada arquivo de build/web comprimido com gzip -9.

Uso: measure_size.py <pasta> [--metrics metrics.json]
Acrescenta a chave inteira `download_gz_bytes` ao metrics.json.
"""

import argparse
import gzip
import json
import sys
from pathlib import Path


def tamanho_gz(pasta):
    total = 0
    for arq in sorted(p for p in pasta.rglob("*") if p.is_file()):
        total += len(gzip.compress(arq.read_bytes(), compresslevel=9, mtime=0))
    return total


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pasta")
    ap.add_argument("--metrics", default="metrics.json")
    args = ap.parse_args()

    pasta = Path(args.pasta)
    if not pasta.is_dir():
        print(f"Erro: a pasta {pasta} não existe. Rode o export web antes.", file=sys.stderr)
        return 1
    total = tamanho_gz(pasta)

    saida = Path(args.metrics)
    dados = json.loads(saida.read_text()) if saida.is_file() else {}
    dados["download_gz_bytes"] = total
    saida.write_text(json.dumps(dados, indent=2) + "\n")
    print(f"download_gz_bytes = {total}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
