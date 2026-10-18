#!/usr/bin/env python3
"""Compara metrics.json com os limites e gera o relatório em Markdown.

Sai com código 1 se alguma métrica exceder o limite. Métrica ausente (ou que não
seja número) vira "—" e não reprova. A baseline (main) é opcional. Campos que não
são limites, como a etiqueta `mode`, não entram na tabela; o modo aparece abaixo dela.
"""

import argparse
import json
import sys
from pathlib import Path

ROTULOS = {
    "download_gz_bytes": ("Download compactado (gzip -9)", "bytes"),
    "load_ms": ("Carregamento em 4G", "ms"),
    "fights_10k_ms": ("10 mil lutas", "ms"),
    "command_p95_us": ("Comando (p95)", "µs"),
}


def ler_json(caminho):
    if not caminho:
        return {}
    arq = Path(caminho)
    if not arq.is_file():
        return {}
    try:
        dados = json.loads(arq.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        print(f"Aviso: {caminho} não é um JSON válido; ignorado.", file=sys.stderr)
        return {}
    return dados if isinstance(dados, dict) else {}


def numero(valor):
    """O valor, se for número (bool não conta); senão None."""
    if isinstance(valor, bool) or not isinstance(valor, (int, float)):
        return None
    return valor


def formatar(valor):
    valor = numero(valor)
    if valor is None:
        return "—"
    return f"{int(valor):,}".replace(",", ".")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--metrics", required=True)
    ap.add_argument("--baseline", default="")
    ap.add_argument("--budgets", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    metricas = ler_json(args.metrics)
    baseline = ler_json(args.baseline)
    limites = ler_json(args.budgets)
    if not limites:
        print("Erro: arquivo de limites ausente ou vazio.", file=sys.stderr)
        return 2

    linhas = [
        "<!-- gf-metrics -->",
        "### Desempenho",
        "",
        "| Medida | main | PR | Limite | Situação |",
        "|---|---|---|---|---|",
    ]
    estourou = False
    for chave, limite in limites.items():
        nome, unidade = ROTULOS.get(chave, (chave, ""))
        pr = numero(metricas.get(chave))
        if pr is None:
            situacao = "—"
        elif pr > limite:
            situacao = "❌"
            estourou = True
        else:
            situacao = "✅"
        linhas.append(
            f"| {nome} (`{chave}`, {unidade}) | {formatar(baseline.get(chave))} "
            f"| {formatar(pr)} | ≤ {formatar(limite)} | {situacao} |"
        )
    linhas.append("")
    modo = metricas.get("mode")
    if isinstance(modo, str) and modo:
        linhas.append(f"Modo medido: `{modo}`.")
        linhas.append("")
    if estourou:
        linhas.append("**Algum limite foi excedido.**")
    Path(args.out).write_text("\n".join(linhas) + "\n", encoding="utf-8")
    print("\n".join(linhas))
    return 1 if estourou else 0


if __name__ == "__main__":
    sys.exit(main())
