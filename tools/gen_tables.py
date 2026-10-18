#!/usr/bin/env python3
"""Gera as tabelas xp_table e train_cost do pacote de regras base.

Reescreve só essas duas chaves em game/data/packs/base/balance.json e preserva o resto.
É idempotente: rodar duas vezes não muda o arquivo.

  xp_table[l]    = round(60 * l**1.45)         para l de 1 a 40  (índice 0 = 0)
  train_cost[v]  = round(8 * 1.11**(v - 6))    para v de 1 a 200 (índice 0 = 0), piso de 1

Uso: python3 tools/gen_tables.py [caminho/do/balance.json]
"""
import json
import math
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
PADRAO = RAIZ / "game" / "data" / "packs" / "base" / "balance.json"
NIVEL_MAX = 40
ATRIBUTO_MAX = 200
LARGURA = 100


def meio_para_cima(x: float) -> int:
    """Arredonda como o Math.round do JavaScript da v0.2 (metade sobe)."""
    return math.floor(x + 0.5)


def xp_table() -> list[int]:
    return [0] + [meio_para_cima(60 * l**1.45) for l in range(1, NIVEL_MAX + 1)]


def train_cost() -> list[int]:
    return [0] + [max(1, meio_para_cima(8 * 1.11 ** (v - 6))) for v in range(1, ATRIBUTO_MAX + 1)]


def _escalar(v) -> str:
    return json.dumps(v, ensure_ascii=False)


def _lista_simples(lista: list) -> bool:
    return all(not isinstance(x, (dict, list)) for x in lista)


def _linhas_lista(lista: list, recuo: str) -> str:
    """Lista de escalares: números quebram em linhas de até LARGURA colunas; textos, um por linha."""
    itens = [_escalar(x) for x in lista]
    linha_unica = "[" + ", ".join(itens) + "]"
    if len(recuo) + len(linha_unica) <= LARGURA:
        return linha_unica
    if any(isinstance(x, str) for x in lista):
        interno = recuo + "  "
        return "[\n" + ",\n".join(interno + i for i in itens) + "\n" + recuo + "]"
    linhas, atual = [], ""
    for item in itens:
        candidato = (atual + ", " + item) if atual else item
        if len(recuo) + 2 + len(candidato) + 1 > LARGURA and atual:
            linhas.append(atual + ",")
            atual = item
        else:
            atual = candidato
    linhas.append(atual)
    interno = recuo + "  "
    return "[\n" + "\n".join(interno + l for l in linhas) + "\n" + recuo + "]"


def serializar(v, recuo: str = "") -> str:
    """JSON com recuo de 2 espaços e listas de escalares compactas (saída estável)."""
    if isinstance(v, dict):
        if not v:
            return "{}"
        if _lista_simples(list(v.values())):
            curto = "{" + ", ".join(f"{_escalar(k)}: {_escalar(x)}" for k, x in v.items()) + "}"
            if len(recuo) + len(curto) + 2 <= LARGURA:
                return curto
        interno = recuo + "  "
        partes = [f"{interno}{_escalar(k)}: {serializar(x, interno)}" for k, x in v.items()]
        return "{\n" + ",\n".join(partes) + "\n" + recuo + "}"
    if isinstance(v, list):
        if not v:
            return "[]"
        if _lista_simples(v):
            return _linhas_lista(v, recuo)
        interno = recuo + "  "
        partes = [interno + serializar(x, interno) for x in v]
        return "[\n" + ",\n".join(partes) + "\n" + recuo + "]"
    return _escalar(v)


def main() -> int:
    caminho = Path(sys.argv[1]) if len(sys.argv) > 1 else PADRAO
    if not caminho.is_file():
        print(f"ERRO: {caminho} não existe.", file=sys.stderr)
        return 1
    dados = json.loads(caminho.read_text(encoding="utf-8"))
    dados["xp_table"] = xp_table()
    dados["train_cost"] = train_cost()
    novo = serializar(dados) + "\n"
    antigo = caminho.read_text(encoding="utf-8")
    if novo != antigo:
        caminho.write_text(novo, encoding="utf-8")
        print(f"Atualizado: {caminho}")
    else:
        print(f"Sem mudanças: {caminho}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
