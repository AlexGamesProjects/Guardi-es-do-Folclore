# Fundação em Godot · Plano de implementação

> **Para agentes:** SUB-SKILL OBRIGATÓRIA: use superpowers:subagent-driven-development (recomendado) ou superpowers:executing-plans para executar este plano tarefa por tarefa. Os passos usam checkbox (`- [ ]`) para acompanhamento.

**Objetivo:** levar o Guardiões do Folclore para o Godot 4.7.2 com um núcleo de regras puro e testado, comandos assíncronos, save seguro com perfis por modo, CI com limites de desempenho e uma casca mínima jogável publicada em `/novo/`.

**Arquitetura:** cinco camadas (`core/` → `data/` → `state/` → `app/` → `ui/`). As regras vivem em funções estáticas puras, com aritmética inteira e sorteio com semente. Toda mudança de estado é um `Command` aplicado por um `CommandExecutor` aguardável (`await`), que devolve o novo estado e a lista de eventos que as telas animam.

**Stack:** Godot 4.7.2 (GDScript tipado), GdUnit4 v6.2.1 (vendorizado), gdtoolkit 4.3.4 (pip), GitHub Actions, Playwright para Python (Chromium já instalado em `/opt/pw-browsers`), Python 3 nos scripts de `tools/`.

**Especificação:** `docs/superpowers/specs/2026-10-17-fundacao-godot-design.md`. Leia a especificação junto com este plano.

## Restrições globais

- Godot **4.7.2-stable**, GdUnit4 **v6.2.1**, gdtoolkit **4.3.4**. Ações do GitHub fixadas pelo SHA do commit, resolvido com `git ls-remote`.
- `core/`: não estende `Node`; não usa `get_tree`, `Time.*`, `OS.get_ticks*`, `randi()`, `randf()`, `randomize()`, `randi_range` global nem o token `float`. Chances em pontos-base (10000 = 100%) e multiplicadores em permilagem (1000 = 1,0×).
- Pacote de regras em JSON (`game/data/packs/base/`) com `manifest.json` contendo `schema_version` e `rules_version`. Pacote inválido impede o jogo de iniciar.
- **O Godot lê todo número de JSON como `float`.** Todo `from_dict` converte explicitamente com `int()`. Sementes ficam abaixo de 2^31.
- Constantes da v0.2, mantidas em `balance.json`: energia máxima 100, +1 a cada 30000 ms; coragem máxima 5, +1 a cada 120000 ms; feira renova a cada 600000 ms; mochila com 14 itens; chefe custa 12 de energia; espera após derrota no chefe de 90000 ms.
- Tela base de 720×1280 na vertical, `stretch/mode=canvas_items`, `stretch/aspect=expand`.
- Export web com `variant/thread_support=false`.
- Nome do guardião: sem espaços nas pontas, sem caracteres de controle, de 1 a 18 caracteres; o padrão é `"Jaci"`.
- Save: no máximo uma gravação a cada 2000 ms, mais uma sempre que o app vai para segundo plano; 2 cópias de reserva; hash SHA-256 do JSON canônico (chaves ordenadas).
- Indicador de espera de comando depois de 300 ms. O teste assíncrono usa atraso de 500 ms.
- Limites de desempenho (calibráveis na Tarefa 14): download compactado ≤ 12 MB; carregamento em "4G" ≤ 5000 ms; 10 mil lutas ≤ 2000 ms; aplicar um comando ≤ 1 ms (p95).
- "4G" é definido como 9000 kbit/s de download, 1500 kbit/s de upload e 60 ms de latência.
- Faixas de balanceamento: 4500 a 6500 pontos-base de vitória nas fases 1 a 9 no nível certo; 2000 a 4000 nos chefes; nível 30 entre 425 e 575 missões médias.
- Versão em `game/project.godot` → `config/version`. Use `"0.3.0-dev"` até a Tarefa 14. A Release só sai com `X.Y.Z` exato.
- Commits em português, no imperativo, terminando com as linhas `Co-Authored-By` e `Claude-Session` da sessão.
- O Negrinho do Pastoreio é sempre aliado: nunca aparece em luta, fase ou rival.

## Foco de revisão

1. **Toque duplo:** o jogador toca duas vezes num botão enquanto um comando ainda está pendente. Esperado: o segundo comando é recusado com `OCUPADO` e nada é aplicado duas vezes. Teste: Tarefa 9, `test_second_send_while_busy_is_rejected`.
2. **Números depois de salvar e carregar:** todo campo inteiro volta como `TYPE_INT`, inclusive sementes perto de 2^31. Teste: Tarefa 10, `test_roundtrip_keeps_int_types`.
3. **Nome do guardião malformado:** vazio, só espaços, 200 caracteres, quebra de linha, aspas e emoji. Esperado: o nome é saneado (emoji é permitido) e nunca quebra o JSON. Teste: Tarefa 8, `test_rename_sanitizes`.
4. **Save principal e as duas reservas corrompidos:** esperado um perfil novo com aviso `SAVE_RECRIADO`, sem travar o jogo. Teste: Tarefa 10, `test_all_copies_corrupt_starts_fresh_with_warning`.
5. **Falha de escrita** (cota do navegador cheia ou disco cheio): esperado que o jogo continue, emita o aviso `SAVE_FALHOU` e mantenha o arquivo anterior intacto. Teste: Tarefa 10, `test_write_failure_keeps_previous_file`.

## Protocolo de execução

Quatro PRs, cada um com a sua issue no milestone "v0.3.0 · Fundação", criada no início do grupo, e com `Closes #N` no PR:

- **PR A:** Tarefas 1 a 3, repositório, CI e medições.
- **PR B:** Tarefas 4 a 7, núcleo de regras.
- **PR C:** Tarefas 8 a 12, estado, comandos, save e testes de regressão e balanceamento.
- **PR D:** Tarefas 13 e 14, casca jogável e fechamento da v0.3.0.

Branches: `feat/fundacao-a-ci`, `feat/fundacao-b-core`, `feat/fundacao-c-estado` e `feat/fundacao-d-casca`, cada um saindo do `main` atualizado depois do merge do anterior. Em cada PR, acrescentar uma linha ao `CHANGELOG.md` em `[Não lançado]` e uma linha no topo do diário de avanços em `docs/ROADMAP.md`.

**Pré-requisito:** o PR #8 (Release automática) já está no `main`.

## Mapa de arquivos

