# Guardiões do Folclore

Jogo de navegador no estilo Hero Zero com lendas do folclore brasileiro: Saci, Curupira, Iara, Boitatá, Cuca, Boto, Mapinguari e Negrinho do Pastoreio.

O jogo tem:
- missões com tempo;
- energia e coragem que recarregam com o tempo;
- treino de atributos;
- Torre dos Chefes com 3 atos e 30 fases (até o nível 30);
- arena de duelos;
- feira de itens;
- bestiário ilustrado.

## Estrutura
- `game/`: o jogo novo, em Godot 4.7.2 (em construção).
- `legacy-web/`: a v0.2 em HTML, publicada no GitHub Pages.
- `tools/`: scripts de ambiente e testes.

## Rodar localmente

A v0.2 (HTML):

```bash
python3 -m http.server -d legacy-web 8000
# ou: npx serve legacy-web
```

Depois abra http://localhost:8000.

O jogo em Godot:

```bash
tools/setup_godot.sh        # instala o Godot 4.7.2 e os templates de export
godot --path game           # abre o jogo
tools/run_tests.sh          # roda os testes (GdUnit4, sem tela)
```

## Documentação
- [CHANGELOG.md](CHANGELOG.md): o que mudou em cada versão.
- [docs/versoes/](docs/versoes/): nota detalhada de cada versão, com decisões e balanceamento.
- [docs/ROADMAP.md](docs/ROADMAP.md): próximas versões planejadas.
- [CLAUDE.md](CLAUDE.md): estrutura do código, fórmulas e fluxo de trabalho.

Versão publicada: **0.2.0** (v0.3.0 em desenvolvimento).
