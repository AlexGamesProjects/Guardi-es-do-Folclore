---
name: projeto-estado
description: Onde o projeto está — versão, PRs abertos, próxima tarefa do plano
type: project
---
- v0.4.0 lançada em 23/10/2026 (Release ok). Main em 0.4.1-dev. Etapa 3 em sub-versões: v0.4.1 esqueleto, v0.4.2 layout, v0.4.3 economia, v0.4.4 guardião e lendas; v0.5.0 fecha.
- Sprites do PixelLab no jogo: Saci, Curupira, Cuca, Iara, Boto e Mapinguari (registro em `docs/arte/pixellab.md`). O Boitatá luta com a carta.
- PC da dona (Windows, desde 24/10/2026): projeto em `D:\Projetos\Guardões do Folclore`, Godot em `D:\Projetos\Godot\Godot_v4.7.2-stable_win64.exe`, `gh` logado como AlexGamesProjects (`C:\Program Files\GitHub CLI\gh.exe`). Sem Python. MCP do PixelLab ainda não configurado. Os `.import` aparecem modificados só por fim de linha (CRLF): não commitar.
- 24/10/2026: PR #38 com merge no main (luta no ritmo do Hero Zero, 1 s por troca, botão 1×/2×/4× e Pular no palco). Esqueleto único montado nas 6 lendas e REPROVADO pela dona (feio, destoa): removido do jogo na branch `chore/remove-esqueleto`; registro em `feat/esqueleto-lendas`. Lendas ficam com as 7 animações do PixelLab. Ideias para a v0.5.0: finalizações (#36) e cenários dinâmicos (#37).
- v0.4.1 · Luta e guardião: próximo passo é o guardião em camadas (#1): corpo animado em tiras do PixelLab (7 animações, sem cabeça), cores trocadas no Godot, cabeça em blocos (rosto, olhos, boca, cabelo, barba) encaixada por um ponto marcado em cada quadro, itens nos pontos da cabeça e da mão. Personalização na criação e editor no jogo. Depois: Boitatá em tiras e export menor (#15).
- Teste no celular (#24): na v0.4.2; a emulação no PC basta por ora.
- Página de teste (artifact "Guardiões do Folclore", https://claude.ai/artifact/PSCoqUjQ2emVicxqfLBK7q): o build web vai como motor.gz.wasm (wasm em gzip) e dados.pck.wasm, com um shim de fetch. Atualizar ao fim de cada entrega.
**Why:** retomar sem reler a conversa.
**How to apply:** ao iniciar, ler isto e `git log --oneline -10`.