```
legacy-web/index.html, legacy-web/assets/*      (movidos da raiz)
game/project.godot, game/export_presets.cfg, game/icon.svg
game/addons/gdUnit4/                             (vendorizado v6.2.1)
game/core/rng/rng.gd                             Rng
game/core/rules/{rules_pack.gd, defs.gd, rules_loader.gd}
game/core/combat/{fighter.gd, combat.gd}
game/core/progression/progression.gd
game/core/stamina/stamina.gd
game/core/economy/{items.gd, missions.gd, rivals.gd, stages.gd}
game/data/packs/base/{manifest,legends,acts,balance,items,rivals}.json
game/state/{game_state.gd, command.gd, command_result.gd, command_router.gd}
game/state/handlers/{mission_handler.gd, training_handler.gd, stage_handler.gd, shop_handler.gd, arena_handler.gd, profile_handler.gd}
game/state/save/{save_codec.gd, save_migrations.gd}
game/app/{clock.gd, command_executor.gd, local_executor.gd, game_service.gd, save_service.gd, file_io.gd, perf_overlay.gd}
game/ui/{menu.tscn/.gd, diagnostico.tscn/.gd, luta_teste.tscn/.gd, mode_badge.tscn/.gd}
game/tests/{unit,data,regression,balance,architecture,async,smoke,fixtures}/
tools/{setup_godot.sh, godot.sha256, run_tests.sh, gen_tables.py, bench.gd, measure_size.py, measure_load.py, check_budgets.py, perf_budgets.json, regen_golden.sh}
.github/actions/setup-godot/action.yml
.github/workflows/{ci.yml, pages.yml, release.yml}
docs/versoes/v0.3.0.md, docs/teste-celular.md
```

---

### Tarefa 1: Mover a v0.2 e criar o projeto Godot com o ambiente de testes

**Arquivos:**
- Mover: `index.html` → `legacy-web/index.html`; `assets/` → `legacy-web/assets/`
- Criar: `game/project.godot`, `game/icon.svg`, `game/main.tscn`, `game/main.gd`, `game/addons/gdUnit4/`, `tools/setup_godot.sh`, `tools/godot.sha256`, `tools/run_tests.sh`, `game/tests/unit/harness_test.gd`
- Modificar: `.github/workflows/pages.yml`, `.github/workflows/release.yml`, `CLAUDE.md` (seções "Como rodar" e "Estrutura do código"), `README.md`

**Interfaces:**
- Produz: `tools/setup_godot.sh` instala o Godot em `$GODOT_BIN` (padrão `~/.local/bin/godot`) e os templates de export em `~/.local/share/godot/export_templates/4.7.2.stable/`. `tools/run_tests.sh [res://caminho]` roda o GdUnit4 sem tela e devolve código ≠ 0 quando há falha.

- [ ] **Passo 1:** Mover a v0.2 com `git mv` e conferir que `legacy-web/index.html` abre localmente com `python3 -m http.server -d legacy-web`, mostrando "Versão 0.2.0" no rodapé.
- [ ] **Passo 2:** Escrever `tools/setup_godot.sh`. Ele baixa `Godot_v4.7.2-stable_linux.x86_64.zip` e `Godot_v4.7.2-stable_export_templates.tpz` das releases do GitHub e confere o SHA-256 contra `tools/godot.sha256`. Na primeira execução, calcular e gravar os hashes, conferindo-os com o arquivo `SHA512-SUMS.txt` da release. O script é idempotente. Rodar e conferir com `godot --version`, que deve mostrar `4.7.2.stable`.
- [ ] **Passo 3:** Criar `game/project.godot` com:
  - `config/name="Guardiões do Folclore"` e `config/version="0.3.0-dev"`;
  - cena principal `res://main.tscn`;
  - tela de 720×1280 na vertical, com `canvas_items` e `expand`;
  - `debug/gdscript/warnings/untyped_declaration=2` (erro);
  - GdUnit4 habilitado.

  Vendorizar o GdUnit4 v6.2.1 em `game/addons/gdUnit4/` a partir do zip da tag.
- [ ] **Passo 4:** Escrever o teste que falha, `game/tests/unit/harness_test.gd`:
  ```gdscript
  extends GdUnitTestSuite
  func test_version_is_dev() -> void:
      assert_str(ProjectSettings.get_setting("application/config/version")).is_equal("0.3.0-dev")
  ```
  Antes do Passo 3 estar completo, `tools/run_tests.sh` reprova. Depois, passa. O script roda `godot --headless --path game --import` e depois o runner de linha de comando do GdUnit4 sobre `res://tests`.
- [ ] **Passo 5:** `main.gd` (Node2D) mostra "Guardiões do Folclore 0.3.0-dev" num `Label` e executa `print("GF_READY")` no `_ready`. Esse sinal é usado pela medição de carregamento.
- [ ] **Passo 6:** Atualizar os workflows:
  - `pages.yml`: publica `legacy-web/` na raiz do site, por enquanto sem `/novo/`.
  - `release.yml`: lê a versão com `grep -oP '^config/version="\K[0-9]+\.[0-9]+\.[0-9]+(?=")' game/project.godot`; o caminho de disparo passa a ser `game/project.godot` no lugar de `index.html`; se o grep não encontrar `X.Y.Z` exato, o workflow sai com sucesso sem criar nada.
  - Conferir com `python3 -c "import yaml;yaml.safe_load(open(...))"` nos dois arquivos.
- [ ] **Passo 7:** Atualizar o `CLAUDE.md` (como rodar o Godot e os testes, e as novas pastas) e o `README.md`. Fazer o commit: "Move a v0.2 para legacy-web e cria o projeto Godot com testes".

### Tarefa 2: CI de qualidade, testes, export web e segredos

**Arquivos:**
- Criar: `.github/actions/setup-godot/action.yml`, `.github/workflows/ci.yml`, `game/export_presets.cfg`, `game/gdlintrc`, `.gitleaks.toml`
- Modificar: `.github/workflows/pages.yml` (passa a incluir `/novo/`)

**Interfaces:**
- Consome: `tools/setup_godot.sh` e `tools/run_tests.sh` (Tarefa 1).
- Produz: os jobs `lint`, `test`, `export-web` e `secrets` no `ci.yml`. O `export-web` envia o artefato `web-build`, com o conteúdo de `build/web/`, que a Tarefa 3 consome.

- [ ] **Passo 1:** Criar a ação composta `setup-godot`: guarda os binários e os templates em cache, com a chave baseada no hash de `tools/godot.sha256`, e roda `tools/setup_godot.sh`.
- [ ] **Passo 2:** Criar `export_presets.cfg` com o preset `Web`, `variant/thread_support=false` e saída `../build/web/index.html`. Conferir localmente com `godot --headless --path game --export-release Web ../build/web/index.html`, que deve gerar `index.html`, `index.wasm` e `index.pck`.
- [ ] **Passo 3:** Criar o `ci.yml`, disparado em `pull_request` e em `push` para o `main`:
  - `lint`: `pip install gdtoolkit==4.3.4`, depois `gdformat --check` e `gdlint` sobre `git ls-files 'game/*.gd' ':!game/addons/**'`, para não checar o GdUnit4 vendorizado.
  - `test`: `tools/run_tests.sh`.
  - `export-web`: exporta e envia o artefato.
  - `secrets`: gitleaks fixado por SHA.

  Fixar todas as ações por SHA, resolvido com `git ls-remote https://github.com/<ação> refs/tags/<versão>`, e anotar a versão num comentário ao lado de cada uma.
