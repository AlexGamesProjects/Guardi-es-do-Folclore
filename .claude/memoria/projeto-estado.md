---
name: projeto-estado
description: Onde o projeto está — versão, PRs abertos, próxima tarefa do plano
type: project
---
- v0.3.0 lançada em 18/10/2026. Main em 0.4.0-dev.
- v0.4.0 em execução direta (sem agentes). Plano `docs/superpowers/plans/2026-10-18-migracao-v0.4.0.md`.
- Feito (branch `feat/v0.4-casca`, PR #30): Tarefas 1–9 e o código da Tarefa 10 (SpriteLib).
- Troca do site guardada na branch `feat/v0.4-site` (entra no PR de fechamento).
- Em andamento: piloto de pixel art no PixelLab (plano trial, 1 job por vez, ~13 min cada).
  - Herói `c0a26aec-76a8-4eb8-96b3-a04c7271830e` (east): parado ✓, ataque (rodando), faltam golpe (taking-punch), derrota (falling-back-death), esquiva (v3 "dodging backward").
  - Saci `5f0d6f83-cda7-43ce-9121-3906b74d07ff` (west): criado, faltam as 5 animações. Saiu com duas pernas.
  - Sprites vão em `game/assets/sprites/<id>/<acao>.png` (tira horizontal de quadros quadrados).
- Depois: dona aprova o estilo → Tarefa 11 (outras lendas) → Tarefa 12 (site, teste em emulação, fechar v0.4.0).
**Why:** retomar sem reler a conversa.
**How to apply:** ao iniciar, ler isto, o ledger `.superpowers/sdd/2026-10-18-migracao-v0.4.0/progress.md` (se existir) e `git log --oneline -10`.
