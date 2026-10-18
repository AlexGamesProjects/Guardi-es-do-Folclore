# Palco de duelo e guardião articulado (v0.4.0, complemento)

**Data:** 18/10/2026 · **Milestone:** v0.4.0
**Complementa:** [spec da v0.4.0](2026-10-18-migracao-v0.4.0-design.md), seção 5.

## 1. Objetivo
1. A luta acontece num palco: os dois lutadores aparecem de corpo inteiro, de frente um para o outro, avançando e golpeando.
2. O guardião do jogador é um boneco articulado. Cada item equipado aparece no corpo dele e o acompanha em todas as animações.
3. Tudo de graça: a arte é feita por código e no Godot, sem gerar nada no PixelLab.

## 2. Palco de duelo (`ui/luta/palco.tscn`)
- **Camadas, de trás para a frente:**
  - fundo: a pintura da lenda escurecida, ou um degradê do tema quando não há pintura;
  - chão: faixa em pixel art de terra batida com capim;
  - os dois lutadores, de pé sobre o chão;
  - efeitos: números de dano flutuantes, faíscas e poeira;
  - placar: no topo, as barras de vida dos dois lados, com nome e nível.
- **Movimento, a partir dos mesmos eventos do núcleo:**
  - `golpe`: o atacante avança até o alcance, toca o ataque e volta; o alvo toca o golpe recebido e recua 6 px. Um número sobe sobre o alvo.
  - `critico`: igual ao golpe, com o número maior e dourado, tremor da tela e flash.
  - `esquiva`: o defensor salta para trás e aparece "Esquivou!".
  - `fim`: o perdedor toca a derrota e o vencedor toca a vitória (um pulo).
- **Inimigos:** usam o sprite do PixelLab (`SpriteLib`) quando existe. Sem sprite, a carta recortada fica de pé no chão, com as mesmas animações por Tween.
- **Controles:** o Pular e a velocidade de 1×/2×/4× continuam como estão. A narração vira uma linha curta embaixo do placar.
- **Interface:** a API da camada de luta continua igual: `Luta.tocar(eventos, velocidade)`, `pular()` e `terminou`. O palco substitui só o miolo visual.

## 3. Guardião articulado (`ui/heroi/`)
- **Montagem:**
  - `Skeleton2D` com 11 ossos: quadril, tronco, cabeça, braço e antebraço de cada lado, coxa e canela de cada lado. Cada osso tem um `Sprite2D` em pixel art.
  - O boneco é desenhado num `SubViewport` pequeno (160×160) e mostrado ampliado 4× com filtro *nearest*. Assim ele mantém o visual de pixel art mesmo quando os ossos giram.
- **Arte das partes:** desenhada por código (`tools/gen_heroi.py`, com Pillow) em PNG de baixa resolução, numa paleta tirada do herói do PixelLab. Ficam em `game/assets/heroi/partes/` (pele, camisa, calça, pés) e `game/assets/heroi/itens/<visual>.png`.
- **Animações:** feitas no Godot com `AnimationPlayer` girando e movendo os ossos: `parado` (respiração), `ataque`, `golpe`, `esquiva`, `derrota`, `vitoria` e `andar`. Os nomes são os mesmos que o `Lutador.animar` já usa, então o crítico é o ataque com efeito.
- **Encaixe dos itens:**

  | Slot | Osso | Como aparece |
  |---|---|---|
  | `cabeca` | cabeça | chapéu, gorro, cocar ou lenço |
  | `corpo` | tronco e braços | troca a camisa (gibão, bata, manto, colete, poncho) |
  | `arma` | antebraço da frente | peixeira, estilingue, zarabatana, cajado, facão, arco ou laço |
  | `amuleto` | tronco | figa, patuá, fita, pena, muiraquitã ou dente no peito |

- **Raridade:**
  - Comum: a peça como desenhada.
  - Rara: brilho verde no contorno.
  - Lendária: brilho dourado que pulsa.
- **Visual do item:** o pacote de regras ganha `visuais` em `items.json`, que liga cada nome-base ao id do desenho (ex.: `"Chapéu de Couro": "chapeu_couro"`). O item já guarda o nome completo ("Chapéu de Couro da Serra"); o visual é escolhido pelo nome-base. Item sem visual não aparece no corpo e não dá erro.
- **Onde aparece:**
  - na luta (palco), no lugar do sprite do PixelLab do herói;
  - num retrato no topo, ao lado do nome;
  - na Mochila, onde o boneco veste o que está equipado e mostra a troca na hora.
  - Os sprites do herói feitos no PixelLab continuam guardados, sem uso.
- **Origem:** o tom de pele e o cabelo vêm de uma escolha simples na criação: 4 tons e 3 cabelos, guardados no estado como `aparencia {pele, cabelo}`. Isso muda o save para a versão 3, com uma migração que dá valores padrão. *(Pode ficar para depois, se a dona preferir.)*

## 4. Testes
- **Unitário:** `HeroiVisual.para_item(item)` devolve o visual certo pelo nome-base, inclusive com epíteto, e "" quando o item não tem visual.
- **Fumaça:**
  - o boneco abre com todos os ossos;
  - equipar um item troca a peça do osso certo;
  - cada animação existe e toca sem erro;
  - a raridade liga o brilho.
- **Palco:**
  - com eventos sintéticos, o atacante avança e volta à posição;
  - o número de dano mostra o valor do evento;
  - o fim toca derrota e vitória;
  - Pular leva ao resultado.
- **Tamanho:** cada PNG de parte ou item fica abaixo de 20 KB.

## 5. Fora do escopo
Animações novas das lendas, chefes com boneco articulado, troca de cabelo ou pele depois da criação, sons.
