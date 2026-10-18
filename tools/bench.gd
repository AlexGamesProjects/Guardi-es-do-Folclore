extends SceneTree
## Mede 10 mil lutas (atributos 40) e 1000 comandos `treinar` aplicados pelo `CommandRouter`, e
## acrescenta `fights_10k_ms` e `command_p95_us` (percentil 95, em µs) ao metrics.json.
##
## Fica em tools/ (e não em game/) porque é uma ferramenta de CI e não faz parte do jogo exportado.
## Por isso NÃO é coberto por gdformat, gdlint nem tools/check_scripts.sh, que só olham game/;
## formate e lint à mão: gdformat tools/bench.gd && (cd game && gdlint ../tools/bench.gd).
##
## Uso (da raiz do repositório):
##   godot --headless --path game -s ../tools/bench.gd -- --metrics="$PWD/metrics.json"
## Com --path, o Godot passa a trabalhar dentro de game/; por isso o caminho deve ser absoluto.

const FIGHTS: int = 10000
const STAT: int = 40
const COMMANDS: int = 1000
const P95_PERMILLE: int = 950
## Vinténs de sobra para que nenhum dos 1000 treinos falhe por falta de dinheiro.
const BENCH_VINT: int = 1_000_000_000_000_000
const BENCH_T0: int = 10_000_000


func _init() -> void:
	var metrics_path: String = ProjectSettings.globalize_path("res://").path_join("../metrics.json")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--metrics="):
			metrics_path = arg.trim_prefix("--metrics=")
	var loaded: RulesLoadResult = RulesLoader.load_dir("res://data/packs/base")
	if not loaded.ok:
		printerr("bench: pacote de regras inválido: %s" % str(loaded.errors))
		quit(1)
		return
	var cfg: Defs.CombatDef = loaded.pack.balance.combat
	var stats: Dictionary = {"for": STAT, "fol": STAT, "mal": STAT, "gin": STAT}
	var a: Fighter = Fighter.make("A", 10, stats)
	var b: Fighter = Fighter.make("B", 10, stats)
	var wins: int = 0
	var started: int = Time.get_ticks_usec()
	for i: int in FIGHTS:
		var r: CombatResult = Combat.simulate(a, b, Rng.new(Rng.derive_seed(2026, i)), cfg)
		if r.win:
			wins += 1
	var elapsed_ms: int = (Time.get_ticks_usec() - started + 999) / 1000
	var p95_us: int = _command_p95_us(loaded.pack)
	if p95_us < 0:
		quit(1)
		return
	var data: Dictionary = {}
	if FileAccess.file_exists(metrics_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(metrics_path))
		if parsed is Dictionary:
			data = Defs.normalize(parsed)
	data["fights_10k_ms"] = elapsed_ms
	data["command_p95_us"] = p95_us
	var file: FileAccess = FileAccess.open(metrics_path, FileAccess.WRITE)
	if file == null:
		printerr("bench: não consegui escrever %s" % metrics_path)
		quit(1)
		return
	file.store_string(JSON.stringify(data, "  ") + "\n")
	file.close()
	print("fights_10k_ms = %d (vitórias de A: %d de %d)" % [elapsed_ms, wins, FIGHTS])
	print("command_p95_us = %d (%d comandos treinar)" % [p95_us, COMMANDS])
	quit(0)


## Aplica 1000 `treinar` em sequência (alternando os atributos) e devolve o percentil 95 do tempo
## de `CommandRouter.apply`, em µs. Devolve -1 se algum comando falhar.
func _command_p95_us(rules: RulesPack) -> int:
	var state: GameState = GameState.new_game("bench", "offline", "Jaci", 7, BENCH_T0, rules)
	state.vint = BENCH_VINT
	var samples: Array[int] = []
	for i: int in COMMANDS:
		var stat: String = Defs.STAT_KEYS[i % Defs.STAT_KEYS.size()]
		var seed_value: int = Rng.derive_seed(state.rng_seed, state.cmd_counter)
		var cmd: Command = Command.make(
			"treinar", {"stat": stat}, seed_value, BENCH_T0, rules.rules_version
		)
		var t0: int = Time.get_ticks_usec()
		var res: CommandResult = CommandRouter.apply(state, cmd, rules)
		samples.append(Time.get_ticks_usec() - t0)
		if not res.ok:
			printerr("bench: treinar falhou com %s" % res.error)
			return -1
		state = res.state
		state.cmd_counter += 1
	samples.sort()
	return samples[(samples.size() * P95_PERMILLE + 999) / 1000 - 1]
