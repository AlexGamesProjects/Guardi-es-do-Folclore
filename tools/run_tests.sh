#!/usr/bin/env bash
# Roda os testes GdUnit4 sem tela. Uso: tools/run_tests.sh [res://caminho]
#   GODOT_BIN  executável do Godot (padrão: ~/.local/bin/godot)
# Sai com código diferente de zero se houver falha.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-$HOME/.local/bin/godot}"
ALVO="${1:-res://tests}"

[ -x "$GODOT_BIN" ] || { echo "ERRO: Godot não encontrado em ${GODOT_BIN}. Rode tools/setup_godot.sh." >&2; exit 1; }
[ -f "${RAIZ}/game/project.godot" ] || { echo "ERRO: ${RAIZ}/game/project.godot não existe." >&2; exit 1; }

echo "Importando recursos..."
"$GODOT_BIN" --headless --path "${RAIZ}/game" --import >/dev/null 2>&1 || true

echo "Rodando testes em ${ALVO}..."
"$GODOT_BIN" --headless --path "${RAIZ}/game" -s \
  res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a "$ALVO" -c
