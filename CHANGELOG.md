# Histórico de versões

Todas as mudanças do jogo ficam registradas aqui. O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/), e a numeração segue o [Versionamento Semântico](https://semver.org/lang/pt-BR/):

- **MAIOR** (1.0.0): mudança grande que quebra o save ou muda o jogo por completo.
- **MENOR** (0.3.0): feature nova, como uma aba, um sistema ou um ato de chefes.
- **CORREÇÃO** (0.2.1): ajuste de balanceamento, texto ou bug.

Cada versão tem uma nota detalhada em [`docs/versoes/`](docs/versoes/).

## [Não lançado]

### Adicionado
- Criação do guardião: comando `criar_guardiao` com nome e origem (Mata Atlântica +2 Ginga, Sertão +2 Fôlego, Amazônia +2 Malícia, Pampa +2 Força), uma vez só. As origens ficam em `balance.json` e são validadas ao carregar.
- Casca do jogo no Godot (`ui/jogo.tscn`): topo fixo com herói, nível, XP, vinténs, muiraquitãs, energia e coragem; rodapé com as abas Missões, Torre, Arena, Feira e Mais; painel de treino ao tocar no herói; avisos e erros num Toast comum.
- Textos de erro por contexto (feira, mochila, arena).
- Aba Missões: 3 ofertas com lenda, dificuldade, energia e recompensa; missão em andamento com tempo restante, acelerar, concluir e renovar.
- Aba Torre dos Chefes: 3 atos de 10 fases, com cadeado por nível e espera depois de perder para um chefe.
- Aba Arena: rivais, desafio com coragem, honra e últimos duelos.
- Feira e Mochila: itens com cor de raridade e comparação com o equipado; comprar, equipar, desequipar, vender e renovar a feira.
- Aba Mais com Mochila, Bestiário e Ajustes (velocidade da luta, painel de desempenho, diagnóstico e versão clássica).
- Bestiário com as 8 pinturas da v0.2 como cartas; a lenda fica desconhecida até ser enfrentada. A carta também aparece na luta.
- Luta animada por cima da aba: carta da lenda, vida, narração, ataque, crítico com tremor e flash, esquiva e derrota; velocidade 1×/2×/4× e Pular.
- Especificação da v0.4.0, Migração (`docs/superpowers/specs/2026-10-18-migracao-v0.4.0-design.md`).

### Alterado
- Save do Godot na versão 2: o guardião ganha o campo `origem`. A migração 1→2 marca os perfis antigos como "legado", que não passam pela criação.
- A versão em desenvolvimento passa a ser `0.4.0-dev`.

### Corrigido
- O teste da versão aceita qualquer número no formato X.Y.Z ou X.Y.Z-dev. Antes ele exigia `0.3.0-dev` e quebrou a CI depois do lançamento.

## [0.3.0] - 2026-10-18

Nota completa: [docs/versoes/v0.3.0.md](docs/versoes/v0.3.0.md)

### Adicionado
- Projeto Godot 4.7.2 em `game/`, com GdUnit4 6.2.1 e tipagem obrigatória. O jogo HTML v0.2 foi para `legacy-web/` e continua publicado na raiz do site.
- CI a cada PR: lint, checagem de tipos, testes, export web sem threads, verificação de segredos e medições de download e carregamento, com relatório automático no PR.
- Núcleo de regras em `game/core/`, só com números inteiros e sorteio por semente: combate, progressão, energia e coragem, itens com raridades, missões, fases da Torre dos Chefes e rivais. Um teste de arquitetura impede que o núcleo dependa de tela, relógio ou sorteio sem semente.
- Pacote de regras versionado em `game/data/packs/base/` com todo o conteúdo da v0.2 e as constantes de balanceamento e de combate, validado ao carregar.
- Estado do jogo, comandos e handlers em `game/state/`: `GameState`, `Command`, `CommandResult` e `CommandRouter`, que aplica cada jogada (missões, treino, Torre dos Chefes, feira, mochila, Arena e nome) sobre um clone e deixa o estado original intacto em caso de erro. Os números dos handlers (chance de item, venda, custos em muiraquitã, honra da Arena) vêm do `balance.json`.
- Comandos assíncronos com `await GameService.send(tipo, params)`: um executor local roda as regras, recusa um segundo comando enquanto o primeiro não termina (toque duplo) e deriva a semente de cada jogada do perfil, o que deixa a partida reproduzível.
- Save com integridade: JSON canônico com SHA-256, gravação em arquivo temporário seguida de troca, duas cópias de reserva, migrações por versão e perfis separados por modo (offline e online). O jogo grava 2 s depois da última mudança e também ao pausar ou perder o foco, e avisa quando a gravação falha ou quando o save precisou ser recriado.
- Inicialização (`Boot`): valida o pacote de regras e mostra a lista de erros se ele estiver quebrado, cria o perfil offline "solo" uma única vez e abre o menu.
- Benchmark de 10 mil lutas no relatório de desempenho do PR (cerca de 0,44 s; limite de 2 s).
- Testes de regressão por cópia de referência (`game/tests/regression/golden/`): 50 lutas com sementes fixas e uma partida roteirizada até o nível 30. Para atualizar depois de uma mudança intencional, rode `tools/regen_golden.sh`.
- Teste de balanceamento: um jogador típico simulado em 20 sementes precisa ficar nas faixas do `balance.json` (vitória nas fases, nos chefes e missões até o nível 30).
- Tempo de um comando (p95) no benchmark de desempenho (`command_p95_us`).
- Casca jogável no Godot, com o visual de madeira e latão da v0.2:
  - menu com Jornada Solo e Roda Online ("Em breve");
  - tela de diagnóstico com selo de modo, nome editável, energia e coragem com contagem regressiva ao vivo e botões de treino, missão rápida e fase da Torre;
  - luta de teste narrada evento a evento.
- Painel de desempenho (FPS, tempo por quadro, memória, modo e versões do save, das regras e do esquema do pacote), aberto com 5 toques na versão. O save também guarda a `schema_version` do pacote de regras, e o benchmark grava o modo medido (`mode`) no `metrics.json`.
- Roteiro de teste no celular em `docs/teste-celular.md`.
- Agentes por camada em `.claude/agents/` (infra-ci, nucleo-regras, estado-app, interface, revisor).
- Especificação da etapa 1, Fundação em Godot (`docs/superpowers/specs/2026-10-17-fundacao-godot-design.md`).
- Roadmap visual com as 6 etapas, status e diário de avanços (`docs/ROADMAP.md`).
- Plano de implementação da Fundação, em 14 tarefas (`docs/superpowers/plans/2026-10-17-fundacao-godot.md`).

### Alterado
- Balanceamento calibrado pela simulação: a `curva` dos chefes passa a seguir a força média do jogador típico (nível 1: 12 → 10; nível 30: 64 → 152), as fases ficam em 0,892× a 1,068× da curva (antes 0,822× a 0,998×), o chefe em 1,09× (antes 1,12×) e o XP das missões cresce 4 por nível (antes 5).
- Milestones reorganizados por etapa: Fundação, Migração, Arte, Som, Contas e segurança e Lojas.
- Limite de carregamento calibrado de 5 s para 12 s com a primeira medição real (10,2 MB em 4G levam cerca de 10 s); redução do export registrada na issue #15.
- `CLAUDE.md` atualizado com a estrutura em camadas e as fórmulas em inteiros.
- A Release de cada versão passa a ser criada automaticamente quando o número em `VERSAO` muda no `main`, sem precisar enviar a tag à mão.

### Corrigido
- "Missão rápida" não trava mais quando os muiraquitãs acabam: o botão tenta concluir primeiro, só acelera se a missão ainda estiver correndo e, sem muiraquitãs, diz quanto tempo falta; um toque depois do fim conclui a missão.
- O menu passa a mostrar os avisos do jogo que chegam enquanto ele está aberto, como a falha ao salvar.

## [0.2.0] - 2026-10-15

Nota completa: [docs/versoes/v0.2.0.md](docs/versoes/v0.2.0.md)

### Adicionado
- Ilustrações pintadas de 8 lendas: Saci, Curupira, Iara, Boitatá, Negrinho do Pastoreio, Cuca, Boto e Mapinguari.
- **Torre dos Chefes**: 3 atos de 10 fases, do nível 1 ao 30, com um chefe ao fim de cada ato (Cuca, Boitatá e Mapinguari).
- Animações de combate distintas para ataque normal, golpe crítico e esquiva, com controle de velocidade (1×, 2×, 4×) e botão para pular.
- Contadores de recarga de energia (+1 a cada 30 s) e coragem (+1 a cada 2 min) na barra do topo.
- Títulos de rank por nível, de Aprendiz da Mata a Lenda Viva.
- Aba Mochila separada, com comparação de atributos contra o item equipado.
- Lendas que aparecem por nível: Cuca no 4, Iara no 8, Boto no 11, Boitatá no 14 e Mapinguari no 21.
- Número da versão no rodapé do jogo.

### Alterado
- Layout refeito: painel lateral do herói com atributos e equipamento, abas com ícones e visual de madeira escura com detalhes em latão.
- Missões deixaram de ser separadas por região e passaram a ser liberadas por nível.
- O Negrinho do Pastoreio aparece só como aliado, em tarefas, nunca como inimigo.

### Removido
- Desenhos simples em SVG das criaturas, substituídos pelas ilustrações.
- Mula sem Cabeça, Lobisomem, Corpo-Seco, Caipora, Minhocão e Matinta Perera, que ficam fora até ganharem ilustração.

### Atenção
- O save da 0.1.0 não é compatível. A chave do save mudou para `guardioes-folclore-v2`.

## [0.1.0] - 2026-10-15

Primeiro protótipo, publicado só como artefato e não versionado no repositório.

### Adicionado
- Missões com tempo e energia, separadas em 4 regiões (Mata Atlântica, Sertão, Pantanal e Amazônia).
- Lutas automáticas, treino de atributos (Força, Fôlego, Malícia e Ginga), feira de itens, arena de duelos e bestiário.
- 12 criaturas desenhadas em SVG no estilo de xilogravura de cordel.

[Não lançado]: https://github.com/AlexGamesProjects/Guardi-es-do-Folclore/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/AlexGamesProjects/Guardi-es-do-Folclore/releases/tag/v0.3.0
[0.2.0]: https://github.com/AlexGamesProjects/Guardi-es-do-Folclore/releases/tag/v0.2.0
[0.1.0]: https://github.com/AlexGamesProjects/Guardi-es-do-Folclore/releases/tag/v0.1.0
