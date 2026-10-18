# Histórico de versões

Todas as mudanças do jogo ficam registradas aqui. O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/), e a numeração segue o [Versionamento Semântico](https://semver.org/lang/pt-BR/):

- **MAIOR** (1.0.0): mudança grande que quebra o save ou muda o jogo por completo.
- **MENOR** (0.3.0): feature nova, como uma aba, um sistema ou um ato de chefes.
- **CORREÇÃO** (0.2.1): ajuste de balanceamento, texto ou bug.

Cada versão tem uma nota detalhada em [`docs/versoes/`](docs/versoes/).

## [Não lançado]

### Adicionado
- Projeto Godot 4.7.2 em `game/`, com GdUnit4 6.2.1 e tipagem obrigatória. O jogo HTML v0.2 foi para `legacy-web/` e continua publicado na raiz do site.
- CI a cada PR: lint, checagem de tipos, testes, export web sem threads, verificação de segredos e medições de download e carregamento, com relatório automático no PR.
- Núcleo de regras em `game/core/`, só com números inteiros e sorteio por semente: combate, progressão, energia e coragem, itens com raridades, missões, fases da Torre dos Chefes e rivais. Um teste de arquitetura impede que o núcleo dependa de tela, relógio ou sorteio sem semente.
- Pacote de regras versionado em `game/data/packs/base/` com todo o conteúdo da v0.2 e as constantes de balanceamento e de combate, validado ao carregar.
- Estado do jogo, comandos e handlers em `game/state/`: `GameState`, `Command`, `CommandResult` e `CommandRouter`, que aplica cada jogada (missões, treino, Torre dos Chefes, feira, mochila, Arena e nome) sobre um clone e deixa o estado original intacto em caso de erro. Os números dos handlers (chance de item, venda, custos em muiraquitã, honra da Arena) vêm do `balance.json`.
- Benchmark de 10 mil lutas no relatório de desempenho do PR (cerca de 0,44 s; limite de 2 s).
- Agentes por camada em `.claude/agents/` (infra-ci, nucleo-regras, estado-app, interface, revisor).
- Especificação da etapa 1, Fundação em Godot (`docs/superpowers/specs/2026-10-17-fundacao-godot-design.md`).
- Roadmap visual com as 6 etapas, status e diário de avanços (`docs/ROADMAP.md`).
- Plano de implementação da Fundação, em 14 tarefas (`docs/superpowers/plans/2026-10-17-fundacao-godot.md`).

### Alterado
- Milestones reorganizados por etapa: Fundação, Migração, Arte, Som, Contas e segurança e Lojas.
- Limite de carregamento calibrado de 5 s para 12 s com a primeira medição real (10,2 MB em 4G levam cerca de 10 s); redução do export registrada na issue #15.
- A Release de cada versão passa a ser criada automaticamente quando o número em `VERSAO` muda no `main`, sem precisar enviar a tag à mão.

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

[Não lançado]: https://github.com/AlexGamesProjects/Guardi-es-do-Folclore/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/AlexGamesProjects/Guardi-es-do-Folclore/releases/tag/v0.2.0
[0.1.0]: https://github.com/AlexGamesProjects/Guardi-es-do-Folclore/releases/tag/v0.1.0