- [ ] **Passo 4:** No `pages.yml`, acrescentar a exportação do Godot (usando a ação composta) e copiar `build/web/` para `_site/novo/`.
- [ ] **Passo 5:** Verificar:
  - Abrir um PR de teste com um GDScript sem tipo: o `lint` ou o `test` precisa reprovar.
  - Colocar uma chave falsa `ghp_` seguida de 36 caracteres num arquivo de teste: o `secrets` precisa reprovar.
  - Depois, reverter as duas coisas.
- [ ] **Passo 6:** Fazer o commit: "Adiciona CI com lint, testes, export web e verificação de segredos".

### Tarefa 3: Medições, limites e relatório no PR

**Arquivos:**
- Criar: `tools/measure_size.py`, `tools/measure_load.py`, `tools/check_budgets.py`, `tools/perf_budgets.json`, `tools/test_check_budgets.py`
- Modificar: `.github/workflows/ci.yml` (job `measure`)

**Interfaces:**
- Consome: o artefato `web-build` (Tarefa 2).
- Produz: `metrics.json`, um objeto plano com chaves inteiras: `download_gz_bytes`, `load_ms` e, a partir da Tarefa 6, `fights_10k_ms` e `command_p95_us`. A comparação é `check_budgets.py --metrics metrics.json --baseline baseline.json --budgets tools/perf_budgets.json --out report.md`, que sai com código 1 se algum limite for excedido. Métricas ausentes viram "—" e não reprovam.

- [ ] **Passo 1:** Escrever o teste que falha, `tools/test_check_budgets.py` (pytest):
  - `test_over_budget_exits_1`: `{"download_gz_bytes": 13_000_000}` contra o limite `12_000_000` dá código de saída 1 e o relatório contém "❌".
  - `test_missing_metric_is_dash`: uma métrica ausente aparece como "—" e o código de saída é 0.
  - `test_table_has_main_and_pr_columns`: o relatório tem as colunas "Medida | main | PR | Limite".

  Rodar `pytest tools/test_check_budgets.py` e confirmar que FALHA.
- [ ] **Passo 2:** Implementar o `check_budgets.py`, com `perf_budgets.json = {"download_gz_bytes": 12000000, "load_ms": 5000, "fights_10k_ms": 2000, "command_p95_us": 1000}`. Rodar o pytest e confirmar que PASSA.
- [ ] **Passo 3:** `measure_size.py build/web` soma o tamanho de cada arquivo comprimido com `gzip -9`.

  `measure_load.py build/web`:
  - serve a pasta com `http.server` numa porta livre;
  - abre o Chromium do Playwright com CDP `Network.emulateNetworkConditions` (latência 60, download 9000 kbit/s, upload 1500 kbit/s, convertidos para bytes/s);
  - mede da navegação até a mensagem de console `GF_READY`, com teto de 30 s;
  - roda 3 vezes e usa a mediana.

  Os dois scripts acrescentam as chaves em `metrics.json`.
- [ ] **Passo 4:** Job `measure` no `ci.yml`:
  1. baixa o `web-build` e roda os dois scripts;
  2. no `push` para o `main`, envia `metrics.json` como artefato `metrics-main`;
  3. no PR, baixa o `metrics-main` mais recente com `gh run list --branch main --workflow ci.yml --status success -L 1 --json databaseId` e `gh run download`;
  4. roda o `check_budgets.py` e publica ou atualiza um único comentário no PR (marcado com `<!-- gf-metrics -->`) via `gh api`.

  Permissões do job: `pull-requests: write` e `actions: read`.
- [ ] **Passo 5:** Verificar num PR real: o comentário aparece com valores reais de download e carregamento. Anotar esses valores para a Tarefa 14.
- [ ] **Passo 6:** Fazer o commit: "Adiciona medições de desempenho com limites e relatório no PR".

**Abrir o PR A**, com `Closes` da issue do grupo A, e esperar a revisão.

---

### Tarefa 4: Sorteio com semente e teste de arquitetura

**Arquivos:**
- Criar: `game/core/rng/rng.gd`, `game/tests/unit/rng_test.gd`, `game/tests/architecture/core_purity_test.gd`

**Interfaces:**
- Produz: `class_name Rng extends RefCounted`, com:
  - `_init(seed_value: int)`;
  - `next_int(max_exclusive: int) -> int`;
  - `range_int(lo: int, hi_inclusive: int) -> int`;
  - `roll_bp(chance_bp: int) -> bool`;
  - `pick(arr: Array) -> Variant`;
  - `get_state() -> int` e `set_state(s: int) -> void`;
  - `static derive_seed(base: int, n: int) -> int`, sempre em `[0, 2^31)`.

  Por dentro, usa um `RandomNumberGenerator` próprio da instância, com `seed` e `state` definidos.

- [ ] **Passo 1:** Testes que falham:
  - `test_same_seed_same_sequence`: duas instâncias com a semente 42 produzem as mesmas 1000 chamadas de `next_int(100)`.
  - `test_state_restore`: guardar o estado, consumir valores, restaurar e reproduzir a mesma sequência.
  - `test_roll_bp_bounds`: `roll_bp(0)` é sempre falso e `roll_bp(10000)` é sempre verdadeiro, em 1000 chamadas.
  - `test_derive_seed_range_and_stable`: `derive_seed(7, 3)` é igual entre chamadas, fica em `[0, 2147483648)` e é diferente de `derive_seed(7, 4)`.
- [ ] **Passo 2:** Teste de arquitetura `core_purity_test.gd`. Ele percorre `res://core/**/*.gd` e reprova, listando arquivo e linha, quando encontra:
  - `extends Node`;
  - `get_tree`;
  - `Time.`;
  - `OS.get_ticks`;
  - `\bfloat\b`;
  - chamadas globais `(?<![\w.])(randi|randf|randomize|randi_range|randf_range)\(`.

  Também inclui `test_detector_catches_violation`, que roda o detector sobre um texto embutido e confirma que ele acusa a violação.
- [ ] **Passo 3:** Rodar `tools/run_tests.sh res://tests/unit/rng_test.gd` e confirmar que FALHA. Implementar `rng.gd`. Rodar a suíte inteira e confirmar que PASSA.
- [ ] **Passo 4:** Fazer o commit: "Adiciona sorteio com semente e teste de pureza do núcleo".

