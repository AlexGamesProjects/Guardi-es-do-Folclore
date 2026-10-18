---
name: projeto-estado
description: Onde o projeto está — versão, PRs abertos, próxima tarefa do plano
type: project
---
- v0.3.0 lançada em 18/10/2026. Main em 0.4.0-dev, com as Tarefas 1–9 do plano da v0.4.0 (PR #30).
- PR #31 (`feat/v0.4-boneco`): palco de duelo e guardião articulado (spec `docs/superpowers/specs/2026-10-18-palco-duelo-boneco-design.md`). Arte do herói gerada por `tools/gen_heroi.py`.
- A troca do site (Godot na raiz, v0.2 em /v02/) está na branch `feat/v0.4-site` e entra no PR de fechamento.
- Página de teste (artifact "Guardiões do Folclore", https://claude.ai/artifact/PSCoqUjQ2emVicxqfLBK7q): o build web vai como motor.gz.wasm (wasm em gzip) e dados.pck.wasm, com um shim de fetch. Atualizar ao fim de cada entrega.
- Sprites das lendas no PixelLab (registro em `docs/arte/pixellab.md`):
  - no jogo: Saci;
  - geradas e esperando o zip da dona: Curupira `152e57ff-2b3c-4098-a0bd-4ed6035e57b1`, Cuca `819f616d-0386-43e1-8814-30669eef1503`, Boto `c5f07c0e-d10e-472f-8d1c-fa290812274b`, Mapinguari `bb039c89-5564-44f5-95d2-7174047d7624`;
  - faltam: Iara (sereia) e Boitatá (cobra), que esperam o bônus diário e uma solução que não seja humanoide.
- Fechamento da v0.4.0: Tarefa 12 do plano (site, teste em emulação, nota).
**Why:** retomar sem reler a conversa.
**How to apply:** ao iniciar, ler isto e `git log --oneline -10`.
