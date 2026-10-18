---
name: referencia-ferramentas
description: Ferramentas e acessos — GitHub REST, Pages, PixelLab, limites
type: reference
---
- GitHub: usar `gh api` REST (GraphQL bloqueado); tag/release só pelo workflow `release.yml`. Repo público (Pages grátis).
- Site: https://alexgamesprojects.github.io/Guardi-es-do-Folclore/ (v0.2 na raiz, Godot em /novo/ até a v0.4.0).
- PixelLab: ferramentas `mcp__remote-devices__pixellab__*` (precisa do app desktop aberto). Plano trial: 40 gerações + bônus diário. Registrar cada geração em `docs/arte/pixellab.md`.
- Godot 4.7.2 via `tools/setup_godot.sh`; testes `tools/run_tests.sh`; `tools/check_scripts.sh`.
- A rede do container não acessa github.io (proxy); use WebFetch para conferir o site.