### Tarefa 5: Pacote de regras base, carregador e testes de contrato

**Arquivos:**
- Criar: `tools/gen_tables.py`, `game/data/packs/base/*.json`, `game/core/rules/defs.gd`, `game/core/rules/rules_pack.gd`, `game/core/rules/rules_loader.gd`, `game/tests/data/rules_contract_test.gd`, `game/tests/fixtures/packs/broken_*/`

**Interfaces:**
- Produz: `class_name RulesLoader`, com `static load_dir(path: String) -> RulesLoadResult` (`ok: bool`, `errors: PackedStringArray`, `pack: RulesPack`).
- Produz: `class_name RulesPack extends RefCounted`, com os campos:
  - `schema_version: int` e `rules_version: String`;
  - `legends: Dictionary[String, LegendDef]`;
  - `acts: Array[ActDef]`;
  - `balance: BalanceDef`;
  - `item_names: Dictionary[String, PackedStringArray]` e `epithets: PackedStringArray`;
  - `rarities: Array[RarityDef]`;
  - `rival_first: PackedStringArray` e `rival_last: PackedStringArray`.
- Produz, em `defs.gd`:
  - `LegendDef`: `id`, `nome`, `lvl`, `lugar`, `ally: bool`, `perf_pm: Dictionary[String,int]`, `tarefas`, `lutas`, `lore`.
  - `ActDef`: `nome`, `de`, `ate`, `capa`, `stages: Array[StageDef]`.
  - `StageDef`: `nome`, `legend_id`.
  - `RarityDef`: `nome`, `mult_pm`.
  - `BalanceDef`: todas as constantes globais, mais `curva: PackedInt32Array` (31 valores), `xp_table` (índice = nível, de 1 a 40), `train_cost` (índice = valor do atributo, de 1 a 200), `ranks`, `mission`, `stage`, `item`, `rival` e `bands`.

- [ ] **Passo 1:** Escrever o `gen_tables.py`. Ele gera:
  - `xp_table[l] = round(60 * l**1.45)` para `l` de 1 a 40;
  - `train_cost[v] = round(8 * 1.11**(v-6))` para `v` de 1 a 200, com piso de 1.

  O resultado vai para `balance.json`. Transcrever de `legacy-web/index.html` (linhas 341 a 447) as constantes `CRI`, `ATOS`, `CURVA`, `RANKS`, `PRIM`, `NOMES_ITEM`, `EPITETOS`, `RAR`, `RIV_N` e `RIV_A`, multiplicando os valores de `perf` e `RAR.m` por 1000 (permilagem). Valores de missão (de `genMissao`, linha 484):
  - duração em segundos `[20, 45, 90]`;
  - energia `[6, 10, 15]`;
  - multiplicador de dificuldade `[1000, 1600, 2400]`;
  - multiplicador de luta 1300;
  - multiplicador por nível da lenda: 1000 + 20 × nível.

  Valores das fases (de `inimigoFase`, linha 510):
  - multiplicador da fase n (0 a 8) = 800 + 22 × (n + 1);
  - multiplicador do chefe = 1120;
  - XP da recompensa = 180 por mil do XP do nível, ou 500 por mil no chefe;
  - vinténs = (40 + 25 × nível), multiplicados por 3 no chefe.

  Nos manifestos: `schema_version` 1 e `rules_version` "1.0.0".
- [ ] **Passo 2:** Testes que falham em `rules_contract_test.gd`:
  - `test_base_pack_loads_ok`: `RulesLoader.load_dir("res://data/packs/base")`, com `ok` verdadeiro e `errors` vazio.
  - `test_base_counts`: 8 lendas, 3 atos de 10 fases e `curva.size() == 31`.
  - `test_negrinho_is_ally_and_never_in_stages`.
  - `test_every_stage_legend_exists_and_unlocked_by_act_end`: o nível da lenda é menor ou igual ao `ate` do ato.
  - `test_values_in_range`: todo `perf_pm` fica em [500, 2000]; nenhum preço, custo ou duração é ≤ 0.
  - `test_ints_not_floats`: `typeof(pack.balance.en_max) == TYPE_INT`.
  - Para cada fixture em `fixtures/packs/broken_*`, o carregador devolve `ok == false` com a mensagem esperada, que fica em `expected_error.txt` dentro da fixture. Fixtures:
    - `broken_missing_field` (lenda sem `perf`);
    - `broken_bad_ref` (fase aponta para `"zumbi"`);
    - `broken_negative` (preço negativo);
    - `broken_schema` (`schema_version` 99).
- [ ] **Passo 3:** Rodar os testes e confirmar que FALHAM. Implementar `defs.gd`, `rules_pack.gd` e `rules_loader.gd`, com validação que acumula todos os erros, não só o primeiro. Rodar de novo e confirmar que PASSAM.
- [ ] **Passo 4:** Fazer o commit: "Adiciona pacote de regras base versionado e validado".

### Tarefa 6: Combate

**Arquivos:**
- Criar: `game/core/combat/fighter.gd`, `game/core/combat/combat.gd`, `game/tests/unit/combat_test.gd`, `tools/bench.gd`
- Modificar: `.github/workflows/ci.yml` (o job `measure` passa a rodar o `bench.gd`)

**Interfaces:**
- Produz: `class_name Fighter extends RefCounted`, com os campos `nome: String`, `lvl: int`, `stats: Dictionary[String,int]` (chaves `for`, `fol`, `mal`, `gin`) e `legend_id: String` (vazio para o herói ou um rival), mais `static make(nome, lvl, stats, legend_id := "") -> Fighter` e `max_hp() -> int`, que retorna `40 + fol*8 + lvl*12`.
- Produz: `class_name Combat`, com `static simulate(a: Fighter, b: Fighter, rng: Rng, max_turns := 40) -> CombatResult`. `CombatResult` tem `win: bool` (do ponto de vista de `a`), `hp_final: PackedInt32Array` e `events: Array[Dictionary]`. Cada evento tem a forma `{"type": "golpe"|"critico"|"esquiva", "atacante": 0|1, "dano": int, "hp": [int, int]}`, e ao final vem `{"type": "fim", "vencedor": 0|1}`.
- Regras em inteiros:
  - iniciativa: `a` começa se `a.gin + rng.range_int(0,5) >= b.gin + rng.range_int(0,5)`;
  - esquiva em pontos-base: `clamp(gin_def*5500/(gin_def+for_atk+30), 300, 3500)`;
  - crítico em pontos-base: `clamp(mal_atk*6000/(mal_atk+fol_def+30), 300, 4000)`;
  - dano base ×10: `for*17 + lvl*25`;
  - dano: `max(1, (base_x10 * rng.range_int(800,1200) + 5000) / 10000)`, dobrado no crítico;
  - vitória de `a` se a vida de `b` ≤ 0, ou se `a` está vivo e `hp_a*max_b >= hp_b*max_a`.

