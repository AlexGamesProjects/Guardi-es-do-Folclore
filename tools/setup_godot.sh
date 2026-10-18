#!/usr/bin/env bash
# Instala o Godot 4.7.2-stable e os templates de export.
#   GODOT_BIN  destino do executável (padrão: ~/.local/bin/godot)
# Idempotente: se a versão certa já estiver instalada, não baixa nada.
# Os SHA-256 dos downloads ficam em tools/godot.sha256. Se faltar uma entrada
# (primeira execução), o script calcula o hash e o confere com o SHA512-SUMS.txt
# da release antes de gravar.
set -euo pipefail

VERSAO="4.7.2"
ESTAVEL="${VERSAO}-stable"
BASE_URL="https://github.com/godotengine/godot/releases/download/${ESTAVEL}"
ZIP="Godot_v${ESTAVEL}_linux.x86_64.zip"
TPZ="Godot_v${ESTAVEL}_export_templates.tpz"

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARQ_HASH="${RAIZ}/tools/godot.sha256"
GODOT_BIN="${GODOT_BIN:-$HOME/.local/bin/godot}"
DIR_TEMPLATES="${HOME}/.local/share/godot/export_templates/${VERSAO}.stable"

erro() { echo "ERRO: $*" >&2; exit 1; }
for cmd in curl unzip sha256sum sha512sum; do
  command -v "$cmd" >/dev/null 2>&1 || erro "o comando '$cmd' não está instalado."
done

godot_ok() {
  [ -x "$GODOT_BIN" ] && [ "$("$GODOT_BIN" --version 2>/dev/null | head -1 | cut -c1-12)" = "${VERSAO}.stable" ]
}
templates_ok() { [ -f "${DIR_TEMPLATES}/version.txt" ] && [ "$(cat "${DIR_TEMPLATES}/version.txt")" = "${VERSAO}.stable" ]; }

if godot_ok && templates_ok; then
  echo "Godot ${VERSAO}.stable e templates já instalados em ${GODOT_BIN}."
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
touch "$ARQ_HASH"

hash_gravado() { awk -v f="$1" '$2 == f { print $1 }' "$ARQ_HASH"; }

# Baixa o arquivo $1 e confere o SHA-256 (gravado ou recém-calculado).
baixar() {
  local nome="$1" esperado obtido
  echo "Baixando ${nome}..."
  curl -fsSL --retry 5 --retry-all-errors -C - -o "${TMP}/${nome}" "${BASE_URL}/${nome}" || erro "falha ao baixar ${BASE_URL}/${nome}"
  obtido="$(sha256sum "${TMP}/${nome}" | awk '{print $1}')"
  esperado="$(hash_gravado "$nome")"
  if [ -n "$esperado" ]; then
    [ "$obtido" = "$esperado" ] || erro "SHA-256 de ${nome} não confere (esperado ${esperado}, obtido ${obtido})."
    return
  fi
  echo "Primeira execução para ${nome}: conferindo com o SHA512-SUMS.txt da release..."
  if [ ! -f "${TMP}/SHA512-SUMS.txt" ]; then
    curl -fsSL --retry 3 -o "${TMP}/SHA512-SUMS.txt" "${BASE_URL}/SHA512-SUMS.txt" || erro "falha ao baixar SHA512-SUMS.txt"
  fi
  local sha512_esperado sha512_obtido
  sha512_esperado="$(awk -v f="$nome" '$2 == f { print $1 }' "${TMP}/SHA512-SUMS.txt")"
  [ -n "$sha512_esperado" ] || erro "${nome} não consta no SHA512-SUMS.txt da release."
  sha512_obtido="$(sha512sum "${TMP}/${nome}" | awk '{print $1}')"
  [ "$sha512_obtido" = "$sha512_esperado" ] || erro "SHA-512 de ${nome} não confere com o da release."
  echo "${obtido}  ${nome}" >> "$ARQ_HASH"
  echo "SHA-256 de ${nome} gravado em tools/godot.sha256."
}

if ! godot_ok; then
  baixar "$ZIP"
  mkdir -p "${TMP}/godot" "$(dirname "$GODOT_BIN")"
  unzip -q -o "${TMP}/${ZIP}" -d "${TMP}/godot"
  install -m 755 "${TMP}/godot/Godot_v${ESTAVEL}_linux.x86_64" "$GODOT_BIN"
fi

if ! templates_ok; then
  baixar "$TPZ"
  mkdir -p "${TMP}/tpz" "$DIR_TEMPLATES"
  unzip -q -o "${TMP}/${TPZ}" -d "${TMP}/tpz"
  cp -r "${TMP}/tpz/templates/." "$DIR_TEMPLATES/"
fi

godot_ok || erro "o Godot instalado não reporta ${VERSAO}.stable."
templates_ok || erro "os templates de export não foram instalados em ${DIR_TEMPLATES}."
echo "Pronto: $("$GODOT_BIN" --version | head -1) em ${GODOT_BIN}."
