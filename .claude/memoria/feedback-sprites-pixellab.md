---
name: feedback-sprites-pixellab
description: Como gerar e trazer sprites do PixelLab sem gastar dinheiro
type: feedback
---
- Gerar as lendas aos poucos, com as gerações grátis: o trial tem 40, mais o bônus diário (+5 por noite, até 20). Não assinar plano.
- O plano trial roda 1 job por vez. Espere com um `sleep` em segundo plano, não com sondagem.
- Por lenda: `create_character` standard, 64 px, vista "side", 4 direções; depois parado, ataque (cross-punch), golpe (taking-punch) e derrota (falling-back-death) por template, mais a esquiva em v3. Inimigos olham para oeste.
- No PC da dona (desde 25/10/2026) o MCP do PixelLab está ligado no Claude Code e o curl baixa o zip direto de `api.pixellab.ai/mcp/characters/<id>/download`; na nuvem, a dona baixa e anexa. As tiras saem de `<acao>/<dir>/frame_*.png`, coladas num quadro quadrado.
**Why:** a dona prefere o caminho grátis e fazer aos poucos.
**How to apply:** ao gerar uma lenda nova, seguir esses passos e registrar o custo em `docs/arte/pixellab.md`.

**Decisão de 24/10/2026:** as lendas ficam com as 7 animações desenhadas (tiras do PixelLab). O esqueleto único (#32) foi testado nas 6 lendas e reprovado pela dona: partes rígidas de 1 quadro ficam feias e destoam no combate. Registro na branch `feat/esqueleto-lendas`. O guardião também terá o corpo em tiras, com a cabeça em blocos por cima (#1).
