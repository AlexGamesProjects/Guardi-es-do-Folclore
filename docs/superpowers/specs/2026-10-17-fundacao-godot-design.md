# Etapa 1 · Fundação em Godot: especificação

- **Data:** 17/10/2026
- **Versão alvo:** v0.3.0
- **Status:** em revisão
- **Decisões tomadas com:** dona do projeto, em sessão de brainstorming

## 1. Objetivo

Migrar o Guardiões do Folclore do protótipo HTML para o **Godot 4**, com uma arquitetura preparada para crescer. A fundação precisa ter:

- regras do jogo testáveis e separadas das telas;
- testes unitários, de regressão e de balanceamento rodando a cada PR;
- medição de desempenho com limites automáticos;
- save que nunca perde progresso entre versões;
- estrutura pronta para um modo online no futuro, sem misturar com o single-player.

A etapa 1 **não** reconstrói as telas do jogo. Ela entrega o núcleo completo e uma casca mínima jogável para provar a arquitetura. As telas completas são a etapa 2.

## 2. Contexto e decisões

| Tema | Decisão |
|---|---|
| Motor | Godot 4, versão estável travada em número exato no repositório |
| Linguagem | GDScript com tipagem obrigatória (C# ainda tem limitações no export web) |
| Quem programa | Só o Claude; a dona do projeto revisa os PRs e testa |
| Plataformas | Navegador e celular primeiro (interface vertical e por toque); Steam depois |
| Estilo visual | Misto: pixel art animada (PixelLab) nas lutas e no mapa, pinturas como cartas (etapa 3) |
| Arquitetura | Núcleo de regras puro dentro do Godot (caminho A) |
| Regras | Dados versionados e validados (1) e comandos assíncronos (3); sem download remoto de regras |
| Modos | Perfis separados: offline (Jornada Solo) e online (Roda Online, etapa 5); nunca se misturam |
| Segurança do online | Criptografia, autenticação e proteção de dados ficam para a etapa 5 |

### Etapas do projeto

| Etapa | Versão | Conteúdo |
|---|---|---|
| **1. Fundação** | v0.3.0 | Esta especificação |
| 2. Migração do jogo | v0.4.0 | Todas as telas e mecânicas da v0.2 refeitas no Godot, interface para celular |
| 3. Arte | v0.5.0 | Sprites do PixelLab, cartas pintadas, herói com opções |
| 4. Som | v0.6.0 | ElevenLabs (efeitos, ambientes, narração) e trilha do Suno |
| 5. Contas e segurança | a definir | Login, save na nuvem, modo online, servidor validando comandos |
| 6. Lojas | a definir | Android, iOS e Steam |

## 3. Arquitetura

### 3.1 Estrutura do repositório

```
/game/                     Projeto Godot 4
  project.godot
  core/                    Regras puras (sem tela, sem relógio, sem sorteio global)
    combat/                Simulação de luta por turnos
    progression/           XP, níveis, treino, ranks
    economy/               Preços, recompensas, feira
    stamina/               Energia e coragem (recarga por tempo)
    rng/                   Sorteio determinístico com semente
    rules/                 Carregamento e validação dos pacotes de regras
  data/packs/base/         Pacote de regras versionado (JSON)
  state/                   Estado do jogador, perfis e comandos
  app/                     Executor de comandos, save, relógio, desempenho
  ui/                      Telas (casca mínima nesta etapa)
  tests/                   unit, data, regression, balance, architecture, async, smoke
/legacy-web/               Jogo HTML v0.2 (index.html + assets), mantido no ar
/tools/                    Scripts da CI (medições, benchmark)
/docs/                     Versões, roadmap, especificações
/.github/workflows/        ci.yml, pages.yml, release.yml
```

### 3.2 Camadas e dependências

| Camada | Responsabilidade | Pode depender de |
|---|---|---|
| `core/` | Regras puras e deterministas | `data/` (definições já carregadas) |
| `data/` | Definições tipadas e pacotes JSON | nada |
| `state/` | Estado do jogador, perfis, comandos | `core/`, `data/` |
| `app/` | Executor, save, relógio, desempenho | `state/`, `core/`, `data/` |
| `ui/` | Exibir estado, enviar comandos, animar eventos | `app/` (e leitura de `state/`) |

**Regras invioláveis do `core/`:**
- não estende `Node` e não acessa a árvore de cenas;
- não lê o relógio do sistema: recebe o instante atual como parâmetro;
- não usa o sorteio global (`randi()`, `randf()`): usa o `Rng` com semente recebido;
- usa **aritmética inteira** em tudo que afeta o resultado: dano em inteiros e chances em pontos-base (1 = 0,01%). Isso garante resultados idênticos em web, celular e num servidor futuro, sem diferenças de ponto flutuante entre plataformas.

Um teste de arquitetura (seção 4) faz valer essas regras.

### 3.3 Pacotes de regras (dados versionados)

- Os pacotes ficam em `game/data/packs/<id>/`, com um `manifest.json` (id, `schema_version`, `rules_version`) e arquivos por domínio: `legends.json`, `stages.json`, `items.json`, `balance.json`.
- O formato é JSON, porque é legível nos diffs dos PRs e independente do motor, o que permite reaproveitá-lo num servidor.
- O carregador converte o JSON em classes tipadas e **valida** tudo:
  - campos obrigatórios e tipos;
  - faixas de valores, sem preço negativo e sem chance acima de 100%;
  - referências cruzadas: toda fase aponta para uma lenda existente e todo item tem um slot válido.
- Um pacote inválido **impede o jogo de iniciar**, com uma mensagem clara. Isso nunca chega ao jogador, porque a CI testa todos os pacotes.
- `schema_version` muda quando o formato muda; `rules_version` muda quando os valores mudam. As duas aparecem no painel de desempenho e são gravadas no save.

O conteúdo inicial reproduz a v0.2:
- 8 lendas, com o Negrinho do Pastoreio só como aliado;
- 3 atos de 10 fases;
- a tabela `CURVA`;
- as fórmulas de vida, dano, crítico, esquiva, XP e treino;
- os itens da feira;
- a recarga de energia e de coragem.

### 3.4 Comandos assíncronos

Toda mudança de estado acontece por um **comando**: `IniciarMissao`, `ConcluirMissao`, `Treinar`, `Comprar`, `Equipar`, `EnfrentarFase`, `Desafiar`, entre outros.

```gdscript
# Contrato (app/command_executor.gd)
class_name CommandExecutor
func execute(cmd: Command) -> CommandResult   # sempre usado com await
```

- `CommandResult` traz: `ok`, o código de erro (por exemplo `ENERGIA_INSUFICIENTE`), o novo estado e a **lista de eventos** (`DanoCausado`, `Critico`, `Esquiva`, `SubiuDeNivel`, `ItemGanho`…).
- As telas **sempre** usam `await`. Enquanto o comando está pendente, a ação fica bloqueada e o jogo mostra um indicador se a espera passar de 300 ms.
- As telas animam a partir dos **eventos**, nunca recalculando regras. É assim que a luta do núcleo vira animação de ataque, crítico ou esquiva.
- O comando carrega a semente do sorteio, o instante atual e a `rules_version`. Isso torna cada resultado reproduzível.

### 3.5 Executores e modos

| Executor | Etapa | Como funciona |
|---|---|---|
| `LocalExecutor` | 1 | Aplica o comando no `core/` dentro do aparelho |
| `RemoteExecutor` | 5 | Envia ao servidor, que roda o mesmo `core/` e devolve o resultado |

- Cada **perfil** tem um campo `mode`: `offline` ou `online`. O executor é escolhido pelo modo do perfil, e as telas não sabem qual está em uso.
- Um perfil offline **nunca** vira online, porque o save local pode ser editado. Copiar de online para offline é permitido no futuro.
- **Visibilidade para o jogador:** na tela inicial, a escolha entre **Jornada Solo** e **Roda Online** ("Em breve" nesta etapa). Dentro do jogo, um selo permanente indica o modo.
- **Visibilidade para desenvolvimento:** todo registro e toda medida levam a etiqueta do modo. O painel de desempenho mostra o modo, a `schema_version` do save e a `rules_version`.

### 3.6 Relógio

`app/clock.gd` define a interface `Clock.now_ms()`. `SystemClock` é usado no jogo e `FakeClock` nos testes, este último com `advance(ms)`. O `core/` só recebe o valor de `now_ms`.

## 4. Testes

O framework é o **GdUnit4**, numa versão travada, rodando sem tela na CI.

| Tipo | Pasta | O que garante |
|---|---|---|
| Unitários | `tests/unit/` | Cada fórmula e cada regra de comando: vida, dano, crítico, esquiva, XP, treino, recarga, validações como "sem vinténs não treina" |
| Contrato de dados | `tests/data/` | Todos os pacotes carregam e são válidos; referências e faixas corretas |
| Regressão (referência) | `tests/regression/` | 50 lutas com sementes fixas e uma partida roteirizada até o nível 30 produzem exatamente o resultado gravado em `tests/regression/golden/*.json` |
| Balanceamento | `tests/balance/` | Um jogador típico simulado vence de 45% a 65% das fases no nível certo e de 20% a 40% dos chefes, e chega ao nível 30 entre 425 e 575 missões médias (a simulação da v0.2 dá cerca de 500; a faixa fica em `balance.json`) |
| Arquitetura | `tests/architecture/` | Varre `core/` e reprova uso de `Node`, árvore de cenas, relógio do sistema, sorteio global ou `float` em campos de resultado |
| Assíncronos | `tests/async/` | Os mesmos fluxos com executor imediato e com executor atrasado de 500 ms produzem o mesmo estado final |
| Fumaça | `tests/smoke/` | Cada tela abre sem erros |

**Atualizar as referências:** uma mudança intencional de comportamento exige regenerar os arquivos em `golden/` com um script de `tools/` e explicar a mudança no PR. O diff mostra exatamente quais lutas mudaram.

**Método:** no `core/`, o teste vem antes do código (TDD).

## 5. Integração contínua e desempenho

### 5.1 Pipeline a cada PR (`ci.yml`)

1. **Qualidade:** formatação e lint do GDScript (gdtoolkit); avisos de tipagem do Godot tratados como erro.
2. **Testes:** todos os tipos da seção 4.
3. **Export web:** com **suporte a threads desligado**. O GitHub Pages não permite configurar os cabeçalhos de isolamento que o export com threads exige.
4. **Medições:**
   - tamanho do download inicial compactado;
   - tempo até a primeira tela interativa, num Chromium automático com rede limitada a "4G";
   - benchmark do núcleo: 10 mil lutas e o custo de aplicar um comando.
5. **Verificador de segredos:** reprova o PR se encontrar algo com formato de chave ou token.
6. **Relatório:** um comentário no PR com cada medida, comparando o valor no `main` com o valor no PR.

### 5.2 Limites iniciais

| Medida | Limite |
|---|---|
| Download inicial compactado | ≤ 12 MB |
| Carregamento até a primeira tela (4G) | ≤ 5 s |
| 10 mil lutas simuladas | ≤ 2 s |
| Aplicar um comando (local) | ≤ 1 ms |

São pontos de partida. Na primeira medição real, cada limite é calibrado e o ajuste fica registrado na nota da versão. Arte e som da etapa 3 em diante carregam sob demanda, para não inflar o download inicial.

### 5.3 FPS

Os servidores da CI não têm placa de vídeo, então FPS não é medido lá. Em vez disso:

- O jogo tem um **painel de desempenho escondido**, aberto com 5 toques no número da versão. Ele mostra FPS, tempo por quadro, memória, modo, `schema_version` e `rules_version`.
- Cada versão tem um **roteiro de teste no celular** registrado na nota da versão: abrir o combate de teste, rodar 3 lutas e anotar FPS médio e mínimo.
- A meta é 60 FPS e nunca menos de 30, num Android intermediário.

### 5.4 Publicação (`pages.yml`)

Depois do merge no `main`:
- a raiz do site publica o `legacy-web/` (v0.2), como hoje;
- `/novo/` publica o export web do Godot.

## 6. Save

- **Local:** `user://`, que no navegador vira o IndexedDB e no celular a pasta privada do app.
- **Formato:** JSON com `save_version`, a `rules_version` em uso, o perfil (`id`, `mode`, nome do guardião) e o estado.
- **Migrações:** uma função por passo (`v1→v2`, `v2→v3`…), aplicadas em sequência. Cada migração tem teste com saves de exemplo em `tests/fixtures/saves/`. **O jogador nunca perde progresso por atualização.**
- **Gravação segura:** grava num arquivo temporário e depois substitui o anterior. Mantém duas cópias de reserva.
- **Integridade:** um hash SHA-256 do conteúdo detecta arquivo corrompido. Nesse caso, o jogo carrega a reserva mais recente e avisa o jogador. O hash serve para detectar corrupção, **não** para impedir trapaça.
- **Quando salva:** depois de comandos que mudam o estado (agrupados, no máximo uma gravação a cada 2 s) e sempre que o app vai para segundo plano.
- **Tempo offline:**
  - a recarga usa o horário gravado;
  - relógio voltando no tempo não gera recarga negativa nem bônus;
  - avanço exagerado é limitado à barra cheia.
- **Save da v0.2 (HTML):** não é importado. O protótipo tem tempos de teste e desequilibraria o jogo.

## 7. Segurança nesta etapa

- O modo offline não coleta nenhum dado pessoal. O nome do guardião fica só no aparelho.
- Nenhum segredo vai para o repositório: tokens e chaves de assinatura ficam nos *Secrets* do GitHub, e o verificador da CI reprova vazamentos.
- O Godot, o GdUnit4, o gdtoolkit e as ações do GitHub ficam travados em versões exatas. As ações são fixadas pelo hash do commit.
- As medições de desempenho são só locais e não enviam nada.
- Criptografia, autenticação, LGPD e proteção do modo online ficam para a etapa 5.

## 8. Casca mínima jogável (UI da etapa 1)

Serve só para provar a arquitetura de ponta a ponta. O visual definitivo é da etapa 2.

1. **Tela inicial:** "Jornada Solo" (ativo) e "Roda Online — Em breve" (desativado).
2. **Tela de diagnóstico:** selo do modo; nome do guardião, nível, vinténs, energia e coragem com recarga ao vivo; botões "Treinar Força", "Missão rápida" e "Enfrentar fase 1".
3. **Luta de teste:** lista os eventos da luta em texto (ataque, crítico, esquiva, vitória) e prova que as telas consomem eventos do `core/`.
4. **Painel de desempenho** (seção 5.3).

## 9. Critérios de pronto da v0.3.0

- [ ] Projeto Godot em `game/`, versão do Godot travada, v0.2 movida para `legacy-web/` e ainda publicada na raiz.
- [ ] `core/` implementa todas as regras da v0.2 em inteiros, com testes unitários.
- [ ] Pacote `base` reproduz o conteúdo da v0.2 e passa nos testes de contrato.
- [ ] Testes de regressão, balanceamento, arquitetura, assíncronos e fumaça passando.
- [ ] Executor local com comandos assíncronos e eventos.
- [ ] Save com versão, migração de exemplo testada, gravação segura, reservas e checagem de integridade.
- [ ] Perfis com campo `mode`; selo de modo visível; "Roda Online" como "Em breve".
- [ ] CI completa a cada PR, com relatório de medidas e limites aplicados.
- [ ] Export web publicado em `/novo/`.
- [ ] Painel de desempenho e roteiro de teste no celular executado e registrado.
- [ ] `CHANGELOG.md`, `docs/versoes/v0.3.0.md`, `docs/ROADMAP.md` e `CLAUDE.md` atualizados.

## 10. Fora do escopo

- Telas definitivas, layout para celular e todas as abas (etapa 2).
- Sprites, cartas e herói ilustrado (etapa 3).
- Áudio (etapa 4).
- Servidor, contas, `RemoteExecutor`, criptografia e LGPD (etapa 5).
- Download remoto de pacotes de regras (descartado).
- Builds de Android, iOS e Steam (etapa 6).

## 11. Riscos e pontos em aberto

| Risco | Mitigação |
|---|---|
| Tamanho real do export web do Godot acima de 12 MB | Medir no primeiro export; recalibrar o limite ou otimizar (template enxuto, compressão) e registrar a decisão |
| Desempenho do Godot web no Safari do iOS | Incluir um iPhone no roteiro de teste quando houver aparelho disponível; o caminho principal no iOS será o app nativo (etapa 6) |
| Diferença de resultado entre plataformas | Aritmética inteira no `core/` e testes de regressão rodando no export web e no headless |
| PixelLab dependente do app desktop aberto | Só afeta a etapa 3; a geração de arte é agendada com a dona do projeto |
| Proteção do `main` (CI verde e aprovação obrigatórias) | Precisa ser ligada pela dona do projeto em Settings → Branches |