- [ ] **Passo 1:** Testes que falham:
  - `test_max_hp_formula`: `fol` 10 e nível 1 dão 132.
  - `test_dodge_crit_bp_clamped`: casos extremos chegam a 300 e 3500/4000.
  - `test_same_seed_same_events`.
  - `test_damage_never_below_1`.
  - `test_ends_within_max_turns`.
  - `test_strong_beats_weak_mostly`: atributos 40 contra 15, 200 sementes, mais de 95% de vitórias.
  - `test_equal_fighters_near_half`: atributos iguais, 2000 sementes, vitórias entre 4500 e 5500 pontos-base.
- [ ] **Passo 2:** Rodar e confirmar que FALHAM. Implementar. Rodar e confirmar que PASSAM.
- [ ] **Passo 3:** `tools/bench.gd` (rodado com `godot --headless --path game -s ../tools/bench.gd`) simula 10 mil lutas com atributos 40, cronometra com `Time.get_ticks_usec()` (permitido fora do `core/`) e acrescenta `fights_10k_ms` em `metrics.json`. Ligar o script no job `measure`.
- [ ] **Passo 4:** Fazer o commit: "Adiciona simulação de combate deterministica em inteiros".

### Tarefa 7: Progressão, energia, itens, missões, fases e rivais

**Arquivos:**
- Criar: `game/core/progression/progression.gd`, `game/core/stamina/stamina.gd`, `game/core/economy/{items.gd, missions.gd, stages.gd, rivals.gd}` e um arquivo de teste por módulo em `game/tests/unit/`

**Interfaces:**
- Produz `Progression`:
  - `static add_xp(lvl: int, xp: int, gain: int, rules: RulesPack) -> Dictionary`, que devolve `{lvl, xp, levels_gained}`;
  - `static train_cost(value: int, rules) -> int`;
  - `static rank(lvl: int, rules) -> String`.
- Produz `Stamina`: `static regen(cur: int, upd_ms: int, now_ms: int, max_v: int, step_ms: int) -> Dictionary`, que devolve `{cur, upd_ms}`, e `static spend(cur: int, upd_ms: int, now_ms: int, max_v: int, amount: int) -> Dictionary`. Regras:
  - relógio voltando no tempo: `upd_ms = now_ms`, sem ganho;
  - acima do máximo: `upd_ms = now_ms`;
  - ganho = `(now - upd) / step`, limitado ao máximo, com `upd += ganho*step`;
  - ao gastar estando cheio, o relógio de recarga reinicia.
- Produz `Items`: `static generate(lvl: int, slot: String, rarity_min: int, rng: Rng, rules) -> Dictionary`. O item é `{id: int, slot, nome, rar, st: {stat: int}, preco: int}`, com:
  - `pts = (40 + 16*lvl) * mult_pm / 10000`;
  - atributo principal = `ceil(pts*6/10)`;
  - o restante vai para um atributo secundário sorteado;
  - `preco = pts*10*(100 + 8*lvl)/100`;
  - raridade sorteada com 6% lendária e 26% rara;
  - o `id` vem de `state.uid`, passado pelo handler.
- Produz `Missions`: `static generate(lvl: int, uid: int, rng, rules) -> Dictionary` (só lendas com `lvl <= nível`; lenda aliada nunca é luta; 60% de chance de luta) e `static enemy_for(mission, hero_stats, lvl, rng, rules) -> Fighter`, com multiplicador por dificuldade `[780, 950, 1120]` × `perf_pm` × `range_int(900, 1100)`, piso 3.
- Produz `Stages`: `static enemy(act: int, n: int, rules) -> Fighter`, `static required_level(act, n, rules) -> int` e `static reward(act, n, rules) -> Dictionary`, que devolve `{xp, vint, muir, item_rarity_min}`.
- Produz `Rivals`: `static generate(hero_lvl: int, hero_stats: Dictionary, honra: int, uid: int, rng, rules) -> Dictionary`, portado de `genRival`, linha 504, em permilagem.

- [ ] **Passo 1:** Testes que falham, com os valores exatos:
  - `test_level_up_carries_xp`: nível 1, XP 50, ganho de 20 resulta em nível 2 com XP 10 (`xp_table[1]` = 60).
  - `test_multi_level_gain`.
  - `test_train_cost_table`: `train_cost(10) == 12`, `train_cost(6) == 8`.
  - `test_regen_partial`: 0 de energia, 65 s depois, com passo de 30 s, resulta em 2 de energia e `upd` avançado 60000.
  - `test_regen_clock_back_no_gain`.
  - `test_regen_years_forward_caps_at_max`.
  - `test_spend_from_full_resets_timer`.
  - `test_item_points_and_price`: nível 10, raridade comum: `pts` = 20, principal = 12, preço = 360.
  - `test_ally_never_fight`: 500 sementes.
  - `test_missions_respect_unlock_level`.
  - `test_stage_required_level`: ato 1, fase 0 → 11.
  - `test_boss_reward`: ato 0, fase 9, nível 10 → vinténs = (40+250)*3 = 870; muiraquitãs = 3; XP = `xp_table[10]*500/1000`.
  - `test_stage_enemy_stats`: ato 0, fase 0 → `CURVA[0]=12 × 822 × perf / 10^6`.
- [ ] **Passo 2:** Rodar e confirmar que FALHAM. Implementar. Rodar e confirmar que PASSAM.
- [ ] **Passo 3:** Fazer o commit: "Adiciona progressão, energia, itens, missões, fases e rivais ao núcleo".

**Abrir o PR B** e esperar a revisão.

---

### Tarefa 8: Estado do jogo, comandos e handlers

**Arquivos:**
- Criar: `game/state/{game_state.gd, command.gd, command_result.gd, command_router.gd}`, `game/state/handlers/*.gd` e um teste por handler em `game/tests/unit/handlers/`

