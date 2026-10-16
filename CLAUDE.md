# Guardiões do Folclore

Jogo de navegador no estilo Hero Zero com lendas do folclore brasileiro. Projeto "Hero Zero da Shoppe".

## Como rodar
- Tudo está em `index.html` (HTML, CSS e JS num arquivo só, sem build).
- As ilustrações ficam em `assets/*.webp` (640×860, convertidas das artes originais).
- Para testar: `npx serve .` ou `python3 -m http.server 8000` e abrir `http://localhost:8000`.
  Abrir o arquivo direto (file://) também funciona.
- O progresso fica no `localStorage`, na chave `guardioes-folclore-v2`. Se o formato do save mudar, troque a chave e o campo `v`.

## Estrutura do código (dentro do `<script>`)
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

## Fórmulas
- Vida = 40 + Fôlego×8 + nível×12.
- Dano = Força×1,7 + nível×2,5, variando de ±20%.
- Crítico dobra o dano. A chance vem de Malícia contra o Fôlego do alvo, com teto de 40%.
- Esquiva vem de Ginga contra a Força do atacante, com teto de 35%.
- XP para subir de nível = 60 × nível^1,45.
- Custo de treino = 8 × 1,11^(valor − 6).
- Fase de chefe n (1–9): atributos = CURVA[nível] × (0,8 + 0,022n) × perfil. Chefe (fase 10): × 1,12.

## Decisões de conteúdo
- O Negrinho do Pastoreio é sempre aliado. Ele aparece só em tarefas e nunca como inimigo.
- O herói ainda é um SVG simples (`heroiSVG`). Falta uma ilustração do protagonista, de preferência com opções de escolha.

## Próximos passos sugeridos
- Arte do herói e de outras lendas (Mula sem Cabeça, Lobisomem, Caipora, Matinta Perera).
- Separar o código em módulos (dados, combate, UI) se o projeto crescer.
- Backend e contas, para salvar o progresso entre aparelhos e ter ranking real na Arena.
- Ajustar os tempos das missões (hoje são de 20 s a 1:30, para testes).
