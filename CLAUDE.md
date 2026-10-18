# Guardiões do Folclore

Jogo de navegador no estilo Hero Zero com lendas do folclore brasileiro. Projeto "Hero Zero da Shoppe".
Repositório: https://github.com/AlexGamesProjects/Guardi-es-do-Folclore

## Fluxo de versões (obrigatório em toda mudança)
1. **Issue:** toda feature ou correção começa como uma issue, ligada ao milestone da versão (ex.: `v0.3.0`).
2. **Branch:** saia de `main` com nome `feat/<assunto>` ou `fix/<assunto>`.
3. **Durante o trabalho:** registre cada mudança em `CHANGELOG.md`, na seção `[Não lançado]`, nas categorias Adicionado, Alterado, Corrigido ou Removido.
4. **Pull request:** abra o PR para `main` usando o template, com "Closes #N", e espere a revisão da dona do projeto.
5. **Fechar a versão,** quando o milestone estiver completo:
   - Escolha o número pelo SemVer: feature nova = MENOR, ajuste = CORREÇÃO.
   - Atualize `config/version` em `game/project.godot` (de `X.Y.Z-dev` para `X.Y.Z`). Se o formato do save mudar, troque também a versão do save.
   - Mova `[Não lançado]` para `[x.y.z] - AAAA-MM-DD` no CHANGELOG e atualize os links no fim do arquivo.
   - Escreva `docs/versoes/vX.Y.Z.md` com objetivo, o que entrou, números de balanceamento, decisões e pendências.
   - Atualize `docs/ROADMAP.md`.
   - Não crie a tag manualmente. Quando o PR com o `config/version` novo entra no `main`, o workflow `release.yml` cria a tag `vX.Y.Z` e a Release com a nota da versão.
6. **Publicação:** o workflow `pages.yml` publica o `main` no GitHub Pages a cada push.
7. **Nunca faça push direto no `main`.** Tudo entra por PR revisado.

**Diário de avanços:** a cada decisão importante ou entrega, acrescente uma linha no topo do "Diário de avanços" em `docs/ROADMAP.md` e atualize o status das etapas.

Commits em português, no imperativo: "Adiciona ato IV", "Corrige recarga da coragem".

## Agentes por camada
O Claude principal é o **líder do jogo**: coordena o trabalho, decide regras e balanceamento, despacha tarefas e confere cada entrega. A implementação fica com agentes especializados, definidos em `.claude/agents/`:

| Agente | Camada |
|---|---|
| `infra-ci` | `tools/`, `.github/`, `project.godot`, export e publicação |
| `nucleo-regras` | `game/core/`, `game/data/` e seus testes |
| `estado-app` | `game/state/`, `game/app/`, save e inicialização |
| `interface` | `game/ui/` e painel de desempenho |
| `revisor` | Revisão independente de cada tarefa (somente leitura) |

Cada tarefa do plano vai para o agente da camada dela e passa pelo `revisor` antes da próxima. Um agente que precisar mexer fora da própria camada para e avisa o líder.

## Como rodar
O jogo novo é um projeto Godot 4.7.2 em `game/` (GDScript). A v0.2 em HTML continua em `legacy-web/` e é a que o GitHub Pages publica na raiz.

**Godot e testes** (Linux x86_64):
- `tools/setup_godot.sh` instala o Godot 4.7.2-stable em `$GODOT_BIN` (padrão `~/.local/bin/godot`) e os templates de export em `~/.local/share/godot/export_templates/4.7.2.stable/`. Confere o SHA-256 contra `tools/godot.sha256`. É idempotente.
- `tools/run_tests.sh [res://caminho]` importa o projeto e roda o GdUnit4 sem tela (padrão: `res://tests`). Sai com código ≠ 0 se houver falha.
- `tools/check_scripts.sh` confere cada GDScript fora de `addons/` no parser do Godot (`--check-only`), o que reprova código sem tipo mesmo que nenhum teste o carregue. Depende do `--import` feito antes pelo `run_tests.sh`.
- Para abrir o jogo: `godot --path game` (ou abra `game/project.godot` no editor).
- A versão do jogo fica em `game/project.godot`, `config/version`. Use `X.Y.Z-dev` durante o desenvolvimento; a Release só sai com `X.Y.Z` exato.
- Avisos de variável sem tipo são erro (`untyped_declaration=2`): declare o tipo de tudo. O GdUnit4 (v6.2.1) fica vendorizado em `game/addons/gdUnit4/`.

