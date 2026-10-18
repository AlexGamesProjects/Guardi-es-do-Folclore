class_name BalanceSim
extends RefCounted
## Jogador típico simulado e taxas de vitória da Torre dos Chefes.
##
## O roteiro do jogador (usado também pela cópia de referência `GoldenCases.playthrough`), a cada
## passo: treina o atributo base mais baixo enquanto houver vinténs; conclui a missão de maior XP;
## enfrenta a próxima fase liberada; compra na feira os itens melhores que os equipados. Itens que
## sobram na mochila são equipados (se forem melhores) ou vendidos. "Melhor" = maior soma de
## atributos. O tempo anda num `FakeClock`: o jogador espera a energia quando falta.

const TARGET_LVL: int = 30
const FIGHTS_PER_STAGE: int = 200
const MAX_STEPS: int = 20000
const START_MS: int = 10_000_000
const BP_FULL: int = 10000
## Desloca as sementes das lutas de fase para longe das sementes dos comandos.
const STAGE_SEED_BASE: int = 1_000_000


## Joga do zero até o nível 30. `snapshot_levels`: níveis em que se grava `state.to_dict()`.
## Devolve {state, commands, missions_to_30, stats_at: {nível: atributos totais},
## snapshots: {"nível": dicionário do estado}}.
static func play(rules: RulesPack, seed_value: int, snapshot_levels: Array[int]) -> Dictionary:
	var p := Player.new(rules, seed_value, snapshot_levels)
	var steps: int = 0
	while p.state.lvl < TARGET_LVL and steps < MAX_STEPS:
		p.step()
		steps += 1
	if p.state.lvl < TARGET_LVL:
		push_error(
			"BalanceSim: o jogador não chegou ao nível %d em %d passos" % [TARGET_LVL, steps]
		)
	return {
		"state": p.state,
		"commands": p.commands,
		"missions_to_30": p.missions_to_30,
		"stats_at": p.stats_at,
		"snapshots": p.snapshots,
	}


## {missions_to_30, stage_win_bp, boss_win_bp, phase_win_bp}. Para cada fase, 200 lutas do herói
## no nível exigido, com os atributos totais do momento em que chegou nesse nível.
## `phase_win_bp` (diagnóstico) traz a taxa de cada fase, na ordem dos atos.
static func run(rules: RulesPack, seed_value: int) -> Dictionary:
	var played: Dictionary = play(rules, seed_value, [])
	var stats_at: Dictionary = played["stats_at"]
	var cfg: Defs.CombatDef = rules.balance.combat
	var stage_wins: int = 0
	var stage_fights: int = 0
	var boss_wins: int = 0
	var boss_fights: int = 0
	var per_phase: Array[int] = []
	var phase_index: int = 0
	for act: int in rules.acts.size():
		for n: int in rules.acts[act].stages.size():
			var lvl: int = Stages.required_level(act, n, rules)
			var hero: Fighter = Fighter.make("Herói", lvl, stats_at[lvl])
			var enemy: Fighter = Stages.enemy(act, n, rules)
			var base_seed: int = Rng.derive_seed(seed_value, STAGE_SEED_BASE + phase_index)
			var wins: int = 0
			for i: int in FIGHTS_PER_STAGE:
				var rng := Rng.new(Rng.derive_seed(base_seed, i))
				if Combat.simulate(hero, enemy, rng, cfg).win:
					wins += 1
			per_phase.append(wins * BP_FULL / FIGHTS_PER_STAGE)
			if Stages.is_boss(act, n, rules):
				boss_wins += wins
				boss_fights += FIGHTS_PER_STAGE
			else:
				stage_wins += wins
				stage_fights += FIGHTS_PER_STAGE
			phase_index += 1
	return {
		"missions_to_30": played["missions_to_30"],
		"stage_win_bp": stage_wins * BP_FULL / maxi(1, stage_fights),
		"boss_win_bp": boss_wins * BP_FULL / maxi(1, boss_fights),
		"phase_win_bp": per_phase,
	}


## Soma dos atributos de um item (0 para espaço vazio).
static func item_score(item: Variant) -> int:
	if not item is Dictionary:
		return 0
	var st: Dictionary = (item as Dictionary)["st"]
	var total: int = 0
	for k: String in st:
		total += int(st[k])
	return total