**Interfaces:**
- Produz `class_name GameState extends RefCounted`:
  - perfil: `profile_id: String`, `mode: String` (`"offline"` ou `"online"`) e `nome: String`;
  - progresso: `lvl`, `xp`, `vint`, `muir`, `energia`, `en_upd_ms`, `coragem`, `co_upd_ms`, `honra`;
  - `stats: Dictionary[String,int]`, `equip: Dictionary[String, Variant]` (item ou `null`) e `mochila: Array[Dictionary]`;
  - `ofertas`, `ativa` (missão ou `{}`), `feira`, `feira_upd_ms`, `rivais`, `duelos`, `vitorias`, `vistos`, `fases: PackedInt32Array` (3 posições) e `chefe_espera_ms`;
  - contadores `uid`, `missoes`, `rng_seed` e `cmd_counter`;
  - métodos `static new_game(profile_id: String, mode: String, nome: String, seed_value: int, now_ms: int, rules) -> GameState`, `clone() -> GameState`, `to_dict() -> Dictionary`, `static from_dict(d: Dictionary) -> GameState` (com `int()` em todo número) e `total_stats() -> Dictionary`.
- Produz `class_name Command extends RefCounted`: `type: String`, `params: Dictionary`, `seed: int`, `now_ms: int` e `rules_version: String`, com `to_dict` e `from_dict`.
- Produz `class_name CommandResult extends RefCounted`: `ok: bool`, `error: String` (vazio quando dá certo), `state: GameState` e `events: Array[Dictionary]`, mais `static success(state, events)` e `static fail(state, code)`.
- Produz `CommandRouter`: `static apply(state: GameState, cmd: Command, rules: RulesPack) -> CommandResult`. Ele sempre trabalha sobre `state.clone()`, aplica `Stamina.regen` no início e usa `Rng.new(cmd.seed)`.
- Tipos de comando e códigos de erro:

| Tipo | Parâmetros | Erros |
|---|---|---|
| `iniciar_missao` | `mission_id` | `NAO_ENCONTRADO`, `MISSAO_ATIVA`, `ENERGIA_INSUFICIENTE` |
| `concluir_missao` | — | `SEM_MISSAO`, `MISSAO_EM_ANDAMENTO` |
| `acelerar_missao` | — | `SEM_MISSAO`, `MUIRAQUITAS_INSUFICIENTES` |
| `treinar` | `stat` | `ATRIBUTO_INVALIDO`, `VINTENS_INSUFICIENTES` |
| `enfrentar_fase` | `act`, `n` | `FASE_BLOQUEADA`, `NIVEL_INSUFICIENTE`, `EM_RECUPERACAO`, `ENERGIA_INSUFICIENTE` |
| `comprar` | `item_id` | `NAO_ENCONTRADO`, `VINTENS_INSUFICIENTES`, `MOCHILA_CHEIA` |
| `equipar` | `item_id` | `NAO_ENCONTRADO` |
| `desequipar` | `slot` | `MOCHILA_CHEIA` |
| `vender` | `item_id` | `NAO_ENCONTRADO` |
| `desafiar` | `rival_id` | `NAO_ENCONTRADO`, `CORAGEM_INSUFICIENTE` |
| `renomear` | `nome` | — (nome saneado) |

  Eventos que se somam aos do combate: `missao_concluida`, `xp_ganho`, `subiu_nivel`, `item_ganho`, `vintens_ganhos`, `fase_vencida`, `ato_concluido` e `honra_alterada`. `GameState.new_game` já preenche as ofertas de missão, a feira e os rivais. Os handlers reabastecem essas listas como a função `garantir()` da v0.2 (linha 516).

- [ ] **Passo 1:** Testes que falham, por handler. Cada um cobre o caminho feliz, todos os códigos de erro da tabela e o estado original intacto quando dá erro (`to_dict` igual antes e depois). Também:
  - `test_rename_sanitizes`: `"  Ana  "` → `"Ana"`; `""` → `"Jaci"`; `"\n\n"` → `"Jaci"`; 200 vezes `"x"` → 18 caracteres; `'Zé "Saci"\t🌿'` → `'Zé "Saci"🌿'`; e o estado depois disso sobrevive a `JSON.stringify`/`parse`.
  - `test_ally_mission_never_fights`.
  - `test_boss_win_full_bag_sells_item` (linha 901 da v0.2).
  - `test_defeat_sets_recovery_90s`.
- [ ] **Passo 2:** Rodar e confirmar que FALHAM. Implementar `GameState`, `Command`, `CommandResult`, o roteador e os handlers. Rodar e confirmar que PASSAM.
- [ ] **Passo 3:** Fazer o commit: "Adiciona estado do jogo, comandos e handlers".

### Tarefa 9: Relógio, executores assíncronos e GameService

**Arquivos:**
- Criar: `game/app/{clock.gd, command_executor.gd, local_executor.gd, game_service.gd}`, `game/tests/async/executor_parity_test.gd`, `game/tests/unit/game_service_test.gd`, `game/tests/support/{fake_clock.gd, delayed_executor.gd}`
- Modificar: `game/project.godot` (autoload `GameService`)

**Interfaces:**
- Produz `Clock` (RefCounted) com `now_ms() -> int`; `SystemClock` usa `Time.get_unix_time_from_system()*1000`, convertido para `int`; `FakeClock` tem `advance(ms: int)` e `set_now(ms: int)`.
- Produz `class_name CommandExecutor extends RefCounted` com `func execute(state: GameState, cmd: Command) -> CommandResult`, sempre usada com `await`.
  - `LocalExecutor` faz `await Engine.get_main_loop().process_frame` e chama `CommandRouter.apply`.
  - `DelayedExecutor.new(inner, delay_ms)`, só para testes, espera um `SceneTreeTimer` antes de delegar.
- Produz o autoload `GameService` (Node), com:
  - sinais `state_changed(state: GameState)`, `events_emitted(events: Array[Dictionary])`, `busy_changed(busy: bool)` e `warning(code: String)`;
  - `setup(rules: RulesPack, executor: CommandExecutor, clock: Clock, state: GameState) -> void`;
  - `send(type: String, params := {}) -> CommandResult`, aguardável. Ele monta o `Command` com `seed = Rng.derive_seed(state.rng_seed, state.cmd_counter)`, `now_ms = clock.now_ms()` e a `rules_version` do pacote, e incrementa `cmd_counter` no estado que volta do resultado;
  - `is_busy() -> bool`.

- [ ] **Passo 1:** Testes que falham:
  - `test_second_send_while_busy_is_rejected`: dois `send("treinar", {"stat": "for"})` sem `await` entre eles, usando `DelayedExecutor` de 500 ms. O segundo resultado tem `error == "OCUPADO"`, e o atributo de força sobe exatamente 1.
  - `test_busy_signal_toggles`.
  - `test_events_emitted_on_success`.
  - `test_executor_parity`: um roteiro fixo de 5 comandos (treinar, iniciar missão, acelerar, concluir, enfrentar fase 0) com `LocalExecutor` e com `DelayedExecutor(500)`, ambos com `FakeClock`, resulta em `state.to_dict()` idêntico.
