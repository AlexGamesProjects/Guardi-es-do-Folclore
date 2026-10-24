---
name: projeto-estado
description: Onde o projeto está — versão, PRs abertos, próxima tarefa do plano
type: project
---
- v0.4.0 lançada em 23/10/2026 (Release ok). Main em 0.4.1-dev. Etapa 3 em sub-versões: v0.4.1 esqueleto, v0.4.2 layout, v0.4.3 economia, v0.4.4 guardião e lendas; v0.5.0 fecha.
- Sprites do PixelLab no jogo: Saci, Curupira, Cuca, Iara, Boto e Mapinguari (registro em `docs/arte/pixellab.md`). O Boitatá luta com a carta.
- PC da dona (Windows, desde 24/10/2026): projeto em `D:\Projetos\Guardões do Folclore`, Godot em `D:\Projetos\Godot\Godot_v4.7.2-stable_win64.exe`, `gh` logado como AlexGamesProjects (`C:\Program Files\GitHub CLI\gh.exe`). Sem Python. MCP do PixelLab ainda não configurado. Os `.import` aparecem modificados só por fim de linha (CRLF): não commitar.
- v0.4.1: protótipo do esqueleto único com o Saci pronto na branch `feat/esqueleto-saci` (#32), esperando a dona comparar em Ajustes → "Esqueleto único (teste)". Se aprovar: as outras lendas (um `rig.json` por lenda + `tools/recortar_lenda.gd`), ligar no Lutador e o Boitatá; depois o export menor (#15).
- Teste no celular (#24): na v0.4.2; a emulação no PC basta por ora.
- Página de teste (artifact "Guardiões do Folclore", https://claude.ai/artifact/PSCoqUjQ2emVicxqfLBK7q): o build web vai como motor.gz.wasm (wasm em gzip) e dados.pck.wasm, com um shim de fetch. Atualizar ao fim de cada entrega.
**Why:** retomar sem reler a conversa.
**How to apply:** ao iniciar, ler isto e `git log --oneline -10`.