class Player:
	extends RefCounted
	var rules: RulesPack
	var clock: FakeClock
	var state: GameState
	var commands: int = 0
	var missions_to_30: int = -1
	var stats_at: Dictionary = {}
	var snapshots: Dictionary = {}
	var _snapshot_levels: Array[int] = []

	func _init(rules_pack: RulesPack, seed_value: int, snapshot_levels: Array[int]) -> void:
		rules = rules_pack
		clock = FakeClock.new(START_MS)
		state = GameState.new_game("sim", "offline", "Jaci", seed_value, clock.now_ms(), rules)
		_snapshot_levels = snapshot_levels
		stats_at[state.lvl] = state.total_stats()

	## Aplica um comando com a semente do contador (R20); o contador só anda no sucesso.
	func send(type: String, params: Dictionary) -> CommandResult:
		var cmd: Command = Command.make(
			type,
			params,
			Rng.derive_seed(state.rng_seed, state.cmd_counter),
			clock.now_ms(),
			rules.rules_version
		)
		var res: CommandResult = CommandRouter.apply(state, cmd, rules)
		if res.ok:
			var old_lvl: int = state.lvl
			state = res.state
			state.cmd_counter += 1
			commands += 1
			_record(old_lvl)
		return res

	func step() -> void:
		_train()
		_mission()
		_stage()
		_tidy_bag()
		_shop()
		_tidy_bag()

	func _record(old_lvl: int) -> void:
		for lvl: int in range(old_lvl + 1, state.lvl + 1):
			stats_at[lvl] = state.total_stats()
			if lvl == BalanceSim.TARGET_LVL:
				missions_to_30 = state.missoes
		for lvl: int in _snapshot_levels:
			if old_lvl < lvl and lvl <= state.lvl:
				snapshots[str(lvl)] = state.to_dict()

	func _train() -> void:
		while true:
			var stat: String = Defs.STAT_KEYS[0]
			for k: String in Defs.STAT_KEYS:
				if state.stats[k] < state.stats[stat]:
					stat = k
			if state.vint < Progression.train_cost(state.stats[stat], rules):
				return
			if not send("treinar", {"stat": stat}).ok:
				return

	func _mission() -> void:
		if state.ofertas.is_empty():
			return
		var best: Dictionary = state.ofertas[0]
		for m: Dictionary in state.ofertas:
			if int(m["xp"]) > int(best["xp"]):
				best = m
		_wait_energy(int(best["en"]))
		if not send("iniciar_missao", {"mission_id": int(best["id"])}).ok:
			return
		clock.advance(int(best["dur"]) * 1000)
		send("concluir_missao", {})

	func _stage() -> void:
		for act: int in rules.acts.size():
			var n: int = state.fases[act]
			if n >= rules.acts[act].stages.size():
				continue
			if state.lvl < Stages.required_level(act, n, rules):
				return
			if clock.now_ms() < state.chefe_espera_ms:
				return
			_wait_energy(rules.balance.chefe_en)
			send("enfrentar_fase", {"act": act, "n": n})
			return

	func _shop() -> void:
		var ids: Array[int] = []
		for item: Dictionary in state.feira:
			ids.append(int(item["id"]))
		for id: int in ids:
			var item: Dictionary = _find(state.feira, id)
			if item.is_empty() or state.vint < int(item["preco"]):
				continue
			var slot: String = str(item["slot"])
			var occupied: bool = state.equip.get(slot) != null
			if BalanceSim.item_score(item) <= BalanceSim.item_score(state.equip.get(slot)):
				continue
			if not send("comprar", {"item_id": id}).ok:
				continue
			if occupied:
				send("equipar", {"item_id": id})

	## Equipa da mochila o que for melhor que o equipado e vende o resto.
	func _tidy_bag() -> void:
		var changed: bool = true
		while changed:
			changed = false
			for item: Dictionary in state.mochila:
				var slot: String = str(item["slot"])
				if BalanceSim.item_score(item) > BalanceSim.item_score(state.equip.get(slot)):
					changed = send("equipar", {"item_id": int(item["id"])}).ok
					break
		var ids: Array[int] = []
		for item: Dictionary in state.mochila:
			ids.append(int(item["id"]))
		for id: int in ids:
			send("vender", {"item_id": id})

	func _wait_energy(amount: int) -> void:
		var b: Defs.BalanceDef = rules.balance
		var now: int = clock.now_ms()
		var en: Dictionary = Stamina.regen(state.energia, state.en_upd_ms, now, b.en_max, b.en_ms)
		var cur: int = en["cur"]
		if cur >= amount:
			return
		var upd: int = en["upd_ms"]
		clock.advance((amount - cur) * b.en_ms - (now - upd))

	static func _find(list: Array[Dictionary], id: int) -> Dictionary:
		for item: Dictionary in list:
			if int(item["id"]) == id:
				return item
		return {}