- [ ] **Passo 2:** Rodar e confirmar que FALHAM. Implementar. Rodar e confirmar que PASSAM.
- [ ] **Passo 3:** Fazer o commit: "Adiciona executores assíncronos e GameService".

### Tarefa 10: Save com integridade, reservas, migrações e perfis

**Arquivos:**
- Criar: `game/state/save/{save_codec.gd, save_migrations.gd}`, `game/app/{file_io.gd, save_service.gd}`, `game/tests/unit/{save_codec_test.gd, save_migrations_test.gd, save_service_test.gd}`, `game/tests/fixtures/saves/`, `game/tests/support/failing_file_io.gd`
- Modificar: `game/app/game_service.gd` (salva depois de comandos, com no máximo uma gravação a cada 2000 ms, e em `NOTIFICATION_APPLICATION_PAUSED`/`FOCUS_OUT`)

**Interfaces:**
- Produz `SaveCodec`:
  - `const SAVE_VERSION := 1`;
  - `static encode(state: GameState, rules_version: String) -> String`. O envelope JSON tem `{save_version, rules_version, profile: {id, mode, nome}, state, hash}`, e o hash é o SHA-256 do JSON canônico (chaves ordenadas) de todo o envelope menos o próprio hash;
  - `static decode(text: String, migrations: SaveMigrations) -> Dictionary`, que devolve `{ok, error: "CORROMPIDO"|"VERSAO_FUTURA"|"", state: GameState}`.
- Produz `SaveMigrations`: `_init(steps: Dictionary)`, onde cada chave `from_version: int` aponta para um `Callable(Dictionary) -> Dictionary`, e `migrate(envelope: Dictionary) -> Dictionary`, que aplica os passos em sequência até `SAVE_VERSION`. A tabela de produção começa vazia.
- Produz `FileIO` (RefCounted) com `read(path) -> String` (vazio se não existir), `write(path, text) -> bool`, `rename(from, to) -> bool`, `exists(path) -> bool` e `list(dir) -> PackedStringArray`.
- Produz `SaveService.new(io: FileIO, root := "user://profiles")`, com:
  - `save(state, rules_version) -> bool`: escreve em `<id>.tmp`, roda as reservas (`<id>.bak2` ← `.bak1` ← `.json`) e renomeia `.tmp` para `.json`;
  - `load(profile_id) -> Dictionary`: devolve `{state, warning: ""|"RESERVA_USADA"|"SAVE_RECRIADO"}` e tenta `.json`, depois `.bak1`, depois `.bak2`;
  - `list_profiles() -> Array[Dictionary]`: lista `{id, mode, nome, lvl}`.

  Uma falha de escrita devolve `false`, e o `GameService` emite `warning("SAVE_FALHOU")`.

- [ ] **Passo 1:** Testes que falham:
  - `test_roundtrip_keeps_int_types`: um estado com `rng_seed = 2147483647` e todos os campos preenchidos passa por `encode` e `decode`, sai com `to_dict` igual e com `typeof == TYPE_INT` em todo valor numérico, inclusive os aninhados.
  - `test_tampered_byte_is_corrupt`.
  - `test_future_version_rejected`.
  - `test_example_migration_applies`: um passo 1→2 registrado só no teste acrescenta um campo; a fixture `v1_example.json` migra e o campo aparece.
  - `test_main_corrupt_uses_backup_with_warning`.
  - `test_all_copies_corrupt_starts_fresh_with_warning`: devolve `warning == "SAVE_RECRIADO"` e um estado novo no mesmo `profile_id` e no mesmo `mode`.
  - `test_write_failure_keeps_previous_file`: `FailingFileIO` falha em `write`; o `.json` anterior fica idêntico byte a byte e `save` devolve `false`.
  - `test_mode_edit_without_rehash_is_corrupt`: trocar `mode` de `offline` para `online` no arquivo sem recalcular o hash faz o save ser tratado como `CORROMPIDO`. Isso detecta só edições ingênuas; a garantia real de que um perfil offline não vira online vem do servidor, na etapa 5.
  - `test_list_profiles_shows_mode`.
- [ ] **Passo 2:** Rodar e confirmar que FALHAM. Implementar. Rodar e confirmar que PASSAM.
- [ ] **Passo 3:** Fazer o commit: "Adiciona save com integridade, reservas, migrações e perfis por modo".

### Tarefa 11: Regressão por cópia de referência e simulação de balanceamento

**Arquivos:**
- Criar: `game/tests/regression/{golden_cases.gd, golden_test.gd}`, `game/tests/regression/golden/{fights.json, playthrough.json}`, `tools/regen_golden.sh`, `game/tests/balance/{balance_sim.gd, balance_test.gd}`
- Modificar: `tools/bench.gd` (acrescenta `command_p95_us`: 1000 aplicações de `treinar` via `CommandRouter.apply`, percentil 95 em µs)

**Interfaces:**
- Produz `GoldenCases`:
  - `static fights() -> Array`: 50 lutas com `seed` de 1 a 50 e atributos variados por um `Rng(9001)` fixo, serializadas como `{seed, a, b, win, hp_final, events}`;
  - `static playthrough() -> Dictionary`: roteiro determinístico, com `FakeClock` e `CommandRouter`, que leva um jogo novo (semente 7) até o nível 30. A cada passo ele treina o atributo mais baixo enquanto houver vinténs, conclui a melhor missão disponível, enfrenta a próxima fase liberada e compra itens melhores que os equipados. O resultado registra `state.to_dict()` nos níveis 5, 10, 20 e 30, mais o número total de comandos.
- Produz `BalanceSim.run(rules, seed) -> Dictionary`, que devolve `{missions_to_30: int, stage_win_bp: int, boss_win_bp: int}`. Usa o mesmo jogador típico de `playthrough`. Para as taxas de vitória, simula 200 lutas por fase com o herói exatamente no nível exigido e com os atributos do momento em que chegou nele.

- [ ] **Passo 1:** O `regen_golden.sh` roda o `golden_cases.gd` com `-s` e grava os JSON. Gerar a primeira cópia de referência e conferir o diff (arquivos novos).
- [ ] **Passo 2:** `golden_test.gd`:
  - `test_fights_match_golden` e `test_playthrough_match_golden`: comparam com os arquivos gravados e, quando diferem, mostram o primeiro caminho divergente, como `fights[12].win`.
  - `test_golden_detects_change`: altera em memória o `for*17` para `for*18` (por injeção no `BalanceDef` de teste) e confirma que a comparação falha.
- [ ] **Passo 3:** `balance_test.gd` agrega 20 sementes e exige:
  - `stage_win_bp` em [4500, 6500];
  - `boss_win_bp` em [2000, 4000];
  - `missions_to_30` em [425, 575].

  Se falhar com as regras portadas, **calibrar apenas os valores em `balance.json`**: multiplicadores de fase, multiplicador do chefe e `curva`. Depois, regenerar a cópia de referência e registrar os valores antigos e os novos, com o motivo, para a nota da v0.3.0.
