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

| 18/10/2026 | Curupira (`152e57ff`) | criação, mais 4 animações por template e a esquiva em v3, oeste | standard/template/v3 | 6 | `curupira/*.png` |
| 18/10/2026 | Cuca (`819f616d`) | criação, mais 4 animações por template e a esquiva em v3, oeste | standard/template/v3 | 6 | `cuca/*.png` |
| 18/10/2026 | Boto (`c5f07c0e`) | criação, mais 4 animações por template e a esquiva em v3 (quadro de 112 px, 2 gerações), oeste | standard/template/v3 | 7 | `boto/*.png` |
| 18/10/2026 | Mapinguari (`bb039c89`) | criação (proporção heroica), mais 4 animações por template e a esquiva em v3 (quadro de 128 px, 2 gerações), oeste | standard/template/v3 | 7 | `mapinguari/*.png` |

**Saldo:** 2 das 40 gerações do trial. Faltam a Iara (sereia) e o Boitatá (cobra de fogo), que esperam o bônus diário e um formato que não seja humanoide.

**Prompt do herói:** "young Brazilian folklore guardian hero, brown skin, straw hat, simple linen shirt, rope belt, holding a wooden slingshot, barefoot, earthy brown and brass palette".

**Prompt do Saci:** "Saci-Pererê from Brazilian folklore, mischievous dark-skinned boy with a single leg, red pointed cap, red shorts, smoking a small clay pipe, playful grin". O modelo humanoide desenhou duas pernas.
