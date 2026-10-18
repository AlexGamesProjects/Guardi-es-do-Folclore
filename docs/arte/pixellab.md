# Registro de gerações do PixelLab

Plano: trial (40 gerações + bônus diário). Uma geração por vez, com 2 a 15 minutos cada. Os arquivos são baixados do PixelLab (zip do personagem) e montados em tiras por ação, em `game/assets/sprites/<id>/<acao>.png`.

| Data | Personagem | O que | Modo | Custo | Arquivo |
|---|---|---|---|---|---|
| 18/10/2026 | Herói (`c0a26aec`) | criação, 4 direções, 64 px, vista lateral | standard | 1 | — |
| 18/10/2026 | Herói | parado (fight-stance-idle-8-frames), leste | template | 1 | `heroi/parado.png` |
| 18/10/2026 | Herói | ataque (cross-punch), leste | template | 1 | `heroi/ataque.png` |
| 18/10/2026 | Herói | golpe (taking-punch), leste | template | 1 | `heroi/golpe.png` |
| 18/10/2026 | Herói | derrota (falling-back-death), leste | template | 1 | `heroi/derrota.png` |
| 18/10/2026 | Herói | esquiva ("quickly dodging backwards…"), leste | v3, 6 quadros | 1 | `heroi/esquiva.png` |
| 18/10/2026 | Saci (`5f0d6f83`) | criação, 4 direções, 64 px, vista lateral | standard | 1 | — |
| 18/10/2026 | Saci | parado, ataque, golpe e derrota (templates), oeste | template | 4 | `saci/*.png` |
| 18/10/2026 | Saci | esquiva ("quickly hopping backwards…"), oeste | v3, 6 quadros | 1 | `saci/esquiva.png` |

**Total do piloto:** 12 gerações.

**Prompt do herói:** "young Brazilian folklore guardian hero, brown skin, straw hat, simple linen shirt, rope belt, holding a wooden slingshot, barefoot, earthy brown and brass palette".

**Prompt do Saci:** "Saci-Pererê from Brazilian folklore, mischievous dark-skinned boy with a single leg, red pointed cap, red shorts, smoking a small clay pipe, playful grin". O modelo humanoide desenhou duas pernas.