**v0.2 em HTML** (`legacy-web/`):
- Tudo está em `legacy-web/index.html` (HTML, CSS e JS num arquivo só, sem build). As ilustrações ficam em `legacy-web/assets/*.webp` (640×860).
- Para testar: `python3 -m http.server -d legacy-web 8000` e abrir `http://localhost:8000`. Abrir o arquivo direto (file://) também funciona.
- O progresso fica no `localStorage`, na chave `guardioes-folclore-v2`. Se o formato do save mudar, troque a chave e o campo `v`.

## Estrutura do repositório
- `game/`: projeto Godot, em camadas. Cada camada só depende das de baixo:
  - `core/`: regras puras (combate, progressão, energia, economia, sorteio `Rng` com semente). Só inteiros e pontos-base; sem `Node`, sem relógio e sem sorteio global. Um teste de arquitetura garante isso.
  - `data/packs/base/`: pacote de regras versionado em JSON (`manifest`, `legends`, `acts`, `balance`, `items`, `rivals`), validado ao carregar.
  - `state/`: `GameState`, `Command`, `CommandRouter`, handlers e save (`save/save_codec.gd`, `save/save_migrations.gd`).
  - `app/`: autoloads `Boot` (inicialização), `GameService` (`await GameService.send(tipo, params)`), `PerfOverlay`, mais `SaveService`, `FileIO`, executores e relógios.
  - `ui/`: telas (`menu`, `diagnostico`, `luta_teste`, `mode_badge`, `erro_regras`) e `theme.tres`. Telas não têm regra: só mandam comandos e mostram estado e eventos.
  - `tests/`: `unit/`, `contract/`, `regression/` (cópias de referência em `golden/`), `balance/`, `smoke/` e `support/`.
- `tools/`: `setup_godot.sh`, `run_tests.sh`, `check_scripts.sh`, `regen_golden.sh`, `bench.gd`, medições (`measure_size.py`, `measure_load.py`, `check_budgets.py`), limites em `perf_budgets.json`, `godot.sha256` e `gitleaks.sha256`.
- `legacy-web/`: a v0.2 em HTML, só manutenção de publicação.
- `.github/workflows/`: `ci.yml` (lint, testes, export, segredos e medições com comentário no PR), `pages.yml` (publica a v0.2 na raiz e o Godot em `/novo/`) e `release.yml` (cria a Release quando `config/version` vira `X.Y.Z`).
- `docs/`: roadmap, notas de versão, roteiro de teste no celular, especificação e plano da Fundação.

**Testes de regressão:** depois de uma mudança intencional de regra ou de balanceamento, rode `tools/regen_golden.sh` e confira o diff das cópias de referência antes do commit.

**Save do Godot:** JSON canônico com SHA-256, em `user://profiles/<perfil>.json` com reservas `.bak1` e `.bak2`. Se o formato mudar, suba `SaveCodec.SAVE_VERSION` e escreva a migração em `save_migrations.gd`.

## Estrutura do código da v0.2 (`legacy-web/index.html`, dentro do `<script>`)
- **Constantes de ritmo:** `EN_MAX`/`EN_MS` (energia: 100, +1 a cada 30 s), `CO_MAX`/`CO_MS` (coragem: 5, +1 a cada 2 min), `FEIRA_MS`, `CHEFE_EN`, `CHEFE_ESPERA`.
- **Dados:**
  - `CRI`: lendas, com nível de aparição, lugar, perfil de atributos (`perf`), frases de missão e texto do bestiário.
  - `ATOS`: os 3 atos da Torre dos Chefes, com 10 fases cada (nível 1–10, 11–20, 21–30).
  - `CURVA`: força média de um jogador típico por nível, tirada de uma simulação. Ela calibra os chefes.
  - `NOMES_ITEM`, `EPITETOS`, `RAR`: itens da Feira.
- **Estado `S`:** criado por `novo()`, salvo por `salvar()`. A regeneração de energia e coragem acontece em `regen()`, chamada a cada segundo pelo `tick()`.
- **Combate:**
  - `lutar(A,B)` gera o log de turnos: dano, crítico e esquiva.
  - `mostrarLuta()` toca as animações. As classes CSS são `atk`/`atkc` (ataque normal e crítico), `leva`/`levac` (alvo atingido), `esquiva`, `corte`, `tremor` e `flash`.
- **Telas:** `telaMissoes`, `telaChefes`, `telaArena`, `telaFeira`, `telaMochila` e `telaBestiario`.
- **Ações:** os cliques usam `data-act`, que chama a função correspondente no objeto `acoes`.

## Fórmulas (núcleo em inteiros; valores em `balance.json`)
Sufixos: `_pm` = por mil (1000 = 1×), `_bp` = pontos-base (10000 = 100%), `_x10` = décimos.
- Vida = `hp_base` 40 + Fôlego×8 + nível×12.
- Dano = (Força×17 + nível×25) / 10, variando de 800 a 1200 por mil (±20%).
- Crítico dobra o dano. A chance vem de Malícia contra o Fôlego do alvo, de 3% a 40%.
- Esquiva vem de Ginga contra a Força do atacante, de 3% a 35%.
- XP para subir de nível: tabela `xp_table` (60 × nível^1,45, arredondado).
- Custo de treino: tabela `train_cost` (8 × 1,11^(valor − 6), arredondado).
- Fase n da Torre (1–9): atributos = `curva`[nível] × (870 + 22n) / 1000 × perfil, ou seja, de 0,892× a 1,068×. Chefe (fase 10): × 1090 / 1000. Calibrado na v0.3.0 por `tests/balance` (fases 45–65% de vitória, chefes 20–40%, 425–575 missões até o nível 30).
- XP de missão = 12 + 4 × nível, multiplicado pela dificuldade.

## Decisões de conteúdo
- O Negrinho do Pastoreio é sempre aliado. Ele aparece só em tarefas e nunca como inimigo.
- Na v0.2 o herói é um SVG simples (`heroiSVG`); no Godot ainda não tem arte. Falta uma ilustração do protagonista, de preferência com opções de escolha.

## Próximos passos sugeridos
- Arte do herói e de outras lendas (Mula sem Cabeça, Lobisomem, Caipora, Matinta Perera).
- Separar o código em módulos (dados, combate, UI) se o projeto crescer.
- Backend e contas, para salvar o progresso entre aparelhos e ter ranking real na Arena.
- Ajustar os tempos das missões (hoje são de 20 s a 1:30, para testes).
