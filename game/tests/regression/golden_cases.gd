class_name GoldenCases
extends SceneTree
## Casos da cópia de referência (regressão). Rodado como script principal, grava os JSON em
## `golden/`; use `tools/regen_golden.sh` só quando a mudança de comportamento for intencional.
##
## - `fights()`: 50 lutas, semente de 1 a 50, combatentes sorteados por um `Rng(9001)` fixo.
## - `playthrough()`: o jogador típico de `BalanceSim`, semente 7, até o nível 30; grava o estado
##   nos níveis 5, 10, 20 e 30 e o total de comandos aplicados.

const GOLDEN_DIR: String = "res://tests/regression/golden"
const BASE_PACK: String = "res://data/packs/base"
const FIGHT_COUNT: int = 50
const FIGHTER_SEED: int = 9001
const PLAYTHROUGH_SEED: int = 7
const LVL_MIN: int = 1
const LVL_MAX: int = 30
const STAT_MIN: int = 3
const STAT_MAX: int = 90
const SNAPSHOT_LEVELS: Array[int] = [5, 10, 20, 30]


func _init() -> void:
	var ok: bool = (
		write_file("fights.json", fights()) and write_file("playthrough.json", playthrough())
	)
	quit(0 if ok else 1)


static func base_rules() -> RulesPack:
	return RulesLoader.load_dir(BASE_PACK).pack


static func fights(rules: RulesPack = null) -> Array:
	var pack: RulesPack = rules if rules != null else base_rules()
	var cfg: Defs.CombatDef = pack.balance.combat
	var gen := Rng.new(FIGHTER_SEED)
	var out: Array = []
	for seed_value: int in range(1, FIGHT_COUNT + 1):
		var a: Fighter = _random_fighter("A", gen)
		var b: Fighter = _random_fighter("B", gen)
		var r: CombatResult = Combat.simulate(a, b, Rng.new(seed_value), cfg)
		(
			out
			. append(
				{
					"seed": seed_value,
					"a": _fighter_dict(a),
					"b": _fighter_dict(b),
					"win": r.win,
					"hp_final": Array(r.hp_final),
					"events": r.events,
				}
			)
		)
	return to_json_value(out)


static func playthrough(rules: RulesPack = null) -> Dictionary:
	var pack: RulesPack = rules if rules != null else base_rules()
	var played: Dictionary = BalanceSim.play(pack, PLAYTHROUGH_SEED, SNAPSHOT_LEVELS)
	var out: Dictionary = {
		"seed": PLAYTHROUGH_SEED,
		"commands": played["commands"],
		"missions_to_30": played["missions_to_30"],
		"levels": played["snapshots"],
	}
	return to_json_value(out)


## Passa o valor por JSON (como o arquivo gravado) e volta os números para `int`.
static func to_json_value(value: Variant) -> Variant:
	return Defs.normalize(JSON.parse_string(JSON.stringify(value)))


static func read_file(file_name: String) -> Variant:
	var path: String = GOLDEN_DIR.path_join(file_name)
	if not FileAccess.file_exists(path):
		return null
	return Defs.normalize(JSON.parse_string(FileAccess.get_file_as_string(path)))


static func write_file(file_name: String, value: Variant) -> bool:
	var path: String = ProjectSettings.globalize_path(GOLDEN_DIR.path_join(file_name))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("regen_golden: não consegui escrever %s" % path)
		return false
	file.store_string(JSON.stringify(value, "  ", true) + "\n")
	file.close()
	print("regen_golden: gravado %s" % path)
	return true


## Primeiro caminho em que `actual` difere de `expected` (ex.: `fights[12].win`), ou "" se iguais.
static func first_diff(expected: Variant, actual: Variant, path: String) -> String:
	if typeof(expected) != typeof(actual):
		return path
	if expected is Dictionary:
		var e: Dictionary = expected
		var a: Dictionary = actual
		var keys: Array = e.keys()
		for k: Variant in a:
			if not e.has(k):
				keys.append(k)
		keys.sort()
		for k: Variant in keys:
			var sub: String = "%s.%s" % [path, str(k)]
			if not e.has(k) or not a.has(k):
				return sub
			var d: String = first_diff(e[k], a[k], sub)
			if not d.is_empty():
				return d
		return ""
	if expected is Array:
		var e_list: Array = expected
		var a_list: Array = actual
		for i: int in mini(e_list.size(), a_list.size()):
			var d: String = first_diff(e_list[i], a_list[i], "%s[%d]" % [path, i])
			if not d.is_empty():
				return d
		if e_list.size() != a_list.size():
			return "%s[%d]" % [path, mini(e_list.size(), a_list.size())]
		return ""
	return "" if expected == actual else path


static func _random_fighter(nome: String, gen: Rng) -> Fighter:
	var lvl: int = gen.range_int(LVL_MIN, LVL_MAX)
	var stats: Dictionary = {}
	for k: String in Defs.STAT_KEYS:
		stats[k] = gen.range_int(STAT_MIN, STAT_MAX)
	return Fighter.make(nome, lvl, stats)


static func _fighter_dict(f: Fighter) -> Dictionary:
	return {"nome": f.nome, "lvl": f.lvl, "stats": f.stats}
