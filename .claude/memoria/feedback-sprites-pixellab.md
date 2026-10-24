---
name: feedback-sprites-pixellab
description: Como gerar e trazer sprites do PixelLab sem gastar dinheiro
type: feedback
---
- Gerar as lendas aos poucos, com as gerações grátis: o trial tem 40, mais o bônus diário (+5 por noite, até 20). Não assinar plano.
- O plano trial roda 1 job por vez. Espere com um `sleep` em segundo plano, não com sondagem.
- Por lenda: `create_character` standard, 64 px, vista "side", 4 direções; depois parado, ataque (cross-punch), golpe (taking-punch) e derrota (falling-back-death) por template, mais a esquiva em v3. Inimigos olham para oeste.
- A nuvem e o terminal do computador não baixam do PixelLab. A dona baixa o zip pelo link `api.pixellab.ai/mcp/characters/<id>/download` e anexa no chat. As tiras saem de `<acao>/<dir>/frame_*.png`, coladas num quadro quadrado.
**Why:** a dona prefere o caminho grátis e fazer aos poucos.
**How to apply:** ao gerar uma lenda nova, seguir esses passos e registrar o custo em `docs/arte/pixellab.md`.

**Decisão de 19/10/2026:** a dona aprovou trocar as tiras por um esqueleto único (Skeleton2D + AnimationPlayer) a partir da v0.4.1. Antes, um protótipo com o Saci para ela comparar (issue #32). A Iara ainda sai em tiras na v0.4.0.
