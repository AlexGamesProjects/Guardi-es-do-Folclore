extends SceneTree
## Mede 10 mil lutas (atributos 40) e acrescenta `fights_10k_ms` ao metrics.json.
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
	var data: Dictionary = {}
	if FileAccess.file_exists(metrics_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(metrics_path))
		if parsed is Dictionary:
			data = Defs.normalize(parsed)
	data["fights_10k_ms"] = elapsed_ms
	var file: FileAccess = FileAccess.open(metrics_path, FileAccess.WRITE)
	if file == null:
		printerr("bench: não consegui escrever %s" % metrics_path)
		quit(1)
		return
	file.store_string(JSON.stringify(data, "  ") + "\n")
	file.close()
	print("fights_10k_ms = %d (vitórias de A: %d de %d)" % [elapsed_ms, wins, FIGHTS])
	quit(0)
