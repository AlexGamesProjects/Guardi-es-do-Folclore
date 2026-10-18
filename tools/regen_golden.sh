#!/usr/bin/env bash
# Regenera a cópia de referência dos testes de regressão (game/tests/regression/golden/*.json).
# Use só quando a mudança de comportamento for intencional, e explique a mudança no PR:
# o diff dos JSON mostra exatamente quais lutas e quais campos do estado mudaram.
#   GODOT_BIN  executável do Godot (padrão: ~/.local/bin/godot)
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-$HOME/.local/bin/godot}"
[ -x "$GODOT_BIN" ] || { echo "ERRO: Godot não encontrado em ${GODOT_BIN}. Rode tools/setup_godot.sh." >&2; exit 1; }

echo "Importando recursos..."
"$GODOT_BIN" --headless --path "${RAIZ}/game" --import >/dev/null 2>&1 || true

echo "Gerando a cópia de referência..."
"$GODOT_BIN" --headless --path "${RAIZ}/game" -s res://tests/regression/golden_cases.gd

git -C "$RAIZ" --no-pager diff --stat -- game/tests/regression/golden/ || true
