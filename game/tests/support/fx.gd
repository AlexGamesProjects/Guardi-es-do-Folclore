class_name Fx
extends RefCounted
## Apoio dos testes de estado: pacote base, jogo novo, comandos e itens de mentira.

const BASE: String = "res://data/packs/base"
const T0: int = 10_000_000


static func rules() -> RulesPack:
	return RulesLoader.load_dir(BASE).pack


static func game(rules_pack: RulesPack, seed_value: int = 7) -> GameState:
	return GameState.new_game("p1", "offline", "Jaci", seed_value, T0, rules_pack)


static func run(
	state: GameState,
	type: String,
	params: Dictionary,
	rules_pack: RulesPack,
	now_ms: int = T0,
	seed_value: int = 99
) -> CommandResult:
	var cmd: Command = Command.make(type, params, seed_value, now_ms, rules_pack.rules_version)
	return CommandRouter.apply(state, cmd, rules_pack)


static func item(
	id: int, slot: String, preco: int = 100, st: Dictionary = {"for": 3, "gin": 1}
) -> Dictionary:
	return {"id": id, "slot": slot, "nome": "Item %d" % id, "rar": 0, "st": st, "preco": preco}


static func fill_bag(state: GameState, rules_pack: RulesPack) -> void:
	state.mochila.clear()
	for i: int in rules_pack.balance.mochila:
		state.mochila.append(item(1000 + i, "corpo"))


static func strong(state: GameState) -> void:
	for k: String in Defs.STAT_KEYS:
		state.stats[k] = 400


static func weak(state: GameState) -> void:
	for k: String in Defs.STAT_KEYS:
		state.stats[k] = 1
	for slot: String in Defs.SLOT_KEYS:
		state.equip[slot] = null


static func types(res: CommandResult) -> Array[String]:
	var out: Array[String] = []
	for e: Dictionary in res.events:
		out.append(str(e["type"]))
	return out


static func find_event(res: CommandResult, type: String) -> Dictionary:
	for e: Dictionary in res.events:
		if e["type"] == type:
			return e
	return {}