- [ ] **Passo 4:** Rodar a suíte inteira e confirmar que PASSA. Rodar o `bench.gd` e conferir que `command_p95_us` aparece no `metrics.json`.
- [ ] **Passo 5:** Fazer o commit: "Adiciona testes de regressão e de balanceamento".

### Tarefa 12: Inicialização do jogo com regras validadas

**Arquivos:**
- Criar: `game/app/boot.gd` (autoload `Boot`), `game/ui/erro_regras.tscn`, `game/tests/smoke/boot_test.gd`
- Modificar: `game/main.gd` e `game/main.tscn`, que passam a delegar ao `Boot`

**Interfaces:**
- Produz `Boot.start(pack_dir := "res://data/packs/base") -> bool`:
  1. carrega as regras; se o pacote for inválido, abre `erro_regras.tscn` com a lista de erros e devolve `false`;
  2. carrega o perfil offline padrão (`"solo"`) pelo `SaveService`; se não houver, cria um com `GameState.new_game`, com a semente vinda do `Crypto.generate_random_bytes(4)` limitada a 31 bits;
  3. configura o `GameService` com `LocalExecutor` e `SystemClock`;
  4. abre o menu.
- [ ] **Passo 1:** Testes que falham:
  - `test_boot_ok_opens_menu`;
  - `test_boot_broken_pack_shows_error`, usando a fixture `broken_bad_ref` da Tarefa 5;
  - `test_boot_creates_offline_profile_once`.
- [ ] **Passo 2:** Rodar e confirmar que FALHAM. Implementar. Rodar e confirmar que PASSAM. Fazer o commit: "Adiciona inicialização com validação das regras".

**Abrir o PR C** e esperar a revisão.

---

### Tarefa 13: Casca jogável, selo de modo e painel de desempenho

**Arquivos:**
- Criar: `game/ui/{menu, diagnostico, luta_teste, mode_badge}.tscn` com os `.gd` de cada uma, `game/app/perf_overlay.gd` (autoload, `CanvasLayer`) e `game/tests/smoke/screens_test.gd`

**Interfaces:**
- Consome: `GameService.send`, seus sinais e `Boot`.
- Telas:
  - `menu`: botões "Jornada Solo" (abre o diagnóstico) e "Roda Online", desativado, com o selo "Em breve". O rótulo da versão, com 5 toques em até 2 s, chama `PerfOverlay.toggle()`. Depois do primeiro quadro desenhado, executa `print("GF_READY")`.
  - `diagnostico`: `mode_badge` no topo (mostra "Offline · Jornada Solo"); nome editável (comando `renomear`); nível, vinténs, energia e coragem com contagem regressiva ao vivo; botões "Treinar Força", "Missão rápida" (inicia a missão mais curta, depois acelera e conclui) e "Enfrentar fase 1". Os botões ficam desativados enquanto `is_busy()`, e um indicador aparece depois de 300 ms. Mostra os códigos de erro e os avisos (`SAVE_FALHOU`, `RESERVA_USADA`, `SAVE_RECRIADO`) com textos em português.
  - `luta_teste`: recebe os eventos e mostra uma linha por evento, a cada 400 ms, como "Jaci acerta Saci Ligeiro: −16 PV", "Golpe crítico!", "Saci Ligeiro esquiva" e "Vitória!".
- `PerfOverlay`: atualiza a cada 500 ms com FPS (`Performance.TIME_FPS`), tempo por quadro em ms, memória estática em MB, modo, `save_version` e `rules_version`.

- [ ] **Passo 1:** Testes de fumaça que falham, com o scene runner do GdUnit4:
  - `test_each_screen_opens_without_errors`: cada `.tscn` abre e roda 5 quadros sem `push_error`.
  - `test_online_button_disabled`.
  - `test_badge_shows_offline`.
  - `test_buttons_disabled_while_busy`, com `DelayedExecutor`.
  - `test_five_taps_toggle_overlay`.
- [ ] **Passo 2:** Rodar e confirmar que FALHAM. Implementar. Rodar e confirmar que PASSAM. Exportar para web e abrir localmente: o fluxo do menu até a luta funciona com o mouse e com toque, simulado no DevTools.
- [ ] **Passo 3:** Fazer o commit: "Adiciona casca jogável, selo de modo e painel de desempenho".

### Tarefa 14: Calibração, teste no celular e fechamento da v0.3.0

**Arquivos:**
- Criar: `docs/teste-celular.md`, `docs/versoes/v0.3.0.md`
- Modificar: `tools/perf_budgets.json`, `game/project.godot` (`config/version="0.3.0"`), `CHANGELOG.md`, `docs/ROADMAP.md`, `CLAUDE.md`, `README.md`

- [ ] **Passo 1:** Calibrar os limites com as medições reais da CI (Tarefa 3, Passo 5, e o último PR). Se o download passar de 12 MB, primeiro tentar reduzir (desativar módulos que não usamos num template personalizado fica **fora** desta etapa; checar se a compressão está ativa). Se não houver como reduzir, ajustar o limite para o valor medido + 10% e registrar o motivo.
- [ ] **Passo 2:** Escrever `docs/teste-celular.md`:
  1. abrir `/novo/` no celular;
  2. tocar 5 vezes na versão;
  3. ir em Jornada Solo e rodar Enfrentar fase 1 três vezes;
  4. anotar o FPS médio e o mínimo, o modelo do aparelho e o navegador.

  Pedir à dona do projeto que execute o roteiro e registrar o resultado na nota.
- [ ] **Passo 3:** Fechar a versão: `config/version="0.3.0"`; mover `[Não lançado]` para `[0.3.0] - AAAA-MM-DD` no `CHANGELOG.md`; escrever `docs/versoes/v0.3.0.md` com objetivo, o que entrou, os limites calibrados, a calibração de balanceamento da Tarefa 11, as decisões, as pendências e o resultado do teste no celular; atualizar o status da etapa 1 no `ROADMAP.md` para "Concluído" e acrescentar a linha no diário; atualizar o `CLAUDE.md` com a nova estrutura, os comandos e as fórmulas em inteiros.
- [ ] **Passo 4:** Conferir que a suíte inteira passa, que a CI está verde e que o `/novo/` está publicado depois do merge. No PR, escrever `Closes #9`.
- [ ] **Passo 5:** Fazer o commit: "Fecha a v0.3.0, Fundação em Godot". **Abrir o PR D**. Depois do merge, conferir que a Release v0.3.0 foi criada pelo `release.yml`.
