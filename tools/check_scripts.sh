#!/usr/bin/env bash
# Confere que todos os GDScripts do jogo (fora de addons/) passam no parser do Godot.
# Como os avisos de tipagem são erro (untyped_declaration=2), um script sem tipos reprova aqui,
# mesmo que nenhum teste o carregue.
#   GODOT_BIN  executável do Godot (padrão: ~/.local/bin/godot)
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-$HOME/.local/bin/godot}"
[ -x "$GODOT_BIN" ] || { echo "ERRO: Godot não encontrado em ${GODOT_BIN}. Rode tools/setup_godot.sh." >&2; exit 1; }

cd "$RAIZ"
falhas=0
total=0
while IFS= read -r arq; do
  total=$((total + 1))
  if ! "$GODOT_BIN" --headless --path game --check-only -s "res://${arq#game/}" >/dev/null 2>&1; then
    echo "ERRO: ${arq} não passa no parser do Godot (tipagem ou sintaxe):" >&2
    "$GODOT_BIN" --headless --path game --check-only -s "res://${arq#game/}" 2>&1 | grep -E 'Parse Error|SCRIPT ERROR' >&2 || true
    falhas=$((falhas + 1))
  fi
done < <(git ls-files 'game/*.gd' ':!game/addons/**'; git ls-files --others --exclude-standard 'game/*.gd' ':!game/addons/**')

[ "$total" -gt 0 ] || { echo "ERRO: nenhum GDScript encontrado em game/." >&2; exit 1; }
[ "$falhas" -eq 0 ] || exit 1
echo "OK: ${total} scripts passam no parser do Godot."
